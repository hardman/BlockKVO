//
//  NSObject+BlockKVO.m
//  BlockKVO
//
//  Created by hongyuwang on 2018/7/3.
//

#import "NSObject+BlockKVO.h"

#import <objc/runtime.h>

///通过keyPath获取set方法的SEL
///若keyPath 是 “name” 则取到的 SEL 则为 “setName:”
static SEL getSetSelector(NSString * keyPath){
    NSString *first = [[keyPath substringToIndex:1] uppercaseString];
    NSString *last = [keyPath substringFromIndex:1];
    return NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", first, last]);
}

///根据set方法的SEL，获取keyPath，同getSetSelector是相对的方法
///若selector是 “setName:”，则返回的keyPath为 “name”
static NSString *getKeyPath(SEL selector){
    NSString *keyPath = NSStringFromSelector(selector);
    keyPath = [keyPath substringWithRange:NSMakeRange(3, keyPath.length - 4)];
    NSString *first = [[keyPath substringToIndex:1] lowercaseString];
    NSString *last = [keyPath substringFromIndex:1];
    return [NSString stringWithFormat:@"%@%@", first, last];
}

///保存了每次添加监听时传入的参数
@interface BlockKVOItem: NSObject
@property (nonatomic, copy) id keyPath;//监听的属性
@property (nonatomic, unsafe_unretained) NSKeyValueObservingOptions options;//选项
@property (nonatomic, copy) void (^block)(id obj, NSString *keyPath, NSDictionary<NSKeyValueChangeKey,id> *change);//回调
@end

@implementation BlockKVOItem
@end

///实际封装KVO的类，作为原对象的ascociate对象，会在原对象销毁时，释放所有变量。
@interface BlockKVO()
@property (nonatomic, weak) id obj;//原对象
@property (nonatomic, weak) Class srcClass;//原类
@property (nonatomic, weak) Class dynamicClass;//动态生成类

@property (nonatomic, strong) NSMutableDictionary<NSString *, BlockKVOItem *>* observers;//所有KVO监听的参数
-(BlockKVOItem *) itemWithKeyPath:(NSString *)keyPath;//获取某个KVO监听参数
@end

static void dynamicSetKeyPath(id obj, SEL sel, id value){
    BlockKVO *blockKVO = [obj blockKVO];
    if(blockKVO != nil) {
        NSString *keypath = getKeyPath(sel);
        BlockKVOItem *item = [blockKVO itemWithKeyPath:keypath];
        if(item != nil) {
            object_setClass(obj, blockKVO.srcClass);
            id oldValue = [obj valueForKey:keypath];
            [obj setValue:value forKey: keypath];
            object_setClass(obj, blockKVO.dynamicClass);
            NSMutableDictionary * change = [[NSMutableDictionary alloc] init];
            if (item.options & NSKeyValueObservingOptionOld){
                change[@"old"] = oldValue;
            }
            if (item.options & NSKeyValueObservingOptionNew) {
                change[@"new"] = value;
            }
            [obj observeValueForKeyPath:keypath ofObject:obj change:change context:nil];
        }
    }
}

@implementation BlockKVO

- (instancetype)initWithObj:(NSObject *)obj
{
    self = [super init];
    if (self) {
        self.obj = obj;
        
        self.srcClass = [obj class];
        
        //添加子类
        NSString *dynamicClassName = [NSString stringWithFormat:@"%@_NotifyKVO", NSStringFromClass(self.srcClass)];
        Class dynamicClass = NSClassFromString(dynamicClassName);
        if(!dynamicClass) {
            dynamicClass = objc_allocateClassPair(self.srcClass, dynamicClassName.UTF8String, 0);
            objc_registerClassPair(dynamicClass);
        }
        self.dynamicClass = dynamicClass;
    }
    return self;
}

//添加KVO监听
-(void) addObserverForKeyPath:(NSString *)keyPath option:(NSKeyValueObservingOptions)option block:(void (^)(id obj, NSString *keyPath, NSDictionary<NSKeyValueChangeKey,id> *change))block{
    
    if(self.observers == nil){
        self.observers = [[NSMutableDictionary alloc] init];
    }else if(self.observers[keyPath] != nil){
        return;
    }
    
    //将obj的类换成新创建的子类，否则不会调到dynamicSetKeyPath
    //只要有KVO监听，就要讲obj的class设置为dynamicClass
    object_setClass(self.obj, self.dynamicClass);
    
    //添加方法
    [self _addSetterMethodForKeyPath:keyPath imp:(IMP)dynamicSetKeyPath encodeType:@"v@:@"];
    
    //保存
    BlockKVOItem *item = [[BlockKVOItem alloc] init];
    item.keyPath = keyPath;
    item.options = option;
    item.block = block;
    self.observers[keyPath] = item;
}

//对class_addMethod的封装
-(void) _addSetterMethodForKeyPath:(NSString *)keyPath imp:(IMP)imp encodeType:(NSString *)type{
    SEL methodSel = getSetSelector(keyPath);
    Class clazz = self.dynamicClass;
    if (class_getMethodImplementation(clazz, methodSel) == NULL) {
        class_addMethod(clazz, methodSel, imp, type.UTF8String);
    }else{
        class_replaceMethod(clazz, methodSel, imp, type.UTF8String);
    }
}

//对class_removeMethod的封装（虽然实际上runtime没有暴露此方法，但是我们可以通过其他途径达到相同效果，比如下面的实现）
-(void) _removeSetterMethodForKeyPath:(NSString *)keyPath encodeType:(NSString *)type{
    SEL methodSel = getSetSelector(keyPath);
    if (class_getMethodImplementation(self.dynamicClass, methodSel) != NULL){
        class_replaceMethod(self.dynamicClass, methodSel, class_getMethodImplementation(self.srcClass, methodSel), type.UTF8String);
    }
}

//移除KVO监听
-(void) removeObserverForKeyPath:(NSString *)keyPath{
    BlockKVOItem *item = self.observers[keyPath];
    if(item != nil) {
        self.observers[keyPath] = nil;
        
        [self _removeSetterMethodForKeyPath:keyPath encodeType:@"v@:@"];
        
        if (self.observers.count == 0) {
            object_setClass(self.obj, self.srcClass);
        }
    }
}

//获取
-(BlockKVOItem *) itemWithKeyPath:(NSString *)keyPath{
    return self.observers[keyPath];
}

@end

static uint8_t _blockKvoAssociatedKey = 0;

@implementation NSObject(BlockKVO)

-(BlockKVO *)blockKVO{
    return objc_getAssociatedObject(self, &_blockKvoAssociatedKey);
}

-(void) initBlockKVO{
    if(self.blockKVO == nil) {
        BlockKVO *kvo = [[BlockKVO alloc] initWithObj:self];
        objc_setAssociatedObject(self, &_blockKvoAssociatedKey, kvo, OBJC_ASSOCIATION_RETAIN);
    }
}

-(void) addObserverForKeyPath:(NSString *)keyPath option:(NSKeyValueObservingOptions)option block:(void (^)(id obj, NSString *keyPath, NSDictionary<NSKeyValueChangeKey,id> *change))block{
    [self initBlockKVO];
    [self.blockKVO addObserverForKeyPath:keyPath option:option block:block];
}

-(void) removeObserverForKeyPath:(NSString *)keyPath{
    if (self.blockKVO != nil) {
        [self.blockKVO removeObserverForKeyPath:keyPath];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    BlockKVOItem *item = [self.blockKVO itemWithKeyPath:keyPath];
    if(item.block) {
        item.block(self, keyPath, change);
    }
}
@end

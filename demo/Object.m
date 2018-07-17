//
//  Object.m
//  BlockKVO
//
//  Created by hongyuwang on 2018/7/3.
//

#import "Object.h"

#import <objc/runtime.h>
#import <objc/message.h>

@implementation Object

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSLog(@" --- Object observeValueForKeyPath:%@ ofObject:%@ change:%@ context:%@", keyPath, object, change, context);
}

-(NSString *) description{
    return [NSString stringWithFormat: @"This is %@ instance keypath = %@", self.class, self.keypath];
}

+(void)test{
    Object *obj = [[Object alloc] init];
    obj.keypath = @"inited";
    NSLog(@"%@", obj);
    object_setClass(obj, Object_KVONotify.class);
    obj.keypath = @"hello world";
}

@end

static void dynamicSetKeyPath(id obj, SEL sel, id v){
    object_setClass(obj, Object.class);
    [obj setValue: v forKey: @"keypath"];
    object_setClass(obj, Object_KVONotify.class);
    NSMutableDictionary * change = [[NSMutableDictionary alloc] init];
    change[@"new"] = v;
    [obj observeValueForKeyPath:@"keypath" ofObject:obj change:change context:nil];
}

@implementation Object_KVONotify
-(void) setKeypath:(NSString *)keypath{
    dynamicSetKeyPath(self, @selector(setKeypath:), keypath);
}
@end

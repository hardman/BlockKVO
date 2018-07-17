//
//  TestBlockKVO.m
//  BlockKVO
//
//  Created by hongyuwang on 2018/7/3.
//

#import "TestBlockKVO.h"

@implementation TestObj

@end

@implementation TestBlockKVO
+(void)test{
    TestBlockKVO *test = [[TestBlockKVO alloc] init];
    [test addObserverForKeyPath:@"sayHello" option:NSKeyValueObservingOptionNew block:^(id obj, NSString *keyPath, NSDictionary<NSKeyValueChangeKey,id> *change) {
        NSLog(@" -- found obj=%@ keypath=%@ change=%@", obj, keyPath, change);
    }];
    
    [test addObserverForKeyPath:@"testObj" option:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld block:^(id obj, NSString *keyPath, NSDictionary<NSKeyValueChangeKey,id> *change) {
        NSLog(@" -- found obj=%@ keypath=%@ change=%@", obj, keyPath, change);
    }];
    
    test.sayHello = @"hello";
    
    [test removeObserverForKeyPath:@"sayHello"];
    
    test.sayHello = @"world";
    
    test.testObj = [TestObj new];
    test.testObj = [TestObj new];
}
@end

//
//  TestBlockKVO.h
//  BlockKVO
//
//  Created by hongyuwang on 2018/7/3.
//

#import <Foundation/Foundation.h>
#import "NSObject+BlockKVO.h"

@interface TestObj: NSObject
@end

@interface TestBlockKVO : NSObject
@property (nonatomic, copy) NSString *sayHello;
@property (nonatomic, weak) TestObj *testObj;

+(void)test;

@end

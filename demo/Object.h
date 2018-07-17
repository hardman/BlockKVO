//
//  Object.h
//  BlockKVO
//
//  Created by hongyuwang on 2018/7/3.
//

#import <Foundation/Foundation.h>

@interface Object : NSObject
@property (nonatomic, copy) NSString *keypath;

+(void)test;
@end

@interface Object_KVONotify: Object

@end

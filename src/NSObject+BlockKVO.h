//
//  NSObject+BlockKVO.h
//  BlockKVO
//
//  Created by hongyuwang on 2018/7/3.
//

#import <Foundation/Foundation.h>

@interface BlockKVO: NSObject
@end

@interface NSObject(BlockKVO)

@property (readonly) BlockKVO *blockKVO;

-(void) addObserverForKeyPath:(NSString *)keyPath option:(NSKeyValueObservingOptions)option block:(void (^)(id obj, NSString *keyPath, NSDictionary<NSKeyValueChangeKey,id> *change))block;

-(void) removeObserverForKeyPath:(NSString *)keyPath;
@end

//
//  NSArray+AnimatedType.h
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (AnimatedType)
@property (nonatomic, assign) BOOL animationTypeReciprocating;

@property (nonatomic, strong) NSString *animationImageVID;

@property (nonatomic, assign) BOOL animatedImage; // 标记为动图资源
@end

NS_ASSUME_NONNULL_END

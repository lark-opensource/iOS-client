//
//  NSError+IESEffectManager.h
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSError (IESEffectManager)

+ (NSError *)ieseffect_errorWithCode:(NSInteger)code description:(NSString *)description;

@end

NS_ASSUME_NONNULL_END

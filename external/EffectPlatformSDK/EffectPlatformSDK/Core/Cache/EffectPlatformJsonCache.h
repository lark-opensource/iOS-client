//
//  EffectPlatformJsonCache.h
//  EffectPlatformSDK
//
//  Created by 琨王 on 2019/2/22.
//

#import <Foundation/Foundation.h>
#import "EffectPlatformCache.h"

NS_ASSUME_NONNULL_BEGIN

// 新版本，直接持久化 json
@interface EffectPlatformJsonCache : NSObject<EffectPlatformCacheService>
- (instancetype)initWithAccessKey:(NSString *)accessKey;
@end

NS_ASSUME_NONNULL_END

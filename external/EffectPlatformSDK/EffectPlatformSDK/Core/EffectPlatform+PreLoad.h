//
//  EffectPlatform+PreLoad.h
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/4/25.
//

#import "EffectPlatform.h"

NS_ASSUME_NONNULL_BEGIN

@interface EffectPlatform (PreLoad)

- (void)preFetchAndDownloadEffects;

- (void)setPreFetchAndDownloadHeaderFields:(NSDictionary *)headerFields;

@end

NS_ASSUME_NONNULL_END

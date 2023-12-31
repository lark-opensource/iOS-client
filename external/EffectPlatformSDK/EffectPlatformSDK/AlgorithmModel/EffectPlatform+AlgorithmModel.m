//
//  EffectPlatform+AlgorithmModel.m
//  Pods
//
//  Created by 琨王 on 2019/3/6.
//

#import "EffectPlatform+AlgorithmModel.h"
#import <EffectPlatformSDK/IESEffectManager.h>

#if !TARGET_IPHONE_SIMULATOR
#import <EffectSDK_iOS/bef_effect_api.h>
#endif

static NSString * const kIESEffectPlatformStoredSDKVersion = @"kIESEffectPlatformStoredSDKVersion";

@implementation EffectPlatform (AlgorithmModel)

+ (void)setUpAlgorithmModelWithExcludePattern:(NSString *)excludePattern
{
}

+ (void)setUpAlgorithmModelWithExcludePattern:(NSString *)excludePattern downloadModels:(BOOL)downloadModels
{
}

+ (void)setAlgorithmModelUseBlock:(void (^)(BOOL, NSString * _Nonnull, NSString * _Nonnull, NSString * _Nonnull, NSInteger, NSString * _Nonnull))completion
{
}

+ (void)setAlgorithmModelDownloadCompletionBlock:(void (^)(BOOL, NSString * _Nonnull, NSError * _Nonnull, NSTimeInterval))completion
{
}

+ (void)setAutoDownloadAlgorithmModel:(BOOL)autoDownloadAlgorithmModel
{
}

+ (void)checkEffectSDKVersionUpdate
{
}

#if !TARGET_IPHONE_SIMULATOR
+ (platformsdk_resource_finder)getResourceFinder
{
    return [[IESEffectManager manager] getResourceFinder];
}
#endif

@end

//
//  AWEHDRModelManager.m
//  Pods
//
//  Created by wang ya on 2019/8/28.
//

#import "AWEHDRModelManager.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectPlatformSDK/IESEffectManager.h>
#import <EffectPlatformSDK/IESAlgorithmRecord.h>
#import <TTVideoEditor/HTSGLContext.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCMacros.h>
#import <TTVideoEditor/VEOneKeySceneStrategyConfig.h>

static NSString * const kACCHDRNormalModelName = @"lens_hdr_v1.0.model";
static NSString * const kACCHDRNightModelName = @"lens_hdrnight_v1.0.model";

@implementation AWEHDRModelManager

+ (BOOL)enableVideoHDR
{
    return  [self p_isAlgorithmModelDownloaded] && [HTSGLContext isSupportGLES30AndCreateGLESContext];
}

+ (void)downloadAlgorithmModelIfNeeded
{
    [EffectPlatform fetchResourcesWithRequirements:@[] modelNames:@{
        @"lens_video_hdr" : [AWEHDRModelManager lensHDRModelNames]} completion:^(BOOL success, NSError * _Nonnull error) {
        if (error || !success) {
            AWELogToolError(AWELogToolTagEffectPlatform, @"Effect Platfrom Download Lens Model Error: %@", error);
        }
    }];
}

+ (BOOL)p_isAlgorithmModelDownloaded
{
    if (ACC_isEmptyArray([AWEHDRModelManager lensHDRModelNames])) {
        return NO;
    }
    return [[IESEffectManager manager] isAlgorithmDownloaded:[AWEHDRModelManager lensHDRModelNames]];
}

+ (NSString *)modelNameForScene:(int)scene
{
    if ([AWEHDRModelManager useOneKeyHDR]) {
        if (scene == VEOneKeySceneCaseNight) {
            return kACCHDRNightModelName;
        } else {
            return kACCHDRNormalModelName;
        }
    } else {
        return kACCHDRNormalModelName;
    }
}

+ (NSString *)modelPathForScene:(int)scene
{
    NSDictionary<NSString *, IESAlgorithmRecord *> *pathDict = [[IESEffectManager manager] checkoutModelInfosWithRequirements:@[] modelNames:@{@"lens_video_hdr" : [AWEHDRModelManager lensHDRModelNames]}];
    IESAlgorithmRecord *algorithm = [pathDict objectForKey:[AWEHDRModelManager modelNameForScene:scene]];
    return algorithm.filePath;
}

+ (NSString *)lensModelPath
{
    NSDictionary<NSString *, IESAlgorithmRecord *> *pathDict = [[IESEffectManager manager] checkoutModelInfosWithRequirements:@[] modelNames:@{@"lens_video_hdr" : [AWEHDRModelManager lensHDRModelNames]}];
    IESAlgorithmRecord *algorithm = [pathDict objectForKey:kACCHDRNormalModelName];
    return algorithm.filePath;
}

+ (nonnull NSArray *)lensHDRModelNames
{
    NSMutableArray *modelNames = [NSMutableArray array];
    [modelNames addObject:kACCHDRNormalModelName];
    if ([AWEHDRModelManager useOneKeyHDR]) {
        [modelNames addObjectsFromArray:@[kACCHDRNightModelName]];
    }
    return [modelNames copy];
    
}

+ (BOOL)useOneKeyHDR
{
    return ACCConfigBool(kConfigBool_use_one_key_lens_hdr_denoise) || ACCConfigBool(kConfigBool_use_one_key_lens_hdr_no_denoise);
}

@end

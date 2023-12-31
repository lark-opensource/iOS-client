//
//  AWEImageEditHDRModelManager.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/8.
//

#import "AWEImageEditHDRModelManager.h"
#import "ACCConfigKeyDefines.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <TTVideoEditor/HTSGLContext.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <EffectPlatformSDK/IESEffectManager.h>
#import <EffectPlatformSDK/IESAlgorithmRecord.h>
#import <CreativeKit/ACCMacros.h>

/*
 
 目前实际上 图片 和视频 用的是同一个HDR的lens模型
 但是为什么会重新重建一个Manager？
 原因有以下两点
 1. 图片在做HDR的时候 视频还没迁移到lens模型上，后面视频迁移到lens的时候加了AB，而图片只支持lens所以不用直接复用
 2. lens HDR在最初VE接口设计的时候并不是一套，模型也不是一个，图片是多模型结构,视频是单模型结构
    而在提测都快结束的时候VE决定改为使用视频HDR的模型，所以为了改动不是很大，暂时先保留图片为独立的一套逻辑
 **/

@implementation AWEImageEditHDRModelManager

+ (BOOL)enableImageLensHDR
{
    if (!ACCConfigBool(kConfigBool_enable_images_album_publish)) {
        return NO;
    }
    return  [self didLensHDRResourcesDownloaded] && [HTSGLContext isSupportGLES30AndCreateGLESContext];
}

+ (void)downloaImageLensHDRResourceIfNeeded
{
    if (!ACCConfigBool(kConfigBool_enable_images_album_publish)) {
        return;
    }
    
    if ([self didLensHDRResourcesDownloaded]) {
        return;
    }
    
    [EffectPlatform fetchResourcesWithRequirements:@[] modelNames:[self p_hdrModelsMapping] completion:^(BOOL success, NSError * _Nonnull error) {
        if (error || !success) {
            AWELogToolError(AWELogToolTagEffectPlatform, @"Effect Platfrom Download image Lens Model Error: %@", error);
        }
    }];
}

+ (NSString *)lensHDRFilePath
{
    NSDictionary<NSString *, IESAlgorithmRecord *> *pathDict = [[IESEffectManager manager] checkoutModelInfosWithRequirements:@[] modelNames:[self p_hdrModelsMapping]];

    NSMutableArray <NSString *> *rets = [NSMutableArray array];

    [[pathDict allValues] enumerateObjectsUsingBlock:^(IESAlgorithmRecord * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!ACC_isEmptyString(obj.filePath)) {
            [rets addObject:obj.filePath];
        }
    }];
    
    if (!ACC_isEmptyArray(rets)) {
        return [rets firstObject];
    }
    return nil;
}

+ (BOOL)didLensHDRResourcesDownloaded
{
    NSArray <NSString *> *modelNames = [self lensHDRModelNames];
    if (ACC_isEmptyArray(modelNames)) {
        return NO;
    }
    return [[IESEffectManager manager] isAlgorithmDownloaded:modelNames];
}

+ (nonnull NSArray <NSString *> *)lensHDRModelNames
{
    NSString *modelName = ACCConfigString(kConfigString_image_album_lens_hdr_model_name);
    if (ACC_isEmptyString(modelName)) {
        return @[];
    }
    return @[modelName];
}

+ (NSDictionary *)p_hdrModelsMapping
{
    return @{@"lens_video_hdr" : [self lensHDRModelNames]};
}

@end

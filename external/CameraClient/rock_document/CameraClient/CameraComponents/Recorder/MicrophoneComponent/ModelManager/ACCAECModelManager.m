//
//  ACCAECModelManager.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/3/14.
//

#import "ACCAECModelManager.h"
#import <CreationKitInfra/ACCLogProtocol.h>

#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectPlatformSDK/IESEffectManager.h>
#import <EffectPlatformSDK/IESAlgorithmRecord.h>
#import <CreativeKit/ACCMacros.h>
#import <TTVideoEditor/VERecorder.h>

static NSString * const kVEAudioAECKey = @"ve_audio_aec";
static NSString * const kVEAudioDAKey = @"ve_audio_dc";
static NSString * const kVEAudioDAModel = @"time_align_44k.model";

@implementation ACCAECModelManager

+ (void)downloadAECModel
{
    if ([self hasDownloadedAECModel]) {
        return;
    }
    
    [EffectPlatform fetchResourcesWithRequirements:@[] modelNames:@{
        kVEAudioAECKey : [ACCAECModelManager AudioAECModelNames]} completion:^(BOOL success, NSError * _Nonnull error) {
        if (error || !success) {
            AWELogToolError(AWELogToolTagEffectPlatform, @"Effect Platfrom Download AEC Model Error: %@", error);
        }
    }];
}

+ (NSString *)AECModelPath
{
    NSDictionary<NSString *, IESAlgorithmRecord *> *pathDict = [[IESEffectManager manager] checkoutModelInfosWithRequirements:@[] modelNames:@{kVEAudioAECKey : [ACCAECModelManager AudioAECModelNames]}];
    IESAlgorithmRecord *algorithm = [[pathDict allValues] firstObject];
    return algorithm.filePath;
}


+ (void)downloadDAModel
{
    if ([[IESEffectManager manager] isAlgorithmDownloaded:@[kVEAudioDAModel]]) {
        return;
    }
    [EffectPlatform fetchResourcesWithRequirements:@[] modelNames:@{
        kVEAudioDAKey : @[kVEAudioDAModel]} completion:^(BOOL success, NSError * _Nonnull error) {
        if (error || !success) {
            AWELogToolError(AWELogToolTagEffectPlatform, @"Effect Platfrom Download TimeAlign Model Error: %@", error);
        }
    }];
}

+ (NSString *)DAModelPath
{
    NSDictionary<NSString *, IESAlgorithmRecord *> *pathDict = [[IESEffectManager manager] checkoutModelInfosWithRequirements:@[] modelNames:@{kVEAudioDAKey : @[kVEAudioDAModel]}];
    IESAlgorithmRecord *algorithm = [[pathDict allValues] firstObject];
    return algorithm.filePath;
}

#pragma mark - private help methods

+ (nonnull NSArray *)AudioAECModelNames
{
    NSString *modelName = [VERecorder aecModelName];
    if (ACC_isEmptyString(modelName)) {
        return @[];
    }
    return @[modelName];
}

+ (BOOL)hasDownloadedAECModel
{
    if (ACC_isEmptyString([VERecorder aecModelName])) {
        return NO;
    }
    return [[IESEffectManager manager] isAlgorithmDownloaded:[ACCAECModelManager AudioAECModelNames]];
}

@end

//
//  ACCEditVideoDataConsumer.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/14.
//

#import "ACCEditVideoDataConsumer.h"
#import "ACCEditVideoDataDowngrading.h"
#import "HTSVideoData+AWEPersistent.h"
#import <TTVideoEditor/HTSVideoData+CacheDirPath.h>
#import <TTVideoEditor/IESVideoVolumConvert.h>
#import <TTVideoEditor/IESAudioVolumConvert.h>
#import <TTVideoEditor/HTSVideoData+Dictionary.h>
#import <CreationKitInfra/ACCCommonDefine.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <TTVideoEditor/AVAsset+Utils.h>
#import "ACCEditCompileSession.h"
#import "NLEEditor_OC+Extension.h"

#import <NLEPlatform/NLEAudioSession.h>
#import <NLEPlatform/NLEExportSession.h>
#import <NLEPlatform/HTSVideoData+Converter.h>

@implementation ACCEditVideoDataConsumer

+ (void)restartReverseAssetForVideoData:(ACCEditVideoData *)videoData
                             completion:(nonnull void (^)(void))completion
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        __block VEReverseUnit *reverseUnit = [[VEReverseUnit alloc] initWithVideoData:videoData];
        [reverseUnit restartReverseAsset:^(BOOL success, AVAsset * _Nullable reverseAsset, NSError * _Nullable error) {
            !completion ?: completion();
            reverseUnit = nil;
        }];
    }, ^(ACCNLEEditVideoData *videoData) {
        [videoData.nle.exportSession restartReverseAsset:^(BOOL success, AVAsset * _Nullable reverseAsset, NSError * _Nullable error) {
            !completion ?: completion();
        }];
    });
}

+ (void)getVolumnWaveWithVideoData:(ACCEditVideoData *)videoData
                       pointsCount:(NSUInteger)pointsCount
                        completion:(void (^)(NSArray * _Nullable values, NSError * _Nullable error))completion
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData * _Nonnull videoData) {
        IESVideoVolumConvertConfig* config = [[IESVideoVolumConvertConfig alloc] init];
        config.type = WaveformTypeMAX;
        config.videoData = videoData;
        config.pointsCount = pointsCount;
        NSError *error;
        IESVideoVolumConvert *convertor = [[IESVideoVolumConvert alloc] initWithConfig:config error:&error];
        if (!error) {
            [convertor startProcess:completion];
        } else {
            !completion ?: completion(nil, error);
        }
    }, ^(ACCNLEEditVideoData *videoData) {
        [videoData.nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
            [[videoData.nle audioSession] getVolumnWaveForVideoWithPointsCount:pointsCount
                                                                    completion:completion];
        }];
    });
}

+ (NSArray *)getVolumnWaveWithAudioURL:(NSURL *)audioURL
                      waveformduration:(CGFloat)waveformduration
                           pointsCount:(NSUInteger)pointsCount
{
    IESAudioVolumConvertConfig* config = [[IESAudioVolumConvertConfig alloc] init];
    config.type = WaveformTypeMAX;
    config.waveformduration = waveformduration;
    config.pointsCount = pointsCount;
    config.audioURL = audioURL;
    IESAudioVolumConvert *converter = [[IESAudioVolumConvert alloc] initWithConfig:config];
    return [converter getVolumePoints];
}

+ (void)saveVideoData:(ACCEditVideoData *)videoData
toFileUsePropertyListSerialization:(NSString *)filePath
           completion:(void (^)(BOOL, NSError * _Nullable))completion
{
    if (!videoData) {
        !completion ?: completion(NO, nil);
        return;
    }
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        [videoData saveVideoDataToFileUsePropertyListSerialization:filePath completion:completion];
    }, ^(ACCNLEEditVideoData *videoData) {
        [videoData moveResourceToDraftFolder:videoData.draftFolder];
        [videoData beginEdit];
        [videoData.nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
            HTSVideoData *veVideoData = acc_videodata_take_hts(videoData);
            [veVideoData saveVideoDataToFileUsePropertyListSerialization:filePath completion:completion];
        }];
    });
}

+ (BOOL)saveDictionaryToPath:(NSString *)path
                        dict:(NSDictionary *)dict
                       error:(NSError *__autoreleasing  _Nullable *)error
{
    return [HTSVideoData saveDictionaryToPath:path dict:dict error:error];
}

+ (NSDictionary *)readDictionaryFromPath:(NSString *)path error:(NSError *__autoreleasing  _Nullable *)error
{
    return [HTSVideoData readDictionaryFromPath:path error:error];
}

+ (void)loadVideoDataFromDictionary:(NSDictionary *)dataDict
                        draftFolder:(NSString *)draftFolder
                         completion:(nullable void (^)(ACCEditVideoData *_Nullable videoData, NSError *_Nullable error))completion
{
    [HTSVideoData loadVideoDataFromDictionary:dataDict fileFolder:draftFolder completion:^(HTSVideoData * _Nullable videoData, NSError * _Nullable error) {
        !completion ?: completion([ACCVEVideoData videoDataWithVideoData:videoData draftFolder:draftFolder], error);
    }];
}

+ (void)loadVideoDataFromFile:(NSString *)filePath
                   completion:(void (^)(ACCEditVideoData * _Nullable, NSError * _Nullable))completion
{
    [HTSVideoData loadVideoDataFromFile:filePath completion:^(HTSVideoData * _Nullable videoData, NSError * _Nullable error) {
        !completion ?: completion([ACCVEVideoData videoDataWithVideoData:videoData draftFolder:filePath], error);
    }];
}

+ (void)setCacheDirPath:(NSString *)cacheDirPath
{
    [HTSVideoData setCacheDirPath:cacheDirPath];
}

+ (BOOL)isCacheDirPathSetted
{
    return [HTSVideoData isCacheDirPathSetted];
}

+ (NSString *)cacheDirPath
{
    return [HTSVideoData cacheDirPath];
}

+ (NSString *)defaultCachePath
{
    NSString *dirPath = [HTSVideoData defaultCacheDirPath];
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDirectory]) {
        NSError *createDirectoryError;
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&createDirectoryError];
        if (createDirectoryError) {
            NSError *attributeError;
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:dirPath error:&attributeError];
            AWELogToolError2(@"cache", AWELogToolTagDraft, @"draft root directory attributes:%@, isDirectory:%@, failed with attributeError:%@, createDirectoryError:%@", attributes, @(isDirectory), attributeError, createDirectoryError);
        }
    }
    return dirPath;
}

+ (void)clearAllCache
{
    [HTSVideoData clearAllCache];
}

+ (BOOL)isPlaceholderVideoAssets:(AVAsset *)asset
{
    if ([asset isBlankVideo]) {
        return YES;
    }
    
    if (![asset isKindOfClass:[AVURLAsset class]]) {
        return NO;
    }
    
    NSString *assetPath = ((AVURLAsset *)asset).URL.absoluteString;
    return [assetPath containsString:@"IESPhoto.bundle/blankown2.mp4"] ||
        [assetPath containsString:@"blank_0x"];
}

@end

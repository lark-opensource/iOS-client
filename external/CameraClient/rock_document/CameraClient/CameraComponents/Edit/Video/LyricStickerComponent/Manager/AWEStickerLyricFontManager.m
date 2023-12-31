//
//  AWEStickerLyricFontManager.m
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2019/10/8.
//

#import "AWEStickerLyricFontManager.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CameraClient/ACCConfigKeyDefines.h>

NSString * const AWEStickerLyricFontPanelStr = @"lyricstylefont";
NSString * const AWEStickerLyricFontExtraKey = @"LinkLyricsStyle";
NSErrorDomain const AWEStickerLyricFontManagerErrorDomain = @"com.AWEStickerLyricFontManager.ErrorDomain";

@implementation AWEStickerLyricFontManager

+ (IESEffectModel *)effectModelWithFontName:(NSString *)fontName
{
    IESEffectPlatformResponseModel *responseModel = [EffectPlatform cachedEffectsOfPanel:AWEStickerLyricFontPanelStr];
    BOOL hasValidCache = responseModel.effects.count > 0;
    if (!hasValidCache) {
        return nil;
    }
    for (IESEffectModel *effectModel in responseModel.effects) {
        NSString *extraFontName = [self formatFontDicWithJSONStr:effectModel.extra key:AWEStickerLyricFontExtraKey];
        if ([extraFontName isEqualToString:fontName]) {
            return effectModel;
        }
    }
    return nil;
}

+ (void)downloadLyricFontIfNeeded
{
    IESEffectPlatformResponseModel *responseModel = [EffectPlatform cachedEffectsOfPanel:AWEStickerLyricFontPanelStr];
    BOOL hasValidCache = responseModel.effects.count > 0;
    [EffectPlatform checkEffectUpdateWithPanel:AWEStickerLyricFontPanelStr effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        if (needUpdate || !hasValidCache) {
            [EffectPlatform downloadEffectListWithPanel:AWEStickerLyricFontPanelStr saveCache:YES completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                if (response && response.effects.count > 0) {
                    for (IESEffectModel *effectModel in response.effects) {
                        [self downloadLyricFontWithEffectModel:effectModel completion:nil];
                    }
                }
            }];
        }
    }];
}

+ (void)fetchLyricFontResourceWithFontName:(NSString *)fontName completion:(void (^)(NSError *, NSString *))completion
{
    if (!fontName || fontName.length <= 0) {
        NSError *error = [NSError errorWithDomain:AWEStickerLyricFontManagerErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"font name can not be nil"}];
        ACCBLOCK_INVOKE(completion, error, nil);
        return;
    }
    [self fetchLyricFontEffectModelsWithCompletion:^(NSError * error, NSArray<IESEffectModel *> * effects) {
        if (error) {
            ACCBLOCK_INVOKE(completion, error, nil);
        } else {
            BOOL findEffectModel = NO;
            for (IESEffectModel *effectModel in effects) {
                NSString *extraFontName = [self formatFontDicWithJSONStr:effectModel.extra key:AWEStickerLyricFontExtraKey];
                if ([extraFontName isEqualToString:fontName]) {
                    findEffectModel = YES;
                    if (effectModel.downloaded) {
                        ACCBLOCK_INVOKE(completion, nil, effectModel.filePath);
                    } else {
                        [self downloadLyricFontWithEffectModel:effectModel completion:completion];
                    }
                    break;
                }
            }
            if (!findEffectModel) {
                NSError *error = [NSError errorWithDomain:AWEStickerLyricFontManagerErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"can not find font resource"}];
                ACCBLOCK_INVOKE(completion, error, nil);
            }
        }
    }];
}

+ (void)fetchLyricFontEffectModelsWithCompletion:(void (^)(NSError *, NSArray<IESEffectModel *> * _Nonnull))completion
{
    IESEffectPlatformResponseModel *responseModel = [EffectPlatform cachedEffectsOfPanel:AWEStickerLyricFontPanelStr];
    BOOL hasValidCache = responseModel.effects.count > 0;
    [EffectPlatform checkEffectUpdateWithPanel:AWEStickerLyricFontPanelStr effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        if (!needUpdate && hasValidCache) {
            ACCBLOCK_INVOKE(completion, nil, responseModel.effects);
        } else {
            [EffectPlatform downloadEffectListWithPanel:AWEStickerLyricFontPanelStr completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                ACCBLOCK_INVOKE(completion, error, response.effects);
            }];
        }
    }];
}

+ (void)downloadLyricFontWithEffectModel:(IESEffectModel *)effectModel completion:(void (^)(NSError *, NSString *))completion
{
    if (effectModel.filePath && [[NSFileManager defaultManager] fileExistsAtPath:effectModel.filePath]) {
        ACCBLOCK_INVOKE(completion, nil, effectModel.filePath);
    } else {
        CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
        [EffectPlatform downloadEffect:effectModel progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
            NSDictionary *extraInfo = @{@"effect_id" : effectModel.effectIdentifier ?: @"",
                                        @"effect_name" : effectModel.effectName ?: @"",
                                        @"download_urls" : [effectModel.fileDownloadURLs componentsJoinedByString:@";"] ?: @"",
                                        @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
            };
            if (!error && filePath) {
                [ACCMonitor() trackService:@"aweme_type_download_font_rate"
                                 status:0
                                  extra:extraInfo];
            } else {
                [ACCMonitor() trackService:@"aweme_type_download_font_rate"
                                 status:1
                                  extra:extraInfo];
            }
            ACCBLOCK_INVOKE(completion, error, filePath);
        }];
    }
}

+ (nullable NSString *)formatFontDicWithJSONStr:(NSString *)strExtra
{
    return [self formatFontDicWithJSONStr:strExtra key:AWEStickerLyricFontExtraKey];
}

+ (nullable NSString *)formatFontDicWithJSONStr:(NSString *)strExtra key:(NSString *)key
{
    NSData *jsonData = [strExtra dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData) {
        NSError *jsonError;
        NSDictionary *extraDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&jsonError];
        if (jsonError) {
            AWELogToolError(AWELogToolTagDraft, @"%s %@", __PRETTY_FUNCTION__, jsonError);
        }
        return [extraDictionary acc_stringValueForKey:key];
    } else {
        return nil;
    }
}

@end

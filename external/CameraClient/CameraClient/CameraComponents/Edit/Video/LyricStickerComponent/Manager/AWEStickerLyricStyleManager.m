//
//  AWEStickerLyricStyleManager.m
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2019/10/8.
//

#import "AWEStickerLyricStyleManager.h"
#import <CreativeKit/ACCMacros.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CameraClient/ACCConfigKeyDefines.h>

NSString * const AWEStickerLyricStylePanelStr = @"lyricstyle";
NSString * const AWEStickerKaraokeLyricStylePanelStr = @"lyrics";
NSString * const AWEStickerKaraokeAudioBGPanelName = @"background";
NSString * const AWEStickerKaraokeAudioEffectPanelName = @"reverberation";
NSString * const AWEKaraokeLyricFontNameId = @"KaraokeFontId";
NSString * const AWEKaraokeLyricInfoStyleKey = @"KaraokeTitleId";
NSString * const AWELyricStyleDefaultColorKey = @"LyricsStyleDefaultColor";

@implementation AWEStickerLyricStyleManager

+ (IESEffectModel * _Nullable)cachedEffectModelForEffectID:(NSString *)effectID panel:(NSString *)panel
{
    IESEffectPlatformResponseModel *responseModel = [EffectPlatform cachedEffectsOfPanel:panel];
    if (responseModel == nil) {
        return nil;
    }
    for (IESEffectModel *effectModel in responseModel.effects) {
        if ([effectModel.effectIdentifier isEqualToString:effectID]) {
            return effectModel;
        }
    }
    return nil;
}

+ (void)fetchOrQueryCachedLyricRelatedEffectList:(NSString *)panel completion:(void (^)(NSError *, NSArray<IESEffectModel *> *))completion
{
    IESEffectPlatformResponseModel *responseModel = [EffectPlatform cachedEffectsOfPanel:panel];
    BOOL hasValidCache = responseModel.effects.count > 0;
    [EffectPlatform checkEffectUpdateWithPanel:panel effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        if (!needUpdate && hasValidCache) {
            ACCBLOCK_INVOKE(completion, nil, responseModel.effects);
        } else {
            [EffectPlatform downloadEffectListWithPanel:panel completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                if (error || response.effects.count == 0) {
                    if (hasValidCache) {
                        ACCBLOCK_INVOKE(completion, nil, responseModel.effects);
                    } else {
                        ACCBLOCK_INVOKE(completion, error, nil);
                    }
                } else {
                    ACCBLOCK_INVOKE(completion, nil, response.effects);
                }
            }];
        }
    }];
}

@end

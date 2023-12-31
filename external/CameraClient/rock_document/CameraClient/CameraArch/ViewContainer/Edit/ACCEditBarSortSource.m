//
//  ACCEditBarSortSource.m
//  CameraClient
//
//  Created by wishes on 2020/6/4.
//

#import "ACCEditBarSortSource.h"
#import "ACCVideoEditToolBarDefinition.h"
#import <CameraClient/ACCConfigKeyDefines.h>

@implementation ACCEditBarSortSource

- (NSArray *)barItemSortArray {
    if (ACCConfigInt(kConfigInt_editor_toolbar_optimize) != ACCStoryEditorOptimizeTypeNone) {
        return @[
            [NSValue valueWithPointer:ACCEditToolBarRedpacketContext],
            [NSValue valueWithPointer:ACCEditToolBarNewYearModuleContext],
            [NSValue valueWithPointer:ACCEditToolBarNewYearTextContext],
            [NSValue valueWithPointer:ACCEditToolBarKaraokeConfigContext],
            [NSValue valueWithPointer:ACCEditToolBarKaraokeBGConfigContext],
            [NSValue valueWithPointer:ACCEditToolBarPublishSettingsContext],
            [NSValue valueWithPointer:ACCEditToolBarQuickSaveDraftContext],
            [NSValue valueWithPointer:ACCEditToolBarQuickSavePrivateContext],
            [NSValue valueWithPointer:ACCEditToolBarQuickSaveAlbumContext],
            [NSValue valueWithPointer:ACCEditToolBarMusicContext],
            [NSValue valueWithPointer:ACCEditToolBarSelectTemplateContext],
            [NSValue valueWithPointer:ACCEditToolBarImage2VideoContext],
            [NSValue valueWithPointer:ACCEditToolBarVideo2ImageContext],
            [NSValue valueWithPointer:ACCEditToolBarTagsContext],
            [NSValue valueWithPointer:ACCEditToolBarCropImageContext],
            [NSValue valueWithPointer:ACCEditToolBarSmartMovieContext],
            [NSValue valueWithPointer:ACCEditToolBarTextContext],
            [NSValue valueWithPointer:ACCEditToolBarInfoStickerContext],
            [NSValue valueWithPointer:ACCEditToolBarEffectContext],
            [NSValue valueWithPointer:ACCEditToolBarFilterContext],
            [NSValue valueWithPointer:ACCEditToolBarBeautyContext],
            [NSValue valueWithPointer:ACCEditToolBarSoundContext],
            [NSValue valueWithPointer:ACCEditToolBarMeteorModeContext],
            //folded
            [NSValue valueWithPointer:ACCEditToolBarAutoCaptionContext],
            [NSValue valueWithPointer:ACCEditToolBarVideoEnhanceContext],
            [NSValue valueWithPointer:ACCEditToolBarClipContext],
            [NSValue valueWithPointer:ACCEditToolBarVoiceChangeContext],
            [NSValue valueWithPointer:ACCEditToolBarMusicCutContext],
            [NSValue valueWithPointer:ACCEditToolBarVideoDubContext],
        ];
    }
    return @[
        [NSValue valueWithPointer:ACCEditToolBarRedpacketContext],
        [NSValue valueWithPointer:ACCEditToolBarNewYearModuleContext],
        [NSValue valueWithPointer:ACCEditToolBarNewYearTextContext],
        [NSValue valueWithPointer:ACCEditToolBarKaraokeConfigContext],
        [NSValue valueWithPointer:ACCEditToolBarKaraokeBGConfigContext],
        [NSValue valueWithPointer:ACCEditToolBarPublishSettingsContext],
        [NSValue valueWithPointer:ACCEditToolBarQuickSaveDraftContext],
        [NSValue valueWithPointer:ACCEditToolBarQuickSavePrivateContext],
        [NSValue valueWithPointer:ACCEditToolBarQuickSaveAlbumContext],
        [NSValue valueWithPointer:ACCEditToolBarStatusBgImageContext],
        [NSValue valueWithPointer:ACCEditToolBarMusicContext],
        [NSValue valueWithPointer:ACCEditToolBarSelectTemplateContext],
        [NSValue valueWithPointer:ACCEditToolBarImage2VideoContext],
        [NSValue valueWithPointer:ACCEditToolBarVideo2ImageContext],
        [NSValue valueWithPointer:ACCEditToolBarTagsContext],
        [NSValue valueWithPointer:ACCEditToolBarCropImageContext],
        [NSValue valueWithPointer:ACCEditToolBarSmartMovieContext],
        [NSValue valueWithPointer:ACCEditToolBarEffectContext],
        [NSValue valueWithPointer:ACCEditToolBarTextContext],
        [NSValue valueWithPointer:ACCEditToolBarInfoStickerContext],
        
        [NSValue valueWithPointer:ACCEditToolBarFilterContext],
        [NSValue valueWithPointer:ACCEditToolBarBeautyContext],
        [NSValue valueWithPointer:ACCEditToolBarClipContext],
        [NSValue valueWithPointer:ACCEditToolBarVideoEnhanceContext],
        [NSValue valueWithPointer:ACCEditToolBarVoiceChangeContext],
        [NSValue valueWithPointer:ACCEditToolBarVideoDubContext],
        [NSValue valueWithPointer:ACCEditToolBarAutoCaptionContext],
        [NSValue valueWithPointer:ACCEditToolBarMusicCutContext],
        [NSValue valueWithPointer:ACCEditToolBarSoundContext],
        [NSValue valueWithPointer:ACCEditToolBarMeteorModeContext],
    ];
}

@end

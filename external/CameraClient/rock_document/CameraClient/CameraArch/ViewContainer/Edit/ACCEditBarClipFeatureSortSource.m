//
//  ACCEditBarClipFeatureSortSource.m
//  CameraClient-Pods-Aweme
//
//  Created by lixingdong on 2020/11/20.
//

#import "ACCEditBarClipFeatureSortSource.h"
#import "ACCVideoEditToolBarDefinition.h"
#import <CameraClient/ACCConfigKeyDefines.h>

@implementation ACCEditBarClipFeatureSortSource

- (NSArray *)barItemSortArray {
    if (ACCConfigInt(kConfigInt_editor_toolbar_optimize) != ACCStoryEditorOptimizeTypeNone) {
        return @[
            [NSValue valueWithPointer:ACCEditToolBarRedpacketContext],
            [NSValue valueWithPointer:ACCEditToolBarPublishSettingsContext],
            [NSValue valueWithPointer:ACCEditToolBarQuickSaveDraftContext],
            [NSValue valueWithPointer:ACCEditToolBarQuickSavePrivateContext],
            [NSValue valueWithPointer:ACCEditToolBarQuickSaveAlbumContext],
            [NSValue valueWithPointer:ACCEditToolBarClipContext],
            [NSValue valueWithPointer:ACCEditToolBarSelectTemplateContext],
            [NSValue valueWithPointer:ACCEditToolBarMusicContext],
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
            [NSValue valueWithPointer:ACCEditToolBarVoiceChangeContext],
            [NSValue valueWithPointer:ACCEditToolBarMusicCutContext],
            [NSValue valueWithPointer:ACCEditToolBarVideoDubContext],
        ];
    }
    return @[
        [NSValue valueWithPointer:ACCEditToolBarRedpacketContext],
        [NSValue valueWithPointer:ACCEditToolBarPublishSettingsContext],
        [NSValue valueWithPointer:ACCEditToolBarQuickSaveDraftContext],
        [NSValue valueWithPointer:ACCEditToolBarQuickSavePrivateContext],
        [NSValue valueWithPointer:ACCEditToolBarQuickSaveAlbumContext],
        [NSValue valueWithPointer:ACCEditToolBarClipContext],
        [NSValue valueWithPointer:ACCEditToolBarSelectTemplateContext],
        [NSValue valueWithPointer:ACCEditToolBarStatusBgImageContext],
        [NSValue valueWithPointer:ACCEditToolBarMusicContext],
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

//
//  ACCEditBarIMSortSource.m
//  CameraClient-Pods-Aweme
//
//  Created by Lincoln on 2020/11/24.
//

#import "ACCEditBarIMSortSource.h"
#import "ACCVideoEditToolBarDefinition.h"

@implementation ACCEditBarIMSortSource

- (NSArray *)barItemSortArray {
    return @[
        [NSValue valueWithPointer:ACCEditToolBarMusicContext],
        [NSValue valueWithPointer:ACCEditToolBarTextContext],
        [NSValue valueWithPointer:ACCEditToolBarInfoStickerContext],
        [NSValue valueWithPointer:ACCEditToolBarEffectContext],
        [NSValue valueWithPointer:ACCEditToolBarFilterContext],
        [NSValue valueWithPointer:ACCEditToolBarBeautyContext],
        [NSValue valueWithPointer:ACCEditToolBarSoundContext],
        //folded
        [NSValue valueWithPointer:ACCEditToolBarAutoCaptionContext],
        [NSValue valueWithPointer:ACCEditToolBarVideoEnhanceContext],
        [NSValue valueWithPointer:ACCEditToolBarClipContext],
        [NSValue valueWithPointer:ACCEditToolBarVoiceChangeContext],
        [NSValue valueWithPointer:ACCEditToolBarMusicCutContext],
        [NSValue valueWithPointer:ACCEditToolBarVideoDubContext],
    ];

}

@end

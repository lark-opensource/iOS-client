//
//  ACCLyricsStickerUpdateFramePlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2020/12/6.
//

#import "ACCLyricsStickerUpdateFramePlugin.h"
#import "ACCInfoStickerContentView.h"
#import "ACCLyricsStickerContentView.h"
#import "ACCLyricsStickerUtils.h"

#import <CreativeKitSticker/ACCStickerProtocol.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>

@implementation ACCLyricsStickerUpdateFramePlugin
@synthesize stickerContainer = _stickerContainer;

+ (instancetype)createPlugin
{
    return [[ACCLyricsStickerUpdateFramePlugin alloc] init];
}

- (void)loadPlugin
{
}

- (void)playerFrameChange:(CGRect)playerFrame
{
}

- (BOOL)featureSupportSticker:(nonnull id<ACCStickerProtocol>)sticker { 
    if (![sticker.config isKindOfClass:[ACCCommonStickerConfig class]]) {
        return NO;
    }
    return ACCStickerContainerFeatureLyricsUpdateFrame & ((ACCCommonStickerConfig *)sticker.config).preferredContainerFeature;
}

- (void)stickerContainer:(UIView<ACCStickerContainerProtocol> *)container beforeRecognizerGesture:(UIGestureRecognizer *)gesture
{
    // 更新歌词贴纸 frame，只需要更新歌词本身，歌名等不需要
    [[self.stickerContainer.allStickerViews btd_filter:^BOOL(ACCStickerViewType  _Nonnull obj) {
        return [obj.contentView isKindOfClass:ACCLyricsStickerContentView.class] && !((ACCLyricsStickerContentView *)obj.contentView).ignoreUpdateFrameWithGesture;
    }] btd_forEach:^(ACCStickerViewType  _Nonnull obj) {
        [ACCLyricsStickerUtils updateFrameForLyricsStickerWrapperView:obj editStickerService:self.editStickerService];
    }];
}

@end

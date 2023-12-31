//
//  ACCVideoEditTipsViewModel.h
//  CameraClient-Pods-DouYin
//
//  Created by chengfei xiao on 2020/8/6.
//

#import <Foundation/Foundation.h>
#import "ACCEditViewModel.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import "AWEVideoEditDefine.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const kAWENormalVideoEditHasMusicLyricBubbleShowKey;
FOUNDATION_EXTERN NSString *const kAWENormalVideoEditNoMusicLyricBubbleShowKey;
FOUNDATION_EXTERN NSString *const kAWENormalVideoEditDonationBubbleShowKey;
FOUNDATION_EXTERN NSString *const kAWENormalVideoEditCustomBubbleShowKey;
FOUNDATION_EXTERN NSString *const kAWENormalVideoEditLiveStickerBubbleShowKey;
FOUNDATION_EXTERN NSString *const kAWENormalVideoEditGrootStickerBubbleShowKey;
FOUNDATION_EXTERN NSString *const kAWENormalVideoEditKaraokeStickerBubbleShowKey;
FOUNDATION_EXTERN NSString *const kAWENormalVideoEditClipAtShareToStorySceneBubbleShowKey;
FOUNDATION_EXTERN NSString *const kAWENormalVideoEditNewYearWishBubbleShowKey;

@interface ACCVideoEditTipsViewModel : ACCEditViewModel

@property (nonatomic, assign) BOOL isVCAppeared;
@property (nonatomic, assign) BOOL isNormalVideoCanShowMusicStickerBubble;

- (BOOL)allowShowLyricStickerBubble;
#pragma mark 是否显示分享到日常场景剪裁 bubble
- (BOOL)allowShowClipAtShareToStorySceneBubble;

@end

NS_ASSUME_NONNULL_END

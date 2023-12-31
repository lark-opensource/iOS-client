//
//  ACCEditAndPublishConstants.h
//  Pods
//
//  Created by chengfei xiao on 2019/10/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


#ifndef kAWEVideoNewPublishViewControllerWillDismissNotification
#define kAWEVideoNewPublishViewControllerWillDismissNotification @"kAWEVideoNewPublishViewControllerWillDismissNotification"
#endif


#define kEffectSDK_GIFFormatError -301
#define kEffectSDK_GIFReadError   -302


#define kAWEEditAndPublishVCMusicButtonId               @"kAWEEditAndPublishVCMusicButtonId"
#define kAWEEditAndPublishVCMusicCutButtonId            @"kAWEEditAndPublishVCMusicCutButtonId"
#define kAWEEditAndPublishVCSoundButtonId               @"kAWEEditAndPublishVCSoundButtonId"
#define KAWEEditAndPublishVCVideoEnhanceId              @"KAWEEditAndPublishVCVideoEnhanceId"
#define kAWEEditAndPublishVCInfoStickerButtonId         @"kAWEEditAndPublishVCInfoStickerButtonId"
#define kAWEEditAndPublishVCVoiceChangeButtonId         @"kAWEEditAndPublishVCVoiceChangeButtonId"
#define kAWEEditAndPublishVCAutoCaptionButtonId         @"kAWEEditAndPublishVCAutoCaptionButtonId"
#define kAWENormalVideoEditAndPublishVCEffectButtonId   @"kAWENormalVideoEditAndPublishVCEffectButtonId"
#define kAWEEditAndPublishVCPhotoMovieTransitionButton  @"kAWEEditAndPublishVCPhotoMovieTransitionButton"
#define kAWEEditAndPublishVCVideoDubButtonId            @"kAWEEditAndPublishVCVideoDubButtonId"
#define kAWEEditAndPublishVCTextButtonId                @"kAWEEditAndPublishVCTextButtonId"

FOUNDATION_EXTERN  NSString * const kACCStickerIDKey;
FOUNDATION_EXTERN  NSString * const kACCStickerGroupIDKey;
FOUNDATION_EXTERN  NSString * const kACCStickerSupportedGestureTypeKey;
FOUNDATION_EXTERN  NSString * const kACCStickerMinimumScaleKey;
FOUNDATION_EXTERN  NSString * const kACCGrootModelResultKey;
FOUNDATION_EXTERN  NSString * const kACCTextLocationModelKey;
FOUNDATION_EXTERN  NSString * const kACCPOIStickerLocationKey;
FOUNDATION_EXTERN  NSString * const kTextLocationModelForCompositionKey;
FOUNDATION_EXTERN  NSString * const kACCTextInfoModelKey;
FOUNDATION_EXTERN  NSString * const kACCTextInfoTextStickerIdKey;
FOUNDATION_EXTERN  NSString * const kACCTextInfoTextStickerContentKey;
FOUNDATION_EXTERN  NSString * const kACCTextInfoTextStickerStartTimeKey;
FOUNDATION_EXTERN  NSString * const kACCTextInfoTextStickerDurationKey;
FOUNDATION_EXTERN  NSString * const kACCPublishFailedDraftDeleteNotification;
FOUNDATION_EXTERN  NSString * const kACCAwemeDraftUpdateNotification;
FOUNDATION_EXTERN  NSString * const ACCEffectIdentifierKey;
FOUNDATION_EXTERN  NSString * const kACCStickerUUIDKey;
FOUNDATION_EXTERN  NSString * const ACCCustomStickerFramesKey;
FOUNDATION_EXTERN  NSString * const ACCInteractionStickerTransferKey;
FOUNDATION_EXTERN  NSString * const ACCCrossPlatformiOSResourcePathKey;
FOUNDATION_EXTERN  NSString * const kACCDonationStickerLocationKey;

typedef NS_ENUM(NSUInteger, AWEEditPageMusicPanelOptimType) {
    AWEEditPageMusicPanelOptimTypeOriginal = 0, ///< online default style
    AWEEditPageMusicPanelOptimTypeNewUIOnly,    ///< new UI only
    AWEEditPageMusicPanelOptimTypeNewUIAndCollection    ///< new UI + collect songs
};

FOUNDATION_EXTERN NSString *const ACCCanvasInteractionGuideShowDateKey;

NS_ASSUME_NONNULL_END

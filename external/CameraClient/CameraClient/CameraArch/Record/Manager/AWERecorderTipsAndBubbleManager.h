//
//  AWERecorderTipsAndBubbleManager.h
//  Pods
//
//  Created by chengfei xiao on 2019/6/12.
//  拍摄页提示优化（dmt需求）https://wiki.bytedance.net/pages/viewpage.action?pageId=349504573

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import "ACCBubbleProtocol.h"
#import <CreationKitArch/ACCMusicModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN
@class AWEVideoHintView, AWEStickerHintView, IESEffectModel, ACCPropRecommendMusicView, ACCMusicRecommendPropBubbleView;

@class AWEVideoPublishViewModel;

typedef NS_OPTIONS(NSUInteger, AWERecoderHintsDismissOptions) {
    AWERecoderHintsDismissNone                  = 0,
    AWERecoderHintsDismissFilterHint            = 1 << 0,
    AWERecoderHintsDismissPropHint              = 1 << 1,
    AWERecoderHintsDismissMusicBubble           = 1 << 2,
    AWERecoderHintsDismissPropMusicBubble       = 1 << 4,
    AWERecoderHintsDismissMusicPropBubble       = 1 << 8,
    AWERecoderHintsDismissImageAlbumGuideView   = 1 << 9,
    AWERecoderHintsDismissDuetWithPropBubble    = 1 << 10,
    AWERecoderHintsDismissAlbumNewContentBubble = 1 << 11,
    AWERecoderHintsDismissDuetLayoutBubble      = 1 << 12,
    AWERecoderHintsDismissRecognitionBubble     = 1 << 13,
    AWERecoderHintsDismissZoomScaleView         = 1 << 14,
};

typedef void(^ACCDismissMusicRecommendPropBubbleBlock)(void);

FOUNDATION_EXTERN NSString * const kACCMoreBubbleShowKey;
FOUNDATION_EXTERN NSString * const kACCImageAlbumGuideShowKey;
FOUNDATION_EXTERN NSString * const kACCMusicRecommendPropBubbleFrequencyDictKey;
FOUNDATION_EXTERN NSString * const kACCMusicRecommendPropIDKey;
FOUNDATION_EXTERN NSString * const kACCDuetGreenScreenHintViewShowKey;

@interface AWERecorderTipsAndBubbleManager : NSObject
@property (nonatomic, readonly) AWEVideoHintView *filterHint;
@property (nonatomic, readonly) UIView *musicBubble;
@property (nonatomic, readonly) UIView *moreBubble;
@property (nonatomic, readonly) AWEStickerHintView *propHintView;
@property (nonatomic, assign) BOOL needShowDuetWithPropBubble;

//拍摄按钮实际模式，MT音乐版权限制会导致 [ACC_VIDEO_CONFIG_Obj currentVideoLenthMode] 跟按钮实际选中的模式不一致
@property (nonatomic,   assign) ACCRecordLengthMode actureRecordBtnMode;

+ (instancetype)shareInstance;

//filter hint
- (void)showFilterHintWithContainer:(nonnull UIView *)container
                         filterName:(nonnull NSString *)filterName
                       categoryName:(nonnull NSString *)catetoryName;
- (void)removefilterHint;

// multi-camera zoom
- (void)showZoomScaleHintViewWithContainer:(nonnull UIView *)containerView zoomScale:(CGFloat)zoomScale isGestureEnd:(BOOL)isGestureEnd;
- (void)removeZoomScaleHintView;

//music bubble
- (void)showMusicTimeBubbleWithPublishModel:(AWEVideoPublishViewModel *)publishModel forView:(UIView *)musicView bubbleStr:(NSString *)str;
- (void)removeMusicBubble;

- (void)showPropRecommendMusicBubbleForTargetView:(UIView *)targetView
                                            music:(id<ACCMusicModelProtocol>)music
                                     publishModel:(AWEVideoPublishViewModel *)publishModel
                                        direction:(ACCBubbleDirection)dir
                                      contentView:(ACCPropRecommendMusicView *)contentView
                                    containerView:(UIView *)containerView
                            withDismissCompletion:(void(^)(void))completion;

- (void)removePropRecommendMusicBubble;

- (void)showMusicRecommendPropBubbleForTargetView:(UIView *)targetView
                                       bubbleView:(ACCMusicRecommendPropBubbleView *)bubbleView
                                    containerView:(UIView *)containerView
                                        direction:(ACCBubbleDirection)direction
                               bubbleDismissBlock:(ACCDismissMusicRecommendPropBubbleBlock)dismissBlock;

- (BOOL)shouldShowMusicRecommendPropBubbleWithInputData:(ACCRecordViewControllerInputData *)inputData isShowingPanel:(BOOL)isShowingPanel;

- (NSString *)calculateCurrentTimeZoneDateFormatString;

- (void)removeMusicRecommendPropBubble;

- (void)dismissMusicRecommendPropBubbleAndUpdatePropIcon;

- (void)removeBubbleAndHintIfNeeded;

// duet with prop bubble
- (void)showDuetWithPropBubbleForTargetView:(UIView *)targetView
                                 bubbleView:(ACCMusicRecommendPropBubbleView *)bubbleView
                              containerView:(UIView *)containerView
                                  direction:(ACCBubbleDirection)direction
                         bubbleDismissBlock:(nullable void(^)(void))dismissBlock;
- (void) removeDuetWithPropBubble;
- (BOOL)shouldShowDuetWithPropBubbleWithInputData:(ACCRecordViewControllerInputData *)inputData;

// image album guide bubble
- (BOOL)showImageAlbumEditGuideIfNeededForView:(UIView *)targetView containerView:(UIView *)containerView;
- (BOOL)isImageAlbumGuideShowing;
- (void)removeImageAlbumEditGuide;

// more bubble
- (void)showMoreBubbleIfNeededForView:(UIView *)moreView;
- (void)removeMoreBubble;

//duet layout bubble for 3 times
- (void)showDuetLayoutBubbleIfNeededForView:(UIView *)duetLayoutView text:(NSString *)text containerView:(UIView *)containerView;
- (void)removeDuetLayoutBubble;

// duet layout prop hint
- (void)removeDuetGreenScreenPropHintView;

// prop hint
- (void)showPropHintWithPublishModel:(AWEVideoPublishViewModel *)publishModel container:(UIView *)container effect:(IESEffectModel *)effect;
- (void)removePropHint;
- (BOOL)isPropHintViewShowing;

- (void)showPropPhotoSensitiveWithContainer:(UIView *)container effect:(IESEffectModel *)effect;
- (void)removePropPhotoSensitive;

- (void)showUserIncentiveBubbleForView:(UIView *)targetView
                            bubbleView:(UIView *)bubbleView
                         containerView:(UIView *)containerView
                             direction:(ACCBubbleDirection)direction
                      cornerAdujstment:(CGPoint)corner
                      anchorAdjustment:(CGPoint)anchor;
- (void)removeUserIncentiveBubble;

// meteor bar item guide
- (void)showMeteorModeItemGuideIfNeeded:(UIView *)itemView dismissBlock:(nullable dispatch_block_t)dismissBlock;

/// recognition bubble
/// recognition lead bubble with longpress lottie
- (void)showRecognitionBubbleWithInputData:(ACCRecordViewControllerInputData *)inputData forView:(UIView *)view titleStr:(nullable NSString *)titleStr contentStr:(nullable NSString *)contentStr loopTimes:(NSInteger)loopTimes showedCallback:(nonnull dispatch_block_t)showedCallback;

/// recognition retry bubble with 2 labels
- (void)showRecognitionBubbleForView:(UIView *)view
                         bubbleTitle:(NSString *)title
                       bubbleTipHint:(NSString *)hint
                          completion:(dispatch_block_t)completion;

/// recognition bar item bubble in right toolbar
- (void)showRecognitionItemBubbleWithInputData:(ACCRecordViewControllerInputData *)inputData forView:(UIView *)view bubbleStr:(NSString *)str showedCallback:(dispatch_block_t)showedCallback;

/// recognition prop hint bubble
- (void)showRecognitionPropHintBubble:(NSString *)hint forView:(UIView *)view center:(CGPoint)center completion:(dispatch_block_t)completion;

/// remove all-kinds recognition bubble
- (void)removeRecognitionBubble:(BOOL)isPropHint;

//dismiss & clear
- (void)dismissWithOptions:(AWERecoderHintsDismissOptions)options;
- (void)clearAll;

- (BOOL)shouldShowAddFeedMusicView;

- (BOOL)anyBubbleIsShowing;

@end

NS_ASSUME_NONNULL_END

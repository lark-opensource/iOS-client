//
//  AWERecorderTipsAndBubbleManager.m
//  Pods
//
//  Created by chengfei xiao on 2019/6/12.
//

#import "AWERepoMusicModel.h"
#import "AWERepoFlowControlModel.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWERecorderTipsAndBubbleManager.h"
#import "AWEStickerHintView.h"
#import <CreationKitInfra/AWEVideoHintView.h>
#import "ACCPropRecommendMusicView.h"
#import "ACCConfigKeyDefines.h"
#import "CAKAlbumAssetModel+Convertor.h"
#import "ACCSelectAlbumAssetsProtocol.h"
#import "ACCMeteorModeUtils.h"
#import "ACCBarItemToastView.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CameraClient/ACCTransitioningDelegateProtocol.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <Masonry/View+MASAdditions.h>
#import <ByteDanceKit/NSDate+BTDAdditions.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCMusicRecommendPropBubbleView.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "AWERepoDuetModel.h"
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import "AWERecognitionLeadTipView.h"
#import "AWERecognitionLoadingView.h"
#import "AWERecognitionModeSwitchButton.h"

NSString * const kACCMoreBubbleShowKey = @"kACCMoreBubbleShowKey";
NSString * const kACCDuetLayoutBubbleShowKey = @"kACCDuetLayoutBubbleShowKey";
NSString * const kACCMusicRecommendPropBubbleFrequencyDictKey = @"kACCMusicRecommendPropBubbleFrequencyDictKey";
NSString * const kACCMusicRecommendPropIDKey = @"kACCMusicRecommendPropIDKey";
NSString * const kACCDuetGreenScreenHintViewShowKey = @"kACCDuetGreenScreenHintViewShowKey";

static NSInteger kACCDuetLayoutBubbleTipsCount = 3;//show 3 times layout bubble tips

NSString *const kACCImageAlbumGuideShowKey = @"kACCImageAlbumGuideShowKey";
static NSString *const kShowAlbumNewContentNoticeRecordBubbleKey = @"kShowAlbumNewContentNoticeRecordBubbleKey";
static NSString *const kShowAlbumNewContentNoticeRecordBubbleShowCountKey = @"kShowAlbumNewContentNoticeRecordBubbleShowCountKey";

typedef NS_ENUM(NSUInteger, kUseFeedMusicNoShowCode) {
    kUseFeedMusicNoShowCodeNone = 0,
    kUseFeedMusicNoShowCodeMomentRefreshSetting = 2,
    kUseFeedMusicNoShowCodeMomentRefreshView = 3,
    kUseFeedMusicNoShowCodeNoCameraPermission = 6,
    kUseFeedMusicNoShowCodeShowStoryTab = 7,
};

@interface AWERecorderTipsAndBubbleManager ()

@property (nonatomic, strong) AWEVideoHintView *filterHint;
@property (nonatomic, strong) AWEVideoHintView *zoomScaleHintView;
@property (nonatomic, strong) UIView *musicBubble;
@property (nonatomic, strong) UIView *moreBubble;
@property (nonatomic, strong) UIView *duetLayoutBubble;
@property (nonatomic, strong) UIView *propRecommendMusicBubble;
@property (nonatomic, strong) UIView *musicRecommendPropBubble;
@property (nonatomic, strong) UIView *duetWithPropBubble;
@property (nonatomic, strong) AWEStickerHintView *propHintView;
@property (nonatomic, strong) AWEStickerHintView *propPhotoSensitiveView;
@property (nonatomic, strong) UIView *userIncentiveBubble;
@property (nonatomic, strong) UIView *imageAlbumGuideBubbleView;

@property (nonatomic, copy) void(^removePropRecommendMusicBubbleCompletion)(void);
@property (nonatomic, copy) void(^showMomentGuideAnimationCompletion)(NSArray<UIImage *> *);
@property (nonatomic, copy) ACCDismissMusicRecommendPropBubbleBlock musicRecommendPropBubbleDismissBlock;

//相册新内容投稿提醒
@property (nonatomic, strong) UIView *albumNewContentBubbleView;
@property (nonatomic, strong) UIImageView *albumNewContentBubbleImageView;
@property (nonatomic, strong) UILabel *albumNewContentBubbleLabel;
@property (nonatomic, strong) UIView *albumNewContentBubble;
@property (nonatomic, strong) UIView *recognitionBubble; ///
@property (nonatomic, strong) CAKAlbumAssetModel *showingAssetModel;
@property (nonatomic, strong) NSString *albumNewContentBubbleType;
@property (nonatomic, strong) id<UIViewControllerTransitioningDelegate, ACCInteractiveTransitionProtocol> transitionDelegate;
@property (nonatomic, strong) NSDictionary *trackInfo;

@end


@implementation AWERecorderTipsAndBubbleManager

+ (instancetype)shareInstance
{
    static dispatch_once_t once;
    static AWERecorderTipsAndBubbleManager *shareInstance = nil;
    
    dispatch_once(&once, ^{
        shareInstance = [[AWERecorderTipsAndBubbleManager alloc] init];
    });
    return shareInstance;
}

#pragma mark - filter

- (void)showFilterHintWithContainer:(nonnull UIView *)container
                         filterName:(nonnull NSString *)filterName
                       categoryName:(nonnull NSString *)catetoryName
{
    if (!container || !filterName || [ACCMeteorModeUtils needShowMeteorModeBubbleGuide]) {
        return;
    }

    [self removeZoomScaleHintView];
    acc_dispatch_main_async_safe(^{
        if (!self.filterHint) {
            self.filterHint = [[AWEVideoHintView alloc] init];
        }
        if (self.filterHint.superview != nil && self.filterHint.superview != container) {
            [self.filterHint removeFromSuperview];
        }
        if (!self.filterHint.superview) {
            [container addSubview:self.filterHint];
            ACCMasMaker(self.filterHint, {
                make.centerX.equalTo(container);
                make.centerY.equalTo(container.mas_top).offset(ACC_SCREEN_HEIGHT / 3);
            });
        }
        self.filterHint.alpha = 0.0;
        [self.filterHint.layer removeAllAnimations];
        [self.filterHint updateTopText:filterName bottomText:catetoryName];
        [UIView animateKeyframesWithDuration:1.2
                                       delay:0
                                     options:UIViewKeyframeAnimationOptionBeginFromCurrentState
                                  animations:^{
                                      [UIView addKeyframeWithRelativeStartTime:0.0
                                                              relativeDuration:(0.3/1.2)
                                                                    animations:^{
                                                                        self.filterHint.alpha = 1.0;
                                                                    }];
                                      [UIView addKeyframeWithRelativeStartTime:(0.9/1.2)
                                                              relativeDuration:(0.3/1.2)
                                                                    animations:^{
                                                                        self.filterHint.alpha = 0.0;
                                                                    }];
                                  }
                                  completion:nil];
    });
}

- (void)removefilterHint
{
    if (self.filterHint) {
        acc_dispatch_main_async_safe(^{
            self.filterHint.alpha = 0.0;
            [self.filterHint.layer removeAllAnimations];
        });
    }
}

#pragma mark - helper
- (BOOL)hasCameraAndMicroPhoneAuth
{
    return [ACCDeviceAuth hasCameraAndMicroPhoneAuth];
}

#pragma mark - zoom
- (void)showZoomScaleHintViewWithContainer:(nonnull UIView *)containerView
                                 zoomScale:(CGFloat)zoomScale
                              isGestureEnd:(BOOL)isGestureEnd
{
    if (!containerView) {
        return;
    }
    [self removefilterHint];
    //PM要求整数倍率的展示不带小数点，其余数值要展示小数点，下面的逻辑是处理这种特殊case的：
    //PM requires integer zoom value to be displayed without decimal points,
    //and other values to be displayed with decimal points.
    NSInteger temp = zoomScale * 10;
    NSString *scaleInfo = [NSString stringWithFormat:@"%.1fx", temp / 10.0];
    if (temp % 10 == 0) {
        scaleInfo = [NSString stringWithFormat:@"%zdx", temp / 10];
    }

    acc_dispatch_main_async_safe(^{
        [self createScaleHintView:containerView];
        [self.zoomScaleHintView updateTopText:scaleInfo bottomText:@""];
        [self.zoomScaleHintView.layer removeAllAnimations];
        [self updateScaleHintViewWithAnimation:isGestureEnd];
    });
}

- (void)removeZoomScaleHintView
{
    if (self.zoomScaleHintView) {
        acc_dispatch_main_async_safe(^{
            self.zoomScaleHintView.tag = 0;
            self.zoomScaleHintView.alpha = 0.0;
            [self.zoomScaleHintView.layer removeAllAnimations];
        });
    }
}

- (void)createScaleHintView:(UIView *)containerView
{
    if (!self.zoomScaleHintView) {
        self.zoomScaleHintView = [[AWEVideoHintView alloc] init];
    }
    if (self.zoomScaleHintView.superview != nil && self.zoomScaleHintView.superview != containerView) {
        [self.zoomScaleHintView removeFromSuperview];
    }
    if (!self.zoomScaleHintView.superview) {
        [containerView addSubview:self.zoomScaleHintView];
        ACCMasMaker(self.zoomScaleHintView, {
            make.centerX.equalTo(containerView);
            make.centerY.equalTo(containerView.mas_top).offset(ACC_SCREEN_HEIGHT / 3);
        });
    }
}

- (void)updateScaleHintViewWithAnimation:(BOOL)isGestureEnd
{
    if (isGestureEnd) {
        self.zoomScaleHintView.tag = 0;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.zoomScaleHintView.alpha = 0.0;
        } completion:nil];
    } else {
        if (self.zoomScaleHintView.tag == 0) {
            self.zoomScaleHintView.alpha = 0;
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.zoomScaleHintView.alpha = 1;
            } completion:^(BOOL finished) {
                self.zoomScaleHintView.tag = 1;
            }];
        }
    }
}

#pragma mark - music bubble

- (void)showMusicTimeBubbleWithPublishModel:(AWEVideoPublishViewModel *)publishModel forView:(UIView *)musicView bubbleStr:(NSString *)str
{
    if (!musicView || ![str length]) {
        return;
    }
    
    NSString * referString = publishModel.repoTrack.referString;
    BOOL shouldDisplayBubble = YES;
    if (referString) {
        if (publishModel.repoDuet.isDuet) {
            shouldDisplayBubble = NO;
        }
    }
    if (!shouldDisplayBubble) {
        return;
    }
    
    [self removeMusicBubble];
    
    acc_dispatch_main_async_safe(^{

        __block UIView *bubble = [ACCBubble() showBubble:str
                                                    forView:musicView
                                           anchorAdjustment:CGPointZero
                                                inDirection:ACCBubbleDirectionDown
                                                    bgStyle:ACCBubbleBGStyleDefault
                                                 completion:^{
                                                        bubble = nil;
                                                    }];
        [ACCBubble() bubble:bubble supportTapToDismiss:YES];
        self.musicBubble = bubble;
    });
}

- (void)removeBubbleAndHintIfNeeded
{
    [self removeMusicBubble];
    [self removePropRecommendMusicBubble];
    [self removeMusicRecommendPropBubble];
    [self removeRecognitionBubble:NO];
}

- (void)removeMusicBubble
{
    if (self.musicBubble) {
        acc_dispatch_main_async_safe(^{
            [ACCBubble() removeBubble:self.musicBubble];
        });
    }
}

#pragma mark - 应用弱绑定音乐道具推荐音乐气泡

- (void)showPropRecommendMusicBubbleForTargetView:(UIView *)targetView
                                            music:(id<ACCMusicModelProtocol>)music
                                     publishModel:(AWEVideoPublishViewModel *)publishModel
                                        direction:(ACCBubbleDirection)direction
                                      contentView:(ACCPropRecommendMusicView *)contentView
                                    containerView:(UIView *)containerView
                            withDismissCompletion:(void(^)(void))completion
{
    [ACCTracker() track:@"show_music_popup" params:@{@"enter_from" : @"video_shoot_page",
                                                     @"music_id" : music.musicID ?: @"",
                                                     @"creation_id" : publishModel.repoContext.createId ?: @""
    }];
    self.removePropRecommendMusicBubbleCompletion = completion;
    if (self.propRecommendMusicBubble || [ACCMeteorModeUtils needShowMeteorModeBubbleGuide]) {
        return; //Keep current bubble, not to show another one.
    }
    @weakify(contentView);
    @weakify(self);
    self.propRecommendMusicBubble = [ACCBubble() showBubbleWithCustomView:contentView
                            contentInsets:UIEdgeInsetsZero
                                  forView:targetView
                          inContainerView:containerView
                               fromAnchor:CGPointZero
                              inDirection:direction
                         anchorAdjustment:CGPointZero
                                  bgStyle:ACCBubbleBGStyleDark
                               completion:^{
        @strongify(contentView);
        [contentView viewAppearEvent];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @strongify(contentView);
            @strongify(self);
            if (contentView != nil && !contentView.hasTappedOnce) {
                [self removePropRecommendMusicBubble];
            }
        });
    }];
    [ACCBubble() bubble:self.propRecommendMusicBubble supportTapToDismiss:NO];
}

- (void)removePropRecommendMusicBubble
{
    if (self.propRecommendMusicBubble) {
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(self.removePropRecommendMusicBubbleCompletion);
            [ACCBubble() tapToDismissWithBubble:self.propRecommendMusicBubble];
            self.propRecommendMusicBubble = nil;
        });
    }
}

#pragma mark - 音乐拍同款推荐道具气泡

- (void)showMusicRecommendPropBubbleForTargetView:(UIView *)targetView
                                       bubbleView:(ACCMusicRecommendPropBubbleView *)bubbleView
                                    containerView:(UIView *)containerView
                                        direction:(ACCBubbleDirection)direction
                               bubbleDismissBlock:(ACCDismissMusicRecommendPropBubbleBlock)dismissBlock
{
    if (!targetView || !containerView || targetView.hidden || targetView.alpha == 0) {
        return;
    }
    self.musicRecommendPropBubbleDismissBlock = dismissBlock;
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMusicRecommendPropBubbleAndUpdatePropIcon)];
    [bubbleView addGestureRecognizer:tapGes];
    // targetView 在屏幕左侧，气泡会自适应调整箭头位置，cornerAdjustment 设置为 CGPointZero 即可
    @weakify(self);
    self.musicRecommendPropBubble = [ACCBubble() showBubbleWithCustomView:bubbleView
                                                            contentInsets:UIEdgeInsetsZero
                                                                  forView:targetView
                                                          inContainerView:containerView
                                                               fromAnchor:CGPointZero
                                                              inDirection:ACCBubbleDirectionUp
                                                         anchorAdjustment:CGPointMake(0, -12)
                                                         cornerAdjustment:CGPointZero
                                                                  bgStyle:ACCBubbleBGStyleDefault
                                                               completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @strongify(self);
            [self dismissMusicRecommendPropBubbleAndUpdatePropIcon];
        });
    }];
    [ACCBubble() bubble:self.musicRecommendPropBubble supportTapToDismiss:NO];
}

- (void)removeMusicRecommendPropBubble
{
    if (self.musicRecommendPropBubble) {
        acc_dispatch_main_async_safe(^{
            [ACCBubble() tapToDismissWithBubble:self.musicRecommendPropBubble];
            self.musicRecommendPropBubble = nil;
        });
    }
}

- (void)dismissMusicRecommendPropBubbleAndUpdatePropIcon
{
    // 如果已经被第三方 dismiss
    if (!self.musicRecommendPropBubble) {
        return;
    }
    ACCBLOCK_INVOKE(self.musicRecommendPropBubbleDismissBlock);
    [self removeMusicRecommendPropBubble];
}

// 音乐推荐道具气泡是否展示的逻辑收敛到此处
- (BOOL)shouldShowMusicRecommendPropBubbleWithInputData:(ACCRecordViewControllerInputData *)inputData isShowingPanel:(BOOL)isShowingPanel
{
    if (![self hasCameraAndMicroPhoneAuth] || [ACCMeteorModeUtils needShowMeteorModeBubbleGuide]) {
        return NO;
    }

    BOOL isInExperiment = (ACCConfigEnum(kConfigInt_server_music_recommend_prop_mode, ACCServerMusicRecommendPropMode) != ACCServerMusicRecommendPropModeNone);
    if (!isInExperiment) {
        return NO;
    }

    BOOL isFromSingleSong = [inputData.publishModel.repoTrack.referExtra[@"shoot_way"] isEqualToString:@"single_song"];
    if (!isFromSingleSong) {
        return NO;
    }

    BOOL hasBindProp = inputData.localSticker != nil;
    if (hasBindProp) {
        return NO;
    }

    if (isShowingPanel) {
        return NO;
    }

    NSUInteger bubbleMaxShowTimePerDay = 2;
    NSString *currentDateString = [self calculateCurrentTimeZoneDateFormatString];
    NSString *currentMusicID = inputData.publishModel.repoMusic.music.musicID;

    NSDictionary *frequencyDictionary = [ACCCache() dictionaryForKey:kACCMusicRecommendPropBubbleFrequencyDictKey];
    NSArray *musicIDArray = frequencyDictionary[currentDateString] ?: @[];

    // 气泡每天展示次数最多2次，且每个 musicID 每天最多展示一次
    if ([musicIDArray count] == bubbleMaxShowTimePerDay || [musicIDArray containsObject:currentMusicID]) {
        return NO;
    }

    BOOL isBackUp = inputData.publishModel.repoDraft.isBackUp;
    if (isBackUp) {
        return NO;
    }

    BOOL isDraft = inputData.publishModel.repoDraft.isDraft;
    if (isDraft) {
        return NO;
    }

    return YES;
}

- (NSString *)calculateCurrentTimeZoneDateFormatString
{
    NSDate *currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval timestampOffset = [[NSTimeZone systemTimeZone] secondsFromGMT];
    NSDate *newDate = [currentDate dateByAddingTimeInterval:timestampOffset];
    return [newDate btd_stringWithFormat:@"yyyy-MM-dd"];
}

#pragma mark - duet with prop bubble
- (void)showDuetWithPropBubbleForTargetView:(UIView *)targetView
                                 bubbleView:(ACCMusicRecommendPropBubbleView *)bubbleView // reuse music recommend prop bubble view
                              containerView:(UIView *)containerView
                                  direction:(ACCBubbleDirection)direction
                         bubbleDismissBlock:(nullable void(^)(void))dismissBlock

{
    if (!targetView || !containerView || targetView.hidden || targetView.alpha == 0) {
        return;
    }
    
    self.duetWithPropBubble = [ACCBubble() showBubbleWithCustomView:bubbleView
                                                      contentInsets:UIEdgeInsetsZero
                                                            forView:targetView
                                                    inContainerView:containerView
                                                         fromAnchor:CGPointZero
                                                        inDirection:direction
                                                   anchorAdjustment:CGPointMake(0, -12)
                                                   cornerAdjustment:CGPointZero
                                                            bgStyle:ACCBubbleBGStyleDefault
                                                         completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            ACCBLOCK_INVOKE(dismissBlock);
            [self removeDuetWithPropBubble];
        });
    }
                               ];
    [ACCBubble() bubble:self.duetWithPropBubble supportTapToDismiss:NO];
}

- (BOOL)shouldShowDuetWithPropBubbleWithInputData:(ACCRecordViewControllerInputData *)inputData
{
    
    if (ACCConfigEnum(kConfigInt_duet_with_effect_or_show_tips_bubble, ACCDuetWithEffectPropType) != ACCDuetWithEffectPropTypeTipsBubble) { return NO; }
    if (!inputData.publishModel.repoDuet.isDuet) { return NO; }
    // 当前合拍贴纸被sticker_id指定了，不会有提示气泡的效果
    if (inputData.publishModel.repoDuet.hasSticker) { return NO; }
    // disable commercialization duet case
    if ([inputData.ugcPathRefer isEqualToString:@"task"]) { return NO;}
    if ([inputData.ugcPathRefer isEqualToString:@"challenge"]) { return NO;}
    if ([ACCMeteorModeUtils needShowMeteorModeBubbleGuide]) { return NO; }

    return YES;
}

- (void) removeDuetWithPropBubble
{
    if (self.duetWithPropBubble) {
        acc_dispatch_main_async_safe(^{
            [ACCBubble() tapToDismissWithBubble:self.duetWithPropBubble];
        });
    }
}

#pragma mark - upload photo bubble

- (BOOL)shouldShowAddFeedMusicView
{
    BOOL shouldShowStoryTab = ACCConfigBool(kConfigBool_enable_story_tab_in_recorder);
    BOOL shouldShowAddFeedMusicView = !shouldShowStoryTab;
    NSInteger notShowCode = kUseFeedMusicNoShowCodeNone;
    if ([self hasCameraAndMicroPhoneAuth]) {
        notShowCode = kUseFeedMusicNoShowCodeNoCameraPermission;
    } else if (shouldShowStoryTab) {
        notShowCode = kUseFeedMusicNoShowCodeShowStoryTab;
    }
    if (kUseFeedMusicNoShowCodeNone != notShowCode) {
        AWELogToolInfo(AWELogToolTagRecord, @"reuse feed music failed with not show code:%zd", notShowCode);
    }
    return shouldShowAddFeedMusicView && [self hasCameraAndMicroPhoneAuth] && ![ACCMeteorModeUtils needShowMeteorModeBubbleGuide];
}

- (BOOL)p_shouldShowImageAlbumGuideView
{
    return ACCConfigBool(kConfigBool_enable_images_album_publish)
        && ACCConfigBool(kConfigBool_enable_images_album_publish_guide)
        && !ACCConfigBool(kConfigBool_image_mvp_defatult_landing_mv)
        && ![ACCCache() boolForKey:kACCImageAlbumGuideShowKey]
        && ![ACCMeteorModeUtils needShowMeteorModeBubbleGuide];
}

- (BOOL)showImageAlbumEditGuideIfNeededForView:(UIView *)targetView containerView:(UIView *)containerView
{
    if (![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin] || [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isNewUser]) {
        return NO;
    }
    
    if (![self p_shouldShowImageAlbumGuideView] || !containerView || !targetView) {
        return NO;
    }
    
    [ACCCache() setBool:YES forKey:kACCImageAlbumGuideShowKey];
    
    @weakify(self);
    acc_dispatch_main_async_safe(^{

        UIImageView *iconView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icon_recorder_tip_bubble_image_album")];
        [iconView sizeToFit];
        // 通过iconViewInsets并不能改变icon的位置，所以指定frame
        iconView.frame = CGRectMake(12.f, 13.f, CGRectGetWidth(iconView.frame), CGRectGetHeight(iconView.frame));
        UIView *bubble = [ACCBubble() showBubble:@"选择多张图片试试"
                                                 forView:targetView
                                                iconView:iconView
                                         inContainerView:containerView
                                          iconViewInsets:UIEdgeInsetsMake(0.f, 0.f, 0.f, 6.f)
                                              fromAnchor:CGPointZero
                                        anchorAdjustment:CGPointMake(36.f, -12.f)
                                        cornerAdjustment:CGPointMake(36.f, 0.f)
                                               fixedSize:CGSizeMake(ACC_SCREEN_WIDTH - 32.f, 48.f)
                                               direction:ACCBubbleDirectionUp
                                                 bgStyle:ACCBubbleBGStyleDark
                                              completion:^{
            @strongify(self);
            self.imageAlbumGuideBubbleView = nil;
        }];
        self.imageAlbumGuideBubbleView = bubble;
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        [self removeImageAlbumEditGuide];
    });

    return YES;
}

- (BOOL)isImageAlbumGuideShowing
{
    return self.imageAlbumGuideBubbleView.superview != nil;
}

- (void)removeImageAlbumEditGuide
{
    if (self.imageAlbumGuideBubbleView) {
        [ACCBubble() removeBubble:self.imageAlbumGuideBubbleView];
        self.imageAlbumGuideBubbleView = nil;
    }
}

#pragma mark - more bubble

- (void)showMoreBubbleIfNeededForView:(UIView *)moreView
{
    if ([ACCMeteorModeUtils needShowMeteorModeBubbleGuide]) {
        return;
    }
    acc_dispatch_main_async_safe(^{
        if (![ACCCache() boolForKey:kACCMoreBubbleShowKey]) {
            self.moreBubble = [ACCBubble() showBubble:ACCLocalizedString(@"shooting_page_more_features_prompt", @"点击展开更多功能") forView:moreView inDirection:ACCBubbleDirectionLeft bgStyle:ACCBubbleBGStyleDefault];
            [ACCBubble() bubble:self.moreBubble supportTapToDismiss:YES];
            [ACCCache() setBool:YES forKey:kACCMoreBubbleShowKey];
        }
    });
}

- (void)removeMoreBubble
{
    if (self.moreBubble) {
        acc_dispatch_main_async_safe(^{
            [ACCBubble() tapToDismissWithBubble:self.moreBubble];
        });
    }
}

- (void)showDuetLayoutBubbleIfNeededForView:(UIView *)duetLayoutView text:(NSString *)text containerView:(UIView *)containerView
{
    if (self.needShowDuetWithPropBubble || [ACCMeteorModeUtils needShowMeteorModeBubbleGuide]) {
        return;
    }

    acc_dispatch_main_async_safe(^{
        NSInteger count = [ACCCache() integerForKey:kACCDuetLayoutBubbleShowKey];
        if (count >= kACCDuetLayoutBubbleTipsCount) {
            return;
        }
        self.duetLayoutBubble = [ACCBubble() showBubble:text forView:duetLayoutView inContainerView:containerView anchorAdjustment:CGPointMake(-5, 0) inDirection:ACCBubbleDirectionLeft bgStyle:ACCBubbleBGStyleDefault completion:nil];
        [ACCBubble() bubble:self.duetLayoutBubble supportTapToDismiss:YES];
        count++;
        [ACCCache() setInteger:count forKey:kACCDuetLayoutBubbleShowKey];
    });
}

- (void)removeDuetLayoutBubble
{
    if (self.duetLayoutBubble) {
        acc_dispatch_main_async_safe(^{
            [ACCBubble() tapToDismissWithBubble:self.duetLayoutBubble];
        });
    }
}

#pragma mark - prop hint

- (void)showPropHintWithPublishModel:(AWEVideoPublishViewModel *)publishModel container:(UIView *)container effect:(IESEffectModel *)effect
{
    if (!container || !effect) {
        return;
    }
    
    NSString * referString = publishModel.repoTrack.referString;
    if (referString) {
        if ([referString isEqualToString:@"draft_again"]) {
            return;
        }
    }
    
    acc_dispatch_main_async_safe(^{
        if (!self.propHintView) {
            self.propHintView = [[AWEStickerHintView alloc] initWithFrame:CGRectZero];
        }
        if (self.propHintView.superview != nil && self.propHintView.superview != container) {
            [self.propHintView removeFromSuperview];
            self.propHintView = nil;
        }
        if (!self.propHintView.superview) {
            [container addSubview:self.propHintView];
            [self.propHintView mas_makeConstraints:^(MASConstraintMaker *maker) {
                maker.bottom.equalTo(container.mas_bottom).offset(-240 - ACC_IPHONE_X_BOTTOM_OFFSET);
                maker.top.equalTo(container.mas_top);
                maker.left.equalTo(container.mas_left);
                maker.width.equalTo(container.mas_width);
            }];
        }
        [self handleDuetGreenScreenPropHintViewWithEffectModel:effect];
        [self.propHintView showWithEffect:effect];
    });
}

- (void)removePropHint
{
    if (self.propHintView) {
        acc_dispatch_main_async_safe(^{
            [self.propHintView remove];
        });
    }
}

- (BOOL)isPropHintViewShowing
{
    return self.propHintView.isShowing;
}

#pragma mark - duet layout prop hint view

- (void)removeDuetGreenScreenPropHintView
{
    BOOL isDuetGreenScreenHintViewShowing = [ACCCache() boolForKey:kACCDuetGreenScreenHintViewShowKey];
    if (isDuetGreenScreenHintViewShowing) {
        [self removePropHint];
        [ACCCache() setBool:NO forKey:kACCDuetGreenScreenHintViewShowKey];
    }
}

- (void)handleDuetGreenScreenPropHintViewWithEffectModel:(IESEffectModel *)effect
{
    BOOL isGreenScreenLayout = effect.isDuetGreenScreen;
    if (isGreenScreenLayout) {
        [ACCCache() setBool:YES forKey:kACCDuetGreenScreenHintViewShowKey];
        @weakify(self);
        self.propHintView.duetGreenScreenHintViewCompletionBlock = ^{
            @strongify(self);
            [self removeDuetGreenScreenPropHintView];
        };
    } else {
        self.propHintView.duetGreenScreenHintViewCompletionBlock = nil;
    }
}

#pragma mark - prop sensitive view

- (void)showPropPhotoSensitiveWithContainer:(UIView *)container effect:(IESEffectModel *)effect
{
    if (!container || !effect) {
        return;
    }
    acc_dispatch_main_async_safe(^{
        if (self.propPhotoSensitiveView) {
            [self.propPhotoSensitiveView removePhotoSensitiveHint];
            [self.propPhotoSensitiveView removeFromSuperview];
        }
        self.propPhotoSensitiveView = [[AWEStickerHintView alloc] initWithFrame:CGRectZero];
        if (!self.propPhotoSensitiveView.superview) {
            [container addSubview:self.propPhotoSensitiveView];
            [self.propPhotoSensitiveView mas_makeConstraints:^(MASConstraintMaker *maker) {
                maker.bottom.equalTo(container.mas_bottom).offset(-240 - ACC_IPHONE_X_BOTTOM_OFFSET);
                maker.top.equalTo(container.mas_top);
                maker.left.equalTo(container.mas_left);
                maker.width.equalTo(container.mas_width);
            }];
        }
        [self.propPhotoSensitiveView showPhotoSensitiveWithEffect:effect];
        [self propPhotoSensitiveViewAutoDismissAfterSecond:3];
    });
}

- (void)propPhotoSensitiveViewAutoDismissAfterSecond:(NSInteger)seconds
{
    AWEStickerHintView *disMissView = self.propPhotoSensitiveView;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [disMissView removePhotoSensitiveHint];
        [disMissView removeFromSuperview];
    });
}

- (void)removePropPhotoSensitive
{
    if (self.propPhotoSensitiveView) {
       acc_dispatch_main_async_safe(^{
           [self.propPhotoSensitiveView removePhotoSensitiveHint];
           [self.propPhotoSensitiveView removeFromSuperview];
       });
    }
}

- (void)showUserIncentiveBubbleForView:(UIView *)targetView
                            bubbleView:(UIView *)bubbleView
                         containerView:(UIView *)containerView
                             direction:(ACCBubbleDirection)direction
                      cornerAdujstment:(CGPoint)corner
                      anchorAdjustment:(CGPoint)anchor
{
    if (!bubbleView || !targetView || !containerView) {
        return ;
    }

    [self removeUserIncentiveBubble];
    acc_dispatch_main_async_safe(^{
        self.userIncentiveBubble = [ACCBubble() showBubbleWithCustomView:bubbleView
                                                           contentInsets:UIEdgeInsetsZero
                                                                 forView:targetView
                                                         inContainerView:containerView
                                                              fromAnchor:CGPointZero
                                                             inDirection:direction
                                                        anchorAdjustment:anchor
                                                        cornerAdjustment:corner
                                                                 bgStyle:ACCBubbleBGStyleDark
                                                              completion:nil];
    });
    [ACCBubble() bubble:self.userIncentiveBubble supportTapToDismiss:NO];
}

- (void)removeUserIncentiveBubble
{
    if (self.userIncentiveBubble) {
        acc_dispatch_main_async_safe(^{
            [ACCBubble() tapToDismissWithBubble:self.userIncentiveBubble];
            self.userIncentiveBubble = nil;
        });
    }
}

#pragma mark - meteor mode

- (void)showMeteorModeItemGuideIfNeeded:(UIView *)itemView dismissBlock:(nullable dispatch_block_t)dismissBlock
{
    if ([ACCMeteorModeUtils needShowMeteorModeBubbleGuide]) {
        [ACCBarItemToastView showOnAnchorBarItem:itemView withContent:@"隆重推出一种新的拍摄玩法" dismissBlock:dismissBlock];
        [ACCMeteorModeUtils markHasShowenMeteorModeBubbleGuide];
    }
}

#pragma mark - recognition bubble
- (void)showRecognitionBubbleWithInputData:(ACCRecordViewControllerInputData *)inputData forView:(UIView *)view titleStr:(nullable NSString *)titleStr contentStr:(nullable NSString *)contentStr loopTimes:(NSInteger)loopTimes showedCallback:(nonnull dispatch_block_t)showedCallback __attribute__((annotate("csa_ignore_block_use_check")))
{
    if (!view || ![titleStr length] || self.recognitionBubble) {
        return;
    }
    /// resolve bubble conflicts
    [self shouldShowRecognitionBubble:inputData completion:^(BOOL shouldShow) {
        if (shouldShow){
            [self p_showRecognitionBubbleForView:view titleStr:titleStr contentStr:contentStr loopTimes:loopTimes completion:showedCallback];
        }
    }];

}

- (void)showRecognitionItemBubbleWithInputData:(ACCRecordViewControllerInputData *)inputData forView:(AWERecognitionModeSwitchButton *)view bubbleStr:(NSString *)str showedCallback:(dispatch_block_t)showedCallback __attribute__((annotate("csa_ignore_block_use_check")))
{
    if (!view || ![str length] || self.recognitionBubble) {
        return;
    }
    /// resolve bubble conflicts
    [self shouldShowRecognitionItemBubble:inputData completion:^(BOOL shouldShow) {
        if (shouldShow){
            [self p_showRecognitionItemBubbleForView:view bubbleStr:str completion:showedCallback];
        }
    }];
}

- (void)showRecognitionBubbleForView:(UIView *)view
                         bubbleTitle:(NSString *)title
                       bubbleTipHint:(NSString *)hint
                          completion:(dispatch_block_t)completion
{
    [self removeRecognitionBubble:NO];

    acc_dispatch_main_async_safe(^{
        let recognitionBubble = [[AWERecognitionLoadingView alloc] initWithFrame:CGRectMake(0, 0, 300, 200) hideLottie:YES];
        recognitionBubble.center = CGPointMake(view.acc_centerX, view.acc_centerY*0.9);
        recognitionBubble.tipTitleLabel.text = title;
        recognitionBubble.tipHintLabel.text = hint;
        [view addSubview:recognitionBubble];

        self.recognitionBubble = recognitionBubble;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [recognitionBubble removeFromSuperview];
        });

        completion();
    });
}

#define PROP_HINT_TAG 0x2333
- (void)showRecognitionPropHintBubble:(NSString *)hint forView:(UIView *)view center:(CGPoint)center completion:(dispatch_block_t)completion
{
    [self removeRecognitionBubble:NO];
    [self removeRecognitionBubble:YES];

    acc_dispatch_main_async_safe(^{
        let propHintLabel = [UILabel new];
        propHintLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        propHintLabel.textColor = UIColor.whiteColor;
        propHintLabel.text = hint;
        [propHintLabel sizeToFit];
        propHintLabel.center = center;
        [view addSubview:propHintLabel];
        propHintLabel.tag = PROP_HINT_TAG;
        ACCBLOCK_INVOKE(completion);

        self.recognitionBubble = propHintLabel;

        /// remove after 5 seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [propHintLabel removeFromSuperview];
        });
    });
}

- (void)p_showRecognitionItemBubbleForView:(AWERecognitionModeSwitchButton *)view bubbleStr:(NSString *)str completion:(dispatch_block_t)completion
{

    [self removeRecognitionBubble:NO];
    acc_dispatch_main_async_safe(^{

        __block UIView *bubble = [ACCBubble() showBubble:str
                                                    forView:view
                                         inContainerView:[[[view superview].superview superview] superview]
                                           anchorAdjustment:CGPointZero
                                                inDirection:ACCBubbleDirectionLeft
                                                    bgStyle:ACCBubbleBGStyleDefault
                                                 completion:^{
                                                        bubble = nil;
                                                    }];
        view.bubble = bubble;
        [ACCBubble() bubble:bubble supportTapToDismiss:YES];

        ACCBLOCK_INVOKE(completion);
        self.recognitionBubble = bubble;
    });
}


- (void)p_showRecognitionBubbleForView:(UIView *)view titleStr:(nullable NSString *)titleStr contentStr:(nullable NSString *)contentStr loopTimes:(NSInteger)loopTimes completion:(dispatch_block_t)completion
{

    acc_dispatch_main_async_safe(^{
        [self removeRecognitionBubble:NO];

        let recognitionBubble = [[AWERecognitionLeadTipView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        recognitionBubble.center = CGPointMake(view.acc_centerX, view.acc_centerY);
        recognitionBubble.titleLabel.text = titleStr;
        recognitionBubble.contentLabel.text = contentStr;
        [view addSubview:recognitionBubble];

        ACCBLOCK_INVOKE(completion);
        @weakify(self)
        [recognitionBubble playWithTimes:loopTimes completion:^{
            @strongify(self)
            [self.recognitionBubble removeFromSuperview];
            self.recognitionBubble = nil;
        }];
        self.recognitionBubble = recognitionBubble;

    });
}

- (void)shouldShowRecognitionBubble:(ACCRecordViewControllerInputData *)inputData
                         completion:(void (^)(BOOL shouldShow))completion
{
    /// reuse 
    [self shouldShowRecognitionItemBubble:inputData completion:completion];
}

- (void)shouldShowRecognitionItemBubble:(ACCRecordViewControllerInputData *)inputData
                             completion:(void (^)(BOOL shouldShow))completion
{
    /// double check
    if (_recognitionBubble){
        return completion(NO);
    }
    
    if ([self shouldShowAddFeedMusicView] ||
        [self shouldShowDuetWithPropBubbleWithInputData:inputData] ||
        [self shouldShowMusicRecommendPropBubbleWithInputData:inputData isShowingPanel:NO] ||
        [self p_shouldShowImageAlbumGuideView]){
        completion(NO);
        return;
    }

    completion(YES);
}

- (void)removeRecognitionBubble:(BOOL)isPropHint
{
    if (isPropHint && self.recognitionBubble.tag != PROP_HINT_TAG){
        return;
    }
    if (self.recognitionBubble) {
        acc_dispatch_main_async_safe(^{
            [self.recognitionBubble removeFromSuperview];
            self.recognitionBubble = nil;
        });
    }
}

#pragma mark - clear all

- (void)dismissWithOptions:(AWERecoderHintsDismissOptions)options
{
    if (options & AWERecoderHintsDismissZoomScaleView) {
        [self removeZoomScaleHintView];
    }
    
    if (options & AWERecoderHintsDismissFilterHint) {
        [self removefilterHint];
    }
    
    if (options & AWERecoderHintsDismissPropHint) {
        [self removePropHint];
        [self removePropPhotoSensitive];
    }
    
    if (options & AWERecoderHintsDismissMusicBubble) {
        [self removeMusicBubble];
    }
    
    if (options & AWERecoderHintsDismissPropMusicBubble) {
        [self removePropRecommendMusicBubble];
    }
    
    if (options & AWERecoderHintsDismissImageAlbumGuideView) {
        [self removeImageAlbumEditGuide];
    }

    if (options & AWERecoderHintsDismissMusicPropBubble) {
        [self removeMusicRecommendPropBubble];
    }
    
    if (options & AWERecoderHintsDismissDuetWithPropBubble){
        [self removeDuetWithPropBubble];
    }

    if (options & AWERecoderHintsDismissDuetLayoutBubble) {
        [self removeDuetLayoutBubble];
    }

    if (options & AWERecoderHintsDismissRecognitionBubble) {
        [self removeRecognitionBubble:NO];
    }
}

- (void)clearAll
{
    AWERecoderHintsDismissOptions option = (AWERecoderHintsDismissFilterHint |
                                            AWERecoderHintsDismissPropHint |
                                            AWERecoderHintsDismissMusicBubble |
                                            AWERecoderHintsDismissPropMusicBubble |
                                            AWERecoderHintsDismissMusicPropBubble |
                                            AWERecoderHintsDismissImageAlbumGuideView |
                                            AWERecoderHintsDismissDuetWithPropBubble |
                                            AWERecoderHintsDismissRecognitionBubble |
                                            AWERecoderHintsDismissDuetLayoutBubble |
                                            AWERecoderHintsDismissZoomScaleView);
    [self dismissWithOptions:option];
    self.filterHint = nil;
    self.musicBubble = nil;
    self.propHintView = nil;
    self.recognitionBubble = nil;
    self.musicRecommendPropBubble = nil;
    self.zoomScaleHintView = nil;
    self.showMomentGuideAnimationCompletion = nil;
    self.duetWithPropBubble = nil;
}

#pragma mark - notifications

- (BOOL)anyBubbleIsShowing
{
    return
    self.filterHint != nil ||
    self.musicBubble != nil ||
    self.moreBubble != nil ||
    self.duetLayoutBubble != nil ||
    self.propRecommendMusicBubble != nil ||
    self.musicRecommendPropBubble != nil ||
    self.duetWithPropBubble != nil ||
    self.propHintView != nil ||
    self.propPhotoSensitiveView != nil ||
    self.userIncentiveBubble != nil ||
    self.imageAlbumGuideBubbleView != nil ||
    self.albumNewContentBubbleView != nil ||
    self.albumNewContentBubbleImageView != nil ||
    self.albumNewContentBubbleLabel != nil ||
    self.albumNewContentBubble != nil ||
    self.recognitionBubble != nil;
}
@end

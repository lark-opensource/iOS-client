//
//  AWEVideoEffectChooseViewController.m
//  Aweme
//
//  Created by hanxu on 2017/4/9.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "AWERepoVideoInfoModel.h"
#import "AWERepoCutSameModel.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEVideoEffectChooseViewController.h"
#import "AWETabView.h"
#import <CameraClient/ACCViewControllerProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "AWEVideoEffectChooseViewModel.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CameraClient/ACCRepoEditEffectModel.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKitSticker/ACCStickerContainerView.h>
#import <CreationKitInfra/UIView+ACCRTL.h>
#import "ACCRepoTextModeModel.h"
#import "ACCRepoAudioModeModel.h"
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/AWERepoDuetModel.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

static CGFloat const kAWEVideoEffectChoosebottomTabViewHeight = 194;

CGFloat kAWEVideoEffectChooseMidMargin = 45;
CGFloat kAWEVideoEffectChooseCancelButtonTop = 20;
CGFloat kAWEVideoEffectChooseCancelButtonHeight = 44;

@interface AWEVideoEffectChooseViewController () <
AWEVideoEffectViewDelegate,
AWEVideoEffectMixTimeBarDelegate,
AWEVideoEffectChooseViewModelDelegate,
ACCEditPreviewMessageProtocol
>

@property (nonatomic, strong) AWEVideoEffectChooseViewModel *chooseViewModel;

@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *saveBtn;
@property (nonatomic, strong) UIView *playerContainer;
@property (nonatomic, strong) UIButton *stopAndPlayBtn;
@property (nonatomic, strong) UIImageView *stopAndPlayImageView;
@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong) AWEVideoEffectMixTimeBar *timeBar;
@property (nonatomic, strong) AWETabView *bottomTabView;
@property (nonatomic, strong) AWEVideoEffectView *timeEffectView;

@property (nonatomic, copy) NSArray<AWEVideoEffectView *> *effectViews;

@property (nonatomic, assign) BOOL showToastLimitFlag;

@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, assign) NSInteger bottomViewIndex;
@property (nonatomic, strong) UIView<ACCLoadingViewProtocol> *loadingView;

@property (nonatomic, assign) CGFloat containerScale;
@property (nonatomic, assign) CGPoint containerCenter;
@property (nonatomic, strong) IESEffectModel *selectedEffectModel;

@property (nonatomic, assign) CGRect originalPlayerRect;

@property (nonatomic, strong) ACCStickerContainerView *stickerContainerView;

@property (nonatomic, strong) UIView *bottomBackgroundView;
@property (nonatomic, strong) ACCAnimatedButton *backIconButton;
@property (nonatomic, strong) ACCAnimatedButton *saveIconButton;
@property (nonatomic, strong) ACCAnimatedButton *revokeButton;
@property (nonatomic, strong) UILabel *effectCategoryMessageLabel;

@end

@implementation AWEVideoEffectChooseViewController

- (void)dealloc {
    AWELogToolDebug(AWELogToolTagEdit, @"%@ dealloc",[self class]);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    NSAssert(NO, @"请使用initWithModel:player:" ALP_IGNORE);
    return nil;
}

- (instancetype)initWithModel:(AWEVideoPublishViewModel *)model
                  editService:(id<ACCEditServiceProtocol>)editService
         stickerContainerView:(ACCStickerContainerView *)stickerContainerView
           originalPlayerRect:(CGRect)playerRect
{
    self = [super init];
    if (self) {
        AWEVideoEffectChooseViewModel *chooseViewModel = [[AWEVideoEffectChooseViewModel alloc] initWithModel:model editService:editService];
        [self bindWithViewModel:chooseViewModel];

        self.hidesBottomBarWhenPushed = YES;
        
        self.originalPlayerRect = playerRect;
        self.stickerContainerView = stickerContainerView;
        
        //init timeEffectTimeRange
        [self.chooseViewModel resetTimeForbiddenStyle];
    }
    return self;
}

- (void)bindWithViewModel:(AWEVideoEffectChooseViewModel *)viewmodel
{
    self.chooseViewModel = viewmodel;
    self.chooseViewModel.delegate = self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [ACCViewControllerService() viewController:self setDisableFullscreenPopTransition:YES];
    [ACCViewControllerService() viewController:self setPrefersNavigationBarHidden:YES];
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);

    [self.view addSubview:self.backgroundView];
    ACCMasMaker(self.backgroundView, {
        make.edges.equalTo(self.view);
    });
    
    [self configureBottomView];
    [self buildViews];
    [self configureTimeBar];
    [self configurePlayer];
    
    [self.chooseViewModel.editService.preview addSubscriber:self];

    [self setExclusiveTouchForView:self.view];
    
    // update category message
    AWEVideoEffectView *effectView = [self p_currentVideoEffectViewWithTabNum:self.bottomViewIndex];
    self.effectCategoryMessageLabel.text = [effectView effectCategoryTitle];
    
    // update revoke button status
    [self refreshRevokeButtonForOptimized];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.cancelBtn.hidden = NO;
    self.saveBtn.hidden = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.chooseViewModel.editService.preview resetPlayerWithViews:@[self.playerContainer]];
    [self.chooseViewModel.editService.preview seekToTime:kCMTimeZero completionHandler:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.cancelBtn.hidden = YES;
    self.saveBtn.hidden = YES;
}

#pragma mark - Initialize UI
-(void)setExclusiveTouchForView:(UIView *)view
{
    for (UIView * v in [view subviews]) {
        [v setExclusiveTouch:YES];
        [self setExclusiveTouchForView:v];
    }
}

- (void)configurePlayer
{
    @weakify(self);
    [self.chooseViewModel configPlayerWithCompletionBlock:^{
        @strongify(self);
        self.timeBar.playProgressControl.alpha = 1.0;
        self.timeBar.playProgressControl.userInteractionEnabled = YES;
    }];
}

- (void)configExclusiveStickerContainers
{
    if (self.stickerContainerView) {
        [self configScale];
        [self.playerContainer addSubview:self.stickerContainerView];
        self.stickerContainerView.transform = CGAffineTransformMakeScale(self.containerScale, self.containerScale);
        self.stickerContainerView.center = self.containerCenter;
        [self makeMaskLayerForContainerView:self.stickerContainerView];
    }
}

- (void)configScale
{
    self.containerScale = 1.0;
    
    CGFloat standScale = 9.0 / 16.0;
    CGRect currentFrame = [self mediaSmallMediaContainerFrame];
    CGFloat currentWidth = CGRectGetWidth(currentFrame);
    CGFloat currentHeight = CGRectGetHeight(currentFrame);
    CGRect oldFrame = self.originalPlayerRect;
    CGFloat oldWidth = CGRectGetWidth(oldFrame);
    CGFloat oldHeight = CGRectGetHeight(oldFrame);
    
    if (currentHeight > 0 && oldWidth > 0 && oldHeight > 0 ) {
        if (fabs(currentWidth / currentHeight - standScale) < 0.01) {
            self.containerScale = currentWidth / oldWidth;
        }
        
        if (currentWidth / currentHeight - standScale > 0.01) {
            self.containerScale = currentWidth / oldWidth;
        }
        
        if (currentWidth / currentHeight - standScale < -0.01) {
            self.containerScale = currentHeight / oldHeight;
        }
    }
    
    self.containerCenter = CGPointMake(self.playerContainer.center.x - self.playerContainer.frame.origin.x, self.playerContainer.center.y - self.playerContainer.frame.origin.y);
}

- (void)makeMaskLayerForContainerView:(UIView *)view
{
    CGRect frame = [self.view convertRect:self.playerContainer.frame toView:view];
    CAShapeLayer *layer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:frame];

    layer.path = path.CGPath;
    view.layer.mask = layer;
}

- (void)buildViews
{
    {
        [self.view addSubview:self.playerContainer];
        self.playerContainer.frame = [self mediaSmallMediaContainerFrame];
        
        [self configExclusiveStickerContainers];
        
        if (self.interactionImageView) {
            [self.playerContainer addSubview:self.interactionImageView];
            ACCMasMaker(self.interactionImageView, {
                make.edges.equalTo(self.playerContainer);
            });
        }
    }
    
    [self p_setupUIOptimization];
}

- (void)refreshEffectFragments
{
    CGFloat totalDuration = [self.chooseViewModel.publishViewModel.repoVideoInfo.video totalVideoDuration];
    //refresh timebar in tab except "time"
    [self.timeBar refreshBarWithEffectArray:[self.chooseViewModel.publishViewModel.repoEditEffect.displayTimeRanges copy] totalDuration:totalDuration];
}

- (void)refreshRevokeButton
{
    NSMutableDictionary *shouldHideRevokeBtnDict = [[NSMutableDictionary alloc] init];
    NSArray<IESMMEffectTimeRange *> *effectRanges = [self.chooseViewModel.publishViewModel.repoVideoInfo.video.effect_operationTimeRange copy];
    for (IESMMEffectTimeRange *range in effectRanges) {
        NSString *rangeCategory = [self.chooseViewModel effectCategoryWithEffectId:range.effectPathId];
        if (rangeCategory) {
            [shouldHideRevokeBtnDict setObject:@(NO) forKey:rangeCategory];
        }
    }
    
    for (AWEVideoEffectView *effectView in self.effectViews) {
        if (effectView.effectCategory) {
            NSNumber *shouldHide = ACCDynamicCast([shouldHideRevokeBtnDict objectForKey:effectView.effectCategory], NSNumber);
            if (shouldHide != nil) {
                [effectView hideRevokeBtn:shouldHide.boolValue];
            } else {
                [effectView hideRevokeBtn:YES];
            }
        }
    }
}

- (void)refreshRevokeButtonForOptimized
{
    NSMutableDictionary *shouldHideRevokeBtnDict = [[NSMutableDictionary alloc] init];
    NSArray<IESMMEffectTimeRange *> *effectRanges = [self.chooseViewModel.publishViewModel.repoVideoInfo.video.effect_operationTimeRange copy];
    for (IESMMEffectTimeRange *range in effectRanges) {
        NSString *rangeCategory = [self.chooseViewModel effectCategoryWithEffectId:range.effectPathId];
        if (rangeCategory) {
            [shouldHideRevokeBtnDict setObject:@(NO) forKey:rangeCategory];
        }
    }
}

- (void)refreshPlayProgress
{
    CGFloat totalDuration = [self.chooseViewModel.publishViewModel.repoVideoInfo.video totalVideoDuration];
    [self.timeBar updatePlayProgressWithTime:self.chooseViewModel.editService.preview.currentPlayerTime totalDuration:totalDuration];
}

- (void)updateShowingToolEffectRangeViewIfNeededWithCategoryKey:(NSString *)categoryKey effectSelected:(BOOL)selected{
    [self.timeBar updateShowingToolEffectRangeViewIfNeededWithCategoryKey:categoryKey effectSelected:selected];
}

- (CGFloat)getPlayControlViewProgress{
    return [self.timeBar getPlayControlViewProgress];
}

- (void)refreshBarWithImageArray:(NSArray<UIImage *> *)imageArray {
    [self.timeBar refreshBarWithImageArray:imageArray];
}

- (void)configureTimeBar
{
    [self.view bringSubviewToFront:self.timeBar];
    @weakify(self)
    [self.chooseViewModel loadFirstPreviewFrameWithCompletion:^(NSMutableArray * _Nonnull imageArray) {
        @strongify(self)
        [self.timeBar refreshBarWithImageArray:imageArray];
    }];
    [self refreshEffectFragments];
    [self switchToTimeEffectsViewWithAnimation:NO]; // no real switch required , only initialize the relevant data
    [self switchToFilterEffectsViewWithCategoryKey:nil animated:NO];
    [self.timeBar updatePlayProgressWithTime:0 totalDuration:[self.chooseViewModel.publishViewModel.repoVideoInfo.video totalVideoDuration]];
}

- (void)switchToFilterEffectsViewWithCategoryKey:(NSString *)categoryKey animated:(BOOL)animated
{
    if (!categoryKey && self.chooseViewModel.effectCategories.count > 0) {
        categoryKey = self.chooseViewModel.effectCategories.firstObject.categoryKey;
    }
    self.timeBar.playProgressControl.userInteractionEnabled = YES;
    void (^block)(void) = ^{
        BOOL effectSelected = NO;
        if (self.selectedEffectModel != nil) {
            NSString *category = [self.chooseViewModel effectCategoryWithEffectId:self.selectedEffectModel.effectIdentifier];
            if (category && [categoryKey isEqualToString:category]) { // 保证选中的是当前tab下的特效
                effectSelected = YES;
            }
        }
        [self.timeBar updateShowingToolEffectRangeViewIfNeededWithCategoryKey:categoryKey effectSelected:effectSelected];
        [self.timeBar updateShowingTimeEffectRangeViewIfNeededWithType:HTSPlayerTimeMachineNormal];
        self.timeBar.timeSelectControl.alpha = 0.0;
        self.timeBar.playProgressControl.alpha = 1.0;
        self.timeBar.timeReverseMask.alpha = 0.0;
    };
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            block();
        }];
    } else {
        block();
    }
    [self refreshEffectFragments];
}

- (void)switchToTimeMachineType:(HTSPlayerTimeMachineType)type withBeginTime:(NSTimeInterval)beginTime duration:(NSTimeInterval)duration animation:(BOOL)animation
{
    if (type != HTSPlayerTimeMachineNormal || type != HTSPlayerTimeMachineReverse) {
        //refresh timebar in tab "time"
        self.chooseViewModel.timeEffectTimeRange.startTime = beginTime;
        self.chooseViewModel.timeEffectTimeRange.endTime = beginTime + duration;

        [self.timeBar refreshTimeEffectRangeViewWithRange:self.chooseViewModel.timeEffectTimeRange totalDuration: [self.chooseViewModel.publishViewModel.repoVideoInfo.video totalVideoDuration]];

        //refresh timeEffectView
        [self.timeBar updateShowingTimeEffectRangeViewIfNeededWithType:type];

        //refresh toolEffectView
        [self.timeBar updateShowingToolEffectRangeViewIfNeededWithCategoryKey:@"" effectSelected:NO];
        [self.timeBar setUpTimeEffectRangeViewAlpha:0.0];
    }
    
    self.timeBar.needReverseTime = type == HTSPlayerTimeMachineReverse;
    
    void (^block)(void) = ^ {
        switch (type) {
            case HTSPlayerTimeMachineNormal:
            {
                self.timeBar.timeReverseMask.alpha = 0.0;
            }
                break;
                
            case HTSPlayerTimeMachineReverse:
            {
                self.timeBar.timeReverseMask.alpha = 1.0;
            }
                break;
            case HTSPlayerTimeMachineTimeTrap:
            {
                self.timeBar.timeReverseMask.alpha = 0.0;
                [self.timeBar setUpTimeEffectRangeViewAlpha:1.0];
            }
                break;
            case HTSPlayerTimeMachineRelativity:
            {
                self.timeBar.timeReverseMask.alpha = 0.0;
                [self.timeBar setUpTimeEffectRangeViewAlpha:1.0];
            }
                break;
        }
    };
    if (!animation) {
        block();
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            block();
        }];
    }
}

- (void)switchToTimeEffectsViewWithAnimation:(BOOL)animation
{
    HTSPlayerTimeMachineType type = self.chooseViewModel.publishViewModel.repoVideoInfo.video.effect_timeMachineType;
    
    NSTimeInterval beginTime = self.chooseViewModel.publishViewModel.repoVideoInfo.video.effect_timeMachineBeginTime;
    if (beginTime <= 0) {
        beginTime = self.chooseViewModel.timeEffectDefaultBeginTime; // default is 0
    }
    NSTimeInterval duration = self.chooseViewModel.publishViewModel.repoVideoInfo.video.effect_newTimeMachineDuration;
    if (duration <= 0) {
        duration = self.chooseViewModel.timeEffectDefaultDuration;
    }
    
    [self switchToTimeMachineType:type withBeginTime:beginTime duration:duration animation:animation];
}

- (void)registerNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEffectUpdated:) name:AWEEffectFilterDataManagerRefreshNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEffectListUpdated:) name:AWEEffectFilterDataManagerListUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadEffectViews) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)clickedTabViewWithCategoryKey:(NSString *)categoryKey isTimeTab:(BOOL)isTimeTab{
    if (!isTimeTab) {
        if (self.chooseViewModel.isPlaying) {
            [self didClickStopAndPlay];
        }
        [self switchToFilterEffectsViewWithCategoryKey:categoryKey animated:YES];
        [self.timeBar setUpPlayProgressControlTintColor:[self.chooseViewModel p_isStickerCategory:categoryKey]];
    } else {
        if (self.chooseViewModel.isPlaying) {
            [self didClickStopAndPlay];
        }
        [self.timeBar setUpPlayProgressControlTintColor:NO];
        
        [self.timeEffectView selectTimeEffect:self.chooseViewModel.publishViewModel.repoVideoInfo.video.effect_timeMachineType];
        [self switchToTimeEffectsViewWithAnimation:YES];
        
        if ([self.chooseViewModel.publishViewModel.repoVideoInfo.video totalVideoDuration] > [self p_videoMaxLength] || [self.timeEffectView hasValidMultiVoiceEffectSegment]) {
            if ([self.chooseViewModel.publishViewModel.repoVideoInfo.video totalVideoDuration] > [self p_videoMaxLength]) {
                [self.timeEffectView setDescriptionText:ACCLocalizedString(@"effect_time_limit_hint", @"Video length limit reached. You can still use reverse motion.")];
            } else {
                [self.timeEffectView setDescriptionText:ACCLocalizedString(@"by_section_disabled_hint", @"Voice effects are applied. You can use reverse motion.")];
            }
            
            for (HTSVideoSepcialEffect *timeEffect in [self.chooseViewModel allTimeEffects]) {
                if (timeEffect.timeMachineType == HTSPlayerTimeMachineTimeTrap || timeEffect.timeMachineType == HTSPlayerTimeMachineRelativity){
                    timeEffect.forbidden = YES;
                    [self.timeEffectView updateCellWithTimeEffect:timeEffect.timeMachineType];
                }
            }
        }
        if (self.chooseViewModel.containLyricSticker) {
            for (HTSVideoSepcialEffect *timeEffect in [self.chooseViewModel allTimeEffects]) {
                if (timeEffect.timeMachineType != HTSPlayerTimeMachineNormal) {
                    timeEffect.forbidden = YES;
                    [self.timeEffectView updateCellWithTimeEffect:timeEffect.timeMachineType];
                }
            }
        }
    }
}

- (void)configureBottomView
{
    [self registerNotification];
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    CGFloat bottomViewHeight = [self mediaSmallBottomViewHeight];
    
    self.bottomTabView = [[AWETabView alloc] init];
    self.bottomTabView.frame = CGRectMake(0, [self timeBarTopMargin] + [AWEVideoEffectMixTimeBar timeBarHeight], screenWidth, [self effectChooseViewFooterViewHeigth] + ACC_IPHONE_X_BOTTOM_OFFSET);
    self.bottomTabView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
    
    // reload bottom tab
    [self reloadBottomTabView];
    
    // cache category and color corresponded to effectID
    [self.chooseViewModel mapEffectIdForCategoryAndColorDict];
    
    @weakify(self);
    self.bottomTabView.shouldClickTabBlock = ^BOOL(NSInteger tabNum) {
        @strongify(self);
        BOOL isRedPacketVideo = [self.chooseViewModel isRedPacketVideo];
        if (isRedPacketVideo && tabNum == 1) {
            [ACCToast() show: ACCLocalizedString(@"red_packet_gesture_use_time_effect_hint", @"红包贴纸暂不支持此功能")];
            return NO;
        }
        return YES;
    };
    
    self.bottomTabView.clickedTabBlock = ^(NSInteger tabNum) {
        @strongify(self);
        self.bottomViewIndex = tabNum;
        [UIView animateWithDuration:0.2 animations:^{
            self.timeBar.alpha = 0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                self.timeBar.alpha = 1;
            }];
        }];
        
        // update category message
        AWEVideoEffectView *effectView = [self p_currentVideoEffectViewWithTabNum:tabNum];
        self.effectCategoryMessageLabel.text = [effectView effectCategoryTitle];
        
        // update revoke button status
        [self refreshRevokeButtonForOptimized];
        
        [self.chooseViewModel clickedTabViewAtIndex:tabNum];
    };
    [self.bottomView addSubview:self.bottomTabView];

    CGFloat leftOffset = 16;
    self.timeBar.frame = CGRectMake(leftOffset, [self timeBarTopMargin], [UIScreen mainScreen].bounds.size.width - 2 * leftOffset, [AWEVideoEffectMixTimeBar timeBarHeight]);
    [self.bottomView addSubview:self.timeBar];
    self.bottomView.frame = CGRectMake(0, 36.0, screenWidth, bottomViewHeight - 36.0);
    self.bottomBackgroundView.frame = CGRectMake(0, screenHeight, screenWidth, bottomViewHeight);
    [self.bottomBackgroundView addSubview:self.bottomView];
    [self.view addSubview:self.bottomBackgroundView];
    self.chooseViewModel.currentEffectViewType = AWEVideoEffectViewTypeFilter;
    
    AWEVideoEffectView *effectView = [self p_currentVideoEffectViewWithTabNum:self.bottomViewIndex];
    self.effectCategoryMessageLabel.text = [effectView effectCategoryTitle];
}

- (void)reloadBottomTabView {
    [self.chooseViewModel getBottomTabViewDataWithNetworkRequestBlock:^{
        [self showLoading];
    } showCacheBlock:^(NSArray * _Nonnull categoryArr) {
        [self showTabViewWithEffectCategories:categoryArr];
    }];
}

- (void)showTabViewWithEffectCategories:(NSArray *)categories {
    self.bottomTabView.hidden = NO;
    [self p_stopLoadingAnim];
    
    NSMutableArray<NSString *> *tabNames = [[NSMutableArray alloc] init];
    NSMutableArray<AWEVideoEffectView *> *tabViews = [[NSMutableArray alloc] init];
    NSMutableDictionary<NSString *, AWEVideoEffectView *> *categoryStickerViewMap = @{}.mutableCopy;
    
    [categories enumerateObjectsUsingBlock:^(IESCategoryModel *category, NSUInteger idx, BOOL * _Nonnull stop) {
        
        AWEVideoEffectViewType viewType = AWEVideoEffectViewTypeFilter;
        if ([category.categoryKey isEqualToString:@"trans"]) {
            viewType = AWEVideoEffectViewTypeTransition;
        } else if ([category.categoryKey isEqualToString:@"sticker"]) {
            viewType = AWEVideoEffectViewTypeTool;
            if (self.chooseViewModel.publishViewModel.repoTextMode.isTextMode) { // text mode does not have any faces, could not apply sticker
                return ;
            }
        }
        
        AWEVideoEffectView *effectView = [[AWEVideoEffectView alloc] initWithType:viewType effects:category.effects effectCategory:category.categoryKey publishModel:self.chooseViewModel.publishViewModel];
        effectView.accessibilityLabel = category.categoryName ?: @"";
        effectView.delegate = self;
        [tabNames addObject:category.categoryName ?: @""];
        [tabViews addObject:effectView];
        if ([self.chooseViewModel p_isStickerCategory:category.categoryKey]) { // 只存道具tab，用于后面处理已选中特效逻辑
            NSString *key = [NSString stringWithFormat:@"%@_%zd", category.categoryKey, idx]; // in case more than 1 sticker tab
            categoryStickerViewMap[key] = effectView;
        }
    }];
    
    // Append time effect tab and view
    if (![self oneCLickFilmingHideTimeEffect]
        && ![self MVHideTimeEffect]
        && self.chooseViewModel.publishViewModel.repoContext.videoType != AWEVideoTypeQuickStoryPicture
        && self.chooseViewModel.publishViewModel.repoContext.videoType != AWEVideoTypePhotoToVideo
        && self.chooseViewModel.publishViewModel.repoContext.videoType != AWEVideoTypeLivePhoto
        && !self.chooseViewModel.isMultiSegPropVideo
        && self.chooseViewModel.publishViewModel.repoVideoInfo.canvasType != ACCVideoCanvasTypeShareAsStory
        && self.chooseViewModel.publishViewModel.repoVideoInfo.canvasType != ACCVideoCanvasTypeRePostVideo &&
        !(self.chooseViewModel.publishViewModel.repoDuet.isDuet && self.chooseViewModel.publishViewModel.repoDuet.isDuetUpload)
        && !self.chooseViewModel.publishViewModel.repoAudioMode.isAudioMode) {
        [tabNames addObject: ACCLocalizedString(@"tab_time", @"时间")];
        self.timeEffectView.accessibilityLabel = @"时间";
        [tabViews addObject:self.timeEffectView];
    }
    
    [self.bottomTabView setNamesOfTabs:[tabNames copy] views:[tabViews copy] withStartIndex:self.bottomViewIndex];
    self.effectViews = tabViews;
    self.chooseViewModel.effectCategories = categories;
    [self.chooseViewModel mapEffectIdForCategoryAndColorDict];
    
    [categoryStickerViewMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, AWEVideoEffectView * _Nonnull obj, BOOL * _Nonnull stop) {
        // notice: key format is "sticker_{index}, eg. sticker_1, sticker_2..."
        NSString *stickerEffectId = nil;
        stickerEffectId = [self.chooseViewModel getStickerEffectIdInDisplayTimeRanges];
        if (stickerEffectId) {
            [obj selectToolEffectWithEffectId:stickerEffectId animated:YES];
            // no delegate methods is called, so we sync data manually
            self.selectedEffectModel = obj.selectedToolEffect;
        }
    }];
    
    [self refreshRevokeButton];
}

- (void)showDefaultTabViewReloading:(BOOL)reloading {
    self.bottomTabView.hidden = NO;
    [self p_stopLoadingAnim];
    
    NSMutableArray<NSString *> *tabNames = [[NSMutableArray alloc] init];
    NSMutableArray<AWEVideoEffectView *> *tabViews = [[NSMutableArray alloc] init];
    
    NSDictionary *dic = @{@"key": @"filter",
                          @"name": @"filter",
                          @"id": @(1501)
                          };
    IESCategoryModel *category = [MTLJSONAdapter modelOfClass:[IESCategoryModel  class] fromJSONDictionary:dic error:nil];
    
    
    NSArray<IESEffectModel *> *effects = reloading ? @[] : [self.chooseViewModel builtinNormalEffects];
    AWEVideoEffectView *effectView = [[AWEVideoEffectView alloc] initWithType:AWEVideoEffectViewTypeFilter effects:effects effectCategory:category.categoryKey publishModel:self.chooseViewModel.publishViewModel];
    effectView.delegate = self;
    [tabNames addObject:category.categoryName];
    [tabViews addObject:effectView];
    
    // time Effect should not be applied on MV
    if ([self oneCLickFilmingHideTimeEffect]
        && ![self MVHideTimeEffect]
        && self.chooseViewModel.publishViewModel.repoContext.videoType != AWEVideoTypeQuickStoryPicture
        && self.chooseViewModel.publishViewModel.repoContext.videoType != AWEVideoTypePhotoToVideo) {
        [tabNames addObject:ACCLocalizedString(@"tab_time", @"时间")];
        [tabViews addObject:self.timeEffectView];
    }
    
    [self.bottomTabView setNamesOfTabs:[tabNames copy] views:[tabViews copy]];
    self.effectViews = tabViews;
    
    self.chooseViewModel.effectCategories = @[category];
    [self.chooseViewModel mapEffectIdForCategoryAndColorDict];
    
    [self refreshRevokeButton];
}

- (void)showLoading {
    [self.bottomTabView setNamesOfTabs:@[] views:@[]];
    self.effectViews = @[];
    self.chooseViewModel.effectCategories = @[];
    self.bottomTabView.hidden = YES;
    [self p_startLoadingAnim];
}

#pragma mark - ACCEditPreviewMessageProtocol

- (void)playerCurrentPlayTimeChanged:(NSTimeInterval)currentTime
{
    [self updateExclusiveStickerContainerStickerHiddenStatusWithCurrentPlayerTime:currentTime];
    
    if ([self.chooseViewModel.editService.preview status] == HTSPlayerStatusPlaying) {
        [self.timeBar updatePlayProgressWithTime:currentTime totalDuration:[self.chooseViewModel.publishViewModel.repoVideoInfo.video totalVideoDuration]];
    }
}

#pragma mark - Action
- (void)didClickCancelBtn:(UIButton *)btn
{
    void (^block)(void) = ^ {
        UIImage *snap = [self.playerContainer acc_snapshotImageAfterScreenUpdates:NO withSize:self.view.bounds.size];
        
        [self.chooseViewModel didClickCancelBtn];
        if (self.willDismissBlock) {
            self.willDismissBlock(snap);
        }

        if (self.transitionService) {
            [self.transitionService dismissViewController:self completion:^{
                ACCBLOCK_INVOKE(self.didDismissBlock);
            }];
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                ACCBLOCK_INVOKE(self.didDismissBlock);
            }];
        }
    };
    
    //save origin data，show "Do not save" alert when quit if there is any change
    NSMutableString *rangeIds = [self.chooseViewModel getRangeIdsFromTimeRangeArray:[self.chooseViewModel.publishViewModel.repoVideoInfo.video.effect_operationTimeRange copy]];
    BOOL hasOperation = ![self.chooseViewModel.originalRangeIds isEqualToString:rangeIds];
    if (hasOperation) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message: ACCLocalizedString(@"dont_safe_effect_hint", @"不保存本次添加的特效？")  preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"dont_safe",@"不保存") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            block();
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [ACCAlert() showAlertController:alertController animated:YES];

    } else {
        block();
    }
}

- (void)didClickSaveBtn:(UIButton *)btn
{
    UIImage *snap = [self.playerContainer acc_snapshotImageAfterScreenUpdates:NO withSize:self.view.bounds.size];
    [self.chooseViewModel didClickSaveBtn];

    ACCBLOCK_INVOKE(self.willDismissBlock, snap);
    if (self.transitionService) {
        [self.transitionService dismissViewController:self completion:^{
            ACCBLOCK_INVOKE(self.didDismissBlock);
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            ACCBLOCK_INVOKE(self.didDismissBlock);
        }];
    }
}

- (void)refreshMovingView:(CGFloat)lastTime
{
    [self.timeBar updatePlayProgressWithTime:lastTime totalDuration:[self.chooseViewModel.publishViewModel.repoVideoInfo.video totalVideoDuration]];
}

- (void)didClickedRevokeButton:(id)sender
{
    AWEVideoEffectView *effectView = [self p_currentVideoEffectViewWithTabNum:self.bottomViewIndex];
    [effectView didClickedRevokeBtn:sender];
}

- (void)didClickStopAndPlay
{
    NSString *clickTypeStr = nil;
    if (self.chooseViewModel.isPlaying) {
         //pause
        self.timeBar.playProgressControl.alpha = 1;
        self.timeBar.playProgressControl.userInteractionEnabled = YES;
        [self.chooseViewModel.editService.preview seekToTime:CMTimeMakeWithSeconds(self.chooseViewModel.editService.preview.currentPlayerTime, 1000000) completionHandler:nil];
        self.chooseViewModel.isPlaying = NO;
        clickTypeStr = @"stop";
    } else {
        //进入播放状态
        self.timeBar.playProgressControl.alpha = 1;
        self.timeBar.playProgressControl.userInteractionEnabled = YES;
        self.chooseViewModel.editService.preview.autoRepeatPlay = YES;
        [self.chooseViewModel.editService.preview play];
        self.chooseViewModel.isPlaying = YES;
        clickTypeStr = @"play";
    }

    [ACCTracker() trackEvent:@"preview_item"
                      params:@{
                          @"click_type" : clickTypeStr ?: @"",
                          @"function_type" : @"effect",
                          @"shoot_way" : self.chooseViewModel.publishViewModel.repoTrack.referString ?: @"",
                          @"content_source" : [self.chooseViewModel.publishViewModel.repoTrack referExtra][@"content_source"] ?: @"",
                          @"content_type" : [self.chooseViewModel.publishViewModel.repoTrack referExtra][@"content_type"] ?: @"",
                          @"is_multi_content" : self.chooseViewModel.publishViewModel.repoTrack.mediaCountInfo[@"is_multi_content"] ?: @"",
                          @"mix_type" : [self.chooseViewModel.publishViewModel.repoTrack referExtra][@"mix_type"] ?: @"",
                          @"creation_id" : self.chooseViewModel.publishViewModel.repoContext.createId ?: @"",
                      }];
}

#pragma mark - Notification

- (void)onEffectUpdated:(NSNotification *)notification {
    IESEffectModel *effect = notification.object;
    NSString *categoryKey = [self.chooseViewModel effectCategoryWithEffectId:effect.effectIdentifier];
    if (effect && categoryKey) {
        [self.chooseViewModel.effectCategories enumerateObjectsUsingBlock:^(IESCategoryModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.categoryKey == categoryKey) {
                if ([obj.effects containsObject:effect]) {
                    AWEVideoEffectView *effectView = [self currentVideoEffectViewWithIndex:idx categoryKey:categoryKey];
                    [effectView updateCellWithEffect:effect];
                    *stop = YES;
                }
            }
        }];
    }
}

- (void)onEffectListUpdated:(NSNotification *)notification {
    BOOL updated = [notification.object boolValue];
    if (updated) {
        [self reloadBottomTabView];
    } else if ([self.chooseViewModel normalEffectPlatformModel].categories.count == 0) {
        [ACCToast() show:ACCLocalizedString(@"com_mig_no_internet_connection_connect_to_the_internet_and_try_again_wemcin", @"网络错误，请检查网络链接")];
        [self showDefaultTabViewReloading:NO];
    }
    [self.chooseViewModel mapEffectIdForCategoryAndColorDict];
}

- (void)reloadEffectViews {
    // reload cell's UI and animation when app becomes active
    for (AWEVideoEffectView *effectView in self.effectViews) {
        if (effectView.type != AWEVideoEffectViewTypeTime) {
            [effectView reload];
        }
    }
}

- (AWEVideoEffectView *)currentVideoEffectViewWithIndex:(NSUInteger)index categoryKey:(NSString *)categoryKey
{
    if (index < 0 || index >= self.effectViews.count) {
        return nil;
    }
    
    __block AWEVideoEffectView *effectView = [self.effectViews objectAtIndex:index];
    if ([effectView.effectCategory isEqualToString:categoryKey]) {
        return effectView;
    }
    
    [self.effectViews enumerateObjectsUsingBlock:^(AWEVideoEffectView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.effectCategory isEqualToString:categoryKey]) {
            effectView = obj;
            *stop = YES;
        }
    }];
    
    return effectView;
}

#pragma mark - AWEVideoEffectViewDelegate
- (void)videoEffectView:(AWEVideoEffectView *)effectView beginLongPressWithType:(IESEffectModel *)effect
{
    [self.chooseViewModel videoEffectView:effectView beginLongPressWithType:effect];
}

- (void)videoEffectView:(AWEVideoEffectView *)effectView beingLongPressWithType:(IESEffectModel *)effect
{
    [self.chooseViewModel videoEffectView:effectView beingLongPressWithType:effect];
}

- (void)videoEffectView:(AWEVideoEffectView *)effectView didFinishLongPressWithType:(IESEffectModel *)effect
{
    [self.chooseViewModel videoEffectView:effectView didFinishLongPressWithType:effect];
}

- (void)videoEffectView:(AWEVideoEffectView *)effectView didCancelLongPressWithType:(IESEffectModel *)effect
{
    [self videoEffectView:effectView didFinishLongPressWithType:effect];
}

//click revoke button
- (void)videoEffectView:(AWEVideoEffectView *)effectView didClickedRevokeBtn:(UIButton *)btn;
{
    [self.chooseViewModel videoEffectView:effectView didClickedRevokeBtn:btn];
}

//click transition effect
- (void)videoEffectView:(AWEVideoEffectView *)effectView clickedCellWithTransitionEffect:(IESEffectModel *)effect {
    [self.chooseViewModel videoEffectView:effectView clickedCellWithTransitionEffect:effect];
}

//select tool effect
- (void)videoEffectView:(AWEVideoEffectView *)effectView didSelectToolEffect:(IESEffectModel *)effect
{
    
    // show hint
    if (effect.hintLabel.length > 0) {
        [ACCToast() show:effect.hintLabel onView:self.playerContainer];
    } else {
        [ACCToast() dismissToast];
    }
    [self.chooseViewModel videoEffectView:effectView didSelectToolEffect:effect];
    
    // 添加道具特效
    CGFloat totalVideoDuration = self.chooseViewModel.publishViewModel.repoVideoInfo.video.totalVideoDuration;
    if (totalVideoDuration > 0) {
        // Update UI
        [self refreshEffectFragments];
        [self refreshRevokeButton];
        NSString *category = [self.chooseViewModel effectCategoryWithEffectId:effect.effectIdentifier];
        if (category) {
            [self.timeBar updateShowingToolEffectRangeViewIfNeededWithCategoryKey:category effectSelected:(effect!=nil)];
        }
        
        //transition animation switch from tool effect to  another
        if (self.selectedEffectModel) {
           [self.timeBar animateElements];
        }
        self.selectedEffectModel = effect;
        
        for (AWEVideoEffectView *effectView in self.effectViews) {
            if ([self.chooseViewModel p_isStickerCategory:effectView.effectCategory]) {
                [effectView resetToolEffectTip];
            }
        }
    } else {
        AWELogToolError(AWELogToolTagEdit, @"apply tool effect error, totalVideoDuration <=0, effect id:%@, effect name:%@",
                        effect.effectIdentifier,effect.effectName);
    }
}

- (void)videoEffectView:(AWEVideoEffectView *)effectView didDeselectToolEffect:(IESEffectModel *)effect
{
    // hide toast
    [ACCToast() dismissToast];
    if (self.chooseViewModel.isPlaying) {
        [self didClickStopAndPlay];
    }

    [self.chooseViewModel videoEffectView:effectView didDeselectToolEffect:effect];
    for (AWEVideoEffectView *effectView in self.effectViews) {
        if ([self.chooseViewModel p_isStickerCategory:effectView.effectCategory]) {
            [effectView resetToolEffectTip];
        }
    }
    self.selectedEffectModel = nil;
}

//time effect
- (BOOL)videoEffectViewShouldShowClickedStyleWithTimeEffect:(HTSVideoSepcialEffect *)effect
{
    if (effect.timeMachineType == HTSPlayerTimeMachineTimeTrap || effect.timeMachineType == HTSPlayerTimeMachineRelativity) {
        CGFloat timeAddCount = 0;
        if (effect.timeMachineType == HTSPlayerTimeMachineTimeTrap) {
            timeAddCount = 2;
        } else if (effect.timeMachineType == HTSPlayerTimeMachineRelativity) {
            timeAddCount = 1;
        }
        if ([self.chooseViewModel.publishViewModel.repoVideoInfo.video totalVideoDuration] + timeAddCount * self.chooseViewModel.timeEffectDefaultDuration > [self p_videoMaxLength]) {
            [ACCToast() show:ACCLocalizedString(@"effect_time_limit", @"Video length limit reached") onView:self.view];
            return NO;
        }
    }

    if (self.chooseViewModel.publishViewModel.repoContext.videoType == AWEVideoTypeKaraoke) {
        [ACCToast() show:@"K歌模式不支持使用时间特效" onView:self.view];
        return NO;
    }
    if (self.chooseViewModel.containLyricSticker && effect.timeMachineType != HTSPlayerTimeMachineNormal) {
        [ACCToast() show:ACCLocalizedString(@"effect_time_mutex", @"Lyrics stickers and time effects can't be used at the same time") onView:self.view];
        return NO;
    }
    return YES;
}

- (void)videoEffectView:(AWEVideoEffectView *)effectVi clickedCellWithTimeEffect:(HTSVideoSepcialEffect *)effect showClickedStyle:(BOOL)showClickedStyle
{
    [self.chooseViewModel videoEffectView:effectVi clickedCellWithTimeEffect:effect showClickedStyle:showClickedStyle];
}

//filter effect
- (void)videoEffectView:(AWEVideoEffectView *)effectView didSelectEffect:(IESEffectModel *)effect {
    if (![self.chooseViewModel checkEffectIsDownloaded:effect]) {
        if (effectView.type == AWEVideoEffectViewTypeTool) {
            if (effectView.selectedToolEffect) {
                [effectView selectToolEffectWithEffectId:effectView.selectedToolEffect.effectIdentifier animated:NO];
            }
        }
        return;
    }
    // effect is downloaded
    switch (effectView.type) {
        case AWEVideoEffectViewTypeTool: {
            if (effectView.selectedToolEffect == effect) {
                [self videoEffectView:effectView didDeselectToolEffect:effect];
                [effectView deselectToolEffectWithEffectId:effect.effectIdentifier];
            } else {
                [self videoEffectView:effectView didSelectToolEffect:effect];
                [effectView selectToolEffectWithEffectId:effect.effectIdentifier animated:YES];
            }
        }
            break;
        case AWEVideoEffectViewTypeTransition: {
            [self videoEffectView:effectView clickedCellWithTransitionEffect:effect];
        }
            break;
        default:
            break;
    }
}

- (void)setIsPlaying:(BOOL)isPlaying
{
    [self.stopAndPlayImageView.layer removeAllAnimations];
    
    if (isPlaying) {
        [self.stopAndPlayBtn setSelected:YES];
        self.stopAndPlayBtn.accessibilityLabel = @"暂停";
        self.stopAndPlayBtn.accessibilityTraits = UIAccessibilityTraitButton;
        CABasicAnimation *opacityAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnim.fromValue = @(1);
        opacityAnim.toValue = @(0);
        opacityAnim.duration = 0.2;
        opacityAnim.fillMode = kCAFillModeForwards;
        opacityAnim.removedOnCompletion = NO;
        [self.stopAndPlayImageView.layer addAnimation:opacityAnim forKey:@"notshow"];
    } else {
        [self.stopAndPlayBtn setSelected:NO];
        self.stopAndPlayBtn.accessibilityLabel = @"播放";
        self.stopAndPlayBtn.accessibilityTraits = UIAccessibilityTraitButton;
        CABasicAnimation *opacityAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnim.fromValue = @(0);
        opacityAnim.toValue = @(1);
        opacityAnim.duration = 0.2;
        opacityAnim.fillMode = kCAFillModeForwards;
        opacityAnim.removedOnCompletion = NO;
        [self.stopAndPlayImageView.layer addAnimation:opacityAnim forKey:@"show"];
    }
}

- (void)setCurrentEffectTimeRange:(IESMMEffectTimeRange *)currentEffectTimeRange
{
    self.timeBar.currentEffectTimeRange = currentEffectTimeRange;
}

- (IESMMEffectTimeRange *)currentEffectTimeRange
{
    return self.timeBar.currentEffectTimeRange;
}

#pragma mark - AWEVideoEffectMixTimeBarDelegate 进度条代理
-(NSString *)effectIdWithEffectType:(IESEffectFilterType)type {
    return [self.chooseViewModel effectIdWithEffectType:type];
}

- (NSString *)effectCategoryWithEffectId:(NSString *)effectId {
    return [self.chooseViewModel effectCategoryWithEffectId:effectId];
}

- (UIColor *)effectColorWithEffectId:(NSString *)effectId {
    return [self.chooseViewModel effectColorWithEffectId:effectId];
}

- (void)userWillMoveTimeBarControl:(AWEVideoPlayControl *)control progress:(double)progress
{
    if (control == self.timeBar.playProgressControl) {
        if (self.chooseViewModel.isPlaying) {
            [self didClickStopAndPlay];
        }
    }
}

- (void)userDidMoveTimeBarControl:(AWEVideoPlayControl *)control progress:(double)progress
{    
    if (control == self.timeBar.playProgressControl) {
        [self.chooseViewModel userDidMoveTimeBarControl:control progress:progress];
    }
}

- (void)userDidFinishMoveTimeBarControl:(AWEVideoPlayControl *)control progress:(double)progress
{
    if (control == self.timeBar.playProgressControl) {
        [self.chooseViewModel userDidFinishMoveTimeBarControl:control progress:progress];
    }
}

#pragma mark - AWEVideoEffectScalableRangeView
- (CGFloat)userCouldChangeRangeViewEffectRange:(CGFloat)rangeFrom rangeTo:(CGFloat)rangeTo proportion:(CGFloat)proportion changeType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType inTimeEffectView:(BOOL)inTimeEffectView
{
    const CGFloat totalVideoDuration = self.chooseViewModel.publishViewModel.repoVideoInfo.video.totalVideoDuration;
    if (inTimeEffectView) {
        HTSPlayerTimeMachineType currentTimeMachineType = self.chooseViewModel.publishViewModel.repoVideoInfo.video.effect_timeMachineType;
        double timeEffectDuration = floor(totalVideoDuration * (rangeTo - rangeFrom) * 1000) / 1000;
        if (currentTimeMachineType == HTSPlayerTimeMachineTimeTrap || currentTimeMachineType == HTSPlayerTimeMachineRelativity) {
            CGFloat timeAddCount = 0;
            if (currentTimeMachineType == HTSPlayerTimeMachineTimeTrap) {
                timeAddCount = 2;
            } else if (currentTimeMachineType == HTSPlayerTimeMachineRelativity) {
                timeAddCount = 1;
            }

            if ([self.chooseViewModel.publishViewModel.repoVideoInfo.video totalVideoDuration] + timeAddCount * timeEffectDuration > [self p_videoMaxLength]) {
                CGFloat maxDuration = ([self p_videoMaxLength] - [self.chooseViewModel.publishViewModel.repoVideoInfo.video totalVideoDuration])/timeAddCount;
                if (self.showToastLimitFlag == NO) {
                    [ACCToast() show:ACCLocalizedString(@"effect_time_limit", @"Video length limit reached") onView:self.view];

                    self.showToastLimitFlag = YES;
                }
                return floor(maxDuration/totalVideoDuration * 1000)/1000;
            }
        }
       
    }
    return -1;
}

-(void)userWillChangeRangeViewEffectRangeInTimeEffectView:(BOOL)inTimeEffectView
{
    if (inTimeEffectView) {
        self.showToastLimitFlag = NO;
        if (self.chooseViewModel.isPlaying) {
            [self didClickStopAndPlay];
        }
    }
}

- (void)userDidChangeRangeViewEffectRange:(CGFloat)rangeFrom rangeTo:(CGFloat)rangeTo proportion:(CGFloat)proportion changeType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType inTimeEffectView:(BOOL)inTimeEffectView
{
    const CGFloat totalVideoDuration = self.chooseViewModel.publishViewModel.repoVideoInfo.video.totalVideoDuration;
    if (inTimeEffectView) {
        [self.chooseViewModel.editService.preview seekToTime:CMTimeMakeWithSeconds(rangeFrom * totalVideoDuration,1000000)];
        self.chooseViewModel.timeEffectTimeRange.startTime = floor(totalVideoDuration * rangeFrom * 1000) / 1000;;
        self.chooseViewModel.timeEffectTimeRange.endTime = floor(totalVideoDuration * rangeTo * 1000) / 1000;
        const CGFloat duration = floor(totalVideoDuration * proportion * 1000) / 1000;
        [self.timeEffectView setUpScalableRangeViewTip:duration];
    } else {
        const CGFloat duration = floor(totalVideoDuration * proportion * 1000) / 1000;
        //once that rangeview changes it's length ,the tips show xx s selected
        for (AWEVideoEffectView *effectView in self.effectViews) {
            if ([self.chooseViewModel p_isStickerCategory:effectView.effectCategory]) {
                [effectView setUpScalableRangeViewTip:duration];
            }
        }
    }
}

- (void)userDidFinishChangeRangeViewEffectRange:(CGFloat)rangeFrom rangeTo:(CGFloat)rangeTo changeType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType inTimeEffectView:(BOOL)inTimeEffectView
{
    [self.chooseViewModel userDidFinishChangeRangeViewEffectRange:rangeFrom rangeTo:rangeTo changeType:changeType inTimeEffectView:inTimeEffectView];
}

#pragma mark - view controller prefers

- (BOOL)prefersStatusBarHidden
{
    return ![UIDevice acc_isIPhoneX];
}

#pragma mark -

- (void)updateExclusiveStickerContainerStickerHiddenStatusWithCurrentPlayerTime:(CGFloat)currentPlayerTime
{
    for (NSArray <ACCStickerViewType> *sticker in self.stickerContainerView.allStickerViews) {
        if ([sticker conformsToProtocol:@protocol(ACCPlaybackResponsibleProtocol)]) {
            [(id<ACCPlaybackResponsibleProtocol>)sticker updateWithCurrentPlayerTime:currentPlayerTime];
        }
    }
}

#pragma mark - Getter & Setter

- (UIButton *)cancelBtn
{
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelBtn.alpha = 0;
        [_cancelBtn setTitle:ACCLocalizedCurrentString(@"cancel") forState:UIControlStateNormal];
        [_cancelBtn.titleLabel setFont:[ACCFont() acc_systemFontOfSize:17 weight:ACCFontWeightRegular]];
        UIColor *titleColor = ACCResourceColor(ACCUIColorConstTextInverse);
        [_cancelBtn setTitleColor:titleColor forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(didClickCancelBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

- (UIButton *)saveBtn
{
    if (!_saveBtn) {
        _saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _saveBtn.alpha = 0;
        [_saveBtn setTitle:ACCLocalizedString(@"save", @"save") forState:UIControlStateNormal];
        [_saveBtn.titleLabel setFont:[ACCFont() acc_systemFontOfSize:17 weight:ACCFontWeightMedium]];
        UIColor *titleColor = ACCResourceColor(ACCUIColorConstTextInverse);
        [_saveBtn setTitleColor:titleColor forState:UIControlStateNormal];
        [_saveBtn addTarget:self action:@selector(didClickSaveBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveBtn;
}

- (UIView *)playerContainer
{
    if (!_playerContainer) {
        _playerContainer = [UIView new];
        _playerContainer.layer.cornerRadius = 2;
        _playerContainer.layer.masksToBounds = YES;
        _playerContainer.accrtl_viewType = ACCRTLViewTypeNormal;
    }
    return _playerContainer;
}

- (UIButton *)stopAndPlayBtn
{
    if (!_stopAndPlayBtn) {
        _stopAndPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_stopAndPlayBtn addTarget:self action:@selector(didClickStopAndPlay) forControlEvents:UIControlEventTouchUpInside];
        _stopAndPlayBtn.accessibilityLabel = _stopAndPlayBtn.isSelected ? @"暂停" : @"播放";
        _stopAndPlayBtn.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return _stopAndPlayBtn;
}

- (UIImageView *)stopAndPlayImageView
{
    if (_stopAndPlayImageView == nil) {
        _stopAndPlayImageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"iconBigplaymusic")];
        _stopAndPlayImageView.contentMode = UIViewContentModeCenter;
    }
    return _stopAndPlayImageView;
}

- (AWEVideoEffectMixTimeBar *)timeBar
{
    if (!_timeBar) {
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        _timeBar = [[AWEVideoEffectMixTimeBar alloc] initWithFrame:CGRectMake(0, 0, screenWidth, [AWEVideoEffectMixTimeBar timeBarHeight])];
        _timeBar.delegate = self;
        _timeBar.backgroundColor = ACCResourceColor(ACCUIColorConstIconPrimary);
        _timeBar.timeReverseMask.backgroundColor = [ACCResourceColor(ACCColorPrimary) colorWithAlphaComponent:0.34];
    }
    return _timeBar;
}

- (UIView *)bottomView
{
    if (_bottomView == nil) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH, [self effectChooseViewFooterViewHeigth] + [AWEVideoEffectMixTimeBar timeBarHeight] + [self timeBarTopMargin] + ACC_IPHONE_X_BOTTOM_OFFSET)
                                                   byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                         cornerRadii:CGSizeMake(12, 12)];
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = path.CGPath;
        _bottomView.layer.mask = layer;
    }
    return _bottomView;
}

- (UIView *)bottomBackgroundView
{
    if (!_bottomBackgroundView) {
        _bottomBackgroundView = [[UIView alloc] init];
        _bottomBackgroundView.backgroundColor = [UIColor clearColor];
        
        CGFloat height = [self effectChooseViewFooterViewHeigth] + [AWEVideoEffectMixTimeBar timeBarHeight] + [self timeBarTopMargin] + ACC_IPHONE_X_BOTTOM_OFFSET + 36.0;
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(0, 36.0)];
        [path addLineToPoint:CGPointMake(ACC_SCREEN_WIDTH - 68.0, 36.0)];
        [path addLineToPoint:CGPointMake(ACC_SCREEN_WIDTH - 68.0, 0)];
        [path addLineToPoint:CGPointMake(ACC_SCREEN_WIDTH, 0)];
        [path addLineToPoint:CGPointMake(ACC_SCREEN_WIDTH, height)];
        [path addLineToPoint:CGPointMake(0, height)];
        [path addLineToPoint:CGPointMake(0, 36.0)];
        
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = path.CGPath;
        _bottomBackgroundView.layer.mask = layer;
    }
    
    return _bottomBackgroundView;
}

- (AWEVideoEffectView *)timeEffectView
{
    if (_timeEffectView == nil) {
        _timeEffectView = [[AWEVideoEffectView alloc] initWithType:AWEVideoEffectViewTypeTime effects:nil effectCategory:nil publishModel:self.chooseViewModel.publishViewModel];
        _timeEffectView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
        _timeEffectView.delegate = self;
        _timeEffectView.publishModel = self.chooseViewModel.publishViewModel;
    }
    return _timeEffectView;
}

- (UIView *)backgroundView
{
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    }
    return _backgroundView;
}

- (ACCAnimatedButton *)backIconButton
{
    if (!_backIconButton) {
        UIImage *img = ACCResourceImage(@"icon_edit_bar_cancel");
        _backIconButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(16, 14, 24, 24)];
        _backIconButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-20, -20, -20, -20);
        [_backIconButton setImage:img forState:UIControlStateNormal];
        [_backIconButton setImage:img forState:UIControlStateHighlighted];
        [_backIconButton addTarget:self action:@selector(didClickCancelBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backIconButton;
}

- (ACCAnimatedButton *)saveIconButton
{
    if (!_saveIconButton) {
        UIImage *img = ACCResourceImage(@"icon_edit_bar_done");
        _saveIconButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(ACC_SCREEN_WIDTH - 40, 14, 24, 24)];
        _saveIconButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-20, -20, -20, -20);
        [_saveIconButton setImage:img forState:UIControlStateNormal];
        [_saveIconButton setImage:img forState:UIControlStateHighlighted];
        [_saveIconButton addTarget:self action:@selector(didClickSaveBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveIconButton;
}

- (ACCAnimatedButton *)revokeButton
{
    if (!_revokeButton) {
        _revokeButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        [_revokeButton setImage:ACCResourceImage(@"iconEffectUndo") forState:UIControlStateNormal];
        [_revokeButton setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse2) forState:UIControlStateNormal];
        [_revokeButton setTitle:ACCLocalizedString(@"effect_delte", @"撤销") forState:UIControlStateNormal];
        [_revokeButton.titleLabel setFont:[ACCFont() acc_systemFontOfSize:13]];
        _revokeButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -10, -10, -10);
        [_revokeButton addTarget:self action:@selector(didClickedRevokeButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _revokeButton;
}

- (UILabel *)effectCategoryMessageLabel
{
    if (!_effectCategoryMessageLabel) {
        _effectCategoryMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(40.0, 0, ACC_SCREEN_WIDTH - 80.0, 52.0)];
        _effectCategoryMessageLabel.textAlignment = NSTextAlignmentCenter;
        _effectCategoryMessageLabel.textColor = ACCResourceColor(ACCColorConstTextInverse2);
        _effectCategoryMessageLabel.font = [ACCFont() acc_systemFontOfSize:13 weight:ACCFontWeightMedium];
        _effectCategoryMessageLabel.text = @"样式";
    }
    return _effectCategoryMessageLabel;
}

#pragma mark - helper

- (void)p_startLoadingAnim {
    self.loadingView = [ACCLoading() showLoadingOnView:self.bottomView];
}

- (void)p_stopLoadingAnim {
    [self.loadingView dismiss];
}

- (void)p_startApplyToolEffect:(NSString *)stickerID
{
    [ACCLoading() showWindowLoadingWithTitle:ACCLocalizedString(@"ss_loading", @"加载中...") animated:NO];
}

- (void)p_stopToolEffectLoadingIfNeeded
{
    [ACCLoading() dismissWindowLoadingWithAnimated:NO];
}

- (NSInteger)p_videoMaxLength
{
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    return MAX([config videoMaxSeconds], [config videoUploadMaxSeconds]);
}

- (AWEVideoEffectView *)p_currentVideoEffectViewWithTabNum:(NSInteger)tabNum
{
    AWEVideoEffectView *effectView = [self.effectViews acc_objectAtIndex:tabNum];
    if (!effectView) {
        effectView = self.effectViews.firstObject;
    }
    
    return effectView;
}

- (BOOL)oneCLickFilmingHideTimeEffect
{
    if (ACCConfigInt(kConfigInt_smart_video_entrance) == ACCOneClickFlimingEntranceNoButton) {
        AWEVideoType videoType = self.chooseViewModel.publishViewModel.repoContext.videoType;
        AWEVideoSource videoSource = self.chooseViewModel.publishViewModel.repoContext.videoSource;
        ACCFeedType feedType = self.chooseViewModel.publishViewModel.repoContext.feedType;

        if (videoType == AWEVideoTypeNormal && videoSource != AWEVideoSourceCapture) {
            return YES;
        } else if (videoType == AWEVideoTypePhotoToVideo) {
            if (self.chooseViewModel.publishViewModel.repoUploadInfo.selectedUploadAssets.count == 1 &&
                self.chooseViewModel.publishViewModel.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone) {
                return NO;
            }
            return YES;
        } else if (videoType == AWEVideoTypeOneClickFilming && feedType == ACCFeedTypeOneClickFilming) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)MVHideTimeEffect
{
    if ([self.chooseViewModel.publishViewModel.repoCutSame isNewCutSameOrSmartFilming]) {
        return self.chooseViewModel.publishViewModel.repoContext.isMVVideo;
    } else {
        return self.chooseViewModel.publishViewModel.repoCutSame.isClassicalMV;
    }
}

#pragma mark - AWEVideoEffectChooseAnimationProtocol

- (UIView *)mediaSmallMediaContainer
{
    return self.playerContainer;
}

- (UIView *)mediaSmallBottomView
{
    return self.bottomBackgroundView;
}

- (CGRect)mediaSmallMediaContainerFrame
{
    CGFloat playerY = ACC_STATUS_BAR_NORMAL_HEIGHT;
    if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeDisabled) {
        playerY += 52;
    }
    
    CGFloat playerHeight = [UIScreen mainScreen].bounds.size.height - (playerY + kAWEVideoEffectChooseMidMargin + [self effectChooseViewFooterViewHeigth] + [self timeBarTopMargin]) - ACC_IPHONE_X_BOTTOM_OFFSET;
    CGFloat playerWidth = self.view.acc_width;
    CGFloat playerX = (self.view.bounds.size.width - playerWidth) / 2;
    CGSize videoSize = CGSizeMake(540, 960);
    if (!CGRectEqualToRect(self.chooseViewModel.publishViewModel.repoVideoInfo.playerFrame, CGRectZero)) {
        videoSize = self.chooseViewModel.publishViewModel.repoVideoInfo.playerFrame.size;
    }
    return AVMakeRectWithAspectRatioInsideRect(videoSize, CGRectMake(playerX, playerY, playerWidth, playerHeight));
}

- (CGFloat)mediaSmallBottomViewHeight
{
    return [self effectChooseViewFooterViewHeigth] + [self timeBarTopMargin] + [AWEVideoEffectMixTimeBar timeBarHeight] + ACC_IPHONE_X_BOTTOM_OFFSET + 36.0;
}

- (NSArray<UIView *>*)displayTopViews
{
    NSMutableArray<UIView *> *topViews = [NSMutableArray array];
    [topViews acc_addObject:self.cancelBtn];
    [topViews acc_addObject:self.saveBtn];
    return topViews.copy;
}

- (CGFloat)timeBarTopMargin
{
    if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeDisabled) {
        return 24.f;
    } else {
        return 66.f;
    }
}

#pragma mark - UI Optimized

- (CGFloat)effectChooseViewFooterViewHeigth
{
    if ([ACCFont() acc_bigFontModeOn]) {
        return kAWEVideoEffectChoosebottomTabViewHeight + 15;
    }
    return kAWEVideoEffectChoosebottomTabViewHeight;
}

/// Adjust UI according to AB
- (void)p_setupUIOptimization
{
    if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeDisabled) {
        [self p_setupUIOptimizationPlayBtn:NO];
        [self p_setupUIOptimizationSaveCancelBtn:NO];
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeSaveCancelBtn) {
        [self p_setupUIOptimizationPlayBtn:NO];
        [self p_setupUIOptimizationSaveCancelBtn:YES];
        [self p_setupUIOptimizationReplaceIconWithText:YES];
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypePlayBtn) {
        [self p_setupUIOptimizationPlayBtn:YES];
        [self p_setupUIOptimizationSaveCancelBtn:YES];
        [self p_setupUIOptimizationReplaceIconWithText:YES];
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeReplaceIconWithText) {
        [self p_setupUIOptimizationPlayBtn:YES];
        [self p_setupUIOptimizationSaveCancelBtn:YES];
        [self p_setupUIOptimizationReplaceIconWithText:NO];
    }
}

- (void)p_setupUIOptimizationSaveCancelBtn:(BOOL)shouldOptimized
{
    if (shouldOptimized) {
        [self.bottomView addSubview:self.backIconButton];
        [self.bottomView addSubview:self.saveIconButton];
    } else {
        [self.view addSubview:self.cancelBtn];
        [self.view addSubview:self.saveBtn];
        
        ACCMasMaker(self.cancelBtn, {
            make.left.equalTo(@16);
            make.centerY.equalTo(self.view.mas_top).offset(52/2 + ([UIDevice acc_isIPhoneX] ? 44 : 0));
            make.height.equalTo(@(kAWEVideoEffectChooseCancelButtonHeight));
        });
        ACCMasMaker(self.saveBtn, {
            make.right.equalTo(@-16);
            make.centerY.equalTo(self.view.mas_top).offset(52/2 + ([UIDevice acc_isIPhoneX] ? 44 : 0));
            make.height.equalTo(@(kAWEVideoEffectChooseCancelButtonHeight));
        });
    }
}

- (void)p_setupUIOptimizationPlayBtn:(BOOL)shouldOptimized
{
    if (shouldOptimized) {
        [self.stopAndPlayBtn setImage:ACCResourceImage(@"cameraStickerPlay") forState:UIControlStateNormal];
        [self.stopAndPlayBtn setImage:ACCResourceImage(@"cameraStickerPause") forState:UIControlStateSelected];
        [self.bottomView addSubview:self.stopAndPlayBtn];
        self.stopAndPlayBtn.frame = CGRectMake(ACC_SCREEN_WIDTH - 40, 12, 28, 28);
        self.stopAndPlayBtn.center = CGPointMake(self.bottomView.frame.size.width / 2.f, self.stopAndPlayBtn.center.y);
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didClickStopAndPlay)];
        [self.playerContainer addGestureRecognizer:tapGesture];
    } else {
        [self.view addSubview:self.stopAndPlayBtn];
        [self.stopAndPlayBtn addSubview:self.stopAndPlayImageView];
        ACCMasMaker(self.stopAndPlayBtn, {
            make.center.equalTo(self.playerContainer);
            make.width.height.equalTo(self.playerContainer);
        });
        ACCMasMaker(self.stopAndPlayImageView, {
            make.left.top.right.bottom.equalTo(self.stopAndPlayBtn);
        });
    }
}

- (void)p_setupUIOptimizationReplaceIconWithText:(BOOL)shouldUseText
{
    if (shouldUseText) {
        [self.backIconButton setImage:nil forState:UIControlStateNormal];
        [self.backIconButton setImage:nil forState:UIControlStateHighlighted];
        [self.backIconButton setTitle:@"取消" forState:UIControlStateNormal];
        self.backIconButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:17];
        CGSize newSize = [self.backIconButton.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, 24.f)];
        self.backIconButton.frame = CGRectMake(16, 14, newSize.width, newSize.height);
        
        [self.saveIconButton setImage:nil forState:UIControlStateNormal];
        [self.saveIconButton setImage:nil forState:UIControlStateHighlighted];
        [self.saveIconButton setTitle:@"保存" forState:UIControlStateNormal];
        self.saveIconButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:17];
        newSize = [self.saveIconButton.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, 24.f)];
        self.saveIconButton.frame = CGRectMake(ACC_SCREEN_WIDTH - 16 - newSize.width, 14, newSize.width, newSize.height);
    }
}

#pragma mark - ACCEditTransitionViewControllerProtocol

- (UIImage *)dismissSnapImage
{
    return [self.playerContainer acc_snapshotImageAfterScreenUpdates:NO withSize:self.view.bounds.size];
}

@end

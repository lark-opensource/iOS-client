//
//  TMAVideoControlView.m
//  OPPluginBiz
//
//  Created by muhuai on 2018/4/24.
//

#import "TMAVideoControlView.h"
#import <OPFoundation/BDPI18n.h>
#import "MMMaterialDesignSpinner.h"
#import "TMABrightness.h"
#import "TMAPlayerModel.h"
#import "TMAVideoDefines.h"
#import "TMAVideoTitleLabel.h"
#import "TMAVideoLockButton.h"
#import "TMAVideoRateSelectionView.h"
#import "OPVideoControlSlider.h"
#import <OPFoundation/UIImage+EMA.h>
#import <Masonry/Masonry.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPVideoViewModel.h>
#import "OPVideoControlBottomView.h"
#import "OPVideoLoadFailView.h"
#import "OPVideoControlViewModel.h"
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>
#if __has_feature(modules)
@import ReactiveObjC;
#else
#import <ReactiveObjC/ReactiveObjC.h>
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

static const CGFloat ZFPlayerAnimationTimeInterval             = 3.0f;
static const CGFloat ZFPlayerControlBarAutoFadeOutTimeInterval = 0.35f;

#define BACKBTNSIDE  40
#define BACKBTNTOPOFFSET 20
#define BACKBTNLEFTOFFSET 15


@interface TMAVideoControlView() <OPVideoControlBottomViewDelegate, OPVideoControlSliderDelegate, UIGestureRecognizerDelegate>
/** 系统菊花 */
@property (nonatomic, strong) MMMaterialDesignSpinner *activity;
/** 重播按钮 */
@property (nonatomic, strong) UIView *repeatBtn;
/** 开始播放按钮 */
@property (nonatomic, strong) UIView *startBtn;
/** 控制层消失时候在底部显示的播放进度progress */
@property (nonatomic, strong) UIProgressView *bottomProgressView;
@property (nonatomic, strong) OPVideoLoadFailView *failedView;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) TMAVideoLockButton *lockBtn;
@property (nonatomic, strong) UIView *lockContainerView;
@property (nonatomic, strong) TMAVideoGradientView *topMask;
@property (nonatomic, strong) TMAVideoGradientView *bottomMask;
@property (nonatomic, strong) UIView *topContainer;
@property (nonatomic, strong) TMAVideoTitleLabel *titleLabel;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIButton *snapshotBtn;
@property (nonatomic, strong) OPVideoControlSlider *videoSlider;
@property (nonatomic, strong) OPVideoControlBottomView *bottomView;
@property (nonatomic, strong) TMAVideoRateSelectionView *rateSelectionView;

@property (nonatomic, strong) UITapGestureRecognizer *singleTapGesture;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

@property (nonatomic, strong) OPVideoControlViewModel *viewModel;
@property (nonatomic, strong) RACCompoundDisposable *disposables;

@end

@implementation TMAVideoControlView

- (instancetype)init {
    self = [super init];
    if (self) {
        BDPLogInfo(@"TMAVideoControlView init");
        _viewModel = [[OPVideoControlViewModel alloc] init];
        [self setupViews];
        
        // 初始化时重置controlView
        [self tma_playerResetControlView];
        
        [self listeningRotating];
        
        [self _bindData];
    }
    return self;
}

- (void)dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [self disposeIfNeeded];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateVideoSliderHidden];
}

- (void)setupViews {
    [self addSubview:self.containerView];
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.mas_safeAreaLayoutGuideLeft);
        make.top.mas_equalTo(self.mas_safeAreaLayoutGuideTop);
        make.right.mas_equalTo(self.mas_safeAreaLayoutGuideRight);
        make.bottom.mas_equalTo(self.mas_safeAreaLayoutGuideBottom);
    }];
    
    [self.containerView addSubview:self.lockContainerView];
    [self.lockContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.containerView);
    }];
    
    [self.containerView addSubview:self.lockBtn];
    [self.lockBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.containerView).mas_offset(16);
        make.centerY.mas_equalTo(self.containerView);
        make.height.mas_equalTo(40);
    }];
    
    [self.lockContainerView addSubview:self.topMask];
    [self.topMask mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.mas_equalTo(self);
        make.bottom.mas_equalTo(self.lockContainerView.mas_top).mas_offset(56);
    }];
    
    [self.lockContainerView addSubview:self.bottomMask];
    [self.bottomMask mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.mas_equalTo(self);
        make.top.mas_equalTo(self.lockContainerView.mas_bottom).mas_offset(-68);
    }];
    
    [self.lockContainerView addSubview:self.snapshotBtn];
    [self.snapshotBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.lockContainerView).mas_offset(-16);
        make.centerY.mas_equalTo(self.lockContainerView);
        make.width.height.mas_equalTo(40);
    }];
    
    [self.lockContainerView addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.lockContainerView).mas_equalTo(16);
        make.trailing.mas_equalTo(self.lockContainerView).mas_equalTo(-16);
        make.bottom.mas_equalTo(self.lockContainerView).mas_offset(-10);
        make.height.mas_equalTo(28);
    }];
    
    [self.lockContainerView addSubview:self.playBtn];
    [self.playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.lockContainerView);
        make.width.height.mas_equalTo(40);
    }];
    
    [self addSubview:self.topContainer];
    [self.topContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.trailing.mas_equalTo(self.containerView);
        make.height.mas_equalTo(56);
    }];
    
    [self.topContainer addSubview:self.backBtn];
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.topContainer).mas_offset(16);
        make.top.mas_equalTo(self.topContainer).mas_offset(12);
        make.width.height.mas_equalTo(20);
    }];
    
    [self.topContainer addSubview:self.titleLabel];
    [self updateTopAreaConstraints];
    
    [self addSubview:self.videoSlider];
    [self.videoSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.mas_equalTo(self.bottomView);
        make.bottom.mas_equalTo(self.bottomView.mas_top).mas_offset(-9);
        make.height.mas_equalTo(12);
    }];
    
    [self addSubview:self.repeatBtn];
    [self.repeatBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    
    [self addSubview:self.startBtn];
    [self.startBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    
    [self addSubview:self.activity];
    [self.activity mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.with.height.mas_equalTo(45);
    }];
    
    [self addSubview:self.failedView];
    [self.failedView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).mas_offset(16);
        make.left.mas_equalTo(self.mas_safeAreaLayoutGuideLeft).mas_offset(16);
        make.right.mas_equalTo(self.mas_safeAreaLayoutGuideRight).mas_offset(-16);
        make.bottom.mas_equalTo(self.mas_safeAreaLayoutGuideBottom).mas_offset(-16);
    }];
    
    [self addSubview:self.bottomProgressView];
    [self.bottomProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.mas_offset(0);
        make.bottom.mas_offset(0);
    }];
}

- (void)updateTopAreaConstraints {
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (self.viewModel.isFullScreen) {
            make.leading.mas_equalTo(self.backBtn.mas_trailing).mas_offset(8);
        } else {
            make.leading.mas_equalTo(self.topContainer).mas_offset(16);
        }
        make.centerY.mas_equalTo(self.backBtn);
        make.trailing.mas_equalTo(self.topContainer).mas_offset(-16);
    }];
}

- (void)updateWithPlayerModel:(TMAPlayerModel *)playerModel {
    self.titleLabel.content = playerModel.title;
    [self.viewModel updateWithPlayerModel:playerModel];
    
    if (self.doubleTapGesture && !self.viewModel.enablePlayGesture) {
        [self removeGestureRecognizer:self.doubleTapGesture];
        self.doubleTapGesture = nil;
    }
    if (self.panGesture && !self.viewModel.enableProgressGesture) {
        [self removeGestureRecognizer:self.panGesture];
        self.panGesture = nil;
    }
    [self addAllGesturesIfNeeded];
}

- (void)_bindData {
    [self disposeIfNeeded];
    RACCompoundDisposable *disposables = [RACCompoundDisposable compoundDisposable];
    
    @weakify(self)
    [disposables addDisposable:[[[[RACObserve(self.viewModel, playEnd) combineLatestWith:RACObserve(self.viewModel, playBtnPosition)] distinctUntilChanged] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        if (!self) return;
        BOOL showPlayBtn = !self.viewModel.playEnd && [self.viewModel showPlayBtnAtCenter];
        self.playBtn.hidden = !showPlayBtn;
    }]];
    
    [disposables addDisposable:[[[[RACObserve(self.viewModel, fullScreen) combineLatestWith:RACObserve(self.viewModel, viewShowingState)] distinctUntilChanged] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        self.backBtn.hidden = !self.viewModel.isFullScreen;
        self.lockBtn.hidden = ![self.viewModel showLockBtn];
        self.snapshotBtn.hidden = ![self.viewModel showSnapshotBtn];
        [self updateVideoSliderHidden];
        self.bottomProgressView.hidden = ![self.viewModel showBottomProgress];
        [self updateTopAreaConstraints];
    }]];
    
    self.disposables = disposables;
}

- (void)disposeIfNeeded {
    if (self.disposables) {
        [self.disposables dispose];
        self.disposables = nil;
    }
}

#pragma mark - Action

- (void)backBtnClick:(UIButton *)sender {
    BDPLogInfo(@"TMAVideoControlView backBtnClick");
    if ([self.tma_delegate respondsToSelector:@selector(tma_controlViewBackAction)]) {
        [self.tma_delegate tma_controlViewBackAction];
    }
}

- (void)lockScreenBtnClick:(BOOL)isLocked {
    BDPLogInfo(@"TMAVideoControlView lockScrrenBtnClick");
    [self tma_playerCancelAutoFadeOutControlView];
    [self animateLockContainerView:isLocked];
    if ([self.tma_delegate respondsToSelector:@selector(tma_controlView:isLocked:)]) {
        [self.tma_delegate tma_controlView:self isLocked:isLocked];
    }
}

- (void)repeatBtnClick:(UIButton *)sender {
    BDPLogInfo(@"TMAVideoControlView repeatBtnClick");
    if ([self.tma_delegate respondsToSelector:@selector(tma_repeatPlayAction)]) {
        [self.tma_delegate tma_repeatPlayAction];
    }
}

- (void)centerStartBtnClick:(UIButton *)sender {
    BDPLogInfo(@"TMAVideoControlView centerStartBtnClick");
    if ([self.tma_delegate respondsToSelector:@selector(tma_controlView:centerStartAction:)]) {
        [self.tma_delegate tma_controlView:self centerStartAction:sender];
    }
}

- (void)playBtnClick:(UIButton *)sender {
    BDPLogInfo(@"TMAVideoControlView playBtnClick");
    sender.selected = !sender.selected;
    if ([self.tma_delegate respondsToSelector:@selector(tma_controlView:playAction:isCenter:)]) {
        [self.tma_delegate tma_controlView:self playAction:sender isCenter:YES];
    }
}

- (void)retryBtnClicked {
    BDPLogInfo(@"TMAVideoControlView failBtnClick");
    if ([self.tma_delegate respondsToSelector:@selector(tma_controlViewRetryAction)]) {
        [self.tma_delegate tma_controlViewRetryAction];
    }
}

- (void)snapshotBtnClicked {
    BDPLogInfo(@"TMAVideoControlView snapshotBtnClick");
    if ([self.tma_delegate respondsToSelector:@selector(tma_controlViewSnapshotAction)]) {
        [self.tma_delegate tma_controlViewSnapshotAction];
    }
}

- (void)onSingleTapGestureRecognized:(UITapGestureRecognizer *)recognizer {
    BDPLogInfo(@"TMAVideoControlView single tap gesture");
    if ([self isAllGestureDisabled]) {
        return;
    }
    [self tma_playerShowOrHideControlView];
    [self tma_playerRemoveRateSelectionPanel];
}

- (void)onDoubleTapGestureRecognized:(UITapGestureRecognizer *)recognizer {
    BDPLogInfo(@"TMAVideoControlView double tap gesture, enable: %@, locked: %@", @(self.viewModel.enablePlayGesture), @(self.lockBtn.locked));
    if (!self.viewModel.enablePlayGesture || self.lockBtn.locked || self.rateSelectionView || [self isAllGestureDisabled]) {
        return;
    }
    if ([self.tma_delegate respondsToSelector:@selector(tma_controlViewDoubleTapAction)]) {
        [self.tma_delegate tma_controlViewDoubleTapAction];
    }
    if (!self.viewModel.showing) {
        [self tma_playerShowControlView];
    }
}

- (void)onPanGestureRecognized:(UIPanGestureRecognizer *)recognizer {
    BDPLogInfo(@"TMAVideoControlView pan gesture, enable: %@, locked: %@", @(self.viewModel.enableProgressGesture), @(self.lockBtn.locked));
    CGPoint translation = [recognizer translationInView:self];
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self videoSliderTouchBegan:self.videoSlider.currentValue];
            break;
        case UIGestureRecognizerStateChanged: {
            CGFloat targetValue = MIN(MAX(self.videoSlider.currentValue + translation.x / self.bounds.size.width, 0), 1);
            [self.videoSlider updateCurrentValue:targetValue];
            [self videoSliderValueChanged:targetValue];
        }
            break;
        case UIGestureRecognizerStateEnded:
            [self videoSliderTouchEnded:self.videoSlider.currentValue];
            break;
        default:
            break;
    }
    [recognizer setTranslation:CGPointZero inView:self];
}

/**
 *  屏幕方向发生变化会调用这里
 */
- (void)onDeviceOrientationChange {
    BDPLogInfo(@"TMAVideoControlView onDeviceOrientationChange");
    if (TMABrightness.sharedBrightness.isLockScreen) { return; }
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown || orientation == UIDeviceOrientationPortraitUpsideDown) { return; }
    if (!self.viewModel.isPlayEnd && !self.viewModel.showing) {
        // 显示、隐藏控制层
        [self tma_playerShowOrHideControlView];
    }
}

#pragma mark - OPVideoControlSliderDelegate

- (void)videoSliderTouchBegan:(CGFloat)value {
    BDPLogInfo(@"TMAVideoControlView progressSliderTouchBegan");
    [self.videoSlider highlightSlider:YES];
    if ([self.tma_delegate respondsToSelector:@selector(tma_controlView:progressSliderTouchBegan:)]) {
        [self.tma_delegate tma_controlView:self progressSliderTouchBegan:value];
    }
}

- (void)videoSliderValueChanged:(CGFloat)value {
    if ([self.tma_delegate respondsToSelector:@selector(tma_controlView:progressSliderValueChanged:)]) {
        [self.tma_delegate tma_controlView:self progressSliderValueChanged:value];
    }
}

- (void)videoSliderTouchEnded:(CGFloat)value {
    BDPLogInfo(@"TMAVideoControlView progressSliderTouchEnded");
    [self.videoSlider highlightSlider:NO];
    [self.videoSlider hideDraggingTime];
    if ([self.tma_delegate respondsToSelector:@selector(tma_controlView:progressSliderTouchEnded:)]) {
        [self.tma_delegate tma_controlView:self progressSliderTouchEnded:value];
    }
}

- (void)videoSliderSingleTapGestureRecognized:(UITapGestureRecognizer *)recognizer {
    BDPLogInfo(@"TMAVideoControlView videoSlider single tap");
    CGPoint point = [recognizer locationInView:recognizer.view];
    CGFloat length = recognizer.view.frame.size.width;
    // 视频跳转的value
    CGFloat tapValue = point.x / length;
    if ([self.tma_delegate respondsToSelector:@selector(tma_controlView:progressSliderTap:)]) {
        [self.tma_delegate tma_controlView:self progressSliderTap:tapValue];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGesture) {
        if (!self.viewModel.enableProgressGesture || self.lockBtn.locked || self.rateSelectionView || [self isAllGestureDisabled]) {
            return NO;
        }
        CGPoint velocity = [self.panGesture velocityInView:self];
        return fabs(velocity.x) > fabs(velocity.y);
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (self.viewModel.isPlayEnd || [touch.view isKindOfClass:[UISlider class]]) {
        return NO;
    }
    
    if (self.viewModel.showing) {
        CGPoint touchLocation = [touch locationInView:self];
        if (CGRectContainsPoint(self.topMask.frame, touchLocation) || CGRectContainsPoint(self.bottomMask.frame, touchLocation)) {
            return NO;
        }
    }
    
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && self.rateSelectionView) {
        CGRect untouchableArea = [self.rateSelectionView untouchableArea];
        if (self.btd_width < untouchableArea.size.width + 30) {
            return YES;
        }
        CGPoint pointInRateSelection = [touch locationInView:self.rateSelectionView];
        return !CGRectContainsPoint(untouchableArea, pointInRateSelection);
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer == self.panGesture && [otherGestureRecognizer isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]) {
        return YES;
    }
    return NO;
}

#pragma mark - Private Method

- (void)showControlView {
    self.viewModel.showing = YES;
    self.backgroundColor = UIColor.clearColor;
    self.containerView.alpha = 1;
    self.topContainer.alpha = self.lockBtn.locked ? 0 : 1;
    self.videoSlider.alpha = self.lockBtn.locked ? 0 : 1;
    self.bottomProgressView.alpha = 0;
    TMABrightness.sharedBrightness.isStatusBarHidden = NO;
}

- (void)hideControlView {
    self.viewModel.showing = NO;
    self.containerView.alpha = 0;
    self.topContainer.alpha = 0;
    self.videoSlider.alpha = 0;
    self.bottomProgressView.alpha = 1;
    if (self.viewModel.isFullScreen && !self.viewModel.playEnd) {
        TMABrightness.sharedBrightness.isStatusBarHidden = YES;
    }
}

- (void)hideOtherControlViewsOnDragging {
    [self tma_playerCancelAutoFadeOutControlView];
    self.viewModel.showing = NO;
    self.containerView.alpha = 0;
    self.topContainer.alpha = 0;
    self.bottomProgressView.alpha = 0;
}

- (void)hideOtherControlViewWithoutTop {
    [self tma_playerCancelAutoFadeOutControlView];
    self.viewModel.showing = NO;
    self.containerView.alpha = 0;
    self.videoSlider.alpha = 0;
    self.bottomProgressView.alpha = 0;
}

/**
 *  监听设备旋转通知
 */
- (void)listeningRotating {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}


- (void)autoFadeOutControlView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tma_playerHideControlView) object:nil];
    [self performSelector:@selector(tma_playerHideControlView) withObject:nil afterDelay:ZFPlayerAnimationTimeInterval];
}

- (void)animateLockContainerView:(BOOL)isLocked {
    [self.lockContainerView.layer removeAllAnimations];
    [self.videoSlider.layer removeAllAnimations];
    CGFloat fromAlpha = isLocked ? 1 : 0;
    CGFloat toAlpha = isLocked ? 0 : 1;
    self.lockContainerView.alpha = fromAlpha;
    self.videoSlider.alpha = fromAlpha;
    self.topContainer.alpha = fromAlpha;
    [UIView animateWithDuration:ZFPlayerControlBarAutoFadeOutTimeInterval animations:^{
        self.lockContainerView.alpha = toAlpha;
        self.videoSlider.alpha = toAlpha;
        self.topContainer.alpha = toAlpha;
    }];
}

- (void)updateVideoSliderHidden {
    BOOL showSlider = ([self.viewModel showProgress] && self.btd_width >= OPVideoShowSliderMinWidth) || self.viewModel.dragged;
    self.videoSlider.hidden = !showSlider;
}

- (NSString *)textWithCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime {
    NSInteger totalHour = totalTime / 3600;
    if (totalHour >= 1) {
        NSInteger currentHour = currentTime / 3600;
        NSInteger currentMin = (currentTime % 3600) / 60;
        NSInteger currentSec = currentTime % 60;
        
        NSInteger totalMin = (totalTime % 3600) / 60;
        NSInteger totalSec = totalTime % 60;
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld/%02ld:%02ld:%02ld", currentHour, currentMin, currentSec, totalHour, totalMin, totalSec];
    }
    NSInteger currentMin = currentTime / 60;
    NSInteger currentSec = currentTime % 60;
    NSInteger totalMin = totalTime / 60;
    NSInteger totalSec = totalTime % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld/%02ld:%02ld", currentMin, currentSec, totalMin, totalSec];
}

- (BOOL)isAllGestureDisabled {
    return self.viewModel.playEnd || !self.failedView.isHidden || !self.startBtn.isHidden;
}

- (void)addAllGesturesIfNeeded {
    if (!self.singleTapGesture) {
        self.singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTapGestureRecognized:)];
        self.singleTapGesture.delegate = self;
        [self addGestureRecognizer:self.singleTapGesture];
    }
    
    if (!self.doubleTapGesture && self.viewModel.enablePlayGesture) {
        self.doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTapGestureRecognized:)];
        self.doubleTapGesture.numberOfTapsRequired = 2;
        self.doubleTapGesture.delegate = self;
        [self addGestureRecognizer:self.doubleTapGesture];
        [self.singleTapGesture requireGestureRecognizerToFail:self.doubleTapGesture];
    }
    
    if (!self.panGesture && self.viewModel.enableProgressGesture) {
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGestureRecognized:)];
        self.panGesture.delegate = self;
        [self addGestureRecognizer:self.panGesture];
    }
}

- (void)removeAllGestures {
    if (self.singleTapGesture) {
        [self removeGestureRecognizer:self.singleTapGesture];
        self.singleTapGesture = nil;
    }
    
    if (self.doubleTapGesture) {
        [self removeGestureRecognizer:self.doubleTapGesture];
        self.doubleTapGesture = nil;
    }
    
    if (self.panGesture) {
        [self removeGestureRecognizer:self.panGesture];
        self.panGesture = nil;
    }
}

#pragma mark - setter

- (void)setTma_delegate:(id<TMAVideoControlViewDelegate>)tma_delegate {
    _tma_delegate = tma_delegate;
    _viewModel.tma_delegate = tma_delegate;
}

#pragma mark - getter

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
    }
    return _containerView;
}

- (TMAVideoLockButton *)lockBtn {
    if (!_lockBtn) {
        _lockBtn = [[TMAVideoLockButton alloc] init];
        @weakify(self);
        _lockBtn.tapAction = ^(BOOL isLocked) {
            @strongify(self);
            [self lockScreenBtnClick:isLocked];
        };
    }
    return _lockBtn;
}

- (UIView *)lockContainerView {
    if (!_lockContainerView) {
        _lockContainerView = [[UIView alloc] init];
    }
    return _lockContainerView;
}

- (TMAVideoGradientView *)topMask {
    if (!_topMask) {
        _topMask = [[TMAVideoGradientView alloc] init];
        _topMask.gradientLayer.colors = @[(__bridge id)UIColor.blackColor.CGColor, (__bridge id)UIColor.clearColor.CGColor];
        _topMask.gradientLayer.startPoint = CGPointMake(0, 0);
        _topMask.gradientLayer.endPoint = CGPointMake(0, 1);
    }
    return _topMask;
}

- (TMAVideoGradientView *)bottomMask {
    if (!_bottomMask) {
        _bottomMask = [[TMAVideoGradientView alloc] init];
        _bottomMask.gradientLayer.colors = @[(__bridge id)UIColor.clearColor.CGColor, (__bridge id)UIColor.blackColor.CGColor];
        _bottomMask.gradientLayer.startPoint = CGPointMake(0, 0);
        _bottomMask.gradientLayer.endPoint = CGPointMake(0, 1);
    }
    return _bottomMask;
}

- (UIView *)topContainer {
    if (!_topContainer) {
        _topContainer = [[UIView alloc] init];
    }
    return _topContainer;
}

- (TMAVideoTitleLabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[TMAVideoTitleLabel alloc] init];
    }
    return _titleLabel;
}

- (UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[UIImage ema_imageNamed:@"op_video_back_btn"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _backBtn.btd_hitTestEdgeInsets = UIEdgeInsetsMake(-4, -4, -4, -4);
    }
    return _backBtn;
}

- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _playBtn.backgroundColor = [UIColor btd_colorWithHexString:@"#1F232999"];
        _playBtn.layer.masksToBounds = YES;
        _playBtn.layer.cornerRadius = 20;
        [_playBtn setImage:[UIImage ema_imageNamed:@"op_video_play_btn"] forState:UIControlStateNormal];
        [_playBtn setImage:[UIImage ema_imageNamed:@"op_video_pause_btn"] forState:UIControlStateSelected];
        [_playBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (UIButton *)snapshotBtn {
    if (!_snapshotBtn) {
        _snapshotBtn = [[UIButton alloc] init];
        _snapshotBtn.backgroundColor = [UIColor btd_colorWithHexString:@"#1F232999"];
        _snapshotBtn.layer.masksToBounds = YES;
        _snapshotBtn.layer.cornerRadius = 20;
        [_snapshotBtn setImage:[UIImage ema_imageNamed:@"op_video_snapshot_btn"] forState:UIControlStateNormal];
        [_snapshotBtn addTarget:self action:@selector(snapshotBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _snapshotBtn;
}

- (OPVideoControlSlider *)videoSlider {
    if (!_videoSlider) {
        _videoSlider = [[OPVideoControlSlider alloc] init];
        _videoSlider.delegate = self;
    }
    return _videoSlider;
}

- (OPVideoControlBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[OPVideoControlBottomView alloc] initWithViewModel:_viewModel];
        _bottomView.delegate = self;
    }
    return _bottomView;
}

- (MMMaterialDesignSpinner *)activity {
    if (!_activity) {
        _activity = [[MMMaterialDesignSpinner alloc] init];
        _activity.lineWidth = 1;
        _activity.duration  = 1;
        _activity.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
        _activity.userInteractionEnabled = NO;
    }
    return _activity;
}

- (UIView *)repeatBtn {
    if (!_repeatBtn) {
        _repeatBtn = [[UIView alloc] init];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(repeatBtnClick:)];
        [_repeatBtn addGestureRecognizer:tapGesture];
        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage ema_imageNamed:@"op_video_replay_btn"]];
        [_repeatBtn addSubview:icon];
        [icon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(_repeatBtn).mas_offset(2);
            make.top.mas_equalTo(_repeatBtn).mas_offset(4);
            make.bottom.mas_equalTo(_repeatBtn).mas_offset(-4);
            make.width.height.mas_equalTo(20);
        }];
        UILabel *text = [[UILabel alloc] init];
        text.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
        text.textColor = [UIColor btd_colorWithHexString:@"#F0F0F0"];
        text.text = BDPI18n.LittleApp_VideoCompt_Replay;
        [_repeatBtn addSubview:text];
        CGFloat width = [text.text btd_widthWithFont:text.font height:24];
        [text mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(icon.mas_trailing).mas_offset(8);
            make.centerY.mas_equalTo(icon);
            make.width.mas_equalTo(width);
            make.trailing.mas_equalTo(_repeatBtn).mas_offset(-2);
        }];
    }
    return _repeatBtn;
}

- (UIView *)startBtn {
    if (!_startBtn) {
        _startBtn = [[UIView alloc] init];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(centerStartBtnClick:)];
        [_startBtn addGestureRecognizer:tapGesture];
        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage ema_imageNamed:@"op_video_play_btn"]];
        [_startBtn addSubview:icon];
        [icon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(_startBtn).mas_offset(2);
            make.top.mas_equalTo(_startBtn).mas_offset(4);
            make.bottom.mas_equalTo(_startBtn).mas_offset(-4);
            make.width.height.mas_equalTo(20);
        }];
        UILabel *text = [[UILabel alloc] init];
        text.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
        text.textColor = [UIColor btd_colorWithHexString:@"#F0F0F0"];
        text.text = BDPI18n.LittleApp_VideoCompt_Play;
        [_startBtn addSubview:text];
        CGFloat width = [text.text btd_widthWithFont:text.font height:24];
        [text mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(icon.mas_trailing).mas_offset(8);
            make.centerY.mas_equalTo(icon);
            make.width.mas_equalTo(width);
            make.trailing.mas_equalTo(_startBtn).mas_offset(-2);
        }];
    }
    return _startBtn;
}

- (OPVideoLoadFailView *)failedView {
    if (!_failedView) {
        _failedView = [[OPVideoLoadFailView alloc] init];
        @weakify(self);
        _failedView.actionBlock = ^{
            @strongify(self);
            [self retryBtnClicked];
        };
    }
    return _failedView;
}

- (UIProgressView *)bottomProgressView {
    if (!_bottomProgressView) {
        _bottomProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        _bottomProgressView.progressTintColor = [UIColor btd_colorWithHexString:@"#3370FF"];
        _bottomProgressView.trackTintColor = [UIColor btd_colorWithHexString:@"#DEE0E3"];
    }
    return _bottomProgressView;
}

#pragma mark - Public method

/** 重置ControlView */
- (void)tma_playerResetControlView {
    self.viewModel.showing = NO;
    self.viewModel.playEnd = NO;
    self.viewModel.dragged = NO;
    
    [self.activity stopAnimating];
    self.repeatBtn.hidden = YES;
    self.startBtn.hidden = NO;
    self.failedView.hidden = YES;
    self.backgroundColor = [UIColor btd_colorWithHexString:@"#0000008C"];
    [self.bottomView resetControlView];
    [self hideControlView];
    self.bottomProgressView.progress = 0;
    [self.videoSlider reset];
    [self updateVideoSliderHidden];
    [self tma_playerLockBtnState:NO];
    [self tma_playerRemoveRateSelectionPanel];
}

/**
 *  取消延时隐藏controlView的方法
 */
- (void)tma_playerCancelAutoFadeOutControlView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

/** 正在播放（隐藏placeholderImageView） */
- (void)tma_playerItemPlaying {
    self.failedView.hidden = YES; // 隐藏错误提示
    self.backgroundColor = UIColor.clearColor;
    [self addAllGesturesIfNeeded];
}

- (void)tma_playerShowOrHideControlView {
    if (self.viewModel.playEnd || self.startBtn.isHidden == NO || self.repeatBtn.isHidden == NO || self.rateSelectionView || !self.failedView.isHidden) {
        return;
    }
    if (self.viewModel.showing) {
        [self tma_playerHideControlView];
    } else {
        BOOL autoFade = self.playBtn.isSelected || self.lockBtn.locked;
        [self tma_playerShowControlViewWithAutoFade:autoFade];
    }
}
/**
 *  显示控制层
 */
- (void)tma_playerShowControlView {
    [self tma_playerShowControlViewWithAutoFade:YES];
}

- (void)tma_playerShowControlViewWithAutoFade:(BOOL)autoFade {
    if ([self.tma_delegate respondsToSelector:@selector(tma_controlViewWillShow:isFullscreen:)]) {
        [self.tma_delegate tma_controlViewWillShow:self isFullscreen:self.viewModel.isFullScreen];
    }
    [self tma_playerCancelAutoFadeOutControlView];
    [UIView animateWithDuration:ZFPlayerControlBarAutoFadeOutTimeInterval animations:^{
        [self showControlView];
    } completion:^(BOOL finished) {
        self.viewModel.showing = YES;
        if (autoFade) {
            [self autoFadeOutControlView];
        }
    }];
}

/**
 *  隐藏控制层
 */
- (void)tma_playerHideControlView {
    if (self.viewModel.playEnd) {
        return;
    }
    
    if ([self.tma_delegate respondsToSelector:@selector(tma_controlViewWillHidden:isFullscreen:)]) {
        [self.tma_delegate tma_controlViewWillHidden:self isFullscreen:self.viewModel.isFullScreen];
    }
    [self tma_playerCancelAutoFadeOutControlView];
    [UIView animateWithDuration:ZFPlayerControlBarAutoFadeOutTimeInterval animations:^{
        [self hideControlView];
    } completion:^(BOOL finished) {
        [self.lockBtn hideTextTip];
        self.viewModel.showing = NO;
    }];
}

- (void)tma_playerBecameFullScreen:(BOOL)isFullscreen {
    self.viewModel.fullScreen = isFullscreen;
    TMABrightness.sharedBrightness.isLandscape = isFullscreen;
    [self setNeedsLayout];
}

- (void)tma_playerHideCenterButton
{
    self.startBtn.hidden = YES;
    self.repeatBtn.hidden = YES;
}

- (void)tma_playerCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)value {
    if (!self.viewModel.dragged) {
        // 更新slider
        [self.videoSlider updateCurrentValue:value];
    }
    self.bottomProgressView.progress = value;
    [self.bottomView updateTimeLabel:[self textWithCurrentTime:currentTime totalTime:totalTime]];
}

- (void)tma_playerDragBegan:(NSInteger)draggingTime totalTime:(NSInteger)totalTime {
    self.viewModel.dragged = YES;
    [self.activity stopAnimating];
    [self hideOtherControlViewsOnDragging];
    self.videoSlider.alpha = 1;
    self.videoSlider.hidden = NO;
    self.backgroundColor = [UIColor btd_colorWithHexString:@"#0000008C"];
    [self.videoSlider showDraggingTime:[self textWithCurrentTime:draggingTime totalTime:totalTime]];
}

- (void)tma_playerDraggingTime:(NSInteger)draggingTime totalTime:(NSInteger)totalTime {
    [self.videoSlider showDraggingTime:[self textWithCurrentTime:draggingTime totalTime:totalTime]];
}

- (void)tma_playerDraggedEnd {
    if (!self.viewModel.dragged) {
        return;
    }
    self.viewModel.dragged = NO;
    [self.videoSlider hideDraggingTime];
    [self updateVideoSliderHidden];
    self.backgroundColor = UIColor.clearColor;
    [self tma_playerShowControlViewWithAutoFade:self.playBtn.isSelected];
}

/** progress显示缓冲进度 */
- (void)tma_playerSetProgress:(CGFloat)progress {
    [self.videoSlider updateBufferingProgress:progress];
}

/** 视频加载失败 */
- (void)tma_playerItemStatusFailed {
    [self hideOtherControlViewWithoutTop];
    [self updateVideoSliderHidden];
    [self tma_playerRemoveRateSelectionPanel];
    
    self.failedView.hidden = NO;
    self.backgroundColor = UIColor.blackColor;
    self.topContainer.alpha = 1;
    [self removeAllGestures];
}

/** 加载的菊花 */
- (void)tma_playerActivity:(BOOL)animated {
    if (animated) {
        [self.activity startAnimating];
    } else {
        [self.activity stopAnimating];
    }
}

/** 播放完了 */
- (void)tma_playerPlayEnd {
    self.viewModel.dragged = NO;
    self.viewModel.playEnd = YES;
    self.viewModel.showing = NO;
    TMABrightness.sharedBrightness.isStatusBarHidden = NO;
    [self hideOtherControlViewWithoutTop];
    [self updateVideoSliderHidden];
    [self tma_playerRemoveRateSelectionPanel];
    
    self.repeatBtn.hidden = NO;
    self.backgroundColor = [UIColor btd_colorWithHexString:@"#0000008C"];
    self.topContainer.alpha = 1;
    [self removeAllGestures];
}

/** 播放按钮状态 */
- (void)tma_playerStartBtnState:(BOOL)state {
    [self.bottomView selectStartBtn:state];
    self.playBtn.selected = state;
}

/** 锁定屏幕方向按钮状态 */
- (void)tma_playerLockBtnState:(BOOL)state {
    self.lockBtn.locked = state;
}

/** 静音按钮状态 */
- (void)tma_playerMuteButtonState:(BOOL)muted {
    [self.bottomView selectMuteBtn:muted];
}

- (void)tma_playerShowRateSelectionPanel:(CGFloat)currentSpeed {
    if (self.rateSelectionView) {
        return;
    }
    [self hideControlView];
    [self tma_playerCancelAutoFadeOutControlView];
    self.rateSelectionView = [[TMAVideoRateSelectionView alloc] initWithSelections:@[@2, @1, @0.5] currentSelection:@(currentSpeed)];
    @weakify(self);
    self.rateSelectionView.tapAction = ^(CGFloat rate) {
        @strongify(self);
        if ([self.tma_delegate respondsToSelector:@selector(tma_controlViewSelectRate:)]) {
            [self.tma_delegate tma_controlViewSelectRate:rate];
        }
        [self tma_playerRemoveRateSelectionPanel];
        [self tma_playerShowControlView];
    };
    [self addSubview:self.rateSelectionView];
    CGFloat width = (self.viewModel.isFullScreen && UIDeviceOrientationIsPortrait(UIDevice.currentDevice.orientation)) ? 160 : 225;
    [self.rateSelectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.right.mas_equalTo(self);
        make.width.mas_equalTo(width);
    }];
}

- (void)tma_playerRemoveRateSelectionPanel {
    if (self.rateSelectionView) {
        [self.rateSelectionView removeFromSuperview];
        self.rateSelectionView = nil;
    }
}

- (void)tma_playerSetRateText:(CGFloat)speed {
    [self.bottomView updateRateBtnText:speed];
}

#pragma clang diagnostic pop

@end

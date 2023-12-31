//
//  OPVideoControlBottomView.m
//  OPPluginBiz
//
//  Created by baojianjun on 2022/4/20.
//  control层bottomView收敛

#import "OPVideoControlBottomView.h"
#import "EMABaseViewController.h"
#import <OPFoundation/UIImage+EMA.h>
#import <ECOInfra/BDPLog.h>
#import <Masonry/Masonry.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDancekit/NSString+BTDAdditions.h>
#import <OPFoundation/BDPI18n.h>
#import "OPVideoControlViewModel.h"
#import "TMAVideoDefines.h"
#import "TMAVideoControlViewDelegate.h"
#if __has_feature(modules)
@import ReactiveObjC;
#else
#import <ReactiveObjC/ReactiveObjC.h>
#endif

@implementation OPVideoControlBottomItem
@end

@interface OPVideoControlBottomView ()

@property (nonatomic, strong) UIButton *startBtn;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *rateBtn;
@property (nonatomic, strong) UIButton *muteBtn;
@property (nonatomic, strong) UIButton *fullScreenBtn;
@property (nonatomic, copy) NSArray<OPVideoControlBottomItem *> *items;

@property (nonatomic, strong) OPVideoControlViewModel *viewModel;
@property (nonatomic, strong) RACCompoundDisposable *disposables;

@end

@implementation OPVideoControlBottomView

- (instancetype)initWithViewModel:(OPVideoControlViewModel *)viewModel {
    self = [super init];
    if (self) {
        _viewModel = viewModel;
        [self _setupView];
        [self _bindData];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self remakeLayout];
}

- (void)_setupView {
    [self addSubview:self.startBtn];
    [self addSubview:self.timeLabel];
    [self addSubview:self.rateBtn];
    [self addSubview:self.muteBtn];
    [self addSubview:self.fullScreenBtn];

    [self remakeLayout];
}

- (void)_bindData {
    [self disposeIfNeeded];
    RACCompoundDisposable *disposables = [RACCompoundDisposable compoundDisposable];
    
    @weakify(self)
    [disposables addDisposable:[[[[RACObserve(self.viewModel, viewShowingState) combineLatestWith:RACObserve(self.viewModel, playBtnPosition)] distinctUntilChanged] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self remakeLayout];
    }]];
    
    [disposables addDisposable:[[[[RACObserve(self.viewModel, fullScreen) skip:1] distinctUntilChanged] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        if (!self) return;
        self.fullScreenBtn.selected = self.viewModel.fullScreen;
    }]];
    
    self.disposables = disposables;
}

- (void)remakeLayout {
    [self constructItems];
    
    BOOL isFullScreenLandscape = self.viewModel.isFullScreen && UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation);
    CGFloat accLeftOffset = isFullScreenLandscape ? 20 : 8;
    CGFloat accRightOffset = isFullScreenLandscape ? 32 : 20;
    __block CGFloat leftOffset = 0;
    __block CGFloat rightOffset = 0;
    __block CGFloat currentWidth = 0;
    
    [self.items enumerateObjectsUsingBlock:^(OPVideoControlBottomItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL show = item.show && (currentWidth + item.size.width <= self.btd_width);
        item.view.hidden = !show;
        if (!show) {
            return;
        }
        
        if (item.alignment == OPVideoControlBottomItemAlignLeft) {
            [item.view mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.mas_equalTo(self).mas_offset(leftOffset);
                make.centerY.mas_equalTo(self);
                make.size.mas_equalTo(item.size);
            }];
            leftOffset += (item.size.width + accLeftOffset);
            currentWidth += (item.size.width + accLeftOffset);
        } else {
            [item.view mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.trailing.mas_equalTo(self).mas_offset(rightOffset);
                make.centerY.mas_equalTo(self);
                make.size.mas_equalTo(item.size);
            }];
            rightOffset -= (item.size.width + accRightOffset);
            currentWidth += (item.size.width + accRightOffset);
        }
    }];
}

- (void)constructItems {
    // 数组顺序对应优先级
    NSMutableArray<OPVideoControlBottomItem *> *items = [NSMutableArray arrayWithCapacity:5];
    
    OPVideoControlBottomItem *startBtnItem = [[OPVideoControlBottomItem alloc] init];
    startBtnItem.view = self.startBtn;
    startBtnItem.show = [self.viewModel showPlayBtnAtBottom];
    startBtnItem.size = CGSizeMake(20, 20);
    startBtnItem.alignment = OPVideoControlBottomItemAlignLeft;
    [items btd_addObject:startBtnItem];
    
    OPVideoControlBottomItem *fullScreenBtnItem = [[OPVideoControlBottomItem alloc] init];
    fullScreenBtnItem.view = self.fullScreenBtn;
    fullScreenBtnItem.show = [self.viewModel showFullScreenBtn];
    fullScreenBtnItem.size = CGSizeMake(20, 20);
    fullScreenBtnItem.alignment = OPVideoControlBottomItemAlignRight;
    [items btd_addObject:fullScreenBtnItem];
    
    OPVideoControlBottomItem *muteBtnItem = [[OPVideoControlBottomItem alloc] init];
    muteBtnItem.view = self.muteBtn;
    muteBtnItem.show = [self.viewModel showMuteBtn];
    muteBtnItem.size = CGSizeMake(20, 20);
    muteBtnItem.alignment = OPVideoControlBottomItemAlignRight;
    [items btd_addObject:muteBtnItem];
    
    OPVideoControlBottomItem *timeLabelItem = [[OPVideoControlBottomItem alloc] init];
    timeLabelItem.view = self.timeLabel;
    timeLabelItem.show = YES;
    timeLabelItem.size = [self.timeLabel.text btd_sizeWithFont:self.timeLabel.font width:HUGE_VALF];
    timeLabelItem.alignment = OPVideoControlBottomItemAlignLeft;
    [items btd_addObject:timeLabelItem];
    
    OPVideoControlBottomItem *rateBtnItem = [[OPVideoControlBottomItem alloc] init];
    rateBtnItem.view = self.rateBtn;
    rateBtnItem.show = [self.viewModel showRateBtn];
    rateBtnItem.size = [self.rateBtn.titleLabel.text btd_sizeWithFont:self.rateBtn.titleLabel.font width:HUGE_VALF];
    rateBtnItem.alignment = OPVideoControlBottomItemAlignRight;
    [items btd_addObject:rateBtnItem];
    
    self.items = items.copy;
}

- (void)dealloc {
    [self disposeIfNeeded];
}

- (void)disposeIfNeeded {
    if (self.disposables) {
        [self.disposables dispose];
        self.disposables = nil;
    }
}

#pragma mark - Public

- (void)selectStartBtn:(BOOL)selected {
    self.startBtn.selected = selected;
}

- (void)selectMuteBtn:(BOOL)selected {
    self.muteBtn.selected = selected;
}

- (void)updateRateBtnText:(CGFloat)value {
    NSString *text = [NSString stringWithFormat:@"%@x", @(value)];
    if (fabs(value - 1) < FLT_EPSILON) {
        text = BDPI18n.LittleApp_VideoCompt_Speed;
    }
    CGFloat currentWidth = [self.rateBtn.titleLabel.text btd_widthWithFont:self.rateBtn.titleLabel.font height:HUGE_VALF];
    CGFloat targetWidth = [text btd_widthWithFont:self.rateBtn.titleLabel.font height:HUGE_VALF];
    [self.rateBtn setTitle:text forState:UIControlStateNormal];
    if (targetWidth > currentWidth) {
        [self remakeLayout];
    }
}

- (void)updateTimeLabel:(NSString *)time {
    CGFloat currentWidth = [self.timeLabel.text btd_widthWithFont:self.timeLabel.font height:HUGE_VALF];
    CGFloat targetWidth = [time btd_widthWithFont:self.timeLabel.font height:HUGE_VALF];
    self.timeLabel.text = time;
    if (targetWidth > currentWidth) {
        [self remakeLayout];
    }
}

- (void)resetControlView {
    self.timeLabel.text = @"";
    [self.rateBtn setTitle:BDPI18n.LittleApp_VideoCompt_Speed forState:UIControlStateNormal];
}

#pragma mark - Action

- (void)playBtnClick:(UIButton *)sender {
    BDPLogInfo(@"TMAVideoControlView playBtnClick");
    sender.selected = !sender.selected;
    if ([self.viewModel.tma_delegate respondsToSelector:@selector(tma_controlView:playAction:isCenter:)]) {
        [self.viewModel.tma_delegate tma_controlView:self playAction:sender isCenter:NO];
    }
}

- (void)fullScreenBtnClick:(UIButton *)sender {
    BDPLogInfo(@"TMAVideoControlView fullScreenBtnClick");
    EMA_STATUS_BAR_ORIENTATION_MODIFY = YES;
    sender.selected = !sender.selected;
    if ([self.viewModel.tma_delegate respondsToSelector:@selector(tma_controlView:fullScreenAction:)]) {
        [self.viewModel.tma_delegate tma_controlView:self fullScreenAction:sender];
    }
    EMA_STATUS_BAR_ORIENTATION_MODIFY = NO;
}

- (void)muteBtnClick:(UIButton *)sender {
    BDPLogInfo(@"TMAVideoControlView muteBtnClick");
    sender.selected = !sender.selected;
    if ([self.viewModel.tma_delegate respondsToSelector:@selector(tma_controlView:muteAction:)]) {
        [self.viewModel.tma_delegate tma_controlView:self muteAction:sender];
    }
}

- (void)rateBtnClick {
    if ([self.viewModel.tma_delegate respondsToSelector:@selector(tma_controlViewRateAction)]) {
        [self.viewModel.tma_delegate tma_controlViewRateAction];
    }
}

#pragma mark - Lazy Getter

- (UIButton *)startBtn {
    if (!_startBtn) {
        _startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_startBtn setImage:[UIImage ema_imageNamed:@"op_video_play_btn"] forState:UIControlStateNormal];
        [_startBtn setImage:[UIImage ema_imageNamed:@"op_video_pause_btn"] forState:UIControlStateSelected];
        [_startBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _startBtn.btd_hitTestEdgeInsets = UIEdgeInsetsMake(-4, -4, -4, -4);
    }
    return _startBtn;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightRegular];
        _timeLabel.textColor = [UIColor btd_colorWithHexString:@"#EDF0F1"];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _timeLabel;
}

- (UIButton *)rateBtn {
    if (!_rateBtn) {
        _rateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _rateBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_rateBtn setTitleColor:[UIColor btd_colorWithHexString:@"#EDF0F1"] forState:UIControlStateNormal];
        [_rateBtn setTitle:BDPI18n.LittleApp_VideoCompt_Speed forState:UIControlStateNormal];
        [_rateBtn addTarget:self action:@selector(rateBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rateBtn;
}

- (UIButton *)muteBtn {
    if (!_muteBtn) {
        _muteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_muteBtn setImage:[UIImage ema_imageNamed:@"op_video_unmute_btn"] forState:UIControlStateNormal];
        [_muteBtn setImage:[UIImage ema_imageNamed:@"op_video_mute_btn"] forState:UIControlStateSelected];
        [_muteBtn addTarget:self action:@selector(muteBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _muteBtn.btd_hitTestEdgeInsets = UIEdgeInsetsMake(-4, -4, -4, -4);
    }
    return _muteBtn;
}

- (UIButton *)fullScreenBtn {
    if (!_fullScreenBtn) {
        _fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenBtn setImage:[UIImage ema_imageNamed:@"op_video_fullscreen_btn"] forState:UIControlStateNormal];
        [_fullScreenBtn setImage:[UIImage ema_imageNamed:@"op_video_shrinkscreen_btn"] forState:UIControlStateSelected];
        [_fullScreenBtn addTarget:self action:@selector(fullScreenBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _fullScreenBtn.btd_hitTestEdgeInsets = UIEdgeInsetsMake(-4, -4, -4, -4);
    }
    return _fullScreenBtn;
}



@end

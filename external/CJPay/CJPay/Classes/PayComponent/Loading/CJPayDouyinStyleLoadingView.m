//
//  CJPayDouyinStyleLoadingView.m
//  CJPay
//
//  Created by 孔伊宁 on 2022/8/10.
//

#import "CJPayDouyinStyleLoadingView.h"
#import "CJPayUIMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPayLoadingManager.h"

@interface CJPayDouyinStyleLoadingView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *logoFieldView;
@property (nonatomic, strong) BDImageView *logoPreGifView;
@property (nonatomic, strong) BDImageView *logoCompleteGifView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation CJPayDouyinStyleLoadingView

+ (CJPayDouyinStyleLoadingView *)sharedView {
    static CJPayDouyinStyleLoadingView *sharedView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if !TARGET_APP_EXTENSION && TARGET_iOS
        sharedView = [[CJPayDouyinStyleLoadingView alloc] initWithFrame:[[[UIApplication sharedApplication] delegate] window].bounds];
#elif !TARGET_APP_EXTENSION && !TARGET_iOS
        sharedView = [[CJPayDouyinStyleLoadingView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.bounds];
#else
        sharedView = [[CJPayDouyinStyleLoadingView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
#endif
    });
    return sharedView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.containerView];
    CJPayMasMaker(self.containerView, {
        make.edges.equalTo(self);
    });
    
    [self.containerView addSubview:self.backgroundView];
    CJPayMasMaker(self.backgroundView, {
        make.center.equalTo(self.containerView);
        make.width.mas_equalTo(136);
        make.height.mas_equalTo(118);
    });
    
    [self.containerView addSubview:self.logoFieldView];
    CJPayMasMaker(self.logoFieldView, {
        make.top.equalTo(self.backgroundView).offset(15);
        make.centerX.equalTo(self.backgroundView);
        make.width.height.mas_equalTo(54);
    });
    
    [self.logoFieldView addSubview:self.logoPreGifView];
    [self.logoFieldView addSubview:self.logoCompleteGifView];
    CJPayMasMaker(self.logoPreGifView, {
        make.center.equalTo(self.logoFieldView);
        make.edges.equalTo(self.logoFieldView);
    });
    CJPayMasMaker(self.logoCompleteGifView, {
        make.center.equalTo(self.logoFieldView);
        make.edges.equalTo(self.logoFieldView);
    });
    self.logoPreGifView.hidden = YES;
    self.logoCompleteGifView.hidden = YES;
    
    [self.containerView addSubview:self.titleLabel];
    CJPayMasMaker(self.titleLabel, {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self.backgroundView.mas_bottom).offset(-20);
        make.height.mas_equalTo(20);
    });
}

- (void)showLoading {
    [self showLoadingWithTitle:nil];
}

- (void)showLoadingWithTitle:(nullable NSString *)title {

    UIView *view = [UIApplication btd_mainWindow];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [view addSubview:self];
    CJPayMasMaker(self, {
        make.edges.equalTo(view);
    });
    self.logoPreGifView.hidden = NO;
    self.logoCompleteGifView.hidden = YES;
    
    [self setLoadingTitle:title];
    
    [self.logoPreGifView cj_loadGifAndInfinityLoopWithURL:[self repeatGifUrl] duration:0.2];
    self.userInteractionEnabled = YES; //设为NO会导致手势传递到下层可响应页面，从而无法阻塞用户交互
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setLoadingTitle:(NSString *)title {
    NSString *loadingTitle = Check_ValidString(title) ? title : CJPayDYPayTitleMessage;
    [self setTitle:loadingTitle];
}

- (void)stopLoadingWithState:(CJPayLoadingQueryState)state {
    NSString *completeGifUrl = [self completeSuccessGifUrl];
    if (state != CJPayLoadingQueryStateSuccess || !self.loadingStyleInfo.isNeedShowPayResult || !Check_ValidString(completeGifUrl)) {
        [self dismiss];
        return;
    }
    
    self.logoPreGifView.hidden = YES;
    self.logoCompleteGifView.hidden = NO;
    [self setTitle:CJPayLocalizedStr(@"支付成功")];
    [self.logoCompleteGifView cj_loadGifAndOnceLoopWithURL:[self completeSuccessGifUrl] duration:0.4];
    [self.logoCompleteGifView startAnimation];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismiss];
    });
}

- (void)dismiss {
    self.userInteractionEnabled = NO;
    [self.logoPreGifView stopAnimation];
    [self.logoCompleteGifView stopAnimation];
    [self.layer removeAllAnimations];
    [self removeFromSuperview];
}

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (NSString *)preLoadGifUrl {
    return [CJPaySettingsManager shared].currentSettings.securityLoadingConfig.breatheStyleLoadingConfig.dialogPreGif;
}

- (NSString *)repeatGifUrl {
    return [CJPaySettingsManager shared].currentSettings.securityLoadingConfig.breatheStyleLoadingConfig.dialogRepeatGif;
}

- (NSString *)completeSuccessGifUrl {
    return [CJPaySettingsManager shared].currentSettings.securityLoadingConfig.breatheStyleLoadingConfig.dialogCompleteSuccessGif;
}

#pragma mark - lazy init
- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [UIView new];
        _containerView.backgroundColor = [UIColor clearColor];
    }
    return _containerView;
}

- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [UIView new];
        _backgroundView.layer.cornerRadius = 12;
        _backgroundView.clipsToBounds = YES;
        _backgroundView.backgroundColor = [UIColor cj_colorWithHexString:@"393b44"];

    }
    return _backgroundView;
}

- (UIView *)logoFieldView {
    if (!_logoFieldView) {
        _logoFieldView = [UIView new];
        _logoFieldView.backgroundColor = [UIColor clearColor];
    }
    return _logoFieldView;
}

- (BDImageView *)logoPreGifView {
    if (!_logoPreGifView) {
        _logoPreGifView = [BDImageView new];
        _logoPreGifView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _logoPreGifView;
}

- (BDImageView *)logoCompleteGifView {
    if (!_logoCompleteGifView) {
        _logoCompleteGifView = [BDImageView new];
        _logoCompleteGifView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _logoCompleteGifView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont cj_fontOfSize:13];
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

@end

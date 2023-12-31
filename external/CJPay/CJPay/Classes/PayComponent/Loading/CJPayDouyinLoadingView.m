//
//  CJPayDouyinLoadingView.m
//  Pods
//
//  Created by 易培淮 on 2021/6/17.
//

#import "CJPayDouyinLoadingView.h"
#import "CJPayUIMacro.h"

static const CGFloat kAnimationDuration = 0.9;

@interface CJPayDouyinLoadingView ()

@property (nonatomic, strong) UIView *hudView;
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *showView;
@property (nonatomic, strong) UIStackView *dotStackView;
@property (nonatomic, strong) NSMutableArray<UIView *> *dotViews;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation CJPayDouyinLoadingView

+ (CJPayDouyinLoadingView *)sharedView
{
    static CJPayDouyinLoadingView *sharedView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if !TARGET_APP_EXTENSION && TARGET_iOS
        sharedView = [[CJPayDouyinLoadingView alloc] initWithFrame:[[[UIApplication sharedApplication] delegate] window].bounds];
#elif !TARGET_APP_EXTENSION && !TARGET_iOS
        sharedView = [[CJPayDouyinLoadingView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.bounds];
#else
        sharedView = [[CJPayDouyinLoadingView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
#endif
    });
    return sharedView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
        _isLoading = NO;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
        _isLoading = NO;
    }
    return self;
}

#pragma mark - Public 

+ (CJPayDouyinLoadingView *)showWindowLoadingWithTitle:(NSString *)title animated:(BOOL)animated afterDelay:(NSTimeInterval)delay
{
    CJPayDouyinLoadingView *loading = [self sharedView];
    UIView *view = [UIApplication sharedApplication].keyWindow;

    if (delay <= 0) {
        [loading p_showLoadingOnView:view title:title animated:animated];
    } else {
        [loading performSelector:@selector(p_showLoadingOnView:) withObject:@[view, title, @(animated)] afterDelay:delay];
    }
    return loading;
}

+ (CJPayDouyinLoadingView *)showLoadingOnView:(UIView *)view title:(NSString *)title animated:(BOOL)animated afterDelay:(NSTimeInterval)delay
{
    return [CJPayDouyinLoadingView showLoadingOnView:view title:title animated:animated afterDelay:delay];
}

+ (CJPayDouyinLoadingView *)showLoadingOnView:(UIView *)view
                                   title:(NSString *)title
                                    icon:(NSString *)iconName
                                 animated:(BOOL)animated
                                   afterDelay:(NSTimeInterval)delay {
    CJPayDouyinLoadingView *loading = [self sharedView];
    [loading setIcon:iconName];
    if (delay <= 0) {
        [loading p_showLoadingOnView:view title:title icon:iconName animated:animated];
    } else {
        [loading performSelector:@selector(p_showLoadingOnView:) withObject:@[view, title, iconName, @(animated)] afterDelay:delay];
    }
    return loading;
}

+ (CJPayDouyinLoadingView *)showLoadingOnView:(UIView *)view
                                   title:(NSString *)title
                                subTitle:(NSString *)subTitle
                                    icon:(NSString *)iconName
                                 animated:(BOOL)animated
                                   afterDelay:(NSTimeInterval)delay {
    CJPayDouyinLoadingView *loading = [self sharedView];
    [loading setIcon:iconName];
    if (delay <= 0) {
        [loading p_showLoadingOnView:view title:title subTitle:subTitle icon:iconName animated:animated];
    } else {
        [loading performSelector:@selector(p_showLoadingOnView:) withObject:@[view, title, iconName, @(animated)] afterDelay:delay];
    }
    return loading;
}

+ (CJPayDouyinLoadingView *)showMessageWithTitle:(NSString *)title
                                    subTitle:(NSString *)subTitle {
    CJPayDouyinLoadingView *loading = [self sharedView];
    [loading setTitle: CJString(title)];
    [loading setSubTitle: CJString(subTitle)];
    [loading setIcon:@"cj_super_pay_result_icon"];
    loading.dotStackView.hidden = YES;
    loading.subTitleLabel.hidden = NO;
    return loading;
}

+ (CJPayDouyinLoadingView *)showLoadingWithView:(UIView *)showView
                                     onView:(UIView *)view {
    CJPayDouyinLoadingView *loading = [self sharedView];
    loading.logoImageView.hidden = YES;
    loading.titleLabel.hidden = YES;
    loading.subTitleLabel.hidden = YES;
    loading.dotStackView.hidden = YES;
    if ([loading.showView isDescendantOfView:loading]) {
        [loading.showView removeFromSuperview];
    }
    loading.showView = showView;
    [loading addSubview:loading.showView];
    CJPayMasMaker(loading.showView, {
        make.edges.equalTo(loading.hudView);
    });
    loading.showView.hidden = NO;
    loading.hudView.alpha = 1;
    [view addSubview:loading];
    CJPayMasMaker(loading, {
        make.edges.equalTo(view);
    });
    return loading;
}

+ (void)dismissWithAnimated:(BOOL)animated {
    [[self sharedView] p_dismissWithAnimated:animated];
}

- (void)allowUserInteraction:(BOOL)allow
{
    self.userInteractionEnabled = !allow;
}

- (void)startAnimating {
    //动画周期 750 ms
    CAKeyframeAnimation *keyAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    //关键帧，一个点亮250ms
    keyAnimation.keyTimes = @[@0,@(kAnimationDuration*1/100),@(kAnimationDuration*3/100),@(kAnimationDuration*5/100),@(kAnimationDuration*32/100),@(kAnimationDuration*33/100),@(kAnimationDuration*50/100),@(kAnimationDuration*66/100),@(kAnimationDuration)];
    keyAnimation.values = @[@0.34,@0.5,@0.6,@0.8,@0.8,@0.4,@0.34,@0.34,@0.34];
    keyAnimation.fillMode = kCAFillModeForwards;
    keyAnimation.removedOnCompletion = NO;
    keyAnimation.calculationMode = kCAAnimationDiscrete;
    keyAnimation.duration = kAnimationDuration;
    keyAnimation.repeatCount = MAXFLOAT;
    for (int i = 0; i<3; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i*kAnimationDuration/3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.dotViews[i].layer addAnimation:keyAnimation forKey:@"keyAnimation"];
        });
    }
}

- (void)stopAnimating {
    for (UIView *dot in self.dotViews) {
        [dot.layer removeAllAnimations];
    }
}

#pragma mark - Private Method

- (void)p_setupUI
{
    [self addSubview:self.containerView];
    CJPayMasMaker(self.containerView, {
        make.edges.equalTo(self);
    });
    
    [self.containerView addSubview:self.hudView];
    CGFloat ratio = CJ_SCREEN_WIDTH / 375.0;
    CJPayMasMaker(self.hudView, {
        make.center.equalTo(self.containerView);
        make.width.mas_equalTo(136.0 * ratio);
        make.height.mas_equalTo(122.0 * ratio);
    });
    
    [self.hudView addSubview:self.logoImageView];
    CJPayMasMaker(self.logoImageView, {
        make.centerX.equalTo(self);
        make.top.equalTo(self.hudView).offset(24 * ratio);
        make.height.width.mas_equalTo(32 * ratio);
    });
    
    [self.hudView addSubview:self.titleLabel];
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.logoImageView.mas_bottom).offset(8 * ratio);
        make.centerX.equalTo(self);
        make.height.mas_equalTo(18 * ratio);
    });
    
    for (int i = 0; i < 3; i++) {
        UIView *dotView = [UIView new];
        dotView.backgroundColor = [UIColor cj_ffffffWithAlpha:1];
        dotView.layer.cornerRadius = 3;
        dotView.layer.opacity = 0.34;
        [self.dotViews addObject:dotView];
        [self.dotStackView addArrangedSubview:dotView];
        CJPayMasMaker(dotView, {
            make.width.height.mas_equalTo(6);
        });
    }
    
    [self.hudView addSubview:self.dotStackView];
    CJPayMasMaker(self.dotStackView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(10 * ratio);
        make.centerX.equalTo(self);
        make.height.mas_equalTo(6);
        make.width.mas_equalTo(38);
    });
    
    [self.hudView addSubview:self.subTitleLabel];
    CJPayMasMaker(self.subTitleLabel, {
       make.top.equalTo(self.titleLabel.mas_bottom).offset(6 * ratio);
       make.centerX.equalTo(self);
       make.height.mas_equalTo(15 * ratio);
    });
}

- (void)p_dismissWithAnimated:(BOOL)animated
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (animated) {
        self.hudView.alpha = 1;
        [UIView animateWithDuration:0.2
                              delay:0
                            options:(UIViewAnimationOptions) (UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
            self.hudView.alpha = 0;
        } completion:nil];
        [self performSelector:@selector(stopAnimating) withObject:nil afterDelay:0.2];
        [self performSelector:@selector(allowUserInteraction:) withObject:@(YES) afterDelay:0.2];
        [self performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.2];
        [self performSelector:@selector(setIsLoading:) withObject:@(NO) afterDelay:0.2];
    } else {
        self.hudView.alpha = 0;
        [self performSelector:@selector(stopAnimating)];
        [self performSelector:@selector(allowUserInteraction:) withObject:@(YES)];
        [self performSelector:@selector(removeFromSuperview)];
        [self performSelector:@selector(setIsLoading:) withObject:@(NO)];
    }
    
}

- (void)p_showLoadingOnView:(NSArray *)params
{
    if (params.count != 4) {
        return;
    }
    BOOL animated = NO;
    if ([params btd_objectAtIndex:3] && [[params btd_objectAtIndex:3] isKindOfClass:NSNumber.class]) {
        animated = ([[params btd_objectAtIndex:3] integerValue] == 0);
    }
    [self p_showLoadingOnView:[params btd_objectAtIndex:0]
                        title:[params btd_objectAtIndex:1]
                         icon:[params btd_objectAtIndex:2]
                     animated:animated];
}

- (void)p_showLoadingOnView:(UIView *)view title:(NSString *)title animated:(BOOL)animated
{
    [self p_showLoadingOnView:view title:title icon:@"cj_douyin_pay_logo_icon" animated:animated];
}

- (void)p_showLoadingOnView:(UIView *)view title:(NSString *)title icon:(NSString *)iconName animated:(BOOL)animated {
    [self p_showLoadingOnView:view title:title subTitle:@"" icon:iconName animated:animated];
}

- (void)p_showLoadingOnView:(UIView *)view title:(NSString *)title subTitle:(NSString *)subTitle icon:(NSString *)iconName animated:(BOOL)animated {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [view addSubview:self];
    CJPayMasMaker(self, {
        make.edges.equalTo(view);
    });
    [self setNeedsLayout];
    [self layoutIfNeeded];
    self.logoImageView.hidden = NO;
    self.titleLabel.hidden = NO;
    self.dotStackView.hidden = NO;
    self.subTitleLabel.hidden = YES;
    if ([self.showView isDescendantOfView:self]) {
        [self.showView removeFromSuperview];
    }
    [self setTitle:title];
    if (Check_ValidString(subTitle)) {
        [self setSubTitle:subTitle];
        self.dotStackView.hidden = YES;
        self.subTitleLabel.hidden = NO;
    }
    [self setIcon:iconName];
    if (!self.isLoading) {
        self.isLoading = YES;
        [self startAnimating];
    }
    [self allowUserInteraction:NO];

    if (animated && !self.isLoading) {
        self.hudView.alpha = 0;
        [UIView animateWithDuration:0.2
                           delay:0
                         options:(UIViewAnimationOptions) (UIViewAnimationCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState)
                      animations:^{
            self.hudView.alpha = 1;
        }
                      completion:^(BOOL finished) {
        }];
    } else {
        self.hudView.alpha = 1;
    }
}

#pragma mark - Setter

- (void)setIcon:(nullable NSString *)iconName {
    if ([iconName hasPrefix:@"http"]) {
        [_logoImageView cj_setImageWithURL:[NSURL URLWithString:iconName]];
    } else {
        [_logoImageView cj_setImage:CJString(iconName)];
    }
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

- (void)setSubTitle:(NSString *)subTitle
{
    _subTitleLabel.text = subTitle;
}

- (void)setIsLoading:(BOOL)isLoading {
    _isLoading = isLoading;
}

#pragma mark - Getter

- (UIView *)containerView
{
    if (!_containerView) {
        _containerView = [UIView new];
        _containerView.backgroundColor = [UIColor clearColor];
    }
    return _containerView;
}

- (UIView *)hudView
{
    if (!_hudView) {
        _hudView = [UIView new];
        _hudView.layer.cornerRadius = 12;
        _hudView.clipsToBounds = YES;
        _hudView.backgroundColor = [UIColor cj_colorWithHexString:@"393B44" alpha:0.9];
    }
    return _hudView;
}

- (UIImageView *)logoImageView
{
    if (!_logoImageView) {
        _logoImageView = [UIImageView new];
    }
    return _logoImageView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont cj_fontOfSize:13];
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (UIStackView *)dotStackView
{
    if (!_dotStackView) {
        _dotStackView = [UIStackView new];
        _dotStackView.axis = UILayoutConstraintAxisHorizontal;
        _dotStackView.distribution = UIStackViewDistributionEqualSpacing;
    }
    return _dotStackView;
}

- (NSMutableArray *)dotViews {
    if (!_dotViews) {
        _dotViews = [NSMutableArray new];
    }
    return _dotViews;
}

- (UILabel *)subTitleLabel
{
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.textAlignment = NSTextAlignmentCenter;
        _subTitleLabel.textColor = [UIColor cj_ffffffWithAlpha:0.6];
        _subTitleLabel.font = [UIFont cj_fontOfSize:11];
        _subTitleLabel.numberOfLines = 0;
    }
    return _subTitleLabel;
}

@end


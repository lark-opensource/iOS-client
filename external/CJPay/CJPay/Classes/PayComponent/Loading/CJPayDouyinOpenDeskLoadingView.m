//
//  CJPayDouyinOpenDeskLoadingView.m
//  CJPay-Pods-AwemeCore
//
//  Created by 利国卿 on 2022/6/2.
//

#import "CJPayDouyinOpenDeskLoadingView.h"
#import "CJPayUIMacro.h"

static const CGFloat kAnimationDuration = 0.75;

@interface CJPayDouyinOpenDeskLoadingView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UIStackView *dotStackView;
@property (nonatomic, strong) NSMutableArray<UIView *> *dotViews;

@property (nonatomic, assign) BOOL isLoading;

@end

@implementation CJPayDouyinOpenDeskLoadingView

+ (CJPayDouyinOpenDeskLoadingView *)sharedView {
    
    static CJPayDouyinOpenDeskLoadingView *sharedView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if !TARGET_APP_EXTENSION && TARGET_iOS
        sharedView = [[CJPayDouyinOpenDeskLoadingView alloc] initWithFrame:[[[UIApplication sharedApplication] delegate] window].bounds];
#elif !TARGET_APP_EXTENSION && !TARGET_iOS
        sharedView = [[CJPayDouyinOpenDeskLoadingView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.bounds];
#else
        sharedView = [[CJPayDouyinOpenDeskLoadingView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
#endif
    });
    return sharedView;
}

#pragma mark - Override

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
        _isLoading = NO;
    }
    return self;
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        [self p_setupUI];
        _isLoading = NO;
    }
    return self;
}

#pragma mark - Public

+ (CJPayDouyinOpenDeskLoadingView *)showLoadingOnView:(UIView *)view {
    return [self showLoadingOnView:view animated:NO];
}

+ (CJPayDouyinOpenDeskLoadingView *)showLoadingOnView:(UIView *)view animated:(BOOL)animated {
    return [self showLoadingOnView:view icon:[self loadingIconName] animated:animated];
}

+ (CJPayDouyinOpenDeskLoadingView *)showLoadingOnView:(UIView *)view
                                         icon:(NSString *)iconName
                                     animated:(BOOL)animated {
    
    CJPayDouyinOpenDeskLoadingView *loadingView = [self sharedView];
    [loadingView p_showLoadingOnView:view icon:iconName animated:animated];
    return loadingView;
}


+ (NSString *)loadingIconName {
    return @"cj_douyin_pay_open_desk_icon";
}

+ (void)dismissWithAnimated:(BOOL)animated {
    [[self sharedView] p_dismissWithAnimated:animated];
}

#pragma mark - Loading Animating

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
            UIView *dotView = [self.dotViews cj_objectAtIndex:i];
            [dotView.layer addAnimation:keyAnimation forKey:@"keyAnimation"];
        });
    }
}

- (void)stopAnimating {
    for (UIView *dot in self.dotViews) {
        [dot.layer removeAllAnimations];
    }
}

#pragma mark - Setter

- (void)setLoadingIconName:(NSString *)iconName {
    [_logoImageView cj_setImage:CJString(iconName)];
}

- (void)allowUserInteraction:(BOOL)allow {
    self.userInteractionEnabled = allow;
}

- (void)setIsLoading:(BOOL)isLoading {
    _isLoading = isLoading;
}

#pragma mark - Private Method

- (void)p_setupUI {
    [self addSubview:self.containerView];
    CJPayMasMaker(self.containerView, {
        make.edges.equalTo(self);
    });
    
    [self.containerView addSubview:self.contentView];
    CJPayMasMaker(self.contentView, {
        make.centerX.equalTo(self.containerView);
        make.centerY.equalTo(self.containerView).offset(-60);
    });
    
    [self.contentView addSubview:self.logoImageView];
    CJPayMasMaker(self.logoImageView, {
        make.left.right.top.equalTo(self.contentView);
        make.width.height.mas_equalTo(104);
    });
    
    for (int i = 0; i < 3; i++) {
        UIView *dotView = [UIView new];
        dotView.backgroundColor = [UIColor cj_ffffffWithAlpha:1];
        dotView.layer.cornerRadius = 5;
        dotView.layer.opacity = 0.34;
        [self.dotViews btd_addObject:dotView];
        [self.dotStackView addArrangedSubview:dotView];
        CJPayMasMaker(dotView, {
            make.width.height.mas_equalTo(10);
        });
    }
    
    [self.contentView addSubview:self.dotStackView];
    CJPayMasMaker(self.dotStackView, {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.logoImageView.mas_bottom).offset(16);
        make.height.mas_equalTo(10);
        make.width.mas_equalTo(70);
        make.bottom.equalTo(self.contentView);
    });
}

- (void)p_showLoadingOnView:(UIView *)onView icon:(NSString *)iconName animated:(BOOL)animated {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [onView addSubview:self];
    CJPayMasMaker(self, {
        make.edges.equalTo(onView);
    });
    [self setNeedsLayout];
    [self layoutIfNeeded];
    self.logoImageView.hidden = NO;
    self.dotStackView.hidden = NO;
    
    [self setLoadingIconName:iconName];
    if (!self.isLoading) {
        self.isLoading = YES;
        [self startAnimating];
    }
    [self allowUserInteraction:NO];
    
    if (animated && !self.isLoading) {
        self.containerView.alpha = 0;
        [UIView animateWithDuration:0.2
                           delay:0
                         options:(UIViewAnimationOptions) (UIViewAnimationCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState)
                      animations:^{
            self.containerView.alpha = 1;
        }
                      completion:^(BOOL finished) {
        }];
    } else {
        self.containerView.alpha = 1;
    }
    
}

- (void)p_dismissWithAnimated:(BOOL)animated {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (animated) {
        self.containerView.alpha = 1;
        [UIView animateWithDuration:0.2
                              delay:0
                            options:(UIViewAnimationOptions) (UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
            self.containerView.alpha = 0;
        } completion:nil];
        [self performSelector:@selector(stopAnimating) withObject:nil afterDelay:0.2];
        [self performSelector:@selector(allowUserInteraction:) withObject:@(YES) afterDelay:0.2];
        [self performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.2];
        [self performSelector:@selector(setIsLoading:) withObject:@(NO) afterDelay:0.2];
    } else {
        self.containerView.alpha = 0;
        [self performSelector:@selector(stopAnimating)];
        [self performSelector:@selector(allowUserInteraction:) withObject:@(YES)];
        [self performSelector:@selector(removeFromSuperview)];
        [self performSelector:@selector(setIsLoading:) withObject:@(NO)];
    }
    
}

#pragma mark - lazy View

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [UIView new];
        _containerView.backgroundColor = [UIColor cj_393b44ff];
    }
    return _containerView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.backgroundColor = [UIColor clearColor];
    }
    return _contentView;
}

- (UIImageView *)logoImageView {
    if (!_logoImageView) {
        _logoImageView = [UIImageView new];
    }
    return _logoImageView;
}

- (UIStackView *)dotStackView {
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
@end

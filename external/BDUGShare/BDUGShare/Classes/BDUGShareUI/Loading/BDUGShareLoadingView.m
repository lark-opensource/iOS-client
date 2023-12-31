//
//  BDUGShareLoadingView.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/6/6.
//

#import "BDUGShareLoadingView.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "BDUGShareAdapterSetting.h"
#import <Gaia/GAIAEngine.h>
#import "BDUGShareMacros.h"

static CGFloat kCircelW = 36;
static CGFloat kW1 = 57;
static CGFloat kPadding = 15;
static CGFloat kEdge = 20;

@interface BDUGShareLoadingViewBundle : NSObject

+ (NSBundle *)mainBundle;

@end

@implementation BDUGShareLoadingViewBundle

+ (NSBundle *)mainBundle {
    NSString *bundlePath = [[NSBundle bundleForClass:BDUGShareLoadingViewBundle.class].resourcePath stringByAppendingPathComponent:@"BDUGShareLoadingResource.bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    if (!bundle) {
        NSAssert(0, @"bundle of BDUGShareLoadingViewBundle can't load");
        bundle = [NSBundle mainBundle];
    }
    return bundle;
}

@end

@interface BDUGShareLoadingView () <BDUGShareAbilityProtocol>

@property (nonatomic, strong) UIView *baseView;
@property (nonatomic, strong) UIImageView *progressView;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, assign) BDUGShareLoadingViewStatus status;

@end

@implementation BDUGShareLoadingView

GAIA_FUNCTION(BDUGShareInitializeGaiaKey)() {
    [BDUGShareAdapterSetting sharedService].shareAbilityDelegate = [BDUGShareLoadingView class];
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static BDUGShareLoadingView *shareInstance;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGShareLoadingView alloc] initWithTitle:@"发布中"];
    });
    return shareInstance;
}

- (instancetype)initWithTitle:(NSString *)title
{
    self = [super init];
    if (self) {
        _title = [title copy];
        self.layer.cornerRadius = 2;
        self.layer.masksToBounds = YES;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        [self addSubview:self.progressView];
        [self.layer addSublayer:self.progressLayer];
        [self addSubview:self.titleLabel];
        [self addSubview:self.cancelButton];
        [self _setupSelfFrame];
        [self _addObservers];
    }
    return self;
}

- (void)dealloc {
    [self _removeObservers];
}

#pragma mark - core

- (void)shareAbilityShowLoading
{
    [self showAnimated:YES];
}

- (void)shareAbilityHideLoading
{
    [self dismissAnimated:YES];
}

#pragma mark - UI

- (void)showOnView:(UIView *)view animated:(BOOL)animated {
    [view addSubview:self.baseView];
    self.baseView.frame = view.bounds;
    [self _showOnView:self.baseView animated:animated];
}

- (void)showAnimated:(BOOL)animated {
    UIView *view = [UIApplication sharedApplication].keyWindow;
    [view addSubview:self.baseView];
    self.baseView.frame = view.bounds;
    [self _showOnView:self.baseView animated:animated];
}

- (void)showAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay
{
    if (delay <= 0) {
        [self showAnimated:animated];
    } else {
        [self performSelector:@selector(_showAnimated:) withObject:[NSNumber numberWithBool:animated] afterDelay:delay];
    }
}

- (void)_showAnimated:(NSNumber *)animated {
    [self showAnimated:[animated boolValue]];
}

- (void)_showOnView:(UIView *)view animated:(BOOL)animated {
    CGFloat w = view.bounds.size.width;
    CGFloat h = view.bounds.size.height;
    self.center = CGPointMake(w / 2, h / 2);
    if (self.superview) {
        [self removeFromSuperview];
    }
    [view addSubview:self];
    self.status = BDUGShareLoadingViewStatusAnimating;
    [self _startLoadingAnim];
    if (animated) {
        self.alpha = 0;
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 1;
        } completion:^(BOOL finished) {
        }];
    } else {
        self.alpha = 1;
    }
}

- (void)dismissAnimated:(BOOL)animated {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.status = BDUGShareLoadingViewStatusStop;
    [self _stopLoadingAnim];
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
            if (self.baseView.superview) {
                [self.baseView removeFromSuperview];
            }
        }];
    } else {
        [self removeFromSuperview];
        if (self.baseView.superview) {
            [self.baseView removeFromSuperview];
        }
    }
}

- (void)_startLoadingAnim {
    [self.progressView.layer removeAllAnimations];
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.fromValue = @(0);
    animation.toValue = @(2 * M_PI);
    animation.duration = 0.8;
    animation.repeatCount = HUGE_VAL;
    [self.progressView.layer addAnimation:animation forKey:@"loading_logo_anim"];
}

- (void)_stopLoadingAnim {
    [self.progressView.layer removeAllAnimations];
}

- (void)_addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)_removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidEnterBackground:(NSNotification *)noti {
    if (self.status == BDUGShareLoadingViewStatusAnimating) {
        self.status = BDUGShareLoadingViewStatusPaused;
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)noti {
    if (self.status == BDUGShareLoadingViewStatusPaused) {
        [self _startLoadingAnim];
        self.status = BDUGShareLoadingViewStatusAnimating;
    }
}

- (void)_setupSelfFrame {
        self.progressLayer.hidden = YES;
        if (!self.title.length) {
            self.bounds = CGRectMake(0, 0, kW1, kW1);
            self.titleLabel.hidden = YES;
        } else {
            CGFloat h = kPadding + self.progressView.frame.size.height + 8 + self.titleLabel.frame.size.height + kPadding;
            CGFloat w = kEdge + self.titleLabel.frame.size.width + kEdge;
            self.bounds = CGRectMake(0, 0, w, h);
        }

//    self.progressLayer.hidden = YES;
//        self.progressLabel.hidden = YES;
//        self.progressView.image = [UIImage imageNamed:@"icon_search_loadingview"];
//        self.progressView.frame = CGRectMake(0, 0, 15, 15);
//        self.titleLabel.font = [UIFont systemFontOfSize:17.0f];
//        self.titleLabel.textColor = [UIColor whiteColor];
//        self.backgroundColor = [UIColor clearColor];
//        CGSize size = [self.titleLabel sizeThatFits:CGSizeMake(300-2*kEdge, 21)];
//        self.titleLabel.bounds = CGRectMake(0, 0, size.width, size.height);
//        if (!self.title.length) {
//            self.bounds = CGRectMake(0, 0, kW1, kW1);
//            self.titleLabel.hidden = YES;
//        } else {
//            CGFloat h = 21;
//            CGFloat w = self.progressView.frame.size.width + 6 + self.titleLabel.frame.size.width;
//            self.bounds = CGRectMake(0, 0, w, h);
//        }
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;

    if (!self.title.length) {
            self.progressView.center = CGPointMake(w/2, h/2);
        } else {
            CGRect frame = self.progressView.frame;
            frame.origin.x = (w - frame.size.width) / 2;
            frame.origin.y = kPadding;
            self.progressView.frame = frame;
            frame = self.titleLabel.frame;
            frame.origin.x = (w - frame.size.width) / 2;
            frame.origin.y = CGRectGetMaxY(self.progressView.frame) + 8;
            self.titleLabel.frame = frame;
        }

//        if (!self.title.length) {
//            self.progressView.center = CGPointMake(w/2, h/2);
//        } else {
//            CGRect frame = self.progressView.frame;
//            frame.origin.x = 0;
//            self.progressView.frame = frame;
//            self.progressView.center = CGPointMake(self.progressView.center.x, self.bounds.size.height/2);
//
//            frame = self.titleLabel.frame;
//            frame.origin.x = 21;
//            self.titleLabel.frame = frame;
//            self.titleLabel.center = CGPointMake(self.titleLabel.center.x, self.bounds.size.height/2);
//        }
    
}

- (UIView *)baseView {
    if (!_baseView) {
        _baseView = [[UIView alloc] init];
        _baseView.backgroundColor = [UIColor clearColor];
        _baseView.userInteractionEnabled = YES;
    }
    return _baseView;
}

- (UIImageView *)progressView {
    if (!_progressView) {
        UIImage *img = [UIImage imageNamed:@"share_loading_image" inBundle:[BDUGShareLoadingViewBundle mainBundle] compatibleWithTraitCollection:nil];
        _progressView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, img.size.width, img.size.height)];
        _progressView.image = img;
    }
    return _progressView;
}

- (CAShapeLayer *)progressLayer {
    if (!_progressLayer) {
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.affineTransform = CGAffineTransformMakeScale(-1, 1);
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, kCircelW, kCircelW)];
        _progressLayer.path = path.CGPath;
        _progressLayer.strokeColor = [UIColor whiteColor].CGColor;
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.lineWidth = 3;
        _progressLayer.lineCap = kCALineCapRound;
        _progressLayer.strokeStart = 0;
        _progressLayer.strokeEnd = 0;
        _progressLayer.transform = CATransform3DMakeRotation(-M_PI/2, 0, 0, 1);
    }
    return _progressLayer;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:17];
        _titleLabel.text = self.title;
        _titleLabel.numberOfLines = 0;
        CGSize size = [_titleLabel sizeThatFits:CGSizeMake(270-2*kEdge, 200)];
        _titleLabel.bounds = CGRectMake(0, 0, size.width, size.height);
    }
    return _titleLabel;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.btd_hitTestEdgeInsets = UIEdgeInsetsMake(-8, -8, -8, -8);
        [_cancelButton setImage:[UIImage imageNamed:@"iconProfileQuestionClose"] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.alpha = 0;
    }
    
    return _cancelButton;
}

- (void)setCancelable:(BOOL)cancelable {
    _cancelable = cancelable;
    _cancelButton.alpha = cancelable ? 1 : 0;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    _titleLabel.text = title;
    if (title.length > 0) {
        _titleLabel.hidden = NO;
    } else {
        _titleLabel.hidden = YES;
    }
    CGSize size = [_titleLabel sizeThatFits:CGSizeMake(300-2*kEdge, 200)];
    _titleLabel.bounds = CGRectMake(0, 0, size.width, size.height);
    [self _setupSelfFrame];
    [_titleLabel setNeedsLayout];
}

- (void)allowUserInteraction:(BOOL)allow
{
    self.baseView.userInteractionEnabled = !allow;
}

#pragma mark - actions

- (void)cancelButtonClicked:(id)sender {
    [self dismissAnimated:YES];
    !self.cancelBlock ?: self.cancelBlock();
}

@end

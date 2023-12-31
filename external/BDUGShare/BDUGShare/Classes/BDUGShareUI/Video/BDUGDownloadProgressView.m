//
//  BDUGDownloadProgressView.m
//  NewsLite
//
//  Created by 杨阳 on 2019/4/28.
//

#import "BDUGDownloadProgressView.h"
#import <ByteDanceKit/UIView+BTDAdditions.h>

static CGFloat kCircelW = 36;
static CGFloat kW1 = 57;
static CGFloat kPadding = 15;
static CGFloat kProgressLabelH = 15;
static CGFloat kEdge = 20;

@interface BDUGDownloadProgressView ()

@property (nonatomic, strong) UIView *baseView;
@property (nonatomic, strong) UIImageView *progressView;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *cancelButton;

@property (nonatomic, assign) BDUGProgressLoadingViewType type;
@property (nonatomic, assign) BDUGProgressLoadingViewStatus status;

@end

@implementation BDUGDownloadProgressView

- (instancetype)initWithType:(BDUGProgressLoadingViewType)type title:(NSString *)title {
    self = [super init];
    if (self) {
        _type = type;
        _title = [title copy];
        self.layer.cornerRadius = 2;
        self.layer.masksToBounds = YES;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        [self addSubview:self.progressView];
        [self.layer addSublayer:self.progressLayer];
        [self addSubview:self.progressLabel];
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
    self.status = BDUGProgressLoadingViewStatusAnimating;
    if (self.type == BDUGProgressLoadingViewTypeNormal || self.type == BDUGProgressLoadingViewTypeHorizon) {
        [self _startLoadingAnim];
    } else {
        //        self.progress = 0;
        [self _updateProgress];
    }
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
    self.status = BDUGProgressLoadingViewStatusStop;
    if (self.type == BDUGProgressLoadingViewTypeNormal || self.type == BDUGProgressLoadingViewTypeHorizon) {
        [self _stopLoadingAnim];
    }
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
            if (self.baseView.superview) {
                [self.baseView removeFromSuperview];
            }
            self.progress = 0;
        }];
    } else {
        [self removeFromSuperview];
        if (self.baseView.superview) {
            [self.baseView removeFromSuperview];
        }
        self.progress = 0;
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

- (void)_updateProgress {
    NSString *text = [NSString stringWithFormat:@"%2d%%", (int)(self.progress*100)];
    self.progressLabel.text = text;
    self.progressLayer.strokeEnd = self.progress;
}

- (void)_addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)_removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidEnterBackground:(NSNotification *)noti {
    if (self.status == BDUGProgressLoadingViewStatusAnimating) {
        self.status = BDUGProgressLoadingViewStatusPaused;
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)noti {
    if (self.status == BDUGProgressLoadingViewStatusPaused) {
        if (self.type == BDUGProgressLoadingViewTypeNormal || self.type == BDUGProgressLoadingViewTypeHorizon) {
            [self _startLoadingAnim];
        }
        self.status = BDUGProgressLoadingViewStatusAnimating;
    }
}

- (void)_setupSelfFrame {
    if (self.type == BDUGProgressLoadingViewTypeNormal) {
        self.progressLayer.hidden = YES;
        self.progressLabel.hidden = YES;
        if (!self.title.length) {
            self.bounds = CGRectMake(0, 0, kW1, kW1);
            self.titleLabel.hidden = YES;
        } else {
            CGFloat h = kPadding + self.progressView.frame.size.height + 8 + self.titleLabel.frame.size.height + kPadding;
            CGFloat w = kEdge + self.titleLabel.frame.size.width + kEdge;
            self.bounds = CGRectMake(0, 0, w, h);
        }
    } else if (self.type == BDUGProgressLoadingViewTypeHorizon) {
        self.progressLayer.hidden = YES;
        self.progressLabel.hidden = YES;
        self.progressView.image = [UIImage imageNamed:@"icon_search_loadingview"];
        self.progressView.frame = CGRectMake(0, 0, 15, 15);
        self.titleLabel.font = [UIFont systemFontOfSize:17.0f];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor clearColor];
        CGSize size = [self.titleLabel sizeThatFits:CGSizeMake(300-2*kEdge, 21)];
        self.titleLabel.bounds = CGRectMake(0, 0, size.width, size.height);
        if (!self.title.length) {
            self.bounds = CGRectMake(0, 0, kW1, kW1);
            self.titleLabel.hidden = YES;
        } else {
            CGFloat h = 21;
            CGFloat w = self.progressView.frame.size.width + 6 + self.titleLabel.frame.size.width;
            self.bounds = CGRectMake(0, 0, w, h);
        }
    } else {
        self.progressView.hidden = YES;
        if (!self.title.length) {
            CGFloat w = kPadding + kCircelW + kPadding;
            self.bounds = CGRectMake(0, 0, w, w);
            self.titleLabel.hidden = YES;
        } else {
            CGFloat h = kPadding + kCircelW + 12 + self.titleLabel.frame.size.height + kPadding;
            CGFloat w = kEdge + self.titleLabel.frame.size.width + kEdge;
            self.bounds = CGRectMake(0, 0, w, h);
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    if (self.type == BDUGProgressLoadingViewTypeNormal) {
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
    } else if (self.type == BDUGProgressLoadingViewTypeHorizon) {
        if (!self.title.length) {
            self.progressView.center = CGPointMake(w/2, h/2);
        } else {
            CGRect frame = self.progressView.frame;
            frame.origin.x = 0;
            self.progressView.frame = frame;
            self.progressView.center = CGPointMake(self.progressView.center.x, self.bounds.size.height/2);
            
            frame = self.titleLabel.frame;
            frame.origin.x = 21;
            self.titleLabel.frame = frame;
            self.titleLabel.center = CGPointMake(self.titleLabel.center.x, self.bounds.size.height/2);
        }
    } else {
        if (!self.title.length) {
            self.progressLayer.position = CGPointMake(w/2, h/2);
        } else {
            self.progressLayer.frame = CGRectMake((w-kCircelW)/2, kPadding, kCircelW, kCircelW);
            CGRect frame = self.titleLabel.frame;
            frame.origin.x = (w - frame.size.width) / 2;
            frame.origin.y = CGRectGetMaxY(self.progressLayer.frame) + 12;
            self.titleLabel.frame = frame;
        }
        self.progressLabel.frame = CGRectMake((w - kW1)/2, self.progressLayer.position.y-kProgressLabelH/2, kW1, kProgressLabelH);
        self.cancelButton.frame = CGRectMake(self.frame.size.width - 24, 0, 24, 24);
    }
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
        UIImage *img = [UIImage imageNamed:@"oval2"];
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

- (UILabel *)progressLabel {
    if (!_progressLabel) {
        _progressLabel = [[UILabel alloc] init];
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        _progressLabel.textColor = [UIColor whiteColor];
        _progressLabel.font = [UIFont systemFontOfSize:12];
        _progressLabel.text = [NSString stringWithFormat:@"%2d%%", 0];
    }
    return _progressLabel;
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

- (void)setProgress:(CGFloat)progress {
    if (_progress != progress) {
        if (progress < 0) {
            progress = 0;
        }
        if (progress > 1) {
            progress = 1;
        }
        _progress = progress;
        [self _updateProgress];
    }
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

//todo: 考虑暴露这个API
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

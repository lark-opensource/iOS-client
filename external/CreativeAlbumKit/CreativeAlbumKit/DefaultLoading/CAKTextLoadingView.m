//
//  CAKTextLoadingView.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/14.
//

#import "CAKTextLoadingView.h"
#import "UIColor+AlbumKit.h"

#import "CAKLoadingView.h"
#import <Masonry/Masonry.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

static const CGFloat kCakVerticalPadding = 15;
static const CGFloat kCakHorizantalPadding = 20;
static const CGFloat kCakLoadingAndTitlePadding = 8;

static const CGFloat kCakAnimationDuration = 0.3;

@interface CAKTextLoadingView ()

@property (nonatomic, strong) UIView *hudView;

@property (nonatomic, strong) CAKLoadingView *loadingView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIView *containerView;

@end

@implementation CAKTextLoadingView

+ (CAKTextLoadingView *)sharedView
{
    static CAKTextLoadingView *sharedView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if !TARGET_APP_EXTENSION && TARGET_iOS
        sharedView = [[CAKTextLoadingView alloc] initWithFrame:[[[UIApplication sharedApplication] delegate] window].bounds];
#elif !TARGET_APP_EXTENSION && !TARGET_iOS
        sharedView = [[CAKTextLoadingView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.bounds];
#else
        sharedView = [[CAKTextLoadingView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
#endif
    });
    return sharedView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    [self addSubview:self.containerView];

    [self.containerView addSubview:self.hudView];
    [self.hudView addSubview:self.loadingView];
    [self.hudView addSubview:self.titleLabel];

    ACCMasMaker(self.containerView, {
        make.edges.equalTo(self);
    });
    ACCMasMaker(self.hudView, {
        make.center.equalTo(self.containerView);
    });
    ACCMasMaker(self.loadingView, {
        make.centerX.equalTo(self);
        make.top.equalTo(@(kCakVerticalPadding));
    });
    ACCMasMaker(self.titleLabel, {
        make.top.equalTo(self.loadingView.mas_bottom).offset(kCakLoadingAndTitlePadding);
        make.bottom.equalTo(self.hudView.mas_bottom).offset(-kCakVerticalPadding);
        make.left.equalTo(@(kCakHorizantalPadding));
        make.right.equalTo(@(-kCakHorizantalPadding));
    });
}

#pragma mark - Public

+ (CAKTextLoadingView *)showLoadingOnView:(UIView *)view title:(NSString *)title animated:(BOOL)animated afterDelay:(NSTimeInterval)delay
{
    CAKTextLoadingView *loading = [[CAKTextLoadingView alloc] initWithFrame:view.bounds];

    if (delay <= 0) {
        [loading p_showLoadingOnView:view title:title animated:animated];
    } else {
        [loading performSelector:@selector(p_showLoadingOnView:) withObject:@[view, title, @(animated)] afterDelay:delay];
    }
    return loading;
}

+ (CAKTextLoadingView *)showLoadingOnView:(UIView *)view title:(NSString *)title animated:(BOOL)animated
{
    return [self showLoadingOnView:view title:title animated:animated afterDelay:0];
}

+ (CAKTextLoadingView *)showLoadingOnView:(UIView *)view withTitle:(NSString *)title
{
    return [self showLoadingOnView:view title:title animated:NO];
}

- (void)dismissWithAnimated:(BOOL)animated
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    void (^dismissBlock)(void) = ^ {
        [self.loadingView stopAnimating];
        [self removeFromSuperview];
    };
    if (animated) {
        self.hudView.alpha = 1;
        [UIView animateWithDuration:0.3
                              delay:0
                            options:(UIViewAnimationOptions) (UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
            self.hudView.alpha = 0;
        } completion:^(BOOL finished) {
            if (dismissBlock) {
                dismissBlock();
            }
        }];
    } else {
        self.hudView.alpha = 0;
        dismissBlock();
    }
}

- (void)dismiss
{
    [self dismissWithAnimated:NO];
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
    CGSize size = [self.titleLabel sizeThatFits:CGSizeMake(300 - 2 * kCakHorizantalPadding, 200)];
    ACCMasUpdate(self.titleLabel, {
        make.size.mas_equalTo(size);
    });

    BOOL hasText = ([title isKindOfClass:[NSString class]] && title.length > 0);
    self.titleLabel.hidden = !hasText;
    if (hasText) {
        self.hudView.backgroundColor = CAKResourceColor(ACCColorToastDefault);
    } else {
        self.hudView.backgroundColor = [UIColor clearColor];
    }
}

- (void)startAnimating
{
    [self.loadingView startAnimating];
}

- (void)stopAnimating
{
    [self.loadingView stopAnimating];
}

- (void)allowUserInteraction:(BOOL)allow
{
    self.userInteractionEnabled = !allow;
}

#pragma mark - Private

- (void)p_showLoadingOnView:(NSArray *)params
{
    if (params.count != 3) {
        return;
    }
    [self p_showLoadingOnView:params[0] title:params[1] animated:[params[2] boolValue]];
}

- (void)p_showLoadingOnView:(UIView *)view title:(NSString *)title animated:(BOOL)animated
{
    [view addSubview:self];
    ACCMasMaker(self, {
        make.edges.equalTo(view);
    });
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self setTitle:title];
    [self startAnimating];

    if (animated) {
        self.hudView.alpha = 0;
        [UIView animateWithDuration:kCakAnimationDuration
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

+ (UIImage *)p_imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.f, 1.f);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - Getter

- (UIView *)containerView
{
    if (!_containerView) {
        _containerView = [[UIImageView alloc] initWithImage:[[self class] p_imageWithColor:[UIColor clearColor]]];
        _containerView.backgroundColor = [UIColor clearColor];
    }
    return _containerView;
}

- (UIView *)hudView
{
    if (!_hudView) {
        _hudView = [UIView new];
        _hudView.layer.cornerRadius = 4;
        _hudView.clipsToBounds = YES;
        _hudView.backgroundColor = CAKResourceColor(ACCColorToastDefault);
    }
    return _hudView;
}

- (CAKLoadingView *)loadingView
{
    if (!_loadingView) {
        _loadingView = [[CAKLoadingView alloc] init];
    }
    return _loadingView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont acc_systemFontOfSize:13 weight:ACCFontWeightSemibold];
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

@end

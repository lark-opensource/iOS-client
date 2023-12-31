//
//  AWETitleRollingTextView.m
//  CameraClient
//
//  Created by HuangHongsen on 2019/11/4.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitBeauty/AWETitleRollingTextView.h>
#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>

static NSString *const kAWETitleRollingTextViewCubeTransitionAnimationKey = @"AWETitleRollingTextViewCubeTransitionAnimationKey";

@interface AWETitleRollingTextView()<CAAnimationDelegate>
@property (nonatomic, strong) UIView *transitionContainerView;
@property (nonatomic, strong) UIView *rollingContainerView;
@property (nonatomic, strong) NSMutableArray *rollingViews;
@property (nonatomic, strong) UIView *sourceView;

@property (nonatomic, assign) BOOL showRollingText;
@property (nonatomic, assign) CGFloat subviewWidth;
@property (nonatomic, copy) NSString *rollingText;
@property (nonatomic, strong) UIColor *rollingTextColor;
@property (nonatomic, strong) UIFont *rollingTextFont;
@property (nonatomic, assign) NSTimeInterval rollingDuration;
@property (nonatomic, copy) void(^stopAnimationCompletion)(void);

@property (nonatomic, assign) BOOL rolling;
@end

@implementation AWETitleRollingTextView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _rollingContainerView = [[UIView alloc] init];
        _rollingContainerView.backgroundColor = [UIColor clearColor];
        _rollingContainerView.userInteractionEnabled = NO;
        [self addSubview:_rollingContainerView];
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)configureWithRollingText:(NSString *)text
                            font:(UIFont *)font
                       textColor:(UIColor *)textColor
                      labelSpace:(CGFloat)labelSpace
                   numberOfRolls:(NSInteger)numberOfRolls
{
    self.rollingText = text;
    self.rollingTextFont = font;
    self.rollingTextColor = textColor;
    [self.rollingViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.rollingViews = [NSMutableArray array];
    CGFloat width = 0.f;
    UILabel *rollingLabelSample = [self p_createRollingLabel];
    numberOfRolls = self.frame.size.width / (rollingLabelSample.frame.size.width + labelSpace) + 2;
    width = (numberOfRolls * (rollingLabelSample.frame.size.width + labelSpace));
    for (NSInteger index = 0; index < numberOfRolls; index++) {
        UILabel *label = [self p_createRollingLabel];
        self.subviewWidth = label.frame.size.width + labelSpace;
        if (label) {
            CGFloat originX = index * (label.frame.size.width + labelSpace);
            [self.rollingViews addObject:label];
            [self.rollingContainerView addSubview:label];
            ACCMasMaker(label, {
                make.left.equalTo(self.rollingContainerView).with.offset(originX);
                make.centerY.equalTo(self.rollingContainerView);
            });
        }
    }
    self.rollingContainerView.frame = CGRectMake(0, 0, width, self.frame.size.height);
}

- (UILabel *)p_createRollingLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.font = self.rollingTextFont;
    label.textColor = self.rollingTextColor;
    label.text = self.rollingText;
    [label sizeToFit];
    label.userInteractionEnabled = NO;
    return label;
}

#pragma mark - Animations
- (void)startAnimatingWithDuration:(NSTimeInterval)duration
                          fromView:(nullable UIView *)sourceView
{
    if (self.rolling) {
        return ;
    }
    self.rolling = YES;
    self.rollingDuration = duration;
    self.sourceView = sourceView;
    if (sourceView) {
        self.rollingContainerView.hidden = YES;
        self.transitionContainerView = [[UIView alloc] initWithFrame:self.bounds];
        [self.transitionContainerView addSubview:sourceView];
        
        UILabel *targetView = [self p_createRollingLabel];
        [self.transitionContainerView addSubview:sourceView];
        [self.transitionContainerView addSubview:targetView];
        targetView.hidden = YES;
        [self addSubview:self.transitionContainerView];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.showRollingText = YES;
            CATransition *transition = [CATransition animation];
            transition.duration = 0.3;
            transition.type = @"cube";
            transition.subtype = kCATransitionFromTop;
            transition.delegate = self;
            [self.transitionContainerView.layer addAnimation:transition forKey:kAWETitleRollingTextViewCubeTransitionAnimationKey];
            targetView.hidden = NO;
            sourceView.hidden = YES;
        });
    } else {
        [self p_startRollingTextWithDuration:duration];
    }
}

- (void)pauseAnimating
{
    CFTimeInterval pausedTime = [self.rollingContainerView.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    self.rollingContainerView.layer.speed = 0.0;
    self.rollingContainerView.layer.timeOffset = pausedTime;
    self.rolling = NO;
}

- (void)resumeAnimating
{
    if (self.rolling) {
        return ;
    }
    self.rolling = YES;
    CFTimeInterval pausedTime = [self.rollingContainerView.layer timeOffset];
    self.rollingContainerView.layer.speed = 1.0;
    self.rollingContainerView.layer.timeOffset = 0.0;
    self.rollingContainerView.layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [self.rollingContainerView.layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    self.rollingContainerView.layer.beginTime = timeSincePause;
}

- (void)stopAnimatingWithCompletion:(void (^)(void))completion
{
    [self.rollingContainerView.layer removeAllAnimations];
    self.rolling = NO;
    if (self.sourceView) {
        self.stopAnimationCompletion = completion;
        [self addSubview:self.sourceView];
        self.sourceView.hidden = YES;
        [self addSubview:self.sourceView];
        
        CATransition *transition = [CATransition animation];
        transition.duration = 0.3;
        transition.type = @"cube";
        transition.subtype = kCATransitionFromBottom;
        transition.delegate = self;
        [self.layer addAnimation:transition forKey:kAWETitleRollingTextViewCubeTransitionAnimationKey];
        self.sourceView.hidden = NO;
        self.rollingContainerView.hidden = YES;
    } else {
        ACCBLOCK_INVOKE(completion);
    }
}

- (void)p_startRollingTextWithDuration:(NSTimeInterval)duration
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.duration = duration;
    animation.fromValue = @(0);
    animation.toValue = @(-self.subviewWidth);
    animation.removedOnCompletion = NO;
    animation.repeatCount = HUGE_VALF;
    self.rollingContainerView.layer.speed = 1.0;
    [self.rollingContainerView.layer addAnimation:animation forKey:nil];
}

#pragma mark - Easy to tap
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGSize bounds = self.bounds.size;
    if (point.x > -10 && point.x < bounds.width + 10) {
        if (point.y > -15 && point.y < bounds.height + 15) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (self.showRollingText) {
        self.rollingContainerView.hidden = NO;
        [self.transitionContainerView removeFromSuperview];
        self.transitionContainerView = nil;
        [self p_startRollingTextWithDuration:self.rollingDuration];
        self.showRollingText = NO;
    } else {
        [self.transitionContainerView removeFromSuperview];
        self.transitionContainerView = nil;
        ACCBLOCK_INVOKE(self.stopAnimationCompletion);
        self.stopAnimationCompletion = nil;
    }
}

@end

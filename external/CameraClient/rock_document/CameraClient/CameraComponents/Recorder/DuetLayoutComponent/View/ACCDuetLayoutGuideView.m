//
//  ACCDuetLayoutGuideView.m
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/2/24.
//

#import "ACCDuetLayoutGuideView.h"

#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/NSTimer+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>

#import <CreativeKit/ACCCacheProtocol.h>
#import <TTVideoEditor/VERecorder.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <lottie-ios/Lottie/LOTAnimationView.h>

static NSString *const kACCDuetLayoutGuideKey = @"kACCDuetLayoutGuideKey";
static CGFloat kAnimationYOffset = 56.0;
static NSString *const kACCDuetLayoutGuideAnimationLottieName = @"acc.duet.layout.guide.lottie.name";

typedef NS_ENUM(NSUInteger, ACCDuetLayoutGuideType) {
    ACCDuetLayoutGuideTypeNone,
    ACCDuetLayoutGuideTypeUpDown,
    ACCDuetLayoutGuideTypeThreeScreen,
};

@interface ACCDuetLayoutGuideView ()

@property (nonatomic, weak) UIView *containerView;
@property (nonatomic, strong) UIView *firstBlackView;
@property (nonatomic, strong) UIView *secondBlackView;
@property (nonatomic, assign) ACCDuetLayoutGuideType guideType;
@property(nonatomic, strong) LOTAnimationView *guideAnimationView;
@property (nonatomic, weak) id<VERecorderPublicProtocol> camera;
@property (nonatomic, strong) NSTimer *durationTimer;
@property (nonatomic, assign) BOOL hasAnimationOnce;//repeat twice

@end

@implementation ACCDuetLayoutGuideView

#pragma mark - public
+ (ACCDuetLayoutGuideView *)showDuetLayoutGuideViewIfNeededWithContainerView:(UIView *)containerView
                                                                  guideIndex:(NSInteger)index
{
    ACCDuetLayoutGuideType type = [self guideTypeFromGuideIndex:index];
    //we currently only support top-bottom and triple screen guide
    if (type == ACCDuetLayoutGuideTypeNone) {
        return nil;
    }
    NSString *storeKey = [self guideTypeStoreKeyForType:type];
    if ([ACCCache() boolForKey:storeKey]) {
        return nil;
    }

    [ACCCache() setBool:YES forKey:storeKey];
    ACCDuetLayoutGuideView *guideView = [[self alloc] initWithContainerView:containerView guideType:type];
    [guideView show];
    return guideView;
}

+ (ACCDuetLayoutGuideType)guideTypeFromGuideIndex:(NSInteger)guideIndex
{
    if (guideIndex == 2) {
        return ACCDuetLayoutGuideTypeUpDown;
    } else if (guideIndex == 3) {
        return ACCDuetLayoutGuideTypeThreeScreen;
    }
    return ACCDuetLayoutGuideTypeNone;
}

- (instancetype)initWithContainerView:(UIView *)containerView guideType:(ACCDuetLayoutGuideType)guideType
{
    if (self = [super initWithFrame:containerView.bounds]) {
        self.containerView = containerView;
        self.guideType = guideType;
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        [self addGestureRecognizer:tapRecognizer];
        [self setupUI];
    }
    return self;
}

+ (NSString *)guideTypeStoreKeyForType:(ACCDuetLayoutGuideType)type
{
    return [NSString stringWithFormat:@"%@-%zd", kACCDuetLayoutGuideKey, type];
}

- (void)setupUI
{
    if (self.guideType == ACCDuetLayoutGuideTypeUpDown) {
        [self setupUIForUpDownScreen];
    } else {
        [self setupUIForThreeScreen];
    }
    self.guideAnimationView.loopAnimation = NO;
    self.guideAnimationView.alpha = 0;
}

- (void)setupUIForUpDownScreen
{
    CGSize containerSize = self.bounds.size;
    CGFloat height = self.bounds.size.height / 2;
    self.firstBlackView.frame = CGRectMake(0, 0, containerSize.width, height + 1);
    [self addSubview:self.firstBlackView];
    
    [self.firstBlackView addSubview:self.guideAnimationView];
    CGFloat offset = self.firstBlackView.bounds.size.height / 2;
    CGFloat ratio = 1.088;
    offset *= ratio;
    self.guideAnimationView.center = CGPointMake(containerSize.width / 2, offset);
}

- (void)setupUIForThreeScreen
{
    CGSize containerSize = self.bounds.size;
    CGFloat HWRatio = 16 / 9.0;
    CGFloat cameraContentHeight = containerSize.width * HWRatio;
    cameraContentHeight = cameraContentHeight >= containerSize.height ? containerSize.height : cameraContentHeight;
    CGFloat height = cameraContentHeight / 3;
    CGFloat yOffset = (containerSize.height - cameraContentHeight) / 2;
    self.firstBlackView.frame = CGRectMake(0, yOffset, containerSize.width, height + 1);
    [self addSubview:self.firstBlackView];

    self.secondBlackView.frame = CGRectMake(0, containerSize.height - height - yOffset, containerSize.width, height);
    [self addSubview:self.secondBlackView];

    self.guideAnimationView.center = CGPointMake(containerSize.width / 2, (height / 2) + 10);
    [self.firstBlackView addSubview:self.guideAnimationView];
}

- (void)show
{
    [self.containerView addSubview:self];
    [self layoutIfNeeded];
    [self doAnimations];
}

- (void)doAnimations
{
    CGFloat showDuration = 0.12;
    CGFloat waitMovingDuration = 0.8;
    CGFloat movingStartTime = showDuration + waitMovingDuration;
    CGFloat movingDuration = 0.7;
    CGFloat waitDismissDuration = 0.52;
    CGFloat dismissDuration = showDuration;
    
    CGPoint start = [self startPoint];
    CGPoint center = self.guideAnimationView.center;
    CGPoint preCenter = center;

    [UIView animateWithDuration:showDuration animations:^{
        self.guideAnimationView.alpha = 1;
    } completion:^(BOOL finished) {
        [self.guideAnimationView play];
    }];
    
    center.y -= kAnimationYOffset;
    @weakify(self);
    CGFloat fireStartTime = movingStartTime;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fireStartTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        [self fireMovingCameraTimer];
    });
    [UIView animateWithDuration:movingDuration delay:movingStartTime options:UIViewAnimationOptionCurveLinear animations:^{
        self.guideAnimationView.center = center;
    } completion:^(BOOL finished) {
        if (self.hasAnimationOnce) {
            [UIView animateWithDuration:dismissDuration delay:waitDismissDuration options:UIViewAnimationOptionCurveLinear animations:^{
                self.guideAnimationView.alpha = 0;
                self.firstBlackView.alpha = 0;
            } completion:^(BOOL finished) {
                [self.camera handlePanEventWithTranslation:CGPointZero location:start];
                [self dismiss];
            }];
        } else {
            self.hasAnimationOnce = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @strongify(self);
                self.guideAnimationView.center = preCenter;
                [self.camera handlePanEventWithTranslation:CGPointZero location:start];
                [self.guideAnimationView stop];
                [self doAnimations];
            });
        }
    }];
}

- (void)dismiss
{
    [self.guideAnimationView stop];
    [self invalidateDurationTimer];
    [self removeFromSuperview];
}

#pragma mark - timer

- (CGPoint)startPoint
{
    CGSize containerSize = self.camera.previewView.acc_size;
    CGPoint startOrigin = [self.guideAnimationView.superview convertPoint:self.guideAnimationView.center toView:self.camera.previewView];
    CGPoint start = CGPointMake(startOrigin.x / containerSize.width, startOrigin.y / containerSize.height);
    return start;
}

- (void)fireMovingCameraTimer
{
    [self invalidateDurationTimer];
    CGSize containerSize = self.camera.previewView.acc_size;
    CGPoint center = self.guideAnimationView.center;
    center.y -= kAnimationYOffset;
    CGPoint startOrigin = [self.guideAnimationView.superview convertPoint:self.guideAnimationView.center toView:self.camera.previewView];
    CGPoint start = CGPointMake(startOrigin.x / containerSize.width, startOrigin.y / containerSize.height);
    [self.camera toggleGestureRecognition:YES type:VETouchGestureRecognitionTypeDrag];
    [self.camera handleTouchDown:start withType:IESMMGestureTypePan];
    [self.camera handlePanEventWithTranslation:CGPointZero location:start];

    @weakify(self);
    __block NSInteger i = 1;
    CGFloat movingDuration = 0.7;
    NSInteger stpesPerSeconds = 48;
    NSInteger stepCounts = movingDuration * stpesPerSeconds;
    CGFloat movingOffset = kAnimationYOffset * (self.guideType == ACCDuetLayoutGuideTypeUpDown ? 1/2.0 : 1/3.0);
    movingOffset /= containerSize.height;
    CGFloat delta = movingOffset / stepCounts;
    
    self.durationTimer = [NSTimer acc_scheduledTimerWithTimeInterval:(1.0 / stpesPerSeconds) block:^(NSTimer *timer){
        @strongify(self);
        CGPoint end = CGPointMake(start.x, (start.y - (i++) * delta));
        if (i == stepCounts) {
            [self invalidateDurationTimer];
        }

        [self.camera handlePanEventWithTranslation:CGPointZero location:end];
    } repeats:YES];
}

- (void)invalidateDurationTimer
{
    if (self.durationTimer) {
        [self.durationTimer invalidate];
        self.durationTimer = nil;
    }
}

#pragma mark - getter and setters
- (UIView *)firstBlackView
{
    if (!_firstBlackView) {
        _firstBlackView = [[UIView alloc] init];
        _firstBlackView.backgroundColor = ACCResourceColor(ACCUIColorConstSDSecondary);
}
    return _firstBlackView;
}

-(UIView *)secondBlackView
{
    if (!_secondBlackView) {
        _secondBlackView = [[UIView alloc] init];
        _secondBlackView.backgroundColor = ACCResourceColor(ACCUIColorConstSDSecondary);
    }
    return _secondBlackView;
}

- (LOTAnimationView *)guideAnimationView
{
    if (!_guideAnimationView) {
        NSString *animationName = [NSString acc_strValueWithName:kACCDuetLayoutGuideAnimationLottieName];
        _guideAnimationView = [LOTAnimationView animationWithFilePath:ACCResourceFile(animationName)];
        _guideAnimationView.frame = CGRectMake(0, 0, 140, 141);
        _guideAnimationView.loopAnimation = YES;
        _guideAnimationView.userInteractionEnabled = NO;
        _guideAnimationView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _guideAnimationView;
}

@end

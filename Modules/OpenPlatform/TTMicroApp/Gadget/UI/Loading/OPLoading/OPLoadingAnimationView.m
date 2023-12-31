//
//  BDPLoadingAnimationView.m
//  Timor
//
//  Created by CsoWhy on 2018/7/24.
//

#import "OPLoadingAnimationView.h"
#import <OPFoundation/OPUtils.h>
#import <OPFoundation/UIColor+OPExtension.h>
#import <OPFoundation/NSTimer+OPWeakTarget.h>
#import <Masonry/Masonry.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

#define animateCircleRadius 6

@interface OPLoadingAnimationView ()

@property (nonatomic, assign) CGFloat animateCircleCenterY;
@property (nonatomic, strong) UIView *animateCircle_1;
@property (nonatomic, strong) UIView *animateCircle_2;
@property (nonatomic, strong) UIView *animateCircle_3;

@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, strong) UIColor *colorDark;   // 三个点中深一点的那个色（与DarkMode无关）
@property (nonatomic, strong) UIColor *colorLight;  // 三个点中浅一点的那个色（与DarkMode无关）

@end

@implementation OPLoadingAnimationView

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame centerY:(frame.size.height - animateCircleRadius) / 2.0];
}

- (instancetype)initWithFrame:(CGRect)frame centerY:(CGFloat)centerY
{
    self = [super initWithFrame:frame];
    if (self) {
        _animateCircleCenterY = centerY;
        _animateCircle_1 = [[UIView alloc] init];
        [self setUpCircle:_animateCircle_1];
        _animateCircle_2 = [[UIView alloc] init];
        [self setUpCircle:_animateCircle_2];
        _animateCircle_3 = [[UIView alloc] init];
        [self setUpCircle:_animateCircle_3];
    }
    return self;
}

- (void)setUpCircle:(UIView *)circle
{
    circle.backgroundColor = self.colorDark;
    circle.layer.cornerRadius = animateCircleRadius / 2.0;
    [self addSubview:circle];
    // 此处布局为frame迁移为autolayout，布局逻辑遵循原始frame布局
    [circle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
        make.size.mas_equalTo(CGSizeMake(animateCircleRadius, animateCircleRadius));
    }];
}

- (void)dealloc
{
    [_timer invalidate];
    _timer = nil;
}

- (void)startLoading
{
    //Invalidate Timer
    [self.timer invalidate];
    
    //Reset Position
    [self setCirclesDistanceWithPercent:1.3];
    
    //Timer to play Animation
    [self playLoadingAnimation];
    WeakSelf;
    NSTimer *timer = [NSTimer op_repeatedTimerWithInterval:0.5 target:self block:^(NSTimer * _Nonnull timer) {
        StrongSelfIfNilReturn;
        [self playLoadingAnimation];
    }];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.timer = timer;
}

- (void)stopLoading
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)playLoadingAnimation
{
    //Params
    CGFloat multiple = 1.2;
    CGFloat duration = 0.3;
    CGFloat delay = 0.1;
    
    //Animate_Circle_1
    [self animateWithDuration:duration animations:^{
        self.animateCircle_1.backgroundColor = self.colorDark;
        self.animateCircle_1.transform = CGAffineTransformMakeScale(multiple, multiple);
        
        //Animate_Circle_2
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self animateWithDuration:duration animations:^{
                self.animateCircle_2.backgroundColor = self.colorDark;
                self.animateCircle_2.transform = CGAffineTransformMakeScale(multiple, multiple);
                
                //Animate_Circle_3
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self animateWithDuration:duration animations:^{
                        self.animateCircle_3.backgroundColor = self.colorDark;
                        self.animateCircle_3.transform = CGAffineTransformMakeScale(multiple, multiple);
                    } completion:^(BOOL finished) {
                        
                        //Animate_Circle_3恢复
                        [self animateWithDuration:duration animations:^{
                            self.animateCircle_3.backgroundColor = self.colorLight;
                            self.animateCircle_3.transform = CGAffineTransformIdentity;
                        } completion:nil];
                    }];
                });
            } completion:^(BOOL finished) {
                
                //Animate_Circle_2恢复
                [self animateWithDuration:duration animations:^{
                    self.animateCircle_2.backgroundColor = self.colorLight;
                    self.animateCircle_2.transform = CGAffineTransformIdentity;
                } completion:nil];
            }];
        });
    } completion:^(BOOL finished) {
        
        //Animate_Circle_1恢复
        [self animateWithDuration:duration animations:^{
            self.animateCircle_1.backgroundColor = self.colorLight;
            self.animateCircle_1.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
}

- (void)animateWithDuration:(CGFloat)duration animations:(void (^)(void))animation completion:(void (^)(BOOL finished))completion
{
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.48 :0.04 :0.52 :0.96]];
    [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        animation();
    } completion:^(BOOL finished) {
        if (completion) {
            completion(finished);
        }
    }];
    [CATransaction commit];
}

- (void)setCirclesDistanceWithPercent:(CGFloat)percent
{
    [_animateCircle_1 mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(_animateCircle_2);
        make.leading.mas_equalTo(_animateCircle_2).offset(-11*percent);
        make.size.mas_equalTo(CGSizeMake(animateCircleRadius, animateCircleRadius));
    }];
    [_animateCircle_3 mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(_animateCircle_2);
        make.leading.mas_equalTo(_animateCircle_2).offset(11*percent);
        make.size.mas_equalTo(CGSizeMake(animateCircleRadius, animateCircleRadius));
    }];
    
    // Reset AnimateCircle Color
    _animateCircle_1.backgroundColor = self.colorDark;
    _animateCircle_2.backgroundColor = self.colorDark;
    _animateCircle_3.backgroundColor = self.colorDark;
}

- (CGFloat)getAnimateCenterY
{
    return _animateCircleCenterY;
}

- (void)setCircleStyle:(BDPLoadingAnimationViewStyle)circleStyle
{
    _circleStyle = circleStyle;
    _colorLight = nil;
    _colorDark = nil;
}

- (UIColor *)colorDark
{
    if (!_colorDark) {
        switch (_circleStyle) {
            case BDPLoadingAnimationViewStyleNone:
                _colorDark = UDOCColor.N200;
                break;
            case BDPLoadingAnimationViewStyleDark:
                _colorDark = [UIColor colorWithRed:0.f green:0 blue:0 alpha:0.2f];
                break;
            case BDPLoadingAnimationViewStyleLight:
                _colorDark = [UIColor colorWithRed:1.f green:1.f blue:1.f alpha:0.3f];
                break;
        }
    }
    return _colorDark;
}

- (UIColor *)colorLight
{
    if (!_colorLight) {
        switch (_circleStyle) {
            case BDPLoadingAnimationViewStyleNone:
                _colorLight = UDOCColor.N400;
                break;
            case BDPLoadingAnimationViewStyleDark:
                _colorLight = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:.1f];
                break;
            case BDPLoadingAnimationViewStyleLight:
                _colorLight = [UIColor colorWithRed:1.f green:1.f blue:1.f alpha:.2f];
                break;
        }
    }
    return _colorLight;
}

@end

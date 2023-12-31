//
//  ACCCutSameCropMaskView.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/12.
//

#import "ACCCutSameCropMaskView.h"
#import <CreativeKit/UIColor+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

@interface ACCCutSameCropMaskView ()

@property (nonatomic, strong) UIVisualEffectView *blurView;

@property (nonatomic, strong) UIView *frameView;

@end

@implementation ACCCutSameCropMaskView

- (instancetype)initWithFrame:(CGRect)frame isBlackMask:(BOOL)isBlackMask
{
    if (self = [super initWithFrame:frame]) {
        if (isBlackMask) {
            self.backgroundColor = ACCResourceColor(ACCColorBGCreation);
        } else {
            self.backgroundColor = [[UIColor acc_colorWithHexString:@"#0E0F1A"] colorWithAlphaComponent:0.6];
        }
        [self addSubview:self.blurView];
        [self addSubview:self.frameView];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.blurView.frame = self.bounds;
    [self refresh];
}

- (void)setFrameSize:(CGSize)frameSize
{
    _frameSize = frameSize;
    
    [self refresh];
}

- (void)setOffset:(CGPoint)offset
{
    _offset = offset;
    
    [self refresh];
}

- (void)refresh
{
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.bounds];
    [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake((self.bounds.size.width - _frameSize.width) / 2 + self.offset.x,
                                                                 (self.bounds.size.height - _frameSize.height) / 2 + self.offset.y,
                                                                 _frameSize.width,
                                                                 _frameSize.height)]];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.backgroundColor = [UIColor blackColor].CGColor;
    maskLayer.path = path.CGPath;
    maskLayer.fillRule = kCAFillRuleEvenOdd;
    
    [self.layer setMask:maskLayer];
    
    self.frameView.frame = CGRectMake(((self.bounds.size.width - (_frameSize.width+1)) / 2) + self.offset.x,
                                      ((self.bounds.size.height - (_frameSize.height+1)) / 2) + self.offset.y,
                                      (_frameSize.width+1),
                                      (_frameSize.height+1));
}

- (void)animateForBlurEffect:(BOOL)blur animate:(BOOL)animate
{
    dispatch_block_t block = ^{
        @try {
            self.blurView.effect = blur ? [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark] : nil;
        } @catch (NSException *exception) {
            
        }
    };

    if (animate) {
        [UIView animateWithDuration:0.3
                         animations:^{
            block();
        }];
    } else {
        block();
    }
}

- (UIVisualEffectView *)blurView
{
    if (!_blurView) {
        _blurView = [[UIVisualEffectView alloc] initWithEffect:nil];
    }
    return _blurView;
}

- (UIView *)frameView
{
    if (!_frameView) {
        _frameView = [[UIView alloc] initWithFrame:CGRectZero];
        _frameView.backgroundColor = [UIColor clearColor];
        _frameView.userInteractionEnabled = NO;
        _frameView.layer.borderWidth = 1.0/[UIScreen mainScreen].scale;
        _frameView.layer.borderColor = [UIColor whiteColor].CGColor;
    }
    
    return _frameView;
}

@end

//
//  ACCLightningRecordLongtailView.m
//  CameraClient-Pods-Aweme
//
//  Created by Kevin Chen on 2021/4/14.
//

#import <CreativeKit/UIImage+CameraClientResource.h>
#import "ACCLightningRecordLongtailView.h"
#import "ACCConfigKeyDefines.h"
#import <CameraClient/ACCRecordMode+LiteTheme.h>

// same diameter as the blur view
static const CGFloat kDiameterLT = 130;
static const CGFloat kDiameterShrink = 64;
// UI 给的图不标准
static const CGFloat kRadiusHeadMax = 5.2;
static const CGFloat kRadiusHeadMin = 1.1;

@interface ACCLightningRecordLongtailView ()

@property (nonatomic, strong) UIView *longtailView;


@property (nonatomic, strong) CALayer *longtailLayer;

@property (nonatomic, strong) CAShapeLayer *maskLayer;

@end

@implementation ACCLightningRecordLongtailView

@synthesize state = _state, recordMode = _recordMode;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(0, 0, kDiameterLT, kDiameterLT)];
    if (self) {
        self.longtailView = [[UIView alloc] initWithFrame:self.frame];
        [self addSubview:self.longtailView];
        
        _longtailLayer = [CALayer layer];
        _longtailLayer.frame = self.bounds;
        _longtailLayer.contents = (__bridge id)(ACCResourceImage(@"icon_longtail_progress").CGImage);
        [self.longtailView.layer addSublayer:_longtailLayer];
        
        _maskLayer = [CAShapeLayer layer];
        _maskLayer.frame = self.frame;
        _maskLayer.backgroundColor = [UIColor.clearColor colorWithAlphaComponent:0].CGColor;
        _maskLayer.fillColor = [UIColor.clearColor colorWithAlphaComponent:1].CGColor;
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path addArcWithCenter:CGPointMake(kDiameterLT / 2, kDiameterLT / 2) radius:kDiameterLT / 2 startAngle:M_PI + M_PI_2 endAngle:M_PI_2 clockwise:YES];
        [path addArcWithCenter:CGPointMake(kDiameterLT / 2, kRadiusHeadMax) radius:kRadiusHeadMax startAngle:M_PI_2 endAngle:M_PI + M_PI_2 clockwise:YES];
        [path closePath];
        _maskLayer.path = path.CGPath;
        self.longtailView.layer.mask = _maskLayer;
    }
    return self;
}

- (void)setProgress:(float)progress animated:(BOOL)animated
{
    if (!self.recordMode.isStoryStyleMode) {
        return;
    }
    self.longtailLayer.transform = CATransform3DMakeRotation(2 * M_PI * progress, 0, 0, 1);
    if (progress > 0.4) {
        self.longtailView.layer.mask = nil;
    } else {
        CGFloat radius = (0.39 - progress) / 0.39 * (kRadiusHeadMax - kRadiusHeadMin) + kRadiusHeadMin;
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path addArcWithCenter:CGPointMake(kDiameterLT / 2, kDiameterLT / 2) radius:kDiameterLT / 2 startAngle:M_PI + M_PI_2 endAngle:M_PI_2 clockwise:YES];
        [path addArcWithCenter:CGPointMake(kDiameterLT / 2, radius) radius:radius startAngle:M_PI_2 endAngle:M_PI + M_PI_2 clockwise:YES];
        [path closePath];
        self.maskLayer.path = path.CGPath;
        self.longtailView.layer.mask = self.maskLayer;
    }
}

- (void)setState:(ACCRecordButtonState)state
{
    if (!self.recordMode.isStoryStyleMode || !ACCConfigBool(kConfigBool_longtail_shoot_animation)) {
        self.longtailView.hidden = YES;
        return;
    }
    switch (state) {
        case ACCRecordButtonBegin: {
            self.longtailView.hidden = YES;
            self.longtailView.layer.mask = self.maskLayer;
            self.longtailLayer.transform = CATransform3DIdentity;
            self.longtailView.transform = CGAffineTransformMakeScale(kDiameterShrink / kDiameterLT, kDiameterShrink / kDiameterLT);
            break;
        }
        case ACCRecordButtonRecording: {
            self.longtailView.hidden = NO;
            [UIView animateWithDuration:kACCRecordAnimateDuration animations:^{
                self.longtailView.transform = CGAffineTransformIdentity;
            }];
            break;
        }
        case ACCRecordButtonPicture: {
            self.longtailView.hidden = YES;
            self.longtailView.layer.mask = self.maskLayer;
            break;
        }
        case ACCRecordButtonPaused: {
            self.longtailView.hidden = YES;
            break;
        }
        default:
            break;
    }
}

@end

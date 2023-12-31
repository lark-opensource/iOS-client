//
//  ACCLightningRecordAlienationView.m
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/11.
//

#import "ACCLightningRecordAlienationView.h"
#import "ACCRecordMode+MeteorMode.h"

#import <CreativeKit/ACCResourceHeaders.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/View+MASAdditions.h>

static const CGFloat kDiameter1 = 64; // ACCRecordButtonBegin

@interface ACCLightningRecordAlienationView ()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *iconImageView;

@end

@implementation ACCLightningRecordAlienationView

@synthesize state = _state;
@synthesize recordMode = _recordMode;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:CGRectMake(0, 0, kDiameter1, kDiameter1)]) {
        self.backgroundColor = UIColor.whiteColor; 
        self.layer.cornerRadius = kDiameter1 / 2;
        self.userInteractionEnabled = NO;
        
        [self addSubview:self.backgroundImageView];
        [self addSubview:self.iconImageView];
        
        ACCMasMaker(self.backgroundImageView, {
            make.edges.equalTo(self);
        });
        
        ACCMasMaker(self.iconImageView, {
            make.center.equalTo(self);
            make.width.height.equalTo(@(34));
        });
    }
    return self;
}

- (void)setState:(ACCRecordButtonState)state
{
    if (state == ACCRecordButtonBegin || state == ACCRecordButtonPicture) {
        self.hidden = !self.recordMode.isMeteorMode;
        if (self.hidden) {
            self.backgroundImageView.transform = CGAffineTransformIdentity;
        } else {
            CABasicAnimation *rotationAnimation;
            rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            rotationAnimation.fromValue = 0;
            rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI / 3 * 2];
            rotationAnimation.duration = 0.55;
            rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            [rotationAnimation setRemovedOnCompletion:NO];
            [rotationAnimation setFillMode:kCAFillModeForwards];
            [self.backgroundImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
        }
    } else {
        self.hidden = YES;
    }
}

-(UIImageView *)backgroundImageView
{
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] init];
        _backgroundImageView.image = ACCResourceImage(@"icon_camera_meteor_mode_bg");
    }
    return _backgroundImageView;
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.image = ACCResourceImage(@"icon_camera_meteor_mode_on");
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _iconImageView;
}

@end

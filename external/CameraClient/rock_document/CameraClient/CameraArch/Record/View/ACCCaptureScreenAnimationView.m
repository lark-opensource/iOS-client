//
//  ACCCaptureScreenAnimationView.m
//  CameraClient-Pods-Aweme
//
//  Created by lingbinxing on 2021/8/15.
//

#import "ACCCaptureScreenAnimationView.h"
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

@interface ACCCaptureScreenAnimationView ()

@property (nonatomic, strong) UIImageView *loadingView;

@end

@implementation ACCCaptureScreenAnimationView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        
        _loadingView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icon_busy_loading")];
        _loadingView.hidden = YES;
        [self addSubview:_loadingView];
        
        ACCMasMaker(_loadingView, {
            make.centerX.equalTo(self);
            make.centerY.equalTo(self);
        });
        
        [self updateHiddenByAnimation];
    }
    return self;
}

- (void)startLoadingAnimation
{
    self.loadingView.hidden = NO;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
    animation.duration = 0.8;
    animation.cumulative = YES;
    animation.repeatCount = HUGE_VAL;
    [self.loadingView.layer addAnimation:animation forKey:@"transform.rotation.z"];
    [self updateHiddenByAnimation];
}

- (void)stopLoadingAnimation
{
    self.loadingView.hidden = YES;
    [self.loadingView.layer removeAllAnimations];
    [self updateHiddenByAnimation];
}

- (void)updateHiddenByAnimation
{
    BOOL isLoading = self.loadingView.layer.animationKeys.count != 0;
    self.hidden = !isLoading;
}

@end

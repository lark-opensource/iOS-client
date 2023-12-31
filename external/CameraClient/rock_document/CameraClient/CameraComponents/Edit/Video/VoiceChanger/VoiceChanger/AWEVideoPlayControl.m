//
//  AWEVideoPlayControl.m
//  Aweme
//
//  Created by Liu Bing on 4/11/17.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import "AWEVideoPlayControl.h"
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

static double kTransformScale = 1.2;
static double kAnimationDuration = 0.2;

@implementation AWEVideoPlayControl

- (void)setImage:(UIImage *)image
{
    self.animationView.image = image;
    self.animationView.frame = CGRectMake(0, 0, image.size.width / image.scale, image.size.height / image.scale);
    _animationView.center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
    [self addSubview:_animationView];
}

- (void)setImageWithName:(NSString *)imageName
{
    UIImage *image = ACCResourceImage(imageName);
    self.animationView.image = image;
    self.animationView.frame = CGRectMake(0, 0, image.size.width / image.scale, image.size.height / image.scale);
    _animationView.center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
    [self addSubview:_animationView];
}


- (UIImageView *)animationView
{
    if (_animationView == nil) {
        _animationView = [[UIImageView alloc] init];
        _animationView.contentMode = UIViewContentModeCenter;
    }
    return _animationView;
}

- (BOOL)canMove
{
    if (!self.userInteractionEnabled || self.alpha < 0.01 || self.hidden) {
        return NO;
    }
    
    return YES;
}

@end

@interface AWEVideoProgressControl ()

@property (nonatomic, strong) UIView *shadowView;
@property (nonatomic, strong) UIView *whiteStripeView;

@end

@implementation AWEVideoProgressControl

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _shadowView = [[UIView alloc] initWithFrame:CGRectZero];
        _shadowView.backgroundColor = [UIColor clearColor];
        _whiteStripeView = [[UIView alloc] initWithFrame:CGRectZero];
        _whiteStripeView.backgroundColor = [UIColor whiteColor];
        _whiteStripeView.hidden = YES;
        [self addSubview:_shadowView];
        [self addSubview:_whiteStripeView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.animationView.bounds].CGPath;
}

- (void)setImage:(UIImage *)image
{
    [self refreshUI];
}

- (void)refreshUI
{
    self.whiteStripeView.hidden = NO;
    self.whiteStripeView.frame = CGRectMake(0, 0, 4, [self progressControlHeight]);
    self.whiteStripeView.center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
    self.whiteStripeView.layer.cornerRadius = 2.0;
    self.shadowView.frame = CGRectMake(0, 0, 4, [self progressControlHeight]);
    self.shadowView.center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
    self.shadowView.layer.shadowRadius = 6;
    self.shadowView.layer.shadowOffset = CGSizeMake(0, 1);
    self.shadowView.layer.shadowOpacity = 0.4;
    self.shadowView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.shadowView.bounds].CGPath;
    self.shadowView.layer.shadowColor = UIColor.blackColor.CGColor;
}

- (void)setImageWithName:(NSString *)imageName
{
    [super setImageWithName:imageName];
    UIImage *image = ACCResourceImage(imageName);
    self.shadowView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    self.shadowView.center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
    self.shadowView.layer.shadowRadius = 6;
    self.shadowView.layer.shadowOffset = CGSizeMake(0, 1);
    self.shadowView.layer.shadowOpacity = 0.4;
    self.shadowView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.animationView.bounds].CGPath;
    self.shadowView.layer.shadowColor = UIColor.blackColor.CGColor;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    UIView *animatedView = self.whiteStripeView;
    if (selected) {
        animatedView.layer.shadowRadius = 12;
        animatedView.layer.shadowOffset = CGSizeMake(0, 1);
        animatedView.layer.shadowPath = [UIBezierPath bezierPathWithRect:animatedView.bounds].CGPath;
        [UIView animateWithDuration:kAnimationDuration animations:^{
            animatedView.layer.shadowColor = [ACCResourceColor(ACCUIColorConstPrimary2) colorWithAlphaComponent:0.3].CGColor;
            animatedView.transform = CGAffineTransformMakeScale(kTransformScale, kTransformScale);
            self.shadowView.transform = CGAffineTransformMakeScale(kTransformScale, kTransformScale);
        }];
    } else {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            animatedView.layer.shadowColor = [UIColor clearColor].CGColor;
            animatedView.transform = CGAffineTransformMakeScale(1.0, 1.0);
            self.shadowView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        }];
    }
}

- (CGFloat)progressControlHeight
{
    return 44.f;
}

@end

@implementation AWETimeSelectControl

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected) {
        self.animationView.layer.shadowRadius = 12;
        self.animationView.layer.shadowOffset = CGSizeMake(0, 2);
        self.animationView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.animationView.bounds].CGPath;
        
        [UIView animateWithDuration:kAnimationDuration animations:^{
            self.animationView.layer.shadowColor = [self.shadowColor colorWithAlphaComponent:0.3].CGColor;
            self.animationView.transform = CGAffineTransformMakeScale(kTransformScale, kTransformScale);
        }];
    } else {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            self.animationView.layer.shadowColor = [UIColor clearColor].CGColor;
            self.animationView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        }];
    }
}

@end


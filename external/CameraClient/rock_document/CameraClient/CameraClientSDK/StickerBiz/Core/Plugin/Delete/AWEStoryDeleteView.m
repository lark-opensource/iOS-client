//
//  AWEStoryDeleteView.m
//  AWEStudio
//
//  Created by hanxu on 2018/11/22.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEStoryDeleteView.h"
#import "AWEXScreenAdaptManager.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCRTL.h>

@interface AWEStoryDeleteView ()

@property (nonatomic, strong) UIView *corView;
@property (nonatomic, strong) UIImageView *topImageView;
@property (nonatomic, strong) UIImageView *bottomImageView;
@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation AWEStoryDeleteView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.accrtl_viewType = ACCRTLViewTypeNormalWithAllDescendants;
        self.corView = [[UIView alloc] init];
        self.corView.backgroundColor = ACCResourceColor(ACCUIColorNegative2);
        self.corView.layer.cornerRadius = 36;
        
        self.topImageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icCameraVideoDelete1")];
        self.topImageView.layer.anchorPoint = CGPointMake(0, 1);

        self.bottomImageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icCameraVideoDelete2")];
        
        self.textLabel = [[UILabel alloc] init];
        self.textLabel.font = [ACCFont() systemFontOfSize:11 weight:ACCFontWeightMedium];
        self.textLabel.shadowColor = [ACCResourceColor(ACCUIColorBGContainer) colorWithAlphaComponent:0.2];
        self.textLabel.shadowOffset = CGSizeMake(0, 0.5);
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.text =  ACCLocalizedString(@"delete",@"delete");
        [self.textLabel sizeToFit];
        
        [self addSubview:self.corView];
        [self addSubview:self.topImageView];
        [self addSubview:self.bottomImageView];
        [self addSubview:self.textLabel];

        self.topImageView.frame = CGRectMake(0, 0, 25, 7.5);
        self.bottomImageView.frame = CGRectMake(0, 7.5, 25, 20);
        self.textLabel.center = CGPointMake(25 * 0.5, CGRectGetMaxY(self.bottomImageView.frame) + 12);
        self.frame = CGRectMake(0, 0, 25, CGRectGetMaxY(self.textLabel.frame));
        self.corView.frame = CGRectMake(0, 0, 72, 72);
        self.corView.center = CGPointMake(25 * 0.5, 27.5 * 0.5);
        self.corView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        
        self.acc_top = [[self class] recommendTopWithAdjustment:NO];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
}

- (void)onDeleteActived
{
    CATransform3D initTransform = CATransform3DMakeScale(0, 0, 0);
    CATransform3D targetTransform = CATransform3DIdentity;
    
    self.layer.transform = initTransform;
    [self.layer removeAllAnimations];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.alpha = 1;
        self.layer.transform = targetTransform;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)onDeleteInActived
{
    CATransform3D targetTransform = CATransform3DMakeScale(0.01, 0.01, 0.01);
    CATransform3D initTransform = CATransform3DIdentity;
    
    self.layer.transform = initTransform;
    [self.layer removeAllAnimations];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.alpha = 0;
        self.layer.transform = targetTransform;
    } completion:^(BOOL finished) {
        self.layer.transform = initTransform;
    }];
}

- (void)startAnimation
{
    self.corView.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.textLabel.alpha = 0;
        self.textLabel.transform = CGAffineTransformMakeScale(1.0 / 1.2, 1.0 / 1.2);
        self.corView.transform = CGAffineTransformMakeScale(1.0 / 1.2, 1.0 / 1.2);
        self.topImageView.transform = CGAffineTransformMakeRotation(- 32.0 / 180.0 * M_PI);
        self.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)stopAnimation
{
    [UIView animateWithDuration:0.2 animations:^{
        self.textLabel.alpha = 1;
        self.transform = CGAffineTransformIdentity;
        self.corView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        self.topImageView.transform = CGAffineTransformIdentity;
        self.textLabel.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.corView.hidden = YES;
    }];
}

+ (CGRect)handleFrame
{
    CGRect rect = CGRectMake(0.5 * (ACC_SCREEN_WIDTH - 40), [[self class] recommendTopWithAdjustment:NO], 40, 40);
    return CGRectInset(rect, -6, -6);
}

+ (CGFloat)recommendTopWithAdjustment:(BOOL)needToAdjust
{
    if (needToAdjust) {
        CGFloat spacing = 9;
        CGFloat topOffset = 48;

        if (@available(iOS 11.0,*)) {
            if ([AWEXScreenAdaptManager needAdaptScreen]) {
                spacing = 24;
            }
        }
        return ACC_STATUS_BAR_NORMAL_HEIGHT + topOffset + spacing + 16;
    }

    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        return (40 + ACC_NAVIGATION_BAR_OFFSET) * ACC_SCREEN_WIDTH / 375.0;
    }

    if ([UIDevice acc_isIPhoneX]) {
        return 38 + ACC_NAVIGATION_BAR_OFFSET;
    }
    
    return 26.5;
}

@end

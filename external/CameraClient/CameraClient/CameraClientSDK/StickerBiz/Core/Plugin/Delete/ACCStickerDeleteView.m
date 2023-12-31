//
//  ACCStickerDeleteView.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/4/22.
//

#import "ACCStickerDeleteView.h"
#import "AWEXScreenAdaptManager.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCRTL.h>

@interface ACCStickerDeleteView ()

@property (nonatomic, strong) UIView *corView;
@property (nonatomic, strong) UIImageView *topImageView;
@property (nonatomic, strong) UIImageView *bottomImageView;
@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation ACCStickerDeleteView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.accrtl_viewType = ACCRTLViewTypeNormalWithAllDescendants;
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        [self addSubview:effectView];
        effectView.layer.cornerRadius = 20;
        effectView.clipsToBounds = YES;
        effectView.frame = CGRectMake(0, 0, 110, 76);
        if (@available(iOS 13.0, *)) {
            effectView.layer.cornerCurve = kCACornerCurveContinuous;
        }

        self.corView = [[UIView alloc] init];
        self.corView.backgroundColor = ACCResourceColor(ACCUIColorBGContainer3);
        self.corView.layer.cornerRadius = 20;
        self.corView.clipsToBounds = YES;
        if (@available(iOS 13.0, *)) {
            self.corView.layer.cornerCurve = kCACornerCurveContinuous;
        }

        self.topImageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icCameraVideoDelete1")];
        self.topImageView.layer.anchorPoint = CGPointMake(0, 1);
        self.topImageView.frame = CGRectMake(42, 14, 25, 7.5);

        self.bottomImageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icCameraVideoDelete2")];
        
        self.textLabel = [[UILabel alloc] init];
        self.textLabel.font = [ACCFont() systemFontOfSize:13 weight:ACCFontWeightMedium];
        self.textLabel.shadowColor = [ACCResourceColor(ACCUIColorBGContainer) colorWithAlphaComponent:0.2];
        self.textLabel.shadowOffset = CGSizeMake(0, 0.5);
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.text =  @"拖到这里删除";
        [self.textLabel sizeToFit];
        
        [self addSubview:self.corView];
        [self addSubview:self.topImageView];
        [self addSubview:self.bottomImageView];
        [self addSubview:self.textLabel];

        self.frame = CGRectMake(0, 0, 110, 76);
    }
    return self;
}

- (void)onDeleteActived
{
    [self.layer removeAllAnimations];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)onDeleteInActived
{
    [self.layer removeAllAnimations];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
    }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.corView.frame = self.bounds;
    self.bottomImageView.frame = CGRectMake(0, 12 + 7.5, 25, 20);
    self.bottomImageView.center = CGPointMake(self.bounds.size.width * 0.5, self.bottomImageView.center.y);
    self.textLabel.acc_top = CGRectGetMaxY(self.bottomImageView.frame) + 4;
    self.textLabel.acc_centerX = self.bounds.size.width * 0.5;
    self.acc_top = [[self class] recommendTopWithAdjustment:NO];
}

- (void)startAnimation
{
    self.corView.hidden = NO;
    self.textLabel.text =  @"松手即可删除";
    [UIView animateWithDuration:0.2 animations:^{
        self.corView.backgroundColor = ACCResourceColor(ACCUIColorNegative);
        self.topImageView.transform = CGAffineTransformMakeRotation(- 32.0 / 180.0 * M_PI);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)stopAnimation
{
    self.textLabel.text =  @"拖到这里删除";
    [UIView animateWithDuration:0.2 animations:^{
        self.corView.backgroundColor = ACCResourceColor(ACCColorConstLineInverse);
        self.topImageView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {

    }];
}

+ (CGRect)handleFrame
{
    CGRect rect = CGRectMake(0.5 * (ACC_SCREEN_WIDTH - 110), ACC_SCREEN_HEIGHT - [[self class] recommendTopWithAdjustment:NO], 110, 72);
    return CGRectInset(rect, -6, -6);
}

+ (CGFloat)recommendTopWithAdjustment:(BOOL)needToAdjust
{
    CGFloat height = 76;
    CGFloat margin = 8;
    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        return ACC_SCREEN_HEIGHT - (margin + ACC_IPHONE_X_BOTTOM_OFFSET) * ACC_SCREEN_WIDTH / 375.0 - height;
    }
    
    return ACC_SCREEN_HEIGHT - margin - height;
}

@end

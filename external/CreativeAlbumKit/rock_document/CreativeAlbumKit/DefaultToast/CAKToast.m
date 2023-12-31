//
//  CAKToast.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/14.
//

#import "CAKToast.h"
#import "UIColor+AlbumKit.h"
#import <objc/runtime.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreationKitInfra/ACCResponder.h>
#import <Masonry/View+MASAdditions.h>

typedef NS_ENUM(NSUInteger, CAKToastAnimationType){
    CAKToastAnimationTypeNavigationBar,
    CAKToastAnimationTypeDangling,
};

static NSTimer *cakDismissTimer;
static UIView *cakActiveToast;
static CAKToastAnimationType cakAnimationType;
static CGRect cakToastTargetFrame;

#define CAKTOAST_OFFSET_Y ACC_STATUS_BAR_NORMAL_HEIGHT + 32

@implementation CAKToast

+ (void)showToast:(NSString *)content
{
    [self showToast:content withStyle:CAKToastStyleNormal];
}

+ (void)showToast:(NSString *)content withStyle:(CAKToastStyle)style
{
    [self showToast:content onViewController:[ACCResponder topViewController] withStyle:style];
}

+ (void)showToast:(NSString *)content onViewController:(UIViewController *)targetViewController withStyle:(CAKToastStyle)style
{
    UIView *targetView = targetViewController.view;

    if (!targetView) {
        targetView = [UIApplication sharedApplication].keyWindow;
    }

    if (targetViewController && targetViewController.navigationController.navigationBar && !targetViewController.navigationController.navigationBar.hidden) {
        cakAnimationType = CAKToastAnimationTypeNavigationBar;
        [self showToast:(NSString *)content
                 onView:targetView
              withFrame:CGRectMake(0, CGRectGetMaxY([targetView convertRect:targetViewController.navigationController.navigationBar.bounds fromView:targetViewController.navigationController.navigationBar]), CGRectGetWidth(targetView.bounds), 34)
              withStyle:style];
    } else {
        cakAnimationType = CAKToastAnimationTypeDangling;
        [self showToast:(NSString *)content
                 onView:targetView
              withFrame:CGRectMake(16, CAKTOAST_OFFSET_Y, CGRectGetWidth(targetView.bounds) - 32, 34)
              withStyle:style];
    }
}

+ (void)showToast:(NSString *)content onView:(UIView *)view withStyle:(CAKToastStyle)style
{
    cakAnimationType = CAKToastAnimationTypeDangling;
    [self showToast:(NSString *)content
             onView:view
          withFrame:CGRectMake(16, CAKTOAST_OFFSET_Y, CGRectGetWidth(view.bounds) - 32, 34)
          withStyle:style];
}

+ (void)showToast:(NSString *)content onView:(UIView *)view withFrame:(CGRect)frame withStyle:(CAKToastStyle)style
{
    void (^block)(UIView *displayView) = ^(UIView *displayView){
        [self dismissToast];
        
        if (!displayView) {
            displayView = [UIApplication sharedApplication].keyWindow;
        }
        
        UIView *toastView = [[UIView alloc] initWithFrame:frame];
        if (fabs(CGRectGetMinX(frame)) > 0.01) {
            toastView.layer.cornerRadius = 2.0;
            toastView.clipsToBounds = YES;
        }
        toastView.backgroundColor = CAKResourceColor(ACCColorToastDefault);
        UIView *containerView = [[UIView alloc] init];
        [toastView addSubview:containerView];
        
        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.textColor = CAKResourceColor(ACCUIColorConstTextInverse);
        textLabel.font = [UIFont acc_systemFontOfSize:14 weight:ACCFontWeightSemibold];
        textLabel.numberOfLines = 3;
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.text = content;
        
        UIImageView *imageView = nil;
        
        [containerView addSubview:textLabel];
        [containerView addSubview:imageView];
        
        [textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.top.bottom.equalTo(containerView);
            if (imageView) {
                make.left.equalTo(imageView.mas_right).offset(8.3);
            } else {
                make.left.equalTo(containerView);
            }
        }];
        
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(containerView);
            make.top.equalTo(textLabel);
            make.width.height.equalTo(@16);
        }];
        
        [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(toastView);
            make.left.greaterThanOrEqualTo(@(16));
            make.right.lessThanOrEqualTo(@(-16));
            make.top.greaterThanOrEqualTo(toastView).offset(7);
            make.bottom.lessThanOrEqualTo(toastView).offset(-7);
        }];
        
        [displayView addSubview:toastView];
        
        [toastView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(frame.size.width);
            make.height.mas_greaterThanOrEqualTo(frame.size.height);
            make.top.mas_equalTo(frame.origin.y);
            make.left.mas_equalTo(frame.origin.x);
        }];
        
        [toastView.superview layoutSubviews];
        
        if (cakAnimationType == CAKToastAnimationTypeDangling) {
            toastView.transform = CGAffineTransformMakeTranslation(0, -CGRectGetHeight(toastView.bounds) / 2);
            toastView.alpha = 0;
        } else {
            toastView.transform = CGAffineTransformMakeTranslation(0, -CGRectGetHeight(toastView.bounds));
            toastView.alpha = 0;
        }
        
        [toastView.superview layoutSubviews];
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toastView.alpha = 1;
            toastView.transform = CGAffineTransformIdentity;
        } completion:nil];
        
        cakActiveToast = toastView;
        cakDismissTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(toastTimeUp:) userInfo:nil repeats:NO];
        cakToastTargetFrame = frame;
    };
    if ([NSThread isMainThread]) {
        block(view);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(view);
        });
    }
}

+ (void)toastTimeUp:(NSTimer *)timer
{
    [self dismissToast];
}

+ (void)dismissToast
{
    if (cakActiveToast) {
        UIView *dismissingToast = cakActiveToast;
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if (cakAnimationType == CAKToastAnimationTypeDangling) {
                dismissingToast.transform = CGAffineTransformMakeTranslation(0, -CGRectGetHeight(dismissingToast.bounds) / 2);
                dismissingToast.alpha = 0;
            } else {
                dismissingToast.transform = CGAffineTransformMakeTranslation(0, -CGRectGetHeight(dismissingToast.bounds));
                dismissingToast.alpha = 0;
            }
        } completion:^(BOOL finished) {
            [dismissingToast removeFromSuperview];
        }];
        [cakDismissTimer invalidate];
        cakDismissTimer = nil;
        cakActiveToast = nil;
    }
}

+ (void)showToast:(NSString *)content withImage:(UIImage *)image
{
    void (^block)(void) = ^{
        [self dismissToast];
        
        UIViewController *topViewController = [ACCResponder topViewController];
        UIView *targetView = topViewController.view;
        if (!targetView) {
            targetView = [UIApplication sharedApplication].keyWindow;
        }
        
        UIView *toastView = [[UIView alloc] init];
        toastView.backgroundColor = CAKResourceColor(ACCColorToastDefault);
        toastView.alpha = 1;
        toastView.layer.cornerRadius = 4;
        
        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.textColor = CAKResourceColor(ACCColorTextPrimary);
        textLabel.font = [UIFont acc_systemFontOfSize:14 weight:ACCFontWeightSemibold];
        textLabel.numberOfLines = 0;
        textLabel.textAlignment = NSTextAlignmentLeft;
        textLabel.text = content;
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = image;
        imageView.contentMode = UIViewContentModeCenter;
        
        [toastView addSubview:imageView];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(toastView).offset(8);
            make.centerY.equalTo(toastView);
            make.width.height.mas_equalTo(36);
        }];
        
        [toastView addSubview:textLabel];
        [textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(toastView);
            make.left.equalTo(imageView.mas_right).offset(10);
            make.right.equalTo(toastView.mas_right).offset(-10);
            make.height.greaterThanOrEqualTo(imageView.mas_height);
            make.top.equalTo(toastView).offset(7);
            make.bottom.equalTo(toastView).offset(-7);
        }];
        
        [targetView addSubview:toastView];
        [toastView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(targetView).offset(20);
            make.right.equalTo(targetView).offset(-20);
            make.centerX.equalTo(targetView);
            make.top.equalTo(targetView).priorityMedium().offset(ACC_STATUS_BAR_NORMAL_HEIGHT + 30);
            if (@available(iOS 11.0, *)) {
                make.top.greaterThanOrEqualTo(targetView.mas_safeAreaLayoutGuideTop);
            } else {
                make.top.equalTo(targetView.mas_top).offset(50);
            }
        }];
        
        [toastView.superview layoutSubviews];
        
        toastView.transform = CGAffineTransformMakeTranslation(0, -CGRectGetHeight(toastView.bounds));
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toastView.transform = CGAffineTransformIdentity;
        } completion:nil];
        
        cakActiveToast = toastView;
        cakDismissTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(toastTimeUp:) userInfo:nil repeats:NO];
    };
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}


@end

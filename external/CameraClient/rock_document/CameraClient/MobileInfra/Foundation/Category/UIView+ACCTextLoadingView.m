//
//  UIView+ACCTextLoadingView.m
//  CameraClient-Pods-Aweme
//
//  Created by ZZZ on 2021/9/7.
//

#import "UIView+ACCTextLoadingView.h"
#import <objc/runtime.h>

@interface ACCTextLoadingViewWrapper : NSObject

@property (nonatomic, weak) UIView *target;

@end

@implementation ACCTextLoadingViewWrapper

@end

@implementation UIView (ACCTextLoadingView)

- (void)acc_storeLoadingView:(nullable UIView *)view
{
    const void *key = @selector(acc_storeLoadingView:);
    ACCTextLoadingViewWrapper *obj = [[ACCTextLoadingViewWrapper alloc] init];
    obj.target = view;
    
    objc_setAssociatedObject(self, key, obj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)acc_loadingViewExists
{
    const void *key = @selector(acc_storeLoadingView:);
    ACCTextLoadingViewWrapper *obj = objc_getAssociatedObject(self, key);
    return obj.target.superview != nil;
}

- (BOOL)acc_loadingViewExistsInHierarchy
{
    BOOL ret = NO;
    UIView *view = self;
    while (view) {
        if ([view acc_loadingViewExists]) {
            ret = YES;
            break;
        }
        view = view.superview;
    }
    return ret;
}

@end

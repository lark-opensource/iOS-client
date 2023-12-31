//
//  UIView+Controller.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/3/7.
//

#import "UIView+HMDController.h"

@implementation UIView (HMDController)

- (UIViewController *)hmd_controller {
    __kindof UIResponder *result;
    for(result = self; result != nil; result = result.nextResponder)
        if([result isKindOfClass:UIViewController.class])
            return (__kindof UIViewController *)result;
    return nil;
}

@end

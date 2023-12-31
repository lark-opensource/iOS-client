//
//  LVDToastService.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/24.
//

#import "LVDToastService.h"
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"

@implementation LVDToastService

- (void)show:(NSString *)message {
    [LVDCameraToast showWithMessage:message on: [LVDCameraAlert currentWindow]];
}

- (void)showSuccess:(NSString *)message {
    [LVDCameraToast showSuccessWithMessage:message on: [LVDCameraAlert currentWindow]];
}

- (void)showError:(NSString *)message {
    [LVDCameraToast showFailedWithMessage:message on: [LVDCameraAlert currentWindow]];
}

- (void)show:(NSString *)message onView:(UIView *)view {
    [LVDCameraToast showWithMessage:message on: view];
}

- (void)showError:(NSString *)message onView:(UIView *)view {
    [LVDCameraToast showFailedWithMessage:message on: view];
}

- (void)showSuccess:(NSString *)message onView:(UIView *)view {
    [LVDCameraToast showSuccessWithMessage:message on: view];
}

- (void)showMultiLine:(NSString *)message onView:(UIView *)view {
    [LVDCameraToast showWithMessage:message on: view];
}

#pragma mark -

- (void)showToast:(NSString *)message {
    [LVDCameraToast showWithMessage:message on: [LVDCameraAlert currentWindow]];
}

- (void)dismissToast {
    [LVDCameraToast dismissOn: [LVDCameraAlert currentWindow]];
}


@end

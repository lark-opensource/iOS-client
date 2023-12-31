//
//  LVDEditorLoadingService.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/3/1.
//

#import <UIKit/UIKit.h>
#import "LVDEditorLoadingService.h"
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"
#import "MVPBaseServiceContainer.h"

@implementation LVDEditorLoadingService

- (void)showLoadingOnWindow {
    UIViewController* controller = [MVPBaseServiceContainer sharedContainer].editing;
    if (controller == NULL) {
        return;
    }
    [LVDCameraToast showLoadingWithMessage:@"" on:controller.view];
}

- (void)updateLoadingLabelWithText:(NSString *)text {
    UIViewController* controller = [MVPBaseServiceContainer sharedContainer].editing;
    if (controller == NULL) {
        return;
    }
    [LVDCameraToast showLoadingWithMessage:text on:controller.view];
}

- (void)dismissLoadingOnWindow {
    UIViewController* controller = [MVPBaseServiceContainer sharedContainer].editing;
    if (controller == NULL) {
        return;
    }
    [LVDCameraToast dismissOn:controller.view];
}

@end

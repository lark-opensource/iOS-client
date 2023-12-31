//
//  LVDEditorToastService.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/3/1.
//

#import <UIKit/UIKit.h>
#import "LVDEditorToastService.h"
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"
#import "MVPBaseServiceContainer.h"

@implementation LVDEditorToastService

- (void)show:(NSString *)message {
    UIViewController* controller = [MVPBaseServiceContainer sharedContainer].editing;
    if (controller == NULL) {
        return;
    }
    [LVDCameraToast showWithMessage:message on:controller.view];
}

@end

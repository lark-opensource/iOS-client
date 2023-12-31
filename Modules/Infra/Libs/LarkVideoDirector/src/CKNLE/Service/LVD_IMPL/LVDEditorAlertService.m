//
//  LVDEditorAlertService.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/3/1.
//

#import "LVDEditorAlertService.h"
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"
#import "MVPBaseServiceContainer.h"
#import <UIKit/UIKit.h>

@implementation LVDEditorAlertService

- (void)showAlertWithTitle:(NSString *)title
               description:(NSString *)description
                 leftTitle:(NSString *)leftTitle
                rightTitle:(NSString *)rightTitle
                 leftBlock:(DVEActionBlock _Nullable)leftBlock
                rightBlock:(DVEActionBlock _Nullable)rightBlock {
    UIViewController* controller = [MVPBaseServiceContainer sharedContainer].editing;
    if (controller == NULL) {
        return;
    }
    UIView* view = controller.view;
    [LVDCameraAlert showWithTitle:title description:description leftTitle:leftTitle rightTitle:rightTitle leftBlock:^{
        if (leftBlock != NULL) {
            leftBlock(view);
        }
    } rightBlock:^{
        if (rightBlock != NULL) {
            rightBlock(view);
        }
    } controller:controller];
}

@end

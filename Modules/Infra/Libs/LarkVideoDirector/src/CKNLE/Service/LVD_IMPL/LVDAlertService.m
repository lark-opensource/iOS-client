//
//  LVDAlertService.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/25.
//

#import "LVDAlertService.h"
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"

@implementation LVDAlertService

- (void)showAlertController:(UIAlertController *)alertController animated:(BOOL)animated {
    [LVDCameraAlert showWithAlert:alertController on: [LVDCameraAlert currentWindow]];
}

- (void)showAlertController:(UIAlertController *)alertController fromView:(UIView *)view {
    [LVDCameraAlert showWithAlert:alertController on: view];
}

- (void)showAlertWithTitle:(NSString *)title
               description:(NSString *)description
                     image:(nullable UIImage *)image
         actionButtonTitle:(NSString *)actionButtonTitle
         cancelButtonTitle:(NSString *)cancelButtonTitle
               actionBlock:(void (^_Nullable)(void))actionBlock
               cancelBlock:(void (^_Nullable)(void))cancelBlock {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:description preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* action = [UIAlertAction actionWithTitle:actionButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        actionBlock();
    }];

    UIAlertAction* cancel = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        cancelBlock();
    }];

    [alert addAction:action];
    [alert addAction:cancel];
    [self showAlertController:alert animated:YES];
}

@end

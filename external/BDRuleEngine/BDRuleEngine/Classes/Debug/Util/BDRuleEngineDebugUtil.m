//
//  BDRuleEngineDebugUtil.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/6/6.
//

#import "BDRuleEngineDebugUtil.h"

@implementation BDRuleEngineDebugUtil

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message viewController:(UIViewController *)vc
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defalutAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:defalutAction];
    [vc presentViewController:alertController animated:YES completion:nil];
}

@end

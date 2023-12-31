//
//  BytedCertCorePiperHandler+ViewUtils.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/10.
//

#import "BDCTCorePiperHandler+ViewUtils.h"
#import "BDCTLocalization.h"
#import "UIViewController+BDCTAdditions.h"
#import "UIImage+BDCTAdditions.h"
#import "BDCTInsetImageView.h"
#import "BytedCertManager+Private.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>


@implementation BDCTCorePiperHandler (ViewUtils)

- (void)registerDialogShow {
    [self registeJSBWithName:@"bytedcert.dialogShow" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        int type = [params[@"type"] intValue];

        // TODO: 需要整理下代码
        if (type == 0) {
            NSString *key1 = params[@"key_1"];
            NSString *title = params[@"title"];
            NSString *message = params[@"message"];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action1 = [UIAlertAction actionWithTitle:key1 style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                callback(
                    TTBridgeMsgSuccess, @{@"status_code" : @(0),
                                          @"data" : @{@"key_id" : @(1)}},
                    nil);
            }];
            [alert addAction:action1];
            [[UIViewController bdct_topViewController] presentViewController:alert animated:YES completion:nil];
        } else if (type == 1) {
            NSString *key1 = params[@"key_1"];
            NSString *key2 = params[@"key_2"];
            NSString *title = params[@"title"];
            NSString *message = params[@"message"];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action1 = [UIAlertAction actionWithTitle:key2 style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                callback(
                    TTBridgeMsgSuccess, @{@"status_code" : @(0),
                                          @"data" : @{@"key_id" : @(2)}},
                    nil);
            }];
            UIAlertAction *action2 = [UIAlertAction actionWithTitle:key1 style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                callback(
                    TTBridgeMsgSuccess, @{@"status_code" : @(0),
                                          @"data" : @{@"key_id" : @(1)}},
                    nil);
            }];
            [alert addAction:action1];
            [alert addAction:action2];
            [[UIViewController bdct_topViewController] presentViewController:alert animated:YES completion:nil];
        } else if (type == 2) {
            if (@available(iOS 11.0, *)) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:BytedCertLocalizedString(@"手持身份证示例") message:nil preferredStyle:UIAlertControllerStyleAlert];

                UIImage *img = [UIImage bdct_holdSampleImage];
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 64, 230, 147)];
                imageView.image = img;
                [alert.view addSubview:imageView];

                NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:alert.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:276];
                NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:alert.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:230 + 20 * 2];
                [alert.view addConstraint:height];
                [alert.view addConstraint:width];

                UIAlertAction *action1 = [UIAlertAction actionWithTitle:BytedCertLocalizedString(@"我知道了") style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action){
                }];

                [alert addAction:action1];
                [[UIViewController bdct_topViewController] presentViewController:alert animated:YES completion:nil];
            } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                // 针对 11.0 以下的iOS系统进行处理
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BytedCertLocalizedString(@"手持身份证示例") message:nil
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:BytedCertLocalizedString(@"我知道了"), nil];
                BDCTInsetImageView *imageView = [[BDCTInsetImageView alloc] init];
                [alert setValue:imageView forKey:@"accessoryView"];
                [alert show];
#pragma clang diagnostic pop
            }
        }
    }];
}

- (void)registerShowLoading {
    [self registeJSBWithName:@"bytedcert.showLoading" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        BDCTShowLoadingWithToast([params btd_stringValueForKey:@"message"]);
    }];
}

- (void)registerHideLoading {
    [self registeJSBWithName:@"bytedcert.hideLoading" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        BDCTDismissLoading;
    }];
}

@end

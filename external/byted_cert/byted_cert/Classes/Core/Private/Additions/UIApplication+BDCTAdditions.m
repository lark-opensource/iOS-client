//
//  UIApplication+BDCTAdditions.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2022/2/6.
//

#import "UIApplication+BDCTAdditions.h"
#import "BDCTAdditions.h"
#import "BytedCertManager+Private.h"

#import <AVFoundation/AVCaptureDevice.h>
#import <Photos/PHPhotoLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>
#import <ByteDanceKit/ByteDanceKit.h>


@implementation UIApplication (BDCTAdditions)

+ (void)bdct_requestAlbumPermissionWithSuccessBlock:(void (^)(void))successBlock failBlock:(void (^)(void))failBlock {
    PHAuthorizationStatus statusBeforeRequest = [PHPhotoLibrary authorizationStatus];
    void (^handler)(PHAuthorizationStatus) = ^(PHAuthorizationStatus statusAfterRequest) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ((statusAfterRequest == PHAuthorizationStatusRestricted || statusAfterRequest == PHAuthorizationStatusDenied) && statusBeforeRequest != PHAuthorizationStatusNotDetermined) {
                [BytedCertManager showAlertOnViewController:[UIViewController bdct_topViewController] title:@"无法启动相册" message:@"请到“设置-隐私-相册”开启当前应用访问相册的权限" actions:@[
                    [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeCancel title:@"退出" handler:failBlock],
                    [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeDefault title:@"立即开启" handler:^{
                        [UIApplication bdct_jumpToAppSettingWithCompletion:^{
                            !failBlock ?: failBlock();
                        }];
                    }]
                ]];
            } else {
                if (statusAfterRequest == PHAuthorizationStatusRestricted || statusAfterRequest == PHAuthorizationStatusDenied) {
                    !failBlock ?: failBlock();
                    return;
                }
                btd_dispatch_async_on_main_queue(^{
                    successBlock();
                });
            }
        });
    };
    if ([self respondsToSelector:@selector(bdctbpea_requestAccessForAlbumWithCompletion:)]) {
        [self performSelector:@selector(bdctbpea_requestAccessForAlbumWithCompletion:) withObject:handler];
    } else {
        if (@available(iOS 14.0, *)) {
            [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:handler];
        } else {
            [PHPhotoLibrary requestAuthorization:handler];
        }
    }
}

+ (void)bdct_jumpToAppSettingWithCompletion:(void (^)(void))completion {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self respondsToSelector:@selector(bdctbpea_openURL:)]) {
        [self performSelector:@selector(bdctbpea_openURL:) withObject:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
#pragma clang diagnostic pop
    } else {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        !completion ?: completion();
    });
}

@end

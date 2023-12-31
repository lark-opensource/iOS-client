//
//  AVCaptureDevice+BDCTAdditions.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2022/2/6.
//

#import "AVCaptureDevice+BDCTAdditions.h"
#import "BytedCertManager+Private.h"
#import "BDCTAdditions.h"

#import <ByteDanceKit/ByteDanceKit.h>
#import <AVFoundation/AVFoundation.h>


@implementation AVCaptureDevice (BDCTAdditions)

+ (instancetype)bdct_frontCamera {
    if (@available(iOS 10.0, *)) {
        return [[AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront].devices btd_find:^BOOL(AVCaptureDevice *_Nonnull obj) {
            return obj.position == AVCaptureDevicePositionFront;
        }];
    } else {
        return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] btd_find:^BOOL(AVCaptureDevice *_Nonnull obj) {
            return AVCaptureDevicePositionFront == obj.position;
        }];
    }
}

+ (instancetype)bdct_backCamera {
    if (@available(iOS 10.0, *)) {
        return [[AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack].devices btd_find:^BOOL(AVCaptureDevice *_Nonnull obj) {
            return obj.position == AVCaptureDevicePositionBack;
        }];
    } else {
        return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] btd_find:^BOOL(AVCaptureDevice *_Nonnull obj) {
            return AVCaptureDevicePositionBack == obj.position;
        }];
    }
}


+ (BOOL)bdct_hasCameraPermission {
    return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized;
}

+ (void)bdct_requestAccessForCameraWithSuccessBlock:(void (^)(void))successBlock failBlock:(void (^)(void))failBlock {
    AVAuthorizationStatus authorityBeforeRequest = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    void (^handler)(BOOL) = ^(BOOL granted) {
        AVAuthorizationStatus authorityAfterRequest = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if ((authorityAfterRequest == AVAuthorizationStatusRestricted || authorityAfterRequest == AVAuthorizationStatusDenied) && authorityBeforeRequest != AVAuthorizationStatusNotDetermined) {
            [BytedCertManager showAlertOnViewController:[UIViewController bdct_topViewController] title:@"无法启动相机" message:@"请到“设置-隐私-相机”开启当前应用访问相机的权限" actions:@[
                [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeCancel title:@"退出" handler:failBlock],
                [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeDefault title:@"立即开启" handler:^{
                    [UIApplication bdct_jumpToAppSettingWithCompletion:^{
                        !failBlock ?: failBlock();
                    }];
                }]
            ]];
        } else {
            if (authorityAfterRequest == AVAuthorizationStatusRestricted || authorityAfterRequest == AVAuthorizationStatusDenied) {
                !failBlock ?: failBlock();
                return;
            }
            btd_dispatch_async_on_main_queue(^{
                successBlock();
            });
        }
    };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self respondsToSelector:@selector(bdctbpea_requestAccessForVideoWithCompletion:)]) {
        [self performSelector:@selector(bdctbpea_requestAccessForVideoWithCompletion:) withObject:handler];
    } else {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:handler];
    }
#pragma clang diagnostic pop
}

+ (BOOL)bdct_hasAudioPermission {
    return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] == AVAuthorizationStatusAuthorized;
}

+ (void)bdct_requestAccessForAudioWithSuccessBlock:(void (^)(void))successBlock failBlock:(void (^)(void))failBlock {
    AVAudioSessionRecordPermission permissionBeforeRequest = [AVAudioSession sharedInstance].recordPermission;
    void (^handler)(BOOL) = ^(BOOL granted) {
        AVAudioSessionRecordPermission permissionAfterRequest = [AVAudioSession sharedInstance].recordPermission;
        if (permissionAfterRequest == AVAudioSessionRecordPermissionDenied && permissionBeforeRequest != AVAudioSessionRecordPermissionUndetermined) {
            [BytedCertManager showAlertOnViewController:[UIViewController bdct_topViewController] title:@"无法启动麦克风" message:@"请到“设置-隐私-麦克风”开启当前应用访问麦克风的权限" actions:@[
                [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeCancel title:@"退出" handler:failBlock],
                [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeDefault title:@"立即开启" handler:^{
                    [UIApplication bdct_jumpToAppSettingWithCompletion:^{
                        !failBlock ?: failBlock();
                    }];
                }]
            ]];
        } else {
            if (permissionAfterRequest == AVAudioSessionRecordPermissionDenied) {
                !failBlock ?: failBlock();
                return;
            }
            btd_dispatch_async_on_main_queue(^{
                successBlock();
            });
        }
    };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([AVAudioSession respondsToSelector:@selector(bdctbpea_requestAudioRecordPermissonWithCompletion:)]) {
        [AVAudioSession performSelector:@selector(bdctbpea_requestAudioRecordPermissonWithCompletion:) withObject:handler];
    } else {
        [[AVAudioSession sharedInstance] requestRecordPermission:handler];
    }
#pragma clang diagnostic pop
}

@end

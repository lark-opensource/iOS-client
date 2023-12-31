//
//  BDCTPrivacyAdditions.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2022/2/5.
//

#import "BDCTPrivacyEmbeddedArchitectureAdditions.h"

#import <BDPolicyKit/BDCameraPrivacyCertEntry.h>
#import <BDPolicyKit/BDAppJumpPrivacyCertEntry.h>
#import <BDPolicyKit/BDMicrophonePrivacyCertEntry.h>
#import <BDPolicyKit/BDTokenCert.h>
#import <BDPolicyKit/BDAlbumPrivacyCertEntry.h>


@implementation AVAudioSession (BDCTPrivacyEmbeddedArchitectureAdditions)

+ (void)bdctbpea_requestAudioRecordPermissonWithCompletion:(void (^)(BOOL granted))handler {
    [BDMicrophonePrivacyCertEntry requestRecordPermission:^(BOOL granted, NSError *_Nonnull policyError) {
        !handler ?: handler(granted);
    } audioSession:AVAudioSession.sharedInstance privacyCert:BDTokenCert.create.token(@"bpea-byted_cert_audio_record_request_permission")];
}

@end


@implementation AVCaptureDevice (BDCTPrivacyEmbeddedArchitectureAdditions)

+ (void)bdctbpea_requestAccessForVideoWithCompletion:(void (^)(BOOL granted))handler {
    [BDCameraPrivacyCertEntry requestAccessCameraWithPrivacyCert:BDTokenCert.create.token(@"bpea-byted_cert_video_request_permission") completionHandler:^(BOOL granted, NSError *_Nonnull policyError) {
        !handler ?: handler(granted);
    }];
}

@end


@implementation AVCaptureSession (BDCTPrivacyEmbeddedArchitectureAdditions)

- (void)bdctbpea_startRunning {
    [BDCameraPrivacyCertEntry startRunningWithCaptureSession:self privacyCert:BDTokenCert.create.token(@"bpea-byted_cert_camera_start_running") error:nil];
}

- (void)bdctbpea_stopRunning {
    [BDCameraPrivacyCertEntry stopRunningWithCaptureSession:self privacyCert:BDTokenCert.create.token(@"bpea-byted_cert_camera_stop_running") error:nil];
}

@end


@implementation UIApplication (BDCTPrivacyEmbeddedArchitectureAdditions)

+ (void)bdctbpea_openURL:(NSURL *)URL {
    [BDAppJumpPrivacyCertEntry openURL:URL withCert:BDTokenCert.create.token(@"bpea-byted_cert_app_jump") error:nil];
}

+ (void)bdctbpea_requestAccessForAlbumWithCompletion:(void (^)(PHAuthorizationStatus status))handler {
    BDTokenCert *token = BDTokenCert.create.token(@"bpea-byted_cert_album_request_permission");
    if (@available(iOS 14.0, *)) {
        [BDAlbumPrivacyCertEntry requestAuthorizationForAccessLevel:PHAccessLevelReadWrite
                                                           withCert:token
                                                  completionHandler:^(PHAuthorizationStatus status, NSError *_Nullable policyError) {
                                                      !handler ?: handler(status);
                                                  }];
    } else {
        [BDAlbumPrivacyCertEntry requestAuthorizationWithCert:token completionHandler:^(PHAuthorizationStatus status, NSError *_Nullable policyError) {
            !handler ?: handler(status);
        }];
    }
}


@end

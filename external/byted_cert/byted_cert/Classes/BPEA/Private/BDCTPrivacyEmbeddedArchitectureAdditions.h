//
//  BDCTPrivacyAdditions.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2022/2/5.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/PHPhotoLibrary.h>

NS_ASSUME_NONNULL_BEGIN


@interface AVAudioSession (BDCTPrivacyEmbeddedArchitectureAdditions)

+ (void)bdctbpea_requestAudioRecordPermissonWithCompletion:(void (^)(BOOL granted))handler;

@end


@interface AVCaptureDevice (BDCTPrivacyEmbeddedArchitectureAdditions)

+ (void)bdctbpea_requestAccessForVideoWithCompletion:(void (^)(BOOL granted))handler;

@end


@interface AVCaptureSession (BDCTPrivacyEmbeddedArchitectureAdditions)

- (void)bdctbpea_startRunning;

- (void)bdctbpea_stopRunning;

@end


@interface UIApplication (BDCTPrivacyEmbeddedArchitectureAdditions)

+ (void)bdctbpea_openURL:(NSURL *)URL;

+ (void)bdctbpea_requestAccessForAlbumWithCompletion:(void (^)(PHAuthorizationStatus status))handler;

@end

NS_ASSUME_NONNULL_END

//
//  BDCTBaseCameraViewController.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/17.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "BDCTDisablePanGestureViewController.h"
#import "BytedCertError.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, BDCTBaseCameraRequirePermission) {
    BDCTBaseCameraRequirePermissionVideo = 1,
    BDCTBaseCameraRequirePermissionAudio = BDCTBaseCameraRequirePermissionVideo << 1,
};


@interface BDCTBaseCameraViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, assign, readonly) BDCTBaseCameraRequirePermission requirePermission;

@property (nonatomic, strong, readonly) AVCaptureSession *cameraSession;
@property (nonatomic, assign) BOOL isCameraSessionConfiguring;

- (void)setupCameraSession;

- (void)deviceOrientationDidChange;

- (void)didTapNavBackButton;
- (void)didTapExitForPermissionError:(BytedCertErrorType)errorType;

- (void)applicationWillResignActive NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END

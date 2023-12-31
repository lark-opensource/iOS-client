//
//  ACCCameraControlEvent.h
//  Pods
//
//  Created by haoyipeng on 2020/6/16.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCameraControlEvent <NSObject>

@optional

- (void)currentCameraPositionChanged:(AVCaptureDevicePosition)currentPosition;

- (void)torchModeChanged:(ACCCameraTorchMode)torchMode;
- (void)isTorchEnableChanged:(BOOL)isTorchEnable;

- (void)flashModeChanged:(ACCCameraFlashMode)flashMode;
- (void)isFlashEnableChanged:(BOOL)isFlashEnable;

- (void)onWillManuallyAdjustFocusPoint:(CGPoint)point;
- (void)onDidManuallyAdjustFocusPoint:(CGPoint)point;

- (void)onWillManuallyAdjustExposurePoint:(CGPoint)point;
- (void)onDidManuallyAdjustExposurePoint:(CGPoint)point;

- (void)onWillManuallyAdjustFocusAndExposurePoint:(CGPoint)point;
- (void)onDidManuallyAdjustFocusAndExposurePoint:(CGPoint)point;

- (void)onWillManuallyAdjustExposureBiasWithRatio:(float)ratio;
- (void)onDidManuallyAdjustExposureBiasWithRatio:(float)ratio;

- (void)onWillSwitchToCameraPosition:(AVCaptureDevicePosition)position;
- (void)onDidSwitchToCameraPosition:(AVCaptureDevicePosition)position;

- (void)onDidInitAudioCapture;
- (void)onWillReleaseAudioCapture;
- (void)onDidReleaseAudioCapture;
- (void)onDidStopVideoCapture:(BOOL)success;

@end

NS_ASSUME_NONNULL_END

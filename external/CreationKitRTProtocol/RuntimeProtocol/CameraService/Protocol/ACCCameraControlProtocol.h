//
//  ACCCameraControlProtocol.h
//  Pods
//
//  Created by haoyipeng on 2020/6/11.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "ACCCameraDefine.h"
#import "ACCCameraWrapper.h"
#import "ACCCameraSubscription.h"
#import <TTVideoEditor/VECameraProtocol.h>
#import <TTVideoEditor/HTSGLRotationMode.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCameraTorchProtocol

- (void)turnOn;
- (void)turnOff;

@end

@protocol ACCCameraControlProtocol <ACCCameraWrapper, ACCCameraSubscription>

#pragma mark - camera position
@property (nonatomic, assign, readonly) AVCaptureDevicePosition currentCameraPosition;
@property (nonatomic, assign, readonly) BOOL audioCaptureInitializing;

- (void)switchToCameraPosition:(AVCaptureDevicePosition)position;

- (void)switchToOppositeCameraPosition;
- (void)syncCameraActualPosition;

#pragma mark - flash & torch
@property (nonatomic, assign, readonly) BOOL isFlashEnable;
@property (nonatomic, assign, readonly) ACCCameraFlashMode flashMode;
@property (nonatomic, assign, readonly) BOOL isTorchEnable;
@property (nonatomic, assign, readonly) ACCCameraTorchMode torchMode;
@property (nonatomic, strong, readonly) NSNumber *brightness;


- (void)switchToFlashMode:(ACCCameraFlashMode)flashMode;
- (void)switchToTorchMode:(ACCCameraTorchMode)torch;

- (void)turnOnUniversalTorch;
- (void)turnOffUniversalTorch;
- (void)registerTorch:(id<ACCCameraTorchProtocol>)torch forCamera:(AVCaptureDevicePosition)camera;

- (IESCameraFlashMode)getNextFlashMode;
- (IESCameraFlashMode)getNextTorchMode;

#pragma mark - zoom
@property (nonatomic, assign, readonly) BOOL supprotZoom;
@property (nonatomic, assign, readonly) CGFloat maxZoomFactor;
@property (nonatomic, assign, readonly) CGFloat minZoomFactor;
@property (nonatomic, assign, readonly) CGFloat zoomFactor;

- (void)resetCameraZoomFactor;
- (void)setCameraMaxZoomFactor:(CGFloat)maxFactor;
- (void)changeToZoomFactor:(CGFloat)zoomFactor;
- (BOOL)currentInVirtualCameraMode;

#pragma mark - focus & exposure point
@property (nonatomic, assign, readonly) CGPoint focusPoint;
@property (nonatomic, assign, readonly) CGPoint exposurePoint;
- (void)changeFocusPointTo:(CGPoint)point;
- (void)changeExposurePointTo:(CGPoint)point;
- (void)changeFocusAndExposurePointTo:(CGPoint)point;
- (void)changeExposureBiasWithRatio:(float)ratio;
- (void)resetExposureBias;

- (CGFloat)currentExposureBias;

#pragma mark - ouputsize
@property (nonatomic, assign, readonly) CGSize outputSize;
- (void)changeOutputSize:(CGSize)outputSize;
- (void)setOutputDirection:(UIImageOrientation)orientation;

#pragma mark - ratio
- (void)setPreviewModeType:(IESPreviewModeType)previewModeType;

#pragma mark - start capture
- (void)startVideoAndAudioCapture;
- (void)stopVideoAndAudioCapture;
- (void)startAudioCapture;
- (void)stopAudioCapture;
- (void)startAudioCapture:(NSInteger)tryNumber completeBlock:(void (^)(BOOL ret, NSError *_Nullable retError))completeBlock;
- (void)startVideoCapture;
- (void)stopVideoCapture;
- (void)stopAndReleaseAudioCapture;
- (void)startVideoCaptureIfCheckAppStatus:(BOOL)checkAppStatus;// Contains the old interface to open the video without checking the status of the app
- (void)releaseAudioCapture;

#pragma mark - capture with policy
- (void)startAudioCaptureWithPrivacyCert:(nullable  id)token;
- (void)startAudioCapture:(void (^_Nullable)(BOOL isSuccess, NSError *_Nullable error))completeBlock withPrivacyCert:(nullable id)token;
- (void)stopAudioCaptureWithPrivacyCert:(nullable  id)token;

- (void)startVideoCaptureWithPrivacyCert:(nullable id)token;
- (void)startVideoCaptureWithAppStatusCheckWithPrivacyCert:(nullable id)token;
- (void)stopVideoCaptureWithPrivacyCert:(nullable id)token;

#pragma mark -
- (void)resumeCameraCapture; // Pause rendering
- (void)pauseCameraCapture; // Restore rendering
- (void)removeHTSGLPreview; // Release htsglpreview in case of non recorded page memory warning
- (void)resumeHTSGLPreviewWithView:(UIView *)view; // Active removal of htsglpreview when recovering non recorded page memory warning

#pragma mark -
- (NSString *)cameraZoomSupportedInfo;
- (NSInteger)status;
- (void)initAudioCapture:(dispatch_block_t)completion;
- (BOOL)isAudioCaptureRuning;
- (void)cancelVideoRecord;
- (CGSize)captureSize;
- (UIView *)previewView;
- (void)setRearPreferredStabilizationMode:(AVCaptureVideoStabilizationMode)rearPreferredStabilizationMode;
- (void)setFrontPreferredStabilizationMode:(AVCaptureVideoStabilizationMode)frontPreferredStabilizationMode;
- (void)preferredCameraType:(NSInteger)IESCameraType;
- (void)notNeedAutoStartAudioCapture:(BOOL)notNeedAutoStartAudioCapture;
//- (void)propertySet:(IESMMARWorldTrackingPropertySet *)propertySet API_AVAILABLE(ios(11.0));
- (void)ignoreNotification:(BOOL)ignoreStatus;
- (BOOL)getIgnoreNotificatio;
- (IESMMCaptureRatio)currenCaptureRatio;
- (void)resetCapturePreferredSize:(CGSize)size then:(void (^_Nullable)(void))then;
- (void)resetCaptureRatio:(IESMMCaptureRatio)ratio then:(void (^_Nullable)(void))then;
- (void)setBGVideoAutoRepeat:(BOOL)autoRepeat;
- (void)resetPreferredFrameRate:(NSUInteger)frameRate;

#pragma mark - handle
- (BOOL)handleTouchUp:(CGPoint)location withType:(IESMMGestureType)type;
- (BOOL)handleTouchDown:(CGPoint)location withType:(IESMMGestureType)type;
- (BOOL)handleLongPressEventWithLocation:(CGPoint)location;
- (BOOL)handlePanEventWithTranslation:(CGPoint)translation location:(CGPoint)location;
- (BOOL)handleScaleEvent:(CGFloat)scale;
- (BOOL)handleRotationEvent:(CGFloat)rotation;
- (BOOL)handleTouchEvent:(CGPoint)location;
- (BOOL)handleDoubleClickEvent:(CGPoint)location;

#pragma mark - dirty lens detection
- (void)runDirtyCameraDetectAlgorithmWithCompletion:(VECameraLensResultBlock)completion;

#pragma mark - PureMode
- (void)setPureCameraMode:(BOOL)mode;

#pragma mark - capture frame

- (void)captureFrameWhenStopCaptre:(nullable void(^)(BOOL success))completion;
- (void)clearCaptureFrame;
- (UIImage *)captureFrame;

@optional
#pragma mark - landscape
- (void)enableHorizontalScreenMode:(HTSGLRotationMode)outputRotation resetRotation:(HTSGLRotationMode)resetRotation;

@end

NS_ASSUME_NONNULL_END

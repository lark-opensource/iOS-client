//
//  ACCCameraAction.h
//  CameraClient
//
//  Created by leo on 2019/12/12.
//

#import <AVFoundation/AVFoundation.h>
#import <CreationKitRTProtocol/ACCCameraDefine.h>
#import <CameraClient/ACCAction.h>
#import "ACCCameraState.h"
#import "ACCRatioActionData.h"
#import "ACCWideAngleActionData.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, ACCCameraActionType) {
    ACCCameraActionTypeChangeNoOp,
    ACCCameraActionTypeInit,
    ACCCameraActionTypeSwitchCamera,
    ACCCameraActionTypeChangePosition,
    ACCCameraActionTypeChangeFlashEnable,
    ACCCameraActionTypeChangeFlashMode,
    ACCCameraActionTypeChangeTorchEnable,
    ACCCameraActionTypeChangeTorchMode,
    ACCCameraActionTypeChangeRatio,
    ACCCameraActionTypeCameraSessionState,
    ACCCameraActionTypeChangeZoom,
    ACCCameraActionTypeChangeWideAngle,
    ACCCameraActionTypeUpdateDeviceType,
    ACCCameraActionTypeChangeMaxZoom,
    ACCCameraActionTypeChangeVideoData,
    ACCCameraActionTypeTapFocus,
    ACCCameraActionTypeTapExposure,
    ACCCameraActionTypeStartVideo,
    ACCCameraActionTypeStartAudio,
    ACCCameraActionTypeStopVideo,
    ACCCameraActionTypeStopAudio,
    ACCCameraActionTypeResetView,
    ACCCameraActionTypeChangeOutpusSize,
    ACCCameraActionTypeChangePreviewType,
    ACCCameraActionTypeRemoveGLPreview,
    ACCCameraActionTypeResumeGLPreview,
};

typedef NS_ENUM(int, ACCCameraInitActionType)
{
    ACCCameraInitActionTypeZoom = 100,
    ACCCameraInitActionTypeFirstRender,
    ACCCameraInitActionTypeMaxZoomFactor,
};

@interface ACCCameraAction : ACCAction
@property (nonatomic, nullable) AVCaptureSessionPreset preferPreset;
@property (nonatomic, strong) id payload;
@end

@interface ACCCameraAction (Create)

#pragma mark - init

+ (instancetype)cameraInitActionWithState:(ACCCameraState *)state;

#pragma mark - Camera Session
+ (instancetype)startVideoAction;
+ (instancetype)startAudioAction;
+ (instancetype)stopVideoAction;
+ (instancetype)stopAudioAction;
+ (instancetype)pauseCameraAction;
+ (instancetype)resumeCameraAction;

#pragma mark - Camera Switch
+ (instancetype)switchAction;
+ (instancetype)switchCameraToPosition: (AVCaptureDevicePosition)position;

#pragma mark - Ratio
+ (instancetype)switchRatioWithData:(ACCRatioActionData *)ratio;

#pragma mark - Flash
+ (instancetype)switchFlash:(ACCCameraFlashMode)mode;
+ (instancetype)changeFlashEnable:(BOOL)flashEnable;

#pragma mark - Torch
+ (instancetype)switchTorch:(ACCCameraTorchMode)mode;
+ (instancetype)changeTorchEnable:(BOOL)torchEnable;

#pragma mark - Focus
+ (instancetype)tapFocusAtPoint:(CGPoint)point;               //内部会做归一，直接传屏幕point
+ (instancetype)tapExposureAtPoint:(CGPoint)point;            //内部会做归一，直接传屏幕point

#pragma mark - Zoom
+ (instancetype)changeZoomScale:(CGFloat)zoomScale;    //线性增长
+ (instancetype)setMaxZoomFactor:(CGFloat)maxZoomFactor;     // 2的几次方
+ (instancetype)changeWideAngle:(ACCWideAngleActionData *)angleData;
+ (instancetype)changeMaxZoom:(CGFloat)zoomFactor;

#pragma mark - View
+ (instancetype)resetPreviewView:(UIView *)view;

#pragma mark - Output Size
+ (instancetype)resetOutputSize:(CGSize)outputSize;

#pragma mark - Preview Type
+ (instancetype)changePreviewTypeAction:(IESMMCameraPreviewType)previewType;

#pragma mark - CameraDevice
+ (instancetype)updateCurrentDevice:(AVCaptureDeviceType)deviceType API_AVAILABLE(ios(10.0));

#pragma mark - VideoData
+ (instancetype)updateVideoData:(HTSVideoData *)videoData;

#pragma mark - Release GL Preview
+ (instancetype)removeGLPreviewAction;
+ (instancetype)resumeGLPreviewActionWithView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END

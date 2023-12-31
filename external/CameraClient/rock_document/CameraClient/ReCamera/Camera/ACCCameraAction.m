//
//  ACCCameraAction.m
//  CameraClient
//
//  Created by leo on 2019/12/12.
//

#import "ACCCameraAction.h"

@implementation ACCCameraAction

@end

@implementation ACCCameraAction (Create)

#pragma mark - Camera Init

+ (instancetype)cameraInitActionWithState:(ACCCameraState *)state
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeInit;
    action.payload = state;
    return action;
}

#pragma mark - Camera Session
+ (instancetype)startVideoAction
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeStartVideo;
    return action;
}

+ (instancetype)startAudioAction
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeStartAudio;
    return action;
}

+ (instancetype)stopVideoAction
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeStopVideo;
    return action;
}

+ (instancetype)stopAudioAction
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeStopAudio;
    return action;
}

+ (instancetype)pauseCameraAction
{
    return [self _cameraSesstionActionWithState:ACCCameraSessionStatePause];
}

+ (instancetype)resumeCameraAction
{
    return [self _cameraSesstionActionWithState:ACCCameraSessionStateResume];
}
    
+ (instancetype)_cameraSesstionActionWithState:(ACCCameraSessionState)state
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeCameraSessionState;
    action.payload = @(state);
    return action;
}

#pragma mark - Camera Switch
+ (instancetype)switchAction
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeSwitchCamera;
    return action;
}

+ (instancetype)switchCameraToPosition: (AVCaptureDevicePosition)position
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangePosition;
    action.payload = @(position);
    
    return action;
}

#pragma mark - Ratio
+ (instancetype)switchRatioWithData:(ACCRatioActionData *)ratio
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeRatio;
    action.payload = ratio;
    return action;
}

#pragma mark - Flash
+ (instancetype)switchFlash:(ACCCameraFlashMode)mode
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeFlashMode;
    action.payload = @(mode);
    return action;
}

+ (instancetype)changeFlashEnable:(BOOL)flashEnable
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeFlashEnable;
    action.payload = @(flashEnable);
    return action;
}

#pragma mark - torch
+ (instancetype)switchTorch:(ACCCameraTorchMode)mode
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeTorchMode;
    action.payload = @(mode);
    return action;
}

+ (instancetype)changeTorchEnable:(BOOL)torchEnable
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeTorchEnable;
    action.payload = @(torchEnable);
    return action;
}

#pragma mark - focus

+ (instancetype)tapFocusAtPoint:(CGPoint)point
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeTapFocus;
    action.payload = @(point);
    return action;
}

+ (instancetype)tapExposureAtPoint:(CGPoint)point
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeTapExposure;
    action.payload = @(point);
    return action;
}

+ (instancetype)focusAtPoint:(CGPoint)point {
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeTapFocus;
    action.payload = @(point);
    return action;
}

+ (instancetype)exposureAtPoint:(CGPoint)point {
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeTapExposure;
    action.payload = @(point);
    return action;
}

#pragma mark - zoom

+ (instancetype)changeWideAngle:(ACCWideAngleActionData *)angleData {
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeWideAngle;
    action.payload = angleData;
    return action;
}

+ (instancetype)changeMaxZoom:(CGFloat)zoomFactor {
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeMaxZoom;
    action.payload = @(zoomFactor);
    return action;
}

#pragma mark - CameraDevice

+ (instancetype)updateCurrentDevice:(AVCaptureDeviceType)deviceType API_AVAILABLE(ios(10.0)) {
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeUpdateDeviceType;
    action.payload = deviceType;
    return action;
}

#pragma mark - VideoData

+ (instancetype)updateVideoData:(HTSVideoData *)videoData {
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeVideoData;
    action.payload = videoData;
    return action;
}

+ (instancetype)changeZoomScale:(CGFloat)zoomScale
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeZoom;
    action.payload = @(zoomScale);
    return action;
}

+ (instancetype)setMaxZoomFactor:(CGFloat)maxZoomFactor
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraInitActionTypeMaxZoomFactor;
    action.payload = @(maxZoomFactor);
    return action;
}

#pragma mark - View

+ (instancetype)resetPreviewView:(UIView *)view
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeResetView;
    action.payload = view;
    return action;
}

#pragma mark - Output Size
+ (instancetype)resetOutputSize:(CGSize)outputSize
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeOutpusSize;
    action.payload = [NSValue valueWithCGSize:outputSize];
    return action;
}

#pragma mark - Preview Type
+ (instancetype)changePreviewTypeAction:(IESMMCameraPreviewType)previewType
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangePreviewType;
    action.payload = @(previewType);
    return action;
}

#pragma mark - Release GL Preview
+ (instancetype)removeGLPreviewAction
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeRemoveGLPreview;
    return action;
}

+ (instancetype)resumeGLPreviewActionWithView:(UIView *)view
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeRemoveGLPreview;
    return action;
}

@end

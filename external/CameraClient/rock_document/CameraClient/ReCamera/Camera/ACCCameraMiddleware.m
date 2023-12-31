//
//  ACCCameraMiddleware.m
//  CameraClient
//
//  Created by leo on 2019/12/12.
//

#import "ACCCameraMiddleware.h"
#import "ACCCameraAction.h"
#import <CreativeKit/ACCMacros.h>

#import <TTVideoEditor/IESMMCamera_private.h>
#import <CameraClient/ACCReduxModule.h>
#import <AVFoundation/AVCaptureSessionPreset.h>

@interface ACCCameraMiddleware ()
@property (nonatomic, assign) BOOL isSwapCamera;
@end

@implementation ACCCameraMiddleware
+ (instancetype)middlewareWithCamera:(IESMMCamera<IESMMRecoderProtocol> *)camera
{
    ACCCameraMiddleware *middleware = [ACCCameraMiddleware middleware];
    middleware.camera = camera;
    [middleware bindCamera];
    return middleware;
}

- (void)bindCamera
{
    void (^actionBlock)(IESCameraAction, NSError *_Nullable, id _Nullable) = self.camera.IESCameraActionBlock;
    @weakify(self);
    [self.camera setIESCameraActionBlock:^(IESCameraAction action, NSError * _Nullable error, id  _Nullable data) {
        @strongify(self);
        ACCBLOCK_INVOKE(actionBlock, action, error, data);
        
        ACCResult *result = nil;
        if (error) {
            result = [ACCResult failure:error];
        } else {
            result = [ACCResult success:data];
        }
        switch (action) {
            case IESCameraDidStartVideoCapture: {
                ACCCameraAction *action = [ACCCameraAction startVideoAction];
                action.payload = result;
                [action fulfill];
                [self dispatch:action];
                break;
            }
            case IESCameraDidStartAudioCapture: {
                ACCCameraAction *action = [ACCCameraAction startAudioAction];
                action.payload = result;
                [action fulfill];
                [self dispatch:action];
                break;
            }
            case IESCameraDidStopVideoCapture: {
                ACCCameraAction *action = [ACCCameraAction stopVideoAction];
                action.payload = result;
                [action fulfill];
                [self dispatch:action];
                break;
            }
            case IESCameraDidFocusComplete: {
                CGPoint focuspoint;
                [data getValue:&focuspoint];
                ACCCameraAction *action = [ACCCameraAction tapFocusAtPoint:focuspoint];
                [action fulfill];
                [self dispatch:action];
                break;
            }
            case IESCameraDidFirstFrameRender: {
                ACCCameraAction *action = [ACCCameraAction action];
                action.type = ACCCameraInitActionTypeFirstRender;
                action.payload = @(YES);
                [action fulfill];
                [self dispatch:action];
                break;
            }
            default:
                break;
        }
    }];
    
    [self.camera setFirstRenderBlock:^{
        @strongify(self);
        ACCCameraAction *action = [ACCCameraAction action];
        action.type = ACCCameraInitActionTypeFirstRender;
        action.payload = @(YES);
        [action fulfill];
        [self dispatch:action];
    }];
}

#pragma mark - action handle

- (BOOL)shouldHandleAction:(ACCAction *)action
{
    return [action isKindOfClass:[ACCCameraAction class]] || [action isKindOfClass:[ACCReduxModuleAction class]];
}

- (ACCAction *)handleAction:(ACCAction *)action next:(nonnull ACCActionHandler)next
{
    if (self.camera) {
        if ([action isKindOfClass:[ACCCameraAction class]]) {
            [self handleCameraAction:(ACCCameraAction *)action];
        } else if ([action isKindOfClass:[ACCReduxModuleAction class]]) {
            [self handleModuleAction:(ACCReduxModuleAction *)action];
        }
    }
    return next(action);
}

- (ACCAction *)handleModuleAction:(ACCReduxModuleAction *)action
{
    switch (action.type) {
        case ACCReduxModuleActionTypeSeed:{

            ACCCameraState *cameraState = [[ACCCameraState alloc] init];
            cameraState.supportZoom = [self.camera isCameraCapabilitySupported:IESMMCameraCapabilityZoom];
            cameraState.devicePosition = self.camera.currentCameraPosition;
            cameraState.isFlashEnable = self.camera.isFlashEnable;
            cameraState.flashMode = self.camera.cameraFlashMode;
            cameraState.isTorchEnable = [self.camera isCameraCapabilitySupported:IESMMCameraCapabilityTorch];
            cameraState.torchMode = self.camera.torchOn ? ACCCameraTorchModeOn : ACCCameraTorchModeOff;
            cameraState.zoomScale = self.camera.currentCameraZoomFactor;
            cameraState.supportZoom = [self.camera isCameraCapabilitySupported:IESMMCameraCapabilityZoom];
            cameraState.focusPoint = self.camera.focusPoint;
            cameraState.exposurePoint = self.camera.exposurePoint;
            cameraState.ratio = self.camera.captureRatio;

            ACCCameraAction *initAction = [ACCCameraAction cameraInitActionWithState:cameraState];
            [initAction fulfill];
            [self dispatch:initAction];
            break;
        }
        default:
            break;
    }
    return action;
}

- (ACCAction *)handleCameraAction:(ACCCameraAction *)action
{
    if (action.status == ACCActionStatusPending) {
        switch (action.type) {
            case ACCCameraActionTypeStartVideo: {
                [self startVideoCapture];
                break;
            }
            case ACCCameraActionTypeStartAudio: {
                [self startAudioCapture];
                break;
            }
            case ACCCameraActionTypeStopVideo: {
                [self stopVideoCapture];
                break;
            }
            case ACCCameraActionTypeStopAudio: {
                [self stopAudioCapture];
                break;
            }
            case ACCCameraActionTypeCameraSessionState: {
                [self updateCamerarecorderState:(ACCCameraSessionState)[action.payload unsignedIntegerValue]];
                break;
            }
            case ACCCameraActionTypeSwitchCamera: {
                [self switchCamera];
                break;
            }
            case ACCCameraActionTypeChangePosition: {
                AVCaptureDevicePosition position = (AVCaptureDevicePosition)[action.payload integerValue];
                if (_camera.currentCameraPosition == position) {
                    [action fulfill];
                } else {
                    [self switchCamera];
                }
                
                break;
            }
            case ACCCameraActionTypeChangeFlashEnable: {
                [self updateFlashEnable];
                break;
            }
            case ACCCameraActionTypeChangeFlashMode: {
                [self updateFlashEnable];
                [self switchFlashMode:(ACCCameraFlashMode)[action.payload unsignedIntegerValue]];
                break;
            }
            case ACCCameraActionTypeChangeTorchEnable: {
                [self updateTorchEnable];
                break;
            }
            case ACCCameraActionTypeChangeTorchMode: {
                [self updateTorchEnable];
                [self switchTorchMode:(ACCCameraTorchMode)[action.payload unsignedIntegerValue]];
                break;
            }
            case ACCCameraActionTypeChangeRatio: {
                [self changeFrameRatio:(IESMMCaptureRatio)[action.payload integerValue] preferredPreset:action.preferPreset];
                break;
            }
            case ACCCameraActionTypeTapFocus: {
                [self tapFocusAtPoint:[action.payload CGPointValue]];
                break;
            }
            case ACCCameraActionTypeTapExposure: {
                [self tapExposureAtPoint:[action.payload CGPointValue]];
                break;
            }
            case ACCCameraActionTypeChangeZoom: {
                [self changeZoom:[action.payload doubleValue]];
                break;
            }
            case ACCCameraActionTypeResetView: {
                [self resetPreviewView:(UIView *)action.payload];
                break;
            }
            case ACCCameraActionTypeChangeMaxZoom: {
                [self changeMaxZoom:[action.payload floatValue]];
                break;
            }
            case ACCCameraActionTypeChangeOutpusSize: {
                [self resetOutputSize:[action.payload CGSizeValue]];
                break;
            }
            case ACCCameraActionTypeChangePreviewType: {
                [self changeCameraPreviewType:[action.payload integerValue]];
                break;
            }
            case ACCCameraActionTypeRemoveGLPreview: {
                [self removeGLPreview];
                break;
            }
            case ACCCameraActionTypeResumeGLPreview: {
                [self resumeGLPreviewWithView:action.payload];
                break;
            }
            default: {
                NSAssert(NO, @"Wrong action type, you shall not reach this case!");
                break;
            }
        }
    }
    
    return action;
}

#pragma mark - Camera Session
- (void)updateCamerarecorderState:(ACCCameraSessionState)recorderState
{
    switch (recorderState) {
        case ACCCameraSessionStatePause:
            [self.camera pauseCameraCapture];
            break;
        case ACCCameraSessionStateResume:
            [self.camera resumeCameraCapture];
            break;
        default:
            break;
    }
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeCameraSessionState;
    [action fulfill];
    action.payload = @(recorderState);
    [self dispatch:action];
}

#pragma mark - switch camera
- (void)switchCamera
{
    self.isSwapCamera = YES;
    if ([self camera].status == HTSCameraStatusIdle || [self camera].status == HTSCameraStatusStopped) {
        
        @weakify(self);
        [self.camera setFirstRenderBlock:^{
            @strongify(self);
            
            if (self.isSwapCamera) {
                [self dispatchCameraSwitchedAction];
                [self dispatchCameraFlashEnableAction];
                [self dispatchCameraTorchEnableAction];
                [self dispatch:[ACCCameraAction switchFlash:ACCCameraFlashModeOff]];
                [self dispatch:[ACCCameraAction switchTorch:ACCCameraTorchModeOff]];
            }
            
            self.isSwapCamera = NO;
        }];
        [[self camera] switchCameraSource];
    }
}

- (void)startVideoCapture
{
    if (self.camera.status != IESMMCameraStatusStopped) {
        return;
    }
    [self.camera startVideoCapture];
}

- (void)startAudioCapture
{
    [self.camera startAudioCapture];
}

- (void)stopVideoCapture
{
    if (self.camera.status == IESMMCameraStatusStopped) {
        return;
    }
    [self.camera stopVideoCapture];
}

- (void)stopAudioCapture
{
    [self.camera stopAudioCapture];
}

- (void)dispatchCameraSwitchedAction
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangePosition;
    [action fulfill];
    
    action.payload = @(self.camera.currentCameraPosition);
    
    [self dispatch:action];
}

#pragma mark - change torch enable

- (void)updateFlashEnable
{
    BOOL isFlashEnabled = [self.camera isCameraCapabilitySupported:IESMMCameraCapabilityFlash];
    isFlashEnabled = self.disableFlashOnFrontPosition ? isFlashEnabled && [_camera currentCameraPosition] == AVCaptureDevicePositionBack : isFlashEnabled;
    ACCCameraAction *action = [ACCCameraAction changeFlashEnable:isFlashEnabled];
    [action fulfill];
    [self dispatch:action];
}

- (void)dispatchCameraFlashEnableAction
{
    ACCCameraAction *action = [ACCCameraAction changeFlashEnable:[self.camera isCameraCapabilitySupported:IESMMCameraCapabilityFlash]];
    [self dispatch:action];
}

#pragma mark - change flash mode

- (void)switchFlashMode:(ACCCameraFlashMode)flashMode
{
    if ([self.camera isCameraCapabilitySupported:IESMMCameraCapabilityFlash]) {
        [self.camera setCameraFlashMode:(IESCameraFlashMode)flashMode];
        [self dispatchChangeCameraFlashModeAction];
    }
}

- (void)dispatchChangeCameraFlashModeAction
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeFlashMode;
    [action fulfill];
    action.payload = @(self.camera.cameraFlashMode);
    
    [self dispatch:action];
}

#pragma mark - change torch mode

- (void)switchTorchMode:(ACCCameraTorchMode)torchMode
{
    if ([self.camera isCameraCapabilitySupported:IESMMCameraCapabilityTorch] &&
        torchMode != ACCCameraTorchModeAuto) {
        [self.camera setTorchOn:torchMode == ACCCameraTorchModeOn];
        [self dispatchChangeCameraTorchModeAction];
    }
}

- (void)dispatchChangeCameraTorchModeAction
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeTorchMode;
    [action fulfill];
    action.payload = @(self.camera.torchOn ? ACCCameraTorchModeOn : ACCCameraTorchModeOff);
    
    [self dispatch:action];
}

#pragma mark - change torch enable

- (void)updateTorchEnable
{
    ACCCameraAction *action = [ACCCameraAction changeTorchEnable:[self.camera isCameraCapabilitySupported:IESMMCameraCapabilityTorch]];
    [action fulfill];
    [self dispatch:action];
}

- (void)dispatchCameraTorchEnableAction
{
    ACCCameraAction *action = [ACCCameraAction changeTorchEnable:[self.camera isCameraCapabilitySupported:IESMMCameraCapabilityTorch]];
    [self dispatch:action];
}

#pragma mark - change frame ratio

- (void)changeFrameRatio:(IESMMCaptureRatio)frameRatio preferredPreset:(AVCaptureSessionPreset)preset
{
    @weakify(self);
    [self.camera resetCaptureRatio:frameRatio preferredPreset:preset then:^{
        @strongify(self);
        [self dispatchChangeRatioAction];
    }];
}

- (void)dispatchChangeRatioAction
{
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeRatio;
    [action fulfill];
    action.payload = @(self.camera.captureRatio);
    [self dispatch:action];
}

#pragma mark - focus

- (void)tapFocusAtPoint:(CGPoint)point
{
    CGPoint pointInCaptureView = CGPointApplyAffineTransform(point, CGAffineTransformMakeScale(self.camera.previewContainer.bounds.size.width / [UIScreen mainScreen].bounds.size.width  , self.camera.previewContainer.bounds.size.height / [UIScreen mainScreen].bounds.size.height));
    CGPoint pointInOne = CGPointApplyAffineTransform(pointInCaptureView, CGAffineTransformMakeScale(1 / self.camera.previewContainer.bounds.size.width, 1 / self.camera.previewContainer.bounds.size.height));
    [self.camera tapFocusAtPoint:pointInOne];
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeTapFocus;
    [action fulfill];
    action.payload = @(pointInOne);
    [self dispatch:action];
}
- (void)tapExposureAtPoint:(CGPoint)point
{
    CGPoint pointInCaptureView = CGPointApplyAffineTransform(point, CGAffineTransformMakeScale(self.camera.previewContainer.bounds.size.width / [UIScreen mainScreen].bounds.size.width  , self.camera.previewContainer.bounds.size.height / [UIScreen mainScreen].bounds.size.height));
    CGPoint pointInOne = CGPointApplyAffineTransform(pointInCaptureView, CGAffineTransformMakeScale(1 / self.camera.previewContainer.bounds.size.width, 1 / self.camera.previewContainer.bounds.size.height));
    [self.camera tapExposureAtPoint:pointInOne];
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeTapExposure;
    [action fulfill];
    action.payload = @(pointInOne);
    [self dispatch:action];
}

#pragma mark - Zoom

- (void)changeZoom:(CGFloat)scale
{
    if (![self.camera isCameraCapabilitySupported:IESMMCameraCapabilityZoom]) {
        return;
    }
    CGFloat minScale = 1.0;
    CGFloat maxZoomFactor = _camera.maxCameraZoomFactor;
    if (scale >= minScale && scale <= maxZoomFactor) {
        [_camera cameraSetZoomFactor:scale];
        [self dispatchCameraDidZoomTo:scale];
    }
}

- (void)dispatchCameraDidZoomTo:(CGFloat)zoomFactor {
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeZoom;
    [action fulfill];
    action.payload = @(zoomFactor);
    
    [self dispatch:action];
}

- (void)changeMaxZoom:(CGFloat)zoomFactor {
    if (![_camera isCameraCapabilitySupported:IESMMCameraCapabilityZoom]) {
        return;
    }
    [_camera setMaxZoomFactor:zoomFactor];
}

#pragma mark - Preview View

- (void)resetPreviewView:(UIView *)view
{
    UIView *resetView = [self.camera resetPreviewView:view];
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeResetView;
    action.payload = resetView;
    [action fulfill];
    [self dispatch:action];
}

#pragma mark - Output Size
- (void)resetOutputSize:(CGSize)size
{
    [self.camera resetOutputSize:size];
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangeOutpusSize;
    action.payload = [NSValue valueWithCGSize:size];
    [action fulfill];
    [self dispatch:action];
}

#pragma mark - Preview Type
- (void)changeCameraPreviewType:(IESMMCameraPreviewType)previewType
{
    [self.camera resetPreviewType:previewType];
    ACCCameraAction *action = [ACCCameraAction action];
    action.type = ACCCameraActionTypeChangePreviewType;
    action.payload = @(previewType);
    [action fulfill];
    [self dispatch:action];
}

#pragma mark - Release GL Preview
- (void)removeGLPreview
{
    [self.camera removeHTSGLPreview];
}

- (void)resumeGLPreviewWithView:(UIView *)view
{
    [self.camera resumeHTSGLPreview:view];
}

@end

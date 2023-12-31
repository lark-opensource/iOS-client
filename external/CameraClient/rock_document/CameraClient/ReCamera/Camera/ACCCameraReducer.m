//
//  ACCCameraReducer.m
//  Pods
//
//  Created by leo on 2019/12/12.
//

#import "ACCCameraReducer.h"
#import "ACCCameraAction.h"

@implementation ACCCameraReducer
- (ACCCameraState *)stateWithAction:(ACCCameraAction *)action andState:(ACCCameraState *)state;
{
    NSAssert([state isKindOfClass:[ACCCameraState class]], @"invalid state type");
    if (![action isKindOfClass:[ACCCameraAction class]]) {
        return state;
    }
    if (action.status == ACCActionStatusSucceeded) {
        ACCCameraState *updatedState = [[ACCCameraState alloc] init];
        [updatedState mergeValuesForKeysFromModel:state];
        switch (action.type) {
            case ACCCameraActionTypeInit: {
                if ([action.payload isKindOfClass:ACCCameraState.class]) {
                    updatedState = [[ACCCameraState alloc] init];
                    [updatedState mergeValuesForKeysFromModel:(ACCCameraState *)action.payload];
                }
                break;
            }
            case ACCCameraActionTypeStartVideo: {
                if ([action.payload isKindOfClass:ACCResult.class]) {
                    updatedState.startVideoCaptureResult = (ACCResult *)action.payload;
                }
                break;
            }
            case ACCCameraActionTypeStartAudio: {
                if ([action.payload isKindOfClass:ACCResult.class]) {
                    updatedState.startAudioCaptureResult = (ACCResult *)action.payload;
                }
                break;
            }
            case ACCCameraActionTypeStopVideo: {
                if ([action.payload isKindOfClass:ACCResult.class]) {
                    updatedState.stopVideoCaptureResult = (ACCResult *)action.payload;
                }
                break;
            }
            case ACCCameraActionTypeCameraSessionState: {
                updatedState.sessionState = [action.payload unsignedIntegerValue];
                break;
            }
            case ACCCameraActionTypeChangePosition: {
                if (state.devicePosition == [action.payload integerValue]) {
                    return state;
                }
                updatedState.devicePosition = [action.payload integerValue];
                break;
            }
            case ACCCameraActionTypeChangeFlashMode: {
                ACCCameraFlashMode newFlashMode = (ACCCameraFlashMode)[action.payload unsignedIntegerValue];
                if (state.flashMode == newFlashMode) {
                    return state;
                }
                updatedState.flashMode = newFlashMode;
                break;
            }
            case ACCCameraActionTypeChangeFlashEnable: {
                BOOL newFlashEnable = (ACCCameraFlashMode)[action.payload boolValue];
                if (state.isFlashEnable == newFlashEnable) {
                    return state;
                }
                updatedState.isFlashEnable = newFlashEnable;
                break;
            }
            case ACCCameraActionTypeChangeTorchMode: {
                ACCCameraTorchMode newTorchMode = (ACCCameraTorchMode)[action.payload unsignedIntegerValue];
                if (state.torchMode == newTorchMode) {
                    return state;
                }
                updatedState.torchMode = newTorchMode;
                break;
            }
            case ACCCameraActionTypeChangeTorchEnable: {
                BOOL newTorchEnable = (ACCCameraTorchMode)[action.payload boolValue];
                if (state.isTorchEnable == newTorchEnable) {
                    return state;
                }
                updatedState.isTorchEnable = newTorchEnable;
                break;
            }
            case ACCCameraActionTypeChangeRatio: {
                if ([action.payload isKindOfClass:[NSNumber class]]) {
                    updatedState.ratio = (IESMMCaptureRatio)[action.payload integerValue];
                } else {
                    return state;
                }
                break;
            }
            case ACCCameraActionTypeUpdateDeviceType: {
                if (@available(iOS 10.0, *)) {
                    updatedState.deviceType = (AVCaptureDeviceType)action.payload;
                }
                break;
            }
            case ACCCameraActionTypeChangeMaxZoom: {
                updatedState.maxZoomFactor = [action.payload floatValue];
                break;
            }
            case ACCCameraActionTypeTapFocus: {
                if ([action.payload isKindOfClass:[NSValue class]]) {
                    updatedState.focusPoint = [action.payload CGPointValue];
                } else {
                    return state;
                }
                break;
            }
            case ACCCameraActionTypeTapExposure: {
                if ([action.payload isKindOfClass:[NSValue class]]) {
                    updatedState.exposurePoint = [action.payload CGPointValue];
                } else {
                    return state;
                }
                break;
            }
            case ACCCameraActionTypeChangeZoom: {
                if ([action.payload isKindOfClass:[NSNumber class]]) {
                    updatedState.zoomScale = [action.payload doubleValue];
                } else {
                    return state;
                }
                break;
            }
            case ACCCameraInitActionTypeZoom: {
                if ([action.payload isKindOfClass:[NSNumber class]]) {
                    updatedState.supportZoom = [action.payload boolValue];
                } else {
                    return state;
                }
                break;
            }
            case ACCCameraActionTypeResetView: {
                if ([action.payload isKindOfClass:[UIView class]]) {
                    updatedState.resetView = action.payload;
                } else {
                    return state;
                }
                break;
            }
            case ACCCameraInitActionTypeFirstRender: {
                if ([action.payload isKindOfClass:[NSNumber class]]) {
                    updatedState.firstRender = [action.payload boolValue];
                } else {
                    return state;
                }
                break;
            }
            case ACCCameraActionTypeChangeOutpusSize:
            {
                if ([action.payload isKindOfClass:[NSValue class]]) {
                    updatedState.outputSize = [action.payload CGSizeValue];
                } else {
                    return state;
                }
                break;
            }
            case ACCCameraActionTypeChangePreviewType: {
                if ([action.payload isKindOfClass:[NSNumber class]]) {
                    updatedState.previewType = [action.payload integerValue];
                } else {
                    return state;
                }
                break;
            }
            default: {
                NSAssert(NO, @"invalid action type!");
                break;
            }
        }
        return updatedState;
    }
    return state;
}

- (Class)domainActionClass
{
    return [ACCCameraAction class];
}

@end

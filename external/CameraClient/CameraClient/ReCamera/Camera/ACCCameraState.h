//
//  ACCCameraState.h
//  Pods
//
//  Created by leo on 2019/12/12.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Mantle/Mantle.h>
#import <CreationKitRTProtocol/ACCCameraDefine.h>
#import <CameraClient/ACCState.h>
#import <CameraClient/ACCResult.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCCameraState : MTLModel

#pragma mark - Camera Session
@property (nonatomic, assign) ACCCameraSessionState sessionState;
@property (nonatomic, assign) AVCaptureDevicePosition devicePosition;
@property (nonatomic, nullable) ACCResult<id> *startVideoCaptureResult;
@property (nonatomic, nullable) ACCResult<id> *startAudioCaptureResult;
@property (nonatomic, nullable) ACCResult<id> *stopVideoCaptureResult;

#pragma mark - Flash Mode
@property (nonatomic, assign) BOOL isFlashEnable;
@property (nonatomic, assign) ACCCameraFlashMode flashMode;

#pragma mark - Torch Mode
@property (nonatomic, assign) BOOL isTorchEnable;
@property (nonatomic, assign) ACCCameraTorchMode torchMode;

#pragma mark - Ratio
@property (nonatomic) IESMMCaptureRatio ratio;

@property (nonatomic, strong) AVCaptureDeviceType deviceType API_AVAILABLE(ios(10.0));

#pragma mark - Focus
@property (nonatomic, assign) CGPoint focusPoint;          //归一
@property (nonatomic, assign) CGPoint exposurePoint;       //归一

#pragma mark - Zoom
@property (nonatomic, assign) BOOL supportZoom;
@property (nonatomic, assign) CGFloat zoomScale;  // 线性
@property (nonatomic, assign) CGFloat maxZoomFactor;

#pragma mark - View

@property (nonatomic) UIView *resetView;

#pragma mark - FirstRender

@property (nonatomic, assign) BOOL firstRender;

#pragma mark - Output Size
@property (nonatomic, assign) CGSize outputSize;

#pragma mark - Preview Type
@property (nonatomic, assign) IESMMCameraPreviewType previewType;

@end

NS_ASSUME_NONNULL_END

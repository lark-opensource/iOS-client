//
//  ACCCameraControlWrapper.m
//  Pods
//
//  Created by haoyipeng on 2020/6/11.
//

#import "ACCCameraControlWrapper.h"
#import <CreationKitRTProtocol/ACCCameraControlEvent.h>
#import <TTVideoEditor/VERecorder.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreativeKit/ACCMacros.h>
#import <TTVideoEditor/VERecorder.h>
#import "ACCConfigKeyDefines.h"
#import "AWERecordFirstFrameTrackerNew.h"
#import "AWERecorderTipsAndBubbleManager.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <KVOController/KVOController.h>
#import "ACCCameraFactory.h"
#import <AVFoundation/AVCaptureDevice.h>

#import <CameraClient/UIDevice+ACCAdditions.h>

CGFloat const kACCMaxCameraZoomFactor = 10.0f;

static ACCCameraTorchMode defaultTorchMode = ACCCameraTorchModeOff;
static ACCCameraFlashMode defaultFlashMode = ACCCameraFlashModeOff;

@interface ACCCameraControlFrameCache : NSObject

@property (nonatomic, strong, nullable) UIImage *captureFrameCache;
+ (instancetype)sharedInstance;

@end

@implementation ACCCameraControlFrameCache

+ (instancetype)sharedInstance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearCache) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)clearCache {
    self.captureFrameCache = nil;
}

@end

@interface ACCCameraControlWrapper () <ACCCameraBuildListener>

@property (nonatomic, strong) ACCCameraSubscription *subscription;

@property (nonatomic, assign) CGSize outputSize;
@property (nonatomic, weak) id<VERecorderPublicProtocol> camera;
@property (nonatomic, assign) BOOL isSwapCamera;
@property (nonatomic, assign) AVCaptureDevicePosition currentCameraPosition;
@property (nonatomic, assign) CGPoint exposurePoint;
@property (nonatomic, assign) CGPoint focusPoint;
@property (nonatomic, assign) CGFloat currentExposureBias;
@property (nonatomic, assign) ACCCameraFlashMode flashMode;
@property (nonatomic, assign) ACCCameraTorchMode torchMode;
@property (nonatomic, strong) id<ACCCameraTorchProtocol> frontCameraTorch;
@property (nonatomic, strong) NSNumber *brightness;
@property (nonatomic, assign) BOOL isFlashEnable;
@property (nonatomic, assign) BOOL isTorchEnable;
@property (nonatomic, assign) BOOL supprotZoom;
@property (nonatomic, assign) CGFloat zoomFactor;
@property (nonatomic, assign) CGFloat maxZoomFactor;
@property (nonatomic, assign) CGFloat minZoomFactor;

@end

@implementation ACCCameraControlWrapper

@synthesize audioCaptureInitializing = _audioCaptureInitializing;
@synthesize enableMultiZoomCapability = _enableMultiZoomCapability;

- (void)setCameraProvider:(id<ACCCameraProvider>)cameraProvider
{
    [cameraProvider addCameraListener:self];
}

#pragma mark - ACCCameraBuildListener

- (void)onCameraInit:(id<VERecorderPublicProtocol>)camera
{
    self.camera = camera;
    
    @weakify(self);
    if (ACCConfigBool(ACCConfigBool_enable_torch_auto_mode)) {
        [camera setCameraInfoBlock:^(IESMMCameraInfoType type, id value) {
            @strongify(self);
            acc_dispatch_main_async_safe(^{
                if (type == IESMMCameraInfoTypeBrightness && [value isKindOfClass:[NSNumber class]]) {
                    self.brightness = value;
                }
            });
        } withCameraInfoRequirement:IESMMCameraInfoTypeBrightness];
    }
}

#pragma mark - setter & getter

- (void)setOutputDirection:(UIImageOrientation)orientation
{
    [self.camera setOutputDirection:orientation];
}

- (void)setCamera:(id<VERecorderPublicProtocol>)camera
{
    _camera = camera;
    self.currentCameraPosition = camera.currentCameraPosition;
    self.isTorchEnable = [self isCameraTorchCapabilitySupported];
    self.isFlashEnable = [camera isCameraCapabilitySupported:IESMMCameraCapabilityFlash];
    if (ACCConfigBool(ACCConfigBOOL_enable_continuous_flash_and_torch)) {
        self.torchMode = [self defaultCameraTorchMode];
        [self switchToFlashMode:[self defaultCameraFlashMode]];
    } else {
        self.torchMode = camera.torchOn ? ACCCameraTorchModeOn : ACCCameraTorchModeOff;
        self.flashMode = (ACCCameraFlashMode)camera.cameraFlashMode;
    }
    self.supprotZoom = [camera isCameraCapabilitySupported:IESMMCameraCapabilityZoom];
    if (self.supprotZoom) {
        [self.camera cameraSetZoomFactor:1.0];
        [self.camera setMaxZoomFactor:kACCMaxCameraZoomFactor];
        self.maxZoomFactor = kACCMaxCameraZoomFactor;
        self.zoomFactor = 1.0;
    }
    @weakify(self);
    [self.KVOController observe:camera keyPath:@"outputSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        self.outputSize = ((NSValue *)change[NSKeyValueChangeNewKey]).CGSizeValue;
    }];
}

- (void)changeExposurePointTo:(CGPoint)point
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (self.camera.previewContainer.bounds.size.width > 0 && self.camera.previewContainer.bounds.size.height > 0) {
        CGPoint pointInOne = CGPointApplyAffineTransform(point, CGAffineTransformMakeScale(1 / self.camera.previewContainer.bounds.size.width, 1 / self.camera.previewContainer.bounds.size.height));
        
        [self.subscription performEventSelector:@selector(onWillManuallyAdjustExposurePoint:) realPerformer:^(id<ACCCameraControlEvent> _Nonnull handler) {
            [handler onWillManuallyAdjustExposurePoint:pointInOne];
        }];
        
        [self.camera tapExposureAtPoint:pointInOne];
        self.exposurePoint = pointInOne;
        
        [self.subscription performEventSelector:@selector(onDidManuallyAdjustExposurePoint:) realPerformer:^(id<ACCCameraControlEvent> _Nonnull handler) {
            [handler onDidManuallyAdjustExposurePoint:pointInOne];
        }];
    } else {
        AWELogToolError(AWELogToolTagRecord, @"change exposure point error, camera's previewContainer bounds: %@", [NSValue valueWithCGRect:self.camera.previewContainer.bounds]);
    }
}

- (void)changeFocusPointTo:(CGPoint)point
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (self.camera.previewContainer.bounds.size.width > 0 && self.camera.previewContainer.bounds.size.height > 0) {
        CGPoint pointInOne = CGPointApplyAffineTransform(point, CGAffineTransformMakeScale(1 / self.camera.previewContainer.bounds.size.width, 1 / self.camera.previewContainer.bounds.size.height));
        
        [self.subscription performEventSelector:@selector(onWillManuallyAdjustFocusPoint:) realPerformer:^(id<ACCCameraControlEvent> _Nonnull handler) {
            [handler onWillManuallyAdjustFocusPoint:pointInOne];
        }];
        
        [self.camera tapFocusAtPoint:pointInOne];
        self.focusPoint = pointInOne;
        
        [self.subscription performEventSelector:@selector(onDidManuallyAdjustFocusPoint:) realPerformer:^(id<ACCCameraControlEvent> _Nonnull handler) {
            [handler onDidManuallyAdjustFocusPoint:pointInOne];
        }];
    } else {
        AWELogToolError(AWELogToolTagRecord, @"change focus point error, camera's previewContainer bounds: %@", [NSValue valueWithCGRect:self.camera.previewContainer.bounds]);
    }
}

- (void)changeFocusAndExposurePointTo:(CGPoint)point
{
    if (![self p_verifyCameraContext]) {
        return ;
    }
    if (self.camera.previewContainer.bounds.size.width > 0 && self.camera.previewContainer.bounds.size.height > 0) {
        CGPoint pointInOne = CGPointApplyAffineTransform(point, CGAffineTransformMakeScale(1 / self.camera.previewContainer.frame.size.width, 1 / self.camera.previewContainer.frame.size.height));

        [self.subscription performEventSelector:@selector(onWillManuallyAdjustFocusAndExposurePoint:) realPerformer:^(id<ACCCameraControlEvent> _Nonnull handler) {
            [handler onWillManuallyAdjustFocusAndExposurePoint:pointInOne];
        }];

        [self.camera tapExposureAtPoint:pointInOne];
        // reset exposure bias
        [self.camera changeExposureBias:0];
        self.currentExposureBias = 0;
        self.exposurePoint = pointInOne;

        [self.camera tapFocusAtPoint:pointInOne];
        self.focusPoint = pointInOne;

        [self.subscription performEventSelector:@selector(onDidManuallyAdjustFocusAndExposurePoint:) realPerformer:^(id<ACCCameraControlEvent> _Nonnull handler) {
            [handler onDidManuallyAdjustFocusAndExposurePoint:pointInOne];
        }];
    } else {
        AWELogToolError(AWELogToolTagRecord, @"change focus and exposure point error, camera's previewContainer bounds: %@", [NSValue valueWithCGRect:self.camera.previewContainer.bounds]);
    }
}

- (void)changeExposureBiasWithRatio:(float)ratio
{
    if (![self p_verifyCameraContext]) {
        return ;
    }
    CGFloat newBias;
    if ([self.camera maxExposureBias] < [self.camera minExposureBias]) {
        newBias = [self.camera exposureBias];
    } else {
        CGFloat difference = [self.camera maxExposureBias] - [self.camera minExposureBias];
        newBias = self.currentExposureBias + ratio * difference;
        if (newBias > [self.camera maxExposureBias]) {
            newBias = [self.camera maxExposureBias];
        } else if (newBias < [self.camera minExposureBias]) {
            newBias = [self.camera minExposureBias];
        }
    }

    [self.subscription performEventSelector:@selector(onWillManuallyAdjustExposureBiasWithRatio:) realPerformer:^(id<ACCCameraControlEvent> _Nonnull handler) {
        [handler onWillManuallyAdjustExposureBiasWithRatio:ratio];
    }];

    [self.camera changeExposureBias:newBias];
    self.currentExposureBias = newBias;

    [self.subscription performEventSelector:@selector(onDidManuallyAdjustExposureBiasWithRatio:) realPerformer:^(id<ACCCameraControlEvent> _Nonnull handler) {
        [handler onDidManuallyAdjustExposureBiasWithRatio:ratio];
    }];
}

- (void)resetExposureBias
{
    if (![self p_verifyCameraContext]) {
        return ;
    }
    if (ACC_FLOAT_GREATER_THAN([self.camera minExposureBias], [self.camera maxExposureBias])) {
        return ;
    }
    CGFloat difference = [self.camera maxExposureBias] - [self.camera minExposureBias];
    float ratio = -(self.currentExposureBias / difference);
    [self changeExposureBiasWithRatio:ratio];
}

- (CGFloat)currentExposureBias
{
    return [self.camera exposureBias];
}

- (void)changeOutputSize:(CGSize)outputSize
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (self.camera) {
        [self.camera resetOutputSize:outputSize];
    } else {
       AWELogToolError(AWELogToolTagRecord, @"change camera output size error, camera is nil");
    }
}

- (void)setPreviewModeType:(IESPreviewModeType)previewModeType
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    self.camera.previewModeType = previewModeType;
}

- (void)resetCameraZoomFactor
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self changeToZoomFactor:1.0];
}

- (CGFloat)minZoomFactor
{
    return [self currentInVirtualCameraMode] ? 0.5 : 1.0;
}

- (void)changeToZoomFactor:(CGFloat)zoomFactor
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self isCameraCapabilitySupportedZoom]) {
        CGFloat minScale = self.minZoomFactor;
        CGFloat maxZoomFactor = self.maxZoomFactor;
        if (zoomFactor >= minScale && zoomFactor <= maxZoomFactor) {
            [self.camera cameraSetZoomFactor:zoomFactor];
            self.zoomFactor = zoomFactor;
        }
    } else {
        AWELogToolError(AWELogToolTagRecord, @"change camera zoom factor error, camera does not support zoom capability");
        return;
    }
}

- (BOOL)isCameraCapabilitySupportedZoom
{
    return [self.camera isCameraCapabilitySupported:IESMMCameraCapabilityZoom];
}

#pragma mark - camera zoom wrapper
//https://bytedance.feishu.cn/docs/doccnqDXU0AT6nTFYDk5qRXkVte

- (BOOL)currentInVirtualCameraMode
{
    if (self.camera.currentCameraPosition != AVCaptureDevicePositionBack) {
        return NO;
    }
    if (@available(iOS 13.0, *)) {
        if ([self.camera.deviceType isEqualToString:AVCaptureDeviceTypeBuiltInTripleCamera] ||
            [self.camera.deviceType isEqualToString:AVCaptureDeviceTypeBuiltInDualWideCamera]) {
            return YES;
        }
    }
    return NO;
}


- (IESCameraFlashMode)getNextFlashMode
{
    return (IESCameraFlashMode)((NSInteger)self.flashMode + 1) % 3;
}

- (IESCameraFlashMode)getNextTorchMode
{
    if (ACCConfigBool(ACCConfigBool_enable_torch_auto_mode)) {
        return (IESCameraFlashMode)((NSInteger)self.torchMode + 1) % 3;
    } else {
        return (self.torchMode == IESCameraFlashModeOn) ? IESCameraFlashModeOff : IESCameraFlashModeOn;
    }
}

- (void)pauseCameraCapture
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (self.camera) {
        if ([ACCDeviceAuth isCameraAuth]) {
            [self.camera pauseCameraCapture];
        } else {
            AWELogToolError(AWELogToolTagRecord, @"pauseCameraCapture error, camera not authorized");
        }
    } else {
       AWELogToolError(AWELogToolTagRecord, @"pauseCameraCapture error, camera is nil");
    }
}

- (void)removeHTSGLPreview
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (self.camera) {
        [self.camera removeHTSGLPreview];
    } else {
       AWELogToolError(AWELogToolTagRecord, @"removeHTSGLPreview error, camera is nil");
    }
}

- (void)resumeCameraCapture
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (self.camera) {
        if ([ACCDeviceAuth isCameraAuth]) {
            [self.camera resumeCameraCapture];
        } else {
            AWELogToolError(AWELogToolTagRecord, @"resumeCameraCapture error, camera not authorized");
        }
    } else {
       AWELogToolError(AWELogToolTagRecord, @"resumeCameraCapture error, camera is nil");
    }
}

- (void)resumeHTSGLPreviewWithView:(nonnull UIView *)view
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (self.camera) {
        [self.camera resumeHTSGLPreview:view];
    } else {
       AWELogToolError(AWELogToolTagRecord, @"resumeHTSGLPreviewWithView error, camera is nil");
    }
}

- (void)startAudioCapture
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    if (![self p_verifyCameraContext]) {
        params[@"status"] = @(0);
        params[@"message"] = @"invalid camere context";
        [ACCTracker() trackEvent:@"studio_start_audio_capture" params:params];
        return;
    }
    
    BOOL success;
    NSString *message;
    
    if (self.camera) {
        if ([ACCDeviceAuth isMicroPhoneAuth]) {
            if (![self.camera startAudioCapture]) {
                success = NO;
                message = @"call startAudioCapture success, but return failed";
                AWELogToolError(AWELogToolTagRecord, message);
            } else {
                success = YES;
                message = @"startAudioCapture success";
                AWELogToolInfo(AWELogToolTagRecord, @"startAudioCapture success");
            }
        } else {
            success = NO;
            message = @"startAudioCapture error, microphone not authorized";
            AWELogToolError(AWELogToolTagRecord, @"startAudioCapture error, microphone not authorized");
        }
    } else {
        success = NO;
        message = @"startAudioCapture error, camera is nil";
        AWELogToolError(AWELogToolTagRecord, @"startAudioCapture error, camera is nil");
    }
    
    params[@"status"] = success ? @(1) : @(0);
    params[@"message"] = message ?: @"";
    [ACCTracker() trackEvent:@"studio_start_audio_capture" params:params];
}

- (void)startAudioCaptureWithReason:(NSString *)reason
{
    AWELogToolInfo(AWELogToolTagRecord, @"start audio capture reason:%@", reason);
    [self startAudioCapture];
}

- (void)startVideoAndAudioCapture
{
    [self startVideoCapture];
    [self startAudioCapture];
}

- (void)startVideoCapture
{
    [self startVideoCaptureIfCheckAppStatus:YES];
}

//包含不校验app状态的开启视频的老接口
- (void)startVideoCaptureIfCheckAppStatus:(BOOL)checkAppStatus
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

    if (![self p_verifyCameraContext]) {
        params[@"status"] = @(0);
        params[@"message"] = @"invalid camere context";
        [ACCTracker() trackEvent:@"studio_start_video_capture" params:params];
        return;
    }
    
    BOOL success;
    NSString *message;

    if (self.camera) {
        [[AWERecordFirstFrameTrackerNew sharedTracker] eventEnd:kAWERecordEventStartCameraCapture trackingBeginEvent:kAWERecordEventCameraCreate];

        if ([ACCDeviceAuth isCameraAuth]) {
            if (checkAppStatus) {
                [self.camera startVideoCaptureWithAppStatusCheck];
                success = YES;
                message = @"startVideoCaptureWithAppStatusCheck";
                AWELogToolInfo(AWELogToolTagRecord, message);
            } else {
                [self.camera startVideoCapture];
                success = YES;
                message = @"startVideoCapture";
                AWELogToolInfo(AWELogToolTagRecord, message);
            }
        } else {
            success = NO;
            message = @"startVideoCapture error, camera not authorized";
            AWELogToolError(AWELogToolTagRecord, message);
        }
    } else {
        success = NO;
        message = @"startVideoCapture error, camera is nil";
        AWELogToolError(AWELogToolTagRecord, message);
    }
    
    params[@"status"] = success ? @(1) : @(0);
    params[@"message"] = message ?: @"";
    [ACCTracker() trackEvent:@"studio_start_video_capture" params:params];
}

- (void)stopAudioCapture
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    if (![self p_verifyCameraContext]) {
        params[@"status"] = @(0);
        params[@"message"] = @"invalid camere context";
        [ACCTracker() trackEvent:@"studio_stop_audio_capture" params:params];
        return;
    }
    
    BOOL success;
    NSString *message;
    
    if (self.camera) {
        if ([ACCDeviceAuth isMicroPhoneAuth]) {
            [self.camera stopAudioCapture];
            success = YES;
            message = @"stopAudioCapture success";
            AWELogToolInfo(AWELogToolTagRecord, message);
        } else {
            success = NO;
            message = @"stopAudioCapture error, microphone not authorized";
            AWELogToolError(AWELogToolTagRecord, message);
        }
    } else {
        success = NO;
        message = @"stopVideoCapture error, camera is nil";
        AWELogToolError(AWELogToolTagRecord, message);
    }
    
    params[@"status"] = success ? @(1) : @(0);
    params[@"message"] = message ?: @"";
    [ACCTracker() trackEvent:@"studio_stop_audio_capture" params:params];
}

- (void)stopAudioCaptureWithReason:(NSString *)reason
{
    AWELogToolInfo(AWELogToolTagRecord, @"stop audio capture reason:%@", reason);
    [self stopAudioCapture];
}

- (void)releaseAudioCapture
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    acc_dispatch_main_async_safe(^{
        [self.subscription performEventSelector:@selector(onWillReleaseAudioCapture) realPerformer:^(id<ACCCameraControlEvent> _Nonnull obj) {
            [obj onWillReleaseAudioCapture];
        }];
    });
    
    [self.camera releaseAudioCapture];
    
    acc_dispatch_main_async_safe(^{
        [self.subscription performEventSelector:@selector(onDidReleaseAudioCapture) realPerformer:^(id<ACCCameraControlEvent> _Nonnull obj) {
            [obj onDidReleaseAudioCapture];
        }];
    });
    AWELogToolInfo(AWELogToolTagRecord, @"releaseAudioCapture");
    [ACCTracker() trackEvent:@"studio_release_audio_capture" params:nil];
}

- (void)stopAndReleaseAudioCapture
{
    [self stopAudioCapture];
    [self releaseAudioCapture];
}

- (void)stopVideoAndAudioCapture
{
    [self stopVideoCapture];
    [self stopAudioCapture];
}

- (void)stopVideoCapture
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    if (![self p_verifyCameraContext]) {
        params[@"status"] = @(0);
        params[@"message"] = @"invalid camere context";
        [ACCTracker() trackEvent:@"studio_stop_video_capture" params:params];
        [self didStopVideoCapture:NO];
        return;
    }
    
    BOOL success;
    NSString *message;
    
    if (self.camera) {
        if ([ACCDeviceAuth isCameraAuth]) {
            [self captureFrameWhenStopCaptre:nil];
            @weakify(self);
            [self.camera stopVideoCaptureWithCompletionHandler:^{
                @strongify(self);
                [self didStopVideoCapture:YES];
            }];
            success = YES;
            message = @"stopVideoCapture success";
            AWELogToolInfo(AWELogToolTagRecord, message);
        } else {
            success = NO;
            message = @"stopVideoCapture error, camera not authorized";
            AWELogToolError(AWELogToolTagRecord, message);
            [self didStopVideoCapture:NO];
        }
    } else {
        success = NO;
        message = @"stopVideoCapture error, camera is nil";
        AWELogToolError(AWELogToolTagRecord, message);
        [self didStopVideoCapture:NO];
    }
    
    params[@"status"] = success ? @(1) : @(0);
    params[@"message"] = message ?: @"";
    [ACCTracker() trackEvent:@"studio_stop_video_capture" params:params];
}

- (void)didStopVideoCapture:(BOOL)success {
    acc_dispatch_main_async_safe(^{
        [self.subscription performEventSelector:@selector(onDidStopVideoCapture:) realPerformer:^(id<ACCCameraControlEvent> _Nonnull obj) {
            [obj onDidStopVideoCapture:success];
        }];
    });
}

- (void)captureFrameWhenStopCaptre:(nullable void(^)(BOOL success))completion {
    if (!ACCConfigBool(kConfigBool_enable_cover_frame_when_start_capture)) {
        ACCBLOCK_INVOKE(completion, NO);
        return;
    }
    [self.camera captureSourcePhotoAsImageWithCompletionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
        if (error) {
            AWELogToolError(AWELogToolTagRecord, @"%s %@", __PRETTY_FUNCTION__, error);
            ACCBLOCK_INVOKE(completion, NO);
            return;
        }
        if (!image) {
            ACCBLOCK_INVOKE(completion, NO);
            return;
        }
        acc_dispatch_main_thread_async_safe(^{
            [ACCCameraControlFrameCache sharedInstance].captureFrameCache = image;
            ACCBLOCK_INVOKE(completion, YES);
        });
    }];
}

- (void)clearCaptureFrame {
    [ACCCameraControlFrameCache sharedInstance].captureFrameCache = nil;
}

- (UIImage *)captureFrame {
    return [ACCCameraControlFrameCache sharedInstance].captureFrameCache;
}

- (void)switchToOppositeCameraPosition
{
    if ([self p_needToSwitchCamera]) {
        [[AWERecorderTipsAndBubbleManager shareInstance] removeZoomScaleHintView];
        AVCaptureDevicePosition switchToPostion = (self.camera.currentCameraPosition == AVCaptureDevicePositionBack) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
        [self switchToCameraPosition:switchToPostion];
    }
}

- (void)switchToCameraPosition:(AVCaptureDevicePosition)position
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (self.camera) {
        if (self.camera.currentCameraPosition == position) {
            return;
        } else {
            [self switchCamera:position];
        }
    } else {
        AWELogToolError(AWELogToolTagRecord, @"switchToCameraPosition: error, camera is nil");
    }
}

- (void)switchCamera:(AVCaptureDevicePosition)position
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.subscription performEventSelector:@selector(onWillSwitchToCameraPosition:) realPerformer:^(id<ACCCameraControlEvent> _Nonnull handler) {
        [handler onWillSwitchToCameraPosition:position];
    }];
    self.isSwapCamera = YES;
    @weakify(self);
    [self.camera setFirstRenderBlock:^{
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            if (self.isSwapCamera) {
                self.isFlashEnable = [self.camera isCameraCapabilitySupported:IESMMCameraCapabilityFlash];
                self.isTorchEnable = [self isCameraTorchCapabilitySupported];
                
                if (!ACCConfigBool(ACCConfigBOOL_enable_continuous_flash_and_torch)) {
                    [self switchToFlashMode:ACCCameraFlashModeOff];
                    [self switchToTorchMode:ACCCameraTorchModeOff];
                }
            }
            self.isSwapCamera = NO;
            self.currentCameraPosition = self.camera.currentCameraPosition;
            
            [self.subscription performEventSelector:@selector(onDidSwitchToCameraPosition:) realPerformer:^(id<ACCCameraControlEvent> _Nonnull handler) {
                [handler onDidSwitchToCameraPosition:self.currentCameraPosition];
            }];
        });
    }];
    [[self camera] switchCameraSource];
    [self.camera setMaxZoomFactor:kACCMaxCameraZoomFactor];
    [self resetCameraZoomFactor];
}

- (void)syncCameraActualPosition
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (self.camera.currentCameraPosition != self.currentCameraPosition) {
        self.isFlashEnable = [self.camera isCameraCapabilitySupported:IESMMCameraCapabilityFlash];
        self.isTorchEnable = [self isCameraTorchCapabilitySupported];
        if (!ACCConfigBool(ACCConfigBOOL_enable_continuous_flash_and_torch)) {
            [self switchToFlashMode:ACCCameraFlashModeOff];
            [self switchToTorchMode:ACCCameraTorchModeOff];
        }
        self.currentCameraPosition = self.camera.currentCameraPosition;
        self.isFlashEnable = [self.camera isCameraCapabilitySupported:IESMMCameraCapabilityFlash];
        self.isTorchEnable = [self isCameraTorchCapabilitySupported];
    }
}

- (void)switchToFlashMode:(ACCCameraFlashMode)flashMode
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (self.flashMode == flashMode && self.currentCameraPosition == self.camera.currentCameraPosition) {
        return;
    }
    if ([self.camera isCameraCapabilitySupported:IESMMCameraCapabilityFlash]) {
        [self.camera setCameraFlashMode:(IESCameraFlashMode)flashMode];
        self.flashMode = flashMode;
    } else {
        AWELogToolError(AWELogToolTagRecord, @"switchToFlashMode: error, current camera not support flash, camera position: %@", @(self.camera.currentCameraPosition));
    }
}

- (void)switchToTorchMode:(ACCCameraTorchMode)torchMode
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    
    if (!(ACCConfigBool(ACCConfigBool_enable_torch_auto_mode) || ACCConfigBool(ACCConfigBool_enable_front_torch))) {
        self.torchMode = _camera.torchOn ? ACCCameraTorchModeOn : ACCCameraTorchModeOff; //Compare with real camera state
        if (self.torchMode == torchMode && self.currentCameraPosition == self.camera.currentCameraPosition) {
            return;
        }
        if ([self isCameraTorchCapabilitySupported] &&
            torchMode != ACCCameraTorchModeAuto) {
            [self.camera setTorchOn:torchMode == ACCCameraTorchModeOn];
            self.torchMode = torchMode;
        } else {
            AWELogToolError(AWELogToolTagRecord, @"switchToTorchMode: error, current camera not support torch, camera position: %@", @(self.camera.currentCameraPosition));
        }
    } else {
        if (self.torchMode == torchMode) {
            return;
        }
                
        if (torchMode != ACCCameraTorchModeOn) {
            [self turnOffUniversalTorch];
        }

        self.torchMode = torchMode;
    }
}

- (void)turnOnUniversalTorch
{
    if (self.camera.currentCameraPosition == AVCaptureDevicePositionFront) {
        [self.frontCameraTorch turnOn];
    } else  if (self.camera.currentCameraPosition == AVCaptureDevicePositionBack) {
        [self.camera setTorchOn:YES];
    }
}

- (void)turnOffUniversalTorch
{
    [self.frontCameraTorch turnOff];
    [self.camera setTorchOn:NO];
}

- (void)registerTorch:(id<ACCCameraTorchProtocol>)torch forCamera:(AVCaptureDevicePosition)camera
{
    if (camera == AVCaptureDevicePositionFront) {
        self.frontCameraTorch = torch;
    }
}

- (BOOL)isCameraTorchCapabilitySupported
{
    if (ACCConfigBool(ACCConfigBool_enable_front_torch)) {
        if (self.camera.currentCameraPosition == AVCaptureDevicePositionFront) {
            return YES;
        }
    }
    
    return [self.camera isCameraCapabilitySupported:IESMMCameraCapabilityTorch];
}

- (ACCCameraTorchMode)defaultCameraTorchMode
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSInteger mode = ACCConfigInt(ACCConfigInt_default_torch_status);
        if (mode >= 0 && mode <= ACCCameraTorchModeAuto) {
            defaultTorchMode = (ACCCameraTorchMode)mode;
        }
    });
    
    return defaultTorchMode;
}

- (ACCCameraFlashMode)defaultCameraFlashMode
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSInteger mode = ACCConfigInt(ACCConfigInt_default_torch_status);
        if (mode >= 0 && mode <= ACCCameraTorchModeAuto) {
            defaultFlashMode = (ACCCameraFlashMode)mode;
        }
    });
    
    return defaultFlashMode;
}

- (void)setZoomFactor:(CGFloat)zoomFactor
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self isCameraCapabilitySupportedZoom]) {
        _zoomFactor = zoomFactor;
    } else {
        AWELogToolError(AWELogToolTagRecord, @"setCameraMaxZoomFactor: error, camera does not support zoom capability");
    }
}

- (void)setCameraMaxZoomFactor:(CGFloat)maxFactor
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self isCameraCapabilitySupportedZoom]) {
        [self.camera setMaxZoomFactor:maxFactor];
        self.maxZoomFactor = maxFactor;
    } else {
        AWELogToolError(AWELogToolTagRecord, @"setCameraMaxZoomFactor: error, camera does not support zoom capability");
    }
}

- (void)setFlashMode:(ACCCameraFlashMode)flashMode
{
    _flashMode = flashMode;
    defaultFlashMode = flashMode;
}

- (void)setTorchMode:(ACCCameraTorchMode)torchMode
{
    _torchMode = torchMode;
    defaultTorchMode = torchMode;
}

#pragma mark - private

- (ACCCameraSubscription *)subscription
{
    if (!_subscription) {
        _subscription = [ACCCameraSubscription new];
    }
    return _subscription;
}

- (void)addSubscriber:(id<ACCCameraControlEvent>)subscriber
{
    [self.subscription addSubscriber:subscriber];
}

#pragma mark -

- (NSString *)cameraZoomSupportedInfo
{
    return [self.camera cameraZoomSupportedInfo];
}

- (NSInteger)status
{
    return self.camera.status;
}

- (void)initAudioCapture:(dispatch_block_t)completion
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    @weakify(self);
    dispatch_block_t wrappedCompletion = ^{
        @strongify(self);
        [self.subscription performEventSelector:@selector(onDidInitAudioCapture) realPerformer:^(id<ACCCameraControlEvent> _Nonnull obj) {
            [obj onDidInitAudioCapture];
        }];
        ACCBLOCK_INVOKE(completion);
    };
    if ([self.camera respondsToSelector:@selector(initAudioCaptureAndSetupAudioSession:)]) {
        [self.camera initAudioCaptureAndSetupAudioSession:^(BOOL ret) {
            if (!ret) {
                AWELogToolError(AWELogToolTagRecord, @"initAudioCaptureAndSetupAudioSession: failed");
            }
            acc_dispatch_main_async_safe(wrappedCompletion);
        }];
    } else if ([self.camera respondsToSelector:@selector(initAudioCapture:)]) {
        [self.camera initAudioCapture:^(BOOL ret) {
            if (!ret) {
                AWELogToolError(AWELogToolTagRecord, @"initAudioCapture: failed");
                acc_dispatch_main_async_safe(wrappedCompletion);
            }
        }];
    }
}

- (BOOL)isAudioCaptureRuning
{
    return [self.camera isAudioCaptureRuning];
}

- (void)cancelVideoRecord
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera cancelVideoRecord];
}

- (CGSize)captureSize
{
    return self.camera.captureSize;
}

-(UIView *)previewView
{
    return (UIView *)self.camera.previewView;
}

- (void)setRearPreferredStabilizationMode:(AVCaptureVideoStabilizationMode)rearPreferredStabilizationMode
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    self.camera.rearPreferredStabilizationMode = rearPreferredStabilizationMode;
}

- (void)setFrontPreferredStabilizationMode:(AVCaptureVideoStabilizationMode) frontPreferredStabilizationMode
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    self.camera.frontPreferredStabilizationMode = frontPreferredStabilizationMode;
}

//Can these two be combined into one function ？
- (void)preferredCameraType:(NSInteger)IESCameraType
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    self.camera.preferredCameraType = IESCameraType ;
}

- (void)notNeedAutoStartAudioCapture:(BOOL)notNeedAutoStartAudioCapture
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    self.camera.notNeedAutoStartAudioCapture = notNeedAutoStartAudioCapture;
}

//- (void)propertySet:(IESMMARWorldTrackingPropertySet *)propertySet API_AVAILABLE(ios(11.0))
//{
//    if (![self p_verifyCameraContext]) {
//        return;
//    }
//    if (@available(iOS 11.0, *)) {
//        self.camera.propertySet = propertySet;
//    }
//}

- (void)ignoreNotification:(BOOL)ignoreStatus
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    self.camera.ignoreNotification = ignoreStatus;
}

- (BOOL)getIgnoreNotificatio
{
    return self.camera.ignoreNotification;
}

- (IESMMCaptureRatio)currenCaptureRatio
{
    return self.camera.captureRatio;
}

- (void)resetCapturePreferredSize:(CGSize)size then:(void (^_Nullable)(void))then
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera resetCaptureRatio:self.camera.captureRatio preferredSize:size then:then];
}

- (void)resetCaptureRatio:(IESMMCaptureRatio)ratio then:(void (^_Nullable)(void))then
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera resetCaptureRatio:ratio then:then];
}

- (void)setBGVideoAutoRepeat:(BOOL)autoRepeat
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(setBGVideoAutoRepeat:)]) {
        [self.camera setBGVideoAutoRepeat:autoRepeat];
    }
}

- (void)startAudioCapture:(NSInteger)tryNumber completeBlock:(void (^)(BOOL ret, NSError *_Nullable retError))completeBlock
{
    if (tryNumber == 0) {
        ACCBLOCK_INVOKE(completeBlock, NO, nil);
    } else {
        @weakify(self);
        if (![self.camera startAudioCapture:^(BOOL isSuccess, NSError * _Nonnull error) {
            @strongify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!isSuccess || error) {
                    [self startAudioCapture:tryNumber-1 completeBlock:completeBlock];
                } else {
                    ACCBLOCK_INVOKE(completeBlock, isSuccess, error);
                }
            });
        }]) {
            AWELogToolError(AWELogToolTagRecord, @"startAudioCapture: failed");
        }
    }
}

#pragma mark - 横屏模式

- (void)enableHorizontalScreenMode:(HTSGLRotationMode)outputRotation resetRotation:(HTSGLRotationMode)resetRotation
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    self.camera.outputRotationMode = outputRotation;
//    if ([self.camera isKindOfClass:[IESMMCamera class]] &&
//        [self.camera respondsToSelector:@selector(enableHorizontalScreenMode:resetRotation:)]) {
//        [(IESMMCamera *)self.camera enableHorizontalScreenMode:outputRotation resetRotation:resetRotation];
//    }
}

#pragma mark - 脏镜头检测

- (void)runDirtyCameraDetectAlgorithmWithCompletion:(VECameraLensResultBlock)completion
{
    [self.camera runDirtyCameraDetectAlgorithmWithCompletion:completion];
}

#pragma mark - Pure Mode
- (void)setPureCameraMode:(BOOL)mode
{
    [self.camera setPureCameraMode:mode];
}

#pragma mark - handle

- (BOOL)handleTouchUp:(CGPoint)location withType:(IESMMGestureType)type
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    return [self.camera handleTouchUp:location withType:type];
}

- (BOOL)handleTouchDown:(CGPoint)location withType:(IESMMGestureType)type
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    return [self.camera handleTouchDown:location withType:type];
}

- (BOOL)handleLongPressEventWithLocation:(CGPoint)location
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    return [self.camera handleLongPressEventWithLocation:location];
}

- (BOOL)handlePanEventWithTranslation:(CGPoint)translation location:(CGPoint)location
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    return [self.camera handlePanEventWithTranslation:translation location:location];
}

- (BOOL)handleScaleEvent:(CGFloat)scale
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    return [self.camera handleScaleEvent:scale];
}

- (BOOL)handleRotationEvent:(CGFloat)rotation
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    return [self.camera handleRotationEvent:rotation];
}

- (BOOL)handleTouchEvent:(CGPoint)location
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    return [self.camera handleTouchEvent:location];
}

- (BOOL)handleDoubleClickEvent:(CGPoint)location
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    if ([self.camera respondsToSelector:@selector(handleDoubleClickEvent:)]) {
        return [self.camera handleDoubleClickEvent:location];
    }
    return NO;
}

- (void)resetPreferredFrameRate:(NSUInteger)frameRate
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera resetPreferredFrameRate:frameRate];
}

- (void)startAudioCapture:(void (^ _Nullable)(BOOL, NSError * _Nullable))completeBlock withPrivacyCert:(nullable id)token {
    [self startAudioCapture:1 completeBlock:completeBlock];
}


- (void)startAudioCaptureWithPrivacyCert:(nullable id)token
{
    [self startAudioCapture];
}


- (void)startVideoCaptureWithAppStatusCheckWithPrivacyCert:(nullable id)token
{
    [self startVideoCaptureIfCheckAppStatus:YES];
}


- (void)startVideoCaptureWithPrivacyCert:(nullable id)token
{
    [self startVideoCapture];
}


- (void)stopAudioCaptureWithPrivacyCert:(nullable id)token
{
    [self stopAudioCapture];
}


- (void)stopVideoCaptureWithPrivacyCert:(nullable id)token
{
    [self stopVideoCapture];
}


#pragma mark - Private Method

- (BOOL)p_verifyCameraContext
{
    if (![self.camera cameraContext]) {
        return YES;
    }
    BOOL result = [self.camera cameraContext] == ACCCameraVideoRecordContext;
    if (!result) {
        ACC_LogError(@"Camera operation error, context not equal to ACCCameraVideoRecordContext point");
    }
    return result;
}

- (BOOL)p_needToSwitchCamera
{
    if (ACCConfigBool(kConfigBool_tools_shoot_switch_camera_while_recording)) {
        return [self camera].status != HTSCameraStatusProcessing;
    } else {
        return ([self camera].status == HTSCameraStatusIdle || [self camera].status == HTSCameraStatusStopped);
    }
}

@end

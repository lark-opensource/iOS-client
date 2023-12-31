//
//  ACCRecorderMiddleware.m
//  CameraClient
//
//  Created by lxp on 2019/12/23.
//

#import <libextobjc/EXTScope.h>
#import "ACCRecorderMiddleware.h"
#import "ACCRecorderAction.h"
#import "ACCRecorderState.h"
#import "ACCCameraAction.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSTimer+ACCAdditions.h>

@interface ACCRecorderMiddleware ()

@property (nonatomic, strong) IESMMCamera<IESMMRecoderProtocol> *camera;
@property (nonatomic, strong) NSTimer *durationTimer;
@property (nonatomic, strong) ACCRecorderConfig *config;

@end

@implementation ACCRecorderMiddleware 

+ (instancetype)middlewareWithCamera:(IESMMCamera<IESMMRecoderProtocol> *)camera
{
    ACCRecorderMiddleware *middleware = [ACCRecorderMiddleware middleware];
    middleware.camera = camera;
    [middleware bindCamera];
    return middleware;
}

#pragma mark - Override
- (BOOL)shouldHandleAction:(ACCAction *)action
{
    return [action isKindOfClass:[ACCRecorderAction class]];
}

- (ACCAction *)handleAction:(ACCAction *)action next:(nonnull ACCActionHandler)next
{
    if ([action isKindOfClass:[ACCRecorderAction class]]) {
        [self handleRecorderAction:(ACCRecorderAction *)action];
    }
    return next(action);
}

- (ACCAction *)handleRecorderAction:(ACCRecorderAction *)action
{
    if (action.status == ACCActionStatusPending) {
        ACCRecorderActionType type = (ACCRecorderActionType)action.type;
        switch (type) {
            case ACCRecorderActionTypeStart: {
                if ([action.payload isKindOfClass:ACCRecorderConfig.class]) {
                    self.config = action.payload;
                }
                [self startRecorder:self.config];
                break;
            }
            case ACCRecorderActionTypePause: {
                [self pauseRecorder];
                break;
            }
            case ACCRecorderActionTypeRevoke: {
                [self revokeRecorder];
                [action fulfill];
                break;
            }
            case ACCRecorderActionTypeRevokeAll: {
                [self revokeAllRecorder];
                break;
            }
            case ACCRecorderActionTypeClear: {
                [self clearRecorder];
                [action fulfill];
            }
                break;
            case ACCRecorderActionTypeCancel: {
                [self cancelRecorder];
                [action fulfill];
                break;
            }
            case ACCRecorderActionTypeFinish: {
                if (!self.videoMode) {
                    [action fulfill];
                    break;
                }
                [self finishRecorder];
                break;
            }
            case ACCRecorderActionTypeChangeMode: {
                [self changeRecorderMode:[action.payload unsignedIntegerValue]];
                [action fulfill];
                break;
            }
            case ACCRecorderActionTypeExtract: {
                [self extractFrame];
                break;
            }
            case ACCRecorderActionTypeUpdateDuration: {
                action.payload = @([self.camera getTotalDuration]);
                [action fulfill];
                break;
            }
        }
    }
    return action;
}

- (void)startRecorder:(ACCRecorderConfig *)config
{
    if (self.videoMode) {
        CGFloat rate = 1.0;
        if (config.videoRate != nil) {
            rate = [config.videoRate doubleValue];
        }
        [_camera startVideoRecordWithRate:rate];
    } else {
        @weakify(self);
        IESMMCameraCaptureHandler handler = ^(UIImage * _Nonnull processedImage, NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                ACCRecorderAction *action = [ACCRecorderAction finishAction];
                if (processedImage && !error) {
                    action.payload = processedImage;
                    [action fulfill];
                } else {
                    // 过度方案，后面统一提供payload方案
                    action.payload = error;
                    [action reject];
                }
                
                [self dispatch:action];
            });
        };
        [_camera captureImageWithOptions:config.photoOptions?:[IESMMCaptureOptions new] handler:handler];
    }
    
    [self fireDurationTimer];
}

- (void)pauseRecorder
{
    [_camera pauseVideoRecord];
    [_camera stopAudioCapture];
    
    [self invalidateDurationTimer];
}

- (void)revokeRecorder
{
    [_camera removeLastVideoFragment];
}

- (void)revokeAllRecorder
{
    @weakify(self);
    [_camera removeAllVideoFragments:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            ACCRecorderAction *action = [ACCRecorderAction revokeAllAction];
            [action fulfill];
            [self dispatch:action];
        });
    }];
}

- (void)clearRecorder
{
    [_camera removeAllVideoFragments];
}

- (void)cancelRecorder
{
    [_camera cancelVideoRecord];
    
    [self invalidateDurationTimer];
}

- (void)finishRecorder
{
    @weakify(self);
    [_camera pauseVideoRecord];
    [_camera exportWithVideo:[_camera videoData] completion:^(HTSVideoData * _Nullable newVideoData, NSError * _Nullable error) {
        @strongify(self);
        ACCRecorderAction *action = [ACCRecorderAction finishAction];
        [action fulfill];
        action.payload = error ? error : newVideoData;
        [self dispatch:action];
    }];
    
    [self invalidateDurationTimer];
}

- (void)extractFrame
{
    @weakify(self);
    [self.camera captureSourcePhotoAsImageByUser:NO completionHandler:^(UIImage * _Nonnull processedImage, NSError * _Nonnull error) {
        @strongify(self);
        ACCResult *result = nil;
        if (error) {
            result = [ACCResult failure:error];
        } else {
            result = [ACCResult success:processedImage];
        }
        
        ACCRecorderAction *action = [ACCRecorderAction extractAction];
        action.payload = result;
        [action fulfill];
        [self dispatch:action];
    } afterProcess:NO];
}

#pragma mark - Recorder Mode
- (void)changeRecorderMode:(ACCRecorderMode)mode
{
    ACCRecorderState *currentState = (ACCRecorderState *)[self getState];
    if (mode != currentState.recordMode) {
        [self dispatch:[ACCCameraAction changeFlashEnable:[_camera isCameraCapabilitySupported:IESMMCameraCapabilityTorch]]];
        [self dispatch:[ACCCameraAction changeTorchEnable:[_camera isCameraCapabilitySupported:IESMMCameraCapabilityFlash]]];
    }
}

- (BOOL)videoMode
{
    ACCRecorderState *currentState = (ACCRecorderState *)[self getState];
    return currentState.recordMode == ACCRecorderModeVideo;
}

#pragma mark -

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
            case IESCameraDidStartVideoRecord: {
                ACCRecorderAction *action = [ACCRecorderAction startActionWithConfig:self.config];
                action.payload = result;
                [action fulfill];
                [self dispatch:action];
                break;
            }
            case IESCameraDidPauseVideoRecord: {
                ACCRecorderAction *action = [ACCRecorderAction pauseAction];
                action.payload = result;
                [action fulfill];
                [self dispatch:action];
                break;
            }
            default:
                break;
        }
    }];
}

#pragma mark -

- (void)fireDurationTimer
{
    [self invalidateDurationTimer];
    
    @weakify(self);
    self.durationTimer = [NSTimer acc_scheduledTimerWithTimeInterval:1.0 / 24 block:^(NSTimer *timer){
        @strongify(self);
        ACCRecorderAction *action = [[ACCRecorderAction alloc] init];
        action.type = ACCRecorderActionTypeUpdateDuration;
        [self dispatch:action];
    } repeats:YES];
}

- (void)invalidateDurationTimer
{
    if (self.durationTimer) {
        [self.durationTimer invalidate];
        self.durationTimer = nil;
    }
}

@end

//
//  ACCCameraLifeCircleEvent.h
//  Pods
//
//  Created by liyingpeng on 2020/6/4.
//

#ifndef ACCCameraLifeCircleEvent_h
#define ACCCameraLifeCircleEvent_h
#import <TTVideoEditor/HTSVideoData.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCameraService;

@protocol ACCCameraLifeCircleEvent <NSObject>

@optional

- (void)onCreateCameraCompleteWithCamera:(id<ACCCameraService>)cameraService;

- (void)cameraService:(id<ACCCameraService>)cameraService pauseRecordWithError:(NSError *)error;
- (void)cameraService:(id<ACCCameraService>)cameraService startRecordWithError:(NSError *)error;

- (void)cameraService:(id<ACCCameraService>)cameraService startVideoCaptureWithError:(NSError *)error;
- (void)cameraService:(id<ACCCameraService>)cameraService stopVideoCaptureWithError:(NSError *)error;

- (void)cameraService:(id<ACCCameraService>)cameraService didRecordReadyWithError:(NSError *)error;
- (void)cameraService:(id<ACCCameraService>)cameraService didReachMaxTimeVideoRecordWithError:(NSError *)error;

- (void)onCameraFirstFrameDidRender:(id<ACCCameraService>)cameraService;// Multiple start capture messages will be sent by a camera instance
- (void)onCameraDidStartRender:(id<ACCCameraService>)cameraService;// A camera instance starts capture several times and only sends this message once

/**
 * dispatch camera.IESCameraActionBlock events
 */
- (void)cameraService:(id<ACCCameraService>)cameraService didTakeAction:(IESCameraAction)action error:(NSError * _Nullable)error data:(id _Nullable)data;

- (void)cameraService:(id<ACCCameraService>)cameraService didChangeDuration:(CGFloat)duration totalDuration:(CGFloat)totalDuration;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCCameraLifeCircleEvent_h */

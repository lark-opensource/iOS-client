//
//  ACCCameraServiceNewImpls.m
//  Pods
//
//  Created by liyingpeng on 2020/5/28.
//

#import "ACCCameraServiceNewImpls.h"
#import <CreativeKit/ACCMacros.h>
#import <IESInject/IESInject.h>

#import "ACCFilterWrapper.h"
#import "ACCEffectWrapper.h"
#import "ACCBeautyWrapper.h"
#import "ACCRecorderWrapper.h"
#import "ACCAlgorithmWrapper.h"
#import "ACCMessageWrapper.h"
#import "ACCCameraControlWrapper.h"
#import <CreationKitInfra/ACCDeviceAuth.h>
#import "AWERecordFirstFrameTrackerNew.h"
#import "AWEXScreenAdaptManager.h"
#import "AWECameraPreviewContainerView.h"
#import <CreationKitInfra/ACCRTLProtocol.h>
#import "ACCConfigKeyDefines.h"
#import "ACCCameraFactory.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/UIApplication+ACC.h>

#import "ACCCreativeBrightnessABUtil.h"

@interface ACCCameraServiceNewImpls ()

@property (nonatomic, strong, readwrite) id<VERecorderPublicProtocol> camera;
@property (nonatomic, assign, readwrite) BOOL cameraHasInit; // camera confit complete

@property (nonatomic, strong) ACCCameraSubscription *subscription;
@property (nonatomic, assign) BOOL hasSendDidRenderMsg;
@property (nonatomic, assign) BOOL isCameraCompleted;
@property (nonatomic, assign) BOOL isLoadFinished;
@property (nonatomic, weak) id<IESServiceProvider> serviceResolver;

@end

@implementation ACCCameraServiceNewImpls
@synthesize config = _config;
@synthesize cameraFactory = _cameraFactory;
@synthesize cameraPreviewView = _cameraPreviewView;

@dynamic beauty;
@dynamic filter;
@dynamic effect;
@dynamic recorder;
@dynamic algorithm;
@dynamic message;
@dynamic karaoke;
@dynamic cameraControl;

- (void)configResolver:(id<IESServiceProvider>)resolver {
    _serviceResolver = resolver;
}

- (id<ACCFilterProtocol>)filter {
    id<ACCFilterProtocol> filter = [self.serviceResolver resolveObject:@protocol(ACCFilterProtocol)];
    return filter;
}

- (id<ACCEffectProtocol>)effect {
    id<ACCEffectProtocol> effect = [self.serviceResolver resolveObject:@protocol(ACCEffectProtocol)];
    return effect;
}

- (id<ACCBeautyProtocol>)beauty {
    id<ACCBeautyProtocol> beauty = [self.serviceResolver resolveObject:@protocol(ACCBeautyProtocol)];
    return beauty;
}

- (id<ACCRecorderProtocol>)recorder {
    id<ACCRecorderProtocol> recorder = [self.serviceResolver resolveObject:@protocol(ACCRecorderProtocol)];
    return recorder;
}

- (id<ACCAlgorithmProtocol>)algorithm {
    id<ACCAlgorithmProtocol> algorithm = [self.serviceResolver resolveObject:@protocol(ACCAlgorithmProtocol)];
    return algorithm;
}

- (id<ACCMessageProtocol>)message {
    id<ACCMessageProtocol> message = [self.serviceResolver resolveObject:@protocol(ACCMessageProtocol)];
    return message;
}

- (id<ACCKaraokeProtocol>)karaoke
{
    id<ACCKaraokeProtocol> karaoke = [self.serviceResolver resolveObject:@protocol(ACCKaraokeProtocol)];
    return karaoke;
}

- (id<ACCCameraControlProtocol>)cameraControl {
    id<ACCCameraControlProtocol> control = [self.serviceResolver resolveObject:@protocol(ACCCameraControlProtocol)];
    return control;
}

#pragma mark - getter

- (ACCCameraSubscription *)subscription {
    if (!_subscription) {
        _subscription = [ACCCameraSubscription new];
    }
    return _subscription;
}

#pragma mark - public

- (void)buildCameraIfNeeded {
    if (self.cameraHasInit) {
        return;
    }
    if (![ACCDeviceAuth isCameraAuth]) {
        return;
    }
    [[AWERecordFirstFrameTrackerNew sharedTracker] eventBegin:kAWERecordEventCameraCreate];
    [[AWERecordFirstFrameTrackerNew sharedTracker] eventBegin:kAWERecordEventPostCameraCreate];
    
    @weakify(self);
    self.camera = [self.cameraFactory buildCameraWithContext:ACCCameraVideoRecordContext completionBlock:^{
        @strongify(self);
        [[AWERecordFirstFrameTrackerNew sharedTracker] eventEnd:kAWERecordEventCameraCreate];
        dispatch_async(dispatch_get_main_queue(), ^{
            // make sure self.camera has init
            [self.recorder setIESCameraDurationBlock:^(CGFloat duration, CGFloat totalDuration) {
                @strongify(self);
                [self.subscription performEventSelector:@selector(cameraService:didChangeDuration:totalDuration:) realPerformer:^(id<ACCCameraLifeCircleEvent> handler) {
                    @strongify(self);
                    [handler cameraService:self didChangeDuration:duration totalDuration:totalDuration];
                }];
            }];
            self.isCameraCompleted = YES;
            [self p_handleComleteCamera];
        });
    }];
    // camera is nil when init at background
    if (!self.camera) {
        return;
    }
    self.cameraHasInit = YES;
    self.camera.previewView.userInteractionEnabled = NO;
    self.config = self.camera.config;
    [self bindCameraLifeCircle];
    [[AWERecordFirstFrameTrackerNew sharedTracker] eventEnd:kAWERecordEventPostCameraCreate];
}

- (void)addSubscriber:(id<ACCCameraLifeCircleEvent>)subscriber {
    [self.subscription addSubscriber:subscriber];
}

- (AWECameraPreviewContainerView *)cameraPreviewView
{
    AWECameraPreviewContainerView *preview = self.cameraFactory.cameraPreviewView;
    preview.frame = [self cameraPreviewViewFrame];
    [ACCRTL() setRTLTypeWithView:preview type:ACCRTLViewTypeNormal];
    [self updatePreviewViewOrientation];
    return preview;
}

- (CGRect)cameraPreviewViewFrame
{
    CGRect frame = [UIScreen mainScreen].bounds;
//    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
//        frame = CGRectMake(0, 0, frame.size.height, frame.size.width);
//    } else {
        if ([UIDevice acc_isIPad]) {
            frame = [AWEXScreenAdaptManager customFullFrame];
        } else {
            frame = CGRectMake(0, [AWEXScreenAdaptManager standPlayerFrame].origin.y, frame.size.width, [AWEXScreenAdaptManager standPlayerFrame].size.height);
        }
//    }
    return frame;
}

- (void)markComponentsLoadFinished
{
    self.isLoadFinished = YES;
    [self p_handleComleteCamera];
}

- (void)updatePreviewViewOrientation
{
    if ([self isSplitting]) {
        return;
    }
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

    CGAffineTransform translation = CGAffineTransformIdentity;
    CGFloat angle = 0;
    CGRect frame = [self cameraPreviewViewFrame];
    CGFloat offset = fabs(frame.size.height - frame.size.width) / 2;
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        translation = CGAffineTransformMakeTranslation(-offset, -offset);
        angle = M_PI_2;
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        translation = CGAffineTransformMakeTranslation(offset, offset);
        angle = -M_PI_2;
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        angle = M_PI;
    }
    self.cameraFactory.cameraPreviewView.transform = CGAffineTransformConcat(translation, CGAffineTransformMakeRotation(angle));
    BOOL needRadius = !ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay) &&
    [AWEXScreenAdaptManager needAdaptScreen];
    self.cameraFactory.cameraPreviewView.layer.cornerRadius = needRadius ? 12.0 : 0.0;
    self.cameraFactory.cameraPreviewView.clipsToBounds = YES;
}

- (id)resolveObject:(Protocol *)protocol {
    return [self.serviceResolver resolveObject:protocol];
}

- (BOOL)isSplitting
{
    return !ACC_FLOAT_EQUAL_TO(ACC_SCREEN_WIDTH, [UIScreen mainScreen].bounds.size.width);
}

#pragma mark - private

- (void)p_handleComleteCamera
{
    if (self.isLoadFinished && self.isCameraCompleted) {
        @weakify(self);
        [self.subscription performEventSelector:@selector(onCreateCameraCompleteWithCamera:) realPerformer:^(id<ACCCameraLifeCircleEvent> handler) {
            @strongify(self);
            [handler onCreateCameraCompleteWithCamera:self];
        }];
    }
}

- (void)bindCameraLifeCircle {
    @weakify(self);
    self.camera.IESCameraActionBlock = ^(IESCameraAction action,  NSError * _Nullable error, id data) {
        @strongify(self);
        if (![self p_verifyCameraContext]) {
            return;
        }
        if (action == IESCameraDidFirstFrameRender) {
            [ACCTracker() trackEvent:@"studio_record_vc_first_frame" params:@{}];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.subscription performEventSelector:@selector(cameraService:didTakeAction:error:data:) realPerformer:^(id<ACCCameraLifeCircleEvent> handler) {
                @strongify(self);
                [handler cameraService:self didTakeAction:action error:error data:data];
            }];

            if (action == IESCameraDidStartVideoCapture) {
                [self.subscription performEventSelector:@selector(cameraService:startVideoCaptureWithError:) realPerformer:^(id<ACCCameraLifeCircleEvent> handler) {
                    @strongify(self);
                    [handler cameraService:self startVideoCaptureWithError:error];
                }];
            } else if (action == IESCameraDidStopVideoCapture) {
                [self.subscription performEventSelector:@selector(cameraService:stopVideoCaptureWithError:) realPerformer:^(id<ACCCameraLifeCircleEvent> handler) {
                    @strongify(self);
                    [handler cameraService:self stopVideoCaptureWithError:error];
                }];
            } else if (action == IESCameraDidStartVideoRecord) {
                [self.subscription performEventSelector:@selector(cameraService:startRecordWithError:) realPerformer:^(id<ACCCameraLifeCircleEvent> handler) {
                    @strongify(self);
                    [handler cameraService:self startRecordWithError:error];
                }];
            } else if (action == IESCameraDidPauseVideoRecord) {
                [self.subscription performEventSelector:@selector(cameraService:pauseRecordWithError:) realPerformer:^(id<ACCCameraLifeCircleEvent> handler) {
                    @strongify(self);
                    [handler cameraService:self pauseRecordWithError:error];
                }];
            } else if (action == IESCameraDidRecordReady) {
                [self.subscription performEventSelector:@selector(cameraService:didRecordReadyWithError:) realPerformer:^(id<ACCCameraLifeCircleEvent> handler) {
                    @strongify(self);
                    [handler cameraService:self didRecordReadyWithError:error];
                }];
            } else if (action == IESCameraDidFirstFrameRender) {
                [[ACCCreativeBrightnessABUtil shareBrightnessManager] adjustBrightnessWhenEnterCreationLine];
                if (!self.hasSendDidRenderMsg) {
                    self.hasSendDidRenderMsg = YES;
                    [[AWERecordFirstFrameTrackerNew sharedTracker] eventEnd:kAWERecordEventFirstFrame];
                    [[AWERecordFirstFrameTrackerNew sharedTracker] eventEnd:kAWERecordEventCameraCaptureFirstFrame trackingEndEvent:kAWERecordEventStartCameraCapture];
                    [self.subscription performEventSelector:@selector(onCameraDidStartRender:) realPerformer:^(id<ACCCameraLifeCircleEvent> handler) {
                        @strongify(self);
                        [handler onCameraDidStartRender:self];
                    }];
                }
                [self.subscription performEventSelector:@selector(onCameraFirstFrameDidRender:) realPerformer:^(id<ACCCameraLifeCircleEvent> handler) {
                    @strongify(self);
                    [handler onCameraFirstFrameDidRender:self];
                }];
            } else if (action == IESCameraDidReachMaxTimeVideoRecord) {
                [self.subscription performEventSelector:@selector(cameraService:pauseRecordWithError:) realPerformer:^(id<ACCCameraLifeCircleEvent> handler) {
                    @strongify(self);
                    [handler cameraService:self pauseRecordWithError:error];
                }];
                [self.subscription performEventSelector:@selector(cameraService:didReachMaxTimeVideoRecordWithError:) realPerformer:^(id<ACCCameraLifeCircleEvent> handler) {
                    @strongify(self);
                    [handler cameraService:self didReachMaxTimeVideoRecordWithError:error];
                }];
            }
        });
    };
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

@end

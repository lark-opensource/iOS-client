//
//  MVPCaptureOrientationComponent.m
//  CameraClient
//
//  Created by Me55a on 2022/1/24.
//  Copyright © 2022 chengfei xiao. All rights reserved.
//

#import "MVPCaptureOrientationComponent.h"
#import <CameraClient/ACCRecordFlowService.h>
#import <CameraClient/AWEVideoFragmentInfo.h>
#import <CameraClient/ACCRecorderEvent.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitInfra/ACCResponder.h>
#import "ACCOrientationDetectorCoreMotion.h"

@interface MVPCaptureOrientationComponent () <ACCRecordFlowServiceSubscriber, ACCRecorderEvent, ACCCameraLifeCircleEvent>

@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) ACCOrientationDetectorCoreMotion *orientationDetector;

@end

@implementation MVPCaptureOrientationComponent

IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)

- (instancetype)initWithContext:(id<IESServiceProvider>)context
{
    self = [super initWithContext:context];
    if (self) {
        _orientationDetector = [[ACCOrientationDetectorCoreMotion alloc] init];
    }
    return self;
}

- (void)componentDidMount
{
    // initial set capture ration, otherwise ratio will be auto type, resetCaptureRatio:then method has no effect
    IESMMCaptureRatio captureRatio = IESMMCaptureRatio16_9;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        captureRatio = IESMMCaptureRatio4_3;
    }
    [self.cameraService.cameraControl resetCaptureRatio:captureRatio then:nil];
    [self bindViewModel];
    [self addNotificationObserve];
}

- (void)bindViewModel
{
    @weakify(self);
    [[[RACObserve(self.orientationDetector, orientation) distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable orientationNumber) {
        @strongify(self);
        // component did not mounted, should not change camera output direction
        if (!self.isMounted) {
            return;
        }
        // recorder vc is not top vc, should not change camera output direction
        if ([ACCResponder topViewController] != self.controller.root) {
            return;
        }
        // recorder is in recording state, should not change camera output direction
        if (self.cameraService.recorder.isRecording) {
            return;
        }
        UIDeviceOrientation orientation = [orientationNumber integerValue];
        [self refreshCameraOutputDirection:orientation];
    }];
    
    [self.cameraService.recorder addSubscriber:self];
    [self.cameraService addSubscriber:self];
}

- (void)addNotificationObserve
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(p_handleApplicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(p_handleApplicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.flowService addSubscriber:self];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)componentWillAppear
{
    [self.orientationDetector startDetect];
    // in case orientation changed in other vc,
    // when back to recorder vc, we should refresh with current device orientation
    [self refreshCameraOutputDirectionWithCurrentOrientation];
}

- (void)componentWillDisappear
{
    [self.orientationDetector stopDetect];
}

#pragma mark - Notification Handle

- (void)p_handleApplicationWillResignActiveNotification
{
    [self.orientationDetector stopDetect];
}

- (void)p_handleApplicationDidBecomeActiveNotification
{
    [self.orientationDetector startDetect];
}

#pragma mark - Orientation

- (void)refreshCameraOutputDirectionWithCurrentOrientation
{
    [self refreshCameraOutputDirection:self.orientationDetector.orientation];
}

- (void)refreshCameraOutputDirection:(UIDeviceOrientation)orientation
{
    @weakify(self);
    void(^finishRatioBlock)(void) = ^{
        @strongify(self);
        if ([self.flowService videoSegmentsCount] != 0) {
            return;
        }
        switch (orientation) {
            case UIDeviceOrientationPortrait:
                [self.cameraService.cameraControl setOutputDirection:UIImageOrientationUp];
                break;
            case UIDeviceOrientationLandscapeLeft:
                [self.cameraService.cameraControl setOutputDirection:UIImageOrientationLeft];
                break;
            case UIDeviceOrientationLandscapeRight:
                [self.cameraService.cameraControl setOutputDirection:UIImageOrientationRight];
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                [self.cameraService.cameraControl setOutputDirection:UIImageOrientationDown];
                break;
            default:
                break;
        }
    };
    
    BOOL portrait = (orientation == UIDeviceOrientationPortrait ||
                     orientation == UIDeviceOrientationPortraitUpsideDown);
    IESMMCaptureRatio curratio = self.cameraService.cameraControl.currenCaptureRatio;
    switch (self.cameraService.cameraControl.currenCaptureRatio) {
        case IESMMCaptureRatio9_16:
            curratio = portrait ? IESMMCaptureRatio9_16 : IESMMCaptureRatio16_9;
            break;
        case IESMMCaptureRatio16_9:
            curratio = portrait ? IESMMCaptureRatio16_9 : IESMMCaptureRatio16_9;
            break;
        default:
            break;
    }
    
    [self.cameraService.cameraControl resetCaptureRatio:curratio then:finishRatioBlock];
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceDidAddFragment:(AWEVideoFragmentInfo *)fragment
{
    fragment.captureOrientation = [self.orientationDetector orientation];
}

- (void)flowServiceDidRemoveAllSegment
{
    [self refreshCameraOutputDirectionWithCurrentOrientation];
}

- (void)flowServiceDidRemoveLastSegment:(BOOL)isReactHasMerge
{
    [self refreshCameraOutputDirectionWithCurrentOrientation];
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)onCameraFirstFrameDidRender:(id<ACCCameraService>)cameraService
{
    [self refreshCameraOutputDirectionWithCurrentOrientation];
}

@end

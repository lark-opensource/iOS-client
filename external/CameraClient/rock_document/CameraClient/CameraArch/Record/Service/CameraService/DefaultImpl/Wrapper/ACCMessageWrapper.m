//
//  ACCEffectWrapper.m
//  Pods
//
//  Created by liyingpeng on 2020/6/2.
//

#import "ACCMessageWrapper.h"
#import "ACCMessageFilterable.h"
#import <CreationKitRTProtocol/ACCCameraDefine.h>
#import "ACCCameraFactory.h"
#import <TTVideoEditor/VERecorder.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCMessageWrapper () <ACCCameraBuildListener, ACCMessageFilterable>

@property (nonatomic, weak) id<VERecorderPublicProtocol> camera;
@property (nonatomic, strong) ACCCameraSubscription *subscription;

@end

@implementation ACCMessageWrapper
@synthesize camera = _camera;
@synthesize messageFilter = _messageFilter;

- (void)setCameraProvider:(id<ACCCameraProvider>)cameraProvider {
    [cameraProvider addCameraListener:self];
}

#pragma mark - ACCCameraBuildListener

- (void)onCameraInit:(id<VERecorderPublicProtocol>)camera {
    self.camera = camera;
}

#pragma mark - setter & getter
- (void)setCamera:(id<VERecorderPublicProtocol>)camera {
    _camera = camera;
    [self bindEffectMessage];
}

- (void)bindEffectMessage
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    @weakify(self);
    self.camera.messageHandler = ^(IESMMEffectMessage *message) {
        @strongify(self);

        if (self.messageFilter && ![self.messageFilter shouldTransferMessage:message]) {
            return;
        } else {
            [self.subscription performEventSelector:@selector(onEffectMessageReceived:) realPerformer:^(id<ACCEffectEvent> subscriber) {
                [subscriber onEffectMessageReceived:message];
            }];
        }
    };
}

#pragma mark - private

- (ACCCameraSubscription *)subscription
{
    if (!_subscription) {
        _subscription = [ACCCameraSubscription new];
    }
    return _subscription;
}

- (void)addSubscriber:(id<ACCEffectEvent>)subscriber
{
    [self.subscription addSubscriber:subscriber];
}

#pragma mark -

- (void)sendMessageToEffect:(IESMMEffectMessage *)message
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera sendMessageToEffect:message];
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

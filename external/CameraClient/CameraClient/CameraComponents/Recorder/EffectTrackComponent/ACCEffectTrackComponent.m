//
//  ACCEffectTrackComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/12/14.
//

#import "ACCEffectTrackComponent.h"

#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CameraClient/ACCRecordFlowService.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "ACCEffectTrackViewModel.h"
#import <EffectPlatformSDK/IESEffectModel.h>

static NSString * const kInterfaceValueTrack = @"trackservice";
static NSString * const kInterfaceKey = @"interface";
static const NSInteger kTrackMsgId = 0x29;

@interface ACCEffectTrackComponent ()
<
ACCCameraLifeCircleEvent,
ACCEffectEvent,
ACCRecordFlowServiceSubscriber
>

@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;

@property (nonatomic, strong) ACCEffectTrackViewModel *viewModel;

@end

@implementation ACCEffectTrackComponent

IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)componentDidMount
{
    self.viewModel = [self.modelFactory createViewModel:ACCEffectTrackViewModel.class];
    @weakify(self);
    self.viewModel.currentStickerHandler = ^NSString * _Nonnull{
        @strongify(self);
        return self.cameraService.effect.currentSticker.effectIdentifier;
    };
    
    [self.cameraService.message addSubscriber:self];
    [self.flowService addSubscriber:self];
}

#pragma mark - ACCEffectEvent

- (void)onEffectMessageReceived:(IESMMEffectMessage *)message
{
    AWELogToolInfo(AWELogToolTagNone, @"ACCTrackComponent receive message type=%zi|msgId=%zi", message.type, message.msgId);
    if (message.type == IESMMEffectMsgOther) {
        switch (message.msgId) {
            case kTrackMsgId:
                [self handleArg2:message.arg2 arg3:message.arg3];
                break;
                
            default:
                break;
        }
    }
}

- (void)handleArg2:(NSInteger)arg2 arg3:(NSString *)arg3
{
    NSData *data = [arg3 dataUsingEncoding:NSUTF8StringEncoding];
    if (data) {
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        NSAssert(!error, @"json serialization failed, error=%@", error);
        if (!error && [dict isKindOfClass:NSDictionary.class]) {
            [self handleJson:dict taskId:arg2];
        } else {
            AWELogToolError(AWELogToolTagNone, @"poi component JSON serialization failed, error=%@", error);
        }
    }
}

- (void)handleJson:(NSDictionary *)json taskId:(NSInteger)taskId
{
    NSString *interface = [json acc_stringValueForKey:kInterfaceKey];
    if ([interface isEqualToString:kInterfaceValueTrack]) {
        NSDictionary *body = [json acc_dictionaryValueForKey:@"body"];
        [self handleTrackBody:body taskId:taskId];
    }
}

- (void)handleTrackBody:(NSDictionary *)body taskId:(NSInteger)taskId
{
    AWELogToolInfo(AWELogToolTagNone, @"handleTrackBody|taskId=%zi|body=%@", taskId, body);
    ACCTrackMessageType type = [body acc_integerValueForKey:@"type"];
    if ((type & ACCTrackMessageTypeRecord) != 0) {
        NSString *event = [body acc_stringValueForKey:@"event"];
        NSDictionary *params = [body acc_dictionaryValueForKey:@"params"];
        [self.viewModel trackRecordWithEvent:event params:params];
    }
    
    if (self.cameraService.recorder.recorderState != ACCCameraRecorderStateRecording) {
        AWELogToolWarn(AWELogToolTagNone, @"recorderState is not in recording");
        return;
    }
    
    NSDictionary *params = [body acc_dictionaryValueForKey:@"params"];
    NSAssert(params, @"params is invalid!!!");
    if (params) {
        [self.viewModel updateEffectTrackModelWithParams:params type:type];
    }
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceDidAddFragment:(AWEVideoFragmentInfo *)fragmentInfo
{
    [self.viewModel addFragment:fragmentInfo];
}

- (void)flowServiceStateDidChanged:(ACCRecordFlowState)state preState:(ACCRecordFlowState)preState
{
    AWELogToolDebug(AWELogToolTagNone, @"state=%zi|preState=%zi", state, preState);
    if (state == ACCRecordFlowStatePause ||
        state == ACCRecordFlowStateStop ||
        state == ACCRecordFlowStateFinishExport) {
        [self.viewModel clearTrackParamsCache];
    }
}

@end

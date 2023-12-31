//
//  ACCRecorderReducer.m
//  Pods
//
//  Created by leo on 2019/12/17.
//

#import "ACCRecorderReducer.h"
#import "ACCRecorderState.h"
#import "ACCRecorderAction.h"
/// Recoder status flow.
/// Start Action: ready -> running, pending -> running
/// Pause Action: runnning -> pending
/// Revoke Action: idx--,  if idx == 0 { pending -> pending } else { pending -> ready }
/// Cancel Action: pending -> ready
/// Finish Action: pending -> pending, output video.
/// or @See https://bytedance.feishu.cn/file/boxcntLm1UXkMaIoGoY7j9L3ipe
@implementation ACCRecorderReducer
- (ACCRecorderState *)stateWithAction:(ACCRecorderAction *)action andState:(ACCRecorderState *)state
{
    if (action.status == ACCActionStatusPending) { return state; }
    
    NSAssert([state isKindOfClass:[ACCRecorderState class]], @"ACCRecorderState Only");
    
    ACCRecorderState *newState = [[ACCRecorderState alloc] init];
    [newState mergeValuesForKeysFromModel:state];
    if (action.type == ACCRecorderActionTypeStart) {
        newState.currentIdx = state.currentIdx + 1;
        newState.status = ACCRecorderStatusRunning;
        if ([action.payload isKindOfClass:ACCResult.class]) {
            newState.startResult = action.payload;
        }
    } else if (action.type == ACCRecorderActionTypePause) {
        newState.status = ACCRecorderStatusPending;
        if ([action.payload isKindOfClass:ACCResult.class]) {
            newState.pauseResult = action.payload;
        }
    } else if (action.type == ACCRecorderActionTypeRevoke) {
        newState.currentIdx = MAX(0, state.currentIdx - 1);
        if(newState.currentIdx <= 0) {
            [self resetStatusToReady:newState];
        }
    } else if (action.type == ACCRecorderActionTypeClear) {
        newState.currentIdx = 0;
    } else if (action.type == ACCRecorderActionTypeRevokeAll) {
        [self resetStatusToReady:newState];
    } else if (action.type == ACCRecorderActionTypeCancel) {
        [self resetStatusToReady:newState];
    } else if (action.type == ACCRecorderActionTypeFinish) {
        newState.exportTime = state.exportTime + 1;
        if ([action.payload isKindOfClass:[HTSVideoData class]]) {
            newState.videoResult = [ACCResult success:(HTSVideoData *)action.payload];
        }
        if ([action.payload isKindOfClass:[UIImage class]]) {
            newState.imageResult = [ACCResult success:(UIImage *)action.payload];
        }
        if ([action.payload isKindOfClass:[NSError class]]) {
            newState.imageResult = [ACCResult failure:(NSError *)action.payload];
        }
//        newState.status = state.recordMode == ACCRecorderModeVideo ? ACCRecorderStatusPending : ACCRecorderStatusReady;
        newState.status = ACCRecorderStatusPending;
    } else if (action.type == ACCRecorderActionTypeChangeMode) {
        [self resetStatusToReady:newState];
        newState.recordMode = [action.payload unsignedIntegerValue];
    } else if (action.type == ACCRecorderActionTypeUpdateDuration) {
        if ([action.payload isKindOfClass:NSNumber.class]) {
            newState.totalDuration = [action.payload doubleValue];
        }
    } else if (action.type == ACCRecorderActionTypeExtract) {
        if ([action.payload isKindOfClass:ACCResult.class]) {
            newState.extractResult = action.payload;
        }
    }

    return newState;
}

- (void)resetStatusToReady:(ACCRecorderState *)state
{
    state.status = ACCRecorderStatusReady;
    state.currentIdx = 0;
    state.exportTime = 0;
    state.imageResult = nil;
    state.videoResult = nil;
}

- (Class)domainActionClass
{
    return [ACCRecorderAction class];
}
@end

//
//  ACCRecorderAction.m
//  BDABTestSDK
//
//  Created by leo on 2019/12/17.
//

#import "ACCRecorderAction.h"

@implementation ACCRecorderAction

@end

@implementation ACCRecorderAction (Create)

#pragma mark - Record Control
+ (instancetype)startAction
{
    return [self startActionWithConfig:nil];
}

+ (instancetype)startActionWithConfig:(ACCRecorderConfig *)config
{
    return [self _recordControlActionWithType:ACCRecorderActionTypeStart payload:config];
}

+ (instancetype)pauseAction
{
    return [self _recordControlActionWithType:ACCRecorderActionTypePause payload:nil];
}

+ (instancetype)revokeAction
{
    return [self _recordControlActionWithType:ACCRecorderActionTypeRevoke payload:nil];
}

+ (instancetype)clearAction
{
    return [self _recordControlActionWithType:ACCRecorderActionTypeClear payload:nil];
}

+ (instancetype)revokeAllAction
{
    return [self _recordControlActionWithType:ACCRecorderActionTypeRevokeAll payload:nil];
}

+ (instancetype)finishAction
{
    return [self _recordControlActionWithType:ACCRecorderActionTypeFinish payload:nil];
}

+ (instancetype)cancelAction
{
    return [self _recordControlActionWithType:ACCRecorderActionTypeCancel payload:nil];
}

+ (instancetype)changeModeAction:(ACCRecorderMode)mode
{
    return [self _recordControlActionWithType:ACCRecorderActionTypeChangeMode payload:@(mode)];
}

+ (instancetype)extractAction
{
    return [self _recordControlActionWithType:ACCRecorderActionTypeExtract payload:nil];
}

+ (instancetype)_recordControlActionWithType:(ACCRecorderActionType)type payload:(id)payload
{
    ACCRecorderAction *action = [ACCRecorderAction action];
    action.type = type;
    action.payload = payload;
    return action;
}

@end

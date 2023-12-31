//
//  ACCMusicAction.m
//  CameraClient
//
//  Created by luochaojing on 2019/12/31.
//

#import "ACCMusicAction.h"

@implementation ACCMusicAction

+ (instancetype)applyMusic:(id<ACCMusicStruct>)music
{
    ACCMusicAction *action = [ACCMusicAction action];
    action.type = ACCMusicActionTypeApply;
    action.payload = music;
    return action;
}

+ (instancetype)deleteMusic
{
    ACCMusicAction *action = [ACCMusicAction action];
    action.type = ACCMusicActionTypeDelete;
    return action;
}

+ (instancetype)enableBGM:(BOOL)enable
{
    ACCMusicAction *action = [ACCMusicAction action];
    action.type = ACCMusicActionTypeEnableBGM;
    action.payload = @(enable);
    return action;
}

+ (instancetype)startBGM:(ACCEffectBGMType)type
{
    ACCMusicAction *action = [ACCMusicAction action];
    action.type = ACCMusicActionTypeStartBGM;
    action.payload = @(type);
    return action;
}

+ (instancetype)pauseBGM:(ACCEffectBGMType)type
{
    ACCMusicAction *action = [ACCMusicAction action];
    action.type = ACCMusicActionTypePauseBGM;
    action.payload = @(type);
    return action;
}

@end

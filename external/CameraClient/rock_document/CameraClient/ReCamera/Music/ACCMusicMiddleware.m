//
//  ACCMusicMiddleware.m
//  CameraClient
//
//  Created by Liu Deping on 2020/1/14.
//

#import "ACCMusicMiddleware.h"
#import "ACCMusicAction.h"

@implementation ACCMusicMiddleware

+ (instancetype)middlewareWithCamera:(IESMMRecoder *)camera
{
    ACCMusicMiddleware *middleware = [ACCMusicMiddleware middleware];
    middleware.camera = camera;
    return middleware;
}

- (BOOL)shouldHandleAction:(ACCAction *)action
{
    return [action isKindOfClass:[ACCMusicAction class]];
}

- (ACCAction *)handleAction:(ACCAction *)action next:(ACCActionHandler)next
{
    if ([action isKindOfClass:[ACCMusicAction class]]) {
        [self handleMusicAction:(ACCMusicAction *)action];
    }
    return next(action);
}

- (ACCAction *)handleMusicAction:(ACCMusicAction *)action
{
    if (action.status == ACCActionStatusPending) {
        switch (action.type) {
            case ACCMusicActionTypeApply:{
                if ([action.payload conformsToProtocol:@protocol(ACCMusicStruct)]) {
                    [self applyMusic:action.payload];
                }
                break;
            }
            case ACCMusicActionTypeDelete: {
                [self.camera removePlayer];
                break;
            }
            case ACCMusicActionTypeEnableBGM: {
                if ([action.payload isKindOfClass:[NSNumber class]]) {
                    [self.camera enableBGM:[action.payload boolValue]];
                }
                break;
            }
            case ACCMusicActionTypeStartBGM: {
                if ([action.payload isKindOfClass:[NSNumber class]]) {
                    [self.camera startBGM:[action.payload unsignedIntValue]];
                }
                break;
            }
            case ACCMusicActionTypePauseBGM: {
                if ([action.payload isKindOfClass:[NSNumber class]]) {
                    [self.camera pauseBGM:[action.payload unsignedIntValue]];
                }
                break;
            }
            default:
                break;
        }
    }
    return action;
}

- (void)applyMusic:(id<ACCMusicStruct>)music
{
    NSInteger repeatCount = ceil(music.videoMaxSeconds / music.musicClipLength);
    [self.camera setMusicWithURL:music.cachedURL startTime:music.musicStartTime clipDuration:music.musicClipLength repeatCount:repeatCount];
}

@end

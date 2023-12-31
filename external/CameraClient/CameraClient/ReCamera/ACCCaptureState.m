//
//  ACCCaptureState.m
//  CameraClient
//
//  Created by leo on 2019/12/12.
//

#import <libextobjc/EXTKeyPathCoding.h>
#import "ACCCaptureState.h"


@implementation ACCCaptureState

- (ACCCameraState *)cameraState
{
    return [self.stateTree objectForKey:@keypath(self.cameraState)];
}

- (ACCRecorderState *)recorderState
{
    return [self.stateTree objectForKey:@keypath(self.recorderState)];
}

- (ACCBeautyState *)beautyState {
    return [self.stateTree objectForKey:@keypath(self.beautyState)];
}

- (ACCMusicState *)musicState {
    return [self.stateTree objectForKey:@keypath(self.musicState)];
}

- (ACCAudioState *)audioState {
    return [self.stateTree objectForKey:@keypath(self.audioState)];
}

@end

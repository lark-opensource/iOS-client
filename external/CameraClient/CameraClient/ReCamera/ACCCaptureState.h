//
//  ACCCaptureState.h
//  CameraClient
//
//  Created by leo on 2019/12/12.
//

#import <Foundation/Foundation.h>

#import <CameraClient/ACCState.h>
#import "ACCCameraState.h"
#import "ACCRecorderState.h"
#import "ACCBeautyState.h"
#import "ACCMusicState.h"
#import "ACCAudioState.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCCaptureState : ACCCompositeState<ACCCompositeState>
@property (nonatomic, strong, readonly) ACCRecorderState *recorderState;
@property (nonatomic, strong, readonly) ACCCameraState *cameraState;
@property (nonatomic, strong, readonly) ACCBeautyState *beautyState;
@property (nonatomic, strong, readonly) ACCMusicState *musicState;
@property (nonatomic, strong, readonly) ACCAudioState *audioState;
@end

NS_ASSUME_NONNULL_END

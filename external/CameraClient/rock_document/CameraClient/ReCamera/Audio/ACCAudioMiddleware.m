//
//  ACCAudioMiddleware.m
//  CameraClient
//
//  Created by ZhangYuanming on 2020/1/8.
//

#import "ACCAudioMiddleware.h"
#import "ACCAudioAction.h"
#import <TTVideoEditor/IESMMCamera.h>
#import <TTVideoEditor/IESMMRecoderProtocol.h>

@interface ACCAudioMiddleware()

@property (nonatomic, weak) IESMMCamera<IESMMRecoderProtocol> *camera;

@end

@implementation ACCAudioMiddleware

+ (ACCAudioMiddleware *)middlewareWithCamera:(IESMMCamera<IESMMRecoderProtocol> *)camera {
    ACCAudioMiddleware *middleware = [[ACCAudioMiddleware alloc] init];
    middleware.camera = camera;
    return middleware;
}

#pragma mark - Override

- (BOOL)shouldHandleAction:(ACCAction *)action
{
    return [action isKindOfClass:[ACCAudioAction class]];
}

- (ACCAction *)handleAction:(ACCAction *)action next:(nonnull ACCActionHandler)next
{
    if ([action isKindOfClass:[ACCAudioAction class]]) {
        [self handleAudioAction:(ACCAudioAction *)action];
    }
    return next(action);
}

- (ACCAction *)handleAudioAction:(ACCAudioAction *)action
{
    ACCAudioActionType type = (ACCAudioActionType)action.type;
    switch (type) {
        case ACCAudioActionTypeStartCapture: {
            [_camera startAudioCapture];
            break;
        }
        case ACCAudioActionTypeStopCapture: {
            [_camera stopAudioCapture];
            break;
        }
    }
    return action;
}

@end

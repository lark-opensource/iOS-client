//
//  ACCAudioAction.m
//  CameraClient
//
//  Created by ZhangYuanming on 2020/1/8.
//

#import "ACCAudioAction.h"

@implementation ACCAudioAction

+ (instancetype)startCapture
{
    ACCAudioAction *action = [ACCAudioAction action];
    action.type = ACCAudioActionTypeStartCapture;
    return action;
}

+ (instancetype)stopCapture
{
    ACCAudioAction *action = [ACCAudioAction action];
    action.type = ACCAudioActionTypeStopCapture;
    return action;
}

@end

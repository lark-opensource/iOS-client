//
//  ACCTrackerUtility.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/4/21.
//

#import "ACCTrackerUtility.h"
 
NSString * _Nonnull ACCDevicePositionStringify(AVCaptureDevicePosition p)
{
    NSString *cameraPostionIdentifier = @"unknown";
    switch (p) {
        case AVCaptureDevicePositionFront:
            cameraPostionIdentifier = @"front";
            break;
        case AVCaptureDevicePositionBack:
            cameraPostionIdentifier = @"back";
            break;
        default:
            cameraPostionIdentifier = @"unknown";
            break;
    }
    return cameraPostionIdentifier;
}


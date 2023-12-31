//
//  ACCTrackerUtility.h
//  CameraClient-Pods-Aweme
//
//  Created by Yuan Xin on 2021/4/20.
//

#import <AVFoundation/AVCaptureDevice.h>

//===========================================================================
//  @description  a handy method that converts AVCaptureDevicePosition type into
//                 correspondent NSString 
//===========================================================================
UIKIT_EXTERN NSString * _Nonnull ACCDevicePositionStringify(AVCaptureDevicePosition p);

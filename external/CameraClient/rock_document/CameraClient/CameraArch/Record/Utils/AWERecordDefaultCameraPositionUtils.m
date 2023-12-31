//
//  AWERecordDefaultCameraPositionUtils.m
//  Pods
//
//  Created by 郝一鹏 on 2019/8/14.
//

#import "AWERecordDefaultCameraPositionUtils.h"
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCMacros.h>

NSString * const HTSVideoDefaultDevicePostionKey = @"HTSVideoDefaultDevicePostionKey";

static AVCaptureDevicePosition _devicePosition = AVCaptureDevicePositionUnspecified;

@interface AWERecordDefaultCameraPositionUtils ()

@property (nonatomic, assign, class) AVCaptureDevicePosition devicePosition;

@end

@implementation AWERecordDefaultCameraPositionUtils

+ (void)setDefaultPosition:(AVCaptureDevicePosition)position
{
    self.devicePosition = position;
    [ACCCache() setInteger:position forKey:HTSVideoDefaultDevicePostionKey];
}

+ (AVCaptureDevicePosition)defaultPosition
{
    if (self.devicePosition != AVCaptureDevicePositionUnspecified) {
        ACCLog(@"======== 1 camera default position is %@ ========",@(self.devicePosition));
        return self.devicePosition;
    }

    NSNumber *storedKey = [ACCCache() objectForKey:HTSVideoDefaultDevicePostionKey];
    if (storedKey != nil) {
        self.devicePosition = [storedKey integerValue];
    } else {
        NSArray *videoDeviceArray = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        if (videoDeviceArray.count == 1) {
            AVCaptureDevice *device = [videoDeviceArray firstObject];
            self.devicePosition = device.position;
        } else {
            self.devicePosition = AVCaptureDevicePositionFront;
        }
    }
    ACCLog(@"======== 2 camera default position is %@ ========", @(self.devicePosition));
    return self.devicePosition;
}

#pragma mark - class property

+ (AVCaptureDevicePosition)devicePosition {
    return _devicePosition;
}

+ (void)setDevicePosition:(AVCaptureDevicePosition)devicePosition
{
    _devicePosition = devicePosition;
}

@end

//
//  AWERecordDefaultCameraPositionUtils.h
//  Pods
//
//  Created by 郝一鹏 on 2019/8/14.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVCaptureDevice.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const HTSVideoDefaultDevicePostionKey;

@interface AWERecordDefaultCameraPositionUtils : NSObject

+ (void)setDefaultPosition:(AVCaptureDevicePosition)position;
+ (AVCaptureDevicePosition)defaultPosition;

@end

NS_ASSUME_NONNULL_END

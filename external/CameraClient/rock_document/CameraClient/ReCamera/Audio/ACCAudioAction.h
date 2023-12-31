//
//  ACCAudioAction.h
//  CameraClient
//
//  Created by ZhangYuanming on 2020/1/8.
//

#import <CameraClient/ACCAction.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, ACCAudioActionType) {
    ACCAudioActionTypeStartCapture,
    ACCAudioActionTypeStopCapture
};

@interface ACCAudioAction : ACCAction

+ (instancetype)startCapture;
+ (instancetype)stopCapture;

@end

NS_ASSUME_NONNULL_END

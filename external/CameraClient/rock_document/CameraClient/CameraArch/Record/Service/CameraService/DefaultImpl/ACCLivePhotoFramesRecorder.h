//
//  ACCLivePhotoFramesRecorder.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/7/18.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import "ACCRecorderLivePhotoProtocol.h"


NS_ASSUME_NONNULL_BEGIN

/// LivePhoto的录制，内部是定时采集序列帧实现的
@interface ACCLivePhotoFramesRecorder : NSObject

/// 配置信息
@property (nonatomic, copy, readonly) id<ACCLivePhotoConfigProtocol> config;

/// 是否正在录制
@property (nonatomic, assign, getter=isRunning, readonly) BOOL running;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithConfig:(id<ACCLivePhotoConfigProtocol>)config;

/// 开始录制
/// @param recorder recorder服务
/// @param progress 进度回调
/// @param completion 录制结束回调
- (void)startWithRecorder:(id<ACCRecorderProtocol>)recorder
                 progress:(void(^ _Nullable)(NSTimeInterval currentDuration))progress
               completion:(void(^ _Nullable)(id<ACCLivePhotoResultProtocol> _Nullable data, NSError * _Nullable error))completion;

@end


@interface ACCLivePhotoConfig : NSObject <ACCLivePhotoConfigProtocol>

@end


@interface ACCLivePhotoResult : NSObject <ACCLivePhotoResultProtocol>

@end

NS_ASSUME_NONNULL_END

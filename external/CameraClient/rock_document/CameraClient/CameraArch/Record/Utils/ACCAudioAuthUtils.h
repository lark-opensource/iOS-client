//
//  ACCAudioAuthUtils.h
//  CameraClient-Pods-Aweme
//
//  Created by Zhihao Zhang on 2020/7/13.
//

#import <Foundation/Foundation.h>

/*
 规则1：录制中进行音频采集，暂停录制时不采集
 规则2：特殊道具需要暂停录制时采集音频提供效果 此优先级低于规则3
 规则3：带有显式麦克风的场景,可手动选择 开启或者关闭音频采集来进行录制 表现为 videoMuted = YES 代表关闭音频
 规则4：一些特殊场景下需要保证VE运行正确 如纯音频录制、K歌
 目前优先级 音频模式 > 用户手动控制的麦克风 > 音频道具
 */

NS_ASSUME_NONNULL_BEGIN
@protocol ACCPublishRepository;

@interface ACCAudioAuthUtils : NSObject

/**
 @brief 一个不太明确场景的老接口  外部业务存量使用中不好清理  请勿新增使用 ❎❎❎
 */
+ (BOOL)shouldStartAudio:(id<ACCPublishRepository>)repository;


/**
 @brief 暂停录制、结束录制时是否应该调用关闭采集
 */

+ (BOOL)shouldStopAudioCaptureWhenPause:(id<ACCPublishRepository>)repository;

/**
 @brief 存在需要开启音频的道具时候需要进行的判断方法
 */
+ (BOOL)shouldStartAudioCaptureWhenApplyProp:(id<ACCPublishRepository>)repository;

@end

NS_ASSUME_NONNULL_END

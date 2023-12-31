//
//  BDXVideoDefines.h
//  BDXElement
//
//  Created by yuanyiyang on 2020/4/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDXVideoPlayState) {
    BDXVideoPlayStatePlay = 0,
    BDXVideoPlayStateStop = 1,
    BDXVideoPlayStatePause = 2,
};

typedef NS_ENUM(NSUInteger, BDXVideoPlaybackAction) {
    /**
     *  停止播放(只调一次，包括手动或自动停止)，将会重置播放器，重新启动将会等同于新建一个播放器
     */
    BDXVideoPlaybackActionStop = 0,
    /**
     *  开始播放(在stop之前只调一次)，用作首帧时间(prepare_time)的统一口径
     *  实际含义：(自研)自研官方首帧回调，实际测试中与开始播放基本一致，时间差<10ms
                (系统)系统播放器实际播放时间点，播放状态从stop->play的状态变化
     */
    BDXVideoPlaybackActionStart,
    /**
     *  从手动暂停到播放状态
     */
    BDXVideoPlaybackActionResume,
    /**
     *  从播放状态到手动暂停
     */
    BDXVideoPlaybackActionPause,
};

typedef NSString * BDXVideoEvent;

FOUNDATION_EXPORT BDXVideoEvent const BDXVideoPlayEvent;
FOUNDATION_EXPORT BDXVideoEvent const BDXVideoPauseEvent;
FOUNDATION_EXPORT BDXVideoEvent const BDXVideoEndedEvent;
FOUNDATION_EXPORT BDXVideoEvent const BDXVideoErrorEvent;
FOUNDATION_EXPORT BDXVideoEvent const BDXVideoTimeUpdateEvent;
FOUNDATION_EXPORT BDXVideoEvent const BDXVideoFullscreenChangeEvent;
FOUNDATION_EXPORT BDXVideoEvent const BDXVideoBufferingEvent;
FOUNDATION_EXPORT BDXVideoEvent const BDXVideoDeviceChangeEvent;
FOUNDATION_EXPORT BDXVideoEvent const BDXVideoSeekEvent;
FOUNDATION_EXPORT BDXVideoEvent const BDXVideoSeekBeginEvent;
FOUNDATION_EXPORT BDXVideoEvent const BDXVideoSeekChangeEvent;
FOUNDATION_EXPORT BDXVideoEvent const BDXVideoSeekEndEvent;
FOUNDATION_EXPORT BDXVideoEvent const BDXVideoStateChangeEvent;


NS_ASSUME_NONNULL_END

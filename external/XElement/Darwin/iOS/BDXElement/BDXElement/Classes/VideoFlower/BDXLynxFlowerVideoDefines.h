// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef BDXLynxFlowerVideoDefines_h
#define BDXLynxFlowerVideoDefines_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BDXLynxFlowerVideoPlayState) {
  BDXLynxFlowerVideoPlayStatePlay = 0,
  BDXLynxFlowerVideoPlayStateStop = 1,
  BDXLynxFlowerVideoPlayStatePause = 2,
};

typedef NS_ENUM(NSUInteger, BDXLynxFlowerVideoPlaybackAction) {
  /**
   *  停止播放(只调一次，包括手动或自动停止)，将会重置播放器，重新启动将会等同于新建一个播放器
   */
  BDXLynxFlowerVideoPlaybackActionStop = 0,
  /**
   *  开始播放(在stop之前只调一次)，用作首帧时间(prepare_time)的统一口径
   *  实际含义：(自研)自研官方首帧回调，实际测试中与开始播放基本一致，时间差<10ms
              (系统)系统播放器实际播放时间点，播放状态从stop->play的状态变化
   */
  BDXLynxFlowerVideoPlaybackActionStart,
  /**
   *  从手动暂停到播放状态
   */
  BDXLynxFlowerVideoPlaybackActionResume,
  /**
   *  从播放状态到手动暂停
   */
  BDXLynxFlowerVideoPlaybackActionPause,
};

typedef NS_ENUM(NSUInteger, BDXLynxFlowerVideoError) {
  // 【code】  【含义】                    【message】            【客户端工程文案】
  /// 3       等待上传                    审核中，视频暂时无法播放     转码中，视频暂时无法播放
  BDXLynxFlowerVideoErrorWaitForUploading = 3,
  /// 4       上传成功                    审核中，视频暂时无法播放     转码中，视频暂时无法播放
  BDXLynxFlowerVideoErrorUploadSucceed = 4,
  /// 10      转码成功(可播放)             success，视频可正常播放     无（客户端不展示）
  BDXLynxFlowerVideoErrorSucceed = 10,
  /// 20      转码失败                    审核中，视频暂时无法播放     转码中，视频暂时无法播放
  BDXLynxFlowerVideoErrorEncodeFailed = 20,
  /// 30      转码进行中                  审核中，视频暂时无法播放     转码中，视频暂时无法播放
  BDXLynxFlowerVideoErrorEncoding = 30,
  /// 40      不存在                     审核中，视频暂时无法播放     视频已删除，无法播放
  BDXLynxFlowerVideoErrorNotExist = 40,
  /// 1000    转码成功，未审核或未生产文章      审核中，视频暂时无法播放 转码中，视频暂时无法播放
  BDXLynxFlowerVideoErrorNotAudited = 1000,
  /// 1002    转码成功，视频删除              未通过审核，视频无法播放     视频已删除，无法播放
  BDXLynxFlowerVideoErrorDeleted = 1002,
};

typedef NSString* BDXLynxFlowerVideoEvent;

FOUNDATION_EXPORT BDXLynxFlowerVideoEvent const BDXLynxFlowerVideoPlayEvent;
FOUNDATION_EXPORT BDXLynxFlowerVideoEvent const BDXLynxFlowerVideoPauseEvent;
FOUNDATION_EXPORT BDXLynxFlowerVideoEvent const BDXLynxFlowerVideoEndedEvent;
FOUNDATION_EXPORT BDXLynxFlowerVideoEvent const BDXLynxFlowerVideoErrorEvent;
FOUNDATION_EXPORT BDXLynxFlowerVideoEvent const BDXLynxFlowerVideoTimeUpdateEvent;
FOUNDATION_EXPORT BDXLynxFlowerVideoEvent const BDXLynxFlowerVideoFullscreenChangeEvent;
FOUNDATION_EXPORT BDXLynxFlowerVideoEvent const BDXLynxFlowerVideoBufferingEvent;
FOUNDATION_EXPORT BDXLynxFlowerVideoEvent const BDXLynxFlowerVideoDeviceChangeEvent;
FOUNDATION_EXPORT BDXLynxFlowerVideoEvent const BDXLynxFlowerVideoSeekEvent;
FOUNDATION_EXPORT BDXLynxFlowerVideoEvent const BDXLynxFlowerVideoSeekBeginEvent;
FOUNDATION_EXPORT BDXLynxFlowerVideoEvent const BDXLynxFlowerVideoSeekChangeEvent;
FOUNDATION_EXPORT BDXLynxFlowerVideoEvent const BDXLynxFlowerVideoSeekEndEvent;

#endif /* BDXLynxFlowerVideoDefines_h */

//
//  DVEPlayerServiceProtocol.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DVEFoundationKit/DVECommonDefine.h>
#import <TTVideoEditor/IESMMBaseDefine.h>
#import <TTVideoEditor/IESMMVideoDataClipRange.h>
#import <TTVideoEditor/IESMMKeyFrameInfo.h>

NS_ASSUME_NONNULL_BEGIN

@class HTSVideoData, NLEInterface_OC;

@protocol DVEPlayerServiceProtocol <NSObject>

// only called when autoRepeated is NO
@property (nonatomic, copy) dispatch_block_t playerCompleteBlock;

@property (nonatomic, copy) dispatch_block_t playerAutoRepeatBlock;

@property (nonatomic, copy) void (^playerTimerBlock)(CGFloat seconds);

/// 编辑的时候，playerunit的播放时间，可以KVO
@property (nonatomic, assign) NSTimeInterval currentPlayerTime;

@property (nonatomic, assign) NSTimeInterval needPausePlayerTime;

// 播放器的状态，可监听
@property (nonatomic, assign) DVEPlayerStatus status;

// 是否播放完成
@property (nonatomic, assign) BOOL isPlayComplete;

- (void)setVideoDataChangBlock:(dispatch_block_t)videoDataChangBlock;

- (void)setPlayerTimeChangBlock:(dispatch_block_t)timeChangChangBlock;

- (void)setPlayerStatuseChangBlock:(dispatch_block_t)statuseChangBlock;

- (void)updateCurVideoDataWithCompleteBlock:(void (^)(NSError *_Nullable error))completeBlock;

- (void)play;

- (void)pause;

- (void)playFrom:(CMTime)start
        duration:(NSTimeInterval)lenth
   completeBlock:(dispatch_block_t _Nullable)completeBlock;

- (void)seekToTime:(CMTime)time
          isSmooth:(BOOL)isSmooth;

- (void)seekToTime:(CMTime)time
          isSmooth:(BOOL)isSmooth
 completionHandler:(void (^_Nullable)(BOOL finished))completionHandler;

- (BOOL)isPlaying;

- (NSTimeInterval)updateVideoDuration;

- (void)updateVideoData:(HTSVideoData *)data
          completeBlock:(void(^)(NSError * _Nullable error)) complete;

- (void)updateSpeedWithAsset:(AVAsset *)asset
                     ToScale:(CGFloat)speed;

- (void)getProcessedPreviewImageAtTime:(NSTimeInterval)atTime
                         preferredSize:(CGSize)size
                           compeletion:(void (^)(UIImage *image, NSTimeInterval atTime))compeletion;

/// 返回视频最后播放时刻和总时长的最大偏差
- (CGFloat)maxSecondsOffsetForEndPlayTimeWithTotalDuration;

@end

NS_ASSUME_NONNULL_END

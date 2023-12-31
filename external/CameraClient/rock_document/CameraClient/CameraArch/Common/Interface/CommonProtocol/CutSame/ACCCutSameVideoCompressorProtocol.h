//
//  ACCCutSameVideoCompressor.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/20.
//

#import <Foundation/Foundation.h>
#import "ACCCutSameVideoCompressConfigProtocol.h"
#import <AVFoundation/AVFoundation.h>
 
NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCCutSameVideoCompressProgress)(CGFloat);
typedef void(^ACCCutSameVideoCompressCompletion)(AVURLAsset  *_Nullable, NSError *_Nullable);

@protocol ACCCutSameVideoCompressorProtocol <NSObject>

/**
 取消当前压缩队列里所有的任务
 */
- (void)cancelAllTasks;

/**
 压缩视频
 @param asset 视频
 @param config 压缩策略
 @param progressHandler 进度回调
 @param completion 完成回调
 */
- (void)compressAsset:(AVURLAsset *)asset
           withConfig:(id<ACCCutSameVideoCompressConfigProtocol>)config
      progressHandler:(ACCCutSameVideoCompressProgress _Nullable)progressHandler
           completion:(ACCCutSameVideoCompressCompletion _Nullable)completion;

@end

@protocol ACCMVCutSameStyleVideoCompressorProtocol <ACCCutSameVideoCompressorProtocol>

@end

NS_ASSUME_NONNULL_END

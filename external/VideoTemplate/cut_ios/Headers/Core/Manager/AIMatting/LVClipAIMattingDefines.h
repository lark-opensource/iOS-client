//
//  LVClipAIMattingDefines.h
//  VideoTemplate
//
//  Created by wuweixin on 2020/12/9.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LVMediaAsset.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const LVClipAIMattingErrorDomain;
typedef NS_ENUM(NSUInteger, LVClipAIMattingErrorCode) {
    LVClipAIMattingErrorCodeUnknown = 0,
    LVClipAIMattingErrorCodeAlgorithmsNotReady = 30000,
    LVClipAIMattingErrorCodeMattingPathWasEmpty = 30001,
};


typedef NS_ENUM(NSUInteger, LVClipAIMattingStatus) {
    LVClipAIMattingStatusIdle = 0,
    LVClipAIMattingStatusPending = 1,
    LVClipAIMattingStatusRunning = 2,
    LVClipAIMattingStatusSuccess = 3,
    LVClipAIMattingStatusFailure = 4,
    LVClipAIMattingStatusCancel  = 5,
    LVClipAIMattingStatusDirty   = 6, //过期，数据有变化
};

/**
 智能抠像进度
 */
@interface LVClipAIMattingProgress : NSObject
@property (nonatomic, assign) NSUInteger totalFrames;
@property (nonatomic, assign) NSUInteger completedFrames;
@property (nonatomic, assign, readonly) CGFloat progress;
@end

/**
 智能抠像记录
 */
@interface LVClipAIMattingRecord : NSObject
@property (nonatomic, copy, nullable) NSString *segmentID;
@property (nonatomic, strong) LVMediaAsset *clipAsset;
@property (nonatomic, copy) NSString *mattingPath;
@property (nonatomic, strong) LVClipAIMattingProgress *progress;
@property (nonatomic, assign) LVClipAIMattingStatus status;

// MARK: - 统计
@property (nonatomic, assign) NSTimeInterval costTimeRecentFrame; // 最近一帧花费的时间
@property (nonatomic, assign, readonly) NSTimeInterval totalCostTime; // 花费的总时间
@property (nonatomic, assign, readonly) NSTimeInterval averageArithmeticCostTimePerFrame; // 算法平均花费的时间
@property (nonatomic, assign, readonly) NSTimeInterval averageBusinessCostTimePerFrame; // 业务平均花费的时间

@property (nonatomic, readonly) BOOL isPending;
@property (nonatomic, readonly) BOOL isRunning;
@property (nonatomic, readonly) BOOL isPendingOrRunning;
@property (nonatomic, readonly) BOOL isSuccess;

- (BOOL)canStartMatting;
- (void)resetProgress;

- (void)beginTracking;
- (void)pauseTracking;
- (void)endTracking;

- (NSString *)trackingTimeDescription;
@end

@protocol LVClipAIMattingResultPrototype <NSObject>
@required
//已经抠图的数量
@property (nonatomic, assign, readonly) NSUInteger mattingedFrame;
//当前Clip需要抠图的总数量
@property (nonatomic, assign, readonly) NSUInteger allMattingFrames;
//当前这个Clip是否抠图完成
@property (nonatomic, assign, readonly) BOOL isFinished;
//需要抠图的AVAsset
@property (nonatomic, strong, readonly) AVAsset *asset;
//抠图中的单帧耗时和抠图完成后的平均耗时
@property (nonatomic, assign, readonly) CGFloat mattingCostTime;

@property (nonatomic, strong, readonly) NSError *error;
@end

typedef void(^LVClipAIMattingResultCallback)(id<LVClipAIMattingResultPrototype> result);
typedef void(^LVClipAIMattingOperationStatusHandler)(BOOL success);
@protocol LVClipAIMattingProxy <NSObject>
@required
- (void)startAIMatting:(LVClipAIMattingRecord *)record
         statusHandler:(LVClipAIMattingOperationStatusHandler)statusHandler
        resultCallback:(LVClipAIMattingResultCallback)resultCallback;
- (void)pauseAIMatting:(LVClipAIMattingRecord *)record
         statusHandler:(LVClipAIMattingOperationStatusHandler)statusHandler;
- (void)cancelAIMatting:(LVClipAIMattingRecord *)record
          statusHandler:(LVClipAIMattingOperationStatusHandler)statusHandler;
@end


@interface NSError (LVClipAIMatting)

+ (NSError *)lv_aiMattingErrorWithCode:(LVClipAIMattingErrorCode)code userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)userInfo;
+ (NSError *)lv_aiMattingErrorWithCode:(LVClipAIMattingErrorCode)code localizedDescription:(NSString *)localizedDescription;

@end

NS_ASSUME_NONNULL_END

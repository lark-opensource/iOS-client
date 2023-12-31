//
//  LVVEAiMattingManager.h
//  VideoTemplate
//
//  Created by wuweixin on 2020/11/24.
//

#import <Foundation/Foundation.h>
#import "LVVEAIMattingFileManager.h"
#import "LVAIMattingCache.h"
#import <AVFoundation/AVFoundation.h>
#import "LVMediaAsset.h"
#import "LVClipAIMattingDefines.h"
#import "LVAIMattingAlgorithmsManager.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN

@class LVAIMattingManager;
@protocol LVAIMattingManagerDelegate <NSObject>
@optional
- (void)aiMattingManager:(LVAIMattingManager *)manager didUpdateProgressWithRecord:(LVClipAIMattingRecord *)record;

- (void)aiMattingManager:(LVAIMattingManager *)manager didSuccessWithRecord:(LVClipAIMattingRecord *)record;
- (void)aiMattingManager:(LVAIMattingManager *)manager didFailureWithError:(NSError *)error forRecord:(LVClipAIMattingRecord *)record;
- (void)aiMattingManager:(LVAIMattingManager *)manager didCancelWithRecord:(LVClipAIMattingRecord *)record;
- (void)aiMattingManagerDidFinish:(LVAIMattingManager *)manager;
- (void)aiMattingManagerDidFailure:(LVAIMattingManager *)manager;
- (void)aiMattingManagerDidCancel:(LVAIMattingManager *)manager;
- (void)aiMattingManagerStatusDidChange:(LVAIMattingManager *)manager;
- (void)aiMattingManagerFunctionDisabled:(LVAIMattingManager *)manager;
@end

typedef void(^LVAIMattingCompletion)(LVAIMattingManager *manager, LVClipAIMattingStatus status);
typedef BOOL(^LVAIMattingAIMattingFunctionEnableFetcher)(void);

@interface LVAIMattingManager : NSObject

@property (nonatomic, weak) id<LVAIMattingManagerDelegate> delegate;
@property (nonatomic, copy, nullable) LVAIMattingCompletion completion;
@property (nonatomic, strong, readonly) LVVEAIMattingFileManager *fileManager;
@property (nonatomic, strong, readonly) LVAIMattingCache *cache;
@property (nonatomic, strong, readonly) LVAIMattingAlgorithmsManager *algorithmsManager;
@property (nonatomic, assign, readonly, getter=isPendingOrRunning) BOOL pendingOrRunning;
@property (nonatomic, assign, readonly, getter=isRunningActually) BOOL runningActually;
@property (nonatomic, assign, readonly) CGFloat currentProgress;
@property (nonatomic, assign, readonly) BOOL isAIMattingFunctionEnabled; // 是否启用智能抠图功能

+ (void)setAIMattingFunctionEnableFetcher:(LVAIMattingAIMattingFunctionEnableFetcher)fetcher;

- (instancetype)initWithProxy:(id<LVClipAIMattingProxy>)proxy;
/// 计算缓存大小
+ (unsigned long long)calculateAllCacheFileSize;
+ (void)cleanAllCacheFiles;

@end

@interface LVAIMattingManager (Basic)
- (void)startMattingWithClipAsset:(LVMediaAsset *)clipAsset;
- (void)pauseAIMattingAsset:(AVAsset *)asset;
- (void)cancelAIMattingAsset:(AVAsset *)asset;
/// 暂停所有的任务
- (void)pause;
/// 取消所有的任务
- (void)cancel;
@end

@class LVMediaSegment;
@interface LVAIMattingManager (Segment)

- (LVClipAIMattingRecord * _Nullable)recordForSegmentID:(NSString *)segmentID;

- (BOOL)canStartMattingWithSegmentID:(NSString *)segmentID;
- (BOOL)isMattingRunningWithSegmentID:(NSString *)segmentID;

- (void)startAIMattingWithSegmentID:(NSString *)segmentID asset:(LVMediaAsset *)asset;
- (void)pauseAIMattingWithSegmentID:(NSString *)segmentID asset:(LVMediaAsset *)asset;
- (void)cancelAIMattingWithSegmentID:(NSString *)segmentID asset:(LVMediaAsset *)asset;

- (void)startAIMattingSegment:(LVMediaSegment *)segment;
- (void)pauseAIMattingSegment:(LVMediaSegment *)segment;
- (void)cancelAIMattingSegment:(LVMediaSegment *)segment;
@end

@class LVVEAIMattingDataItem;
@class LVVEAIMattingSyncDataItem;
@interface LVAIMattingManager (Sync)
- (void)syncAIMattingWithDataItems:(NSArray<LVVEAIMattingSyncDataItem *> *)dataItems;
- (void)removeAIMattingIfNeededWithDataItems:(NSArray<LVVEAIMattingSyncDataItem *> *)dataItems;
@end

@interface LVVEAIMattingDataItem : NSObject
@property (nonatomic, copy) NSString *segmentID;
@property (nonatomic, strong) LVMediaAsset *mediaAsset;
@property (nonatomic, assign, getter=isMatting) BOOL matting;
@end

@interface LVVEAIMattingSyncDataItem : LVVEAIMattingDataItem
@property (nonatomic, assign, getter=isMatting) BOOL matting;
@end

NS_ASSUME_NONNULL_END

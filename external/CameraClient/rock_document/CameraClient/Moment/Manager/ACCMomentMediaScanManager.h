//
//  ACCMomentMediaScanManager.h
//  Pods
//
//  Created by Pinka on 2020/5/14.
//

#import <Foundation/Foundation.h>
#import "ACCMomentMediaAsset.h"

@class PHAsset;
@class ACCMomentMediaDataProvider;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSInteger const ACCMomentMediaScanDefaultOperationCount;

typedef NS_ENUM(NSInteger, ACCMomentMediaScanManagerCompleteState) {
    ACCMomentMediaScanManagerCompleteState_HasMore,
    ACCMomentMediaScanManagerCompleteState_AllCompleted,
    ACCMomentMediaScanManagerCompleteState_Canceled,
    ACCMomentMediaScanManagerCompleteState_BeReplaced,
    ACCMomentMediaScanManagerCompleteState_Fail
};

typedef void(^ACCMomentMediaScanManagerCompletion)(ACCMomentMediaScanManagerCompleteState state, ACCMomentMediaAsset * _Nullable lastAsset, NSError * _Nullable error);

typedef NS_ENUM(NSInteger, ACCMomentMediaScanManagerScanState) {
    ACCMomentMediaScanManagerScanState_Idle,
    ACCMomentMediaScanManagerScanState_ForegroundScanning,
    ACCMomentMediaScanManagerScanState_ForegroundScanPaused,
    ACCMomentMediaScanManagerScanState_BackgroundScanning,
    ACCMomentMediaScanManagerScanState_BackgroundScanPaused,
};

FOUNDATION_EXTERN NSInteger const ACCMomentMediaScanDefaultOperationCount;

@class PHAsset;

typedef BOOL(^ACCMomentMediaScanManagerAssetFilter)(PHAsset *asset);

@interface ACCMomentMediaScanManager : NSObject

/// Multi-Thread Optimize, Default is YES
@property (nonatomic, assign) BOOL multiThreadOptimize;

@property (nonatomic, assign, readonly) ACCMomentMediaScanManagerScanState state;

@property (nonatomic, copy) NSArray<NSNumber *> *crops;

@property (nonatomic, copy) ACCMomentMediaScanManagerAssetFilter assetFilter;

@property (nonatomic, assign) NSInteger scanQueueOperationCount;

@property (nonatomic, strong, readonly) ACCMomentMediaDataProvider *dataProvider;

@property (nonatomic, assign) NSUInteger scanLimitCount;

@property (nonatomic, assign) CGFloat scanRedundancyScale;

+ (instancetype)shareInstance;

- (void)startForegroundScanWithPerCallbackCount:(NSUInteger)perCallbackCount
                                    needAllScan:(BOOL)needAllScan
                                     completion:(ACCMomentMediaScanManagerCompletion)completion;

- (void)startBackgroundScanWithCompletion:(ACCMomentMediaScanManagerCompletion)completion;

- (void)stopScan;

- (void)pauseScan;

- (void)resumeScan;

- (void)processResultCleanWithCompletion:(ACCMomentMediaScanManagerCompletion)completion;

- (void)clearDatas;

#pragma mark - Debug Methods
- (void)setSuperParams:(int64_t)superParams;

@end

NS_ASSUME_NONNULL_END

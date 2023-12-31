//
//  CJPayHybridPerformanceMonitor.h
//  Pods
//
//  Created by wangxinhua on 2022/10/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, CJPayHybridPerformanceStage) {
    CJPayHybridPerformanceStageCallAPI,
    CJPayHybridPerformanceStageInitFinished,
    CJPayHybridPerformanceStageStartLoadURL,
    CJPayHybridPerformanceStagePageStarted,
    CJPayHybridPerformanceStagePageFinished,
};

@interface CJPayHybridPerformanceModel : NSObject

@property (nonatomic, assign) NSTimeInterval callAPITime;
@property (nonatomic, assign) NSTimeInterval createFinishdedTime;
@property (nonatomic, assign) NSTimeInterval startLoadURLTime;
@property (nonatomic, assign) NSTimeInterval pageStartedTime;
@property (nonatomic, assign) NSTimeInterval pageLoadFinishedTime;

- (long)hybridContainerPrepareTime;
- (long)hybridContainerCreatedFinishedTime;
- (long)hybridStartURLLoadTime;
- (long)hybridPageStartedTime;
- (long)hybridPageLoadFinishedTime;

@end

@interface CJPayHybridPerformanceMonitor : NSObject

@property (nonatomic, strong, readonly) CJPayHybridPerformanceModel *performanceModel;
@property (nonatomic, copy) NSString *kernelTypeStr;

- (instancetype)initWith:(NSString *)urlStr;
- (instancetype)initWith:(NSString *)urlStr callAPITime:(NSTimeInterval)callAPITime;


/// 记录各个节点发生的时间戳
/// - Parameters:
///   - stage: 当前节点
///   - timeStamp: 当前时间戳，如果为0，则获取当前时间戳
- (void)trackPerformanceStage:(CJPayHybridPerformanceStage)stage defaultTimeStamp:(NSTimeInterval)timeStamp;

@end

NS_ASSUME_NONNULL_END

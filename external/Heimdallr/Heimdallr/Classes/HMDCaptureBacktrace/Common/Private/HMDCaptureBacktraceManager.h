//
//  HMDCaptureBacktraceManager.h
//  AWECloudCommand
//
//  Created by maniackk on 2020/10/21.
//

#import <Foundation/Foundation.h>

@class HMDThreadBacktrace;

NS_ASSUME_NONNULL_BEGIN

@interface HMDCaptureBacktraceManager : NSObject

@property(nonatomic, assign)NSInteger backtraceThreshold;
@property(nonatomic, assign)NSInteger errorTime;
@property(nonatomic, copy)NSString *sceneType;

- (void)addBacktrace:(HMDThreadBacktrace *)backtrace;
- (void)finishRecord:(BOOL)uploadData withReportBlock:(void (^)(void))block;
- (NSArray *)CaptureBacktracesReportData;

@end

NS_ASSUME_NONNULL_END

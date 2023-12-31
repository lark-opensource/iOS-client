//
//  HMDNetTrafficFreqRequestTool.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/10/23.
//

#import <Foundation/Foundation.h>

@class HMDNetTrafficSourceUsageModel;

NS_ASSUME_NONNULL_BEGIN

@interface HMDNetTrafficFreqRequestTool : NSObject

@property (nonatomic, assign) NSInteger frequencyThreashold;
@property (nonatomic, assign) long long anchorTS;

- (HMDNetTrafficSourceUsageModel * _Nullable)cachedSourceInfoWithKey:(NSString *)key;
- (NSArray <HMDNetTrafficSourceUsageModel *> * _Nullable)dumpHighFrequencyUsageWithThreshold:(NSInteger)threshold;
- (void)cacheSourceUsageInfo:(HMDNetTrafficSourceUsageModel * _Nonnull)usageInfo;
- (void)cleanCache;

@end

NS_ASSUME_NONNULL_END

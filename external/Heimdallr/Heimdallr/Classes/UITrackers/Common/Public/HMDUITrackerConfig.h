//
//  HMDUITrackerConfig.h
//  BDAlogProtocol
//
//  Created by 刘诗彬 on 2018/12/19.
//

#import "HMDModuleConfig.h"

extern NSString *_Nonnull const kHMDModuleUITracker;//UI交互监控

@interface HMDUITrackerConfig : HMDModuleConfig

@property (nonatomic, assign) NSInteger flushCount;
@property (nonatomic, assign) double flushInterval;
@property (nonatomic, assign) NSInteger maxUploadCount;
@property (nonatomic, assign) NSUInteger recentAccessScenesLimit;//记录用户最后访问页面的上限
@property (nonatomic, assign) BOOL ISASwizzleOptimization;

@end


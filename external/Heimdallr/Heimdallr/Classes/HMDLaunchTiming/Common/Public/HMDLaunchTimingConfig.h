//
//  HMDLaunchAnalysisConfig.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/5/27.
//

#import "HMDModuleConfig.h"


extern NSString *const kHMDModuleLaunchAnalysis;//启动时间监控


@interface HMDLaunchTimingConfig : HMDModuleConfig

@property (nonatomic, assign) BOOL enableCollectPerf;
@property (nonatomic, assign) BOOL enableCollectNet;

@end


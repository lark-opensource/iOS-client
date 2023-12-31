//
//  HMDStartDetectorConfig.h
//  BDAlogProtocol
//
//  Created by 刘诗彬 on 2018/12/19.
//

#import "HMDModuleConfig.h"
extern NSString *const kHMDModuleStartDetector;//启动时间监控

@interface HMDStartDetectorConfig : HMDModuleConfig

@property (nonatomic, assign)BOOL detectCPPInitializer;
@property (nonatomic, assign)BOOL detectLoad;

@end

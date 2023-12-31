//
//  HMDControllerTimingConfig.h
//  BDAlogProtocol
//
//  Created by 刘诗彬 on 2018/12/19.
//

#import "HMDModuleConfig.h"

extern NSString * _Nonnull const kHMDModuleControllerTracker;//页面加载时间监控

@interface HMDControllerTimingConfig : HMDModuleConfig

@property (nonatomic, assign) float flushInterval;
@property (nonatomic, assign) NSInteger flushCount;

@end


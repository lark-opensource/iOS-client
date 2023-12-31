//
//  HMDOTConfig.h
//  Pods
//
//  Created by fengyadong on 2019/12/12.
//

#import <Foundation/Foundation.h>
#import "HMDModuleConfig.h"

extern NSString * _Nonnull const kHMDModuleOpenTracingTracker;//tracing监控

@interface HMDOTConfig : HMDModuleConfig

@property (nonatomic, strong, nullable) NSDictionary *allowServiceList;
@property (nonatomic, strong, nullable) NSDictionary *allowErrorList;

@end


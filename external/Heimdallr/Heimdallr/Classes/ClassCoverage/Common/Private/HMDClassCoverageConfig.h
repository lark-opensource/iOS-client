//
//  HMDClassCoverageConfig.h
//  Pods
//
//  Created by kilroy on 2020/6/8.
//

#import <Foundation/Foundation.h>
#import "HMDModuleConfig.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kHMDModuleClassCoverage;//线上Class Coverage监控

@interface HMDClassCoverageConfig : HMDModuleConfig

@property (nonatomic, assign) NSTimeInterval checkInterval;//客户端定时遍历所有类的时间间隔，默认2min
@property (nonatomic, assign) BOOL wifiOnly;//仅在Wifi环境下上报文件
@property (nonatomic, assign) NSUInteger devicePerformanceLevelThreshold;//支持开启的设备性能等级的阈值（即等级>=此阈值），默认2，不包括iPhone6s之前设备。设备性能等级定义见：HMDInfo+DeviceInfo.h

@end

NS_ASSUME_NONNULL_END

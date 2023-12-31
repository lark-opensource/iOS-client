//
//  HMDLaunchAnalyseConfig.h
//  AWECloudCommand
//
//  Created by maniackk on 2020/9/10.
//

#import "HMDModuleConfig.h"


@interface HMDLaunchAnalyseConfig : HMDModuleConfig

extern NSString *const kHMDModuleLaunchAnalyse; //获取启动堆栈

@property (nonatomic, assign) NSInteger maxCollectTime;  //单位：秒， 最大的采集时间，超过停止采集，并丢弃已采集堆栈；默认20s
@property (nonatomic, assign) NSInteger maxErrorTime;  //单位：毫秒，最大的误差时间，超过此误差时间丢弃已采集堆栈；默认500ms

@end


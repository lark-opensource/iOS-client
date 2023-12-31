//
//  HMDGWPASanConfig.h
//  AWECloudCommand
//
//  Created by maniackk on 2021/9/16.
//

#import <Foundation/Foundation.h>
#import "HMDModuleConfig.h"


extern NSString * _Nullable const kHMDModuleGWPASan;

@interface HMDGWPASanConfig : HMDModuleConfig

//最大同时分配的个数，默认1024，极端情况消耗16MB内存;如果isOpenDebugMode为true，则该参数无意义；MaxMapAllocationsDebugMode参数生效
//最大可配置131072，极端情况消耗2GB内存
@property (nonatomic, assign) uint32_t MaxSimultaneousAllocations;

//采样率 1/SampleRate，默认1000
@property (nonatomic, assign) uint32_t SampleRate;

// 是否开启线下模块，默认NO；开启后，会通过磁盘方式来监控更多的内存分配
@property (nonatomic, assign) BOOL isOpenDebugMode;

// 如果isOpenDebugMode为true，这个参数才有意义，否则MaxSimultaneousAllocations生效；
//32768对应映射1GB文件，默认是：设备RAM小于1G，这个功能不会被开启；小于2G，映射1G文件，小于3G，映射1.5G文件，大于3G，映射4G文件
@property (nonatomic, assign) uint32_t MaxMapAllocationsDebugMode;

// 是否使用新版本 GWPAsan
@property (nonatomic, assign) BOOL useNewGWPAsan;

// 是否在发生 Asan 后进行 CoreDump
@property (nonatomic, assign) BOOL coredumpIfAsan;

@end


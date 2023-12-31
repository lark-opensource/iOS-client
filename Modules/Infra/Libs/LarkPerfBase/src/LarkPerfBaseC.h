//
//  LarkPerfBaseC.h
//  LarkPerfBase
//
//  Created by ByteDance on 2023/3/9.
//

#import <Foundation/Foundation.h>
#import <mach/mach.h>

NS_ASSUME_NONNULL_BEGIN

kern_return_t lark_powerlog_device_cpu_load(host_cpu_load_info_t cpu_load);
//获取设备CPU计数
host_cpu_load_info_data_t lark_perfbase_device_cpu(void);
//计算设备CPU值
double lark_perfbase_device_cpu_cal(host_cpu_load_info_data_t begin,host_cpu_load_info_data_t end);

NS_ASSUME_NONNULL_END

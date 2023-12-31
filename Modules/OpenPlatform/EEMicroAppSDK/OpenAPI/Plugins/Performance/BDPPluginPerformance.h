//
//  BDPPluginPerformance.h
//  TTMicroApp
//
//  Created by yinyuan.0 on 2019/3/11.
//

#import <Foundation/Foundation.h>
#import <TTMicroApp/BDPPluginBase.h>

@interface BDPPluginPerformance : BDPPluginBase

/// 获取性能打点数据
BDP_EXPORT_HANDLER(getPerformance)

@end

//
//  BDPPluginPerformance.m
//  TTMicroApp
//
//  Created by yinyuan.0 on 2019/3/11.
//

#import "BDPPluginPerformance.h"
#import <TTMicroApp/BDPAppPageController.h>
#import <TTMicroApp/BDPAppController.h>
#import <TTMicroApp/BDPFPSMonitor.h>
#import <TTMicroApp/BDPCPUMonitor.h>
#import <TTMicroApp/BDPMemoryMonitor.h>
#import <TTMicroApp/BDPTaskManager.h>

@implementation BDPPluginPerformance

/// 获取性能打点数据
- (void)getPerformanceWithParam:(NSDictionary *)param callback:(BDPJSBridgeCallback)callback engine:(BDPJSBridgeEngine)engine controller:(UIViewController *)controller {
    OPAPICallback *apiCallback = BDP_API_CALLBACK;
    controller = [BDPAppController currentAppPageController:controller fixForPopover:false];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];

    CGFloat fps = BDPFPSMonitor.fps;
    float cpuUsage = BDPCPUMonitor.cpuUsage;
    CGFloat usedMemoryInB = BDPMemoryMonitor.currentMemoryUsageInBytes;
    NSDictionary *performanceData = @{@"cpu":@(cpuUsage/100.f), @"fps":@(fps), @"memory":@(usedMemoryInB/(1024*1024))};
    [data addEntriesFromDictionary:performanceData];

    NSMutableDictionary *timing = [NSMutableDictionary dictionary];
    data[@"timing"] = timing;

    NSMutableArray *performanceArray = [NSMutableArray array];

    if ([controller isKindOfClass:[BDPAppPageController class]]) {
        BDPAppPageController *vc = (BDPAppPageController *)controller;
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:engine.uniqueID];
        if(task.performanceMonitor) [performanceArray addObject:task.performanceMonitor];
        /**
        if (task.context.performanceMonitor) {
            [performanceArray addObject:task.context.performanceMonitor];
        }
         */
        if(vc.performanceMonitor) [performanceArray addObject:vc.performanceMonitor];
        if(vc.appPage.bwv_performanceMonitor) [performanceArray addObject:vc.appPage.bwv_performanceMonitor];
    }

    for (BDPPerformanceMonitor *manager in performanceArray) {
        id timingData = manager.timingData;
        if (timingData) [timing addEntriesFromDictionary:timingData];
        id performanceData = manager.performanceData;
        if (performanceData) [data addEntriesFromDictionary:performanceData];
    }

    apiCallback.addMap(data).invokeSuccess();
}

@end

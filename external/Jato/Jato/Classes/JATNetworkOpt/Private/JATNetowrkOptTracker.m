//
//  JATNetowrkOptTracker.m
//  TikTok
//
//  Created by zhangxiao on 2022/8/9.
//

#import "JATNetowrkOptTracker.h"
#import <Heimdallr/HMDTTMonitor.h>

NSString *const JATNetworkOptPathSwitchThreadCheckCost = @"jat_network_opt_path_switch_thread_check_cost";
NSString *const JATNetworkOptTaskExecuteWaitCost = @"jat_network_opt_task_execute_wait_cost";

@implementation JATNetowrkOptTracker

- (void)trackerService:(NSString *)service metric:(NSDictionary<NSString *,NSNumber *> *)metric {
    if (service) {
        [[HMDTTMonitor defaultManager] hmdTrackService:service metric:metric category:nil extra:nil];
    }
}

@end

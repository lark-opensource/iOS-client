//
//  HMDNetTrafficMonitor+NetworkCollect.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/2/25.
//

#import "HMDNetTrafficMonitor+NetworkCollect.h"
#import "HMDTTNetPushTrafficCollector.h"
#import "HMDNetworkTrafficCollector.h"

@implementation HMDNetTrafficMonitor (NetworkCollect)

- (void)switchNetworkCollectStatus:(BOOL)isOn {
    HMDNetworkTrafficCollector *networkCollector = [HMDNetworkTrafficCollector sharedInstance];
    if (networkCollector.isRunning == isOn) { return; }
    if (isOn) {
        [networkCollector start];
    } else {
        [networkCollector stop];
    }
}

- (void)switchTTPushCollectStatus:(BOOL)isOn {
    HMDTTNetPushTrafficCollector *pushCollector = [HMDTTNetPushTrafficCollector sharedInstance];
    if (pushCollector.isRunning == isOn) { return; }
    if (isOn) {
        [pushCollector start];
    } else {
        [pushCollector stop];
    }
}

@end

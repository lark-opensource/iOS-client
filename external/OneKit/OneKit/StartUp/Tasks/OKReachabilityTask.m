//
//  OKReachabilityTask.m
//  OKStartUp
//
//  Created by bob on 2020/1/15.
//

#import "OKReachabilityTask.h"
#import "OKStartUpFunction.h"
#import "OKReachability.h"

OKAppTaskAddFunction() {
    [[OKReachabilityTask new] scheduleTask];
}

@implementation OKReachabilityTask

- (void)startWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    [[OKReachability sharedInstance] startNotifier];
}

@end

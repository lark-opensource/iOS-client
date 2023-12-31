//
//  HMDInjectedInfo+NetworkSchedule.m
//  Heimdallr
//
//  Created by 王佳乐 on 2019/4/17.
//

#import "HMDInjectedInfo+NetworkSchedule.h"
#import <objc/runtime.h>
NSString * const kHMDNetworkScheduleNotification = @"kHMDNetworkScheduleNotification";

@implementation HMDInjectedInfo (NetworkSchedule)

- (NSNumber *)disableNetworkRequest {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setDisableNetworkRequest:(NSNumber *)disableNetworkRequest {
    BOOL last = [self.disableNetworkRequest boolValue];
    objc_setAssociatedObject(self, @selector(disableNetworkRequest), disableNetworkRequest, OBJC_ASSOCIATION_RETAIN);
    if (last && ![disableNetworkRequest boolValue]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kHMDNetworkScheduleNotification object:nil];
    }
}

@end

//
//  HMDTTNetPushMonitor.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/12/28.
//

#import "HMDTTNetPushTrafficCollector.h"
#import "HMDDynamicCall.h"
#import "HMDALogProtocol.h"
#import "HMDTracker.h"
#import "NSDictionary+HMDSafe.h"

// hard code ttnet push info name string to compatibly older TTNetwork version.
static NSString *const kHMDTTNetPushMonitorNotiName = @"kTTPushManagerOnTrafficChanged";
static NSString *const kHMDTTNetPushMonitorNotiUserInfoUrl = @"kTTPushManagerOnTrafficChangedUserInfoKeyURL";
static NSString *const kHMDTTNetPushMonitorNotiUserInfoSentBytes = @"kTTPushManagerOnTrafficChangedUserInfoKeySentBytes";
static NSString *const kHMDTTNetPushMonitorNotiUserInfoReceivedBytes = @"kTTPushManagerOnTrafficChangedUserInfoKeyReceivedBytes";

static NSString *const kHMDTTNetPushMonitorBussinessName = @"ttnet_push";

@interface HMDTTNetPushTrafficCollector ()

@property (atomic, assign, readwrite) BOOL isRunning;

@end

@implementation HMDTTNetPushTrafficCollector

+ (instancetype)sharedInstance {
    static HMDTTNetPushTrafficCollector *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDTTNetPushTrafficCollector alloc] init];
    });
    return instance;
}

- (void)dealloc {
    if (self.isRunning) {
        [self unregisterTTNetPushNotification];
    }
}

- (void)start {
    if (!self.isRunning) {
        self.isRunning = YES;
        [self registerTTNetPushNotification];
    }
}

- (void)stop {
    if (self.isRunning) {
        self.isRunning = NO;
        [self unregisterTTNetPushNotification];
    }
}

- (void)registerTTNetPushNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTrafficChanged:) name:kHMDTTNetPushMonitorNotiName object:nil];
}

- (void)unregisterTTNetPushNotification {
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kHMDTTNetPushMonitorNotiName object:nil];
    } @catch (NSException *exception) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDTTNetPushMonitor remove notification exception: %@", exception.description);
        }
    }
}

- (void)handleTrafficChanged:(NSNotification *)notification {
    NSString *url = [[notification.userInfo hmd_objectForKey:kHMDTTNetPushMonitorNotiUserInfoUrl class:[NSString class]] copy];
    if (!url) { return; }
    int64_t sentBytes = [notification.userInfo hmd_longLongForKey:kHMDTTNetPushMonitorNotiUserInfoSentBytes];
    int64_t receivedBytes = [notification.userInfo hmd_longLongForKey:kHMDTTNetPushMonitorNotiUserInfoReceivedBytes];
    if (url) {
        [HMDTracker asyncActionOnTrackerQueue:^{
            DC_OB(DC_CL(HMDNetTrafficMonitor, sharedMonitor), networkTrafficUsageWithURL:sendBytes:recvBytes:clientType:MIMEType:, url, sentBytes, receivedBytes, kHMDTTNetPushMonitorBussinessName, @"");
        }];

    }
}

@end

//
//  HMDNetConnectionTypeWatch.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/3/1.
//

#import "HMDTTNetQualityHelper.h"
#import "hmd_section_data_utility.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import "HMDALogProtocol.h"
#import "NSDictionary+HMDSafe.h"

HMD_LOCAL_MODULE_CONFIG(HMDNetConnectionTypeWatch)

@interface HMDTTNetQualityHelper ()

@property (atomic, assign) BOOL isRunning;
@property (atomic, assign) NSInteger netQualityCode;

@end

@implementation HMDTTNetQualityHelper

#pragma mark --- life cycle
+ (instancetype)sharedInstance {
    static HMDTTNetQualityHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDTTNetQualityHelper alloc] init];
    });
    return instance;
}

- (void)start {
    if (!self.isRunning) {
        self.isRunning = YES;
        [self activelyGetCurrentNetConnectType];
        [self registerNetConnectionTypeNotification];
    }
}

- (void)stop {
    if (self.isRunning) {
        self.isRunning = NO;
        [self unregisterNetConnectionTypeNotification];
    }
}

- (void)dealloc {
    if (self.isRunning) {
        [self unregisterNetConnectionTypeNotification];
    }
}

- (void)activelyGetCurrentNetConnectType {
    TTNetEffectiveConnectionType netType = [[TTNetworkManager shareInstance] getEffectiveConnectionType];
    self.netQualityCode = [self mapTTNetConnectionTypeToStandardCode:netType];
    [self sentNetConnectionTypeChange];
}

- (void)sentNetConnectionTypeChange {
    if (self.delegate && [self.delegate respondsToSelector:@selector(hmdCurrentNetQualityDidChange:)]) {
        [self.delegate hmdCurrentNetQualityDidChange:self.netQualityCode];
    }
}

- (void)registerQualityDelegate:(id<HMDNetQualityProtocol>)delegate {
    self.delegate = delegate;
    //While first register delegate,sent once netQualityCode for update delegate current netQuality
    [self sentNetConnectionTypeChange];
}

#pragma mark --- observer net connection type
- (void)registerNetConnectionTypeNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNetConnectionTypeChange:) name:kTTNetConnectionTypeNotification object:nil];
}


- (void)unregisterNetConnectionTypeNotification {
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kTTNetConnectionTypeNotification object:nil];
    } @catch (NSException *exception) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"remove kTTNetConnectionTypeNotification exception");
        }
    }
}

- (void)recieveNetConnectionTypeChange:(NSNotification *)notification {
    NSInteger connectionType = [notification.userInfo hmd_integerForKey:@"connection_type"];
    self.netQualityCode = [self mapTTNetConnectionTypeToStandardCode:connectionType];
    [self sentNetConnectionTypeChange];
}

#pragma mark --- map type code
// android and ios is defferent; map current type to the appointed code
- (NSInteger)mapTTNetConnectionTypeToStandardCode:(TTNetEffectiveConnectionType)connectionType {
    NSInteger standardCode = -1;
    switch (connectionType) {
        case EFFECTIVE_CONNECTION_TYPE_UNKNOWN:
            standardCode = 0;
            break;
        case EFFECTIVE_CONNECTION_TYPE_OFFLINE:
            standardCode = 1;
            break;
        case EFFECTIVE_CONNECTION_TYPE_SLOW_2G:
            standardCode = 2;
            break;
        case EFFECTIVE_CONNECTION_TYPE_2G:
            standardCode = 3;
            break;
        case EFFECTIVE_CONNECTION_TYPE_3G:
            standardCode = 4;
            break;
        case EFFECTIVE_CONNECTION_TYPE_SLOW_4G:
            standardCode = 5;
            break;
        case EFFECTIVE_CONNECTION_TYPE_MODERATE_4G:
            standardCode = 6;
            break;
        case EFFECTIVE_CONNECTION_TYPE_GOOD_4G:
            standardCode = 7;
            break;
        case EFFECTIVE_CONNECTION_TYPE_EXCELLENT_4G:
            standardCode = 8;
            break;
        case EFFECTIVE_CONNECTION_TYPE_LAST:
            standardCode = 9;
            break;
        default:
            break;
    }

    return standardCode;
}

@end

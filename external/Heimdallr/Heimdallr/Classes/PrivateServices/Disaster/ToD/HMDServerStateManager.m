//
//  HMDServerStateManager.m
//  Heimdallr
//
//  Created by wangyinhui on 2021/11/18.
//

#import "HMDServerStateManager.h"
// Utility
#import "HMDMacro.h"
#import "HMDUserDefaults.h"
#import "HMDThreadSafeDictionary.h"
#import "NSDictionary+HMDSafe.h"
// DeviceInfo
#import "HMDInjectedInfo.h"

@interface HMDServerStateManager ()

@property (nonatomic, strong) HMDThreadSafeDictionary *hmdServerCheckers;
@property (nonatomic, copy) NSString * _Nullable defaultAppID;

@end

@implementation HMDServerStateManager

+ (instancetype)shared {
    static HMDServerStateManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HMDServerStateManager alloc] init];
        [manager getAppID];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _hmdServerCheckers = [HMDThreadSafeDictionary dictionaryWithCapacity:2];
    }
    return self;
}

- (HMDServerStateChecker *)getServerChecker:(HMDReporter)reporter {
    return [self getServerChecker:reporter forApp:self.defaultAppID];
}

- (HMDServerStateChecker *)getServerChecker:(HMDReporter)reporter forApp:(NSString *)aid {
    NSString *appID = aid;
    if (HMDIsEmptyString(appID)) {
        if (!self.defaultAppID || self.defaultAppID.intValue == 0) {
            [self getAppID];
        }
        appID = self.defaultAppID;
    }
    // 未传入 aid，且无法获取 hostAppID，则无法正常创建对应的 ServerChecker
    if (HMDIsEmptyString(appID)) {
        return nil;
    }
    NSString *serverCheckerKey = [NSString stringWithFormat:@"server_checker_%tu_%@", reporter, appID];
    if ([self.hmdServerCheckers hmd_hasKey:serverCheckerKey]) {
        return [self.hmdServerCheckers objectForKey:serverCheckerKey];
    } else {
        HMDServerStateChecker *checker = [HMDServerStateChecker stateCheckerWithReporter:reporter forApp:appID];
        [self.hmdServerCheckers setObject:checker forKey:serverCheckerKey];
        return checker;
    }
}

static NSString * const HMDServerStateManagerAppID = @"HMDServerStateManagerAppID";

- (void)getAppID {
    NSString *appID = [HMDInjectedInfo defaultInfo].appID;
    if (appID && appID.intValue != 0) {
        [[HMDUserDefaults standardUserDefaults] setObject:appID forKey:HMDServerStateManagerAppID];
    } else {
        NSString *userDefaultAppID = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:HMDServerStateManagerAppID];
        if (!HMDIsEmptyString(userDefaultAppID)) {
            appID = userDefaultAppID;
        }
    }
    self.defaultAppID = appID;
}

@end

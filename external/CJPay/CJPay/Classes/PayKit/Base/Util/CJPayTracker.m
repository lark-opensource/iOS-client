//
//  CJPayTracker.m
//  CJPay
//
//  Created by 王新华 on 2019/2/12.
//

#import "CJPayTracker.h"
#import "CJPaySDKMacro.h"
#import "CJSDKParamConfig.h"
#import "CJPayRequestParam.h"
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import "CJPayCommonUtil.h"

@interface CJPayTracker()

@property (nonatomic, copy) NSHashTable *trackerDels;
@property (nonatomic, strong) NSMutableDictionary *mutableCommonDic;
@property (nonatomic, assign) pthread_mutex_t mutexLock;
@property (nonatomic, copy) NSString *latestActionHash;

@end

@implementation CJPayTracker

+ (instancetype)shared {
    static CJPayTracker *tracker;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tracker = [[CJPayTracker alloc] init];
    });
    return tracker;
}

- (instancetype)init {
    self = [super init];
    if(self) {
        pthread_mutex_init(&_mutexLock, NULL);
    }
    return self;
}
+ (NSDictionary *)p_commonTrackDic {
    CJPayTracker *instance = [self shared];
    if (instance.mutableCommonDic) {
        return [instance.mutableCommonDic copy];
    }
    return @{};
}

+ (void)addCommonTrackDic:(NSDictionary *)commonTrackDic {
    CJPayTracker *instance = [self shared];
    if (!instance.mutableCommonDic) {
        instance.mutableCommonDic = [NSMutableDictionary new];
    }
    [instance.mutableCommonDic addEntriesFromDictionary:commonTrackDic];
}



- (NSHashTable *)trackerDels {
    if (!_trackerDels) {
        _trackerDels = [NSHashTable weakObjectsHashTable] ;
    }
    return _trackerDels;
}

+ (void)event:(NSString *)event params:(NSDictionary *)params {
    NSDictionary *baseParam = @{
        @"app" : CJPayAppName,
        @"os_name" : @"iOS",
        @"app_platform" : @"native",
        @"cjpay_sdk_version" : CJString([CJSDKParamConfig defaultConfig].version),
        @"params_for_special" : @"tppp",
        @"aid" : CJString([CJPayRequestParam gAppInfoConfig].appId),
        @"font_size": @(1.0), // 如果传入了commonTrack，会替换该值
        @"host_version_code": CJString([CJPayRequestParam appVersion]),
        @"host_update_version_code": CJString([UIApplication btd_bundleVersion])
    };
    
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc] initWithDictionary:baseParam];
    if (Check_ValidString([CJPayTracker shared].latestActionHash)) {
        NSString *actionStr = [[CJPayTracker shared].latestActionHash stringByAppendingString:event];
        NSString *clientAcHash = [[CJPayCommonUtil createMD5With:actionStr] substringToIndex:16];
        [CJPayTracker shared].latestActionHash = clientAcHash;
        [paramsDic addEntriesFromDictionary:@{@"client_ac_hash":clientAcHash}];
    } else {
        NSString *clientAcHash = [[CJPayCommonUtil createMD5With:event] substringToIndex:16];
        [CJPayTracker shared].latestActionHash = clientAcHash;
        [paramsDic addEntriesFromDictionary:@{@"client_ac_hash":clientAcHash}];
    }
    
    [paramsDic addEntriesFromDictionary:[self p_commonTrackDic]];
    
    [paramsDic addEntriesFromDictionary:params];
    if ([CJPayTracker trackerCls] && ![[CJPayTracker shared] hasValidTrackerDelegate]) {//如果没有TTTracker、BDTrackerSDK，且没有代理则走Protocol上报
        [BDTrackerProtocol eventV3:event params:paramsDic];
    } else { //代理上报
        pthread_mutex_t mutexLock = [CJPayTracker shared].mutexLock;
        pthread_mutex_lock(&mutexLock);
        NSArray<id<CJPayManagerBizDelegate>> * configDelegates = [[[CJPayTracker shared].trackerDels allObjects] copy];
        pthread_mutex_unlock(&mutexLock);
        if (configDelegates && configDelegates.count > 0) {
            [configDelegates enumerateObjectsUsingBlock:^(id<CJPayManagerBizDelegate>  _Nonnull trackDelegate, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([trackDelegate respondsToSelector:@selector(event:params:)]) {
                    [trackDelegate event:event params:paramsDic];
                }
            }];
        }
    }
    CJPayLogInfo(@"Tracker: event = %@, params = %@", event, params);
}

// 从BDTrackerProtocol copy过来，用来判断是否有打点SDK
+ (Class)trackerCls {
    static Class cls = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cls = NSClassFromString(@"TTTracker") ?: NSClassFromString(@"BDTrackerSDK");
    });
    
    return cls;
}

- (void)setTrackerDelegate:(id<CJPayManagerBizDelegate>)trackerDelegate {
    [self removeTrackerDelegate:_trackerDelegate];
    _trackerDelegate = trackerDelegate;
    [self addTrackerDelegate:trackerDelegate];
}

- (BOOL)hasValidTrackerDelegate {
    BOOL hasValidDelegate = NO;
    pthread_mutex_lock(&_mutexLock);
    hasValidDelegate = self.trackerDels.count > 0;
    pthread_mutex_unlock(&_mutexLock);
    return hasValidDelegate;
}

- (void)addTrackerDelegate:(id<CJPayManagerBizDelegate>)trackerDelegate {
    pthread_mutex_lock(&_mutexLock);
    [self.trackerDels addObject:trackerDelegate];
    pthread_mutex_unlock(&_mutexLock);
}

- (void)removeTrackerDelegate:(id<CJPayManagerBizDelegate>)trackerDelegate {
    pthread_mutex_lock(&_mutexLock);
    [self.trackerDels removeObject:trackerDelegate];
    pthread_mutex_unlock(&_mutexLock);
}


@end

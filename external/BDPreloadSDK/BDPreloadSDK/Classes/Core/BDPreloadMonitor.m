//
//  BDPreloadMonitor.m
//  BDPreloadSDK
//
//  Created by wealong on 2019/8/22.
//

#import "BDPreloadMonitor.h"
#import "BDPreloadUtil.h"

#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <BDAlogProtocol/BDAlogProtocol.h>

static NSString * const kBDPreloadWiFiKey = @"kBDPreloadWiFiKey";
static NSString * const kBDPreloadFlowKey = @"kBDPreloadFlowKey";

@interface BDPreloadTrackInfo : NSObject

@property (assign, nonatomic) BOOL isWiFi;
@property (strong, nonatomic) NSString *preloadKey;
@property (strong, nonatomic) NSString *scene;
@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) NSDictionary *extra;
@property (assign, nonatomic) long long trafficSize;
@property (assign, nonatomic) NSTimeInterval enqueueTime;
@property (assign, nonatomic) NSTimeInterval startTime;
@property (assign, nonatomic) NSTimeInterval finishTime;
@property (assign, nonatomic) BDPreloadType  type;

- (NSDictionary *)reportParams;

@end

@implementation BDPreloadTrackInfo

- (NSDictionary *)reportParams {
    NSMutableDictionary *reportParams = [self.extra ?: @{} mutableCopy];
    reportParams[@"preload_size"] = @(self.trafficSize);
    reportParams[@"preload_scene"] = self.scene;
    reportParams[@"preload_wifi"] = @(self.isWiFi);
    reportParams[@"preload_key"] = self.preloadKey;
    NSTimeInterval waitTime = (self.startTime - self.enqueueTime) * 1000;
    NSTimeInterval runTime  = (self.finishTime - self.startTime) * 1000;
    reportParams[@"preload_wait_time"] = @(waitTime);
    reportParams[@"preload_run_time"] = @(runTime);
    reportParams[@"preload_type"] = @(self.type);
    if (self.error) {
        reportParams[@"success"] = @(1);
        reportParams[@"error_code"] = @(self.error.code);
        reportParams[@"error_info"] = self.error.localizedDescription ?: @"";
    }
    
    return reportParams;
}

@end

@interface BDPreloadSceneInfo : NSObject

@property (strong, nonatomic) NSString *scene;
@property (assign, nonatomic) long long flowTrafficSize;
@property (assign, nonatomic) long long wifiTrafficSize;

@end

@implementation BDPreloadSceneInfo


@end

@interface BDPreloadMonitor()

@property (strong, nonatomic) NSMutableDictionary *sceneInfos;

@property (strong, nonatomic) NSMutableDictionary *trackInfos;

@end

@implementation BDPreloadMonitor

+ (instancetype)sharedInstance {
    static BDPreloadMonitor *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[BDPreloadMonitor alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.trackInfos = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)startMonitor {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(monitor) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)monitor {
    
    __weak typeof(self) wself = self;
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        __strong typeof(wself) self = wself;
        for (BDPreloadSceneInfo *sceneInfo in self.sceneInfos) {
            [BDTrackerProtocol eventV3:@"preload_traffic_monitor"
                                params:@{
                                         @"preload_sence": sceneInfo.scene ?: @"",
                                         @"wifi_preload_traffic_size": @(sceneInfo.flowTrafficSize),
                                         @"flow_preload_traffic_size": @(sceneInfo.wifiTrafficSize),
                                         }];
        }
        
        self.sceneInfos = [NSMutableDictionary dictionary];
    }];
    
}

- (void)trackPreloadWithKey:(NSString *)key scene:(NSString *)scene trafficSize:(long long)trafficSize error:(NSError *)error extra:(NSDictionary *)extra {
    
    __weak typeof(self) wself = self;
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        __strong typeof(wself) self = wself;
        BDPreloadTrackInfo *trackInfo = self.trackInfos[key];
        trackInfo.scene = scene;
        if (trafficSize > 0) {
            trackInfo.trafficSize = trafficSize;
        }
        trackInfo.isWiFi = [BDPreloadUtil isWifiConnected];
        NSMutableDictionary *mExtra = [trackInfo.extra ?: @{} mutableCopy];
        [mExtra addEntriesFromDictionary:extra ?: @{}];
        trackInfo.extra = [mExtra copy];
        trackInfo.finishTime = [[NSDate date] timeIntervalSince1970];
        trackInfo.error = error;
    }];
    
}

- (void)push:(NSOperation *)task {
    NSString *preloadKey = task.bdp_preloadKey;
    NSTimeInterval initTime = task.bdp_initTime;
    BDPreloadType type = task.bdp_preloadType;
    NSString *scene = task.bdp_scene;
    
    __weak typeof(self) wself = self;
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        __strong typeof(wself) self = wself;
        BDPreloadTrackInfo *trackInfo = self.trackInfos[preloadKey];
        if (trackInfo) {
            if (!isEmptyString(trackInfo.scene)) {
                [self pop:preloadKey];
            }
        } else {
            trackInfo = [[BDPreloadTrackInfo alloc] init];
            trackInfo.preloadKey = preloadKey;
            trackInfo.startTime = [[NSDate date] timeIntervalSince1970];
            trackInfo.enqueueTime = initTime;
            trackInfo.type = type;
            trackInfo.scene = scene;
            
            if (trackInfo && preloadKey) {
                self.trackInfos[preloadKey] = trackInfo;
            }
        }
    }];
}

- (void)pop:(NSString *)preloadKey {
    
    __weak typeof(self) wself = self;
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        __strong typeof(wself) self = wself;
        BDPreloadTrackInfo *trackInfo = self.trackInfos[preloadKey];
        NSString *scene = trackInfo.scene;
        if (trackInfo) {
            [self.trackInfos removeObjectForKey:preloadKey];
            if (!isEmptyString(scene)) {
                NSDictionary *report = [trackInfo reportParams];
                BDALOG_PROTOCOL_INFO(@"BDPreload %@", report);
                [BDTrackerProtocol eventV3:@"bd_preload_finish" params:report];
                BDPreloadSceneInfo *sceneInfo = self.sceneInfos[trackInfo.scene] ?: [[BDPreloadSceneInfo alloc] init];
                if (trackInfo.isWiFi) {
                    sceneInfo.wifiTrafficSize += trackInfo.trafficSize;
                } else {
                    sceneInfo.flowTrafficSize += trackInfo.trafficSize;
                }
                
                if (sceneInfo) {
                    self.sceneInfos[scene] = sceneInfo;
                }
            }
        }
    }];
}

- (void)popAll {
    
    __weak typeof(self) wself = self;
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        __strong typeof(wself) self = wself;
        [self.trackInfos removeAllObjects];
    }];
}

+ (void)trackPreloadWithKey:(NSString *)key scene:(NSString *)scene {
    [[BDPreloadMonitor sharedInstance] trackPreloadWithKey:key scene:scene trafficSize:0 error:nil extra:nil];
}

+ (void)trackPreloadWithKey:(NSString *)key scene:(NSString *)scene error:(nullable NSError *)error {
    [[BDPreloadMonitor sharedInstance] trackPreloadWithKey:key scene:scene trafficSize:0 error:error extra:nil];
}

+ (void)trackPreloadWithKey:(NSString *)key scene:(NSString *)scene trafficSize:(long long)trafficSize extra:(NSDictionary *)extra {
    [[BDPreloadMonitor sharedInstance] trackPreloadWithKey:key scene:scene trafficSize:trafficSize error:nil extra:extra];
}

+ (void)trackPreloadWithKey:(NSString *)key scene:(NSString *)scene trafficSize:(long long)trafficSize error:(NSError *)error extra:(NSDictionary *)extra {
    [[BDPreloadMonitor sharedInstance] trackPreloadWithKey:key scene:scene trafficSize:trafficSize error:error extra:extra];
}

+ (void)push:(NSOperation *)task {
    [[BDPreloadMonitor sharedInstance] push:task];
}

+ (void)pop:(NSString *)preloadKey {
    [[BDPreloadMonitor sharedInstance] pop:preloadKey];
}

+ (void)popAll {
    [[BDPreloadMonitor sharedInstance] popAll];
}

@end

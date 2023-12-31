//
//  HMDDebugRealConfig.m
//  Heimdallr
//
//  Created by joy on 2018/4/19.
//

#import "HMDDebugRealConfig.h"
#import "HMDNetworkReachability.h"

@implementation HMDDebugRealConfig

- (instancetype)initWithParams:(NSDictionary *)params {
    if (![params isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    if (self = [super init]) {
        [self defaultInitialize];
        [self setupWithParams:params];
    }
    
    return self;
}

- (void)defaultInitialize {
    self.fetchStartTime = 0;
    self.fetchEndTime = 0;
    self.uploadTypeArray = nil;
    self.isNeedWifi = YES;
    self.limitCnt = 100;
}

- (void)setupWithParams:(NSDictionary *)params {
    if (params && [params isKindOfClass:[NSDictionary class]]) {
        if ([[params allKeys] containsObject:@"fetch_start_time"] && [[params valueForKey:@"fetch_start_time"] isKindOfClass:[NSNumber class]]) {
            self.fetchStartTime = [[params valueForKey:@"fetch_start_time"] doubleValue];
        }
        if (!self.fetchStartTime) {
            self.fetchStartTime = 0.0;
        }
        
        if ([[params allKeys] containsObject:@"fetch_end_time"] && [[params valueForKey:@"fetch_end_time"] isKindOfClass:[NSNumber class]]) {
            self.fetchEndTime = [[params valueForKey:@"fetch_end_time"] doubleValue];
        }
        if (!self.fetchEndTime) {
            NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
            self.fetchEndTime = currentTime;
        }
        
        if ([[params allKeys] containsObject:@"upload_type"]) {
            if ([[params valueForKey:@"upload_type"] isKindOfClass:[NSArray class]]) {
                NSArray *array = [params valueForKey:@"upload_type"];
                if (array && array.count > 0) {
                    self.uploadTypeArray = array;
                }
            }
        }
        if ([[params allKeys] containsObject:@"wifi_only"]) {
            id obj = [params valueForKey:@"wifi_only"];
            if ([obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSString class]]) {
                self.isNeedWifi = [obj boolValue];
            }
        } else {
            self.isNeedWifi = YES;
        }
    }
}

/*
 enable_anr_monitor：卡顿检测
 enable_oom_monitor：OOM 检测
 enable_ui_monitor：UI行为检测
 enable_performance_monitor：性能，比如 CPU、内存、电量、页面的加载初始化时间等
 enable_exception_monitor：iOS 这边的 Crash 保护，堆栈等信息
 image_monitor：图片监控
 api_all
 api_error
 service_monitor：业务埋点
*/

- (BOOL)checkIfAllowedDebugRealUploadWithType:(NSString *)type {
    
    BOOL typeNeedUpload = YES;
    
    BOOL networkCanUpload = YES;
    
    BOOL isWifi = [HMDNetworkReachability isWifiConnected];
    if (self.isNeedWifi && !isWifi) {
        networkCanUpload = NO;
    }
    
    // 如果没有下发该配置项目，则全部捞上来
    if (!self.uploadTypeArray || self.uploadTypeArray.count < 1) {
        typeNeedUpload = YES;
        return (typeNeedUpload && networkCanUpload);
    }
    // 如果配置包含则上报，不包含则不上报
    if (![self.uploadTypeArray containsObject:type]) {
        return NO;
    } else {
        typeNeedUpload = YES;
        return (typeNeedUpload && networkCanUpload);
    }
}

- (BOOL)checkIfNetworkAllowedDebugRealUpload {
    BOOL networkAllowedUpload = YES;
    
    BOOL isWifi = [HMDNetworkReachability isWifiConnected];
    if (self.isNeedWifi && !isWifi) {
        networkAllowedUpload = NO;
    }
    return networkAllowedUpload;
}

@end

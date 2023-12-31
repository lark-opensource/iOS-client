//
//  EMALocationTask.m
//  EEMicroAppSDK
//
//  Created by 新竹路车神 on 2020/7/12.
//

#import "EMALocationTask.h"
#import <CoreLocation/CLLocation.h>
#import <OPFoundation/BDPTimorClient.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/OPFoundation-Swift.h>
static NSUInteger gLocationTaskID = 0;

@implementation EMALocationTask

- (instancetype)init
{
    self = [super init];
    if (self) {
        _taskId = @(++gLocationTaskID).stringValue;
    }
    return self;
}

- (void)updateLocation:(CLLocation *)location {
    BDPLogInfo(@"updateLocation start! newLocation: %@, currentLocation:%@, isUseNewUpdateAlgorithm: %d",location, self.location, EMALocationManagerFGBridge.isUseNewUpdateAlgorithm);
    if (location) {
        if (EMALocationManagerFGBridge.isUseNewUpdateAlgorithm) {
            [self newUpdateLocation:location];
        } else {
            [self oldUpdateLocation:location];
        }
    }
    if (self.isDesiredLocationAvailable) {
        [self completeTask:NO];
    }
    BDPLogInfo(@"updateLocation done! currentLocation: %@",self.location);
}

- (void)oldUpdateLocation:(CLLocation *)location {
    if (!location) {
        return;
    }
    if (self.location && location.horizontalAccuracy > self.location.horizontalAccuracy) {
        // 新的精度变低的处理
        CLLocationDistance distance = [self.location distanceFromLocation:location];
        if (distance < self.location.horizontalAccuracy) {
            // 新的位置还在原精度更高的位置范围内则不用替换坐标
            return;
        }
    }
    self.location = location;
}
- (void)newUpdateLocation:(CLLocation *)location {
    if (!location) {
        return;
    }
    if (self.location == nil) {
        self.location = location;
        return;
    }
    /*
     定位的更新有两个维度
     1. timestamp:时间戳 越大越好
     2. accuracy: 精确度 越小越好
     对比两个维度由以下几种情况
     1. new.timestamp >= old.timestamp && new.accuracy > old.accuracy：  定位是最新，精确度不是更好的      若时差阈值则使用
     2. new.timestamp >= old.timestamp && new.accuracy <= old.accuracy： 定位是最新的，精确度更好          最好的结果 立即使用
     3. new.timestamp < old.timestamp && new.accuracy > old.accuracy：   定位不是最新的，精确度不是更好的   最差的结果，放弃使用
     4. new.timestamp < old.timestamp && new.accuracy <= old.accuracy：  定位不是最新的，精确度是更好的     若时差在阈值内 使用 ？
     对于 4 我的结论是最好不用，从定位的oncall 来看，除了 定位SDK的问题大部分都是用到时效性差的定位。所以对4 不再使用
     那么上面的逻辑可以如下表示
     */
    NSTimeInterval newTimestamp = location.timestamp.timeIntervalSince1970;
    NSTimeInterval oldTimestamp = self.location.timestamp.timeIntervalSince1970;
    CLLocationAccuracy newAccuracy = location.horizontalAccuracy;
    CLLocationAccuracy oldAccuracy = self.location.horizontalAccuracy;
    if (newTimestamp - oldTimestamp >= 0
        && (newAccuracy <= oldAccuracy || newTimestamp - oldTimestamp > EMALocationManagerFGBridge.updateCurrentLocationTimeout)){
        self.location = location;
    }
}

- (void)updateLocationCallback:(CLLocation *)location
                     locations:(NSArray *)locations{
    if (self.updateCallback) {
       NSMutableArray *finnalLocs = [NSMutableArray array];
        BDPPlugin(appEnginePlugin, EMAAppEnginePluginDelegate);
       if (appEnginePlugin.onlineConfig.returnLocations) {
           for (CLLocation *loc in locations) {
               [finnalLocs addObject:[self targetLocationFromLocation:loc]];
           }
       }
       self.updateCallback([self targetLocationFromLocation:location],finnalLocs);
    }
}

/**
 *  坐标是否满足精度要求
 *  kCLLocationAccuracyThreeKilometers: 3000
 *  kCLLocationAccuracyKilometer: 1000
 *  kCLLocationAccuracyHundredMeters: 100
 *  kCLLocationAccuracyNearestTenMeters: 10
 *  kCLLocationAccuracyBest: -1
 *  kCLLocationAccuracyBestForNavigation: -2
 */
- (BOOL)isDesiredLocationAvailable {
    if (!self.location) {
        return NO;
    }
    if (self.desiredAccuracy <= kCLLocationAccuracyNearestTenMeters) {
        if (self.location.horizontalAccuracy <= 20 && self.location.verticalAccuracy <= 20) {
            // 满足20米精度
            return YES;
        }
    } else if (self.location.horizontalAccuracy <= self.desiredAccuracy && self.location.verticalAccuracy <= self.desiredAccuracy) {
        return YES;
    }
    return NO;
}

- (void)completeTask:(BOOL)isTimeout {
    if (self.completed) {
        return;
    }

    // 清理timer
    [self.timeOutTimer invalidate];
    self.timeOutTimer = nil;

    NSError *error = self.location?nil:self.error;
    BDPLogInfo(@"requestLocation result: %@", BDPParamStr(self.location, error));
    // 埋点上报
    if (self.monitor) {
        if (self.location) {
            if (@available(iOS 15, *)) {
                self.monitor
                    .kv(@"isProducedByAccessory", @(self.location.sourceInformation.isProducedByAccessory))
                    .kv(@"isSimulatedBySoftware", @(self.location.sourceInformation.isSimulatedBySoftware));
            }
            
            self.monitor
                /// 定位结果实效性 越大越好一般为负数
                .kv(@"resultAging",@(self.location.timestamp.timeIntervalSinceNow))
                /// 定位结果准确度 约小越好
                .kv(@"accuracyDifference",@(self.location.horizontalAccuracy - self.desiredAccuracy) )
                .kv(@"result", kEventValue_success)
                .kv(@"horizontalAccuracy", @(self.location.horizontalAccuracy))
                .kv(@"verticalAccuracy", @(self.location.verticalAccuracy));
        } else {
            self.monitor.kv(@"result", kEventValue_fail)
                .timing();
        }
        self.monitor.setError(error)
            .timing()
            .flush();
    }

    // 回调
    if (self.callback) {
        self.callback([self targetLocationFromLocation:self.location], self.accuracyAuthorization, error);
    }

    self.updateCallback = nil;
    self.callback = nil;

    self.completed = YES;
}

- (CLLocation *)targetLocationFromLocation:(CLLocation *)location {
    if (location) {
        if (self.coordinateSystemType == EMACoordinateSystemTypeGCJ02) {
            // WGS84 -> GCJ-02
            CLLocationCoordinate2D coordinate = [OPLocaionOCBridge bdp_convertLocationToGCJ02:location.coordinate];
            return [[CLLocation alloc]
                    initWithCoordinate:coordinate
                    altitude:location.altitude
                    horizontalAccuracy:location.horizontalAccuracy
                    verticalAccuracy:location.verticalAccuracy
                    course:location.course
                    speed:location.speed
                    timestamp:location.timestamp];
        }
    }
    return location;
}

@end

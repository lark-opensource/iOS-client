//
//  EMALocationTask.h
//  EEMicroAppSDK
//
//  Created by 新竹路车神 on 2020/7/12.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <OPFoundation/BDPLocationPluginDelegate.h>

@class OPMonitorEvent;

NS_ASSUME_NONNULL_BEGIN
/// 定位任务
@interface EMALocationTask : NSObject

@property (nonatomic, strong, readonly) NSString *taskId;
@property (nonatomic, copy, nullable) void(^updateCallback)(CLLocation * _Nullable, NSArray<CLLocation *> * _Nullable);
// 定位任务的完成回调
@property (nonatomic, copy, nullable) void(^callback)(CLLocation * _Nullable, BDPAccuracyAuthorization, NSError * _Nullable);
@property (nonatomic, strong) NSTimer *timeOutTimer;
@property (nonatomic, strong, nullable) CLLocation *location;
@property (nonatomic, assign) CLLocationAccuracy desiredAccuracy;
@property (nonatomic, assign) BDPAccuracyAuthorization accuracyAuthorization;
@property (nonatomic, assign) BDPCoordinateSystemType coordinateSystemType;
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, strong) OPMonitorEvent *monitor;
@property (nonatomic, assign) BOOL completed;

- (void)updateLocation:(CLLocation *)location;

- (void)updateLocationCallback:(CLLocation *)location locations:(NSArray *)locations;

- (void)completeTask:(BOOL)isTimeout;

@end

NS_ASSUME_NONNULL_END

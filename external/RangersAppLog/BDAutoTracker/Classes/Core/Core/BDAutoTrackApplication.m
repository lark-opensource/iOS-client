//
//  BDAutoTrackApplication.m
//  RangersAppLog
//
//  Created by bytedance on 2022/4/6.
//

#import <Foundation/Foundation.h>
#import "BDCommonDefine.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackApplication.h"

@interface BDAutoTrackApplication()

@property (nonatomic, assign) NSTimeInterval autoTrackUpdateLocationTimeInterval;
@property (nonatomic, assign) NSTimeInterval autoTrackUpdateLocationLastTime;

@end



@implementation BDAutoTrackApplication

#pragma mark - init

static BDAutoTrackApplication *sharedInstance = nil;

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    self.screenOrientation =[self status_bar_orientation_str: statusBarOrientation];
//    NSLog(@"BDAutoTrackApplication init, screenOrientation>>>> %@", self.screenOrientation);
    
    self.autoTrackUpdateLocationLastTime = 0;
    self.autoTrackUpdateLocationTimeInterval = 60;
    
    [self bindevents];

    return self;
}


#pragma mark - system

- (void)update_sys_orientation {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (statusBarOrientation == UIInterfaceOrientationUnknown) {
            UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
            self.screenOrientation = [self orientation_str:orientation];
//            NSLog(@"screenOrientation>>>> %@", self.screenOrientation);
            return;
        }
        
        self.screenOrientation =[self status_bar_orientation_str: statusBarOrientation];
//        NSLog(@"statusBarOrientation>>>> %@", self.screenOrientation);
    });
}

- (NSString *)orientation_str:(enum UIDeviceOrientation)orientation {
    if (orientation == UIDeviceOrientationPortrait) {
        return kBDAutoTrackPortrait;
    }
    if (orientation == UIDeviceOrientationPortraitUpsideDown) {
        return kBDAutoTrackPortrait;
    }
    if (orientation == UIDeviceOrientationLandscapeLeft) {
        return kBDAutoTrackLandscape;
    }
    if (orientation == UIDeviceOrientationLandscapeRight) {
        return kBDAutoTrackLandscape;
    }
    if (orientation == UIDeviceOrientationFaceUp) {
        return kBDAutoTrackPortrait;
    }
    if (orientation == UIDeviceOrientationFaceDown) {
        return kBDAutoTrackPortrait;
    }
//    NSLog(@"orientation>>>>> %ld", orientation);
    return @"";
}

- (NSString *)status_bar_orientation_str:(enum UIInterfaceOrientation)statusBarOrientation {
    if (statusBarOrientation == UIInterfaceOrientationPortrait) {
        return kBDAutoTrackPortrait;
    }
    if (statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        return kBDAutoTrackPortrait;
    }
    if (statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
        return kBDAutoTrackLandscape;
    }
    if (statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
        return kBDAutoTrackLandscape;
    }
//    NSLog(@"statusBarOrientation>>>>> %ld", statusBarOrientation);
    return @"";
}

- (NSString *)geo_coordinate_system_str:(enum BDAutoTrackGeoCoordinateSystem)geoCoordinateSystem {
    if (geoCoordinateSystem == BDAutoTrackGeoCoordinateSystemWGS84) {
        return kBDAutoTrackWGS84;
    }
    if (geoCoordinateSystem == BDAutoTrackGeoCoordinateSystemGCJ02) {
        return kBDAutoTrackGCJ02;
    }
    if (geoCoordinateSystem == BDAutoTrackGeoCoordinateSystemBD09) {
        return kBDAutoTrackBD09;
    }
    if (geoCoordinateSystem == BDAutoTrackGeoCoordinateSystemBDCS) {
        return kBDAutoTrackBDCS;
    }
    return @"";
}


#pragma mark - events

- (void)bindevents {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUIDeviceOrientationChange) name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)onUIDeviceOrientationChange {
    [self update_sys_orientation];
}


#pragma mark - implementations

- (void)updateGPSLocation:(enum BDAutoTrackGeoCoordinateSystem)geoCoordinateSystem longitude:(double)longitude latitude:(double)latitude {
    self.geoCoordinateSystem = [self geo_coordinate_system_str:geoCoordinateSystem];
    self.longitude = longitude * pow(10, 6);
    self.latitude = latitude * pow(10, 6);
}

- (BOOL)hasGPSLocation {
    return self.geoCoordinateSystem != nil;
}

- (void)updateAutoTrackGPSLocation:(enum BDAutoTrackGeoCoordinateSystem)geoCoordinateSystem longitude:(double)longitude latitude:(double)latitude {
//    NSLog(@">>>>> update gps location");
    NSTimeInterval nowTime = bd_currentIntervalValue();
    if (nowTime - self.autoTrackUpdateLocationLastTime < self.autoTrackUpdateLocationTimeInterval) {
        return;
    }
    
//    NSLog(@"update gps location>>>>> %f, %f", longitude, latitude);
    self.autoTrackGeoCoordinateSystem = [self geo_coordinate_system_str:geoCoordinateSystem];
    self.autoTrackLongitude = longitude * pow(10, 6);
    self.autoTrackLatitude = latitude * pow(10, 6);
    self.autoTrackUpdateLocationLastTime = nowTime;
}

- (BOOL)hasAutoTrackGPSLocation {
    return self.autoTrackGeoCoordinateSystem != nil;
}

+ (void)updateAutoTrackGPSLocation:(enum BDAutoTrackGeoCoordinateSystem)geoCoordinateSystem longitude:(double)longitude latitude:(double)latitude  {
    if (sharedInstance != nil) {
        [sharedInstance updateAutoTrackGPSLocation:geoCoordinateSystem longitude:longitude latitude:latitude];
    }
}

@end

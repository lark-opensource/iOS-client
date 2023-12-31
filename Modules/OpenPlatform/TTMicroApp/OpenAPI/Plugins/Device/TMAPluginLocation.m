//
//  TTMicroAppLocation.m
//  Timor
//
//  Created by muhuai on 2017/11/29.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPI18n.h>
#import <OPPluginManagerAdapter/BDPJSBridgeUtil.h>
#import <OPFoundation/BDPMacroUtils.h>
#import "BDPPrivacyAccessNotifier.h"
#import <OPFoundation/BDPResponderHelper.h>
#import <OPFoundation/BDPSandBoxHelper.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPUtils.h>
#import "TMAPluginLocation.h"
#import <CoreLocation/CoreLocation.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <TTMicroApp/OPAPIDefine.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import "OPLocationPrivacyAccessStatusManager.h"
#import <OPFoundation/OPFoundation-Swift.h>

// location accuracy authorization is full
NSString* const  kAccuracyAuthorzationFull = @"full";
// location accuracy authorization is reduced
NSString* const  kAccuracyAuthorzationReduced = @"reduced";

@interface TMAPluginLocation()

@property (nonatomic, assign) BOOL didShowAlertEnabled;
@property (nonatomic, assign) BOOL didShowAlertDenied;

@end

@implementation TMAPluginLocation

#pragma mark - Initilize
/*-----------------------------------------------*/
//              Initilize - 初始化相关
/*-----------------------------------------------*/

+ (BDPJSBridgePluginMode)pluginMode
{
    return BDPJSBridgePluginModeLifeCycle;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupLocation];
    }
    return self;
}

- (void)setupLocation {
    BDPLogTagInfo(@"Location", @"setupLocation");
    if (![CLLocationManager locationServicesEnabled]) {
        BDPLogError(@"CLLocationManager locationServices is not Enabled")
        return;
    }
    self.didShowAlertEnabled = NO;
    self.didShowAlertDenied = NO;
}

#pragma mark - Function Implementation
/*-----------------------------------------------*/
//       Function Implementation - 方法实现
/*-----------------------------------------------*/
- (void)getLocationWithParam:(NSDictionary * _Nullable)param
                    callback:(BDPJSBridgeCallback _Nullable)callback
                     context:(BDPPluginContext _Nullable)context {
    OP_API_RESPONSE(OPAPIResponse)
    if (!CLLocationManager.locationServicesEnabled) {
        BDPLogError(@"system location is disable, %@ request location failed", context.engine.uniqueID ?: @"")
        // 弹出提示框
        [self alertUserDeniedOrLocDisable:NO fromController:context.controller];
        OP_CALLBACK_WITH_ERRMSG([response callback:OPGeneralAPICodeSystemAuthDeny], BDPI18n.unable_access_location)
        return;
    }
    CLAuthorizationStatus status = CLLocationManager.authorizationStatus;
    if (status == kCLAuthorizationStatusDenied) {
        BDPLogError(@"authorizationStatus is Denied, %@ request location failed", context.engine.uniqueID ?: @"")
        [self alertUserDeniedOrLocDisable:YES fromController:context.controller];
        OP_CALLBACK_WITH_ERRMSG([response callback:OPGeneralAPICodeSystemAuthDeny], BDPI18n.unable_access_location)
        return;
    }
    if (status == kCLAuthorizationStatusRestricted) {
        BDPLogError(@"authorizationStatus is Restricted, %@ request location failed", context.engine.uniqueID ?: @"")
        [self alertUserDeniedOrLocDisable:YES fromController:context.controller];
        OP_CALLBACK_WITH_ERRMSG([response callback:GetLocationAPICodeLocationFail], BDPI18n.unable_access_location)
        return;
    }
    [self updateLocationAccessStatus:YES];
    BDPLogInfo(@"%@ start call location service", context.engine.uniqueID ?: @"")
    WeakSelf;
    BDPPlugin(locationPlugin, BDPLocationPluginDelegate);
    [locationPlugin bdp_reqeustLocationWithParam:param context:context completion:^(CLLocation *location, BDPAccuracyAuthorization accuracy, NSError *error) {
        StrongSelfIfNilReturn;
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"host return error: %@", error];
            OP_CALLBACK_WITH_ERRMSG([response callback:GetLocationAPICodeLocationFail], msg)
            BDPLogError(msg)
            return;
        }
        if (location) {
            NSDictionary *data = [self dicFromLocation:location accuracy:accuracy];
            OP_CALLBACK_WITH_DATA([response callback:OPGeneralAPICodeOk], data)
            [self updateLocationAccessStatus:NO];
        } else {
            if (![self checkCLAuthoriztionStatus:[CLLocationManager authorizationStatus]]) {
                NSString *msg = @"Unable to access your location";
                OP_CALLBACK_WITH_ERRMSG([response callback:OPGeneralAPICodeSystemAuthDeny], @"Unable to access your location")
                BDPLogError(msg)
            } else {
                NSString *msg = @"getLocation failed";
                OP_CALLBACK_WITH_ERRMSG([response callback:GetLocationAPICodeLocationFail], msg)
            }
        }
    }];
}

- (BOOL)checkCLAuthoriztionStatus:(CLAuthorizationStatus)status {
    BOOL result = YES;
    if (status == kCLAuthorizationStatusNotDetermined || status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        result = NO;
    }
    return result;
}


- (NSDictionary *)dicFromLocation:(CLLocation *)location
                         accuracy:(BDPAccuracyAuthorization)accuracy {
    NSMutableDictionary *dic = NSMutableDictionary.dictionary;
    [dic setValue:@(location.coordinate.latitude) forKey:@"latitude"];
    [dic setValue:@(location.coordinate.longitude) forKey:@"longitude"];
    [dic setValue:@(location.speed) forKey:@"speed"];
    [dic setValue:@(location.altitude) forKey:@"altitude"];
    [dic setValue:@(location.horizontalAccuracy) forKey:@"accuracy"];
    [dic setValue:@(location.verticalAccuracy) forKey:@"verticalAccuracy"];
    [dic setValue:@(location.horizontalAccuracy) forKey:@"horizontalAccuracy"];
    [dic setValue:@((int64_t)(location.timestamp.timeIntervalSince1970 * 1000)) forKey:@"timestamp"];
    NSString *accuracyStr = [self getAccuracyAuthorizationString:accuracy];
    if (!BDPIsEmptyString(accuracyStr)) {
        [dic setValue:accuracyStr forKey:@"authorizationAccuracy"];
    } else {
        BDPLogError(@"Accuracy is nil.");
        NSAssert(NO, @"Location accuracy authorization is nil.");
    }
    return dic.copy;
}

// 通过枚举值匹配字符串
- (NSString * _Nullable)getAccuracyAuthorizationString:(BDPAccuracyAuthorization)auth {
    switch (auth) {
        case BDPAccuracyAuthorizationFullAccuracy:
            // 精确授权
            return kAccuracyAuthorzationFull;
        case BDPAccuracyAuthorizationReducedAccuracy:
            // 非精确授权
            return kAccuracyAuthorzationReduced;
        case BDPAccuracyAuthorizationUnknown:
            // unknown为精确授权
            return kAccuracyAuthorzationFull;
        default:
            return nil;
    }
}

- (void)alertUserDeniedOrLocDisable:(BOOL)isUserDenied fromController:(UIViewController *)fromController {
    BDPLogTagInfo(@"Location", @"alertUserDeniedOrLocDisable, isUserDenied=%@", @(isUserDenied));
    NSString *title = BDPI18n.permissions_no_access;
    NSString *description = BDPI18n.permissions_location_services_on;
    if (isUserDenied) {
        if (self.didShowAlertDenied) {
            return;
        }
        self.didShowAlertDenied = YES;
        NSString *appName = BDPSandBoxHelper.appDisplayName;
        description = [NSString stringWithFormat:BDPI18n.permissions_location_services_access, appName];
    } else {
        if (self.didShowAlertEnabled) {
            return;
        }
        self.didShowAlertEnabled = YES;
    }

    // 适配DarkMode:使用主端提供的UDDilog
    UDDialog *dialog = [UDOCDialogBridge createDialog];
    [UDOCDialogBridge setTitleWithDialog:dialog text:BDPI18n.permissions_no_access];
    [UDOCDialogBridge setContentWithDialog:dialog text:description];
    [UDOCDialogBridge addSecondaryButtonWithDialog:dialog text:BDPI18n.cancel dismissCompletion:^{

    }];

    [UDOCDialogBridge addButtonWithDialog:dialog text:BDPI18n.microapp_m_permission_go_to_settings dismissCompletion:^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];

    UIViewController *alertController = (UIViewController *)dialog;
    UIWindow *window = fromController.view.window ?: OPWindowHelper.fincMainSceneWindow;
    BDPExecuteOnMainQueue(^{
        if ([BDPDeviceHelper isPadDevice]) {
            UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
            popPresenter.sourceView = window;
            popPresenter.sourceRect = window.bounds;
        }
        UIViewController *topVC = [BDPResponderHelper topViewControllerFor:[BDPResponderHelper topmostView:window]];
        if ([UDRotation isAutorotateFrom:topVC]) {
            [UDOCDialogBridge setAutorotatableWithDialog:alertController enable:YES];
        }
        [topVC presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)updateLocationAccessStatus:(BOOL)isUsing {
    [[OPLocationPrivacyAccessStatusManager shareInstance] updateSingleLocationAccessStatus:isUsing];
}

@end

//
//  BDAutoTrackIDFA.m
//  RangersAppLog
//
//  Created by bob on 2020/8/28.
//

#import "BDAutoTrackIDFA.h"
#import "BDAutoTrackDeviceHelper.h"

#import <AdSupport/ASIdentifierManager.h>

#ifdef __IPHONE_14_0
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#endif

@implementation BDAutoTrackIDFA

NSString *gTrackingIdentifier;
BOOL gAuthorizationStatusDetermined; //

+ (void)initialize
{
    gAuthorizationStatusDetermined = NO;
    gTrackingIdentifier = nil;
}

+ (NSString *)trackingIdentifier {
    if (gAuthorizationStatusDetermined) {
        return gTrackingIdentifier;
    }
    if ([self authorizationStatus] == BDAutoTrackAuthorizationStatusNotDetermined) {
        static NSString *identifier;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            identifier = [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString;
        });
        return identifier;
    }
    gTrackingIdentifier = [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString;
    gAuthorizationStatusDetermined = YES;
    return gTrackingIdentifier;
}

+ (BDAutoTrackAuthorizationStatus)authorizationStatusBefore14 {
    if ([ASIdentifierManager sharedManager].isAdvertisingTrackingEnabled) {
         return BDAutoTrackAuthorizationStatusAuthorized;
    }
    return BDAutoTrackAuthorizationStatusDenied;
}


+ (BDAutoTrackAuthorizationStatus)authorizationStatus {
    if (bd_device_isSimulator()) {
        return [self authorizationStatusBefore14];
    }
    
    #ifdef __IPHONE_14_0
    if (@available(iOS 14.0, *)) {
        switch ([ATTrackingManager trackingAuthorizationStatus]) {
            case ATTrackingManagerAuthorizationStatusNotDetermined: return BDAutoTrackAuthorizationStatusNotDetermined;
            case ATTrackingManagerAuthorizationStatusRestricted: return BDAutoTrackAuthorizationStatusRestricted;
            case ATTrackingManagerAuthorizationStatusDenied: return BDAutoTrackAuthorizationStatusDenied;
            case ATTrackingManagerAuthorizationStatusAuthorized: return BDAutoTrackAuthorizationStatusAuthorized;
        }
        
        return BDAutoTrackAuthorizationStatusNotDetermined;
    }
    #endif
    
    return [self authorizationStatusBefore14];
}

+ (void)requestAuthorizationBefore14:(BDAutoTrackAuthorizationHandler)completion  {
    if ([ASIdentifierManager sharedManager].isAdvertisingTrackingEnabled) {
        completion(BDAutoTrackAuthorizationStatusAuthorized);
    } else {
        completion(BDAutoTrackAuthorizationStatusDenied);
    }
}

+ (void)requestAuthorizationWithHandler:(BDAutoTrackAuthorizationHandler)completion  {
    if (completion == nil) {
        completion = ^(BDAutoTrackAuthorizationStatus status) {
        };
    }
    
    if (bd_device_isSimulator()) {
        [self requestAuthorizationBefore14:completion];
        return;
    }
    #ifdef __IPHONE_14_0
    if (@available(iOS 14.0, *)) {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            BDAutoTrackAuthorizationStatus authStatus = BDAutoTrackAuthorizationStatusNotDetermined;
            if (status == ATTrackingManagerAuthorizationStatusAuthorized) {
                authStatus = BDAutoTrackAuthorizationStatusAuthorized;
            } else if (status == ATTrackingManagerAuthorizationStatusDenied) {
                authStatus = BDAutoTrackAuthorizationStatusDenied;
            } else if (status == ATTrackingManagerAuthorizationStatusRestricted) {
                authStatus = BDAutoTrackAuthorizationStatusRestricted;
            } else {
                authStatus = BDAutoTrackAuthorizationStatusNotDetermined;
            }
            completion(authStatus);
        }];
        
        return;
    }
    #endif
    
    [self requestAuthorizationBefore14:completion];
}

@end

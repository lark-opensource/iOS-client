//
//  OKReachability+Cellular.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "OKReachability+Cellular.h"
#import "OKCellular.h"
#import <CoreTelephony/CTCarrier.h>

@implementation OKReachability (Cellular)

+ (BOOL)isNetworkConnected {
    OKReachabilityStatus status = [[OKReachability sharedInstance] currentReachabilityStatus];
    return status == OKReachabilityStatusReachableViaWiFi || status == OKReachabilityStatusReachableViaWWAN;
}

+ (OKCellularConnectionType)cellularConnectionType {
    OKCellularServiceType service = [[OKCellular sharedInstance] currentDataServiceType];
    
    return [[OKCellular sharedInstance] cellularConnectionTypeForService:service];
}

+ (BOOL)is2GConnected {
    OKCellularServiceType service = [[OKCellular sharedInstance] currentDataServiceType];
    return [self is2GConnectedForService:service];
}

+ (BOOL)is3GConnected {
    OKCellularServiceType service = [[OKCellular sharedInstance] currentDataServiceType];
    
    return [self is3GConnectedForService:service];
}

+ (BOOL)is4GConnected {
    OKCellularServiceType service = [[OKCellular sharedInstance] currentDataServiceType];
    
    return [self is4GConnectedForService:service];
}

+ (BOOL)is5GConnected {
    OKCellularServiceType service = [[OKCellular sharedInstance] currentDataServiceType];
    return [self is5GConnectedForService:service];
}

+ (NSString *)carrierName {
    OKCellularServiceType service = [[OKCellular sharedInstance] currentDataServiceType];

    return [self carrierNameForService:service];
}

+ (NSString *)carrierMCC {
    OKCellularServiceType service = [[OKCellular sharedInstance] currentDataServiceType];

    return [self carrierMCCForService:service];
}

+ (NSString *)carrierMNC {
    OKCellularServiceType service = [[OKCellular sharedInstance] currentDataServiceType];
    
    return [self carrierMNCForService:service];
}

+ (OKCellularConnectionType)cellularConnectionTypeForService:(OKCellularServiceType)service {
    
    return [[OKCellular sharedInstance] cellularConnectionTypeForService:service];
}

+ (BOOL)is2GConnectedForService:(OKCellularServiceType)service {
    OKCellularConnectionType connectionType = [[OKCellular sharedInstance] cellularConnectionTypeForService:service];
    return  connectionType == OKCellularConnectionType2G;;
}

+ (BOOL)is3GConnectedForService:(OKCellularServiceType)service {
    OKCellularConnectionType connectionType = [[OKCellular sharedInstance] cellularConnectionTypeForService:service];
    
    return connectionType == OKCellularConnectionType3G;
}

+ (BOOL)is4GConnectedForService:(OKCellularServiceType)service {
    OKCellularConnectionType connectionType = [[OKCellular sharedInstance] cellularConnectionTypeForService:service];
    
    return connectionType == OKCellularConnectionType4G;
}

+ (BOOL)is5GConnectedForService:(OKCellularServiceType)service {
    OKCellularConnectionType connectionType = [[OKCellular sharedInstance] cellularConnectionTypeForService:service];
    
    return connectionType == OKCellularConnectionType5G;
}

+ (NSString *)carrierNameForService:(OKCellularServiceType)service {
    CTCarrier *carrier =[[OKCellular sharedInstance] carrierForService:service];

    return carrier.carrierName;
}

+ (NSString *)carrierMCCForService:(OKCellularServiceType)service {
    CTCarrier *carrier =[[OKCellular sharedInstance] carrierForService:service];

    return carrier.mobileCountryCode;
}

+ (NSString *)carrierMNCForService:(OKCellularServiceType)service {
    CTCarrier *carrier =[[OKCellular sharedInstance] carrierForService:service];

    return carrier.mobileNetworkCode;
}

@end

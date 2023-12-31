//
//  BDTrackerProtocolDefine.h
//  Pods
//
//  Created by bob on 2020/3/26.
//

#import <Foundation/Foundation.h>

#ifndef BDTrackerProtocolDefine_h
#define BDTrackerProtocolDefine_h

/// network type
typedef NS_ENUM(NSInteger, BDTrackerNetworkConnectionType) {
    /// init default state
    BDTrackerNetworkConnectionTypeNone = -1,
    /// no network
    BDTrackerNetworkConnectionTypeNoConnection = 0,
    BDTrackerNetworkConnectionTypeMobile = 1,
    BDTrackerNetworkConnectionType2G = 2,
    BDTrackerNetworkConnectionType3G = 3,
    BDTrackerNetworkConnectionTypeWiFi = 4,
    BDTrackerNetworkConnectionType4G = 5,
    BDTrackerNetworkConnectionType5G = 6,
};


typedef NS_ENUM(NSUInteger, BDTrackerLaunchFrom) {
    BDTrackerLaunchFromInitialState = 0,
    BDTrackerLaunchFromUserClick = 1,
    BDTrackerLaunchFromRemotePush = 2,
    BDTrackerLaunchFromWidget = 3,
    BDTrackerLaunchFromSpotlight = 4,
    BDTrackerLaunchFromExternal = 5,
    BDTrackerLaunchFromBackground = 6,
    BDTrackerLaunchFromSiri = 7,
};

#endif /* BDTrackerProtocolDefine_h */

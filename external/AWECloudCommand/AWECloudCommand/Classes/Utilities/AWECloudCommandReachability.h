//
//  AWECloudCommandReachability.h
//  Pods
//
//  Created by xiangwu on 2017/5/15.
//
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSInteger {
    AWECloudCommandNotReachable = 0,
    AWECloudCommandReachableViaWiFi,
    AWECloudCommandReachableVia2G,
    AWECloudCommandReachableVia3G,
    AWECloudCommandReachableVia4G,
} AWECloudCommandNetworkStatus;

extern NSString *kAWECloudCommandReachabilityChangedNotification;

@interface AWECloudCommandReachability : NSObject

/*!
 * Use to check the reachability of a given host name.
 */
+ (instancetype)reachabilityWithHostName:(NSString *)hostName;

/*!
 * Use to check the reachability of a given IP address.
 */
+ (instancetype)reachabilityWithAddress:(const struct sockaddr *)hostAddress;

/*!
 * Checks whether the default route is available. Should be used by applications that do not connect to a particular host.
 */
+ (instancetype)reachabilityForInternetConnection;


#pragma mark reachabilityForLocalWiFi
//reachabilityForLocalWiFi has been removed from the sample.  See ReadMe.md for more information.
//+ (instancetype)reachabilityForLocalWiFi;

/*!
 * Start listening for reachability notifications on the current run loop.
 */
- (BOOL)startNotifier;
- (void)stopNotifier;

- (AWECloudCommandNetworkStatus)currentReachabilityStatus;

/*!
 * WWAN may be available, but not active until a connection has been established. WiFi may require a connection for VPN on Demand.
 */
- (BOOL)connectionRequired;

@end

NS_ASSUME_NONNULL_END

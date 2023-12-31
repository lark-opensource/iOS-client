//
//  PNSNetworkProtocol.h
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/15.
//

#import "PNSServiceCenter.h"

#ifndef PNSNetworkProtocol_h
#define PNSNetworkProtocol_h

#define PNSNetwork PNS_GET_INSTANCE(PNSNetworkProtocol)

typedef NS_ENUM(NSInteger, PNSNetworkStatus) {
    PNSNetworkNotReachable = 0,
    PNSNetworkReachableViaWiFi,
    PNSNetworkReachableViaWWAN
};

typedef void (^PNSNetworkChangeBlock)(PNSNetworkStatus);


@protocol PNSNetworkProtocol <NSObject>

- (PNSNetworkStatus)currentNetworkStatus;

- (void)registerNetworkChangeHandler:(PNSNetworkChangeBlock _Nonnull)block;

@end

#endif /* PNSNetworkProtocol_h */

//
//  OKConnection.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "OKConnection.h"
#import "OKReachability.h"
#import "OKCellular.h"

@interface OKConnection ()

@property (nonatomic, assign) OKNetworkConnectionType connection;
@property (nonatomic, copy) NSString *connectMethodName;

@end

@implementation OKConnection

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance {
    static OKConnection *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onConnectionChanged)
                                                     name:OKNotificationReachabilityChanged
                                                   object:nil];
        [self onConnectionChanged];
    }

    return self;
}

- (OKNetworkConnectionType)cellularConnection {
    OKCellularServiceType serviceType = [[OKCellular sharedInstance] currentDataServiceType];
    OKCellularConnectionType connectionType = [[OKCellular sharedInstance] cellularConnectionTypeForService:serviceType];
    
    switch (connectionType) {
        case OKCellularConnectionType5G:
            return OKNetworkConnectionType5G;
        case OKCellularConnectionType4G:
            return OKNetworkConnectionType4G;
        case OKCellularConnectionType3G:
            return OKNetworkConnectionType3G;
        case OKCellularConnectionType2G:
            return OKNetworkConnectionType2G;
        case OKCellularConnectionTypeUnknown:
            return OKNetworkConnectionTypeMobile;
        case OKCellularConnectionTypeNone:
            return OKNetworkConnectionTypeNone;
    }
}

- (void)onConnectionChanged {
    OKReachabilityStatus status = [[OKReachability sharedInstance] currentReachabilityStatus];
    
    /* update self.connection */
    switch (status) {
        case OKReachabilityStatusNotReachable:
            self.connection = OKNetworkConnectionTypeNone;
            break;
        case OKReachabilityStatusReachableViaWiFi:
            self.connection = OKNetworkConnectionTypeWiFi;
            break;
        case OKReachabilityStatusReachableViaWWAN:
            self.connection = [self cellularConnection];
            break;

    }

    /* update self.connectMethodName */
    switch (self.connection) {
        case OKNetworkConnectionTypeWiFi:
            self.connectMethodName = @"WIFI";
            break;
        case OKNetworkConnectionType2G:
            self.connectMethodName = @"2G";
            break;
        case OKNetworkConnectionType3G:
            self.connectMethodName = @"3G";
            break;
        case OKNetworkConnectionType4G:
            self.connectMethodName = @"4G";
            break;
        case OKNetworkConnectionType5G:
            self.connectMethodName = @"5G";
            break;
        case OKNetworkConnectionTypeMobile:
            self.connectMethodName = @"mobile";
            break;
        default:
            self.connectMethodName = nil;
            break;
    }
}


@end

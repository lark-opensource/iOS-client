//
//  PNSNetworkImpl.m
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/20.
//

#import "PNSNetworkImpl.h"
#import "PNSServiceCenter+private.h"
#import <TTReachability/TTReachability.h>

PNS_BIND_DEFAULT_SERVICE(PNSNetworkImpl, PNSNetworkProtocol)

@interface PNSNetworkImpl()
@property (nonatomic, strong) NSMutableArray<PNSNetworkChangeBlock> *blocks;
@end

@implementation PNSNetworkImpl

- (PNSNetworkStatus)currentNetworkStatus {
    TTReachability *reachability = [TTReachability reachabilityForInternetConnection];
    return [self __pnsNetworkStatusFromTTReachabilityStatus:reachability.currentReachabilityStatus];
}

- (instancetype)init {
    if (self = [super init]) {
        self.blocks = [NSMutableArray new];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                      selector:@selector(receiveNetworkChangedNotification:)
                                                          name:TTReachabilityChangedNotification
                                                        object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)receiveNetworkChangedNotification:(NSNotification *)notification {
    TTReachability *reach = [notification object];
    if ([reach isKindOfClass:[TTReachability class]]) {
        PNSNetworkStatus status = [self __pnsNetworkStatusFromTTReachabilityStatus:reach.currentReachabilityStatus];
        [[self.blocks copy] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            PNSNetworkChangeBlock block = (PNSNetworkChangeBlock)obj;
            block(status);
        }];
    }
}


- (void)registerNetworkChangeHandler:(PNSNetworkChangeBlock)block
{
    if (block) {
        [self.blocks addObject:block];
    }
}

- (PNSNetworkStatus)__pnsNetworkStatusFromTTReachabilityStatus:(NetworkStatus)status
{
    switch (status) {
        case NotReachable:
            return PNSNetworkNotReachable;
        case ReachableViaWiFi:
            return PNSNetworkReachableViaWiFi;
        case ReachableViaWWAN:
            return PNSNetworkReachableViaWWAN;
    }
    return NotReachable;
}

@end

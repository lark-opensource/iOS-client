//
//  PNSTrackerImpl.m
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/20.
//

#import "PNSTrackerImpl.h"
#import "PNSServiceCenter+private.h"
#import <BDTrackerProtocol/BDTrackerProtocol.h>

PNS_BIND_DEFAULT_SERVICE(PNSTrackerImpl, PNSTrackerProtocol)

@implementation PNSTrackerImpl

- (void)event:(NSString * _Nonnull)event params:(NSDictionary * _Nullable)params {
    [BDTrackerProtocol eventV3:event params:params.copy];
}

@end

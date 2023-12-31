//
//  TSPKInSameSubnetworkFunc.m
//  Musically
//
//  Created by ByteDance on 2022/10/8.
//

#import "TSPKInSameSubnetworkFunc.h"
#import "TSPKNetworkManager.h"

@implementation TSPKInSameSubnetworkFunc

- (NSString *)symbol {
    return @"is_in_same_subnetwork";
}

- (id)execute:(NSMutableArray *)params {
    if (params.count >= 1) {
        NSString *networkAddress = params[0];
        
        if ([[TSPKNetworkManager shared] checkIfIPAddressInSameSubnet:networkAddress]) {
            return @YES;
        }
    }
    
    return @NO;
}

@end

//
//  BDPAppContext.m
//  OPFoundation
//
//  Created by justin on 2022/12/22.
//

#import "BDPAppContext.h"
#import "BDPTracingManager.h"
#import <ECOInfra/ECOInfra-Swift.h>

@implementation BDPAppContext
- (OPTrace *)getTrace {
    return [[BDPTracingManager sharedInstance] getTracingByUniqueID:self.engine.uniqueID] ?: [[BDPTracingManager sharedInstance] generateTracingByUniqueID:self.engine.uniqueID];
}

- (ECONetworkRequestSourceWapper *)getSource {
    return [[ECONetworkRequestSourceWapper alloc] initWithSource:ECONetworkRequestSourceApi];
}

@end

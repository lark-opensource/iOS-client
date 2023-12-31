//
//  TSPKLocalNetworkBasePipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKLocalNetworkBasePipeline.h"

@implementation TSPKLocalNetworkBasePipeline

+ (NSString *)dataType {
    return TSPKDataTypeLocalNetwork;
}

+ (TSPKHandleResult *)handleAPIAccess:(NSString *)api networkAddress:(NSString *)networkAddress {
    NSDictionary *params;
    if (networkAddress != nil) {
        params = @{@"content": networkAddress};
    }
    
    return [self handleAPIAccess:api className:nil params:params];
}

- (BOOL)deferPreload
{
    return YES;
}

+ (BOOL)isEntryDefaultEnable {
    return NO;
}

@end

//
//  BDIDemoAPIs.m
//  BDiOSpy
//
//  Created by byte dance on 2021/12/1.
//

#import "BDIDemoAPIs.h"

@implementation BDIDemoAPIs

+ (nonnull NSArray<BDIRPCRoute *> *)routes {
    NSMutableArray *rpcRoutes = [NSMutableArray array];
    [rpcRoutes addObjectsFromArray:@[
        [BDIRPCRoute CALL:@"get_version" respondTarget:self action:@selector(handleGetVersion:)],
    ]];
    return rpcRoutes;
}

+ (BDIRPCResponse *)handleGetVersion:(BDIRPCRequest *)request
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *mainVersion = [[mainBundle infoDictionary] valueForKey:@"CFBundleVersion"];
    if(mainVersion == nil){
        mainVersion = @"";
    }
    NSDictionary *result = @{
        @"bundle_id": [[NSBundle mainBundle] bundleIdentifier],
        @"bundle_version": mainVersion
    };
    return [BDIRPCResponse responseToRequest:request WithResult:result];
}

@end

//
//  HMDConfigHelper.m
//  Heimdallr
//
//  Created by Nickyo on 2023/5/31.
//

#import "HMDConfigHelper.h"
#import "HMDNetworkProvider.h"
#import "NSDictionary+HMDSafe.h"

@implementation HMDConfigHelper

+ (NSDictionary *)requestHeaderFromProvider:(id<HMDNetworkProvider>)provider {
    if (provider == nil) {
        return nil;
    }
    NSParameterAssert([provider conformsToProtocol:@protocol(HMDNetworkProvider)]);
    NSParameterAssert([provider respondsToSelector:@selector(reportHeaderParams)]);
    NSParameterAssert([provider respondsToSelector:@selector(reportCommonParams)]);
    
    NSMutableDictionary *params = [[provider reportHeaderParams] mutableCopy];
    NSDictionary *commonParams = [provider reportCommonParams];
    if (commonParams != nil) {
        [params addEntriesFromDictionary:commonParams];
    }
    
    [params enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:NSNumber.class]) {
            [params hmd_setObject:[(NSNumber *)obj stringValue] forKey:key];
        }
    }];
    
    // When setting requests a url which contains 'minor_version' greater than or equal to one, distribution field will be api_block_list, request_allow_header and response_allow_header.
    // When setting requests a url which contains 'minor_version' less than one or doesn't contains 'minor_version', distribution field will be api_black_list, request_white_header and response_white_header.
    [params hmd_setObject:@"1" forKey:@"minor_version"];
    
    return [params copy];
}

static NSString * const kHMDSDKConfigHeaderInfoKey = @"HMDSDKConfigHeaderInfo_";

+ (NSString *)configHeaderKeyForAppID:(NSString *)appID {
    return [kHMDSDKConfigHeaderInfoKey stringByAppendingString:appID];
}

@end

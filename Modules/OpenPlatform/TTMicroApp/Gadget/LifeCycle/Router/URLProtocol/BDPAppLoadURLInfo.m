//
//  BDPAppLoadURLInfo.m
//  Timor
//
//  Created by 傅翔 on 2019/2/2.
//

#import "BDPAppLoadURLInfo.h"

#import <OPSDK/OPSDK-Swift.h>

@implementation BDPAppLoadURLInfo

+ (NSString * _Nonnull)uniqueKeyForURLRequest:(NSURLRequest *)urlRequest {
    if (!urlRequest) {
        return @"";
    }
    NSString *userAgent = [self userAgentFromURLRequest:urlRequest];
    return [NSString stringWithFormat:@"[%@]-[%@]", urlRequest.URL.absoluteString?:@"", userAgent?:@""];
}

+ (OPAppUniqueID * _Nullable)parseUniqueIDFromURLRequest:(NSURLRequest *)urlRequest {

    NSString *userAgent = [self userAgentFromURLRequest:urlRequest];
    if (!userAgent) {
        return nil;
    }
    
    NSRange uniqueIDRange = [userAgent rangeOfString:@"uniqueID/"];
    if (uniqueIDRange.length <= 0 || uniqueIDRange.location + uniqueIDRange.length > userAgent.length) {
        return nil;
    }
    userAgent = [userAgent substringFromIndex:uniqueIDRange.location + uniqueIDRange.length];
    NSRange firstSpaceRange = [userAgent rangeOfString:@" "];
    if (firstSpaceRange.location >= 0 && firstSpaceRange.length > 0) {
        userAgent = [userAgent substringToIndex:firstSpaceRange.location];
    }
    if (!userAgent.length) {
        return nil;
    }
    
    OPAppUniqueID *uniqueID = [OPAppUniqueID uniqueIDWithFullString:userAgent];
    if (!uniqueID.isValid) {
        return nil;
    }
    return uniqueID;
}

+ (NSString * _Nullable)userAgentFromURLRequest:(NSURLRequest *)urlRequest {
    if (!urlRequest) {
        return nil;
    }
    return [urlRequest valueForHTTPHeaderField:@"User-Agent"] ?: [urlRequest valueForHTTPHeaderField:@"user-agent"];
}

@end

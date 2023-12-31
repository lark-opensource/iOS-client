//
//  HMDTTNetHelper.h
//  Heimdallr
//
//  Created by fengyadong on 2018/1/29.
//

#import <Foundation/Foundation.h>
#import <TTNetworkManager/TTNetworkManager.h>

@interface HMDTTNetHelper : NSObject

+ (uint64_t)getRequestLengthForRequest:(TTHttpRequest *)request;
+ (uint64_t)getHeadersLength:(NSDictionary *)headers;
+ (NSDictionary<NSString *, NSString *> *)getCookiesForRequest:(TTHttpRequest *)request;
+ (uint64_t)getResponseLengthForResponse:(TTHttpResponse *)response body:(id)body;
+ (BOOL)isTTNetChromium;

@end

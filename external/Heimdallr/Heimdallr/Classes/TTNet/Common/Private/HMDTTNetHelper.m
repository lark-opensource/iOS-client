//
//  HMDTTNetHelper.m
//  Heimdallr
//
//  Created by fengyadong on 2018/1/29.
//

#import "HMDTTNetHelper.h"
#import <objc/runtime.h>
#import "HMDDynamicCall.h"

@implementation HMDTTNetHelper

+ (uint64_t)getRequestLengthForRequest:(TTHttpRequest *)request {
    NSDictionary<NSString *, NSString *> *headerFields = [request.allHTTPHeaderFields copy];
    NSDictionary<NSString *, NSString *> *cookiesHeader = [self getCookiesForRequest:request];
    if (cookiesHeader.count) {
        NSMutableDictionary *headerFieldsWithCookies = [NSMutableDictionary dictionaryWithDictionary:headerFields];
        [headerFieldsWithCookies addEntriesFromDictionary:cookiesHeader];
        headerFields = [headerFieldsWithCookies copy];
    }
    
    NSUInteger headersLength = [self getHeadersLength:headerFields];
    NSUInteger bodyLength = [request.HTTPBody length];
    return headersLength + bodyLength;
}

+ (uint64_t)getHeadersLength:(NSDictionary *)headers {
    int64_t headersLength = 0;
    if (headers && [NSJSONSerialization isValidJSONObject:headers]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:headers
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
        headersLength = data.length;
    }
    
    return headersLength;
}

+ (NSDictionary<NSString *, NSString *> *)getCookiesForRequest:(TTHttpRequest *)request {
    NSDictionary<NSString *, NSString *> *cookiesHeader;
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    if (request.URL) {
        NSArray<NSHTTPCookie *> *cookies = [cookieStorage cookiesForURL:request.URL];
        if (cookies.count) {
            cookiesHeader = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
        }
    }
    return cookiesHeader;
}

+ (uint64_t)getResponseLengthForResponse:(TTHttpResponse *)response body:(id)body {
    if (class_getProperty([TTHttpResponse class], "timinginfo")) {
        id timingInfo = DC_OB(response, timinginfo);
        Class timingInfoCls = NSClassFromString(@"TTHttpResponseTimingInfo");
        if (timingInfoCls &&
            class_getProperty(timingInfoCls, "totalReceivedBytes")) {
            id recievedBytes = DC_OB(timingInfo, totalReceivedBytes);
            return [recievedBytes isKindOfClass:[NSNumber class]] ? [recievedBytes unsignedIntegerValue] : 0;
        }
    }
    int64_t responseLength = 0;
    NSDictionary<NSString *, NSString *> *headerFields = [response.allHeaderFields copy];
    NSUInteger headersLength = [self getHeadersLength:headerFields];
    int64_t contentLength = 0;
    if (body && [body isKindOfClass:[NSData class]]) {
        contentLength += ((NSData *)body).length;
    } else if(body && [body isKindOfClass:[NSDictionary class]]){
        contentLength += [self getHeadersLength:body];
    }
    responseLength = headersLength + contentLength;
    return responseLength;
}

+ (BOOL)isTTNetChromium
{
    BOOL isChromium = [TTNetworkManager getLibraryImpl] == TTNetworkManagerImplTypeLibChromium;
    return isChromium;
}

@end

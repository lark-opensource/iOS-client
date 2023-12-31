//
//  HMDHTTPUtil.m
//  Heimdallr
//
//  Created by fengyadong on 2018/1/25.
//

#import "HMDHTTPUtil.h"

@implementation HMDHTTPUtil

+ (uint64_t)getRequestLengthForRequest:(NSURLRequest *)request streamLength:(NSInteger)streamLength {
    NSDictionary<NSString *, NSString *> *headerFields = request.allHTTPHeaderFields;
    NSDictionary<NSString *, NSString *> *cookiesHeader = [self getCookiesForRequest:request];
    if (cookiesHeader.count) {
        NSMutableDictionary *headerFieldsWithCookies = [NSMutableDictionary dictionaryWithDictionary:headerFields];
        [headerFieldsWithCookies addEntriesFromDictionary:cookiesHeader];
        headerFields = [headerFieldsWithCookies copy];
    }
    
    NSUInteger headersLength = [self getHeadersLength:headerFields];
    NSUInteger bodyLength = [request.HTTPBody length] ?: streamLength;
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

+ (NSDictionary<NSString *, NSString *> *)getCookiesForRequest:(NSURLRequest *)request {
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

+ (uint64_t)getResponseLengthForResponse:(NSURLResponse *)response bodyLength:(uint64_t)bodyLength {
    int64_t responseLength = 0;
    if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSDictionary<NSString *, NSString *> *headerFields = httpResponse.allHeaderFields;
        NSUInteger headersLength = [self getHeadersLength:headerFields];
        int64_t contentLength = (httpResponse.expectedContentLength != NSURLResponseUnknownLength) ?
        httpResponse.expectedContentLength :
        bodyLength;
        responseLength = headersLength + contentLength;
    }
    return responseLength;
}

@end

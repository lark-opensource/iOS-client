//
//  NSURLRequest+TSPKCommonRequest.m
//  TSPrivacyKit
//
//  Created by admin on 2022/9/2.
//

#import "NSURLRequest+TSPKCommonRequest.h"
#import "TSPKNetworkHostEnvProtocol.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <PNSServiceKit/PNSServiceCenter.h>

NSString *const TSPKNetworkSessionDropKey = @"TSPKNetworkSessionDropKey";
NSString *const TSPKNetworkSessionDropMessageKey = @"TSPKNetworkSessionDropMessageKey";
NSString *const TSPKNetworkSessionDropCodeKey = @"TSPKNetworkSessionDropCodeKey";
NSString *const TSPKNetworkSessionHandleKey = @"TSPKNetworkSessionHandleKey";

@implementation NSURLRequest (TSPKCommonRequest)

- (NSURL *)tspk_util_url {
    return self.URL;
}

- (void)setTspk_util_url:(NSURL *)tspk_util_url {}

- (NSDictionary<NSString *,NSString *> *)tspk_util_headers {
    return self.allHTTPHeaderFields;
}

- (NSData *)tspk_util_HTTPBody {
    return self.HTTPBody;
}

- (NSInputStream *)tspk_util_HTTPBodyStream {
    return self.HTTPBodyStream;
}

- (NSString *)tspk_util_HTTPMethod {
    return self.HTTPMethod;
}

- (NSString *)tspk_util_eventType {
    return @"urlprotocol";
}

- (NSString *)tspk_util_eventSource {
    Class<TSPKNetworkHostEnvProtocol> env = PNS_GET_CLASS(TSPKNetworkHostEnvProtocol);
    if ([env respondsToSelector:@selector(eventSourceFromRequest:)]) {
        NSString *source = [env eventSourceFromRequest:self];
        return source != nil? source: @"urlprotocol";
    }
    return @"urlprotocol";
}

- (BOOL)tspk_util_isRedirect {
    return NO;
}

- (void)tspk_util_setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    // if request need to change headers
    // plz use NSMutableURLRequest
    NSAssert(false, @"plz use NSMutableURLRequest");
}

- (NSString *)tspk_util_valueForHTTPHeaderField:(NSString *)field {
    return [self valueForHTTPHeaderField:field];
}

- (void)tspk_util_doDrop:(NSDictionary *)actions {
    // abandon other actions, if request need to be dropped
    // plz use NSMutableURLRequest
    NSAssert(false, @"plz use NSMutableURLRequest");
}

@end

@implementation NSMutableURLRequest (TSPKCommonRequest)

- (NSURL *)tspk_util_url {
    return self.URL;
}

- (void)setTspk_util_url:(NSURL *)tspk_util_url {
    self.URL = tspk_util_url;
}

- (NSDictionary<NSString *,NSString *> *)tspk_util_headers {
    return self.allHTTPHeaderFields;
}

- (NSData *)tspk_util_HTTPBody {
    return self.HTTPBody;
}

- (NSInputStream *)tspk_util_HTTPBodyStream {
    return self.HTTPBodyStream;
}

- (NSString *)tspk_util_HTTPMethod {
    return self.HTTPMethod;
}

- (NSString *)tspk_util_eventType {
    return @"urlprotocol";
}

- (NSString *)tspk_util_eventSource {
    Class<TSPKNetworkHostEnvProtocol> env = PNS_GET_CLASS(TSPKNetworkHostEnvProtocol);
    if ([env respondsToSelector:@selector(eventSourceFromRequest:)]) {
        NSString *source = [env eventSourceFromRequest:self];
        return source != nil? source: @"urlprotocol";
    }
    return @"urlprotocol";
}

- (BOOL)tspk_util_isRedirect {
    return NO;
}

- (void)tspk_util_setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [self setValue:value forHTTPHeaderField:field];
}

- (NSString *)tspk_util_valueForHTTPHeaderField:(NSString *)field {
    return [self valueForHTTPHeaderField:field];
}

- (void)tspk_util_doDrop:(NSDictionary *)actions {
    // abandon other actions, if request need to be dropped
    [NSURLProtocol setProperty:@(YES) forKey:TSPKNetworkSessionDropKey inRequest:self];
    [NSURLProtocol setProperty:[actions btd_stringValueForKey:@"message" default:@"dropped by TSPKNetworkURLProtocol"] forKey:TSPKNetworkSessionDropMessageKey inRequest:self];
    [NSURLProtocol setProperty:[actions btd_numberValueForKey:@"code" default:@-98] forKey:TSPKNetworkSessionDropCodeKey inRequest:self];
}

@end

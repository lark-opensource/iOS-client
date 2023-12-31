//
//  TTRedirectTask+TSPKCommonRequest.m
//  Musically
//
//  Created by admin on 2022/10/18.
//

#import "TTRedirectTask+TSPKCommonRequest.h"
#import "TSPKNetworkHostEnvProtocol.h"
#import <PNSServiceKit/PNSServiceCenter.h>

@implementation TTRedirectTask (TSPKCommonRequest)

- (NSURL *)tspk_util_url {
    return self.redirectUrl;
}

- (void)setTspk_util_url:(NSURL *)tspk_url {
    self.redirectUrl = tspk_url;
}

- (NSDictionary<NSString *,NSString *> *)tspk_util_headers {
    return self.allHTTPHeaderFields;
}

- (NSData *)tspk_util_HTTPBody {
    return nil;
}

- (NSInputStream *)tspk_util_HTTPBodyStream {
    return nil;
}

- (NSString *)tspk_util_HTTPMethod {
    return @"";
}

- (NSString *)tspk_util_eventType {
    return @"ttnet";
}

- (NSString *)tspk_util_eventSource {
    Class<TSPKNetworkHostEnvProtocol> env = PNS_GET_CLASS(TSPKNetworkHostEnvProtocol);
    if ([env respondsToSelector:@selector(eventSourceFromRequest:)]) {
        NSString *source = [env eventSourceFromRequest:self];
        return source != nil? source: @"webview";
    }
    return @"webview";
}

- (BOOL)tspk_util_isRedirect {
    return YES;
}

- (void)tspk_util_setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    NSDictionary<NSString *, NSString *> *allHeader = self.allHTTPHeaderFields.copy;
    for (NSString *key in allHeader) {
        if([key caseInsensitiveCompare:field] == NSOrderedSame) {
            [self setValue:value forHeader:key];
            return;
        }
    }
    [self setValue:value forHeader:field];
}

- (NSString *)tspk_util_valueForHTTPHeaderField:(NSString *)field {
    for (NSString *key in self.allHTTPHeaderFields) {
        if([key caseInsensitiveCompare:field] == NSOrderedSame) {
            return self.allHTTPHeaderFields[key];
        }
    }
    return nil;
}

- (void)tspk_util_doDrop:(NSDictionary *)actions {
    [self cancel];
}

@end

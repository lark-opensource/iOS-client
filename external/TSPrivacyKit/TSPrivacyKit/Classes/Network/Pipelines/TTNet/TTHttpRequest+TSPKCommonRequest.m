//
//  TTHttpRequest+TSPKCommonRequest.m
//  TSPrivacyKit
//
//  Created by admin on 2022/9/2.
//

#import "TTHttpRequest+TSPKCommonRequest.h"
#import "TSPKNetworkHostEnvProtocol.h"
#import <PNSServiceKit/PNSServiceCenter.h>
#import <TTNetworkManager/TTNetworkManager.h>

@implementation TTHttpRequest (TSPKCommonRequest)

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
    return nil;
}

- (NSString *)tspk_util_HTTPMethod {
    return self.HTTPMethod;
}

- (NSString *)tspk_util_eventType {
    return @"ttnet";
}

- (NSString *)tspk_util_eventSource {
    Class<TSPKNetworkHostEnvProtocol> env = PNS_GET_CLASS(TSPKNetworkHostEnvProtocol);
    if ([env respondsToSelector:@selector(eventSourceFromRequest:)]) {
        NSString *source = [env eventSourceFromRequest:self];
        return source != nil? source: @"ttnet";
    }
    return @"ttnet";
}

- (BOOL)tspk_util_isRedirect {
    return NO;
}

- (void)tspk_util_setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    NSDictionary<NSString *, NSString *> *allHeader = self.allHTTPHeaderFields.copy;
    for (NSString *key in allHeader) {
        if([key caseInsensitiveCompare:field] == NSOrderedSame) {
            [self setValue:value forHTTPHeaderField:key];
            return;
        }
    }
    [self setValue:value forHTTPHeaderField:field];
}

- (NSString *)tspk_util_valueForHTTPHeaderField:(NSString *)field {
    for (NSString *key in self.allHTTPHeaderFields) {
        if([key caseInsensitiveCompare:field] == NSOrderedSame) {
            return [self valueForHTTPHeaderField:key];
        }
    }
    return nil;
}

- (void)tspk_util_doDrop:(NSDictionary *)actions {
    [self setValue:@"1" forHTTPHeaderField:kTTNetNeedDropClientRequest];
}

@end

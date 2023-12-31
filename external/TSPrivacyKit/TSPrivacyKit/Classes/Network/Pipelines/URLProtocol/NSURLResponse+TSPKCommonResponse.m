//
//  NSURLResponse+TSPKCommonResponse.m
//  TSPrivacyKit
//
//  Created by admin on 2022/9/2.
//

#import "NSURLResponse+TSPKCommonResponse.h"

@implementation NSURLResponse (TSPKCommonResponse)

- (NSURL *)tspk_util_url {
    return self.URL;
}

- (NSDictionary<NSString *,NSString *> *)tspk_util_headers {
    if ([self isKindOfClass:[NSHTTPURLResponse class]]) {
        return ((NSHTTPURLResponse *)self).allHeaderFields;
    }
    return nil;
}

- (NSString *)tspk_util_valueForHTTPHeaderField:(NSString *)field {
    if ([self isKindOfClass:[NSHTTPURLResponse class]]) {
        if (@available(iOS 13.0, *)) {
            return [((NSHTTPURLResponse *)self) valueForHTTPHeaderField:field];
        }
    }
    return nil;
}

@end

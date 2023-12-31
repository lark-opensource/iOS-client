//
//  TTHttpResponse+TSPKCommonResponse.m
//  TSPrivacyKit
//
//  Created by admin on 2022/9/2.
//

#import "TTHttpResponse+TSPKCommonResponse.h"

@implementation TTHttpResponse (TSPKCommonResponse)

- (NSURL *)tspk_util_url {
    return self.URL;
}

- (NSDictionary<NSString *,NSString *> *)tspk_util_headers {
    return self.allHeaderFields;
}

- (NSString *)tspk_util_valueForHTTPHeaderField:(NSString *)field {
    return [self.allHeaderFields valueForKey:field];
}

@end

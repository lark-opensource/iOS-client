//
//  BytedCertNetResponse.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/14.
//

#import "BytedCertNetResponse.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>


@implementation BytedCertNetResponse

+ (instancetype)responseWithTTNetHttpResponse:(TTHttpResponse *)httpResponse {
    return [[BytedCertNetResponse alloc] initWithStatusCode:httpResponse.statusCode logId:[httpResponse.allHeaderFields btd_stringValueForKey:@"x-tt-logid"]];
}

- (instancetype)initWithStatusCode:(NSInteger)statusCode logId:(NSString *)logId {
    self = [super init];
    if (self) {
        _statusCode = statusCode;
        _logId = logId;
    }
    return self;
}

@end

//
//  BDHMJSBErrorModel+WebError.m
//  IESWebViewMonitor
//
//  Created by zhangxiao on 2021/7/26.
//

#import "BDHMJSBErrorModel+WebError.h"

@implementation BDHMJSBErrorModel (WebError)

- (NSDictionary *)webJSBFetchErrorDict {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@"fetchError" forKey:@"event_type"];
    [dict setValue:self.url?:@"unknown" forKey:@"url"];
    [dict setValue:self.method?:@"unknown" forKey:@"method"];
    [dict setValue:@(self.bridgeCode) forKey:@"jsb_ret"];
    [dict setValue:@(self.httpCode) forKey:@"status_code"];

    [dict setValue:@(self.errorCode) forKey:@"error_no"];
    if (self.errorMsg) {
        [dict setValue:self.errorMsg forKey:@"error_msg"];
    }

    [dict setValue:@(self.requestErrorCode) forKey:@"request_error_code"];
    if (self.requestErrorMsg) {
        [dict setValue:self.requestErrorMsg forKey:@"request_error_msg"];
    }

    return [dict copy];
}

@end

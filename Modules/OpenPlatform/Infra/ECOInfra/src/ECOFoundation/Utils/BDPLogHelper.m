//
//  BDPLogHelper.m
//  Timor
//
//  Created by houjihu on 2018/9/30.
//

#import "BDPLogHelper.h"
#import <ECOInfra/BDPLog.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/BDPUtils.h>
#import "NSString+BDPExtension.h"
static NSString * const RequestTag = @"Request";

@implementation BDPLogHelper

+ (void)logRequestBeginWithEventName:(NSString * _Nullable)eventName URLString:(NSString * _Nullable)URLString withTrace:(NSString *)traceId {
    NSString *safeUrl = [self safeURLString:URLString];
    BDPLogTagInfo(RequestTag, @"beginRequest url=%@, event=%@, trace=%@", safeUrl, eventName, traceId);
}

+ (void)logRequestBeginWithEventName:(NSString * _Nullable)eventName URLString:(NSString * _Nullable)URLString {
    NSString *safeUrl = [self safeURLString:URLString];
    BDPLogTagInfo(RequestTag, @"beginRequest url=%@, event=%@, trace=nil", safeUrl, eventName);
}

+ (void)logRequestEndWithEventName:(NSString * _Nullable)eventName URLString:(NSString * _Nullable)URLString URLResponse:(NSURLResponse * _Nullable)URLResponse {
    NSHTTPURLResponse *httpResponse = [URLResponse isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)URLResponse: nil;
    NSString *safeUrl = [self safeURLString:URLString];
    BDPLogTagInfo(RequestTag, @"endRequest url=%@, event=%@, code=%@", safeUrl, eventName, httpResponse ? [NSString stringWithFormat:@"%ld", (long)httpResponse.statusCode] : @"");
}

+ (void)logRequestEndWithEventName:(NSString * _Nullable)eventName URLString:(NSString * _Nullable)URLString error:(NSError * _Nullable)error {
    NSString *safeUrl = [self safeURLString:URLString];
    if (error) {
        BDPLogTagWarn(RequestTag, @"endRequest url=%@, event=%@, error=%@", safeUrl, eventName, error);
    } else {
        BDPLogTagInfo(RequestTag, @"endRequest url=%@, event=%@, error=%@", safeUrl, eventName,error);

    }
}

+ (nullable NSString *)safeURLString:(NSString  * _Nullable)url {
    if (!url) {
        BDPLogInfo(@"Empty url received for [safeURLString].");
        return nil;
    }
    if (![url isKindOfClass:[NSString class]]) {
        NSAssert(NO, @"safeURLString url param must be NSString! But received %@ .", [url class]);
        return nil;
    }
    return [NSString safeURLString:url];
}

+ (nullable NSString *)safeURL:(NSURL * _Nullable)url {
    if (!url) {
        BDPLogInfo(@"Empty url received for [safeURL].");
        return nil;
    }
    if (![url isKindOfClass:[NSURL class]]) {
        NSAssert(NO, @"safeURL url param must be NSURL! But received %@ .", [url class]);
        return nil;
    }
    return [self safeURLString:url.absoluteString];
}
@end

//
//  OPTrace+RequestID.m
//  ECOProbe
//
//  Created by MJXin on 2021/4/9.
//

#import "OPTrace+RequestID.h"
#import <objc/runtime.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/NSString+BDPExtension.h>

static char kOPTraceRequestIDKey;
static NSUInteger TracingRequestSequencyID = 0;
static const NSString *kTracingRequestSequencyIDAlphabet = @"bqve5m0k467dfrxnghctisu91w8jloa2yp3z";

@implementation OPTrace (RequestID)
+ (NSString *)uuid:(NSString *)source {
    static NSString *sourceStr;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sourceStr = [NSString stringWithFormat:@"%@.%@.%@", [ECONetworkDependency deviceID], [[NSUUID UUID] UUIDString], @([NSDate date].timeIntervalSince1970)];
    });
    return [[NSString stringWithFormat:@"%@%@", sourceStr, source] bdp_md5];
}

+ (NSString *)sequency {
    NSUInteger sequencyId;
    @synchronized (self) {
        sequencyId = TracingRequestSequencyID;
        TracingRequestSequencyID += 1;
    }
    NSMutableString *sequency = [NSMutableString string];
    NSUInteger length = kTracingRequestSequencyIDAlphabet.length;
    while (sequencyId > 0) {
        NSUInteger index = sequencyId % length;
        sequencyId = sequencyId / length;
        [sequency appendFormat:@"%C", [kTracingRequestSequencyIDAlphabet characterAtIndex:index]];
    }
    while (sequency.length < 6) {
        [sequency appendFormat:@"%C", [kTracingRequestSequencyIDAlphabet characterAtIndex:0]];
    }
    return [sequency copy];
}

- (void)genRequestID:(NSString *)source {
    if ([self getRequestID]) {
        return;
    }
    NSString *timeStr = [NSString stringWithFormat:@"%@", @((NSInteger)(1000 * [NSDate.date timeIntervalSince1970]))];
    NSString *requestID = [NSString stringWithFormat:@"02%@%@%@", timeStr, [OPTrace uuid: source], [OPTrace sequency]];
    objc_setAssociatedObject(self, &kOPTraceRequestIDKey, requestID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable NSString *)getRequestID {
    return objc_getAssociatedObject(self, &kOPTraceRequestIDKey);
}

@end

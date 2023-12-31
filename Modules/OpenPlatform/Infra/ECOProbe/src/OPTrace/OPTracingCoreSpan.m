//
//  OPTrace.m
//  LarkOPInterface
//
//  Created by changrong on 2020/9/10.
//

#import "OPTracingCoreSpan.h"
#import "OPTraceConstants.h"
#import "NSDictionary+ECOExtensions.h"

@interface OPTracingCoreSpan()

@property (nonatomic, strong) NSString *traceId;
@property (nonatomic, assign) NSTimeInterval createTime;

- (instancetype)initWithJSONDict:(NSDictionary *)json NS_DESIGNATED_INITIALIZER;

@end

@implementation OPTracingCoreSpan

- (instancetype)initWithTraceId:(NSString *)traceId {
    self = [super init];
    if (self) {
        self.traceId = traceId;
        self.createTime = [[NSProcessInfo processInfo] systemUptime];
    }
    return self;
}

- (nullable instancetype)initWithJSONDict:(NSDictionary *)json {
    self = [super init];
    if(self) {
        NSString *traceId = [json eco_stringValueForKey: kTraceSerializeKeyTraceId];
        NSTimeInterval createTime = [json eco_doubleValueForKey: kTraceSerializeKeyCreateTime];
        if (traceId && createTime) {
            self.traceId = traceId;
            self.createTime = createTime;
        } else {
            NSAssert(NO, @"OPTracingCoreSpan parse from json failed! traceId or time not valid!");
            return nil;
        }
    }
    return self;
}

#pragma mark OPTraceProtocol

- (nonnull id<OPTraceProtocol>)subTrace {
    NSAssert(NO, @"OPTracingCoreSpan is internal, use OPTrace please!");
    return nil;
}

- (NSString * _Nullable)serialize {
    NSAssert(NO, @"OPTracingCoreSpan is internal, use OPTrace please!");
    return nil;
}

- (OPMonitorServiceConfig * _Nonnull)config {
    NSAssert(NO, @"OPTracingCoreSpan is internal, use OPTrace please!");
    return nil;
}

+ (instancetype _Nullable)deserializeFrom:(nonnull NSString *)json {
    NSAssert(NO, @"OPTracingCoreSpan is internal, use OPTrace please!");
    return nil;
}

- (void)finish {
    NSAssert(NO, @"OPTracingCoreSpan is internal, use OPTrace please!");
}

- (void)flush:(nonnull OPMonitorEvent *)monitor platform:(OPMonitorReportPlatform)platform {
    NSAssert(NO, @"OPTracingCoreSpan is internal, use OPTrace please!");
}

- (void)log:(nonnull OPMonitorEvent *)monitor {
    NSAssert(NO, @"OPTracingCoreSpan is internal, use OPTrace please!");
}

@end

//
//  BDPTracing.m
//  Timor
//
//  Created by Chang Rong on 2020/2/17.
//

#import "BDPTracing.h"
#import <ECOInfra/BDPLog.h>
#import "BDPTracingExtension.h"
#import "BDPTracingClientDurationExtension.h"
#import "BDPMonitorHelper.h"
#import "BDPMonitorEvent.h"

typedef NS_ENUM(NSInteger, BDPTracingExtensionType) {
    BDPTracingExtensionTypeUnknown = 0,
    BDPTracingExtensionTypeClientDuration, ///<<<ClientDuration
};

@interface BDPTracing()

@property (nonatomic, strong) NSString *traceId;
@property (nonatomic, assign) NSInteger createTime;
@property (nonatomic, strong) NSDictionary<NSNumber *, id<BDPTracingExtension>> *extensions;

@end

@interface BDPTracing(Extension)

- (void)setupExtension;

@end

@implementation BDPTracing

- (instancetype)initWithTraceId:(NSString *)traceId {
    self = [super initWithTraceId:traceId];
    if (self) {
        self.createTime = [[NSProcessInfo processInfo] systemUptime] * 1000;
        [self setupExtension];
    }
    return self;
}

@end

@implementation BDPTracing(Extension)
/**
 * 挂载所有支持的extension，目前支持：
 * - ClientDurationExtension
 *
 */
- (void)setupExtension {
    NSMutableDictionary *extesions = [NSMutableDictionary dictionary];
    extesions[@(BDPTracingExtensionTypeClientDuration)] = [[BDPTracingClientDurationExtension alloc] init];
    self.extensions = [extesions copy];
}

/**
 * link_trace 作为tracing能力的一部分，当发生merge时，自动埋点 mp_app_event_link
 * 依据当前tracing，遍历所有extension，并调用协议的merge
 */
- (void)linkTracing:(BDPTracing *)linkedTracing {
    BDPMonitorWithName(kEventName_mp_app_event_link, nil).bdpTracing(self).kv(@"link_trace_id", linkedTracing.traceId).flush();
    [self.extensions enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, id<BDPTracingExtension>  _Nonnull obj, BOOL * _Nonnull stop) {
        id<BDPTracingExtension> extension = linkedTracing.extensions[key];
        if (!extension) {
            return;
        }
        [obj mergeExtension:extension];
    }];
}

@end

@implementation BDPTracing(ClientDurationExtension)

- (BDPTracingClientDurationExtension *)clientDurationExtension {
    return self.extensions[@(BDPTracingExtensionTypeClientDuration)];
}

- (void)clientDurationTagStart:(NSString *)key {
    [self.clientDurationExtension start:key];
}

- (NSInteger)clientDurationTagEnd:(NSString *)startKey {
    return [self.clientDurationExtension end:startKey];
}

- (NSInteger)clientDurationFor:(NSString *)startKey{
    return [self.clientDurationExtension endDuration:startKey];
}

- (NSInteger)endDuration:(NSString *)startKey timestamp:(NSInteger)timestamp{
    return [self.clientDurationExtension endDuration:startKey timestamp:timestamp];
}

@end


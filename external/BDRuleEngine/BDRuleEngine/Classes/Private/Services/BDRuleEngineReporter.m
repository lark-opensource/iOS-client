//
//  BDRuleEngineReporter.m
//  Indexer
//
//  Created by WangKun on 2021/12/20.
//

#import "BDRuleEngineReporter.h"
#import "BDRuleEngineSettings.h"
#import "BDRuleEngineDelegateCenter.h"
#import "NSDictionary+BDRESafe.h"

#import <PNSServiceKit/PNSTrackerProtocol.h>
#import <PNSServiceKit/PNSMonitorProtocol.h>

NSString * const BDRELogNameStrategyExecute      = @"rule_engine_execute_result";
NSString * const BDRELogNameStrategyGenerate     = @"rule_engine_generate_strategies";
NSString * const BDRELogNameExpressionExecute    = @"event_expr_execute";
NSString * const BDRELogNameRulerStart           = @"ruler_start_time_consuming";
NSString * const BDRELogNameExpressionExecuteAbnormal = @"rule_execute_error";

NSString * const BDRELogSampleTagSourceKey       = @"source";
NSString * const BDRELogStartEventSourceValue    = @"start";
NSString * const BDRELogExprExecEventSourceValue = @"expr";
NSString * const BDRElogExprExecErrorSourceValue = @"error";
NSString * const BDRELogStartEventDelayTimeKey   = @"first_start";

@interface BDREReportContent ()

@property (nonatomic, strong, nullable) NSDictionary *metric; /// 测量指标
@property (nonatomic, strong, nullable) NSDictionary *category; /// 维度信息
@property (nonatomic, strong, nullable) NSDictionary *extra; /// 额外信息

@end

@implementation BDREReportContent

- (instancetype)initWithMetric:(NSDictionary *)metric category:(NSDictionary *)category extra:(NSDictionary *)extra
{
    if (self = [super init]) {
        _metric = metric;
        _category = category;
        _extra = extra;
    }
    return self;
}

@end

@implementation BDRuleEngineReporter

static dispatch_queue_t reportQueue() {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("queue-BDRuleEngineReport", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (id<PNSTrackerProtocol>)tracker
{
    static id<PNSTrackerProtocol> tracker;
    if (!tracker) {
        tracker = PNSTracker;
    }
    return tracker;
}

+ (id<PNSMonitorProtocol>)monitor
{
    static id<PNSMonitorProtocol> monitor;
    if (!monitor) {
        monitor = PNSMonitor;
    }
    return monitor;
}

+ (void)delayLog:(NSString *)event
            tags:(NSDictionary *)tags
           block:(BDRuleEngineReportDataBlock)block
{
    NSDictionary *globalSample = [BDRuleEngineSettings globalSampleRate];
    NSNumber *delayTime = [globalSample bdre_numberForKey:BDRELogStartEventDelayTimeKey] ?: @5;
    [self log:event tags:tags delay:[delayTime unsignedIntegerValue] block:block];
}

+ (void)log:(NSString *)event
       tags:(NSDictionary *)tags
      block:(BDRuleEngineReportDataBlock)block
{
    [self log:event tags:tags delay:0 block:block];
}

+ (void)log:(NSString *)event
       tags:(NSDictionary *)tags
      delay:(NSUInteger)delay
      block:(BDRuleEngineReportDataBlock)block
{
    if (!block) {
        return;
    }
    
    id<BDRuleEngineDelegate> delegate = [BDRuleEngineDelegateCenter delegate];
    if (delegate) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), reportQueue(), ^{
            [delegate report:event tags:tags block:block];
        });
        return;
    }
    
    if (![BDRuleEngineReporter shouldSampleWithTags:tags]) {
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), reportQueue(), ^{
        id<BDRuleEngineReportDataSource> content = block();
        [BDRuleEngineReporter log:event metric:content.metric category:content.category extra:content.extra];
    });
}

+ (void)log:(NSString *)event
     metric:(NSDictionary *)metric
   category:(NSDictionary *)category
      extra:(NSDictionary *)extra
{
    if ([BDRuleEngineSettings enableAppLog]) {
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        if (metric) {
            [params addEntriesFromDictionary:metric];
        }
        if (category) {
            [params addEntriesFromDictionary:category];
        }
        if (extra) {
            [params addEntriesFromDictionary:extra];
        }
        
        [[self tracker] event:event params:[params copy]];
    }
    [[self monitor] trackService:event metric:metric category:category attributes:extra];
}

+ (BOOL)shouldSampleWithTags:(NSDictionary *)tags
{
    NSString *source = [tags bdre_stringForKey:BDRELogSampleTagSourceKey];
    NSDictionary *globalSample = [BDRuleEngineSettings globalSampleRate];
    NSNumber *globalRate = [globalSample bdre_numberForKey:source] ?: @10000;
    if (![globalRate unsignedIntegerValue]) {
        return NO;
    }
    UInt64 timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    if (timeStamp % [globalRate unsignedIntegerValue]) {
        return NO;
    }
    return YES;
}

@end

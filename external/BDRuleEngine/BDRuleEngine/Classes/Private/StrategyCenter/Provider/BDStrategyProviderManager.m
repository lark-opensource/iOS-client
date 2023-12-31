//
//  BDStrategyProviderManager.m
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by PengYan on 2021/12/10.
//

#import "BDStrategyProviderManager.h"

#import "BDStrategyProvider.h"
#import "BDStrategyUpdateProtocol.h"
#import "BDRuleEngineConstant.h"
#import "BDRuleEngineLogger.h"
#import "BDRuleEngineReporter.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>

@interface BDStrategyProviderManager ()

@property (nonatomic, copy) NSArray<id<BDStrategyProvider>> *providers;

@end

@implementation BDStrategyProviderManager

- (void)registerStrategyProvider:(id<BDStrategyProvider>)provider
{
    NSMutableArray *result = self.providers.count ? [self.providers mutableCopy] : [NSMutableArray array];
    [result btd_addObject:provider];
    
    [result sortUsingComparator:^NSComparisonResult(id<BDStrategyProvider> obj1, id<BDStrategyProvider> obj2) {
        if (obj1.priority < obj2.priority) {
            return NSOrderedAscending;
        } else if (obj1.priority > obj2.priority) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    self.providers = [NSArray arrayWithArray:result];
}

#pragma mark - private
- (instancetype)init
{
    if (self = [super init]) {
        [self addNotification];
    }
    return self;
}

- (void)dealloc
{
    [self removeNotification];
}

- (void)addNotification
{
    // add strategy update notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(listenStrategyUpdate)
                                                 name:BDStrategyUpdateNotification
                                               object:nil];
}

- (void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)listenStrategyUpdate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self fetchStrategyAndPreprocess];
    });
}

- (NSDictionary *)fetchStrategy
{
    NSDictionary *strategies = @{};
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    for (NSInteger index = self.providers.count - 1; index >= 0; index--) {
        id<BDStrategyProvider> provider = [self.providers btd_objectAtIndex:index];
        NSDictionary *providerStrategies = [provider strategies];
        if (providerStrategies) {
            strategies = providerStrategies;
            break;
        }
    }
    CFTimeInterval costTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000000;
    [BDRuleEngineReporter delayLog:BDRELogNameRulerStart tags:@{BDRELogSampleTagSourceKey : BDRELogStartEventSourceValue} block:^id<BDRuleEngineReportDataSource> _Nonnull{
        return [[BDREReportContent alloc] initWithMetric:@{
            @"cost": @(costTime)
        } category:@{
            @"event_name": @"rule_engine_fetch_strategy"
        } extra:nil];
    }];
    return strategies;
}

- (void)fetchStrategyAndPreprocess
{
    NSDictionary *strategies = [self fetchStrategy];
    if (![strategies count]) {
        NSAssert(NO, @"not strategy in providers");
        return;
    }
    
    [self.delegate preprocessStrategy:strategies];
}

@end

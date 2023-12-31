//
//  TSPKRuleEngineSubscriber.h
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/30.
//

#import <Foundation/Foundation.h>
#import "TSPKSubscriber.h"
#import "TSPKEvent.h"
#import <PNSServiceKit/PNSBacktraceProtocol.h>
#import <PNSServiceKit/PNSRuleEngineProtocol.h>

extern NSString *_Nullable const TSPKRuleEngineAction;

extern NSString *_Nullable const TSPKRuleEngineActionFuse;
extern NSString *_Nullable const TSPKRuleEngineActionReport;
extern NSString *_Nullable const TSPKRuleEngineActionDowngrade;
extern NSString *_Nullable const TSPKRuleEngineActionCache;

extern NSString *_Nullable const TSPKMethodGuardFuseField;
extern NSString *_Nullable const TSPKMethodGuardField;

@interface TSPKRuleEngineSubscriber : NSObject<TSPKSubscriber>

- (nullable NSDictionary *)convertEventDataToParams:(nullable TSPKEventData *)eventData source:(nullable NSString *)source;
- (void)reportInfoWithParams:(nullable NSDictionary *)params
                ruleSetNames:(NSArray<NSString *> *_Nullable)ruleSetNames
                  ruleResult:(nullable id <PNSSingleRuleResultProtocol>)ruleResult
              usedParameters:(nullable NSDictionary *)usedParameters
                    needFuse:(BOOL)needFuse
                  backtraces:(nullable NSArray *)backtraces
                   eventData:(nullable TSPKEventData *)eventData
                   signature:(nullable NSString *)signature;

- (void)appendExecuteResult:(nullable id<PNSRuleResultProtocol>)result
                toEventData:(nullable TSPKEventData *)eventData
                      input:(nullable NSDictionary *)input;

@end

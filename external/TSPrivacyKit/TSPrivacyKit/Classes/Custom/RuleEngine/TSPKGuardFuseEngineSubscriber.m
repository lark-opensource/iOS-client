//
//  TSPKGuardFuseEngineSubscriber.m
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/30.
//

#import "TSPKGuardFuseEngineSubscriber.h"
#import "TSPKReporter.h"
#import "TSPKStatisticEvent.h"
#import <PNSServiceKit/PNSRuleEngineProtocol.h>
#import <PNSServiceKit/PNSServiceCenter.h>

@implementation TSPKGuardFuseEngineSubscriber

- (NSString *)uniqueId {
    return @"TSPKGuardFuseEngineSubscriber";
}

- (TSPKHandleResult *)hanleEvent:(TSPKEvent *)event {
    NSArray *backtraces = event.eventData.apiModel.backtraces;
    NSDictionary *params = [self convertEventDataToParams:event.eventData source:TSPKRuleEngineSpaceGuardFuse];

    id<PNSRuleResultProtocol> results = [PNS_GET_INSTANCE(PNSRuleEngineProtocol) validateParams:params];
    [self appendExecuteResult:results toEventData:event.eventData input:params];

    if (results.values.count > 0) {
        TSPKHandleResult *result;
        for (id<PNSSingleRuleResultProtocol> singleRuleResult in results.values) {
            if ([singleRuleResult.conf[TSPKRuleEngineAction] isEqualToString:TSPKRuleEngineActionFuse]) {
                // when result conf is fuse, get backtraces
                if (backtraces == nil) {
                    backtraces = [PNS_GET_INSTANCE(PNSBacktraceProtocol) getBacktracesWithSkippedDepth:0 needAllThreads:NO];
                }
                // assign when result is nil
                if (result == nil) {
                    result = [TSPKHandleResult new];
                    result.action = TSPKResultActionFuse;
                    result.returnValue = singleRuleResult.conf[@"fuse_result"][params[@"api"]];
                }
                
                [self reportInfoWithParams:params ruleSetNames:results.ruleSetNames ruleResult:singleRuleResult usedParameters:results.usedParameters needFuse:YES backtraces:backtraces eventData:event.eventData signature:results.signature];
            }
        }
        
        if (result) {
            return result;
        }
    }
    return nil;
}

@end

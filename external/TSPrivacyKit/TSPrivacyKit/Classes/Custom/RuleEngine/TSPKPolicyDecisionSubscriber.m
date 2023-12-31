//
//  TSPKPolicyDecisionSubscriber.m
//  Musically
//
//  Created by ByteDance on 2022/11/16.
//

#import "TSPKPolicyDecisionSubscriber.h"
#import "TSPrivacyKitConstants.h"
#import <PNSServiceKit/PNSPolicyDecisionProtocol.h>

@implementation TSPKPolicyDecisionSubscriber

- (NSString *)uniqueId {
    return @"TSPKPolicyDecisionSubscriber";
}

- (TSPKHandleResult *)hanleEvent:(TSPKEvent *)event {
    TSPKAPIUsageType usageType = event.eventData.apiModel.apiUsageType;
    if (usageType == TSPKAPIUsageTypeInfo) {
        return nil;
    }
    
    NSArray *backtraces = event.eventData.apiModel.backtraces;
    NSDictionary *params = [self convertEventDataToParams:event.eventData source:TSPKRuleEngineSpacePolicyDecision];
    
    id<PNSPDPResultProtocol> policyDecisionResults = [PNS_GET_INSTANCE(PNSPolicyDecisionProtocol) validatePolicyWithSource:TSPKPolicyDecisionSourceGuard entryToken:event.eventData.apiModel.entryToken context:params wrappedAPI:nil];
    
    id<PNSRuleResultProtocol> results = policyDecisionResults.result;
    
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
        
        for (id<PNSSingleRuleResultProtocol> singleRuleResult in results.values) {
            if ([singleRuleResult.conf[TSPKRuleEngineAction] isEqualToString:TSPKRuleEngineActionReport]) {
                // when result conf is upload, get backtraces
                if (backtraces == nil) {
                    backtraces = [PNS_GET_INSTANCE(PNSBacktraceProtocol) getBacktracesWithSkippedDepth:0 needAllThreads:NO];
                }
                [self reportInfoWithParams:params ruleSetNames:results.ruleSetNames ruleResult:singleRuleResult usedParameters:results.usedParameters needFuse:NO backtraces:backtraces eventData:event.eventData signature:results.signature];
            } else if ([singleRuleResult.conf[TSPKRuleEngineAction] isEqualToString:TSPKRuleEngineActionDowngrade]) {
                if (backtraces == nil) {
                    backtraces = [PNS_GET_INSTANCE(PNSBacktraceProtocol) getBacktracesWithSkippedDepth:0 needAllThreads:NO];
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    for (__attribute__((unused)) TSPKEvent *unreleaseEvent in event.eventData.subEvents) {
                        TSPKDowngradeAction action = event.eventData.apiModel.downgradeAction;
                        !action ?: action();
                    }
                    [self reportInfoWithParams:params ruleSetNames:results.ruleSetNames ruleResult:singleRuleResult usedParameters:results.usedParameters needFuse:NO backtraces:backtraces eventData:event.eventData signature:results.signature];
                });
            }
        }
    }
    return nil;
}


@end

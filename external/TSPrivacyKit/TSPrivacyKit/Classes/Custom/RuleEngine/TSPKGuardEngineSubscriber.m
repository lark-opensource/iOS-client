//
//  TSPKGuardEngineSubscriber.m
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/30.
//

#import "TSPKGuardEngineSubscriber.h"
#import "TSPKReporter.h"
#import "TSPKStatisticEvent.h"
#import <PNSServiceKit/PNSRuleEngineProtocol.h>
#import <PNSServiceKit/PNSServiceCenter.h>
#import <TSPrivacyKit/TSPKSignalManager+public.h>

@implementation TSPKGuardEngineSubscriber

- (NSString *)uniqueId {
    return @"TSPKGuardEngineSubscriber";
}

- (TSPKHandleResult *)hanleEvent:(TSPKEvent *)event {
    NSArray *backtraces = event.eventData.apiModel.backtraces;
    NSDictionary *guardParams = [self convertEventDataToParams:event.eventData source:TSPKRuleEngineSpaceGuard];
    
    id<PNSRuleResultProtocol> results = [PNS_GET_INSTANCE(PNSRuleEngineProtocol) validateParams:guardParams];
    [self appendExecuteResult:results toEventData:event.eventData input:guardParams];

    if (results.values.count > 0) {
        for (id<PNSSingleRuleResultProtocol> singleRuleResult in results.values) {
            if ([singleRuleResult.conf[TSPKRuleEngineAction] isEqualToString:TSPKRuleEngineActionReport]) {
                // when result conf is upload, get backtraces
                if (backtraces == nil) {
                    backtraces = [PNS_GET_INSTANCE(PNSBacktraceProtocol) getBacktracesWithSkippedDepth:0 needAllThreads:NO];
                }
                [self reportInfoWithParams:guardParams ruleSetNames:results.ruleSetNames ruleResult:singleRuleResult usedParameters:results.usedParameters needFuse:NO backtraces:backtraces eventData:event.eventData signature:results.signature];
            } else if ([singleRuleResult.conf[TSPKRuleEngineAction] isEqualToString:TSPKRuleEngineActionDowngrade]) {
                if (backtraces == nil) {
                    backtraces = [PNS_GET_INSTANCE(PNSBacktraceProtocol) getBacktracesWithSkippedDepth:0 needAllThreads:NO];
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSString *content = @"Guard release instance";
                    [TSPKSignalManager addSignalWithType:TSPKSignalTypeGuard permissionType:event.eventData.apiModel.dataType content:content extraInfo:@{@"instance": event.eventData.apiModel.hashTag ?:@""}];
                    
                    [self reportInfoWithParams:guardParams ruleSetNames:results.ruleSetNames ruleResult:singleRuleResult usedParameters:results.usedParameters needFuse:NO backtraces:backtraces eventData:event.eventData signature:results.signature];
                    
                    for (__attribute__((unused)) TSPKEvent *unreleaseEvent in event.eventData.subEvents) {
                        TSPKDowngradeAction action = event.eventData.apiModel.downgradeAction;
                        !action ?: action();
                    }
                });
            }
        }
    }
    return nil;
}

@end

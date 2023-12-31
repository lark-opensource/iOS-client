//
//  TSPKRuleEngine.m
//  Indexer
//
//  Created by admin on 2022/2/13.
//

#import "TSPKRuleEngineManager.h"
#import "TSPKAppBackgroundFunc.h"
#import "TSPKFrequencyFunc.h"
#import "TSPKCallStackFilterFunc.h"
#import "TSPKValidateEmailFunc.h"
#import "TSPKValidatePhoneNumberFunc.h"
#import <PNSServiceKit/PNSRuleEngineProtocol.h>
#import <PNSServiceKit/PNSServiceCenter.h>

@interface TSPKRuleEngineManager ()

@property (nonatomic) TSPKRuleEngineExtraParameterBuilder extraParamsBuilder;

@end

@implementation TSPKRuleEngineManager

+ (instancetype)sharedEngine
{
    static TSPKRuleEngineManager *engine;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        engine = [[TSPKRuleEngineManager alloc] init];
    });
    return engine;
}

- (void)setExtraParams:(TSPKRuleEngineExtraParameterBuilder)block {
    self.extraParamsBuilder = block;
}

- (void)registerDefaultFunc {
    id <PNSRuleEngineProtocol> ruleEngine = PNS_GET_INSTANCE(PNSRuleEngineProtocol);
    [ruleEngine registerFunc:[TSPKAppBackgroundFunc new]];
    [ruleEngine registerFunc:[TSPKFrequencyFunc new]];
    [ruleEngine registerFunc:[TSPKCallStackFilterFunc new]];
    [ruleEngine registerFunc:[TSPKValidateEmailFunc new]];
    [ruleEngine registerFunc:[TSPKValidatePhoneNumberFunc new]];
}

@end

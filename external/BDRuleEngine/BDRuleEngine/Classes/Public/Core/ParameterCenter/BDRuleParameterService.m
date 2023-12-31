//
//  BDRuleParameterService.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/9.
//

#import "BDRuleParameterService.h"
#import "BDRuleParameterRegistry.h"

@implementation BDRuleParameterService

+ (void)registerParameterWithKey:(NSString *)key type:(BDRuleParameterType)type builder:(BDRuleParameterBuildBlock)builder
{
    [BDRuleParameterRegistry registerParameterWithKey:key type:type builder:builder];
}

+ (NSArray<BDRuleParameterBuilderModel *> *)stateParameters
{
   return [BDRuleParameterRegistry stateParameters];
}

@end

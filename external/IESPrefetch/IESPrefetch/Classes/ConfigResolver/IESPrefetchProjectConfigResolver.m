//
//  IESPrefetchProjectConfigResolver.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/3.
//

#import "IESPrefetchProjectConfigResolver.h"
#import "IESPrefetchProjectTemplate.h"
#import "IESPrefetchLogger.h"
#import "IESPrefetchAPIConfigResolver.h"
#import "IESPrefetchRuleConfigResolver.h"
#import "IESPrefetchOccasionConfigResolver.h"

@implementation IESPrefetchProjectConfigResolver

- (id<IESPrefetchConfigTemplate>)resolveConfig:(NSDictionary *)config
{
    if (!([config isKindOfClass:[NSDictionary class]] && config.count > 0)) {
        return nil;
    }
    IESPrefetchOccasionConfigResolver *occasionResolver = [IESPrefetchOccasionConfigResolver new];
    IESPrefetchRuleConfigResolver *ruleResolver = [IESPrefetchRuleConfigResolver new];
    IESPrefetchAPIConfigResolver *apiResolver = [IESPrefetchAPIConfigResolver new];
    
    IESPrefetchAPITemplate *apiTemplate = [apiResolver resolveConfig:config];
    if (apiTemplate == nil) {
        PrefetchConfigLogW(@"config not include APIs，ignored");
        return nil;
    }
    IESPrefetchRuleTemplate *ruleTemplate = [ruleResolver resolveConfig:config];
    IESPrefetchOccasionTemplate *occasionTemplate = [occasionResolver resolveConfig:config];
    if (ruleTemplate) {
        occasionTemplate.children = @[ruleTemplate];
    }
    if (apiTemplate) {
        ruleTemplate.children = @[apiTemplate];
    }
    
    IESPrefetchProjectTemplate *template = [IESPrefetchProjectTemplate new];
    NSMutableArray<id<IESPrefetchConfigTemplate>> *projectChildren = [NSMutableArray new];
    if (ruleTemplate) {
        [projectChildren addObject:ruleTemplate];
    }
    if (occasionTemplate) {
        [projectChildren addObject:occasionTemplate];
    }
    template.children = [projectChildren copy];
    
    return template;
}

@end

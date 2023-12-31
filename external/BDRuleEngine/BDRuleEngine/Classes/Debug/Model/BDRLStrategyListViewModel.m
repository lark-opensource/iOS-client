//
//  BDRLStrategyListViewModel.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by ByteDance on 27.4.22.
//

#import "BDRLStrategyListViewModel.h"
#import "BDRLStrategyDetailViewModel.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface BDRLStrategyListViewModel ()

@property (nonatomic, strong) NSArray<NSString *> *titles;
@property (nonatomic, strong) NSDictionary *json;
@property (nonatomic, strong) NSArray<NSDictionary *> *jsons;

@end

@implementation BDRLStrategyListViewModel

- (NSUInteger)count
{
    return self.titles.count;
}

- (NSString *)titleAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section > [self count]) return nil;
    return self.titles[indexPath.section];
}

- (BDRLStrategyViewModel *)viewModelAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section > 1) {
        BDRLStrategyViewModel *viewModel;
        viewModel = [[BDRLStrategyDetailViewModel alloc] initWithJson:self.jsons[indexPath.section]];
        return viewModel;
    }
    return nil;
}

- (instancetype)initWithJson:(NSDictionary *)json
{
    if (self = [super init]) {
        self.json = json;
        [self __setup];
    }
    return self;
}

- (void)__setup
{
    NSMutableArray *mutableTitles = [NSMutableArray array];
    NSMutableArray *mutableJsons = [NSMutableArray array];

    NSString *strategySelectBreakDescription;
    NSString *ruleExecBreakDescription;
    if ([self.json objectForKey:@"strategy_select_break"] == nil) {
        strategySelectBreakDescription = @"是";
    }
    else {
        if ([self.json btd_boolValueForKey:@"strategy_select_break"] == YES) {
            strategySelectBreakDescription = @"是";
        }
        else {
            strategySelectBreakDescription = @"否";
        }
    }
    if ([self.json objectForKey:@"rule_exec_break"] == nil) {
        ruleExecBreakDescription = @"是";
    }
    else {
        if ([self.json btd_boolValueForKey:@"rule_exec_break"] == YES) {
            ruleExecBreakDescription = @"是";
        }
        else {
            ruleExecBreakDescription = @"否";
        }
    }
    [mutableTitles addObject:[NSString stringWithFormat:@"策略选取短路: %@", strategySelectBreakDescription]];
    [mutableTitles addObject:[NSString stringWithFormat:@"规则执行短路: %@", ruleExecBreakDescription]];
    [mutableJsons addObject:[NSDictionary dictionary]];
    [mutableJsons addObject:[NSDictionary dictionary]];


    for (NSDictionary *rule in self.json[@"strategy_map"][@"rules"]) {
        NSMutableDictionary *json = [NSMutableDictionary dictionary];
        NSString *title = [rule btd_stringValueForKey:@"title"];
        [mutableTitles addObject:title];
        [json setValuesForKeysWithDictionary:self.json[@"strategies"][rule[@"conf"][@"strategy"]]];
        [json setValuesForKeysWithDictionary:rule];
        [mutableJsons addObject:[json copy]];
    }

    _titles = [mutableTitles copy];
    _jsons = [mutableJsons copy];
}

@end

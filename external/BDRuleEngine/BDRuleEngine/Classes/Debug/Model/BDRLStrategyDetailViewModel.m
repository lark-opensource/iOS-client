//
//  BDRLStrategyDetailViewModel.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by ByteDance on 27.4.22.
//

#import "BDRLStrategyDetailViewModel.h"

@interface BDRLPolicyViewModel : NSObject

@property (nonatomic, strong) NSDictionary *json;

@end

@implementation BDRLPolicyViewModel

- (instancetype)initWithJson:(NSDictionary *)json
{
    if (self = [super init]) {
        self.json = json;
    }
    return self;
}

- (NSString *)policyTitle
{
    return [NSString stringWithFormat:@"规则名称:%@", self.json[@"title"]];
}

- (NSString *)policyConf
{
    return [NSString stringWithFormat:@"规则返回值:\n%@", self.json[@"conf"]];
}

- (NSString *)policyCel
{
    return [NSString stringWithFormat:@"规则生效条件: %@", self.json[@"cel"]];
}

@end

@interface BDRLStrategyDetailViewModel ()

@property (nonatomic, strong) NSDictionary *json;
@property (nonatomic, strong) NSArray<BDRLPolicyViewModel *> *policies;

@end

@implementation BDRLStrategyDetailViewModel

- (NSUInteger)count
{
    return self.policies.count;
}

- (instancetype)initWithJson:(NSDictionary *)json
{
    if (self = [super init]) {
        self.json = json;
        [self __setup];
    }
    return self;
}

- (NSString *)strategyTitle
{
    return [NSString stringWithFormat:@"策略名称: %@", self.json[@"title"]];
}

- (NSString *)strategyCel
{
    return [NSString stringWithFormat:@"策略生效条件: %@", self.json[@"cel"]];
}

- (NSString *)policyTitleAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > [self count]) return nil;
    return [self.policies[indexPath.row] policyTitle];
}

- (NSString *)policyConfAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > [self count]) return nil;
    return [self.policies[indexPath.row] policyConf];
}

- (NSString *)policyCelAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > [self count]) return nil;
    return [self.policies[indexPath.row] policyCel];
}

- (void)__setup
{
    NSMutableArray *mutablePolicies = [NSMutableArray array];
    for (NSDictionary *policyJson in self.json[@"rules"]) {
        [mutablePolicies addObject:[[BDRLPolicyViewModel alloc] initWithJson:policyJson]];
    }
    _policies = [mutablePolicies copy];
}

@end

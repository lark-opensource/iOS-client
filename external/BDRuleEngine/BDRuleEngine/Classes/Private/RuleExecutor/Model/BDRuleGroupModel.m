//
//  BDRuleGroupModel.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/11/25.
//

#import "BDRuleGroupModel.h"
#import "BDREInstruction.h"
#import "NSDictionary+BDRESafe.h"
#import "BDREInstructionCacheManager.h"
#import "BDRuleEngineSettings.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>

@implementation BDRuleModel

- (instancetype)initWithDictionary:(NSDictionary *)dict key:(NSString *)key
{
    if (self = [super init]) {
        self.key = key;
        self.title = [dict bdre_stringForKey:@"title"];
        self.conf = [dict bdre_dictForKey:@"conf"];
        self.cel = [dict bdre_stringForKey:@"cel"];
        self.commands = [BDREInstruction commandsWithJsonArray:[dict bdre_arrayForKey:@"il"]];
        self.children = [BDRuleModel parseJsonArray:[dict bdre_arrayForKey:@"children"]];
    }
    return self;
}

- (void)loadCommandsAndEnableExecutor:(BOOL)enable
{
    if (!self.commands) {
        self.commands = [[BDREInstructionCacheManager sharedManager] findCommandsForExpr:self.cel];
    }
    if (enable) {
        self.qucikExecutor = [BDRuleQuickExecutorFactory createExecutorWithCommands:self.commands cel:self.cel];
    }
}

- (NSDictionary *)jsonFormat
{
    return @{
        @"key"     : self.key ?: @"",
        @"title"   : self.title ?: @"",
        @"conf"    : self.conf ?: @"",
        @"cel"     : self.cel ?: @"",
        @"children": [BDRuleModel formatToJsonArray:self.children] ?: @[]
    };
}

+ (NSArray<BDRuleModel *> *)parseJsonArray:(NSArray *)jsonArray
{
    if ([jsonArray count] == 0) {
        return nil;
    }
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[jsonArray count]];
    for (NSDictionary *dict in jsonArray) {
        if (![dict isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        BDRuleModel *childModel = [[BDRuleModel alloc] initWithDictionary:dict key:@""];
        [result btd_addObject:childModel];
    }
    return [NSArray arrayWithArray:result];
}

+ (NSArray<NSDictionary *> *)formatToJsonArray:(NSArray<BDRuleModel *> *)modelArray
{
    if ([modelArray count] == 0) {
        return nil;
    }
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[modelArray count]];
    for (BDRuleModel *model in modelArray) {
        [result btd_addObject:[model jsonFormat]];
    }
    return [NSArray arrayWithArray:result];
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[BDRuleModel class]]) {
        return NO;
    }
    BDRuleModel *rule = (BDRuleModel *)object;
    if ([self.title isEqualToString:rule.title]) {
        return YES;
    }
    return NO;
}

- (NSUInteger)hash
{
    return self.title.hash;
}

@end

@implementation BDRuleGroupModel

- (instancetype)initWithJsonArray:(NSArray *)jsonArray
                             name:(NSString *)name
{
    return [self initWithJsonArray:jsonArray name:name keys:nil];
}

- (instancetype)initWithJsonArray:(NSArray *)jsonArray
                             name:(NSString *)name
                             keys:(nullable NSArray *)keys
{
    _rawJsonArray = jsonArray;
    NSArray *array = [BDRuleModel parseJsonArray:jsonArray];
    return [self initWithArray:array name:name keys:keys];
}


- (instancetype)initWithArray:(NSArray<BDRuleModel *> *)array
                         name:(NSString *)name
{
    return [self initWithArray:array name:name keys:nil];
}

- (instancetype)initWithArray:(NSArray<BDRuleModel *> *)array
                         name:(NSString *)name
                         keys:(nullable NSArray *)keys
{
    if (self = [super init]) {
        _rules = array;
        _name = name;
        _keys = keys;
    }
    return self;
}

- (instancetype)initWithMergeRuleGroupModelArray:(NSArray<BDRuleGroupModel *> *)array
{
    NSMutableArray *mergedRules = [NSMutableArray array];
    NSMutableArray *mergedNames = [NSMutableArray array];
    
    for (BDRuleGroupModel *model in array) {
        if (![mergedNames containsObject:model.name]) {
            [mergedNames btd_addObject:model.name];
        }
        for (BDRuleModel *rule in model.rules) {
            if (![mergedRules containsObject:rule]) {
                [mergedRules btd_addObject:rule];
            }
        }
    }
    NSString *mergedName = [[mergedNames copy] btd_jsonStringEncoded];
    return [self initWithArray:[mergedRules copy] name:mergedName];
}

- (NSDictionary *)jsonFormat
{
    return @{
        @"name": self.name ?: @"",
        @"keys": self.keys ?: @"",
        @"rules": self.rawJsonArray ?: ([BDRuleModel formatToJsonArray:self.rules] ?: @[]),
    };
}

@end

//
//  BDREInstructionCacheManager.m
//  Aweme
//
//  Created by Chengmin Zhang on 2022/8/29.
//

#import "BDREInstructionCacheManager.h"
#import "BDRuleEngineKVStore.h"
#import "BDREInstruction.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

static NSString * const kBDRuleEngineInstructionID           = @"com.bd.ruleengine.instructions";
static NSString * const kBDRuleEngineInstructionKey          = @"instructions";
static NSString * const kBDRuleEngineInstructionSignatureKey = @"signature";

@interface BDREInstructionCacheManager ()

@property (nonatomic, strong) NSDictionary *commandMap;
@property (nonatomic, copy) NSString *signature;

@end

@implementation BDREInstructionCacheManager

+ (BDREInstructionCacheManager *)sharedManager
{
    static BDREInstructionCacheManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self loadCommandMap];
    }
    return self;
}

- (void)loadCommandMap
{
    if (self.commandMap) {
        return;
    }
    self.signature = [BDRuleEngineKVStore stringForKey:kBDRuleEngineInstructionSignatureKey uniqueID:kBDRuleEngineInstructionID];
    NSDictionary *instructionMap = [BDRuleEngineKVStore objectOfClass:[NSDictionary class] forKey:kBDRuleEngineInstructionKey uniqueID:kBDRuleEngineInstructionID];
    [self updateCommandMapWithInstructionJsonMap:instructionMap];
}

- (void)updateInstructionJsonMap:(NSDictionary *)instructionMap signature:(NSString *)signature
{
    self.signature = signature;
    [self updateCommandMapWithInstructionJsonMap:instructionMap];
    [BDRuleEngineKVStore setString:signature forKey:kBDRuleEngineInstructionSignatureKey uniqueID:kBDRuleEngineInstructionID];
    [BDRuleEngineKVStore setObject:instructionMap forKey:kBDRuleEngineInstructionKey uniqueID:kBDRuleEngineInstructionID];
}

- (void)updateCommandMapWithInstructionJsonMap:(NSDictionary *)instructionMap
{
    NSMutableDictionary *newCommandMap = [self.commandMap mutableCopy] ?: [NSMutableDictionary dictionary];
    for (NSString *expr in instructionMap.allKeys) {
        if (![newCommandMap btd_objectForKey:expr default:nil]) {
            NSArray *instructions = [instructionMap btd_objectForKey:expr default:nil];
            if (instructions) {
                [newCommandMap btd_setObject:[BDREInstruction commandsWithJsonArray:instructions] forKey:expr];
            }
        }
    }
    self.commandMap = [newCommandMap copy];
}

- (nullable NSArray<BDRECommand *> *)findCommandsForExpr:(nonnull NSString *)expr
{
    return [self.commandMap btd_objectForKey:expr default:nil];
}

@end

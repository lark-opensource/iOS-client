//
//  BDREInstruction.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/7/14.
//

#import "BDREInstruction.h"
#import "BDREValueCommand.h"
#import "BDREOperatorCommand.h"
#import "BDREFunctionCommand.h"
#import "BDREIdentifierCommand.h"
#import "BDRuleEngineSettings.h"
#import "BDREOperatorManager.h"
#import "BDREFuncManager.h"
#import "BDRENull.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface BDREInstruction ()

@property (nonatomic, assign) uint instruction;
@property (nonatomic, strong, nonnull) id value;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (BDRECommand *)command;

@end

@implementation BDREInstruction

- (instancetype)initWithInstruction:(uint)inst value:(id)value
{
    if (self = [super init]) {
        _instruction = inst;
        _value = value;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    NSNumber *inst = [dict btd_numberValueForKey:@"i"];
    id value = [dict btd_objectForKey:@"v" default:nil];
    if (!inst || !value) {
        return nil;
    }
    return [self initWithInstruction:[inst unsignedIntValue] value:value];
}

- (BDRECommand *)command
{
    BDREInstructionType instType = self.instruction << 14 >> 28;
    uint paramCount = self.instruction << 22 >> 22;
    BDRECommand *command = nil;
    switch (instType) {
        case BDREInstructionLiteral:
        {
            if ([self.value isKindOfClass:NSString.class] && [self.value isEqualToString: NSStringFromClass(BDRENull.class)]) {
                command = [[BDREValueCommand alloc] initWithValue:[BDRENull new]];
            } else {
                command = [[BDREValueCommand alloc] initWithValue:self.value];
            }
        }
            break;
        case BDREInstructionVariable:
        {
            command = [[BDREIdentifierCommand alloc] initWithIdentifier:self.value];
        }
            break;
        case BDREInstructionFunction:
        {
            BDREFunc *func = [[BDREFuncManager sharedManager] getFuncFromSymbol:self.value];
            command = [[BDREFunctionCommand alloc] initWithFuncName:self.value func:func argsLength:paramCount];
        }
            break;
        case BDREInstructionOperator:
        {
            BDREOperator *op = [[BDREOperatorManager sharedManager] getOperatorFromSymbol:self.value];
            if (!op) {
                return nil;
            }
            command = [[BDREOperatorCommand alloc] initWithOperator:op];
        }
            break;
    }
    return command;
}

- (NSDictionary *)jsonFormat
{
    return @{
        @"i" : @(self.instruction),
        @"v" : self.value
    };
}

+ (NSArray<BDRECommand *> *)commandsWithJsonArray:(NSArray *)jsonArray
{
    if (![BDRuleEngineSettings enableInstructionList] || !jsonArray.count) {
        return nil;
    }
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:jsonArray.count];
    for (NSDictionary *dict in jsonArray) {
        if (![dict isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        BDREInstruction *inst = [[BDREInstruction alloc] initWithDictionary:dict];
        if (!inst) {
            return nil;
        }
        BDRECommand *command = [inst command];
        if (!command) {
            return nil;
        }
        [result btd_addObject:[inst command]];
    }
    return [NSArray arrayWithArray:result];
}

@end

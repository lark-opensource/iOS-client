//
//  LKREInstruction.m
//  LKRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/7/14.
//

#import "LKREInstruction.h"
#import "LKREValueCommand.h"
#import "LKREOperatorCommand.h"
#import "LKREFunctionCommand.h"
#import "LKREIdentifierCommand.h"
#import "LKREOperatorManager.h"
#import "LKREFuncManager.h"
#import "LKRENull.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface LKREInstruction ()

@property (nonatomic, assign) uint instruction;
@property (nonatomic, strong, nonnull) id value;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (LKRECommand *)command;

@end

@implementation LKREInstruction

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

- (LKRECommand *)command
{
    LKREInstructionType instType = self.instruction << 14 >> 28;
    uint paramCount = self.instruction << 22 >> 22;
    LKRECommand *command = nil;
    switch (instType) {
        case LKREInstructionLiteral:
        {
            if ([self.value isKindOfClass:NSString.class] && [self.value isEqualToString: NSStringFromClass(LKRENull.class)]) {
                command = [[LKREValueCommand alloc] initWithValue:[LKRENull new]];
            } else {
                command = [[LKREValueCommand alloc] initWithValue:self.value];
            }
        }
            break;
        case LKREInstructionVariable:
        {
            command = [[LKREIdentifierCommand alloc] initWithIdentifier:self.value];
        }
            break;
        case LKREInstructionFunction:
        {
            LKREFunc *func = [[LKREFuncManager sharedManager] getFuncFromSymbol:self.value];
            if (!func) {
                return nil;
            }
            command = [[LKREFunctionCommand alloc] initWithFunc:func argsLength:paramCount];
        }
            break;
        case LKREInstructionOperator:
        {
            LKREOperator *op = [[LKREOperatorManager sharedManager] getOperatorFromSymbol:self.value];
            if (!op) {
                return nil;
            }
            command = [[LKREOperatorCommand alloc] initWithOperator:op];
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

+ (NSArray<LKRECommand *> *)commandsWithJsonArray:(NSArray *)jsonArray
{
    if (jsonArray.count == 0) {
        return nil;
    }
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:jsonArray.count];
    for (NSDictionary *dict in jsonArray) {
        if (![dict isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        LKREInstruction *inst = [[LKREInstruction alloc] initWithDictionary:dict];
        if (!inst) {
            return nil;
        }
        LKRECommand *command = [inst command];
        if (!command) {
            return nil;
        }
        [result btd_addObject:[inst command]];
    }
    return [NSArray arrayWithArray:result];
}

@end

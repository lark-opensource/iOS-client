//
//  LKREInstruction.h
//  LKRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/7/14.
//

#import <Foundation/Foundation.h>
#import "LKRECommand.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint, LKREInstructionType)
{
    LKREInstructionLiteral  = 0,
    LKREInstructionVariable = 1,
    LKREInstructionFunction = 2,
    LKREInstructionOperator = 3
};

typedef NS_ENUM(uint, LKREInstructionVariType)
{
    LKREInstructionVariNULL        = 0,
    LKREInstructionVariBool        = 1,
    LKREInstructionVariInt         = 2,
    LKREInstructionVariLong        = 3,
    LKREInstructionVariFloat       = 4,
    LKREInstructionVariDouble      = 5,
    LKREInstructionVariChar        = 6,
    LKREInstructionVariString      = 7,
    LKREInstructionVariCollection  = 8
};

@interface LKREInstruction : NSObject

- (instancetype)initWithInstruction:(uint)inst value:(id)value;

- (NSDictionary *)jsonFormat;

+ (NSArray<LKRECommand *> *)commandsWithJsonArray:(NSArray *)jsonArray;

@end

NS_ASSUME_NONNULL_END

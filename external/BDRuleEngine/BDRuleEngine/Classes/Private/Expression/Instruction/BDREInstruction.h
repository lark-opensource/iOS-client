//
//  BDREInstruction.h
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/7/14.
//

#import <Foundation/Foundation.h>
#import "BDRECommand.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint, BDREInstructionType)
{
    BDREInstructionLiteral  = 0,
    BDREInstructionVariable = 1,
    BDREInstructionFunction = 2,
    BDREInstructionOperator = 3
};

typedef NS_ENUM(uint, BDREInstructionVariType)
{
    BDREInstructionVariNULL        = 0,
    BDREInstructionVariBool        = 1,
    BDREInstructionVariInt         = 2,
    BDREInstructionVariLong        = 3,
    BDREInstructionVariFloat       = 4,
    BDREInstructionVariDouble      = 5,
    BDREInstructionVariChar        = 6,
    BDREInstructionVariString      = 7,
    BDREInstructionVariCollection  = 8
};

@interface BDREInstruction : NSObject

- (instancetype)initWithInstruction:(uint)inst value:(id)value;

- (NSDictionary *)jsonFormat;

+ (NSArray<BDRECommand *> *)commandsWithJsonArray:(NSArray *)jsonArray;

@end

NS_ASSUME_NONNULL_END

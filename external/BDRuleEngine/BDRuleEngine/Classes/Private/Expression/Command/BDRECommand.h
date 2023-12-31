//
//  BDRECommand.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import <Foundation/Foundation.h>

#import "BDREExprEnv.h"

NS_ASSUME_NONNULL_BEGIN

@class BDREInstruction;

@interface BDRECommand : NSObject

- (void)execute:(NSMutableArray *)cmdStack withEnv:(id<BDREExprEnv>)env error:(NSError **)error;

- (BDREInstruction *)instruction;

+ (nonnull NSArray<NSDictionary *> *)instructionJsonArrayWithCommands:(nonnull NSArray<BDRECommand *> *)commands;

@end

NS_ASSUME_NONNULL_END

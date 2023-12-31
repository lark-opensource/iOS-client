//
//  BDRECommand.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDRECommand.h"
#import "BDREInstruction.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>

@implementation BDRECommand

- (void)execute:(NSMutableArray *)cmdStack withEnv:(id<BDREExprEnv>)env error:(NSError *__autoreleasing  _Nullable *)error
{
    
}

- (BDREInstruction *)instruction
{
    return nil;
}

+ (NSArray<NSDictionary *> *)instructionJsonArrayWithCommands:(NSArray<BDRECommand *> *)commands
{
    NSMutableArray *instructions = [NSMutableArray arrayWithCapacity:commands.count];
    for (BDRECommand *command in commands) {
        [instructions btd_addObject:[[command instruction] jsonFormat]];
    }
    return [NSArray arrayWithArray:instructions];
}

@end

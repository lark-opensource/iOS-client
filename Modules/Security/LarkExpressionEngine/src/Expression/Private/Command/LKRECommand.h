//
//  LKRECommand.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import <Foundation/Foundation.h>

#import "LKREExprEnv.h"

NS_ASSUME_NONNULL_BEGIN

@class LKREInstruction;

@interface LKRECommand : NSObject

- (void)execute:(NSMutableArray *)cmdStack withEnv:(id<LKREExprEnv>)env error:(NSError **)error;

- (LKREInstruction *)instruction;

@end

NS_ASSUME_NONNULL_END

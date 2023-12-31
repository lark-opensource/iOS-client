//
//  LKREExprEval.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import <Foundation/Foundation.h>
#import "LKREExprEnv.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKREExprEval : NSObject

- (id)eval:(NSArray *)commandArray withEnv:(id<LKREExprEnv>)env error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

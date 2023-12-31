//
//  BDREExprEval.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import <Foundation/Foundation.h>
#import "BDREExprEnv.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREExprEval : NSObject

+ (id)eval:(NSArray *)commandArray withEnv:(id<BDREExprEnv>)env error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

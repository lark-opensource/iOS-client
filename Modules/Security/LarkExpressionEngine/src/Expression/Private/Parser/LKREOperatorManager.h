//
//  LKREOperatorManager.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import <Foundation/Foundation.h>
#import "LKREExprEnv.h"
#import "LKREOperator.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKREOperatorManager : NSObject

+ (LKREOperatorManager *)sharedManager;

- (LKREOperator *)getOperatorFromSymbol:(NSString *)symbol;

- (void)registerOperator:(LKREOperator *)op;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

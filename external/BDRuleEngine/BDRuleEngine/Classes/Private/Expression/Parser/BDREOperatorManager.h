//
//  BDREOperatorManager.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import <Foundation/Foundation.h>
#import "BDREExprEnv.h"
#import "BDREOperator.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREOperatorManager : NSObject

+ (BDREOperatorManager *)sharedManager;

- (BDREOperator *)getOperatorFromSymbol:(NSString *)symbol;

- (void)registerOperator:(BDREOperator *)op;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

//
//  LKREOperatorCommand.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKRECommand.h"
#import "LKREOperator.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKREOperatorCommand : LKRECommand

- (LKREOperatorCommand *)initWithOperator:(LKREOperator *)operator;

@end

NS_ASSUME_NONNULL_END

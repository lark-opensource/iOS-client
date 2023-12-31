//
//  BDREOperatorCommand.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDRECommand.h"
#import "BDREOperator.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREOperatorCommand : BDRECommand

@property (nonatomic, strong, readonly) BDREOperator *operator;
@property (nonatomic, assign, readonly) NSUInteger opDataNumber;

- (BDREOperatorCommand *)initWithOperator:(BDREOperator *)operator;

@end

NS_ASSUME_NONNULL_END

//
//  LKREOperatorNode.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREBaseNode.h"
#import "LKREOperatorManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKREOperatorNode : LKREBaseNode

@property (nonatomic, strong) LKREOperator *opetator;

- (instancetype)initWithOperatorValue:(LKREOperator *)op originValue:(NSString *)originValue index:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END

//
//  BDREOperatorNode.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREBaseNode.h"
#import "BDREOperatorManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREOperatorNode : BDREBaseNode

@property (nonatomic, strong) BDREOperator *opetator;

- (instancetype)initWithOperatorValue:(BDREOperator *)op originValue:(NSString *)originValue index:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END

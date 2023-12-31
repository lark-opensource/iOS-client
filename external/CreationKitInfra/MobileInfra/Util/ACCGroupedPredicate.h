//
//  ACCPredicates.h
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/4.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ACCGroupedPredicateOperand) {
    ACCGroupedPredicateOperandAnd,
    ACCGroupedPredicateOperandOr,
    ACCGroupedPredicateOperandDefault = ACCGroupedPredicateOperandAnd
};

NS_ASSUME_NONNULL_BEGIN

@interface ACCGroupedPredicate <__covariant InputType, __covariant OutputType> : NSObject

typedef BOOL(^ACCPredicateBlock)(InputType _Nullable input, OutputType *_Nullable output);

/// With operand AND
- (instancetype)init;
- (instancetype)initWithOperand:(ACCGroupedPredicateOperand)operand;

- (void)addPredicate:(ACCPredicateBlock)predicate with:(id)host;
- (void)removePredicate:(ACCPredicateBlock)predicate;
- (BOOL)evaluateWithObject:(nullable InputType)object output:(_Nullable OutputType *)output;
- (BOOL)evaluateWithObject:(nullable InputType)object;
- (BOOL)evaluate;

@end

NS_ASSUME_NONNULL_END

//
//  ACCPredicates.m
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/4.
//

#import <CreationKitInfra/ACCGroupedPredicate.h>

@interface ACCGroupedPredicate <Input, Output> ()

@property (nonatomic, strong) NSMapTable<ACCPredicateBlock, id> *predicates;
@property (nonatomic, assign) ACCGroupedPredicateOperand operand;

@end

@implementation ACCGroupedPredicate

- (instancetype)init
{
    return [self initWithOperand:(ACCGroupedPredicateOperandAnd)];
}

- (instancetype)initWithOperand:(ACCGroupedPredicateOperand)operand
{
    self = [super init];
    if (self) {
        _predicates = [NSMapTable strongToWeakObjectsMapTable];
        _operand = operand;
    }
    return self;
}

- (BOOL)evaluateWithObject:(nullable id)object
{
    return [self evaluateWithObject:object output:NULL];
}

- (BOOL)evaluateWithObject:(id)object output:(id *)output
{
    switch (self.operand) {
        case ACCGroupedPredicateOperandAnd:
            return [self evaluateWithAnd:object output:output];
            break;
        case ACCGroupedPredicateOperandOr:
            return [self evaluateWithOr:object output:output];
            break;
    }
}

- (BOOL)evaluateWithAnd:(id)object output:(id *)output
{
    BOOL result = YES;
    for (ACCPredicateBlock aPredicate in self.predicates.keyEnumerator) {
        result &= aPredicate(object, output);
        if (!result) {
            break;
        }
    }
    return result;
}

- (BOOL)evaluateWithOr:(id)object output:(id *)output
{
    BOOL result = NO;
    for (ACCPredicateBlock aPredicate in self.predicates.keyEnumerator) {
        result |= aPredicate(object, output);
        if (result) {
            break;
        }
    }
    return result;
}

- (BOOL)evaluate
{
    return [self evaluateWithObject:nil];
}

- (void)addPredicate:(ACCPredicateBlock)predicate with:(id)host
{
    [self.predicates setObject:host forKey:predicate];
}

- (void)removePredicate:(ACCPredicateBlock)predicate
{
    [self.predicates removeObjectForKey:predicate];
}

@end

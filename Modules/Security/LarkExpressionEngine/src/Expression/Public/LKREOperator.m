//
//  LKREOperator.m
//  LKRuleEngine
//
//  Created by WangKun on 2022/2/15.
//

#import "LKREOperator.h"

@implementation LKREOperator

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    NSAssert(false, @"must implementation this function in subclass! %@", NSStringFromClass(self));
    return @(-1);
}

@end

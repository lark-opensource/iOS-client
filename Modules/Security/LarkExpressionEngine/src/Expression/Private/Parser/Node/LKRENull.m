//
//  LKRENull.m
//  LKRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/3/28.
//

#import "LKRENull.h"

@implementation LKRENull

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[LKRENull class]]) {
        return NO;
    }
    return YES;
}

@end

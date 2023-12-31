//
//  BDRENull.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/3/28.
//

#import "BDRENull.h"

@implementation BDRENull

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[BDRENull class]]) {
        return NO;
    }
    return YES;
}

@end

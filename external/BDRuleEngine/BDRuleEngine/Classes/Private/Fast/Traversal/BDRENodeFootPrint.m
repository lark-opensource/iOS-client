//
//  BDRENodeFootPrint.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/17.
//

#import "BDRENodeFootPrint.h"

@implementation BDRENodeFootPrint

- (instancetype)init
{
    if (self = [super init]) {
        _isVisited = NO;
        _calculateRes = NO;
    }
    return self;
}

@end

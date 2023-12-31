//
//  LKREChecker.m
//  LarkExpressionEngine
//
//  Created by ByteDance on 2023/11/14.
//

#import "LKREChecker.h"
#import "LKREParamMissing.h"

@implementation LKREChecker

+ (BOOL)isLKREParamMissing:(id)object
{
    return [object isKindOfClass:[LKREParamMissing class]];
}

@end

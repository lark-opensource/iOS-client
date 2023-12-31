//
//  BDREIdentifierUtil.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREIdentifierUtil.h"

@implementation BDREIdentifierUtil

+ (BOOL)isValidIdentifier:(NSString *)identifier
{
    NSString *pattern = @"([A-Za-z_]+[A-Za-z_0-9]*)";
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [pre evaluateWithObject:identifier];
}

@end

//
//  IESDirectSchemaResolver.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/4.
//

#import "IESFallbackSchemaResolver.h"

@implementation IESFallbackSchemaResolver

- (BOOL)shouldInterceptHierachicalSchema:(NSString *)urlString
{
    return YES;
}

- (NSURL *)resolveFlatSchema:(NSString *)urlString
{
    return [NSURL URLWithString:urlString];
}

@end

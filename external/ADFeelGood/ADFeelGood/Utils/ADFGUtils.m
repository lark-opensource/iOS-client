//
//  ADFGUtils.m
//  ADFeelGood
//
//  Created by cuikeyi on 2021/1/15.
//

#import "ADFGUtils.h"

@implementation ADFGUtils

+ (NSError *)errorWithCode:(NSInteger)code msg:(NSString *)msg
{
    NSError *error = [NSError errorWithDomain:@"com.adfeelgood.error" code:code userInfo:@{
        NSLocalizedDescriptionKey: msg?:@""
    }];
    return error;
}

@end

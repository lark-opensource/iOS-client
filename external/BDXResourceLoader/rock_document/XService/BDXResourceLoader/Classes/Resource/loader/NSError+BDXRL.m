//
//  NSError+BDXResourceLoader.m
//  BDXResourceLoader
//
//  Created by David on 2021/3/16.
//

#import "NSError+BDXRL.h"

#import "BDXResourceLoader.h"

@implementation NSError (BDXRL)

+ (NSError *)errorWithCode:(BDXRLErrorCode)errorcode message:(NSString *)message
{
    return [[NSError alloc] initWithDomain:kBDXRLDomain code:errorcode userInfo:@{NSLocalizedDescriptionKey: message ?: @"unknow"}];
}

@end

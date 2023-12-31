//
//  NSError+IESGurdKit.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/10.
//

#import "NSError+IESGurdKit.h"

NSString * const kIESGurdKitErrorDomain = @"IESGurdKitErrorDomain";

@implementation NSError (IESGurdKit)

+ (instancetype)ies_errorWithCode:(IESGurdSyncStatus)status description:(NSString *)description
{
    return [NSError errorWithDomain:kIESGurdKitErrorDomain
                               code:status
                           userInfo:@{ NSLocalizedDescriptionKey : description ? : @"" }];
}

@end

// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "BDWebForestUtil.h"

@implementation BDWebForestUtil

+ (NSURL *)urlWithURLString:(NSString *)urlString queryParameters:(NSDictionary *)params
{
    NSURLComponents *componets = [[NSURLComponents alloc] initWithString:urlString];
    NSMutableArray *newQueryItems = [[componets queryItems] mutableCopy] ?: [NSMutableArray array];

    [params enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* obj, BOOL * _Nonnull stop) {
        __block BOOL isExist = NO;
        [[componets queryItems] enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([item.name isEqualToString:key]) {
                isExist = YES;
                *stop = YES;
            }
        }];
        if (!isExist) {
            [newQueryItems addObject:[[NSURLQueryItem alloc] initWithName:key value:obj]];
        }
    }];
    [componets setQueryItems:newQueryItems];
    return [componets URL];
}

@end

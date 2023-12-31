// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestQueryParameters.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>

@implementation IESForestQueryParameters

- (instancetype)initWithURLString:(NSString *)urlString
{
    if (self = [super init]) {
        NSDictionary<NSString*, NSString*> *queryDictionary = [urlString btd_queryParamDict];
        _dynamic = [queryDictionary btd_numberValueForKey:@"dynamic"];
        _waitGeckoUpdate = [queryDictionary btd_numberValueForKey:@"waitGeckoUpdate"];
        _onlyOnline = [queryDictionary btd_numberValueForKey:@"onlyOnline"];
    }
    return self;
}

- (NSString *)description
{
    NSMutableArray *descArray = [[NSMutableArray alloc] init];
    if (_dynamic) {
        [descArray addObject:[NSString stringWithFormat:@"dynamic: %@", _dynamic]];
    }
    if (_waitGeckoUpdate) {
        [descArray addObject:[NSString stringWithFormat:@"waitGeckoUpdate: %@", _waitGeckoUpdate]];
    }
    if (_onlyOnline) {
        [descArray addObject:[NSString stringWithFormat:@"onlyOnline: %@", _onlyOnline]];
    }
    if (descArray.count == 0) {
        return @"(null)";
    }

    return [NSString stringWithFormat:@"{%@}", [descArray componentsJoinedByString:@", "]];
}

@end

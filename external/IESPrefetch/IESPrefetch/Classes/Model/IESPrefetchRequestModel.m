//
//  IESPrefetchRequestModel.m
//  IESPrefetch
//
//  Created by Hao Wang on 2019/6/28.
//

#import "IESPrefetchRequestModel.h"
#import "IESPrefetchParamModel.h"

@implementation IESPrefetchRequestModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _url = dictionary[@"url"];
        _method = dictionary[@"method"];
        _occasion = dictionary[@"occasion"];
        _expires = [dictionary[@"expires"] longLongValue];
        _headers = dictionary[@"headers"];
        // params
        NSDictionary *p = dictionary[@"params"];
        NSMutableDictionary *paramDict = [NSMutableDictionary dictionaryWithCapacity:p.count];
        [p enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            paramDict[key] = [[IESPrefetchParamModel alloc] initWithDictionary:obj];
        }];
        _params = paramDict;
        // data
        NSDictionary *d = dictionary[@"data"];
        NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithCapacity:d.count];
        [d enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            dataDict[key] = [[IESPrefetchParamModel alloc] initWithDictionary:obj];
        }];
        _data = dataDict;
    }
    return self;
}

@end

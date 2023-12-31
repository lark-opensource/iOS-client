//
//  IESPrefetchJSNetworkRequestModel.m
//  IESPrefetch
//
//  Created by Hao Wang on 2019/8/8.
//

#import "IESPrefetchJSNetworkRequestModel.h"
#import "IESPrefetchLogger.h"
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CommonCrypto/CommonCrypto.h>

@interface IESPrefetchJSNetworkRequestModel ()

@property (nonatomic, copy) NSString *hashValue;

@end

@implementation IESPrefetchJSNetworkRequestModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        _url = dictionary[@"url"];
        [self addHeadersDict:dictionary[@"headers"]];
        [self addParamsDict:dictionary[@"params"]];
        [self addDataDict:dictionary[@"data"]];
        _method = dictionary[@"method"];
        _needCommonParams = [dictionary[@"needCommonParams"] boolValue];
        _ignoreCache = [dictionary[@"ignore_cache"] boolValue];
    }
    return self;
}

- (void)addHeadersDict:(NSDictionary<NSString *, id> *)headers
{
    NSMutableDictionary<NSString *, NSString *> *headerDict = [NSMutableDictionary new];
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj != [NSNull null]) {
            headerDict[key] = [obj description];
        }
    }];
    _headers = [headerDict copy];
}

- (void)addParamsDict:(NSDictionary<NSString *, id> *)params
{
    NSMutableDictionary<NSString *, id> *paramsDict = [NSMutableDictionary new];
    [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj != [NSNull null]) {
            paramsDict[key] = obj;
        }
    }];
    _params = [paramsDict copy];
}

- (void)addDataDict:(NSDictionary<NSString *, id> *)params
{
    NSMutableDictionary<NSString *, id> *paramsDict = [NSMutableDictionary new];
    [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj != [NSNull null]) {
            paramsDict[key] = obj;
        }
    }];
    _data = [paramsDict copy];
}

- (NSString *)calculateHash
{
    NSString *description = [self description];
    NSData *data = [description dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    const char *str = [data bytes];
    CC_MD5((const void *)str, (CC_LONG)data.length, result);
    NSMutableString *mutableString = [NSMutableString new];
    for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [mutableString appendFormat:@"%02X", result[i]];
    }
    
    return mutableString.description;
}

- (NSString *)hashValue
{
    if (_hashValue == nil) {
        NSTimeInterval start = [[NSDate date] timeIntervalSinceReferenceDate];
        _hashValue = [self calculateHash];
        NSTimeInterval end = [[NSDate date] timeIntervalSinceReferenceDate];
        PrefetchLogV(@"RequestModel", @"calculate hash of request model cost: %.2fms", (end - start) * 1000);
    }
    return _hashValue;
}

- (NSString *)description
{
    NSString *url = self.url?: @"";
    NSURLComponents *components = [NSURLComponents componentsWithString:url];
    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray new];
    // use array of URLQueryItem instead of dict, because URLQueryItem's value may be nil.
    // like: 'https://xxxx.com?a'
    if (components.queryItems) {
        [queryItems addObjectsFromArray:components.queryItems];
        components.query = nil;
        url = components.string;
    }
    NSMutableString *mutableString = [NSMutableString stringWithString:url ];
    [mutableString appendFormat:@"|%@|", self.method.uppercaseString];
    [mutableString appendString:@"|headers|"];
    [[self.headers.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
        return [obj1 compare:obj2] == NSOrderedDescending;
    }] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mutableString appendFormat:@"%@=%@&", obj, self.headers[obj]];
    }];
    [mutableString appendString:[NSString stringWithFormat:@"|needCommonParams|%@", @(self.needCommonParams)]];
    [mutableString appendString:@"|query|"];
    if ([self.params isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = self.params;
        // turn dict into an array of URLQueryItem
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            NSURLQueryItem *queryItem = [[NSURLQueryItem alloc] initWithName:key.description value:obj.description];
            if (queryItem) {
                [queryItems btd_addObject:queryItem];
            }
        }];
        
    } else if ([self.params isKindOfClass:[NSString class]]){ // 可能是 NSString
        // use URLComponents to turn the string params into an array of URLQueryItem.
        NSURLComponents *dummyComponents = [NSURLComponents new];
        dummyComponents.query = (NSString *)self.params;
        NSArray<NSURLQueryItem *> *dummyQueryItems = dummyComponents.queryItems;
        if (dummyQueryItems.count > 0) {
            [queryItems addObjectsFromArray:dummyQueryItems];
        }
    }
    
    // sort queryItems and then turn into a string format.
    NSArray<NSURLQueryItem *> *sortedQueryItems = [queryItems sortedArrayUsingComparator:^NSComparisonResult(NSURLQueryItem * _Nonnull obj1, NSURLQueryItem * _Nonnull obj2) {
        return [obj1.name compare:obj2.name] == NSOrderedDescending;
    }];
    
    [sortedQueryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mutableString appendFormat:@"%@", obj.name];
        if (obj.value) {
            [mutableString appendFormat:@"=%@", obj.value];
        }
        [mutableString appendFormat:@"&"];
    }];
    
    
    [mutableString appendString:@"|data|"];
    [mutableString appendString:[self dataDescFromDict:self.data]];
    
    // note: extras不参与计算
    return mutableString.description;
}

- (NSString *)dataDescFromDict:(NSDictionary *)dict {
    NSMutableString *mutableString = @"".mutableCopy;
    // 支持嵌套结构
    [[dict.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull key1, NSString * _Nonnull key2) {
        return [key1 compare:key2] == NSOrderedDescending;
    }] enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        
        id value = dict[key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            [mutableString appendFormat:@"%@={%@}&", key, [self dataDescFromDict:value]];
        } else {
            [mutableString appendFormat:@"%@=%@&", key, value];
        }
    }];
    return [mutableString copy];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@:%p> %@", NSStringFromClass([self class]), self, [self description]];
}

- (NSDictionary *)dictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"url"] = self.url;
    dict[@"method"] = self.method;
    dict[@"headers"] = self.headers;
    dict[@"data"] = self.data;
    dict[@"params"] = self.params;
    dict[@"needCommonParams"] = @(self.needCommonParams);
    dict[@"ignore_cache"] = @(self.ignoreCache);
    return [dict copy];
}

@end

//
//  TSPKNetworkUtil.m
//  T-Develop
//
//  Created by admin on 2022/10/25.
//

#import "TSPKNetworkUtil.h"
#import "TSPKNetworkConfigs.h"
#import <ByteDanceKit/ByteDanceKit.h>

@implementation TSPKNetworkUtil

static NSTimeInterval tTSPKNetworkMonitorStartTime = 0;

+ (void)updateMonitorStartTime {
    tTSPKNetworkMonitorStartTime = CFAbsoluteTimeGetCurrent();
}

+ (NSTimeInterval)monitorStartTime {
    return tTSPKNetworkMonitorStartTime;
}

+ (NSString *)realPathFromURL:(NSURL *)url {
    if (BTD_isEmptyString(url.path)) {
        return url.path;
    }
    NSRange range = [url.absoluteString rangeOfString:url.path];
    NSString *charAfterPath;
    if (url.absoluteString.length > range.location + range.length) {
        charAfterPath = [url.absoluteString substringWithRange:NSMakeRange(range.location + range.length, 1)];
    }
    BOOL shouldAddSuffix = [charAfterPath isEqualToString:@"/"];
    return shouldAddSuffix ? [url.path stringByAppendingString:@"/"] : url.path;
}

+ (NSMutableDictionary *)cookieString2MutableDict:(NSString *)string {
    NSMutableDictionary *cookieMap = [NSMutableDictionary dictionary];
    NSArray *cookieKeyValueStrings = [string componentsSeparatedByString:@";"];
    for (NSString *cookieKeyValueString in cookieKeyValueStrings) {
        // Find the position of the first "=" sign
        NSRange separatorRange = [cookieKeyValueString rangeOfString:@"="];
        
        if (separatorRange.location != NSNotFound &&
            separatorRange.location > 0 &&
            separatorRange.location < ([cookieKeyValueString length] - 1)) {
            // The above conditions ensure that there is content before and after "=", so that the key or value is not empty
            
            NSRange keyRange = NSMakeRange(0, separatorRange.location);
            NSString *key = [cookieKeyValueString substringWithRange:keyRange];
            NSString *value = [cookieKeyValueString substringFromIndex:separatorRange.location + separatorRange.length];
            
            key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [cookieMap setObject:value forKey:key];
        }
    }
    return cookieMap;
}

+ (NSString *)cookieDict2String:(NSDictionary *)dict {
    NSMutableString *result = [[NSMutableString alloc] initWithString:@""];
    
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [result appendFormat:@"%@=%@;", key, obj];
    }];
    return [result substringToIndex:(result.length - 1)];
}

#pragma mark - body
+ (NSData *)bodyStream2Data:(NSInputStream *)bodyStream {
    NSMutableData *data = [[NSMutableData alloc] init];
    [bodyStream open];
    BOOL endOfStreamReached = NO;
    while (!endOfStreamReached) {
        NSInteger maxLength = 1024;
        uint8_t d[maxLength];
        NSInteger bytesRead = [bodyStream read:d maxLength:maxLength];
        if (bytesRead == 0) {
            endOfStreamReached = YES;
        } else if (bytesRead == -1) {
            endOfStreamReached = YES;
        } else if (bodyStream.streamError == nil) {
            [data appendBytes:(void *)d length:bytesRead];
        }
    }
    [bodyStream close];
    return data;
}

#pragma mark - url
+ (NSURL *)URLWithURLString:(NSString *)str
{
    if (str == nil || str.length == 0) {
        return nil;
    }
    NSString * fixStr = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSURL * u = [NSURL URLWithString:fixStr];
    if (!u) {
        u = [NSURL URLWithString:[fixStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    return u;
}

+ (NSString *)URLStringWithoutQuery:(NSString *)urlString
{
    if (urlString == nil || urlString.length == 0) {
        return nil;
    }
    NSArray *subStrs = [urlString componentsSeparatedByString:@"?"];
    return subStrs.count > 0 ? [subStrs btd_objectAtIndex:0] : @"";
}

#pragma mark - QUERY

+ (NSString *)constructWithBaseUrlString:(NSString *)baseUrlString queryMap:(NSDictionary *)queryMap {
    NSMutableArray<NSString *> *modifiedQueryArray = [NSMutableArray new];
    [queryMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [modifiedQueryArray addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
    }];
    NSString *modifiedQueryString = modifiedQueryArray.count > 0 ? [modifiedQueryArray componentsJoinedByString:@"&"] : @"";
    
    NSString *modifiedUrlString = [NSString stringWithFormat:@"%@?%@", baseUrlString, modifiedQueryString];
    return modifiedUrlString;
}


+ (NSArray<NSURLQueryItem *> *)convertQueryToArray:(NSString *)queryString {
    if (!queryString) {
        return nil;
    }
    
    NSArray *queryKVs = [queryString componentsSeparatedByString:@"&"];
    NSMutableArray *mutableKVArray = [NSMutableArray array];
    for (NSString *kvItem in queryKVs) {
        NSString *key, *value;
        NSRange queryRange = [kvItem rangeOfString:@"="];
        if (queryRange.location != NSNotFound) {
            key = [kvItem substringToIndex:queryRange.location];
            value = [kvItem substringFromIndex:queryRange.location + 1];
            
            NSURLQueryItem *item = [[NSURLQueryItem alloc] initWithName:key value:value];
            [mutableKVArray btd_addObject:item];
        }
    }
    
    return mutableKVArray;
}

+ (NSString *)convertArrayToQuery:(NSArray<NSURLQueryItem *> *)queryItems {
    if (queryItems.count == 0) return @"";
    NSMutableString *query = [NSMutableString new];
    [queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [query appendFormat:@"%@=%@&", obj.name, obj.value];
    }];
    return [query substringToIndex:(query.length - 1)];
}

@end

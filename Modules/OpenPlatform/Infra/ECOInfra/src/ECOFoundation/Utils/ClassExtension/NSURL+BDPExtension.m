//
//  NSURL+BTDAdditions.m
//  Pods
//
//  Created by yanglinfeng on 2019/7/2.
//

#import "NSURL+BDPExtension.h"
#import "NSDictionary+BDPExtension.h"
#import "NSString+BDPExtension.h"
#import "BDPUtils.h"

@implementation NSURL (BTDAdditions)

+ (nullable instancetype)bdp_URLWithString:(NSString *)str {
    return [self bdp_URLWithString:str relativeToURL:nil];
}

+ (nullable instancetype)bdp_URLWithString:(NSString *)str relativeToURL:(NSURL *)url {
    if (BDPSafeString(str)) {
        return nil;
    }
    NSString *fixStr = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSURL *u = nil;
    if (url) {
        u = [NSURL URLWithString:fixStr relativeToURL:url];
    }
    else {
        u = [NSURL URLWithString:fixStr];
    }
    if (!u) {
        //
        //Fail to construct a URL directly. Try to construct a URL with a encodedQuery.
        NSString *sourceString = fixStr;
        NSRange fragmentRange = [fixStr rangeOfString:@"#"];
        NSString *fragment = nil;
        if (fragmentRange.location != NSNotFound) {
            sourceString = [fixStr substringToIndex:fragmentRange.location];
            fragment = [fixStr substringFromIndex:fragmentRange.location];
        }
        NSArray *substrings = [sourceString componentsSeparatedByString:@"?"];
        if ([substrings count] > 1) {
            NSString *beforeQuery = [substrings objectAtIndex:0];
            NSString *queryString = [substrings objectAtIndex:1];
            NSArray *paramsList = [queryString componentsSeparatedByString:@"&"];
            NSMutableDictionary *encodedQueryParams = [NSMutableDictionary dictionary];
            [paramsList enumerateObjectsUsingBlock:^(NSString *param, NSUInteger idx, BOOL *stop){
                NSArray *keyAndValue = [param componentsSeparatedByString:@"="];
                if ([keyAndValue count] > 1) {
                    NSString *key = [keyAndValue objectAtIndex:0];
                    NSString *value = [keyAndValue objectAtIndex:1];
//                    value = [TTStringHelper recursiveDecodeForString:value];
                    [self _bdp_decodeWithEncodedURLString:&value];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    CFStringRef cfValue = (__bridge CFStringRef)value;
                    CFStringRef encodedValue = CFURLCreateStringByAddingPercentEscapes(
                                                                                       kCFAllocatorDefault,
                                                                                       cfValue,
                                                                                       NULL,
                                                                                       CFSTR(":/?#@!$&'(){}*+="),
                                                                                       kCFStringEncodingUTF8);
#pragma clang diagnostic pop
                    value = (__bridge_transfer NSString *)encodedValue;
                    [encodedQueryParams setValue:value forKey:key];
                }
            }];
            
            NSString *encodedQuery = [encodedQueryParams bdp_URLQueryString];
            NSString *encodedURLString = [[[beforeQuery stringByAppendingString:@"?"] stringByAppendingString:encodedQuery] stringByAppendingString:fragment?:@""];
            
            if (url) {
                u = [NSURL URLWithString:encodedURLString relativeToURL:url];
            }
            else {
                u = [NSURL URLWithString:encodedURLString];
            }
        }
        /*
         *   http://p1.meituan.net/adunion/a1c87dd93958f3e7adbeb0ecf1c5c166118613.jpg@228w|0_2_0_150az
         *   The above link does not hit the special string escaping logic. After rollbacking, try to escape again and then convert it to the URL...       --yingjie
         */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (!u) {
            u = [NSURL URLWithString:[fixStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
#pragma clang diagnostic pop
        
        NSAssert(u, @"Fail to construct a URL.Please be sure that url is legal and contact with the professionals.");
    }
    return u;
}

+ (void)_bdp_decodeWithEncodedURLString:(NSString **)urlString
{
    if ([*urlString rangeOfString:@"%"].length == 0){
        return;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    *urlString = (__bridge_transfer NSString *)(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef)*urlString, CFSTR(""), kCFStringEncodingUTF8));
#pragma clang diagnostic pop
}

- (NSDictionary<NSString *,NSString *> *)bdp_queryItems {
    NSString *query = self.query;
    if (query == nil || query.length == 0) {
        return nil;
    }
    NSMutableDictionary *result = [NSMutableDictionary new];
    NSArray *paramsList = [query componentsSeparatedByString:@"&"];
    [paramsList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *keyAndValue = [obj componentsSeparatedByString:@"="];
        if ([keyAndValue count] > 1) {
            NSString *paramKey = [keyAndValue objectAtIndex:0];
            NSString *paramValue = [keyAndValue objectAtIndex:1];
            [result setValue:paramValue forKey:paramKey];
        }
    }];
    return result;
}

+ (nullable instancetype)bdp_URLWithString:(NSString *)URLString queryItems:(NSDictionary *)queryItems {
    return [self bdp_URLWithString:URLString queryItems:queryItems fragment:nil];
}

+ (nullable instancetype)bdp_URLWithString:(NSString *)URLString queryItems:(NSDictionary *)queryItems fragment:(NSString *)fragment {
    if (URLString == nil) {
        return nil;
    }
    NSMutableString * querys = [NSMutableString stringWithCapacity:10];
    if ([queryItems count] > 0) {
        [queryItems enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSNumber class]]) {
                obj = [((NSNumber *)obj) stringValue];
            }
            NSString *encodedKey = [[NSString stringWithFormat:@"%@", key] URLEncodedString];
            NSString *encodedValue = [[NSString stringWithFormat:@"%@", obj] URLEncodedString];
            if (encodedKey && encodedValue) {
                [querys appendFormat:@"%@=%@", encodedKey, encodedValue];
                [querys appendString:@"&"];
            }
        }];
        if ([querys hasSuffix:@"&"]) {
            [querys deleteCharactersInRange:NSMakeRange([querys length] - 1, 1)];
        }
    }
    
    NSMutableString * resultURL = [NSMutableString stringWithString:URLString];
    if ([querys length] > 0) {
        if ([resultURL rangeOfString:@"?"].location == NSNotFound) {
            [resultURL appendString:@"?"];
        }
        else if (![resultURL hasSuffix:@"?"] && ![resultURL hasSuffix:@"&"]) {
            [resultURL appendString:@"&"];
        }
        [resultURL appendString:querys];
    }
    
    if ([fragment isKindOfClass:[NSString class]] && [fragment length] > 0) {
        [resultURL appendFormat:@"#%@", fragment];
    }
    
    NSURL * URL = [self URLWithString:resultURL];
    return URL;
}

- (NSDictionary<NSString *,NSString *> *)bdp_queryItemsWithDecoding {
    NSURLComponents *components = [NSURLComponents componentsWithString:self.absoluteString];
    if (components.queryItems == nil || components.queryItems.count == 0) {
        return nil;
    }
    NSMutableDictionary *queryDict = [NSMutableDictionary new];
    for (NSURLQueryItem *item in components.queryItems) {
        queryDict[item.name] = item.value;
    }
    return [queryDict copy];
}

- (NSURL *)bdp_URLByMergingQueryKey:(NSString *)key value:(NSString *)value {
    if (key.length && value.length) {
        return [self bdp_URLByMergingQueries:@{key: value}];
    }
    return self;
}

- (NSURL *)bdp_URLByMergingQueries:(NSDictionary<NSString *,NSString *> *)queries {
    if (queries.count == 0) {
        return self;
    }
    NSDictionary *items = [self bdp_queryItemsWithDecoding] ? : @{};
    NSMutableDictionary<NSString*, NSString *> *queryItems = [items mutableCopy];
    [queries enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * stop) {
        if ([obj isKindOfClass:[NSNumber class]]) {
            queryItems[key] = [(NSNumber *)obj stringValue];
        } else if ([obj isKindOfClass:[NSString class]]) {
            queryItems[key] = obj;
        }
    }];
    NSURLComponents *components = [NSURLComponents componentsWithString:self.absoluteString];
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:queryItems.count];
    [queryItems enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * stop) {
        NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:key value:obj];
        [array addObject:queryItem];
    }];
    components.queryItems = array;
    return components.URL;
}

- (nullable NSString *)safeURLString {
    return [NSString safeURL:self];
}

- (nullable NSString *)safeAES256Key:(NSString *)key iv:(NSString *)iv {
    return [NSString safeAES256URL:self key:key iv:iv];
}

@end

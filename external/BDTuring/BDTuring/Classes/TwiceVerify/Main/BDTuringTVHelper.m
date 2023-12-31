//
//  BDTuringTVHelper.m
//  BDTuring-BDTuringResource
//
//  Created by yanming.sysu on 2020/10/29.
//

#import "BDTuringTVHelper.h"

@implementation BDTuringTVHelper

+ (UIViewController *)getVisibleTopViewController {
    UIWindow *keyWindow;
    if ([[UIApplication sharedApplication] keyWindow]) {
        keyWindow = [[UIApplication sharedApplication] keyWindow];
    }else if ([[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(window)]) {
        keyWindow = [[[UIApplication sharedApplication] delegate] window];
    }
    
    UIViewController *resultVC;
    resultVC = [self _visibleTopViewController:[keyWindow rootViewController]];
    
    while (resultVC.presentedViewController) {
        resultVC = [self _visibleTopViewController:resultVC.presentedViewController];
    }
    
    return resultVC;
}

+ (UIViewController *)_visibleTopViewController:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self _visibleTopViewController:[(UINavigationController *)vc topViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self _visibleTopViewController:[(UITabBarController *)vc selectedViewController]];
    } else {
        return vc;
    }
    
    return nil;
}

+ (BOOL)isIphoneX {
    if (@available(iOS 11.0, *)) {
        if ([[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0) {
            return YES;
        }
    }
    return NO;
}

+ (CGFloat)iphoneXBottomHeight {
    if (@available(iOS 11.0, *)) {
        if ([[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0) {
            return [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom;
        }
    }
    return 0;
}

@end


@implementation NSURL (BDTuringURLUtils)

- (NSURL *)bdturing_URLByMergingQueries:(NSDictionary<NSString *,NSString *> *)queries {
    if (queries.count == 0) {
        return self;
    }
    NSDictionary *items = [self bdturing_queryItemsWithDecoding] ? : @{};
    NSMutableDictionary<NSString*, NSString *> *queryItems = [items mutableCopy];
    [queries enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSNumber class]]) {
            queryItems[key] = [(NSNumber *)obj stringValue];
        } else if ([obj isKindOfClass:[NSString class]]) {
            queryItems[key] = obj;
        }
    }];

    NSURLComponents *components = [NSURLComponents componentsWithString:self.absoluteString];
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:queryItems.count];
    [queryItems enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:key value:obj];
        [array addObject:queryItem];
    }];

    components.queryItems = array;
    return components.URL;
}

- (NSDictionary<NSString *,NSString *> *)bdturing_queryItemsWithDecoding {
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

@end


@implementation NSString(BDTuringAddition)

/**
 *  将字符串进行URL编码
 */
- (NSString *)bdturing_URLEncodedString
{
    __autoreleasing NSString *encodedString;
    NSString *originalString = (NSString *)self;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    encodedString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                          NULL,
                                                                                          (__bridge CFStringRef)originalString,
                                                                                          NULL,
                                                                                          (CFStringRef)@":!*();@/&?#[]+$,='%’\"",
                                                                                          kCFStringEncodingUTF8
                                                                                          );
#pragma clang diagnostic pop
    return encodedString;
}

- (NSString *)bdturing_URLStringByAppendQueryItems:(NSDictionary *)items
{
    return [self bdturing_URLStringByAppendQueryItems:items fragment:nil];
}

- (NSString *)bdturing_URLStringByAppendQueryItems:(NSDictionary *)items fragment:(NSString *)fragment
{
    NSMutableString *querys = [NSMutableString stringWithCapacity:10];
    if ([items count] > 0) {
        [items enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSString class]]) {
                [querys appendFormat:@"%@=%@", key, [(NSString *)obj bdturing_URLEncodedString]];
                [querys appendString:@"&"];
            } else if ([obj isKindOfClass:[NSNumber class]]) {
                [querys appendFormat:@"%@=%@", key, (NSNumber *)obj];
                [querys appendString:@"&"];
            }
        }];
        if ([querys hasSuffix:@"&"]) {
            [querys deleteCharactersInRange:NSMakeRange([querys length] - 1, 1)];
        }
    }
    
    NSMutableString *retURLString = [NSMutableString stringWithString:[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    if ([querys length] > 0) {
        if ([retURLString rangeOfString:@"?"].location == NSNotFound) {
            [retURLString appendString:@"?"];
        }
        else if (![retURLString hasSuffix:@"?"] && ![retURLString hasSuffix:@"&"]) {
            [retURLString appendString:@"&"];
        }
        [retURLString appendString:querys];
    }
    
    if ([fragment isKindOfClass:[NSString class]] && [fragment length] > 0) {
        [retURLString appendFormat:@"#%@", fragment];
    }
    
    return retURLString;
}


@end

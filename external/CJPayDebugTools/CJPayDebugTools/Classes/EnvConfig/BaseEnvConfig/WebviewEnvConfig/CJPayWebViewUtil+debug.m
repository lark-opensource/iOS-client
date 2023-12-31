//
//  CJPayWebViewUtil+debug.m
//  Pods
//
//  Created by 尚怀军 on 2021/1/25.
//

#import "CJPayWebViewUtil+debug.h"
#import <CJPay/CJPaySDKMacro.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "CJPayDebugManager.h"

@implementation CJPayWebViewUtil (debug)

+ (void)swizzleDebugMethod {
    CJPayGaiaRegisterComponentMethod
    [self btd_swizzleInstanceMethod:NSSelectorFromString(@"prepareBeforeGotoWebVCWithURL:")
                               with:@selector(debug_prepareBeforeGotoWebVCWithURL:)];
}

- (NSString *)debug_prepareBeforeGotoWebVCWithURL:(NSString *)url {
    if ([CJPayDebugManager boeIsOpen]) {
        if ([self p_shouldProcessScheme:url]) {
            return [self p_processScheme:url];
        }
        NSURLComponents *urlComponents = [NSURLComponents componentsWithString:[url cj_safeURLString]];
        NSString *boeSuffix = [CJPayDebugManager boeSuffix];
        NSArray *urlWhiteList = [CJPayDebugManager boeUrlWhiteList];
        if (![urlComponents.host hasSuffix:boeSuffix] && ![urlWhiteList containsObject:urlComponents.host]) {
            urlComponents.host = [NSString stringWithFormat:@"%@%@", urlComponents.host, boeSuffix];
            urlComponents.scheme = @"http";
            return urlComponents.URL.absoluteString;
        } else {
            return [self debug_prepareBeforeGotoWebVCWithURL:url];
        }

    } else {
        return [self debug_prepareBeforeGotoWebVCWithURL:url];
    }
}

- (NSString *)p_processScheme:(NSString *)scheme {
    if ([self p_shouldProcessScheme:scheme]) {
        NSURLComponents *components = [NSURLComponents componentsWithString:scheme];
        NSMutableArray *queryItems = [components.queryItems mutableCopy];
        __block NSURLQueryItem *urlQueryItems;
        __block NSURLQueryItem *newUrlQueryItems;
        [queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.name isEqualToString:@"url"]) {
                urlQueryItems = obj;
                NSString *urlValue = [obj.value stringByRemovingPercentEncoding];
                NSURLComponents *urlComponents = [NSURLComponents componentsWithString:[urlValue cj_safeURLString]];
                NSString *boeSuffix = [CJPayDebugManager boeSuffix];
                NSArray *urlWhiteList = [CJPayDebugManager boeUrlWhiteList];
                if (![urlComponents.host hasSuffix:boeSuffix] && ![urlWhiteList containsObject:urlComponents.host]) {
                    urlComponents.host = [NSString stringWithFormat:@"%@%@", urlComponents.host, boeSuffix];
                    urlComponents.scheme = @"http";
                }
                newUrlQueryItems = [[NSURLQueryItem alloc] initWithName:@"url" value:urlComponents.URL.absoluteString];
                *stop = YES;
            }
        }];
        if (newUrlQueryItems && urlQueryItems) {
            [queryItems removeObject:urlQueryItems];
            [queryItems addObject:newUrlQueryItems];
            components.queryItems = [queryItems copy];
        }
        return components.URL.absoluteString;
    }
    return scheme;
}

- (BOOL)p_shouldProcessScheme:(NSString *)scheme {
    return [scheme hasPrefix:@"sslocal://cjpay"] || [scheme hasPrefix:@"aweme://cjpay"];
}

@end

//
//  CJPayRequestCommonConfiguration.m
//  Pods
//
//  Created by 王新华 on 2021/9/22.
//

#import "CJPayRequestCommonConfiguration.h"

static Class<CJPayRequestInterceptionProtocol> cjpayRequestInterceptProtocol;

@implementation CJPayRequestCommonConfiguration

+ (void)setRequestInterceptProtocol:(Class<CJPayRequestInterceptionProtocol>)requestInterceptProtocol {
    cjpayRequestInterceptProtocol = requestInterceptProtocol;
}

+ (NSHashTable *)p_customHttpRequestHeaderProtocols {
    static NSHashTable *hashTable;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hashTable = [NSHashTable weakObjectsHashTable];
    });
    return hashTable;
}

+ (void)appendCustomHeaderProtocol:(Class<CJPaySDKHTTPRequestCustomHeaderProtocol>)protocol {
    NSHashTable *hashTable = [self p_customHttpRequestHeaderProtocols];
    if (![hashTable containsObject:protocol]) {
        [hashTable addObject:protocol];
    }
}

@end

@implementation CJPayRequestCommonConfiguration(Read)

+ (Class<CJPayRequestInterceptionProtocol>)requestInterceptProtocol {
    return cjpayRequestInterceptProtocol;
}

+ (NSHashTable<Class<CJPaySDKHTTPRequestCustomHeaderProtocol>> *)httpRequestHeaderProtocols {
    return [self p_customHttpRequestHeaderProtocols];
}

@end

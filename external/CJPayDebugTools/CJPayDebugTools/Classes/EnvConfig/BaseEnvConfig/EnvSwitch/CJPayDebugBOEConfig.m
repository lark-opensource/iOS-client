//
//  CJPayDebugBOEConfig.m
//  CJPay
//
//  Created by wangxiaohong on 2020/1/19.
//

#import "CJPayDebugBOEConfig.h"

@implementation CJPayDebugBOEConfig

+ (instancetype)shared {
    static CJPayDebugBOEConfig *share;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [CJPayDebugBOEConfig new];
    });
    return share;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _configHost = @"https://pay-boe.snssdk.com";
        _boeEnv = @{@"X-TT-ENV" : @"prod"};
        _boeWhiteList = @[@"https://tp-pay-test.snssdk.com", @"https://tp-pay.snssdk.com"];
        _boeSuffix = @".boe-gateway.byted.org";
    }
    return self;
}

- (void)enableBoe
{
    self.boeIsOpen = YES;
    [self updateBoeCookies];
}

- (void)disableBoe
{
    self.boeIsOpen = NO;
    [self p_deleteBoeCookies];
}

- (void)updateBoeCookies
{
    [self.boeEnv enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSHTTPCookie *cookie = [[NSHTTPCookie alloc] initWithProperties:[self p_buildCookie:key value:obj host:self.boeSuffix]];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    }];
}

- (void)p_deleteBoeCookies
{
    NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:self.boeSuffix]];
    [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self.boeEnv objectForKey:obj.name]) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:obj];
        }
    }];
}

- (nonnull NSDictionary<NSHTTPCookiePropertyKey,id> *)p_buildCookie:(NSString *)name value:(NSString *)value host:(NSString *)host
{
    NSMutableDictionary *cookie = [NSMutableDictionary dictionary];
    [cookie setValue:name forKey:NSHTTPCookieName];
    [cookie setValue:value forKey:NSHTTPCookieValue];
    [cookie setValue:@"/" forKey:NSHTTPCookiePath];
    [cookie setValue:[NSDate dateWithTimeIntervalSinceNow:3600] forKey:NSHTTPCookieExpires];
    [cookie setValue:@"cjpaysdk-add" forKey:NSHTTPCookieComment];
    [cookie setValue:host forKey:NSHTTPCookieDomain];
    return cookie;
}

@end

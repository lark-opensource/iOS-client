//
//  CJPayCookieUtil.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSDictionary *_Nullable(^CJPayConfigBlock)(void);

@interface CJPayCookieUtil : NSObject

@property (nonatomic, copy) CJPayConfigBlock cookieBlock;

+ (instancetype)sharedUtil;

- (void)setupCookie:(nullable void(^)(BOOL)) completion;
- (void)cleanCookies;

- (NSString *)getWKCookieScript:(NSString *)forUrl;

- (NSString *)getWebCommonScipt:(NSString *)forUrl;

- (NSDictionary *)_getCookieDic:(NSString *)forUrl;

- (NSDictionary<NSString *, NSString *> *)cjpayExtraParams;

@end

NS_ASSUME_NONNULL_END

//
//  NSURLProtocol+WebKitSupport.h
//  NSURLProtocol+WebKitSupport
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLProtocol (WebKitSupport)

/**
 * @brief 注册、注销 WKWebKit URL拦截。非多线程安全。
 */
+ (void)wk_registerScheme:(NSString*)scheme;
+ (void)wk_unregisterScheme:(NSString*)scheme;
+ (void)wk_unregisterAllCustomSchemes;

@end

NS_ASSUME_NONNULL_END

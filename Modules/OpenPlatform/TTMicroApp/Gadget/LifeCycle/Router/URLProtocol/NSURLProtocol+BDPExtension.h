//
//  NSURLProtocol+BDPExtension.h
//  Timor
//
//  Created by CsoWhy on 2018/8/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLProtocol (BDPExtension)

/**
 * @brief 注册、注销 WKWebKit URL拦截。非多线程安全。
 */
+ (void)bdp_registerScheme:(NSString*)scheme;
+ (void)bdp_unregisterScheme:(NSString*)scheme;

/** 设置WKWebview拦截协议，多个时考虑这个, 耗时更短*/
+ (void)bdp_registerSchemes:(NSArray<NSString *> *)schemes withWKWebview:(id)wkwebview;
+ (void)bdp_unregisterSchemes:(NSArray<NSString *> *)schemes withWKWebview:(id)wkwebview;

@end

NS_ASSUME_NONNULL_END

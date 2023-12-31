//
//  NSURLProtocol+OPExtension.h
//  Timor
//
//  Created by CsoWhy on 2018/8/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLProtocol (OPExtension)

/**
 * @brief 注册、注销 WKWebKit URL拦截。非多线程安全。
 */
+ (void)op_registerScheme:(NSString*)scheme;
+ (void)op_unregisterScheme:(NSString*)scheme;

/** 设置WKWebview拦截协议，多个时考虑这个, 耗时更短*/
+ (void)op_registerSchemes:(NSArray<NSString *> *)schemes withWKWebview:(id)wkwebview;
+ (void)op_unregisterSchemes:(NSArray<NSString *> *)schemes withWKWebview:(id)wkwebview;

@end

NS_ASSUME_NONNULL_END

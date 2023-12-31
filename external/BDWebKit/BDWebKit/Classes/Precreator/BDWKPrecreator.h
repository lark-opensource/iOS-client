//
//  BDWKProvider.h
//  BDWebKit
//
//  Created by Nami on 2019/11/13.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef WKWebView * _Nonnull(^BDWKGenerateHandler)(WKWebViewConfiguration *configuration);

/**
 * WK预创建
 */
@interface BDWKPrecreator : NSObject

/**
 *  设置可以缓存的 WKWebView 实例的最大数量
 * @note
 * 当设置为 0 时，就会清空已有的缓存实例。默认为 0。
 */
@property (nonatomic, assign) NSInteger maxNumberOfInstances;

/**
 * 设置内存警告时，不缓存实例的时间。当内存警告发生时，缓存会被清空，只有等到下次 fetch 或者 setMaxNumberOfInstances 接口被调用才会重新创建缓存实例。
 * 默认为 5 * 60 s。
 */
@property (nonatomic, assign) NSInteger memoryWarningProtectDuration;

/**
 * 当内存警告时，是否移除所有预创建的WK。默认YES
 */
@property (nonatomic, assign) BOOL isClearPrecreateWKWhenMemoryWarning;

/**
 * 设置补充WebView数量的delay时间，默认3s
 */
@property (nonatomic, assign) NSTimeInterval precreateWKDelaySeconds;

/**
 * 设置默认configuration，重新设置会清空已创建的实例
 */
@property (nonatomic, strong, nullable) WKWebViewConfiguration *webViewConfiguration;

/**
 * 设置默认构造block，可以自行构造WK。重新设置会清空已创建的实例
 */
@property (nonatomic, copy, nullable) BDWKGenerateHandler generateHandler;

/**
 * 当前缓存的WK个数
 */
@property (nonatomic, readonly) NSUInteger cachedCount;

/**
 * 默认预创建容器
 */
+ (instancetype)defaultPrecreator;

/**
 * 取走一个WKWebView，如果未预创建，则创建一个。
 */
- (WKWebView *)takeWebView;

/**
 * 取走一个WKWebView，如果未预创建，则创建一个。
 * @param isFromCache 返回是否来自预创建
 */
- (WKWebView *)takeWebViewWithIsFromCache:(BOOL * _Nullable)isFromCache;

@end

NS_ASSUME_NONNULL_END

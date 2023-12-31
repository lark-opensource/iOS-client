//
//  CJPayWebViewUADelegate.h
//  webview_ua_optimize_wuxi
//
//  Created by wuxi on 2023/6/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayWebViewUADelegate <NSObject>

/// 是否允许从 BDUAManager 获取 UA
- (BOOL)enableUAFetch;

/// 从 WKWebView 获取最新实时的 userAgent
- (void)fetchLastestSystemUserAgentWithCompletion:(void(^)(NSString * _Nullable userAgent,
                                                           NSString * _Nullable applicationName,
                                                           NSError * _Nullable error))completion;

/// 优先获取缓存的 UserAgent，如果没有则获取实时的 UA，效率优先
- (void)fetchSystemUserAgentWithCompletion:(void(^)(NSString * _Nullable userAgent,
                                                    NSString * _Nullable applicationName,
                                                    NSError * _Nullable error))completion;

/// 同步获取缓存的 UserAgent, 首次可能为空
- (NSString * _Nullable)fetchSystemUserAgentFromeCache;

@end

NS_ASSUME_NONNULL_END

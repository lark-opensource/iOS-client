//
//  BDWebViewUIManager.h
//  Aweme
//
//  Created by wuxi on 2023/5/31.
//

#import <Foundation/Foundation.h>

/// 提供从 WKWebView 获取 UserAgent 的能力
@interface BDWebViewUAManager : NSObject

/// 是否允许从 BDUAManager 获取 UA
+ (BOOL)enableUAFetch;

/// 从 WKWebView 获取最新实时的 userAgent
+ (void)fetchLastestSystemUserAgentWithCompletion:(void(^)(NSString * _Nullable userAgent,
                                                    NSString * _Nullable applicationName,
                                                    NSError * _Nullable error))completion;

/// 优先获取缓存的 UserAgent，如果没有则获取实时的 UA，效率优先
+ (void)fetchSystemUserAgentWithCompletion:(void(^)(NSString * _Nullable userAgent,
                                                    NSString * _Nullable applicationName,
                                                    NSError * _Nullable error))completion;

/// 同步获取缓存的 UserAgent, 首次可能为空
+ (NSString * _Nullable)fetchSystemUserAgentFromeCache;

@end

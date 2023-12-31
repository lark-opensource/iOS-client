//
//  BDWebPreloadOfflineInterceptor.h
//  Aweme
//
//  Created by bytedance on 2022/6/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WKWebView;
@interface BDWebPreloadOfflineInterceptor : NSObject

+ (void)setupWithWebView:(WKWebView *)webview;

@end

NS_ASSUME_NONNULL_END

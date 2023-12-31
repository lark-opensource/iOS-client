//
//  WKWebView+Security.h
//  BDWebKit-Pods-Aweme
//
//  Created by huangzhongwei on 2021/4/16.
//

#import <Foundation/Foundation.h>
#import "BDWebSecSettingManager.h"
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (Security)
+(void)enableSecurity:(id<BDWebSecSettingDelegate>)settingsDelegate;
@end

NS_ASSUME_NONNULL_END

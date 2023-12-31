//
//  BDWebViewOfflineStatusLogicControl.h
//  ByteWebView
//
//  Created by Lin Yong on 2019/2/28.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface BDWebViewOfflineStatusLogicControl : NSObject

+ (void)addWebViewWhenCreate:(WKWebView *)createdWebView;
+ (WKWebView *)lastVisibleWebViewWhenDestroy:(WKWebView *)destroyWebView;

@end

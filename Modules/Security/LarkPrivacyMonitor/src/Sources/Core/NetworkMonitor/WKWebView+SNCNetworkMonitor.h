//
//  WKWebView+SNCNetworkMonitor.h
//  LarkPrivacyMonitor
//
//  Created by 汤泽川 on 2023/7/4.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (SNCNetworkMonitor)
+ (void)snc_setupNetworkMonitor;
@end

NS_ASSUME_NONNULL_END

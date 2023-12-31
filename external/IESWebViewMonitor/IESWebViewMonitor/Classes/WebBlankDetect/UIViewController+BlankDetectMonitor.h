//
//  UIViewController+BlankDetectMonitor.h
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/6/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^BDWebViewMonitorBizSwitchBlock)(NSString *url);

@class WKWebView;

@interface BDMonitorWebBlankDetector : NSObject

+ (void)switchWebViewBlankDetect:(BOOL)isOn webView:(WKWebView *)webView viewController:(UIViewController *)viewController;

@end

@interface UIViewController (BlankDetectMonitor)

// 开启webview自动白屏检测
- (void)switchWebViewBlankDetect:(BOOL)isOn webView:(WKWebView *)webView;

// 开启白屏自动检测，添加block接口，由业务方根据回退时当前url判断是否需要检测
- (void)switchWebViewBlankDetect:(BOOL)isOn webView:(WKWebView *)webView bizSwitchBlock:(nullable BDWebViewMonitorBizSwitchBlock)bizSwitchBlock;

@end

NS_ASSUME_NONNULL_END

//
//  BDTuringWebView.h
//  BDTuring
//
//  Created by bob on 2020/2/25.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN
@class BDTuringConfig, BDTuringWebView;

@protocol BDTuringWebViewDelegate <NSObject>

@optional

- (void)webViewDidShow:(BDTuringWebView *)verifyView;
- (void)webViewDidHide:(BDTuringWebView *)verifyView;
- (void)webViewDidDismiss:(BDTuringWebView *)verifyView;

- (void)webViewLoadDidSuccess:(BDTuringWebView *)verifyView;
- (void)webViewLoadDidFail:(BDTuringWebView *)verifyView;

@end

@interface BDTuringWebView : UIView <WKNavigationDelegate>

@property (nonatomic, strong, readonly) WKWebView *webView;
@property (nonatomic, weak, nullable) id<BDTuringWebViewDelegate> delegate;
@property (nonatomic, assign) BOOL loadingSuccess;
@property (nonatomic, assign) long long startLoadTime;

- (void)loadWebView;
- (void)showVerifyView;
- (void)hideVerifyView; /// will never show after it hide 
- (void)scheduleDismissVerifyView;
- (void)dismissVerifyView;
- (UIViewController *)controller;

- (void)startLoadingView;
- (void)stopLoadingView;

@end

NS_ASSUME_NONNULL_END

//
//  BDWSCCWebViewCustomHandler.h
//  tiktok-scc
//
//  Created by ByteDance on 2022/9/26.
//


#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDWebViewSCCReportType) {
    BDWebViewSCCReportTypeUnknown,
    BDWebViewSCCReportTypeAllow,
    BDWebViewSCCReportTypeDeny,
    BDWebViewSCCReportTypeNotice,
    BDWebViewSCCReportTypeCancel,
};

@protocol BDWSCCWebViewCustomHandler <NSObject>

- (NSDictionary * _Nullable)fetchAllowAndDenyList;

// @return 返回YES表示需要取消这次网络请求
- (BOOL)bdw_URLRiskLevel:(BDWebViewSCCReportType)level forReason:(NSString * _Nullable)reason withWebView:(WKWebView * _Nonnull)webView forURL:(NSURL *_Nonnull)url canGoBack:(BOOL)canGoBack;

// @return 返回YES表示跳过云查
- (BOOL)bdw_willSkipSCCCloudCheck:(WKWebView * _Nonnull)webView forURL:(NSURL * _Nonnull)url;

@optional

-(NSDictionary * _Nullable)fetchSeclinkParameter;

-(NSDictionary * _Nullable)fetchAllowListForJumpAPP;

@end

NS_ASSUME_NONNULL_END


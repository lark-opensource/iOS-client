//
//  BDWebURLSchemeTaskHandler.h
//  BDWebKit
//
//  Created by li keliang on 2020/4/3.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "BDWebHTTPCachePolicy.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDWebURLSchemeTask;

typedef NSData * _Nullable (^BDWebURLSchemeTaskDataProcessor)(id<BDWebURLSchemeTask>task, NSData * data);
typedef NSURLResponse * _Nullable (^BDWebURLSchemeTaskResponseProcessor)(id<BDWebURLSchemeTask>task, NSURLResponse * data);

@protocol BDWebURLSchemeTaskLifeCycleProtocol <NSObject>

@optional

- (void)URLSchemeTask:(id<BDWebURLSchemeTask>)task didReceiveResponse:(NSURLResponse *)response;

- (void)URLSchemeTask:(id<BDWebURLSchemeTask>)task didLoadData:(NSData *)data;

- (void)URLSchemeTaskDidFinishLoading:(id<BDWebURLSchemeTask>)task;

- (void)URLSchemeTask:(id<BDWebURLSchemeTask>)task didFailWithError:(NSError *)error;

- (void)URLSchemeTask:(id<BDWebURLSchemeTask>)task didPerformRedirection:(NSURLResponse *)response newRequest:(NSURLRequest *)request;

@end

@protocol BDWebURLSchemeTask <NSObject>

@property (nonatomic, readonly, strong) NSURLRequest *bdw_request;

- (void)bdw_didReceiveResponse:(NSURLResponse *)response;

- (void)bdw_didLoadData:(NSData *)data;

- (void)bdw_didFinishLoading;

- (void)bdw_didFailWithError:(NSError *)error;

- (void)bdw_didPerformRedirection:(NSURLResponse *)response newRequest:(NSURLRequest *)request;

@optional

// Get from BDWebRequestDecorator, will be set to NSURLRequest associatedObject
@property (nullable, nonatomic, strong) NSDictionary *bdw_additionalInfo;

// Get from BDWebRequestDecorator, will judge whether schemeHandler should reuse ttnet task.
@property (nonatomic, assign) BOOL bdw_shouldUseNetReuse;

// Get from RL, will be set to IESWebViewMonitor&HDT
@property (nullable, nonatomic, strong) NSMutableDictionary *bdw_rlProcessInfoRecord;

// Get from TTHttpResponseTimingInfo if task finish with TTNet
@property (nullable, nonatomic, strong) NSDictionary *bdw_ttnetResponseTimingInfoRecord;

// Process data before sent to WebView, at BDWebURLSchemeTask:bdw_didLoadData:
@property (nonatomic, copy) BDWebURLSchemeTaskDataProcessor bdw_dataProcessor;

// Process response before sent to WebView, at BDWebURLSchemeTask:bdw_didReceiveResponse:
@property (nonatomic, copy) BDWebURLSchemeTaskResponseProcessor bdw_responseProcessor;

@property (nonatomic, weak, nullable) id<BDWebURLSchemeTaskLifeCycleProtocol> bdw_lifecycleDelegate;

@property (nonatomic, weak) WKWebView *bdw_webView;

@property (nonatomic, assign) BOOL taskFinishWithTTNet;

@property (nonatomic, assign) BOOL taskFinishWithLocalData;

@property (nonatomic, assign) BOOL useTTNetCommonParams;

@property (nonatomic, assign) BOOL ttnetEnableCustomizedCookie;

@property (nonatomic, assign) BOOL willRecordForMainFrameModel;

@property (nonatomic, assign) BDWebHTTPCachePolicy taskHttpCachePolicy;

@end

@protocol BDWebURLSchemeTaskHandler <NSObject>

- (instancetype)initWithWebView:(nullable WKWebView *)webView schemeTask:(id<BDWebURLSchemeTask>)task;

+ (BOOL)bdw_canHandleRequest:(NSURLRequest *)request;

- (void)bdw_startURLSchemeTask;

- (void)bdw_stopURLSchemeTask;

@optional

+ (BOOL)bdw_canHandleRequest:(NSURLRequest *)request
                     webview:(nullable WKWebView *)webview;

@end

NS_ASSUME_NONNULL_END

//
//  IESFalconManager.h
//  IESWebKit
//
//  Created by li keliang on 2018/10/9.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "IESFalconCustomInterceptor.h"
#import "IESFalconGurdInterceptionDelegate.h"
#import <BDWebKit/BDWebURLProtocolTask.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IESFalconInterceptionDelegate <NSObject>

@optional
- (void)falconInterceptedRequest:(NSURLRequest *)request willLoadFromCache:(BOOL)fromCache;

@end

@protocol IESFalconMonitorInterceptor <NSObject>

@optional
- (void)willGetMetaData:(id<IESFalconMetaData> _Nullable)metaData forRequest:(NSURLRequest *)request;
- (void)didGetMetaData:(id<IESFalconMetaData> _Nullable)metaData forRequest:(NSURLRequest *)request isGetMethod:(BOOL)isGetMethod isCustomInterceptor:(BOOL)isCustomInterceptor;
- (void)webView:(WKWebView *)webView loadRequest:(NSURLRequest *)request metaData:(id<IESFalconMetaData> _Nullable)metaData isCustomInterceptor:(BOOL)isCustomInterceptor;
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation;
@end

@interface IESFalconManager : NSObject

@property (nullable,  class) id<IESFalconInterceptionDelegate> interceptionDelegate;

@property (nonatomic, class, assign) BOOL interceptionLock;

@property (nonatomic, class, assign) BOOL webpDecodeEnable;

// disable http&https scheme for webview, always for outside-website
@property (nonatomic, class, assign) BOOL interceptionDisableWKHttpScheme;
@property (nonatomic, class, assign) BOOL interceptionWKHttpScheme;
@property (nonatomic, class, assign) BOOL interceptionEnable;
/// enable custom intercetpors of webview instance
@property (nonatomic, class, assign) BOOL interceptionInstanceLevelEnable;

@property (nonatomic, class, copy) NSString *(^defaultUABlock)(void);

//call before set interceptionEnable.
@property (nonatomic, class, assign) BOOL interceptionUseFalconURLSchemaHandle;

@property(nonatomic, strong, class, readonly) NSHashTable *monitorInterceptors;

+ (void)addInterceptor:(id<IESFalconMonitorInterceptor>)interceptor;

+ (void)removeInterceptor:(id<IESFalconMonitorInterceptor>)interceptor;

// check if request will be blocked, use RequestFilter from BDWebInterceptor
+ (BOOL)willBlockRequest:(NSURLRequest *)request;

// decorate request at IESFalconURLProtocol canonicalRequestForRequest
+ (NSURLRequest *)willDecorateRequest:(NSURLRequest *)request;

+ (void)willDecorateURLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask;

+ (void)bdw_URLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask didReceiveResponse:(NSURLResponse *)response;

+ (void)bdw_URLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask didLoadData:(NSData *)data;

+ (void)bdw_URLProtocolTaskDidFinishLoading:(id<BDWebURLProtocolTask>)urlProtocolTask;

+ (void)bdw_URLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask didFailWithError:(NSError *)error;

+ (void)bdw_URLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask didPerformRedirection:(NSURLResponse *)response newRequest:(NSURLRequest *)request;

@property (nonatomic, class, readonly, copy) NSArray <id<IESFalconCustomInterceptor>> *customInterceptors;

+ (void)registerPattern:(NSString *)pattern forGurdAccessKey:(NSString *)accessKey;
+ (void)registerPatterns:(NSArray <NSString *> *)patterns forGurdAccessKey:(NSString *)accessKey;

+ (void)registerPattern:(NSString *)pattern forSearchPath:(NSString *)searchPath;
+ (void)registerPatterns:(NSArray <NSString *> *)patterns forSearchPath:(NSString *)searchPath;

+ (void)unregisterPatterns:(NSArray <NSString *> *)patterns;

+ (void)registerCustomInterceptor:(id<IESFalconCustomInterceptor>)interceptor;
+ (void)unregisterCustomInterceptor:(id<IESFalconCustomInterceptor>)interceptor;

+ (id<IESFalconMetaData> _Nullable)falconMetaDataForURLRequest:(NSURLRequest *)request;

+ (BOOL)shouldInterceptForRequest:(NSURLRequest*)request;

+ (NSData * _Nullable)falconDataForURLRequest:(NSURLRequest *)request;

/// check interceptors from webview.bdw_customInterceptors first.
/// @param request request
/// @param webview WKWebView
+ (id<IESFalconMetaData> _Nullable)falconMetaDataForURLRequest:(NSURLRequest *)request
                                                       webView:(WKWebView * _Nullable)webview;

/// check interceptors from webview.bdw_customInterceptors first.
/// @param request request
/// @param webview WKWebView
+ (BOOL)shouldInterceptForRequest:(NSURLRequest*)request
                          webView:(WKWebView * _Nullable)webview;

/// check interceptors from webview.bdw_customInterceptors first.
/// @param request request
/// @param webview WKWebView
+ (NSData * _Nullable)falconDataForURLRequest:(NSURLRequest *)request
                                      webView:(WKWebView * _Nullable)webview;

+ (void)webView:(WKWebView *)webView
    loadRequest:(NSURLRequest *)request
       metaData:(id<IESFalconMetaData> _Nullable)metaData;

+ (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation;

/// append FalconTag/{custom_uuid} to user agent
/// @param webview WKWebView
/// @param uuid uuid key (eg: monitor webview uuid)
/// @result YES:succeed to add UA tag  NO: maybe falconTag already exist or customUA is nil
+ (BOOL)decorateFalconWebView:(WKWebView *)webview withUUID:(NSString *)uuid;

/// append FalconTag/{UUID} to user agent
/// @param webview WKWebView
+ (void)decoratedFalconUserAgentWithWebView:(WKWebView *)webview;

/// find webview with specific user agent
/// @param userAgent user agent
+ (WKWebView *)webviewWithUserAgent:(NSString *)userAgent;

@end

@interface WKWebView (Falcon)

@property (nonatomic, readonly) NSArray<id<IESFalconCustomInterceptor>> *bdw_customFalconInterceptors;

@property (nonatomic, assign) BOOL bdw_disableGlobalFalconIntercetors;

/// Webview wiil retain the interceptor.
/// @param customInterceptor custom interceptor
- (void)bdw_registerFalconCustomInterceptor:(id<IESFalconCustomInterceptor>)customInterceptor;

- (void)bdw_unregisterFalconCustomInterceptor:(id<IESFalconCustomInterceptor>)customInterceptor;

@end

@interface NSURLRequest (IESFalconManager)

// key - BDWebResourceMonitorEventType.h
@property (nonatomic) NSMutableDictionary *bdw_falconProcessInfoRecord;

// 初始化相关字段,非重置,尽量只调用一次
- (void)bdw_initFalconProcessInfoRecord;

@end

NS_ASSUME_NONNULL_END

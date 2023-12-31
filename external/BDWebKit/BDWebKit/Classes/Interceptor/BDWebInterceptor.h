//
//  BDWebInterceptor.h
//  BDWebKit
//
//  Created by li keliang on 2020/3/13.
//

#import <Foundation/Foundation.h>
#import <BDWebCore/IWKPluginObject.h>
#import <BDWebKit/BDWebURLSchemeTaskHandler.h>
#import <BDWebKit/BDWebURLProtocolTask.h>
#import "BDWebRequestDecorator.h"
#import "BDWebRequestFilter.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDWebInterceptorMonitor <NSObject>

- (void)bdw_URLSchemeTask:(id<BDWebURLSchemeTask>)schemeTask didReceiveResponse:(NSURLResponse *)response;

- (void)bdw_URLSchemeTask:(id<BDWebURLSchemeTask>)schemeTask didLoadData:(NSData *)data;

- (void)bdw_URLSchemeTaskDidFinishLoading:(id<BDWebURLSchemeTask>)schemeTask;

- (void)bdw_URLSchemeTask:(id<BDWebURLSchemeTask>)schemeTask didFailWithError:(NSError *)error;

- (void)bdw_URLSchemeTask:(id<BDWebURLSchemeTask>)schemeTask didPerformRedirection:(NSURLResponse *)response newRequest:(NSURLRequest *)request;

@optional

- (void)bdw_URLProtocolTask:(id<BDWebURLProtocolTask>)schemeTask didReceiveResponse:(NSURLResponse *)response;

- (void)bdw_URLProtocolTask:(id<BDWebURLProtocolTask>)schemeTask didLoadData:(NSData *)data;

- (void)bdw_URLProtocolTaskDidFinishLoading:(id<BDWebURLProtocolTask>)schemeTask;

- (void)bdw_URLProtocolTask:(id<BDWebURLProtocolTask>)schemeTask didFailWithError:(NSError *)error;

- (void)bdw_URLProtocolTask:(id<BDWebURLProtocolTask>)schemeTask didPerformRedirection:(NSURLResponse *)response newRequest:(NSURLRequest *)request;

@end


@class BDWebURLSchemeTask;

@protocol BDWebInterceptorHandler <NSObject>

@required

- (BOOL)canHandleRequest:(BDWebURLSchemeTask *)schemeTask;

@optional

- (void)bdw_URLSchemeTask:(BDWebURLSchemeTask *)schemeTask didLoadData:(NSData *)data;

- (void)bdw_URLSchemeTaskDidFinishLoading:(BDWebURLSchemeTask *)schemeTask;

@end

@interface BDWebInterceptor : NSObject

+ (instancetype)sharedInstance;
+ (NSHashTable *)bdw_globalInterceptorMonitors;
+ (void)addGlobalInterceptorMonitor:(id<BDWebInterceptorMonitor>)interceptorMonitor;
+ (void)removeGlobalInterceptorMonitor:(id<BDWebInterceptorMonitor>)interceptorMonitor;
+ (void)addGlobalRequestFilter:(id<BDWebRequestFilter>)requestFilter;
+ (void)removeGlobalRequestFilter:(id<BDWebRequestFilter>)requestFilter;
+ (BOOL)willBlockRequest:(NSURLRequest *)request;
+ (NSURLRequest *)willDecorateRequest:(NSURLRequest *)request;
+ (void)willDecorateURLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask;

- (void)registerCustomURLSchemaHandler:(Class<BDWebURLSchemeTaskHandler>)schemaHandler;
- (void)registerCustomRequestDecorator:(Class<BDWebRequestDecorator>)requestDecorator;
- (void)removeCustomRequestDecorator:(Class<BDWebRequestDecorator>)requestDecorator;
- (void)setupClassPluginForWebInterceptor;

@end

@interface WKWebViewConfiguration (BDWebInterceptor)

@property (nonatomic, assign) BOOL bdw_enableInterceptor API_AVAILABLE(ios(12.0));
@property (nonatomic, assign) BOOL bdw_skipFalconWaitFix;

@end

@interface WKWebView (BDWebInterceptor)

@property (nonatomic,   weak) id<BDWebInterceptorMonitor> bdw_interceptorMonitor API_AVAILABLE(ios(12.0));
@property (nonatomic,   weak) id<BDWebInterceptorHandler> bdw_interceptorHandler API_AVAILABLE(ios(12.0));

@end

NS_ASSUME_NONNULL_END

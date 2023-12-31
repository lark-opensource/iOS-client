// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxPerformance.h"
#import "LynxResourceFetcher.h"

#if TARGET_OS_IOS
#import "LynxImageFetcher.h"
#import "LynxScrollListener.h"
#endif

@class LynxView;
@class LynxModule;
@class LynxConfigInfo;
@class LynxEventDetail;

@protocol LynxTimingListener <NSObject>

@optional
- (void)lynxView:(LynxView *)lynxView onSetup:(NSDictionary *)info;
- (void)lynxView:(LynxView *)lynxView
        onUpdate:(NSDictionary *)info
          timing:(NSDictionary *)updateTiming;

@end

@protocol LynxJSBTimingListener <NSObject>

@optional
- (void)lynxView:(LynxView *)lynxView onCallJSBFinished:(NSDictionary *)info;
- (void)lynxView:(LynxView *)lynxView onJSBInvoked:(NSDictionary *)jsbInfo;

@end

@protocol LynxViewLifecycle <NSObject, LynxTimingListener, LynxJSBTimingListener>

@optional

+ (void)lynxView:(LynxView *)lynxView
    reportResourceInfo:(NSDictionary *)info
             eventType:(NSString *)eventType;

/**
 * Notify that element has been created on LynxView. This method
 * is called when every element was created.
 */
- (void)lynxViewDidCreateElement:(LynxUI*)element name:(NSString*)name;

// issue: #1510
- (void)lynxView:(LynxView *)view
    didInvokeMethod:(NSString *)method
           inModule:(NSString *)module
          errorCode:(int)code;

/**
 * Notify that content has started loading on LynxView. This method
 * is called once for each content loading request.
 */
- (void)lynxViewDidStartLoading:(LynxView *)view;

/**
 * Notify that content has been successful loaded on LynxView. This method
 * is called once for each load content request.
 *
 * @param view LynxView
 * @param url  The url of the content
 */
- (void)lynxView:(LynxView *)view didLoadFinishedWithUrl:(NSString *)url;

/**
 * Report lynx config info after that content has been successful loaded on LynxView.
 * This method is called once for each load content request.
 *
 * @param view LynxView
 * @param info LynxConfigInfo
 */
- (void)lynxView:(LynxView *)view didLoadFinishedWithConfigInfo:(LynxConfigInfo *)info;
/**
 * Notify that LynxView has been first layout after the content is loaded.
 * You can get performance during loading process of the LynxView at this time.
 */
- (void)lynxViewDidFirstScreen:(LynxView *)view;

/**
 * Notify that LynxView has been layout after the content has changed,
 * such as after native updateData, js setData.
 */
- (void)lynxViewDidPageUpdate:(LynxView *)view;

/**
 * Notify the JS Runtime is  ready.
 */
- (void)lynxViewDidConstructJSRuntime:(LynxView *)view;

/**
 * Notify that LynxView has been updated after updating data on LynxView,
 * but the view may not be updated.
 * You can get performance during updating perocess of the LynxView at this moment.
 */
- (void)lynxViewDidUpdate:(LynxView *)view;

/**
 * Notify the intriniscContentSize has changed.
 */
- (void)lynxViewDidChangeIntrinsicContentSize:(LynxView *)view;

/**
 * Notify tasm has finished.
 */
- (void)lynxViewOnTasmFinishByNative:(LynxView *)view;

/**
 * Notify the host application of a image request and allow the application
 * to redirect the url and return. If the return value is null, LynxView will
 * continue to load image from the origin url as usual. Otherwise, the redirect
 * url will be used.
 *
 * This method will be called on any thread.
 *
 * The following scheme is supported in LynxView:
 * 1. Http scheme: http or https
 * 2. File scheme: sources in app sandbox
 * Notice: Image in asste catalog is not support now.
 *
 * @param url the url that ready for loading image
 * @return A url string that fit int with the support scheme list or null
 */
- (NSURL *)shouldRedirectImageUrl:(NSURL *)url
    __attribute__((deprecated("Use loadImage:size:completion: to load image.")));

/**
 * The callback is only called when template provider failed to fetch tempate resource.
 * The callback is depercated. Developer should use `lynxView:didRecieveError:` with errorCode
 * `LynxErrorCodeTemplateProvider`.
 */
- (void)lynxView:(LynxView *)view
    didLoadFailedWithUrl:(NSString *)url
                   error:(NSError *)error
    __attribute__((deprecated("Use `lynxView:didRecieveError:`.")));

/**
 * Notify that LynxView has error happens.
 * @param view which view meets the error.
 * @param error the error object which should be a LynxError instance.
 * @see LynxError for error domain and error code.
 */
- (void)lynxView:(LynxView *)view didRecieveError:(NSError *)error;

/**
 * 首次加载完成之后的性能数据统计完成回调。
 * NOTE：回调时机由于渲染线程的差别，不固定，不应作为任何业务方的打点起始点。
 * 回调位于主线程。
 */
- (void)lynxView:(LynxView *)view didReceiveFirstLoadPerf:(LynxPerformance *)perf;

/**
 * 界面更新之后的性能统计完成回调。
 * NOTE：回调时机由于渲染线程的差别，不固定，不应作为任何业务方的打点起始点。
 * 回调位于主线程。
 */
- (void)lynxView:(LynxView *)view didReceiveUpdatePerf:(LynxPerformance *)perf;

/**
 * 首次加载完成之后或者界面更新之后，动态组件性能数据统计完成回调。
 * NOTE：回调时机由于渲染线程的差别，不固定，不应作为任何业务方的打点起始点。
 * 回调位于主线程。
 */
- (void)lynxView:(LynxView *)view didReceiveDynamicComponentPerf:(NSDictionary *)perf;

/**
 * 界面销毁后上报使用过的component
 */
- (void)lynxView:(LynxView *)view didReportComponentInfo:(NSSet<NSString *> *)componentSet;

/**
 * Notify that LynxView will send a touch event to frontend.
 * @param event Event's detail, including eventName, lynxView, etc.
 */
- (void)onLynxEvent:(LynxEventDetail *)event;

/**
 * @param info Piper's information
 *             "url" : (String)Lynx's url
 *             "module-name" (NSString): module's name
 *             "method-name" (NSString): method's name
 *             "params" (NSArray<id>): (Optional) other necessary parameters
 */
- (void)onPiperInvoked:(NSDictionary *)info;

/**
 * @param info Piper's response
 *             "url" : (String)Lynx's url
 *             "module-name" (NSString): module's name
 *             "method-name" (NSString): method's name
 *             "session-id"(NSString): method's invoke session key string
 *             "response" (NSArray<Str>): (Optional) jsb response parameters
 */
- (void)onPiperResponsed:(NSDictionary *)info;

@end

/**
 * A class conforming to the LynxViewClient protocol can provide
 * methods for tracking progress for loading of @see LynxView.
 */

#if TARGET_OS_IOS
__attribute__((deprecated(
    "lifecycle functions in LynxViewClient will be moved to protocol LynxViewLifeCycle")))
@protocol
    LynxViewClient<LynxImageFetcher, LynxResourceFetcher, LynxViewLifecycle, LynxScrollListener>

@end
#endif

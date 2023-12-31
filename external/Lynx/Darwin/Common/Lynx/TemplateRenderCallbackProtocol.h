//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_TEMPLATERENDERCALLBACKPROTOCOL_H_
#define DARWIN_COMMON_LYNX_TEMPLATERENDERCALLBACKPROTOCOL_H_

#import <Foundation/Foundation.h>
#include "tasm/page_config.h"
#include "tasm/react/ios/prop_bundle_darwin.h"

/**
 * This protocol is implemented by LynxTemplateRender
 */

NS_ASSUME_NONNULL_BEGIN

@class LynxTheme;
@class LynxContext;
@class LynxGenericReportInfo;

@protocol TemplateRenderCallbackProtocol <NSObject>

@required
/**
 * Notify that data has been updated after updating data on LynxView,
 * but the view may not be updated.
 */
- (void)onDataUpdated;
/**
 * Notify that page has been changed.
 */
- (void)onPageChanged:(BOOL)isFirstScreen;
/**
 * Notify that tasm has finished.
 */
- (void)onTasmFinishByNative;
/**
 * Notify that content has been successful loaded. This method
 * is called once for each load content request.
 */
- (void)onTemplateLoaded:(NSString *)url;
/**
 * Notify the JS Runtime is  ready.
 */
- (void)onRuntimeReady;
/**
 * Dispatch error to LynxTemplateRender
 */
- (void)onErrorOccurred:(NSInteger)code message:(NSString *)errMessage;
/**
 * Dispatch module method request to LynxTemplateRender
 * @param method method name
 * @param module module name
 * @param code error code
 */
- (void)didInvokeMethod:(NSString *)method inModule:(NSString *)module errorCode:(int32_t)code;
/**
 * Notify the performance data statistics after the first load is completed
 */
- (void)onFirstLoadPerf:(NSDictionary *)perf;
/**
 * Notify the performance statistics after page update
 */
- (void)onUpdatePerfReady:(NSDictionary *)perf;
/**
 * Notify the performance statistics after dynamic component is loaded or updated
 */
- (void)onDynamicComponentPerf:(NSDictionary *)perf;

- (void)setLocalTheme:(LynxTheme *)theme;
- (void)setPageConfig:(const std::shared_ptr<lynx::tasm::PageConfig> &)pageConfig;
- (void)setTiming:(uint64_t)timestamp key:(NSString *)key updateFlag:(NSString *)updateFlag;

/**
 * Get translated resource
 */
- (NSString *)translatedResourceWithId:(NSString *)resId themeKey:(NSString *)key;
/**
 * Get internationalization resource
 * @param channel channel
 * @param url fallback url
 */
- (void)getI18nResourceForChannel:(NSString *)channel withFallbackUrl:(NSString *)url;

/**
 * Asynchronous trigger lepus bridge to invoke function from event handler
 * @param data function param
 * @param callbackID callback id
 */
- (void)invokeLepusFunc:(NSDictionary *)data callbackID:(int32_t)callbackID;

/**
 * Notify lynx to load component. This method will be called after fetching dynamic component
 * resource
 * @param tem template data of component
 * @param url template url of component
 * @param callbackId callbackId
 */
- (void)loadComponent:(NSData *)tem withURL:(NSString *)url withCallbackId:(int32_t)callbackId;

- (void)onCallJSBFinished:(NSDictionary *)info;
- (void)onJSBInvoked:(NSDictionary *)info;

- (void)reportEvents:(std::vector<std::unique_ptr<lynx::tasm::PropBundle>>)stack;

/**
 * Performance data
 */
- (long)initStartTiming;
- (long)initEndTiming;

- (LynxContext *)getLynxContext;
- (NSMutableDictionary<NSString *, id> *)getLepusModulesClasses;

- (BOOL)enableAirStrictMode;

@optional
- (void)invokeUIMethod:(NSString *_Nonnull)method_string
                params:(NSDictionary *_Nonnull)params
              callback:(int)callback
                toNode:(int)node;

/**
 * Notify that SSR page has hydrated successfully . This method
 * is called once for each load content request.
 */
- (void)onSSRHydrateFinished:(NSString *)url;

/**
 * Class hold some info like templateURL, thread strategy, pageConfig and etc.
 * It's used to report some common useful parameter when report event.
 * Mainly converted to JSONObject by toJSONObject() method,
 * and used as the third argument in API below:
 * @see ILynxApplogService#onReportEvent(String, JSONObject, JSONObject)
 */
- (LynxGenericReportInfo *)genericReportInfo;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_TEMPLATERENDERCALLBACKPROTOCOL_H_

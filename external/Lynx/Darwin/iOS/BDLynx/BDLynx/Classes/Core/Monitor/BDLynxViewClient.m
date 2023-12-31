//
//  BDLynxViewClient.m
//  BDLynx
//
//  Created by bill on 2020/2/4.
//

#import "BDLynxViewClient.h"
#import "NSDictionary+BDLynxAdditions.h"

#import "BDLImageProtocol.h"
#import "BDLReportProtocol.h"
#import "BDLSDKManager.h"
#import "BDLynxTracker.h"
#import "BDSettings.h"
#import "LynxEnv.h"
#import "LynxError.h"
#import "LynxView.h"

#import <TTNetworkManager/TTNetworkManager.h>
#import "BDLHostProtocol.h"
#import "BDLLynxModuleProtocol.h"
#import "BDLSDKManager.h"
#import "BDLUtils.h"
#import "BDLynxPostDataHttpRequestSerializer.h"

@interface BDLynxViewClient ()

@property(nonatomic, copy) NSString *channel;
@property(nonatomic, copy) NSString *bundlePath;
@property(nonatomic, copy) NSString *sessionID;
@property(nonatomic, copy) NSString *errorMessage;
@property(nonatomic, copy) NSString *originURL;

// Hybrid Monitor
@property(nonatomic, assign) CFTimeInterval startLoadTime;
@property(nonatomic, assign) CFTimeInterval pageStartTime;
@property(nonatomic, assign) CFTimeInterval firstDrawTime;
@property(nonatomic, assign) CFTimeInterval firstScreenTime;
@property(nonatomic, assign) CFTimeInterval pageFinishTime;

@property(nonatomic, assign) CFTimeInterval binaryDecodeInterval;
@property(nonatomic, assign) CFTimeInterval decodeToLoadInterval;
@property(nonatomic, assign) CFTimeInterval lynxLoadInterval;
@property(nonatomic, assign) CFTimeInterval finishLoadTasmInterval;
@property(nonatomic, assign) CFTimeInterval firstDrawInterval;
@property(nonatomic, assign) CFTimeInterval layoutInterval;
@property(nonatomic, assign) CFTimeInterval firstScreenInterval;
@property(nonatomic, assign) CFTimeInterval renderPageInterval;
@property(nonatomic, assign) CFTimeInterval pageFinishInterval;

// Engine Timeline
@property(nonatomic, assign) CFTimeInterval diffRootInterval;
@property(nonatomic, assign) CFTimeInterval diffSameRootInterval;
@property(nonatomic, assign) CFTimeInterval jsFinishLoadCoreInterval;
@property(nonatomic, assign) CFTimeInterval jsFinishLoadAppInterval;
@property(nonatomic, assign) CFTimeInterval jsTasmAllReadyInterval;
@property(nonatomic, assign) CFTimeInterval ttiInterval;

@property(nonatomic, assign) BOOL isFirstScreenTracked;
@property(nonatomic, assign) BOOL isFinishTracked;

// For Monitor report: Bid - businessId
@property(nonatomic, copy) NSString *reportBid;
// For Monitor report: Pid - pageId
@property(nonatomic, copy) NSString *reportPid;

@property(nonatomic, strong) NSDictionary *perfDict;

@end

@implementation BDLynxViewClient

- (instancetype)initWithChannel:(NSString *)channel
                     bundlePath:(NSString *)path
                      sessionID:(NSString *)sessionID
                  pageStartTime:(CFTimeInterval)time {
  self = [super init];
  if (self) {
    _channel = channel;
    _bundlePath = path;
    _sessionID = sessionID;
    _pageStartTime = time;
  }
  return self;
}

- (void)updateChannel:(NSString *)channel
           bundlePath:(NSString *)path
            sessionID:(NSString *)sessionID
        pageStartTime:(CFTimeInterval)time {
  _channel = channel;
  _bundlePath = path;
  _sessionID = sessionID;
  _pageStartTime = time;
}

- (void)updateBid:(NSString *)bid pid:(NSString *)pid {
  _reportBid = bid;
  _reportPid = pid;
}

- (nonnull dispatch_block_t)loadImageWithURL:(nonnull NSURL *)url
                                        size:(CGSize)targetSize
                                 contextInfo:(nullable NSDictionary *)contextInfo
                                  completion:(nonnull LynxImageLoadCompletionBlock)completionBlock {
  if (url) {
    if (BDL_SERVICE(BDLImageProtocol)) {
      [BDL_SERVICE_WITH_SELECTOR(BDLImageProtocol, @selector(requestImage:channel:path:complete:))
          requestImage:url
               channel:self.channel
                  path:self.bundlePath
              complete:^(UIImage *_Nonnull image, NSError *__nullable error) {
                if (completionBlock) {
                  completionBlock(image, error, url);
                }
              }];
    } else {
      //            NSLog(@"------ BDLImageProtocol not bind ------");
    }
  }
  return ^{
    // TODO
    if (url) {
    }
  };
}

- (dispatch_block_t)loadCanvasImageWithURL:(NSURL *)url
                               contextInfo:(nullable NSDictionary *)contextInfo
                                completion:
                                    (nonnull LynxCanvasImageLoadCompletionBlock)completionBlock {
  if (url == nil) {
    return nil;
  }

  NSURLSessionDataTask *task = [NSURLSession.sharedSession
        dataTaskWithURL:url
      completionHandler:^(NSData *received, NSURLResponse *response, NSError *error) {
        if (completionBlock) {
          NSURL *responseUrl = [response URL];
          completionBlock(received, error, responseUrl);
        }
      }];
  [task resume];

  return ^() {
    [task cancel];
  };
}

- (void)lynxViewDidStartLoading:(LynxView *)view {
  // 1
  _pageStartTime = [self currentTimeSince1970];
  _startLoadTime = [self currentTimeSince1970];
  [self trackLynxRenderPipelineTrigger:@"start_load_time"];
  if ([self.lifeCycleDelegate respondsToSelector:@selector(viewDidStartLoading)]) {
    [self.lifeCycleDelegate viewDidStartLoading];
  }
}

- (void)lynxView:(LynxView *)view didLoadFinishedWithUrl:(NSString *)url {
  // 4
  _pageFinishTime = [self currentTimeSince1970];
  [self trackLynxRenderPipelineTrigger:@"page_finish_time"];
  [[BDSettings shareInstance] syncSettings];
  if ([self.lifeCycleDelegate respondsToSelector:@selector(viewDidFinishLoadWithURL:)]) {
    [self.lifeCycleDelegate viewDidFinishLoadWithURL:url];
  }
}

- (void)lynxView:(LynxView *)view didReceiveFirstLoadPerf:(LynxPerformance *)perf {
  [self convertLifeCycleInterval:perf];
  self.perfDict = perf.toDictionary;
  [self trackLynxRenderPipelineTrigger:@"page_first_load_perf_time"];
  if ([self.lifeCycleDelegate respondsToSelector:@selector(viewDidReceiveFirstLoad:)]) {
    [self.lifeCycleDelegate
        viewDidReceiveFirstLoad:self.layoutInterval + self.jsTasmAllReadyInterval];
  }
}

- (void)lynxView:(LynxView *)view didReceiveUpdatePerf:(LynxPerformance *)perf {
  [self convertLifeCycleInterval:perf];
  [self trackLynxRenderPipelineTrigger:@"page_update_perf_time"];
}

- (void)lynxViewDidFirstScreen:(LynxView *)view {
  // 2
  _firstDrawTime = [self currentTimeSince1970];
  [self trackLynxRenderPipelineTrigger:@"first_draw_time"];
  _firstScreenTime = [self currentTimeSince1970];
  if ([self.lifeCycleDelegate respondsToSelector:@selector(viewDidFirstScreen)]) {
    [self.lifeCycleDelegate viewDidFirstScreen];
  }
}

- (void)lynxViewDidPageUpdate:(LynxView *)view {
  if ([self.lifeCycleDelegate respondsToSelector:@selector(viewDidPageUpdate)]) {
    [self.lifeCycleDelegate viewDidPageUpdate];
  }
}

- (void)lynxViewDidUpdate:(LynxView *)view {
  // 5
  [self trackLynxRenderPipelineTrigger:@"page_update_time"];
  if ([self.lifeCycleDelegate respondsToSelector:@selector(viewDidUpdate)]) {
    [self.lifeCycleDelegate viewDidUpdate];
  }
}

- (void)lynxView:(LynxView *)view didRecieveError:(NSError *)error {
  NSString *errorMessage = [error.userInfo bdlynx_stringValueForKey:@"message"];
  self.errorMessage = errorMessage;
  if ([self.lifeCycleDelegate respondsToSelector:@selector(viewDidRecieveError:)]) {
    [self.lifeCycleDelegate viewDidRecieveError:error];
  }
  [self trackLynxLifeCycleTrigger:@"receive_error"
                          logType:@"hybrid_monitor"
                          service:@"hybrid_app_monitor_lynx_error"];
  if (error.code == LynxErrorCodeJavaScript) {
    [self reportJsError:errorMessage];
  } else {
    @try {
      [BDL_SERVICE_WITH_SELECTOR(BDLReportProtocol, @selector(reportException:))
          reportException:error];
    } @catch (NSException *exception) {
      NSLog(@"%@:%@", [exception name], [exception reason]);
    }
  }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)lynxView:(LynxView *)view didLoadFailedWithUrl:(NSString *)url error:(NSError *)error {
  if ([self.lifeCycleDelegate respondsToSelector:@selector(viewDidLoadFailedWithUrl:error:)]) {
    [self.lifeCycleDelegate viewDidLoadFailedWithUrl:url error:error];
  }
  NSString *errorMessage = [error.userInfo bdlynx_stringValueForKey:@"message"];
  self.errorMessage = errorMessage;
  self.originURL = url;
  [self trackLynxLifeCycleTrigger:@"load_failed"
                          logType:@"hybrid_monitor"
                          service:@"hybrid_app_monitor_lynx_exception"];
}
#pragma clang diagnostic pop

- (void)lynxViewDidChangeIntrinsicContentSize:(LynxView *)view {
  if ([self.lifeCycleDelegate respondsToSelector:@selector(viewDidChangeIntrinsicContentSize:)]) {
    [self.lifeCycleDelegate viewDidChangeIntrinsicContentSize:view.intrinsicContentSize];
  }
}

- (void)viewDidChangeIntrinsicContentSize:(LynxView *)view {
  // 3
  if (!self.isFirstScreenTracked) {
    self.isFirstScreenTracked = YES;
  }
}

- (void)lynxViewDidConstructJSRuntime:(LynxView *)view {
  if ([self.lifeCycleDelegate respondsToSelector:@selector(viewDidConstructJSRuntime)]) {
    [self.lifeCycleDelegate viewDidConstructJSRuntime];
  }
}

- (void)trackLynxRenderPipelineTrigger:(NSString *)trigger {
  [self trackLynxLifeCycleTrigger:trigger
                          logType:@"hybrid_monitor"
                          service:@"hybrid_app_monitor_lynx_timeline_event"];
}

- (void)convertLifeCycleInterval:(LynxPerformance *)performance {
  NSDictionary *performanceDict = performance.toDictionary;
  self.binaryDecodeInterval = [performanceDict bdlynx_floatValueForKey:@"tasm_binary_decode"] ?: 0;
  self.decodeToLoadInterval =
      [performanceDict bdlynx_floatValueForKey:@"tasm_end_decode_finish_load_template"] ?: 0;
  self.finishLoadTasmInterval =
      [performanceDict bdlynx_floatValueForKey:@"tasm_finish_load_template"] ?: 0;
  self.layoutInterval = [performanceDict bdlynx_floatValueForKey:@"layout"] ?: 0;
  self.renderPageInterval = [performanceDict bdlynx_floatValueForKey:@"render_page"] ?: 0;

  self.firstDrawInterval = self.finishLoadTasmInterval;
  self.firstScreenInterval = self.layoutInterval + self.finishLoadTasmInterval;
  self.pageFinishInterval =
      self.renderPageInterval ? (self.firstScreenInterval + self.firstDrawInterval) : 0;

  self.diffRootInterval = [performanceDict bdlynx_floatValueForKey:@"diff_root_create"] ?: 0;
  self.diffSameRootInterval = [performanceDict bdlynx_floatValueForKey:@"diff_same_root"] ?: 0;
  self.jsFinishLoadCoreInterval =
      [performanceDict bdlynx_floatValueForKey:@"js_finish_load_core"] ?: 0;
  self.jsFinishLoadAppInterval =
      [performanceDict bdlynx_floatValueForKey:@"js_finish_load_app"] ?: 0;
  self.jsTasmAllReadyInterval =
      [performanceDict bdlynx_floatValueForKey:@"js_and_tasm_all_ready"] ?: 0;
  self.ttiInterval = [performanceDict bdlynx_floatValueForKey:@"tti"] ?: 0;
}

- (CFTimeInterval)currentTimeSince1970 {
  return (CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970) * 1000;
}

- (void)trackLynxLifeCycleTrigger:(NSString *)trigger
                          logType:(NSString *)logType
                          service:(NSString *)service {
  NSMutableDictionary *data = [NSMutableDictionary dictionary];

  NSMutableDictionary *category = [NSMutableDictionary dictionary];
  [category setObject:@"lynx" forKey:@"type"];
  [category setObject:trigger forKey:@"trigger"];
  [category setValue:self.channel forKey:@"channel"];
  [category setValue:self.channel forKey:@"lynx_channel"];
  [category setValue:[NSString stringWithFormat:@"%@%@", self.channel, self.bundlePath]
              forKey:@"url"];
  [category setValue:self.originURL forKey:@"origin_url"];
  [category setValue:self.sessionID forKey:@"session_id"];
  if ([service isEqualToString:@"hybrid_app_monitor_lynx_exception"] ||
      [service isEqualToString:@"hybrid_app_monitor_lynx_error"]) {
    [category setValue:self.errorMessage forKey:@"reason"];
  }
  category[@"bid"] = self.reportBid;
  category[@"pid"] = self.reportPid;

  NSMutableDictionary *metrics = [NSMutableDictionary dictionary];

  if ([logType isEqualToString:@"hybrid_monitor"]) {
    [metrics
        setObject:(_startLoadTime && _pageStartTime) ? @(_startLoadTime - _pageStartTime) : @(0)
           forKey:@"lynx_load_interval"];
    [metrics setObject:@(self.binaryDecodeInterval) forKey:@"binary_decode_interval"];
    [metrics setObject:@(self.decodeToLoadInterval) forKey:@"decode_finish_interval"];
    [metrics setObject:@(self.firstDrawInterval) forKey:@"first_draw_interval"];
    [metrics setObject:@(self.firstScreenInterval) forKey:@"first_screen_interval"];
    [metrics setObject:@(self.pageFinishInterval) forKey:@"page_finish_interval"];

    [metrics setObject:@(self.binaryDecodeInterval) forKey:@"tasm_binary_decode"];
    [metrics setObject:@(self.decodeToLoadInterval) forKey:@"tasm_end_decode_finish_load_template"];
    [metrics setObject:@(self.finishLoadTasmInterval) forKey:@"tasm_finish_load_template"];
    [metrics setObject:@(self.layoutInterval) forKey:@"layout"];
    [metrics setObject:@(self.renderPageInterval) forKey:@"render_page"];
    [metrics setObject:@(self.diffRootInterval) forKey:@"diff_root_create"];
    [metrics setObject:@(self.diffSameRootInterval) forKey:@"diff_same_root"];
    [metrics setObject:@(self.jsFinishLoadCoreInterval) forKey:@"js_finish_load_core"];
    [metrics setObject:@(self.jsFinishLoadAppInterval) forKey:@"js_finish_load_app"];
    [metrics setObject:@(self.jsTasmAllReadyInterval) forKey:@"js_and_tasm_all_ready"];
    [metrics setObject:@(self.ttiInterval) forKey:@"tti"];
    if (self.perfDict) {
      [metrics addEntriesFromDictionary:self.perfDict];
    }
  }
  [metrics setObject:@([[NSDate date] timeIntervalSince1970] * 1000.0) forKey:@"event_ts"];

  NSMutableDictionary *extra = [NSMutableDictionary dictionary];
  [extra setObject:@(_startLoadTime) ?: @(0) forKey:@"StartLoadTime"];
  [extra setObject:@(_pageStartTime) ?: @(0) forKey:@"PageStartTime"];
  [extra setObject:@(_firstDrawTime) ?: @(0) forKey:@"FirstDrawTime"];
  [extra setObject:@(_firstScreenTime) ?: @(0) forKey:@"FirstScreenTime"];
  [extra setObject:@(_pageFinishTime) ?: @(0) forKey:@"PageFinishTime"];
  [data setObject:extra forKey:@"extra"];

  [data setObject:service forKey:@"service"];
  [data setObject:@0 forKey:@"status"];

  [data setObject:category forKey:@"category"];
  [data setObject:metrics forKey:@"metrics"];

  [data setObject:@{@"ts" : @([[NSDate date] timeIntervalSince1970] * 1000.0)} forKey:@"value"];
  [BDLUtils trackData:data logTypeStr:logType];
}

- (void)reportJsError:(NSString *)errorMsg {
  // Report jserror to slardar browser
  // Extract error data and repackage it in a new format
  NSData *originData = [errorMsg dataUsingEncoding:NSUTF8StringEncoding];
  NSError *originErr;
  NSDictionary *originDic = [NSJSONSerialization JSONObjectWithData:originData
                                                            options:NSJSONReadingMutableContainers
                                                              error:&originErr];
  NSString *sourceMsg;
  if (!originErr && [[originDic allKeys] containsObject:@"error"]) {
    sourceMsg = originDic[@"error"];
  } else {
    return;
  }

  NSData *jsonData = [sourceMsg dataUsingEncoding:NSUTF8StringEncoding];
  NSError *err;
  NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&err];
  if (err) {
    dic = [[NSMutableDictionary alloc] init];
    NSDictionary *stack = @{@"type" : @"INTERNAL_RUNTIME_ERROR", @"value" : errorMsg};
    NSArray *values = @[ stack ];
    NSDictionary *exception = @{@"values" : values};
    NSMutableDictionary *sentry = [[NSMutableDictionary alloc] init];
    [sentry setValue:exception forKey:@"exception"];
    [dic setValue:sentry forKey:@"sentry"];

    NSMutableDictionary *tags = [[NSMutableDictionary alloc] init];
    [tags setValue:@(YES) forKey:@"jscrash"];
    [sentry setValue:tags forKey:@"tags"];

    [dic setValue:sentry forKey:@"sentry"];
    [dic setValue:@"" forKey:@"url"];
  }

  [self modifyJsonObject:dic];
  [self sendDataToServer:dic];
}

- (void)modifyJsonObject:(NSMutableDictionary *)dic {
  NSString *pid = [dic objectForKey:@"pid"];
  if (BDLIsEmptyString(pid)) {
    [dic setValue:@"INTERNAL_ERROR" forKey:@"pid"];  // pid
  }

  [dic setValue:@"bdlynx_core" forKey:@"bid"];
  [dic setValue:@"{}" forKey:@"context"];
  [dic setValue:@"jserr" forKey:@"ev_type"];
  [dic setValue:@"" forKey:@"hostname"];
  [dic setValue:@"file://" forKey:@"protocol"];
  [dic setValue:[[NSUUID UUID] UUIDString] forKey:@"slardar_session_id"];
  [dic setValue:[BDL_SERVICE(BDLHostProtocol) deviceID] ?: @"" forKey:@"slardar_web_id"];
  [dic setValue:@(1) forKey:@"sample_rate"];

  long currentTime = (long)([[NSDate date] timeIntervalSince1970] * 1000);
  [dic setValue:@(currentTime) forKey:@"timestamp"];
  NSMutableDictionary *sentry = [dic objectForKey:@"sentry"];
  if (!sentry) {
    sentry = [[NSMutableDictionary alloc] init];
    [dic setValue:sentry forKey:@"sentry"];
  }

  NSMutableDictionary *tags = [sentry objectForKey:@"tags"];
  if (!tags) {
    tags = [[NSMutableDictionary alloc] init];
    [dic setValue:tags forKey:@"tags"];
  }
  [tags setValue:[BDL_SERVICE(BDLHostProtocol) deviceID] ?: @"" forKey:@"did"];  // did
  [tags setValue:[BDL_SERVICE(BDLHostProtocol) appID] ?: @"" forKey:@"aid"];     // appid

  NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
  NSString *appName = [infoDictionary objectForKey:@"CFBundleName"];

  [tags setValue:appName forKey:@"app_name"];  // app_name
  [tags setValue:self.channel ?: @"" forKey:@"group_id"];
  [tags setValue:@"" forKey:@"card_id"];
  [tags setValue:[BDLSDKManager lynxVersionString] forKey:@"native_lynx_sdk_version"];
  NSString *bdlynxVersion = [BDL_SERVICE(BDLLynxModuleProtocol) versionString];
  [tags setValue:bdlynxVersion forKey:@"native_bdlynx_sdk_version"];
  [tags setValue:@"ios" forKey:@"system"];
  [tags setValue:@"card" forKey:@"app_type"];
}

- (void)sendDataToServer:(NSMutableDictionary *)dic {
  if (![BDLSDKManager getSystemInfoByKey:@"SLARDAR_DOMAIN"]) {
    return;
  }
  NSString *urlPath =
      [NSString stringWithFormat:@"https://%@/log/sentry/v2/api/slardar/main/",
                                 [BDLSDKManager getSystemInfoByKey:@"SLARDAR_DOMAIN"]];

  [[TTNetworkManager shareInstance]
      requestForBinaryWithResponse:urlPath
                            params:[dic copy]
                            method:@"POST"
                  needCommonParams:NO
                 requestSerializer:[BDLynxPostDataHttpRequestSerializer class]
                responseSerializer:nil
                        autoResume:YES
                          callback:^(NSError *error, id obj, TTHttpResponse *response) {
                            if (error) {
                              [BDLUtils error:error.localizedDescription ?: @"error"];
                            }
                          }];
}

@end

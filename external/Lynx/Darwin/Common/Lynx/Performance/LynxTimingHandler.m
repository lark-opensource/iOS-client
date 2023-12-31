//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxTimingHandler.h"
#import "LynxContext.h"
#import "LynxExtraTiming.h"
#import "LynxService.h"
#import "LynxTraceEvent.h"
#import "LynxTraceEventWrapper.h"

#define SETUP_PREFIX @"setup_"
#define UPDATE_PREFIX @"update_"
#define SSR_SUFFIX @"_ssr"

#define SETUP_TIMESTAMP_COUNT 21
#define UPDATE_TIMESTAMP_COUNT 10
#define TIMING_ACTUAL_FMP @"__lynx_timing_actual_fmp"
#define DRAW_END @"draw_end"
#define LOAD_APP_END @"load_app_end"

#define LAYOUT_START @"layout_start"
#define LAYOUT_END @"layout_end"
#define UI_OPERATION_FLUSH_START @"ui_operation_flush_start"
#define UI_OPERATION_FLUSH_END @"ui_operation_flush_end"

#define SSR_TIMING @"ssr_render_page_timing"

@interface LynxTimingHandler ()

@property(nonatomic, assign) NSInteger threadStrategy;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *metrics;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *setupTiming;
// updateTimings is used to mark update-timing info.
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSNumber *> *> *updateTimings;
// updateTimingsToBeReported is used to report timing info which has timing updateFlag set by FE,
// and the timing info is ready to be reported.
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSNumber *> *>
        *updateTimingsToBeReported;
// used to store all of the attribute timingFlags to be reported
@property(nonatomic, strong) NSMutableSet<NSString *> *attributeTimingFlags;
@property(nonatomic, strong) NSMutableDictionary *ssrSetupInfo;

@end

@implementation LynxTimingHandler

- (instancetype)initWithThreadStrategy:(NSInteger)threadStrategy {
  self = [super init];
  if (self) {
    _threadStrategy = threadStrategy;
    _setupTiming = [NSMutableDictionary dictionary];
    _updateTimings = [NSMutableDictionary dictionary];
    _updateTimingsToBeReported = [NSMutableDictionary dictionary];
    _metrics = [NSMutableDictionary dictionary];
    _extraTiming = [[LynxExtraTiming alloc] init];
    _attributeTimingFlags = [NSMutableSet set];
  }
  return self;
}

#pragma mark - markTiming / setTiming

- (void)markTiming:(NSString *)key updateFlag:(NSString *_Nullable)flag {
  if ([NSThread isMainThread]) {
    LYNX_TRACE_INSTANT(LYNX_TRACE_CATEGORY_WRAPPER,
                       (flag ? [key stringByAppendingFormat:@".%@", flag] : key));
    uint64_t timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    [self setTiming:timestamp key:key updateFlag:flag];
  } else {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf markTiming:key updateFlag:flag];
    });
  }
}

- (void)setTiming:(uint64_t)timestamp
              key:(NSString *_Nonnull)key
       updateFlag:(NSString *_Nullable)updateFlag {
  if ([NSThread isMainThread]) {
    [self __setTiming:timestamp key:key updateFlag:updateFlag];
  } else {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf __setTiming:timestamp key:key updateFlag:updateFlag];
    });
  }
}

- (BOOL)isSetupTiming:(NSString *_Nonnull)key {
  return [key hasPrefix:SETUP_PREFIX];
}

- (BOOL)isUpdateTiming:(NSString *_Nonnull)key updateFlag:(NSString *_Nullable)updateFlag {
  // Update Timings must have a flag.
  return updateFlag && [key hasPrefix:UPDATE_PREFIX];
}

- (void)__setTiming:(uint64_t)timestamp
                key:(NSString *_Nonnull)key
         updateFlag:(NSString *_Nullable)updateFlag {
  if ([self isSetupTiming:key]) {
    [self processSetupTiming:timestamp key:key];
  } else if ([self isUpdateTiming:key updateFlag:updateFlag]) {
    [self processUpdateTiming:timestamp key:key updateFlag:updateFlag];
  } else {
    [self setExtraTimingIfNeeded:timestamp key:key];
  }
  if ([key hasSuffix:DRAW_END]) {
    [self dispatchAttributeTimingIfNeeded:timestamp];
  }
}

- (void)setExtraTimingIfNeeded:(uint64_t)timestamp key:(NSString *)key {
  if ([key isEqualToString:OC_PREPARE_TEMPLATE_START] &&
      self.extraTiming.prepareTemplateStart == 0) {
    self.extraTiming.prepareTemplateStart = timestamp;
  } else if ([key isEqualToString:OC_PREPARE_TEMPLATE_END] &&
             self.extraTiming.prepareTemplateEnd == 0) {
    self.extraTiming.prepareTemplateEnd = timestamp;
  }
}

- (void)setExtraTiming:(LynxExtraTiming *)extraTiming {
  if (!extraTiming) {
    return;
  }
  if ([NSThread isMainThread]) {
    [self __setExtraTiming:extraTiming];
  } else {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf __setExtraTiming:extraTiming];
    });
  }
}

- (void)__setExtraTiming:(LynxExtraTiming *)extraTiming {
  if (extraTiming) {
    _extraTiming.openTime = extraTiming.openTime;
    _extraTiming.containerInitStart = extraTiming.containerInitStart;
    _extraTiming.containerInitEnd = extraTiming.containerInitEnd;
    if (extraTiming.prepareTemplateStart > 0) {
      _extraTiming.prepareTemplateStart = extraTiming.prepareTemplateStart;
    }
    if (extraTiming.prepareTemplateEnd > 0) {
      _extraTiming.prepareTemplateEnd = extraTiming.prepareTemplateEnd;
    }
  }
}

- (void)addAttributeTimingFlag:(NSString *)flag {
  if ([self.updateTimingsToBeReported objectForKey:flag]) {
    // the attributeTimingFlag has been reported before, just return.
    return;
  }
  LYNX_TRACE_INSTANT(LYNX_TRACE_CATEGORY_WRAPPER,
                     ([NSString stringWithFormat:@"Attribute timingFlag: %@ is added", flag]));
  if ([self.attributeTimingFlags count] == 0) {
    // We need to mark DRAW_END this time since we have an attributeTimingFlag.
    // To avoid duplicate marking, we only mark when the size of attributeTimingFlags is 0.
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf markTiming:OC_UPDATE_DRAW_END updateFlag:nil];
    });
  }
  [self.attributeTimingFlags addObject:flag];
}

#pragma mark - calculate helper

- (void)calculateBySetup {
  [self calculateSsrMetricsIfNeeded];

  if (self.extraTiming.prepareTemplateStart > 0) {
    uint64_t fcp = [self setupDrawEnd] - self.extraTiming.prepareTemplateStart;
    uint64_t tti =
        MAX([self setupLoadAppEnd], [self setupDrawEnd]) - self.extraTiming.prepareTemplateStart;
    [self.metrics setValue:@(fcp) forKey:@"fcp"];
    [self.metrics setValue:@(tti) forKey:@"tti"];
  }

  uint64_t lynx_fcp = [self setupDrawEnd] - [self setupLoadTemplateStart];
  uint64_t lynx_tti =
      MAX([self setupDrawEnd], [self setupLoadAppEnd]) - [self setupLoadTemplateStart];
  [self.metrics setValue:@(lynx_fcp) forKey:@"lynx_fcp"];
  [self.metrics setValue:@(lynx_tti) forKey:@"lynx_tti"];
}

- (void)calculateByUpdate:(NSString *)reportUpdateFlag {
  if ([reportUpdateFlag isEqualToString:TIMING_ACTUAL_FMP]) {
    [self calculateByActualFMPUpdate];
  }
}

- (uint64_t)setupDrawEnd {
  return [[self.setupTiming objectForKey:DRAW_END] unsignedLongLongValue];
}

- (uint64_t)setupLoadAppEnd {
  return [[self.setupTiming objectForKey:LOAD_APP_END] unsignedLongLongValue];
}

- (uint64_t)setupLoadTemplateStart {
  return [[self.setupTiming objectForKey:@"load_template_start"] unsignedLongLongValue];
}

- (void)calculateByActualFMPUpdate {
  uint64_t drawEnd = [self actualFMPDrawEnd];
  if (drawEnd <= 0) {
    return;
  }
  if (self.extraTiming.prepareTemplateStart > 0) {
    uint64_t actualFMP = drawEnd - self.extraTiming.prepareTemplateStart;
    [self.metrics setValue:@(actualFMP) forKey:@"actual_fmp"];
  }
  uint64_t lynxActualFMP = drawEnd - [self setupLoadTemplateStart];
  [self.metrics setValue:@(lynxActualFMP) forKey:@"lynx_actual_fmp"];
}

- (uint64_t)actualFMPDrawEnd {
  NSDictionary<NSString *, NSNumber *> *timing =
      [self.updateTimingsToBeReported objectForKey:TIMING_ACTUAL_FMP];
  return [[timing objectForKey:DRAW_END] unsignedLongLongValue];
}

#pragma mark - setup

- (void)processSetupTiming:(uint64_t)timestamp key:(NSString *)key {
  NSString *skey = [key stringByReplacingOccurrencesOfString:SETUP_PREFIX withString:@""];

  [self setSsrRenderPageTimingIfNeeded:timestamp key:skey];

  if (![skey hasSuffix:SSR_SUFFIX]) {
    [self.setupTiming setValue:@(timestamp) forKey:skey];
  }

  [self dispatchSetupTimingIfNeeded];
}

- (BOOL)isSetupReady {
  // The order of arrival of timestamps under multi-threading is uncertain,
  // so need to wait for all timestamps to arrive before calling back.
  // If you add a timestamp, please pay attention to the SETUP_TIMESTAMP_COUNT。
  return self.setupTiming.count == SETUP_TIMESTAMP_COUNT
         // when enableJSRuntime if false, DRAW_END means the first screen has shown
         // and only the status of tasm-thread needs to be reported
         || (!self.enableJSRuntime && [self.setupTiming objectForKey:DRAW_END]);
}

- (void)dispatchSetupTimingIfNeeded {
  if ([self isSetupReady]) {
    [self dispatchSetupTiming];
    [self dispatchAttributeTimingIfNeeded:[[self.setupTiming objectForKey:DRAW_END]
                                              unsignedLongLongValue]];
  }
}

- (void)dispatchSetupTiming {
  [self calculateBySetup];
  LynxView *lynxView = [self.lynxContext getLynxView];
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxViewLifecycle.onTimingSetup");
  [[lynxView getLifecycleDispatcher] lynxView:lynxView onSetup:[self timingInfo]];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
  [self.lynxContext sendGlobalEvent:@"lynx.performance.timing.onSetup"
                         withParams:@[ [self timingInfo] ]];
  [lynxView triggerTrailReport];
}

#pragma mark - update

- (void)processUpdateTiming:(uint64_t)timestamp
                        key:(NSString *)key
                 updateFlag:(NSString *_Nullable)updateFlag {
  NSString *ukey = [key stringByReplacingOccurrencesOfString:UPDATE_PREFIX withString:@""];
  NSMutableDictionary<NSString *, NSNumber *> *updateTiming =
      [self.updateTimings objectForKey:updateFlag];
  // The timestamp of the same timing flag mustn't be set repeatedly.
  if ([updateTiming objectForKey:ukey]) {
    return;
  }
  if (!updateTiming) {
    updateTiming = [NSMutableDictionary dictionary];
    [self.updateTimings setValue:updateTiming forKey:updateFlag];
  }
  [updateTiming setValue:@(timestamp) forKey:ukey];
  [self dispatchUpdateTimingIfNeeded:updateTiming updateFlag:updateFlag];
  return;
}

- (BOOL)isUpdateReady:(NSMutableDictionary<NSString *, NSNumber *> *)updateTiming {
  // The order of arrival of timestamps under multi-threading is uncertain,
  // so need to wait for all timestamps to arrive before calling back.
  // If you add a timestamp, please pay attention to the SETUP_TIMESTAMP_COUNT.
  return (updateTiming.count == UPDATE_TIMESTAMP_COUNT);
}

- (void)dispatchUpdateTimingIfNeeded:(NSMutableDictionary<NSString *, NSNumber *> *)updateTiming
                          updateFlag:(NSString *)updateFlag {
  if ([self isUpdateReady:updateTiming]) {
    [self dispatchUpdateTiming:updateTiming reportUpdateFlag:updateFlag];
    [self clearUpdateTimingAfterDispatch:updateFlag];
  }
}

- (void)dispatchUpdateTiming:(NSDictionary<NSString *, NSNumber *> *)updateTiming
            reportUpdateFlag:(NSString *)reportUpdateFlag {
  // The timestamp of the same timing flag mustn't be reported repeatedly.
  if ([self.updateTimingsToBeReported objectForKey:reportUpdateFlag]) {
    return;
  }
  [self.updateTimingsToBeReported setValue:updateTiming.copy forKey:reportUpdateFlag];
  [self calculateByUpdate:reportUpdateFlag];
  NSDictionary *info = [self timingInfo];
  NSMutableDictionary *currentUpdateTimingInfo = [NSMutableDictionary dictionary];
  [currentUpdateTimingInfo setDictionary:info];
  [currentUpdateTimingInfo setValue:@{reportUpdateFlag : updateTiming.copy}
                             forKey:@"update_timings"];

  LynxView *lynxView = [self.lynxContext getLynxView];
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, [@"LynxViewLifecycle.onTimingUpdate."
                                                      stringByAppendingString:reportUpdateFlag])
  [[lynxView getLifecycleDispatcher] lynxView:lynxView
                                     onUpdate:info
                                       timing:@{reportUpdateFlag : updateTiming.copy}];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);

  [self.lynxContext sendGlobalEvent:@"lynx.performance.timing.onUpdate"
                         withParams:@[ currentUpdateTimingInfo ]];
  [lynxView triggerTrailReport];
}

- (NSMutableDictionary<NSString *, NSNumber *> *)updateTimingForFlag:(NSString *)updateFlag {
  NSMutableDictionary<NSString *, NSNumber *> *updateTiming =
      [self.updateTimings objectForKey:updateFlag];
  if (!updateTiming) {
    updateTiming = [NSMutableDictionary dictionary];
    [self.updateTimings setValue:updateTiming forKey:updateFlag];
  }
  return updateTiming;
}

#pragma mark - attributeTimingFlags
- (void)dispatchAttributeTimingIfNeeded:(uint64_t)timestamp {
  if ([self.attributeTimingFlags count] == 0) {
    return;
  }
  if (![self isSetupReady]) {
    // attributeTiming should be dispatched after setupTiming has been dispatched.
    // If setupTiming is not ready, attribute updateTiming info is meaningless,
    // because it only contains the endpoint Draw_end, but not the starting point.
    return;
  }
  // Each time we meet DRAW_END timing is mark, we would check attributeTimingFlags.
  NSMutableSet<NSString *> *attributeTimingFlags = [self.attributeTimingFlags copy];
  [self.attributeTimingFlags removeAllObjects];
  NSDictionary<NSString *, NSNumber *> *updateTiming = @{DRAW_END : @(timestamp)};
  // Iter attributeTimingFlags and dispatch attributeTiming.
  for (NSString *flag in attributeTimingFlags) {
    [self dispatchUpdateTiming:updateTiming reportUpdateFlag:flag];
  }
}

#pragma mark - timingInfo getter

- (NSDictionary *)timingInfo {
  NSDictionary *dic = @{
    @"thread_strategy" : @(self.threadStrategy),
    @"metrics" : self.metrics.copy,
    @"setup_timing" : self.setupTiming.copy,
    @"update_timings" : self.updateTimingsToBeReported.copy,
    @"extra_timing" : [self.extraTiming toDictionary],
    @"url" : self.url ? self.url : @""
  };

  if ([self isSsr]) {
    NSMutableDictionary *ssrDic = [dic mutableCopy];
    [ssrDic addEntriesFromDictionary:_ssrSetupInfo];
    // remove meaningless values
    [ssrDic removeObjectForKey:@"metrics"];
    return ssrDic;
  }

  return dic;
}

#pragma mark - clear

- (void)clearUpdateTimingAfterDispatch:(NSString *)updateFlag {
  [self.updateTimings removeObjectForKey:updateFlag];
}

- (void)clearAllTimingInfo {
  if ([NSThread isMainThread]) {
    [self __clearAllTimingInfo];
  } else {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf __clearAllTimingInfo];
    });
  }
}

- (void)__clearAllTimingInfo {
  [_setupTiming removeAllObjects];
  [_updateTimings removeAllObjects];
  [_updateTimingsToBeReported removeAllObjects];
  [_metrics removeAllObjects];
  [_attributeTimingFlags removeAllObjects];

  _ssrSetupInfo = nil;
}

#pragma mark - SSR

- (void)setSsrTimingInfo:(NSDictionary *)info {
  if ([NSThread isMainThread]) {
    [self __setSsrTimingInfo:info];
  } else {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf __setSsrTimingInfo:info];
    });
  }
}

- (void)__setSsrTimingInfo:(NSDictionary *)info {
  _ssrSetupInfo = [NSMutableDictionary new];
  if (info) {
    _ssrSetupInfo[@"ssr_extra_info"] = info.copy;
  }
  _ssrSetupInfo[SSR_TIMING] = [NSMutableDictionary new];
}

- (BOOL)isSsr {
  return (_ssrSetupInfo != nil);
}

- (void)setSsrRenderPageTimingIfNeeded:(uint64_t)timestamp key:(NSString *_Nonnull)key {
  if (![self isSsr]) {
    return;
  }
  if ([key hasSuffix:SSR_SUFFIX]) {
    [_ssrSetupInfo[SSR_TIMING] setValue:@(timestamp) forKey:key];
    return;
  }
  if ([self shouldReuseTiming:key]) {
    [_ssrSetupInfo[SSR_TIMING] setValue:@(timestamp)
                                 forKey:[key stringByAppendingString:SSR_SUFFIX]];
  }
}

- (BOOL)shouldReuseTiming:(NSString *)key {
  return [key isEqualToString:LAYOUT_START] || [key isEqualToString:LAYOUT_END] ||
         [key isEqualToString:UI_OPERATION_FLUSH_START] ||
         [key isEqualToString:UI_OPERATION_FLUSH_END] || [key isEqualToString:DRAW_END];
}

- (void)calculateSsrMetricsIfNeeded {
  if (![self isSsr]) {
    return;
  }

  NSMutableDictionary *ssrMetrics = [NSMutableDictionary new];

  uint64_t renderPageStart =
      [_ssrSetupInfo[SSR_TIMING][@"render_page_start_ssr"] unsignedLongLongValue];
  uint64_t drawEndSsr = [_ssrSetupInfo[SSR_TIMING][@"draw_end_ssr"] unsignedLongLongValue];

  // tti: MAX(draw_end, load_app_end)  - render_page_start_ssr
  uint64_t lynxTtiSsr = MAX([self setupDrawEnd], [self setupLoadAppEnd]) - renderPageStart;
  [ssrMetrics setValue:@(lynxTtiSsr) forKey:@"lynx_tti_ssr"];

  // fcp: draw_end_ssr - render_page_start_ssr
  uint64_t lynxFcpSsr = drawEndSsr - renderPageStart;
  [ssrMetrics setValue:@(lynxFcpSsr) forKey:@"lynx_fcp_ssr"];

  _ssrSetupInfo[@"ssr_metrics"] = ssrMetrics.copy;
}

@end

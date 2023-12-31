// Copyright 2019 The Lynx Authors. All rights reserved.
#import "LynxView.h"
#import "CoreJsLoaderManager.h"
#import "JSModule+Internal.h"
#import "LynxDefines.h"
#import "LynxDevtool.h"
#import "LynxEnv.h"
#import "LynxFontFaceManager.h"
#import "LynxGenericReportInfo.h"
#import "LynxGetUIResultDarwin.h"
#import "LynxHeroTransition.h"
#import "LynxLazyRegister.h"
#import "LynxLifecycleDispatcher.h"
#import "LynxLifecycleTracker.h"
#import "LynxLog.h"
#import "LynxPerformanceUtils.h"
#import "LynxTemplateData+Converter.h"
#import "LynxTemplateRender+Internal.h"
#import "LynxTemplateRender.h"
#import "LynxTemplateRenderDelegate.h"
#import "LynxTheme.h"
#import "LynxThreadManager.h"
#import "LynxTraceEvent.h"
#import "LynxUI.h"
#import "LynxView+Internal.h"
#import "LynxViewInternal.h"
#import "LynxWeakProxy.h"

#import "LynxService.h"
#define RUN_RENDER_SAFELY(method)              \
  do {                                         \
    if (_templateRender != nil) {              \
      method                                   \
    } else {                                   \
      LLogWarn(@"LynxTemplateRender is nil."); \
    }                                          \
  } while (0)

using namespace lynx::tasm;
using namespace lynx::lepus;

#pragma mark - LynxViewBuilder
@implementation LynxViewBuilder {
  LynxThreadStrategyForRender _threadStrategy;
  NSMutableDictionary<NSString*, id<LynxResourceProvider>>* _providers;
  NSMutableDictionary<NSString*, LynxAliasFontInfo*>* _builderRegistedAliasFontMap;
}

- (id)init {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxViewBuilder init")
  self = [super init];
  if (self) {
    [LynxLazyRegister loadLynxInitTask];
    self.enableAutoExpose = YES;
    self.fontScale = 1.0;
    self.enableTextNonContiguousLayout = NO;
    self.enableLayoutOnly = [LynxEnv.sharedInstance getEnableLayoutOnly];
    self.debuggable = false;
    _providers = [NSMutableDictionary dictionary];
    _builderRegistedAliasFontMap = [NSMutableDictionary dictionary];
  }
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
  return self;
}

- (LynxThreadStrategyForRender)getThreadStrategyForRender {
  return _threadStrategy;
}

- (void)setThreadStrategyForRender:(LynxThreadStrategyForRender)threadStrategy {
  switch (threadStrategy) {
    case LynxThreadStrategyForRenderAllOnUI:
    case LynxThreadStrategyForRenderPartOnLayout:
      _threadStrategy = LynxThreadStrategyForRenderAllOnUI;
      break;
    case LynxThreadStrategyForRenderMostOnTASM:
      _threadStrategy = LynxThreadStrategyForRenderMostOnTASM;
      break;
    case LynxThreadStrategyForRenderMultiThreads:
      _threadStrategy = LynxThreadStrategyForRenderMultiThreads;
      break;
    default:
      LLogError(@"invalid value used for thread rendering strategy, please use enum "
                @"'LynxThreadStrategyForRender' defined in LynxView.mm");
      _threadStrategy = LynxThreadStrategyForRenderAllOnUI;
      break;
  }
}

- (void)addLynxResourceProvider:(NSString*)resType provider:(id<LynxResourceProvider>)provider {
  [_providers setValue:provider forKey:resType];
}

- (NSDictionary*)getLynxResourceProviders {
  return _providers;
}

- (void)registerFont:(UIFont*)font forName:(NSString*)name {
  if ([name length] == 0) {
    return;
  }

  LynxAliasFontInfo* info = [_builderRegistedAliasFontMap objectForKey:name];
  if (info == nil) {
    if (font != nil) {
      info = [LynxAliasFontInfo new];
      info.font = font;
      [_builderRegistedAliasFontMap setObject:info forKey:name];
    }
  } else {
    info.font = font;
    if ([info isEmpty]) {
      [_builderRegistedAliasFontMap removeObjectForKey:name];
    }
  }
}

- (void)registerFamilyName:(NSString*)fontFamilyName withAliasName:(NSString*)aliasName {
  if ([aliasName length] == 0) {
    return;
  }

  LynxAliasFontInfo* info = [_builderRegistedAliasFontMap objectForKey:aliasName];
  if (info == nil) {
    if (fontFamilyName != nil) {
      info = [LynxAliasFontInfo new];
      info.name = fontFamilyName;
      [_builderRegistedAliasFontMap setObject:info forKey:aliasName];
    }
  } else {
    info.name = fontFamilyName;
    if ([info isEmpty]) {
      [_builderRegistedAliasFontMap removeObjectForKey:aliasName];
    }
  }
}

- (NSDictionary*)getBuilderRegistedAliasFontMap {
  return _builderRegistedAliasFontMap;
}

@end

#pragma mark - LynxView

@interface LynxView () <LynxTemplateRenderDelegate>

@property(nonatomic, strong) LynxLifecycleDispatcher* lifecycleDispatcher;
@property(nonatomic, strong) LynxLifecycleTracker* lifecycleTracker;

@property(nonatomic, assign) BOOL attached;

@end

@implementation LynxView {
  LynxWeakProxy* _clientWeakProxy;
  BOOL _enableTextNonContiguousLayout;
  BOOL _enableLayoutOnly;

  CGSize _intrinsicContentSize;

  BOOL _dispatchingIntrinsicContentSizeChange;
  BOOL _enableSyncFlush;
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
  NSString* description =
      [NSString stringWithFormat:@"%s in class %@ is unavailable", sel_getName(_cmd), self.class];
  NSAssert(false, description);
#pragma clang diagnostic pop
  return nil;
}

- (void)onLongPress {
  RUN_RENDER_SAFELY([_templateRender onLongPress];);
}

- (instancetype)init {
  return [self initWithBuilderBlock:nil];
}

- (instancetype)initWithFrame:(CGRect)frame {
  return [self initWithBuilderBlock:^(LynxViewBuilder* builder) {
    builder.frame = frame;
  }];
}

- (instancetype)initWithBuilderBlock:(void (^)(NS_NOESCAPE LynxViewBuilder*))block {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxView initWithBuilderBlock")
  [LynxLazyRegister loadLynxInitTask];
  self = [super initWithFrame:CGRectZero];
  self.accessibilityLabel = @"lynxview";
  _dispatchingIntrinsicContentSizeChange = NO;
  if (self) {
    [self initLifecycleDispatcher];
  }
  _templateRender = [[LynxTemplateRender alloc] initWithBuilderBlock:block lynxView:self];
  _lifecycleTracker.genericReportInfo = [_templateRender genericReportInfo];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
  return self;
}

- (instancetype)initWithoutRender {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxView initWithoutRender");
  [LynxLazyRegister loadLynxInitTask];
  self = [super initWithFrame:CGRectZero];
  self.accessibilityLabel = @"lynxview";
  [self initLifecycleDispatcher];

  return self;
}

- (LynxLifecycleDispatcher*)getLifecycleDispatcher {
  return _lifecycleDispatcher;
};

- (void)requestLayoutWhenSafepointEnable {
}

- (void)updateScreenMetricsWithWidth:(CGFloat)width height:(CGFloat)height {
  [_templateRender updateScreenMetricsWithWidth:width height:height];
}

/**
 UICTContentSizeCategoryXS                     0.824
 UICTContentSizeCategoryS                      0.882
 UICTContentSizeCategoryM                      0.942
 UICTContentSizeCategoryL                      1.0
 UICTContentSizeCategoryXL                     1.1118
 UICTContentSizeCategoryXXL                    1.235
 UICTContentSizeCategoryXXXL                   1.353
 UICTContentSizeCategoryAccessibilityM         1.647
 UICTContentSizeCategoryAccessibilityL         1.941
 UICTContentSizeCategoryAccessibilityXL        2.353
 UICTContentSizeCategoryAccessibilityXXL       2.764
 UICTContentSizeCategoryAccessibilityXXXL      3.118
 */
- (void)updateFontScale:(CGFloat)scale {
  if (_templateRender != nil) {
    [_templateRender updateFontScale:scale];
  }
}

- (void)initLifecycleDispatcher {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxView initLifecycleDispatcher")
  _lifecycleDispatcher = [[LynxLifecycleDispatcher alloc] init];
  [_lifecycleDispatcher addLifecycleClient:[LynxEnv sharedInstance].lifecycleDispatcher];
  _lifecycleTracker = [[LynxLifecycleTracker alloc] init];
  [_lifecycleDispatcher addLifecycleClient:_lifecycleTracker];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (void)loadTemplate:(NSData*)tem withURL:(NSString*)url {
  [self loadTemplate:tem withURL:url initData:nil];
}

- (void)loadTemplateFromURL:(NSString*)url {
  [self loadTemplateFromURL:url initData:nil];
}

- (void)loadTemplate:(NSData*)tem withURL:(NSString*)url initData:(LynxTemplateData*)data {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxView LoadTemplate")
  [self trackInfoLoadTemplateUrl:url];
  if (_dispatchingIntrinsicContentSizeChange) {
    LLogInfo(@"Warning!!!! you possibly call loadTemplate inside of layoutDidFinish call stack");
  }
  RUN_RENDER_SAFELY([_templateRender loadTemplate:tem withURL:url initData:data];);
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (void)loadTemplateBundle:(id)bundle withURL:(NSString*)url initData:(LynxTemplateData*)data {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxView LoadTemplateBundle")
  [self trackInfoLoadTemplateUrl:url];
  if (_dispatchingIntrinsicContentSizeChange) {
    LLogInfo(
        @"Warning!!!! you possibly call loadTemplateBundle inside of layoutDidFinish call stack");
  }
  RUN_RENDER_SAFELY([_templateRender loadTemplateBundle:bundle withURL:url initData:data];);
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (void)loadSSRData:(nonnull NSData*)tem
            withURL:(nonnull NSString*)url
           initData:(LynxTemplateData*)data {
  LLogInfo(@"LynxView %p: start loadSSRData with %@", self, url);
  RUN_RENDER_SAFELY([_templateRender loadSSRData:tem withURL:url initData:data];);
}

- (void)loadSSRDataFromURL:(NSString*)url initData:(LynxTemplateData*)data {
  LLogInfo(@"LynxView %p: start loadSSRDataFromURL with %@", self, url);
  RUN_RENDER_SAFELY([_templateRender loadSSRDataFromURL:url initData:data];);
}

- (void)ssrHydrate:(nonnull NSData*)tem
           withURL:(nonnull NSString*)url
          initData:(nullable LynxTemplateData*)data {
  LLogInfo(@"LynxView %p: start ssrHydrate with %@", self, url);
  RUN_RENDER_SAFELY([_templateRender ssrHydrate:tem withURL:url initData:data];);
}

- (void)ssrHydrateFromURL:(NSString*)url initData:(nullable LynxTemplateData*)data {
  LLogInfo(@"LynxView %p: start ssrHydrateFromURL with %@", self, url);
  RUN_RENDER_SAFELY([_templateRender ssrHydrateFromURL:url initData:data];);
}

- (void)dispatchError:(LynxError*)error {
  if (error.code == LynxErrorCodeLoadTemplate) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self.lifecycleDispatcher lynxView:self didLoadFailedWithUrl:self.url error:error];
#pragma clang diagnostic pop
  }
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxViewLifecycle didRecieveError");
  [self.lifecycleDispatcher lynxView:self didRecieveError:error];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (void)loadTemplateFromURL:(NSString*)url initData:(LynxTemplateData*)data {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxView LoadTemplate")
  [self trackInfoLoadTemplateUrl:url];
  if (_dispatchingIntrinsicContentSizeChange) {
    LLogInfo(
        @"Warning!!!! you possibly call loadTemplateFromURL inside of layoutDidFinish call stack");
  }
  RUN_RENDER_SAFELY([_templateRender loadTemplateFromURL:url initData:data];);
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (void)hotModuleReplace:(NSString*)message withParams:(NSDictionary*)params {
  LLogInfo(@"LynxView %p: start hotModuleReplace with %@", self, params[@"url"]);
  if (_dispatchingIntrinsicContentSizeChange) {
    LLogInfo(
        @"Warning!!!! you possibly call hotModuleReplace inside of layoutDidFinish call stack");
  }
  RUN_RENDER_SAFELY([_templateRender hotModuleReplace:message withParams:params];);
}

- (LynxUI*)findUIByIndex:(int)index {
  if (_templateRender != nil) {
    return [_templateRender findUIByIndex:index];
  } else {
    return nil;
  }
}

- (void)setGlobalPropsWithDictionary:(NSDictionary<NSString*, id>*)data {
  RUN_RENDER_SAFELY([_templateRender updateGlobalPropsWithDictionary:data];);
}

- (void)setGlobalPropsWithTemplateData:(LynxTemplateData*)data {
  RUN_RENDER_SAFELY([_templateRender updateGlobalPropsWithTemplateData:data];);
}

- (void)updateGlobalPropsWithDictionary:(NSDictionary<NSString*, id>*)data {
  RUN_RENDER_SAFELY([_templateRender updateGlobalPropsWithDictionary:data];);
}

- (void)updateGlobalPropsWithTemplateData:(LynxTemplateData*)data {
  RUN_RENDER_SAFELY([_templateRender updateGlobalPropsWithTemplateData:data];);
}

- (void)updateDataWithString:(NSString*)data {
  [self updateDataWithString:data processorName:nil];
}

- (void)updateDataWithString:(NSString*)data processorName:(NSString*)name {
  RUN_RENDER_SAFELY([_templateRender updateDataWithString:data processorName:name];);
}

- (void)updateDataWithDictionary:(NSDictionary<NSString*, id>*)data {
  [self updateDataWithDictionary:data processorName:nil];
}

- (void)updateDataWithDictionary:(NSDictionary<NSString*, id>*)data processorName:(NSString*)name {
  RUN_RENDER_SAFELY([_templateRender updateDataWithDictionary:data processorName:name];);
}

- (void)updateDataWithTemplateData:(LynxTemplateData*)data {
  RUN_RENDER_SAFELY([_templateRender updateDataWithTemplateData:data];);
}

- (void)updateDataWithTemplateData:(nullable LynxTemplateData*)data
            updateFinishedCallback:(void (^)(void))callback {
  RUN_RENDER_SAFELY([_templateRender updateDataWithTemplateData:data
                                         updateFinishedCallback:callback];);
}

- (void)resetDataWithTemplateData:(LynxTemplateData*)data {
  RUN_RENDER_SAFELY([_templateRender resetDataWithTemplateData:data];);
}

- (void)reloadTemplateWithTemplateData:(LynxTemplateData*)data {
  [self reloadTemplateWithTemplateData:data globalProps:nil];
}

- (void)reloadTemplateWithTemplateData:(nonnull LynxTemplateData*)data
                           globalProps:(nullable LynxTemplateData*)globalProps {
  RUN_RENDER_SAFELY([_templateRender reloadTemplateWithTemplateData:data globalProps:globalProps];);
}

- (NSDictionary*)getCurrentData {
  if (_templateRender != nil) {
    return [_templateRender getCurrentData];
  } else {
    return nil;
  }
}

- (NSDictionary*)getPageDataByKey:(NSArray*)keys {
  if ([keys count] == 0) {
    LLogInfo(@"getPageDataByKey called with empty keys.");
    return nil;
  }

  if (_templateRender != nil) {
    return [_templateRender getPageDataByKey:keys];
  } else {
    return nil;
  }
}

- (void)onEnterForeground {
  _attached = YES;
  RUN_RENDER_SAFELY([_templateRender onEnterForeground];);
}

- (void)onEnterBackground {
  _attached = NO;
  RUN_RENDER_SAFELY([_templateRender onEnterBackground];);
}

- (void)sendGlobalEvent:(nonnull NSString*)name withParams:(nullable NSArray*)params {
  if ([_templateRender enableAirStrictMode]) {
    // In Air mode, send global event by triggering lepus closure
    [self sendGlobalEventToLepus:name withParams:params];
  } else {
    RUN_RENDER_SAFELY([_templateRender sendGlobalEvent:name withParams:params];);
  }
}

- (void)sendGlobalEventToLepus:(nonnull NSString*)name withParams:(nullable NSArray*)params {
  RUN_RENDER_SAFELY([_templateRender sendGlobalEventToLepus:name withParams:params];);
}

- (void)triggerEventBus:(nonnull NSString*)name withParams:(nullable NSArray*)params {
  if (name.length) {
    RUN_RENDER_SAFELY([_templateRender triggerEventBus:name withParams:params];);
  }
}

- (void)setFrame:(CGRect)frame {
  // TODO should update viewport here?
  [super setFrame:frame];
}

- (void)layoutSubviews {
  if (_enableSyncFlush && [self.subviews count] > 0) {
    [self syncFlush];
  }
  [super layoutSubviews];
  RUN_RENDER_SAFELY([_templateRender triggerLayoutInTick];);
}

- (void)invalidateIntrinsicContentSize {
  [self triggerLayout];
  [super invalidateIntrinsicContentSize];
}

- (void)triggerLayout {
  RUN_RENDER_SAFELY([_templateRender triggerLayout];);
}

- (void)syncFlush {
  [_templateRender syncFlush];
}

- (void)setEnableRadonCompatible:(BOOL)enableRadonCompatible
    __attribute__((deprecated("Radon diff mode can't be close after lynx 2.3."))) {
}

- (void)setEnableLayoutOnly:(BOOL)enableLayoutOnly {
  _enableLayoutOnly = enableLayoutOnly;
}

- (void)setEnableSyncFlush:(BOOL)enableSyncFlush {
  _enableSyncFlush = enableSyncFlush;
}

- (void)setEnableTextNonContiguousLayout:(BOOL)enableTextNonContiguousLayout {
  _enableTextNonContiguousLayout = enableTextNonContiguousLayout;
}

- (BOOL)enableTextNonContiguousLayout {
  return _enableTextNonContiguousLayout || [self.templateRender enableTextNonContiguousLayout];
}

- (CGSize)intrinsicContentSize {
  return _intrinsicContentSize;
}

- (void)setIntrinsicContentSize:(CGSize)size {
  _intrinsicContentSize = size;

  _dispatchingIntrinsicContentSizeChange = YES;
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER,
                     @"LynxViewLifecycle DidChangeIntrinsicContentSize")
  [_lifecycleDispatcher lynxViewDidChangeIntrinsicContentSize:self];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
  _dispatchingIntrinsicContentSizeChange = NO;
}

- (void)updateViewport {
  RUN_RENDER_SAFELY([_templateRender updateViewport];);
}

- (void)updateViewportWithPreferredLayoutWidth:(CGFloat)preferredLayoutWidth
                         preferredLayoutHeight:(CGFloat)preferredLayoutHeight {
  [self updateViewportWithPreferredLayoutWidth:preferredLayoutWidth
                         preferredLayoutHeight:preferredLayoutHeight
                                    needLayout:YES];
}

- (void)updateViewportWithPreferredLayoutWidth:(CGFloat)preferredLayoutWidth
                         preferredLayoutHeight:(CGFloat)preferredLayoutHeight
                                    needLayout:(BOOL)needLayout {
  [self setPreferredLayoutWidth:preferredLayoutWidth];
  [self setPreferredLayoutHeight:preferredLayoutHeight];
  RUN_RENDER_SAFELY([_templateRender updateViewport:needLayout];);
}

- (id<LynxViewClient>)client {
  if (_clientWeakProxy) {
    return _clientWeakProxy.target;
  }
  return nil;
}

- (void)setClient:(id<LynxViewClient>)client {
  LynxWeakProxy* clientWeakProxy = [LynxWeakProxy proxyWithTarget:client];

  if ([client conformsToProtocol:@protocol(LynxViewClient)] ||
      [client conformsToProtocol:@protocol(LynxViewLifecycle)]) {
    if (_clientWeakProxy) {
      [_lifecycleDispatcher removeLifecycleClient:(id<LynxViewLifecycle>)_clientWeakProxy];
    }
    [_lifecycleDispatcher addLifecycleClient:(id<LynxViewLifecycle>)clientWeakProxy];
  }

  _clientWeakProxy = clientWeakProxy;

  self.imageFetcher = _clientWeakProxy.target;
  self.resourceFetcher = _clientWeakProxy.target;
  self.scrollListener = _clientWeakProxy.target;
}

- (void)setImageFetcher:(id<LynxImageFetcher>)imageFetcher {
  _imageFetcher = imageFetcher;
  RUN_RENDER_SAFELY([_templateRender setImageFetcherInUIOwner:imageFetcher];);
}

- (void)setResourceFetcher:(id<LynxResourceFetcher>)resourceFetcher {
  _resourceFetcher = resourceFetcher;
  RUN_RENDER_SAFELY([_templateRender setResourceFetcherInUIOwner:resourceFetcher];);
}

- (void)setScrollListener:(id<LynxScrollListener>)scrollListener {
  _scrollListener = scrollListener;
  RUN_RENDER_SAFELY([_templateRender setScrollListener:scrollListener];);
}

- (void)reset {
  // clear view
  LLogInfo(@"LynxView %p:reset", self);
  [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
  [[self.layer sublayers] makeObjectsPerformSelector:@selector(removeFromSuperlayer)];

  RUN_RENDER_SAFELY([_templateRender reset];);
}

// This method is about to be removed, do not call this method.
// TODO(limeng.amer): lynx 2.10 removes this method.
- (void)dispatchViewDidStartLoading {
  NSString* url;
  if (_templateRender != nil) {
    url = [_templateRender url];
  } else {
    url = nil;
  }
  LLogInfo(@"LynxView %p: StartLoading %@ ", self, url);
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxViewLifecycle didStartLoading");
  [_lifecycleDispatcher lynxViewDidStartLoading:self];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
}

- (void)willMoveToWindow:(UIWindow*)newWindow {
  [super willMoveToWindow:newWindow];

  RUN_RENDER_SAFELY([_templateRender willMoveToWindow:newWindow];);
}

- (void)didMoveToWindow {
  [super didMoveToWindow];

  RUN_RENDER_SAFELY([_templateRender didMoveToWindow:self.window == nil];);
}

// TODO(songshourui.null): opt me
// In TCProject's UITextView case, when user chose "SelectAll" or "Select", the keyboard
// will be dismissed. Since in some cases, UITextEffectsWindow hitest function is not
// called by iOS, and LynxView hittest function will be called such that
// [self endEditing:true] will be called. To workaround this bad case, when
// LynxView hittest function is called, call this tapOnUICalloutBarButton function to
// determine whether to dismiss the keyboard.
- (BOOL)tapOnUICalloutBarButton:(CGPoint)point withEvent:(UIEvent*)event {
  NSArray<UIWindow*>* windows = [UIApplication sharedApplication].windows;
  BOOL res = NO;
  if (windows == nil || [windows count] == 0) {
    return res;
  }
  for (UIWindow* window in windows) {
    NSString* windowName = NSStringFromClass([window class]);
    if (window != nil && windowName != nil && windowName.length == 19 &&
        [windowName hasPrefix:@"UITextEff"] && [windowName hasSuffix:@"ectsWindow"] &&
        ![window isEqual:self.window]) {
      CGPoint newPoint = [window convertPoint:point fromView:self];
      UIView* target = [window hitTest:newPoint withEvent:event];
      NSString* targetName = NSStringFromClass([target class]);
      if (target != nil && targetName != nil && targetName.length == 18 &&
          [targetName hasPrefix:@"UICallo"] && [targetName hasSuffix:@"utBarButton"]) {
        res = YES;
        break;
      } else if (target != nil && targetName != nil && targetName.length == 11 &&
                 [targetName hasPrefix:@"UISta"] && [targetName hasSuffix:@"ckView"]) {
        res = YES;
        break;
      } else if (target != nil && targetName != nil && targetName.length == 26 &&
                 [targetName hasPrefix:@"_UIVisualEff"] &&
                 [targetName hasSuffix:@"ectContentView"]) {
        res = YES;
        break;
      }
    }
  }
  return res;
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
  LLogInfo(@"Lynxview %p: hitTest with point.x: %f, point.y: %f", self, point.x, point.y);

  id<LynxEventTarget> touchTarget = nil;
  RUN_RENDER_SAFELY(touchTarget = [_templateRender hitTestInEventHandler:point withEvent:event];);
  UIView* view = [super hitTest:point withEvent:event];

  if ([self needEndEditing:view] &&
      ![[[[view superview] superview] superview] isKindOfClass:[UITextView class]] &&
      ![touchTarget ignoreFocus] && ![self tapOnUICalloutBarButton:point withEvent:event]) {
    // To free our touch handler from being blocked, dispatch endEditing asynchronously.
    __weak LynxView* weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf endEditing:true];
    });
  }
  // If target eventThrough, return nil to let event through LynxView.
  if ([touchTarget eventThrough]) {
    return nil;
  } else {
    return view;
  }
}

- (BOOL)needEndEditing:(UIView*)view {
  if ([view isKindOfClass:[UITextField class]] || [view isKindOfClass:[UITextView class]]) {
    return NO;
  }

  // In UITextView case, when user chose "SelectAll", the view hierarchy will be like this:
  // UITextRangeView -> UITextSelectionView -> _UITextContainerView -> BDXLynxTextView
  // However, UITextRangeView is a private class which is not accessible, so we can only
  // use [[[superview]superview]superview] as judge condition to avoid keyboard being folded
  // so that user can adjust cursor positions.
  if ([[[[view superview] superview] superview] isKindOfClass:[UITextView class]]) {
    return NO;
  }

  // In iOS16 & UITextField has the same issue mentioned before, the view hierarchy will be like
  // this: UITextRangeView -> UITextSelectionView -> _UITextLayoutCanvasView -> UIFieldEditor ->
  // BDXLynxTextField so use [[[[superview] superview] superview] superview] to handle this
  // situation.
  if (@available(iOS 16.0, *)) {
    if ([[[[[view superview] superview] superview] superview] isKindOfClass:[UITextField class]]) {
      return NO;
    }
  }

  return YES;
}

- (void)clearForDestroy {
  LLogInfo(@"Lynxview %p: clearForDestroy", self);
  if (_dispatchingIntrinsicContentSizeChange) {
    LLogInfo(@"Warning!!!! you possibly call clearForDestroy inside of layoutDidFinish call stack");
  }

  // forbidden clearForDestroy not on ui thread
  if (![NSThread isMainThread]) {
    NSString* stack =
        [[[NSThread callStackSymbols] valueForKey:@"description"] componentsJoinedByString:@"\n"];
    NSString* errMsg = [NSString
        stringWithFormat:@"LynxView %p clearForDestroy not on ui thread, thread:%@, stack:%@", self,
                         [NSThread currentThread], stack];
    if (_templateRender) {
      [_templateRender onErrorOccurred:LynxErrorCodeLynxViewDestroyNotOnUi message:errMsg];
    } else {
      [self dispatchError:[LynxError lynxErrorWithCode:LynxErrorCodeLynxViewDestroyNotOnUi
                                               message:errMsg]];
    }
    LLogError(@"LynxView %p clearForDestroy not on ui thread, thread:%@", self,
              [NSThread currentThread]);
  }

  if (_templateRender) {
    LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxViewLifecycle didReportComponentInfo")
    [_lifecycleDispatcher lynxView:self didReportComponentInfo:_templateRender.componentSet];
    LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
  }
  // need set nil here, else call _templateRender after clearForDestroy
  // will cause crash in LynxShell
  _templateRender = nil;
}

- (void)dealloc {
  [self clearForDestroy];
}

- (nullable UIView*)viewWithName:(nonnull NSString*)name {
  if (_templateRender != nil) {
    return [_templateRender viewWithName:name];
  } else {
    return nil;
  }
}

- (nullable UIView*)findViewWithName:(nonnull NSString*)name {
  if (_templateRender) {
    return [_templateRender findViewWithName:name];
  } else {
    return nil;
  }
}

- (nullable LynxUI*)uiWithName:(nonnull NSString*)name {
  if (_templateRender != nil) {
    return [_templateRender uiWithName:name];
  } else {
    return nil;
  }
}

- (nullable UIView*)viewWithIdSelector:(nonnull NSString*)idSelector {
  if (_templateRender != nil) {
    return [_templateRender viewWithIdSelector:idSelector];
  } else {
    return nil;
  }
}

- (nullable NSArray<UIView*>*)viewsWithA11yID:(NSString*)a11yID {
  if (_templateRender != nil) {
    return [_templateRender viewsWithA11yID:a11yID];
  } else {
    return nil;
  }
}

- (nullable LynxUI*)uiWithIdSelector:(nonnull NSString*)idSelector {
  if (_templateRender != nil) {
    return [_templateRender uiWithIdSelector:idSelector];
  } else {
    return nil;
  }
}

- (NSString*)cardVersion {
  if (_templateRender != nil) {
    return [_templateRender cardVersion];
  } else {
    return nil;
  }
}

- (nonnull LynxConfigInfo*)lynxConfigInfo {
  if (_templateRender != nil) {
    return _templateRender.lynxConfigInfo;
  } else {
    return [[LynxConfigInfo alloc] init];
  }
}

- (LynxPerformance*)forceGetPerf {
  return nil;
}

- (nullable JSModule*)getJSModule:(nonnull NSString*)name {
  if (_templateRender != nil) {
    return [_templateRender getJSModule:name];
  } else {
    return nil;
  }
}

- (nullable NSNumber*)getLynxRuntimeId {
  if (_templateRender != nil) {
    return [_templateRender getLynxRuntimeId];
  }
  return nil;
}

- (void)pauseRootLayoutAnimation {
  RUN_RENDER_SAFELY([_templateRender pauseRootLayoutAnimation];);
}

- (void)resumeRootLayoutAnimation {
  RUN_RENDER_SAFELY([_templateRender resumeRootLayoutAnimation];);
}

- (void)addLifecycleClient:(id<LynxViewLifecycle>)lifecycleClient {
  if (lifecycleClient) {
    [_lifecycleDispatcher addLifecycleClient:lifecycleClient];
  }
}

- (void)setTheme:(LynxTheme*)theme {
  RUN_RENDER_SAFELY([_templateRender setTheme:theme];);
}

- (nullable LynxTheme*)theme {
  if (_templateRender != nil) {
    return [_templateRender theme];
  } else {
    return nil;
  }
}

- (void)setEnableAsyncDisplay:(BOOL)enableAsyncDisplay {
  RUN_RENDER_SAFELY([_templateRender setEnableAsyncDisplay:enableAsyncDisplay];);
}

- (BOOL)enableAsyncDisplay {
  if (_templateRender != nil) {
    return [_templateRender enableAsyncDisplay];
  } else {
    return FALSE;
  }
}

- (BOOL)enableTextLayerRender {
  return [_templateRender enableTextLayerRender];
}

- (void)resetAnimation {
  RUN_RENDER_SAFELY([_templateRender resetAnimation];);
}
- (void)restartAnimation {
  RUN_RENDER_SAFELY([_templateRender restartAnimation];);
}

// get and set of layout property
- (LynxViewSizeMode)layoutHeightMode {
  if (_templateRender != nil) {
    return [_templateRender layoutHeightMode];
  } else {
    return LynxViewSizeModeExact;
  }
}

- (void)setLayoutHeightMode:(LynxViewSizeMode)layoutHeightMode {
  RUN_RENDER_SAFELY(_templateRender.layoutHeightMode = layoutHeightMode;);
}

- (LynxViewSizeMode)layoutWidthMode {
  if (_templateRender != nil) {
    return [_templateRender layoutWidthMode];
  } else {
    return LynxViewSizeModeExact;
  }
}

- (void)setLayoutWidthMode:(LynxViewSizeMode)layoutWidthMode {
  RUN_RENDER_SAFELY(_templateRender.layoutWidthMode = layoutWidthMode;);
}

// return "0" as default value
- (CGFloat)preferredMaxLayoutWidth {
  if (_templateRender != nil) {
    return [_templateRender preferredMaxLayoutWidth];
  } else {
    return 0;
  }
}

- (void)setPreferredMaxLayoutWidth:(CGFloat)preferredMaxLayoutWidth {
  RUN_RENDER_SAFELY(_templateRender.preferredMaxLayoutWidth = preferredMaxLayoutWidth;);
}

- (CGFloat)preferredMaxLayoutHeight {
  if (_templateRender != nil) {
    return [_templateRender preferredMaxLayoutHeight];
  } else {
    return 0;
  }
}

- (void)setPreferredMaxLayoutHeight:(CGFloat)preferredMaxLayoutHeight {
  RUN_RENDER_SAFELY(_templateRender.preferredMaxLayoutHeight = preferredMaxLayoutHeight;);
}

- (CGFloat)preferredLayoutWidth {
  if (_templateRender != nil) {
    return [_templateRender preferredLayoutWidth];
  } else {
    return 0;
  }
}

- (void)setPreferredLayoutWidth:(CGFloat)preferredLayoutWidth {
  RUN_RENDER_SAFELY(_templateRender.preferredLayoutWidth = preferredLayoutWidth;);
}

- (CGFloat)preferredLayoutHeight {
  if (_templateRender != nil) {
    return [_templateRender preferredLayoutHeight];
  } else {
    return 0;
  }
}

- (void)setPreferredLayoutHeight:(CGFloat)preferredLayoutHeight {
  RUN_RENDER_SAFELY(_templateRender.preferredLayoutHeight = preferredLayoutHeight;);
}

- (nullable NSString*)url {
  if (_templateRender != nil) {
    return [_templateRender url];
  } else {
    return nil;
  }
}

- (id<LynxBaseInspectorOwner>)baseInspectorOwner {
  if (_templateRender && _templateRender.devTool) {
    return _templateRender.devTool.owner;
  }
  return nil;
}

- (void)detachRender {
  _templateRender = nil;
}

- (void)attachTemplateRender:(LynxTemplateRender* _Nullable)templateRender {
  if (_templateRender) {
    LLogWarn(@"LynxView %p:LynxTemplateRender is already attached", self);
    return;
  }
  _templateRender = templateRender;
  [_templateRender attachLynxView:self];
};

- (void)processLayout:(NSData*)tem withURL:(NSString*)url initData:(LynxTemplateData*)data {
  LLogInfo(@"LynxView %p: start processLayout with %@", self, url);
  RUN_RENDER_SAFELY([_templateRender processLayout:tem withURL:url initData:data];);
}

- (void)processLayoutWithSSRData:(nonnull NSData*)tem
                         withURL:(nonnull NSString*)url
                        initData:(nullable LynxTemplateData*)data {
  LLogInfo(@"LynxView %p: start processLayoutWithSSRData with %@", self, url);
  RUN_RENDER_SAFELY([_templateRender processLayoutWithSSRData:tem withURL:url initData:data];);
}

- (void)processRender {
  if (![LynxThreadManager isMainQueue]) {
    __weak LynxView* weakSelf = self;
    [LynxThreadManager runBlockInMainQueue:^{
      [weakSelf processRender];
    }];
    return;
  }

  BOOL isAttachSuccess = [_templateRender processRender:self];
  if (!isAttachSuccess) {
    LLogWarn(@"LynxView processRender error. url:%@", _templateRender.url);
    return;
  }
  [self updateViewport];
}

- (void)setNeedPendingUIOperation:(BOOL)needPendingUIOperation {
  [_templateRender setNeedPendingUIOperation:needPendingUIOperation];
}

- (void)startLynxRuntime {
  [_templateRender startLynxRuntime];
}

- (BOOL)isLayoutFinish {
  return [_templateRender isLayoutFinish];
}

- (void)resetViewAndLayer {
  // clear view
  [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
  [[self.layer sublayers] makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
}

- (NSDictionary*)getAllJsSource {
  if (_templateRender != nil) {
    return [_templateRender getAllJsSource];
  } else {
    return nil;
  }
}

- (float)rootWidth {
  if (_templateRender != nil) {
    return [_templateRender rootWidth];
  } else {
    return 0;
  }
}

- (float)rootHeight {
  if (_templateRender != nil) {
    return [_templateRender rootHeight];
  } else {
    return 0;
  }
}

- (LynxThreadStrategyForRender)getThreadStrategyForRender {
  return [_templateRender getThreadStrategyForRender];
}

- (LynxContext*)getLynxContext {
  return [_templateRender getLynxContext];
}

- (void)setExtraTiming:(LynxExtraTiming*)timing {
  [self.templateRender setExtraTiming:timing];
}

- (NSDictionary*)getAllTimingInfo {
  return [_templateRender getAllTimingInfo];
}

- (void)setExtraTimingWithDictionary:(NSDictionary*)timing {
  LynxExtraTiming* timingInfo = [[LynxExtraTiming alloc] init];
  timingInfo.openTime = [[timing objectForKey:@"open_time"] unsignedLongLongValue];
  timingInfo.containerInitStart =
      [[timing objectForKey:@"container_init_start"] unsignedLongLongValue];
  timingInfo.containerInitEnd = [[timing objectForKey:@"container_init_end"] unsignedLongLongValue];
  timingInfo.prepareTemplateStart =
      [[timing objectForKey:@"prepare_template_start"] unsignedLongLongValue];
  timingInfo.prepareTemplateEnd =
      [[timing objectForKey:@"prepare_template_end"] unsignedLongLongValue];
  [self.templateRender setExtraTiming:timingInfo];
}

- (void)triggerTrailReport {
  [_templateRender triggerTrailReport];
}

- (void)runOnTasmThread:(dispatch_block_t)task {
  [_templateRender runOnTasmThread:task];
}

- (id<LynxKryptonHelper>)getKryptonHelper {
  if (_templateRender != nil) {
    return _templateRender.kryptonHelper;
  } else {
    return nil;
  }
}

#pragma mark - LynxTemplateRenderDelegate

- (void)templateRenderOnDataUpdated:(LynxTemplateRender*)templateRender {
  LLog(@"Lynxview Lifecycle OnDataUpdated in %p", self);
  [_lifecycleDispatcher lynxViewDidUpdate:self];
}

- (void)templateRender:(LynxTemplateRender*)templateRender onPageChanged:(BOOL)isFirstScreen {
  LLog(@"Lynxview Lifecycle onPageChanged in %p", self);
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (strongSelf) {
      if (isFirstScreen) {
        TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxViewLifecycle lynxViewDidFirstScreen");
        [strongSelf.lifecycleDispatcher lynxViewDidFirstScreen:strongSelf];
      } else {
        TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxViewLifecycle lynxViewDidPageUpdate");
        [strongSelf.lifecycleDispatcher lynxViewDidPageUpdate:strongSelf];
      }
    }
  });
}

- (void)templateRenderOnTasmFinishByNative:(LynxTemplateRender*)templateRender {
  [_lifecycleDispatcher lynxViewOnTasmFinishByNative:self];
  [LynxService(LynxServiceTrackEventProtocol)
      kProbe_SpecialEventDirectWithName:@"load_finish"
                                 format:@"lynx url: %@"
                                   data:self.templateRender.url];
}

- (void)templateRender:(LynxTemplateRender*)templateRender
      onTemplateLoaded:(NSString*)url
            configInfo:(LynxConfigInfo*)configInfo {
  [[LynxHeroTransition sharedInstance] executeEnterTransition:self];
  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "LynxViewLifecycle::didLoadFinished");
  [_lifecycleDispatcher lynxView:self didLoadFinishedWithUrl:url];
  [_lifecycleDispatcher lynxView:self didLoadFinishedWithConfigInfo:configInfo];
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
}

- (void)templateRenderOnRuntimeReady:(LynxTemplateRender*)templateRender {
  [_lifecycleDispatcher lynxViewDidConstructJSRuntime:self];
}

- (void)templateRender:(LynxTemplateRender*)templateRender
    onReceiveFirstLoadPerf:(LynxPerformance*)perf {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxViewLifecycle::didReceiveFirstLoadPerf");
  [_lifecycleDispatcher lynxView:self didReceiveFirstLoadPerf:perf];
}

- (void)templateRender:(LynxTemplateRender*)templateRender onUpdatePerf:(LynxPerformance*)perf {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxViewLifecycle::didReceiveUpdatePerf");
  [_lifecycleDispatcher lynxView:self didReceiveUpdatePerf:perf];
}

- (void)templateRender:(LynxTemplateRender*)templateRender
    onReceiveDynamicComponentPerf:(NSDictionary*)perf {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxViewLifecycle::didReceiveDynamicComponentPerf");
  [_lifecycleDispatcher lynxView:self didReceiveDynamicComponentPerf:perf];
}

- (NSString*)templateRender:(LynxTemplateRender*)templateRender
    translatedResourceWithId:(NSString*)resId
                    themeKey:(NSString*)key {
  return [self.resourceFetcher translatedResourceWithId:resId
                                                  theme:self.theme
                                               themeKey:key
                                                   view:self];
}

- (void)templateRender:(LynxTemplateRender*)templateRender
       didInvokeMethod:(NSString*)method
              inModule:(NSString*)module
             errorCode:(int)code {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxViewLifecycle didInvokeMethod");
  [_lifecycleDispatcher lynxView:self didInvokeMethod:method inModule:module errorCode:code];
}

- (void)templateRender:(LynxTemplateRender*)templateRender onErrorOccurred:(LynxError*)error {
  if (error.code == LynxErrorCodeLoadTemplate) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_lifecycleDispatcher lynxView:self didLoadFailedWithUrl:self.url error:error];
#pragma clang diagnostic pop
  }
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxViewLifecycle didRecieveError");
  [_lifecycleDispatcher lynxView:self didRecieveError:error];
}

- (void)templateRenderOnResetViewAndLayer:(LynxTemplateRender*)templateRender {
  [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
  [[self.layer sublayers] makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
}

- (void)templateRenderOnTemplateStartLoading:(LynxTemplateRender*)templateRender {
  LLogInfo(@"LynxView %p: StartLoading %@ ", self, templateRender.url ?: @"");
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxViewLifecycle didStartLoading");
  [_lifecycleDispatcher lynxViewDidStartLoading:self];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
}

- (void)templateRenderOnFirstScreen:(LynxTemplateRender*)templateRender {
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (strongSelf) {
      TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxViewLifecycle lynxViewDidFirstScreen");
      [strongSelf.lifecycleDispatcher lynxViewDidFirstScreen:strongSelf];
    }
  });
}

- (void)templateRenderOnPageUpdate:(LynxTemplateRender*)templateRender {
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (strongSelf) {
      TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxViewLifecycle lynxViewDidPageUpdate");
      [strongSelf.lifecycleDispatcher lynxViewDidPageUpdate:strongSelf];
    }
  });
}

- (void)templateRenderOnDetach:(LynxTemplateRender*)templateRender {
  [self detachRender];
}

- (void)templateRender:(LynxTemplateRender*)templateRender onCallJSBFinished:(NSDictionary*)info {
  [_lifecycleDispatcher lynxView:self onCallJSBFinished:info];
}

- (void)templateRender:(LynxTemplateRender*)templateRender onJSBInvoked:(NSDictionary*)info {
  [_lifecycleDispatcher lynxView:self onJSBInvoked:info];
}

- (void)templateRenderSetLayoutOption:(LynxTemplateRender*)templateRender {
  [self setEnableTextNonContiguousLayout:_enableTextNonContiguousLayout];
  [self setEnableLayoutOnly:_enableLayoutOnly];
}

- (void)templateRenderRequestNeedsLayout:(LynxTemplateRender*)templateRender {
  [self setNeedsLayout];
}

- (void)templateRenderOnTransitionUnregister:(LynxTemplateRender*)templateRender {
  [[LynxHeroTransition sharedInstance] unregisterLynxView:self];
}

- (void)templateRender:(LynxTemplateRender*)templateRender onLynxEvent:(LynxEventDetail*)event {
  [_lifecycleDispatcher onLynxEvent:event];
}

- (void)preloadDynamicComponents:(nonnull NSArray*)urls {
  LLogInfo(@"LynxView %p: preload dynamic components: %@", self,
           [urls componentsJoinedByString:@", "]);
  if ([urls count] == 0) {
    return;
  }
  RUN_RENDER_SAFELY([_templateRender preloadDynamicComponents:urls];);
}

#pragma mark - track
- (void)trackInfoLoadTemplateUrl:(NSString*)url {
  [LynxService(LynxServiceTrackEventProtocol) kProbe_SpecialEventDirectWithName:@"load_template"
                                                                         format:@"lynx url: %@"
                                                                           data:url];
}

@end

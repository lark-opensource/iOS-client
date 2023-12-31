

// Copyright 2020 The Lynx Authors. All rights reserved.
// Created by Young on 2020/7/28.

#import "LynxTemplateRender.h"
#import "CoreJsLoaderManager.h"
#import "LepusApiActorManager.h"
#import "LynxAccessibilityModule.h"
#import "LynxConfig+Internal.h"
#import "LynxContext+Internal.h"
#import "LynxDevtool+Internal.h"
#import "LynxDevtool.h"
#import "LynxEnv.h"
#import "LynxError.h"
#import "LynxEventEmitter.h"
#import "LynxEventHandler+Internal.h"
#import "LynxExposureModule.h"
#import "LynxFontFaceManager.h"
#import "LynxGetUIResultDarwin.h"
#import "LynxHeroTransition.h"
#import "LynxIntersectionObserverModule.h"
#include "LynxKeyboardEventDispatcher.h"
#import "LynxKryptonHelper.h"
#import "LynxLayoutTick.h"
#import "LynxLifecycleDispatcher.h"
#import "LynxLog.h"
#import "LynxResourceModule.h"
#import "LynxSSRHelper.h"
#import "LynxSetModule.h"
#import "LynxShadowNode.h"
#import "LynxShadowNodeOwner.h"
#import "LynxTemplateBundle+Converter.h"
#import "LynxTemplateBundle.h"
#import "LynxTemplateData+Converter.h"
#import "LynxTemplateRender+Internal.h"
#import "LynxTemplateRenderDelegate.h"
#import "LynxTheme.h"
#import "LynxTouchHandler+Internal.h"
#import "LynxUIContext+Internal.h"
#import "LynxUIExposure+Internal.h"
#import "LynxUIIntersectionObserver+Internal.h"
#import "LynxUILayoutTick.h"
#import "LynxUIMethodModule.h"
#import "LynxUIOwner.h"
#import "LynxVersion.h"
#import "LynxView+Internal.h"
#import "LynxViewClient.h"
#import "LynxWeakProxy.h"
#import "PaintingContextProxy.h"
#import "TemplateRenderCallbackProtocol.h"
#include "base/debug/backtrace.h"
#include "base/iOS/lynx_env_darwin.h"
#include "base/threading/task_runner_manufactor.h"
#include "lepus/json_parser.h"
#import "shell/ios/native_facade_darwin.h"
#include "shell/lynx_engine.h"
#include "shell/lynx_shell.h"
#include "starlight/layout/layout_global.h"
#include "tasm/config.h"
#include "tasm/dynamic_component/ios/dynamic_component_loader_darwin.h"
#include "tasm/generator/version.h"
#include "tasm/lynx_env_config.h"
#include "tasm/lynx_get_ui_result.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/react/element_manager.h"
#include "tasm/react/ios/layout_context_darwin.h"
#include "tasm/react/ios/lepus_value_converter.h"
#include "tasm/template_assembler.h"

#include "LynxProviderRegistry.h"
#import "LynxServiceAppLogProtocol.h"
#import "LynxTraceEvent.h"
#import "LynxTraceEventWrapper.h"
#include "config/config.h"
#import "jsbridge/ios/piper/resource_loader_darwin.h"
#import "jsbridge/ios/piper/webassembly_bridge.h"
#import "shell/ios/external_source_loader_darwin.h"
#import "shell/ios/js_proxy_darwin.h"
#include "shell/ios/vsync_monitor_darwin.h"
#include "shell/module_delegate_impl.h"
#include "tasm/lynx_trace_event.h"

#include "LynxConvertUtils.h"
#import "LynxGenericReportInfo.h"
#import "LynxPerformanceUtils.h"
#import "LynxService.h"
#import "LynxTimingHandler.h"
#import "LynxTraceEvent.h"
#include "base/closure.h"
#include "tasm/lynx_trace_event.h"

#if __ENABLE_LYNX_NET__
#import "LynxNetworkModule.h"
#endif

#if ENABLE_AIR
#include "tasm/air/bridge/ios/air_module_handler_darwin.h"
#endif

// DO NOT DELETE, OTHERWISE POD_BINARY WILL PUNISH YOU!!!   ~ :)
// BINARY_KEEP_SOURCE_FILE

/*the list on iOS will be implemented with UICollectionView when lynx version higher than
 * kMinSupportedMultiColumnListVersion*/

@interface LynxTemplateRender () <TemplateRenderCallbackProtocol> {
  BOOL _enableAsyncDisplayFromNative;
  BOOL _enableImageDownsampling;
  BOOL _enableTextNonContiguousLayout;
  BOOL _enableLayoutOnly;
}

@property(nonatomic, strong) NSMutableDictionary* extra;

@property(nonatomic) LynxProviderRegistry* providerRegistry;
@property(nonatomic) uint64_t initialMemory;
@property(nonatomic) uint64_t loadedMemory;

@property(nonatomic, strong) LepusApiActorManager* lepusApiActorManager;
@property(nonatomic, weak) id<LynxTemplateRenderDelegate> delegate;
@property(nonatomic, weak) LynxView* lynxView;

@property(nonatomic, strong) LynxSSRHelper* lynxSSRHelper;

- (void)dispatchError:(LynxError*)error;
- (void)markDirty;
@end

using lynx::tasm::HmrData;

@implementation LynxTemplateRender {
  BOOL _hasStartedLoad;
  BOOL _enableAirStrictMode;
  BOOL _enableLayoutSafepoint;
  BOOL _isAsyncRender;
  BOOL _enableAutoExpose;
  BOOL _needPendingUIOperation;
  BOOL _enablePendingJSTaskOnLayout;
  BOOL _enablePreUpdateData;
  BOOL _enableMultiAsyncThread;
  LynxConfig* _config;
  LynxContext* _context;
  LynxGroup* _group;
  LynxUILayoutTick* _uilayoutTick;
  LynxShadowNodeOwner* _shadowNodeOwner;
  LynxEventHandler* _eventHandler;
  LynxEventEmitter* _eventEmitter;
  LynxKeyboardEventDispatcher* _keyboardEventDispatcher;
  LynxThreadStrategyForRender _threadStrategyForRendering;
  LynxUIIntersectionObserverManager* _intersectionObserverManager;

  CGFloat _fontScale;
  CGSize _intrinsicContentSize;
  std::unique_ptr<lynx::shell::LynxShell> shell_;
  PaintingContextProxy* _paintingContextProxy;

  LynxTheme* _localTheme;
  LynxTemplateData* _globalProps;

  std::weak_ptr<lynx::piper::ModuleManagerDarwin> module_manager_;
  std::shared_ptr<lynx::tasm::PageConfig> pageConfig_;
}

@synthesize layoutWidthMode = _layoutWidthMode;
@synthesize layoutHeightMode = _layoutHeightMode;
@synthesize preferredMaxLayoutWidth = _preferredMaxLayoutWidth;
@synthesize preferredMaxLayoutHeight = _preferredMaxLayoutHeight;
@synthesize preferredLayoutWidth = _preferredLayoutWidth;
@synthesize preferredLayoutHeight = _preferredLayoutHeight;
@synthesize frameOfLynxView = _frameOfLynxView;
@synthesize isDestroyed = _isDestroyed;
@synthesize hasRendered = _hasRendered;
@synthesize url = _url;
@synthesize enableJSRuntime = _enableJSRuntime;
@synthesize devTool = _devTool;
@synthesize timingHandler = _timingHandler;
@synthesize lepusModulesClasses_ = _lepusModulesClasses_;

LYNX_NOT_IMPLEMENTED(-(instancetype)initWithCoder : (NSCoder*)aDecoder)

- (void)onErrorOccurred:(NSInteger)code message:(NSString*)errMessage {
  // only the first error will show and dispatch
  if (errMessage) {
    NSMutableDictionary* json = [NSMutableDictionary new];
    [json setValue:_url forKey:@"url"];
    [json setValue:errMessage forKey:@"error"];
    [json setValue:[LynxVersion versionString] forKey:@"sdk"];
    [json setValue:[self cardVersion] forKey:@"card_version"];

    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:json
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (jsonData) {
      NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
      [self dispatchError:[LynxError lynxErrorWithCode:code message:jsonString]];
      LLogError(@"LynxTemplateRender onErrorOccurred message: %@ in %p", jsonString, self);
    }
    [_devTool showErrorMessage:errMessage withCode:code];
  }
}

// issue: #1510
- (void)didInvokeMethod:(NSString*)method inModule:(NSString*)module errorCode:(int32_t)code {
  if (module && method) {
    if (_delegate) {
      // LynxViewLifecycle:willInokveMethod:inModule: is an optional method.
      // Client defined method may throw exception, which will make all module methods not work
      @try {
        [_delegate templateRender:self didInvokeMethod:method inModule:module errorCode:code];
      } @catch (NSException* exception) {
        [self onErrorOccurred:LynxErrorCodeModuleFuncCallException
                  sourceError:[LynxError
                                  lynxErrorWithCode:LynxErrorCodeModuleFuncCallException
                                            message:[NSString
                                                        stringWithFormat:
                                                            @"LynxLifecycle, didInvokeMethod:%@, "
                                                            @"inModule:%@ threw an exception.",
                                                            method, module]]];
      }
    }
  }
}

- (void)onErrorOccurred:(NSInteger)code sourceError:(NSError*)source {
  if (source) {
    std::string errorMessage = [[source localizedDescription] UTF8String];
    [self onErrorOccurred:code
                  message:[NSString
                              stringWithCString:lynx::base::debug::GetBacktraceInfo(errorMessage)
                                                    .c_str()
                                       encoding:NSUTF8StringEncoding]];

    [_lynxSSRHelper onErrorOccurred:code sourceError:source];
  }
}

- (void)onLongPress {
  [_devTool handleLongPress];
}

- (instancetype)initWithBuilderBlock:(void (^)(NS_NOESCAPE LynxViewBuilder*))block
                            lynxView:(LynxView*)lynxView {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxTemplateRender initWithBuilderBlock");
  if (self = [super init]) {
    _initStartTiming = [[NSDate date] timeIntervalSince1970] * 1000;
    LynxViewBuilder* builder = [LynxViewBuilder new];
    [builder setThreadStrategyForRender:LynxThreadStrategyForRenderAllOnUI];
    builder.enableJSRuntime = YES;
    builder.frame = CGRectZero;
    builder.screenSize = CGSizeZero;
    if (block) {
      TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxTemplateRender init CustomBuilder");
      block(builder);
    }
#if __ENABLE_LYNX_NET__
    [builder.config registerModule:LynxNetworkModule.class];
#endif
    CGSize screenSize;
    if (!CGSizeEqualToSize(builder.screenSize, CGSizeZero)) {
      screenSize = builder.screenSize;
    } else {
      screenSize = [UIScreen mainScreen].bounds.size;
    }
    _enableAirStrictMode = builder.enableAirStrictMode;
    // enable js default yes
    _enableJSRuntime = _enableAirStrictMode ? NO : builder.enableJSRuntime;
    _lepusModulesClasses_ = [[NSMutableDictionary alloc] init];
    _extra = [[NSMutableDictionary alloc] init];
    _needPendingUIOperation = builder.enableUIOperationQueue;
    _lepusApiActorManager = [[LepusApiActorManager alloc] init];
    _enablePendingJSTaskOnLayout = builder.enablePendingJSTaskOnLayout;
    _enableMultiAsyncThread = builder.enableMultiAsyncThread;
    // First prepare env
    [self prepareEnvWidthScreenSize:screenSize enableAsyncCreate:builder.enableAsyncCreateRender];

    if (lynxView != nil) {
      _lynxView = lynxView;
      _delegate = (id<LynxTemplateRenderDelegate>)lynxView;
      lynxView.clipsToBounds = YES;
      [lynxView setEnableTextNonContiguousLayout:[builder enableTextNonContiguousLayout]];
      [lynxView setEnableLayoutOnly:[LynxEnv.sharedInstance getEnableLayoutOnly]];
      [lynxView setEnableSyncFlush:[builder enableSyncFlush]];
    }
    _devTool = [[LynxDevtool alloc] initWithLynxView:lynxView debuggable:builder.debuggable];
    [_devTool setSharedVM:builder.group];
    _enableAsyncDisplayFromNative = YES;
    _enableTextNonContiguousLayout = [builder enableTextNonContiguousLayout];
    _enableLayoutOnly = [LynxEnv.sharedInstance getEnableLayoutOnly];

    builder.config = builder.config ?: [LynxEnv sharedInstance].config;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    builder.config = builder.config ?: [[LynxConfig alloc] initWithProvider:nil];
#pragma clang diagnostic pop
    _config = builder.config;
    _group = builder.group;
    _fetcher = builder.fetcher;
    _hasStartedLoad = NO;
    _fontScale = builder.fontScale;
    // Prepare lynx ui context screen metrics
    LynxScreenMetrics* screenMetrics =
        [[LynxScreenMetrics alloc] initWithScreenSize:screenSize scale:[UIScreen mainScreen].scale];
    // Prepare lynx ui owner
    _uiOwner = [[LynxUIOwner alloc] initWithContainerView:lynxView
                                           templateRender:self
                                        componentRegistry:builder.config.componentRegistry
                                            screenMetrics:screenMetrics];
    [_devTool attachLynxUIOwner:_uiOwner];
    __weak typeof(self) weakSelf = self;
    _uiOwner.onFirstScreenListener = ^() {
      [weakSelf dispatchDidFirstScreen];
    };
    _uiOwner.onPageUpdateListener = ^() {
      [weakSelf dispatchDidPageUpdate];
    };
    CGRect frame = builder.frame;
    // prepare genericReportInfo
    _genericReportInfo = [LynxGenericReportInfo infoWithTarget:_lynxView];
    [_genericReportInfo updateThreadStrategy:[builder getThreadStrategyForRender]];
    // prepare timing handler
    _timingHandler =
        [[LynxTimingHandler alloc] initWithThreadStrategy:[builder getThreadStrategyForRender]];
    _timingHandler.enableJSRuntime = _enableJSRuntime;
    _uiOwner.uiContext.timingHandler = _timingHandler;
    _uiOwner.uiContext.contextDict = [builder.config.contextDict copy];
    // set thread strategy for rendering
    _threadStrategyForRendering = builder.getThreadStrategyForRender;
    _isAsyncRender =
        _threadStrategyForRendering == LynxThreadStrategyForRenderMultiThreads ? YES : NO;
    _enableLayoutSafepoint = builder.enableLayoutSafepoint;
    _uilayoutTick = [[LynxUILayoutTick alloc] initWithRoot:lynxView
                                                     block:^() {
                                                       __strong LynxTemplateRender* strongSelf =
                                                           weakSelf;
                                                       strongSelf->shell_->TriggerLayout();
                                                     }];
    _enableAutoExpose = builder.enableAutoExpose;
    _enablePreUpdateData = builder.enablePreUpdateData;

    LynxProviderRegistry* registry = [[LynxProviderRegistry alloc] init];
    NSDictionary* providers = [LynxEnv sharedInstance].resoureProviders;
    for (NSString* globalKey in providers) {
      [registry addLynxResourceProvider:globalKey provider:providers[globalKey]];
    }
    providers = [builder getLynxResourceProviders];
    for (NSString* key in providers) {
      [registry addLynxResourceProvider:key provider:providers[key]];
    }
    _providerRegistry = registry;

    _uiOwner.fontFaceContext.resourceProvider =
        [registry getResourceProviderByKey:LYNX_PROVIDER_TYPE_FONT];

    _uiOwner.fontFaceContext.builderRegistedAliasFontMap = [builder getBuilderRegistedAliasFontMap];

    [self initShadowNodeOwner];
    // Prepare shell
    [self prepareShell];

    // Prepare touch handler
    [self prepareEventHandler];

    // update viewport when preset width and heigth
    if ((!CGRectEqualToRect(frame, CGRectZero) && !CGSizeEqualToSize(frame.size, CGSizeZero))) {
      _layoutWidthMode = LynxViewSizeModeExact;
      _layoutHeightMode = LynxViewSizeModeExact;
      _preferredLayoutWidth = frame.size.width;
      _preferredLayoutHeight = frame.size.height;
      [self updateViewport];
    }
    _frameOfLynxView = frame;
    if (lynxView && !CGRectEqualToRect(lynxView.frame, _frameOfLynxView) &&
        !CGRectEqualToRect(CGRectZero, _frameOfLynxView)) {
      lynxView.frame = _frameOfLynxView;
    }

    // get runtime id from jsproxy
    if (_enableJSRuntime) {
      [_devTool setRuntimeId:[[self getLynxRuntimeId] integerValue]];
    }
    _initEndTiming = [[NSDate date] timeIntervalSince1970] * 1000;
    [_timingHandler setTiming:_initStartTiming key:OC_SETUP_CREATE_LYNX_START updateFlag:nil];
    [_timingHandler setTiming:_initEndTiming key:OC_SETUP_CREATE_LYNX_END updateFlag:nil];
  }
  lynx::base::PerfCollector::GetInstance().InsertDouble(
      shell_->GetTraceId(), lynx::base::PerfCollector::PerfStamp::INIT_START, _initStartTiming);
  lynx::base::PerfCollector::GetInstance().InsertDouble(
      shell_->GetTraceId(), lynx::base::PerfCollector::PerfStamp::INIT_END, _initEndTiming);
  return self;
};

- (void)prepareEnvWidthScreenSize:(CGSize)screenSize enableAsyncCreate:(BOOL)enableAsyncCreate {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxTemplateRender::prepareEnvWidthScreenSize");
  // prepare env of device and css
  if (enableAsyncCreate) {
    return;
  }
  [[LynxEnv sharedInstance] initLayoutConfig:screenSize];
}

- (void)initPiper {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxTemplateRender::initPiper");
  //    TODO: The LynxRuntimeDarwin Pointer is not stored at the moment. If LynxView
  //    wants to handle it, store it.

  std::string tag = [(_group ? [_group groupName] : [LynxGroup singleGroupTag]) UTF8String];

  // TODO: (chenyouhui.duke) :
  // The property of LynxView has been removed from LynxTemplateRender.
  // This method will be called in 'reset' method which can't get LynxView.
  // Temporary use _delegate to cast to LynxView
  _context = [[LynxContext alloc] initWithLynxView:_lynxView];

  _timingHandler.lynxContext = _context;

  auto module_manager = std::make_shared<lynx::piper::ModuleManagerDarwin>();
  module_manager_ = module_manager;
  if (_config) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "module_manager->addWrappers");
    module_manager->addWrappers(_config.moduleManagerPtr->moduleWrappers());
  }

  LynxConfig* globalConfig = [LynxEnv sharedInstance].config;
  if (_config != globalConfig && globalConfig) {
    module_manager->parent = globalConfig.moduleManagerPtr;
  }
  module_manager->context = _context;

  // register internal module
  module_manager->registerModule(LynxIntersectionObserverModule.class);
  module_manager->registerModule(LynxUIMethodModule.class);
  module_manager->registerModule(LynxSetModule.class);
  module_manager->registerModule(LynxResourceModule.class);
  module_manager->registerModule(LynxAccessibilityModule.class);
  module_manager->registerModule(LynxExposureModule.class);
  [_devTool registerModule:self];

  // register auth module blocks
  for (LynxMethodBlock methodAuth in _config.moduleManagerPtr->methodAuthWrappers()) {
    module_manager->registerMethodAuth(methodAuth);
  }

  // register piper session info block
  for (LynxMethodSessionBlock methodSessionBlock in _config.moduleManagerPtr
           ->methodSessionWrappers()) {
    module_manager->registerMethodSession(methodSessionBlock);
  }

  [self.extra addEntriesFromDictionary:[module_manager->extraWrappers() copy]];

  self.lepusModulesClasses_ = [NSMutableDictionary new];
  if (module_manager->parent) {
    [self.lepusModulesClasses_ addEntriesFromDictionary:module_manager->parent->modulesClasses_];
  }
  [self.lepusModulesClasses_ addEntriesFromDictionary:module_manager->modulesClasses_];
  // init wasm from runtime
  [WebAssemblyBridge initWasm];
  auto loader = std::make_shared<lynx::piper::JSSourceLoaderDarwin>();
  std::vector<std::string> preload_js_paths;
  NSArray* preloadJSPaths = _group ? [_group preloadJSPaths] : nil;
  if (preloadJSPaths != nil) {
    for (NSString* path : preloadJSPaths) {
      preload_js_paths.emplace_back([path UTF8String]);
    }
  }

  _context.providerRegistry = _providerRegistry;
  auto external_source_loader = std::make_unique<lynx::shell::ExternalSourceLoaderDarwin>(
      [_providerRegistry getResourceProviderByKey:LYNX_PROVIDER_TYPE_EXTERNAL_JS],
      [_providerRegistry getResourceProviderByKey:LYNX_PROVIDER_TYPE_DYNAMIC_COMPONENT], _fetcher,
      self);

  auto on_runtime_actor_created =
      [&module_manager, any_canvas_enabled = [LynxGroup enableOptimizedCanvas:_group],
       lynx_view = _lynxView, context = _context,
       external_source_loader = external_source_loader.get()](auto& actor) {
        module_manager->initBindingPtr(module_manager,
                                       std::make_shared<lynx::shell::ModuleDelegateImpl>(actor));
        auto js_proxy = lynx::shell::JSProxyDarwin::Create(
            actor, lynx_view, actor->Impl()->GetRuntimeId(), any_canvas_enabled);
        [context setJSProxy:js_proxy];
        external_source_loader->SetJSProxy(js_proxy);
      };

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

  Class kryptonHelperClass = NSClassFromString(@"LynxKryptonApp");
  if ([LynxGroup enableOptimizedCanvas:_group] && NSStringFromClass(kryptonHelperClass).length) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxTemplateRender::enableKrypton");
    lynx::tasm::Config::setEnableKrypton(true);
    if ([LynxGroup enableOptimizedCanvas:_group]) {
      // TODO: delete this line of code after some time.
      [[_uiOwner getComponentRegistry] registerUI:NSClassFromString(@"LynxUICanvas")
                                         withName:@"canvas"];
      LLogInfo(@"LynxKrypton enabled with canvas optimize, regist LynxUICanvas for canvas");
    } else {
      LLogInfo(@"LynxKrypton enabled without canvas optimize");
    }
    _kryptonHelper = [[kryptonHelperClass alloc] init];
    [_kryptonHelper setupWithTemplateRender:self];
  } else {
    LLogInfo(@"LynxKrypton not used!!");
  }

#pragma clang diagnostic pop
  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "LynxTemplateRender::initPiper:InitRuntime");
  shell_->InitRuntime(
      tag, loader, module_manager, std::move(on_runtime_actor_created), std::move(preload_js_paths),
      [self needUpdateCoreJS], _group && [_group useProviderJsEnv],
      std::make_shared<lynx::shell::VSyncMonitorIOS>(false), std::move(external_source_loader),
      false, _enablePendingJSTaskOnLayout, false, "", [LynxGroup enableOptimizedCanvas:_group]);
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
  shell_->SetLepusApiActorDarwin([_lepusApiActorManager lepusApiActor]);
#if ENABLE_AIR
  if (_enableAirStrictMode) {
    shell_->InitAirEnv(std::make_unique<lynx::air::AirModuleHandlerDarwin>(self));
  }
#endif
}

/**
   check corejs update
 */
- (bool)needUpdateCoreJS {
  id<ICoreJsLoader> coreJsLoader = [CoreJsLoaderManager shareInstance].loader;
  bool lynxCoreUpdated = (coreJsLoader != nil && [coreJsLoader jsCoreUpdate]);
  if (!lynxCoreUpdated) {
    [coreJsLoader checkUpdate];
  }
  return lynxCoreUpdated;
}

// Prepare shadow node owner
- (void)initShadowNodeOwner {
  _shadowNodeOwner = [[LynxShadowNodeOwner alloc] initWithUIOwner:_uiOwner
                                                componentRegistry:[_uiOwner getComponentRegistry]
                                                       layoutTick:_uilayoutTick
                                                    isAsyncRender:_isAsyncRender
                                                          context:_uiOwner.uiContext];
  if (_uiOwner != nil && _uiOwner.uiContext != nil) {
    _uiOwner.uiContext.nodeOwner = _shadowNodeOwner;
  }
}

// Prepare shell
- (void)prepareShell {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxTemplateRender prepareShell")
  lynx::base::LynxEnvDarwin::initNativeUIThread();
  auto native_facade_creator = [self] {
    return std::make_unique<lynx::shell::NativeFacadeDarwin>(self);
  };
  CGSize screenSize = _uiOwner.uiContext.screenMetrics.screenSize;
  auto lynx_env_config = lynx::tasm::LynxEnvConfig(screenSize.width, screenSize.height);
  auto painting_context =
      std::make_unique<lynx::tasm::PaintingContextDarwin>(_uiOwner, !_needPendingUIOperation);
  _paintingContextProxy =
      [[PaintingContextProxy alloc] initWithPaintingContext:painting_context.get()];
  [_shadowNodeOwner setDelegate:_paintingContextProxy];

  // TODO(heshan):will remove pass runners to element manager
  auto loader = std::make_shared<lynx::tasm::DynamicComponentLoaderDarwin>(_fetcher, self);
  auto layout_context_creator = [shadow_node_owner = _shadowNodeOwner](auto layout_mediator,
                                                                       auto trace_id) {
    return std::make_unique<lynx::tasm::LayoutContext>(
        std::move(layout_mediator),
        std::make_unique<lynx::tasm::LayoutContextDarwin>(shadow_node_owner), trace_id);
  };

  auto lynx_engine_creator =
      [painting_context = std::move(painting_context), lynx_env_config = std::move(lynx_env_config),
       loader, enableLayoutOnly = _enableLayoutOnly, enablePreUpdateData = _enablePreUpdateData](
          auto delegate, auto& runners, auto& card_cached_data_mgr, int32_t trace_id,
          auto shell) mutable {
        TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxTemplateRender::lynx_engine_creator");
        /**
         * Not init VSyncMonitorIOS when create it,
         * because when applying MostOnTasm strategy,
         * VSyncMonitor will add CADisplayLink to the wrong runloop.
         */
        auto tasm = std::make_shared<lynx::tasm::TemplateAssembler>(
            *delegate,
            std::make_unique<lynx::tasm::ElementManager>(
                std::move(painting_context), delegate.get(), lynx_env_config,
                std::make_shared<lynx::shell::VSyncMonitorIOS>(false)),
            trace_id);
        tasm->SetEnableLayoutOnly(enableLayoutOnly);
        tasm->Init(runners.GetTASMTaskRunner());
        tasm->SetDynamicComponentLoader(loader);
        std::string locale = std::string([[[LynxEnv sharedInstance] locale] UTF8String]);
        tasm->SetLocale(locale);
        tasm->EnablePreUpdateData(enablePreUpdateData);
        return std::make_unique<lynx::shell::LynxEngine>(tasm, std::move(delegate),
                                                         card_cached_data_mgr);
      };
  lynx::shell::ShellOption option;
  option.enable_js_ = self.enableJSRuntime;
  option.enable_multi_tasm_thread_ =
      _enableMultiAsyncThread || [LynxEnv getBoolExperimentSettings:@"enable_multi_tasm_thread"];
  option.enable_multi_layout_thread_ =
      _enableMultiAsyncThread || [LynxEnv getBoolExperimentSettings:@"enable_multi_layout_thread"];
  shell_.reset(lynx::shell::LynxShell::Create(
      native_facade_creator, lynx_engine_creator, layout_context_creator,
      static_cast<lynx::base::ThreadStrategyForRendering>(_threadStrategyForRendering),
      std::make_shared<lynx::shell::VSyncMonitorIOS>(false),
      [loader](auto& actor) { loader->SetEngineActor(actor); }, option));
  shell_->SetLepusApiActorDarwin([_lepusApiActorManager lepusApiActor]);

  [_devTool onTemplateAssemblerCreated:(intptr_t)shell_.get()];
  [self initPiper];
  [self updateNativeTheme];
  [self updateNativeGlobalProps];
  // FIXME
  shell_->SetFontScale(_fontScale);
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (void)prepareEventHandler {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxTemplateRender prepareEventHandler")
  _uiOwner.uiContext.shellPtr = reinterpret_cast<int64_t>(shell_.get());
  _eventEmitter = [[LynxEventEmitter alloc] initWithLynxTemplateRender:self];
  _uiOwner.uiContext.eventEmitter = _eventEmitter;
  if (_eventHandler == nil) {
    // TODO: (chenyouhui.duke) :
    // The property of LynxView has been removed from LynxTemplateRender.
    // This method will be called in 'reset' method which can't get LynxView.
    // Temporary use _delegate to cast to LynxView
    _eventHandler = [[LynxEventHandler alloc] initWithRootView:_lynxView];
  }
  _uiOwner.uiContext.eventHandler = _eventHandler;

  [_eventHandler updateUiOwner:_uiOwner eventEmitter:_eventEmitter];
  _intersectionObserverManager =
      [[LynxUIIntersectionObserverManager alloc] initWithLynxContext:_context];
  _intersectionObserverManager.uiOwner = _uiOwner;
  [_eventEmitter addObserver:_intersectionObserverManager];

  _context.intersectionManager = _intersectionObserverManager;
  _context.uiOwner = _uiOwner;

  _keyboardEventDispatcher = [[LynxKeyboardEventDispatcher alloc] initWithContext:_context];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (void)loadTemplate:(NSData*)tem withURL:(NSString*)url initData:(LynxTemplateData*)data {
  if (nil == url) {
    LLogError(@"LynxTemplateRender loadTemplate with data but url is empty! in render %p", self);
    return;
  }

  [_devTool onLoadFromLocalFile:tem withURL:url initData:data];

  _url = url;
  // Update template url to LynxGenericReportInfo.
  [_genericReportInfo updateLynxUrl:url];
  [_paintingContextProxy setEnableFlush:!_needPendingUIOperation];
  [self dispatchViewDidStartLoading];
  [self internalLoadTemplate:tem withUrl:url initData:data];
}

- (void)loadSSRData:(NSData*)tem
            withURL:(NSString*)url
           initData:(nullable LynxTemplateData*)initData {
  [_devTool onLoadFromLocalFile:tem withURL:url initData:initData];
  [_paintingContextProxy setEnableFlush:!_needPendingUIOperation];

  _url = url;
  // Update template url to LynxGenericReportInfo.
  [_genericReportInfo updateLynxUrl:url];
  __weak LynxTemplateRender* weakSelf = self;
  NSString* errorMsg = [self executeNativeOpSafely:^() {
    if (![NSThread isMainThread]) {
      NSString* stack =
          [[[NSThread callStackSymbols] valueForKey:@"description"] componentsJoinedByString:@"\n"];
      LLogError(@"LoadSSRData on other thread:%@, stack:%@", [NSThread currentThread].name, stack);
    }
    __strong LynxTemplateRender* strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf markDirty];
    if (_hasStartedLoad || strongSelf->shell_->IsDestroyed()) {
      [strongSelf reset];
    } else {
      [strongSelf updateViewport];
    }

    // wating for hydarte
    _hasStartedLoad = YES;
    [strongSelf.lynxSSRHelper onLoadSSRDataBegan:url];
    auto data = ConvertNSBinary(tem);
    std::shared_ptr<lynx::tasm::TemplateData> ptr(nullptr);
    lynx::lepus::Value value;
    if (initData != nil) {
      value = *LynxGetLepusValueFromTemplateData(initData);
      ptr = std::make_shared<lynx::tasm::TemplateData>(
          value, initData.isReadOnly,
          initData.processorName ? initData.processorName.UTF8String : "");
    }

    [_timingHandler setSsrTimingInfo:@{@"url" : (url ?: @""), @"data_size" : @(tem.length)}];

    strongSelf->shell_->LoadSSRData(data, ptr);
  }];
  [self onErrorOccurred:LynxErrorCodeSsrDecode message:errorMsg];
}

- (void)ssrHydrate:(nonnull NSData*)tem
           withURL:(nonnull NSString*)url
          initData:(nullable LynxTemplateData*)data {
  if ([_lynxSSRHelper isHydratePending]) {
    _hasStartedLoad = NO;
    [_lynxSSRHelper onHydrateBegan:url];
  }

  [self loadTemplate:tem withURL:url initData:data];
}

- (void)invokeLepusFunc:(NSDictionary*)data callbackID:(int32_t)callbackID {
  [_lepusApiActorManager invokeLepusFunc:data callbackID:callbackID];
}

- (void)loadTemplateWithoutLynxView:(NSData*)tem
                            withURL:(NSString*)url
                           initData:(LynxTemplateData*)data {
  [self detachLynxView];
  _hasRendered = NO;
  [self loadTemplate:tem withURL:url initData:data];
}

- (void)dispatchError:(LynxError*)error {
  if (_delegate) {
    [_delegate templateRender:self onErrorOccurred:error];
  }
}

- (void)loadTemplateFromURL:(NSString*)url initData:(LynxTemplateData*)data {
  if (nil == url) {
    LLogError(@"LynxTemplateRender loadTemplateFromURL url is empty! in render %p", self);
    return;
  }
  [self onLoadFromURL:url initData:data];
  [self dispatchViewDidStartLoading];
  __weak LynxTemplateRender* weakSelf = self;
  LynxTemplateLoadBlock complete = ^(NSData* tem, NSError* error) {
    NSTimeInterval requestTemplateEnd = [[NSDate date] timeIntervalSince1970] * 1000;
    [[weakSelf timingHandler] setTiming:requestTemplateEnd
                                    key:OC_PREPARE_TEMPLATE_END
                             updateFlag:nil];
    //    if (![weakSelf.url isEqualToString:url]) {
    //      return;
    //    }
    NSDictionary* urls = [weakSelf processUrl:url];
    [weakSelf.devTool onLoadFromURL:[urls objectForKey:@"compile_path"] ?: @""
                           initData:data
                            postURL:[urls objectForKey:@"post_url"] ?: @""];
    if (!error) {
      [weakSelf internalLoadTemplate:tem withUrl:url initData:data];
    } else {
      [weakSelf onErrorOccurred:LynxErrorCodeTemplateProvider sourceError:error];
    }
  };
  LLogInfo(@"LynxTemplateRender loadTemplate url after process is %@", url);
  NSTimeInterval requestTemplateStart = [[NSDate date] timeIntervalSince1970] * 1000;
  [_timingHandler setTiming:requestTemplateStart key:OC_PREPARE_TEMPLATE_START updateFlag:nil];
  [_config.templateProvider loadTemplateWithUrl:url onComplete:complete];
}

- (void)loadSSRDataFromURL:(NSString*)url initData:(nullable LynxTemplateData*)data {
  if (nil == url) {
    LLogError(@"LynxTemplateRender loadSSRDataFromURL url is empty! in render %p", self);
    return;
  }

  __weak LynxTemplateRender* weakSelf = self;
  LynxTemplateLoadBlock complete = ^(NSData* tem, NSError* error) {
    if (!error) {
      [weakSelf loadSSRData:tem withURL:url initData:data];
    } else {
      [weakSelf onErrorOccurred:LynxErrorCodeTemplateProvider sourceError:error];
    }
  };
  LLogInfo(@"loadSSRDataFromURL loadssrdata url after process is %@", url);
  [_config.templateProvider loadTemplateWithUrl:url onComplete:complete];
}

- (LynxSSRHelper*)lynxSSRHelper {
  if (!_lynxSSRHelper) {
    _lynxSSRHelper = [[LynxSSRHelper alloc] init];
  }
  return _lynxSSRHelper;
}

- (void)ssrHydrateFromURL:(NSString*)url initData:(nullable LynxTemplateData*)data {
  if ([_lynxSSRHelper isHydratePending]) {
    _hasStartedLoad = NO;
    [_lynxSSRHelper onHydrateBegan:url];
  }

  [self loadTemplateFromURL:url initData:data];
}

- (void)hotModuleReplace:(NSString*)message withParams:(NSDictionary*)params {
  LLogInfo(@"LynxTemplateRender, call hotModuleReplace with message %@", message);
}

- (NSString*)executeNativeOpSafely:(void(NS_NOESCAPE ^)(void))block {
  NSString* errorMsg = nil;
  BOOL hasBacktrace = NO;
  try {
    @try {
      block();
    } @catch (NSException* exception) {
      errorMsg = [NSString stringWithFormat:@"%@:%@", [exception name], [exception reason]];
    }
  } catch (const std::runtime_error& e) {
    errorMsg = [NSString stringWithUTF8String:e.what()];
  } catch (const std::exception& e) {
    errorMsg = [NSString stringWithUTF8String:e.what()];
  } catch (const char* msg) {
    errorMsg = [NSString stringWithUTF8String:msg];
  } catch (const lynx::base::LynxError& e) {
    hasBacktrace = YES;
    errorMsg = [NSString stringWithUTF8String:e.error_message_.c_str()];
  } catch (...) {
    errorMsg = @"Unknow fatal exception";
  }

  if (errorMsg) {
    if (_delegate) {
      [_delegate templateRenderOnResetViewAndLayer:self];
    }

    [_devTool destroyDebugger];
    shell_->Destroy();

    if (!hasBacktrace) {
      std::string errorMessage([errorMsg UTF8String]);
      errorMsg =
          [NSString stringWithCString:lynx::base::debug::GetBacktraceInfo(errorMessage).c_str()
                             encoding:[NSString defaultCStringEncoding]];
    }
  }

  return errorMsg;
}

- (LynxUI*)findUIByIndex:(int)index {
  return [_uiOwner findUIBySign:index];
}

- (NSString*)formatLynxSchema:(NSString*)url {
  if (!url) {
    return url;
  }

  {
    // handle abnormal url like @"this is a test url", return itself without processing
    NSURL* uri = [NSURL URLWithString:url];
    if (!uri) {
      return url;
    }
  }

  // Clear query parameters on target NSURLComponents
  NSURLComponents* originalComponents = [[NSURLComponents alloc] initWithString:url];
  NSURLComponents* targetComponents = [[NSURLComponents alloc] initWithString:url];
  [targetComponents setQueryItems:nil];

  // Append reserved queries to targetComponents
  NSArray<NSURLQueryItem*>* queryItems = [originalComponents queryItems];
  NSSet<NSString*>* reservedParamKeys =
      [[NSSet alloc] initWithObjects:@"surl", @"url", @"channel", @"bundle", nil];
  NSMutableArray<NSURLQueryItem*>* appendedParams = [[NSMutableArray alloc] init];
  for (NSURLQueryItem* item in queryItems) {
    if ([reservedParamKeys containsObject:[item name]] && [item value] && [item value].length > 0) {
      [appendedParams addObject:item];
    }
  }
  [targetComponents setQueryItems:appendedParams];
  return [targetComponents string];
}

- (void)prepareForLoadTemplateWithUrl:(NSString*)url initData:(LynxTemplateData*)data {
  if (![NSThread isMainThread]) {
    LOGE("LoadTemplate on other thread:" << [NSThread currentThread] << ", url:" << url);
  }
  self.initialMemory = [LynxPerformanceUtils availableMemory];
  {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "reportErrorGlobalContext");
    NSString* finalSchema = [self formatLynxSchema:url];
    [LynxService(LynxServiceMonitorProtocol) reportErrorGlobalContextTag:LynxContextTagLastLynxURL
                                                                    data:finalSchema];
  }
  if (_hasStartedLoad || self->shell_->IsDestroyed()) {
    [self reset];
  } else {
    [self updateViewport];
  }
  [self resetLayoutStatus];
  _timingHandler.url = url;
  TRACE_EVENT_INSTANT(LYNX_TRACE_CATEGORY_VITALS, LYNX_TRACE_EVENT_START_LOAD, "color",
                      LYNX_TRACE_EVENT_VITALS_COLOR_START_LOAD);
}

- (void)internalLoadTemplate:(NSData*)tem withUrl:(NSString*)url initData:(LynxTemplateData*)data {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxTemplateRender LoadTemplate")
  NSString* errorMsg = [self executeNativeOpSafely:^() {
    [self prepareForLoadTemplateWithUrl:url initData:data];
    lynx::lepus::Value value;
    std::shared_ptr<lynx::tasm::TemplateData> ptr(nullptr);
    if (data != nil) {
      TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateTemplateData");
      value = *LynxGetLepusValueFromTemplateData(data);
      ptr = std::make_shared<lynx::tasm::TemplateData>(
          value, data.isReadOnly, data.processorName ? data.processorName.UTF8String : "");
    }
    self->shell_->LoadTemplate([url UTF8String], ConvertNSBinary(tem), ptr);
    _hasStartedLoad = YES;
  }];
  [self onErrorOccurred:LynxErrorCodeLoadTemplate message:errorMsg];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (void)loadTemplateBundle:(LynxTemplateBundle*)bundle
                   withURL:(NSString*)url
                  initData:(LynxTemplateData*)data {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxTemplateRender::loadTemplateBundle")
  if ([bundle errorMsg]) {
    LLogError(
        @"LynxTemplateRender loadTemplateBundle with an invalid LynxTemplateBundle. error is: %p",
        [bundle errorMsg]);
    return;
  }
  auto template_bundle = LynxGetRawTemplateBundle(bundle);
  if (template_bundle == nullptr) {
    LLogError(@"LynxTemplateRender loadTemplateBundle with an empty LynxTemplateBundle.");
    return;
  }

  NSString* errorMsg = [self executeNativeOpSafely:^() {
    [self prepareForLoadTemplateWithUrl:url initData:data];
    lynx::lepus::Value value;
    std::shared_ptr<lynx::tasm::TemplateData> ptr(nullptr);
    if (data != nil) {
      TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateTemplateData");
      value = *LynxGetLepusValueFromTemplateData(data);
      ptr = std::make_shared<lynx::tasm::TemplateData>(
          value, data.isReadOnly, data.processorName ? data.processorName.UTF8String : "");
    }
    self->shell_->LoadTemplateBundle(lynx::base::SafeStringConvert([url UTF8String]),
                                     *template_bundle, ptr);
    _hasStartedLoad = YES;
  }];
  [self onErrorOccurred:LynxErrorCodeLoadTemplate message:errorMsg];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (void)requestLayoutWhenSafepointEnable {
  if (_enableLayoutSafepoint &&
      (_threadStrategyForRendering == LynxThreadStrategyForRenderPartOnLayout ||
       _needPendingUIOperation) &&
      _delegate != nil) {
    // trigger layout
    if ([_delegate respondsToSelector:@selector(templateRenderRequestNeedsLayout:)]) {
      [_delegate templateRenderRequestNeedsLayout:self];
    }
  }
}

- (void)updateGlobalPropsWithDictionary:(NSDictionary<NSString*, id>*)data {
  LYNX_TRACE_SECTION_WITH_INFO(LYNX_TRACE_CATEGORY_WRAPPER, @"TemplateRender.setGlobalProps", data);
  if (data.count > 0) {
    [self updateGlobalPropsWithTemplateData:[[LynxTemplateData alloc] initWithDictionary:data]];
  }
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
}

- (void)updateGlobalPropsWithTemplateData:(LynxTemplateData*)data {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"TemplateRender.setGlobalProps");
  if (data) {
    if (!_globalProps) {
      _globalProps = [[LynxTemplateData alloc] initWithDictionary:[NSDictionary new]];
    }
    [_globalProps updateWithTemplateData:data];
    [self updateNativeGlobalProps];
  }
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
}

- (void)updateNativeGlobalProps {
  if (shell_ == nil || _globalProps == nil) {
    return;
  }
  NSString* errorMsg = [self executeNativeOpSafely:^() {
    self->shell_->UpdateGlobalProps(*LynxGetLepusValueFromTemplateData(_globalProps));
  }];
  [self onErrorOccurred:LynxErrorCodeUpdate message:errorMsg];
}

- (void)updateDataWithString:(NSString*)data processorName:(NSString*)name {
  if (data) {
    [self requestLayoutWhenSafepointEnable];
    LynxTemplateData* templateData = [[LynxTemplateData alloc] initWithJson:data];
    [templateData markState:name];
    [templateData markReadOnly];
    [self updateDataWithTemplateData:templateData];
  }
}

- (void)updateDataWithDictionary:(NSDictionary<NSString*, id>*)data processorName:(NSString*)name {
  if (data.count > 0) {
    [self requestLayoutWhenSafepointEnable];
    LynxTemplateData* templateData = [[LynxTemplateData alloc] initWithDictionary:data];
    [templateData markState:name];
    [templateData markReadOnly];
    [self updateDataWithTemplateData:templateData];
  }
}

- (void)executeUpdateDataSafely:(void (^)(void))block {
  if (!self->shell_->IsDestroyed()) {
    NSString* errorMsg = [self executeNativeOpSafely:^() {
      [self requestLayoutWhenSafepointEnable];
      if (![NSThread isMainThread]) {
        LOGE("update data on other thread:" << [NSThread currentThread]);
      }
      block();
    }];

    [self onErrorOccurred:LynxErrorCodeUpdate message:errorMsg];
  }
}

- (void)updateDataWithTemplateData:(LynxTemplateData*)data {
  [self updateDataWithTemplateData:data updateFinishedCallback:nil];
}

- (void)updateDataWithTemplateData:(LynxTemplateData*)data
            updateFinishedCallback:(void (^)(void))callback {
  if (data) {
    [self executeUpdateDataSafely:^() {
      lynx::base::closure native_callback = nullptr;
      if (callback) {
        native_callback = [callback]() {
          @autoreleasepool {
            callback();
          }
        };
      }
      lynx::lepus::Value value = *LynxGetLepusValueFromTemplateData(data);
      std::shared_ptr<lynx::tasm::TemplateData> ptr = std::make_shared<lynx::tasm::TemplateData>(
          value, data.isReadOnly, data.processorName ? data.processorName.UTF8String : "");
      [self resetLayoutStatus];
      [self markDirty];
      self->shell_->UpdateDataByParsedData(ptr, std::move(native_callback));
    }];
  }
}
- (void)resetDataWithTemplateData:(LynxTemplateData*)data {
  if (data) {
    [self executeUpdateDataSafely:^() {
      lynx::lepus::Value value = *LynxGetLepusValueFromTemplateData(data);
      std::shared_ptr<lynx::tasm::TemplateData> ptr = std::make_shared<lynx::tasm::TemplateData>(
          value, data.isReadOnly, data.processorName ? data.processorName.UTF8String : "");
      [self resetLayoutStatus];
      [self markDirty];
      self->shell_->ResetDataByParsedData(ptr);
    }];
  }
}

- (void)reloadTemplateWithTemplateData:(nullable LynxTemplateData*)data
                           globalProps:(nullable LynxTemplateData*)globalProps {
  if (data) {
    [self executeUpdateDataSafely:^() {
      auto template_data = ConvertLynxTemplateDataToTemplateData(data);
      [self resetLayoutStatus];
      [self markDirty];

      /**
       * Null globalProps -> Nil Value;
       * Empty globalProps -> Table Value;
       */
      if (globalProps == nil) {
        self->shell_->ReloadTemplate(template_data);
      } else {
        self->_globalProps = globalProps;
        auto props_value = LynxGetLepusValueFromTemplateData(globalProps);
        self->shell_->ReloadTemplate(
            template_data,
            props_value ? *props_value : lynx::lepus::Value(lynx::lepus::Dictionary::Create()));
      }
    }];
  }
}

- (NSDictionary*)getCurrentData {
  std::unique_ptr<lepus_value> data = shell_->GetCurrentData();
  if (data == nullptr) {
    NSLog(@"getCurrentData with nullptr;");
    return @{};
  }
  NSString* json = [NSString stringWithUTF8String:(lepusValueToJSONString(*(data.get())).data())];
  NSData* nsData = [json dataUsingEncoding:NSUTF8StringEncoding];
  if (!nsData) {
    NSLog(@"getCurrentData with nil data;");
    return @{};
  }
  NSError* error;
  NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:nsData
                                                       options:NSJSONReadingMutableContainers
                                                         error:&error];
  if (error) {
    NSLog(@"getCurrentData error: %@", error);
    return @{};
  }
  return dict;
}

- (NSDictionary*)getPageDataByKey:(NSArray*)keys {
  std::vector<std::string> keysVec;
  for (NSString* key : keys) {
    keysVec.emplace_back([key UTF8String]);
  }
  lepus_value data = shell_->GetPageDataByKey(std::move(keysVec));
  if (data.IsNil()) {
    NSLog(@"getCurrentData return nullptr;");
    return @{};
  }

  NSString* json = [NSString stringWithUTF8String:(lepusValueToJSONString(data).data())];
  NSData* nsData = [json dataUsingEncoding:NSUTF8StringEncoding];
  if (!nsData) {
    NSLog(@"getCurrentData with nil data;");
    return @{};
  }
  NSError* error;
  NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:nsData
                                                       options:NSJSONReadingMutableContainers
                                                         error:&error];
  if (error) {
    NSLog(@"getCurrentData error: %@", error);
    return @{};
  }
  return dict;
}

- (void)onEnterForeground {
  [self onEnterForeground:true];
}

- (void)onEnterBackground {
  [self onEnterBackground:true];
}

- (BOOL)getAutoExpose {
  return _enableAutoExpose && (!pageConfig_ || pageConfig_->GetAutoExpose());
}

// when called onEnterForeground/onEnterBackground
// directly by LynxView, force onShow/onHide,
// else by willMoveToWindow, need check autoExpose or not
- (void)onEnterForeground:(bool)forceChangeStatus {
  if (shell_ != nullptr && (forceChangeStatus || [self getAutoExpose])) {
    shell_->OnEnterForeground();
  }
  [_uiOwner onEnterForeground];
  [_devTool onEnterForeground];
}

- (void)onEnterBackground:(bool)forceChangeStatus {
  if (shell_ != nullptr && (forceChangeStatus || [self getAutoExpose])) {
    shell_->OnEnterBackground();
  }
  [_uiOwner onEnterBackground];
  [_devTool onEnterBackground];
}

- (void)sendGlobalEvent:(nonnull NSString*)name withParams:(nullable NSArray*)params {
  // When SSR hydrate status is pending、beginning or failed, a global event will be sent to SSR
  // runtime to be consumed. But this global event will also be cached so that when runtimeReady it
  // behaves as normal global event.
  NSArray* finalParams = params;
  if ([_lynxSSRHelper shouldSendEventToSSR]) {
    // Send global event to SSR
    lynx::lepus::Value value = LynxConvertToLepusValue(params);
    self->shell_->SendSsrGlobalEvent([name UTF8String], value);

    // process params
    finalParams = [LynxSSRHelper processEventParams:params];
  }

  if (_context != nil) {
    [_context sendGlobalEvent:name withParams:finalParams];
  } else {
    LLogError(@"TemplateRender %p sendGlobalEvent %@ error, can't get LynxContext", self, name);
  }
}

- (void)sendGlobalEventToLepus:(nonnull NSString*)name withParams:(nullable NSArray*)params {
  lynx::lepus::Value value = LynxConvertToLepusValue(params);
  self->shell_->SendGlobalEventToLepus([name UTF8String], value);
}

- (void)triggerEventBus:(nonnull NSString*)name withParams:(nullable NSArray*)params {
  lynx::lepus::Value value = LynxConvertToLepusValue(params);
  self->shell_->TriggerEventBus([name UTF8String], value);
}

- (void)triggerLayout {
  [self updateViewport];
  if (_uilayoutTick) {
    NSString* errorMsg = [self executeNativeOpSafely:^{
      [self->_uilayoutTick triggerLayout];
    }];
    [self onErrorOccurred:LynxErrorCodeLayout message:errorMsg];
  }
}

- (void)updateViewport {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxTemplateRender updateViewport");
  [self updateViewport:true];
}

- (void)syncFlush {
  if (![NSThread isMainThread]) {
    NSString* stack =
        [[[NSThread callStackSymbols] valueForKey:@"description"] componentsJoinedByString:@"\n"];
    NSString* errMsg = [NSString
        stringWithFormat:
            @"LynxTemplateRender %p syncFlush must be called on ui thread, thread:%@, stack:%@",
            self, [NSThread currentThread], stack];
    [self onErrorOccurred:LynxErrorCodeSyncFlushInNonUiThread message:errMsg];
    LLogError(@"LynxTemplateRender %p syncFlush must be called on ui thread, thread:%@", self,
              [NSThread currentThread]);
    return;
  }
  shell_->Flush();
}

- (void)markDirty {
  shell_->MarkDirty();
}

- (void)updateViewport:(BOOL)needLayout {
  if (shell_->IsDestroyed()) {
    return;
  }
  SLMeasureMode heightMode = (SLMeasureMode)_layoutHeightMode;
  SLMeasureMode widthMode = (SLMeasureMode)_layoutWidthMode;
  CGFloat width =
      _layoutWidthMode == LynxViewSizeModeMax ? _preferredMaxLayoutWidth : _preferredLayoutWidth;
  CGFloat height =
      _layoutHeightMode == LynxViewSizeModeMax ? _preferredMaxLayoutHeight : _preferredLayoutHeight;
  shell_->UpdateViewport(width, widthMode, height, heightMode, needLayout);
}

- (void)updateScreenMetricsWithWidth:(CGFloat)width height:(CGFloat)height {
  if (shell_->IsDestroyed()) {
    return;
  }

  CGFloat scale = [UIScreen mainScreen].scale;
  shell_->UpdateScreenMetrics(width, height, scale);

  if (_uiOwner != nil && _uiOwner.uiContext != nil) {
    [_uiOwner.uiContext updateScreenSize:CGSizeMake(width, height)];
  }
}

- (void)updateFontScale:(CGFloat)scale {
  if (shell_->IsDestroyed()) {
    return;
  }
  shell_->UpdateFontScale(scale);
}

- (void)reset {
  // clear view
  if (_delegate) {
    [_delegate templateRenderOnResetViewAndLayer:self];
    _hasRendered = NO;
  }

  _lynxSSRHelper = nil;

  _globalProps = [_globalProps deepClone];
  [_uiOwner reset];

  [_timingHandler clearAllTimingInfo];

  [_devTool destroyDebugger];

  shell_->Destroy();

  if ([_delegate respondsToSelector:@selector(templateRenderOnTransitionUnregister:)]) {
    [_delegate templateRenderOnTransitionUnregister:self];
  }

  if (_shadowNodeOwner) {
    [_shadowNodeOwner destroySelf];
  }

  [self initShadowNodeOwner];
  [self prepareShell];

  [self prepareEventHandler];
  [self updateViewport];
  [_timingHandler setTiming:_initStartTiming key:OC_SETUP_CREATE_LYNX_START updateFlag:nil];
  [_timingHandler setTiming:_initEndTiming key:OC_SETUP_CREATE_LYNX_END updateFlag:nil];
}

- (void)dispatchViewDidStartLoading {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxTemplateRender dispatchViewDidStartLoading");
  if (_delegate) {
    [_delegate templateRenderOnTemplateStartLoading:self];
  }
}

- (void)dispatchDidFirstScreen {
  [_devTool onFirstScreen];
  [_delegate templateRenderOnFirstScreen:self];
}

- (void)dispatchDidPageUpdate {
  [_delegate templateRenderOnPageUpdate:self];
  [_devTool onPageUpdate];
}

- (void)willMoveToWindow:(UIWindow*)newWindow {
  [_uiOwner willContainerViewMoveToWindow:newWindow];
  if (newWindow != nil) {
    [self onEnterForeground:false];
  } else {
    [self onEnterBackground:false];
  }
}

- (void)didMoveToWindow:(BOOL)windowIsNil {
  [_devTool onMovedToWindow];
  [_uiOwner didMoveToWindow:windowIsNil];
}

- (void)onLoadFromURL:(NSString*)url initData:(LynxTemplateData*)data {
  NSDictionary* urls = [self processUrl:url];
  url = [urls objectForKey:@"compile_path"] ?: @"";
  _url = url;
  // Update template url to LynxGenericReportInfo.
  [_genericReportInfo updateLynxUrl:url];
}

- (NSMutableDictionary*)processUrl:(NSString*)url {
  NSMutableDictionary* res = [[NSMutableDictionary alloc] init];
  NSString* templateUrl = url;
  NSString* postUrl = @"";
  NSString* compileKey = @"compile_path";
  NSString* postKey = @"post_url";
  [res setObject:templateUrl forKey:compileKey];
  [res setObject:postUrl forKey:postKey];

  NSString* sep = @"&=?";
  NSCharacterSet* set = [NSCharacterSet characterSetWithCharactersInString:sep];
  NSArray* temp = [url componentsSeparatedByCharactersInSet:set];
  for (size_t i = 0; i < [temp count] - 1; ++i) {
    if ([temp[i] isEqualToString:compileKey]) {
      [res setObject:temp[i + 1] forKey:compileKey];
    } else if ([temp[i] isEqualToString:postKey]) {
      [res setObject:temp[i + 1] forKey:postKey];
    }
  }
  return res;
}

- (id<LynxEventTarget>)hitTestInEventHandler:(CGPoint)point withEvent:(UIEvent*)event {
  return [_eventHandler hitTest:point withEvent:event];
};

- (void)clearForDestroy {
  [_uiOwner reset];

  [_devTool destroyDebugger];
  shell_->Destroy();
}

- (void)dealloc {
  [_uiOwner reset];
  pageConfig_.reset();
  [_devTool destroyDebugger];
  // ios block cannot capture std::unique_ptr, tricky...
  auto* shell = shell_.release();
  // LynxView maybe release in main flow of TemplateAssembler,
  // so need just release LynxShell delay, avoid crash
  dispatch_async(dispatch_get_main_queue(), ^{
    delete shell;
  });
}

- (nullable NSNumber*)getLynxRuntimeId {
  if (_context != nil) {
    return [_context getLynxRuntimeId];
  }
  return nil;
}

- (nullable UIView*)findViewWithName:(nonnull NSString*)name {
  LynxWeakProxy* weakLynxUI = [_uiOwner weakLynxUIWithName:name];
  id weakUI = weakLynxUI.target;
  __strong LynxUI* strongUI = (LynxUI*)weakUI;
  return strongUI.view;
}

- (nullable UIView*)viewWithName:(nonnull NSString*)name {
  return [_uiOwner uiWithName:name].view;
}

- (nullable LynxUI*)uiWithName:(nonnull NSString*)name {
  return [_uiOwner uiWithName:name];
}

- (nullable UIView*)viewWithIdSelector:(nonnull NSString*)idSelector {
  return [_uiOwner uiWithIdSelector:idSelector].view;
}

- (NSArray<UIView*>*)viewsWithA11yID:(NSString*)a11yID {
  NSMutableArray<UIView*>* ret = [NSMutableArray array];
  [[_uiOwner uiWithA11yID:a11yID]
      enumerateObjectsUsingBlock:^(LynxUI* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        if (obj.view) {
          [ret addObject:obj.view];
        }
      }];
  return ret;
}

- (nullable LynxUI*)uiWithIdSelector:(nonnull NSString*)idSelector {
  return [_uiOwner uiWithIdSelector:idSelector];
}

- (NSString*)cardVersion {
  if (!pageConfig_) {
    return @"error";
  } else {
    return [NSString stringWithUTF8String:pageConfig_->GetVersion().c_str()];
  }
}

- (LynxConfigInfo*)lynxConfigInfo {
  if (!pageConfig_) {
    LynxConfigInfoBuilder* builder = [LynxConfigInfoBuilder new];
    return [builder build];
  } else {
    LynxConfigInfoBuilder* builder = [LynxConfigInfoBuilder new];
    builder.pageVersion = [NSString stringWithUTF8String:pageConfig_->GetVersion().c_str()];
    builder.pageType =
        [NSString stringWithUTF8String:lynx::tasm::GetDSLName(pageConfig_->GetDSL())];
    builder.cliVersion = [NSString stringWithUTF8String:pageConfig_->GetCliVersion().c_str()];
    builder.customData = [NSString stringWithUTF8String:pageConfig_->GetCustomData().c_str()];
    builder.templateUrl = _url;
    builder.targetSdkVersion =
        [NSString stringWithUTF8String:pageConfig_->GetTargetSDKVersion().c_str()];
    builder.lepusVersion = [NSString stringWithUTF8String:pageConfig_->GetLepusVersion().c_str()];
    builder.threadStrategyForRendering = _threadStrategyForRendering;
    builder.enableLepusNG = pageConfig_->GetEnableLepusNG();
    builder.enableCanvas = _group.enableCanvas;
    builder.radonMode = [NSString stringWithUTF8String:pageConfig_->GetRadonMode().c_str()];
    builder.reactVersion = [NSString stringWithUTF8String:pageConfig_->GetReactVersion().c_str()];
    builder.registeredComponent = _uiOwner.getComponentRegistry.allRegisteredComponent;
    builder.cssAlignWithLegacyW3c = pageConfig_->GetCSSAlignWithLegacyW3C();
    builder.enableCSSParser = pageConfig_->GetEnableCSSParser();
    return [builder build];
  }
}

- (LynxPerformance*)forceGetPerf {
  return nil;
}

- (nullable JSModule*)getJSModule:(nonnull NSString*)name {
  if (_context != nil) {
    return [_context getJSModule:name];
  }
  return NULL;
}

- (void)pauseRootLayoutAnimation {
  [_uiOwner pauseRootLayoutAnimation];
}

- (void)resumeRootLayoutAnimation {
  [_uiOwner resumeRootLayoutAnimation];
}

- (void)updateNativeTheme {
  if (shell_ == nullptr || _localTheme == nil) {
    return;
  }
  auto themeDict = lynx::lepus::Dictionary::Create();
  auto keys = [_localTheme allKeys];
  for (NSString* key in keys) {
    auto keyStr = lynx::lepus::String([key UTF8String]);
    NSString* val = [_localTheme valueForKey:key];
    auto valStr = lynx::lepus::String([val UTF8String]);
    themeDict->SetValue(keyStr.impl(), lepus_value(valStr.impl()));
  }

  lynx::base::scoped_refptr<lynx::lepus::Dictionary> dict = lynx::lepus::Dictionary::Create();
  dict->SetValue(CARD_CONFIG_THEME, lynx::lepus::Value(themeDict));

  shell_->UpdateConfig(lynx::lepus::Value(dict));
}

- (void)setTheme:(LynxTheme*)theme {
  if (theme == nil) {
    return;
  }

  [self setLocalTheme:theme];
  [self markDirty];
  [self requestLayoutWhenSafepointEnable];
  [self updateNativeTheme];
}

- (nullable LynxTheme*)theme {
  return _localTheme;
}

- (void)setLocalTheme:(LynxTheme*)theme {
  if (_localTheme == nil) {
    _localTheme = theme;
  } else {
    [_localTheme setThemeConfig:[theme themeConfig]];
  }
}

- (void)setEnableAsyncDisplay:(BOOL)enableAsyncDisplay {
  _enableAsyncDisplayFromNative = enableAsyncDisplay;
}

- (BOOL)enableAsyncDisplay {
  return _enableAsyncDisplayFromNative &&
         (pageConfig_ == nullptr || pageConfig_->GetEnableAsyncDisplay());
}

- (void)setImageDownsampling:(BOOL)enableImageDownsampling {
  _enableImageDownsampling = enableImageDownsampling;
}

- (BOOL)enableImageDownsampling {
  return pageConfig_ != nullptr && pageConfig_->GetEnableImageDownsampling();
}

- (BOOL)enableNewImage {
  return pageConfig_ != nullptr && pageConfig_->GetEnableNewImage();
}

- (BOOL)trailNewImage {
  return pageConfig_ != nullptr && pageConfig_->GetTrailNewImage();
}

- (NSInteger)redBoxImageSizeWarningThreshold {
  if (pageConfig_ != nullptr) {
    return pageConfig_->GetRedBoxImageSizeWarningThreshold();
  }
  return -1;
}

- (BOOL)enableTextNonContiguousLayout {
  return pageConfig_ != nullptr && pageConfig_->GetEnableTextNonContiguousLayout();
}

- (BOOL)enableLayoutOnly {
  return _enableLayoutOnly;
}

- (BOOL)enableTextLayerRender {
  return pageConfig_ != nullptr && pageConfig_->GetEnableTextLayerRender();
}

- (void)triggerLayoutInTick {
  if (_uilayoutTick) {
    [_uilayoutTick triggerLayout];
  }
}

- (void)setImageFetcherInUIOwner:(id<LynxImageFetcher>)imageFetcher {
  _uiOwner.uiContext.imageFetcher = imageFetcher;
}

- (void)setResourceFetcherInUIOwner:(id<LynxResourceFetcher>)resourceFetcher {
  _uiOwner.uiContext.resourceFetcher = resourceFetcher;
  _uiOwner.fontFaceContext.resourceFetcher = resourceFetcher;
}

- (void)setScrollListener:(id<LynxScrollListener>)scrollListener {
  _uiOwner.uiContext.scrollListener = scrollListener;
}

- (void)resetAnimation {
  [_uiOwner resetAnimation];
}

- (void)restartAnimation {
  [_uiOwner restartAnimation];
}

- (void)detachLynxView {
  [_delegate templateRenderOnDetach:self];
  if (_lynxView) {
    _lynxView = nil;
    _delegate = nil;
  }
}

- (void)startLynxRuntime {
  _enablePendingJSTaskOnLayout = NO;
  if (shell_ != nullptr) {
    shell_->StartJsRuntime();
  }
}

- (void)processLayout:(nonnull NSData*)tem
              withURL:(nonnull NSString*)url
             initData:(nullable LynxTemplateData*)data {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxTemplateRender processLayout");
  _needPendingUIOperation = YES;
  [_paintingContextProxy setEnableFlush:!_needPendingUIOperation];
  [self loadTemplate:tem withURL:url initData:data];
}

- (void)processLayoutWithSSRData:(nonnull NSData*)tem
                         withURL:(nonnull NSString*)url
                        initData:(nullable LynxTemplateData*)data {
  _needPendingUIOperation = YES;
  [_paintingContextProxy setEnableFlush:!_needPendingUIOperation];
  [self loadSSRData:tem withURL:url initData:data];
}

- (void)attachLynxView:(LynxView* _Nonnull)lynxView {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxTemplateRender attachLynxView");
  _lynxView = lynxView;
  _delegate = (id<LynxTemplateRenderDelegate>)lynxView;

  if ([_delegate respondsToSelector:@selector(templateRenderSetLayoutOption:)]) {
    [_delegate templateRenderSetLayoutOption:self];
  }

  if (shell_ != nullptr) {
    shell_->StartJsRuntime();
  }

  if (_uilayoutTick) {
    [_uilayoutTick attach:lynxView];
  }

  if (_uiOwner != nil) {
    [_uiOwner attachLynxView:lynxView];
  }

  if (_eventHandler) {
    [_eventHandler attachLynxView:lynxView];
  }

  if (_devTool) {
    [_devTool attachLynxView:lynxView];
  }
}

- (BOOL)processRender:(LynxView* _Nonnull)lynxView {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxTemplateRender processRender");
  if (shell_ == nullptr || shell_->IsDestroyed()) {
    return NO;
  }

  if (_lynxView == nil) {
    [self attachLynxView:lynxView];
  }

  if (_isAsyncRender || _needPendingUIOperation) {
    _hasRendered = YES;
    // Should set enable flush before forceFlush for list.
    [self setNeedPendingUIOperation:NO];
    [_paintingContextProxy forceFlush];
    LLogInfo(@"LynxTemplateRender process render finished");
  }
  return YES;
}

- (void)setNeedPendingUIOperation:(BOOL)needPendingUIOperation {
  _needPendingUIOperation = needPendingUIOperation;
  [_paintingContextProxy setEnableFlush:!needPendingUIOperation];
}

- (BOOL)isLayoutFinish {
  return [_paintingContextProxy isLayoutFinish];
}

- (void)resetLayoutStatus {
  [_paintingContextProxy resetLayoutStatus];
}

- (NSDictionary*)getAllJsSource {
  NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
  for (auto const& item : shell_->GetAllJsSource()) {
    auto key = [NSString stringWithCString:item.first.c_str() encoding:NSUTF8StringEncoding];
    auto value = [NSString stringWithCString:item.second.c_str() encoding:NSUTF8StringEncoding];
    if (key && value) {
      [dict setObject:value forKey:key];
    }
  }
  return dict;
}

- (float)rootWidth {
  if (_shadowNodeOwner != nil) {
    return [_shadowNodeOwner rootWidth];
  } else {
    return 0;
  }
}

- (float)rootHeight {
  if (_shadowNodeOwner != nil) {
    return [_shadowNodeOwner rootHeight];
  } else {
    return 0;
  }
}

// TODO(songshourui.null): do not rename this function now to avoid break change.
- (bool)sendSyncTouchEvent:(LynxTouchEvent*)event {
  return [_lepusApiActorManager sendSyncTouchEvent:event];
}

- (void)sendCustomEvent:(LynxCustomEvent*)event {
  [_lepusApiActorManager sendCustomEvent:event];
}

- (void)onPseudoStatusChanged:(int32_t)tag
                fromPreStatus:(int32_t)preStatus
              toCurrentStatus:(int32_t)currentStatus {
  [_lepusApiActorManager onPseudoStatusChanged:tag
                                 fromPreStatus:preStatus
                               toCurrentStatus:currentStatus];
}

- (void)notifyIntersectionObservers {
  if (_context && _context.intersectionManager) {
    [_context.intersectionManager notifyObservers];
  }
}

- (NSSet<NSString*>*)componentSet {
  return _uiOwner.componentSet;
}

- (LynxUIIntersectionObserverManager*)getLynxUIIntersectionObserverManager {
  return _intersectionObserverManager;
}

- (void)registerCanvasManager:(void*)canvasManager {
  shell_->AdoptCanvasManager(
      std::shared_ptr<lynx::canvas::ICanvasManager>((lynx::canvas::ICanvasManager*)canvasManager));
}

- (LynxThreadStrategyForRender)getThreadStrategyForRender {
  return _threadStrategyForRendering;
}

- (LynxContext*)getLynxContext {
  return _context;
}

- (void)setExtraTiming:(LynxExtraTiming*)timing {
  [_timingHandler setExtraTiming:timing];
}

- (nullable NSDictionary*)getAllTimingInfo {
  return [_timingHandler timingInfo];
}

- (void)triggerTrailReport {
  NSMutableDictionary* page_config = [NSMutableDictionary dictionary];
  std::unordered_map<std::string, std::string> map = pageConfig_->GetPageConfigMap();
  for (std::unordered_map<std::string, std::string>::iterator it = map.begin(); it != map.end();
       ++it) {
    NSString* key = [NSString stringWithUTF8String:it->first.c_str()];
    NSString* value = [NSString stringWithUTF8String:it->second.c_str()];
    page_config[key] = value;
  }
  lepus_value trial_options = pageConfig_->GetTrialOptions();
  NSMutableDictionary* extra = [NSMutableDictionary dictionary];
  if (!trial_options.IsNil()) {
    auto trial_options_table = trial_options.Table();
    for (auto& feature : *trial_options_table) {
      NSString* key = [NSString stringWithUTF8String:feature.first.c_str()];
      extra[key] = lynx::tasm::convertLepusValueToNSObject(feature.second);
    }
  }
  self.loadedMemory = [LynxPerformanceUtils availableMemory];
  NSMutableDictionary* memoryInfo = [NSMutableDictionary dictionary];
  [memoryInfo addEntriesFromDictionary:[LynxPerformanceUtils memoryStatus]];
  [memoryInfo addEntriesFromDictionary:@{
    @"memory_cost" : [NSString stringWithFormat:@"%lld", self.initialMemory - self.loadedMemory]
  }];
  NSDictionary* data = @{
    @"page_config" : page_config,
    @"metric" : [self getAllTimingInfo],
    @"memory" : memoryInfo,
    @"extra" : extra
  };
  [LynxService(LynxServiceMonitorProtocol) reportTrailEvent:@"lynx_inspector" data:data];
}

- (nullable NSDictionary*)getExtraInfo {
  return _extra;
}

- (void)runOnTasmThread:(dispatch_block_t)task {
  std::function<void(void)> native_task = [task]() { task(); };
  shell_->RunOnTasmThread(std::move(native_task));
}

- (void)invokeUIMethod:(NSString*)method
                params:(NSDictionary*)params
              callback:(int)callback
                toNode:(int)node {
  __weak LynxTemplateRender* weakSelf = self;
  LynxUIMethodCallbackBlock cb = ^(int code, id _Nullable data) {
    NSDictionary* res = @{@"code" : @(code), @"data" : data ?: @{}};
    if (weakSelf) {
      __strong LynxTemplateRender* strongSelf = weakSelf;
      if (code >= 0 && strongSelf->_context && strongSelf->_context->proxy_) {
        strongSelf->_context->proxy_->CallJSApiCallbackWithValue(callback, res);
      }
    }
  };

  [_uiOwner invokeUIMethodForSelectorQuery:method params:params callback:cb toNode:node];
}

- (void)registerModule:(Class<LynxModule> _Nonnull)module param:(id _Nullable)param {
  auto module_manager = module_manager_.lock();
  if (module_manager) {
    LLogInfo(@"LynxTemplateRender registerModule: %@ with param (address): %p", module, param);
    module_manager->registerModule(module, param);
  }
}

- (BOOL)isModuleExist:(NSString* _Nonnull)moduleName {
  auto module_manager = module_manager_.lock();
  if (module_manager) {
    return [module_manager->getModuleClasses() objectForKey:moduleName] != nil;
  }
  return NO;
}

- (void)setTemplateRenderDelegate:(LynxTemplateRenderDelegateExternal*)delegate {
  if (_lynxView != nil) {
    LLogError(
        @"LynxTemplateRender can not setTemplateRenderDelegate, _lynxView has been attached.");
    return;
  }
  _delegate = delegate;
}

#pragma mark - TemplateRenderCallbackProtocol

- (void)onDataUpdated {
  [_delegate templateRenderOnDataUpdated:self];
}

- (void)onPageChanged:(BOOL)isFirstScreen {
  if (isFirstScreen) {
    [_devTool onFirstScreen];
  } else {
    [_devTool onPageUpdate];
  }
  [_delegate templateRender:self onPageChanged:isFirstScreen];
}

- (void)onTasmFinishByNative {
  [_delegate templateRenderOnTasmFinishByNative:self];
}

- (void)onTemplateLoaded:(NSString*)url {
  [_delegate templateRender:self onTemplateLoaded:url configInfo:[self lynxConfigInfo]];
  [_devTool onLoadFinished];
}

- (void)onSSRHydrateFinished:(NSString*)url {
  [_lynxSSRHelper onHydrateFinished:url];
}

- (void)onRuntimeReady {
  [_delegate templateRenderOnRuntimeReady:self];
}

- (void)onFirstLoadPerf:(NSDictionary*)perf {
  LynxPerformance* performance =
      [[LynxPerformance alloc] initWithPerformance:perf url:_url configInfo:[self lynxConfigInfo]];
  [_delegate templateRender:self onReceiveFirstLoadPerf:performance];
}

- (void)onUpdatePerfReady:(NSDictionary*)perf {
  LynxPerformance* performance =
      [[LynxPerformance alloc] initWithPerformance:perf url:_url configInfo:[self lynxConfigInfo]];
  [_delegate templateRender:self onUpdatePerf:performance];
}

- (void)onDynamicComponentPerf:(NSDictionary*)perf {
  [_delegate templateRender:self onReceiveDynamicComponentPerf:perf];
}

- (void)setPageConfig:(const std::shared_ptr<lynx::tasm::PageConfig>&)pageConfig {
  pageConfig_ = pageConfig;

  // Since page config is a C++ class and Event Handler is a pure OC class, the set methods must be
  // called here.
  [_eventHandler setEnableSimultaneousTap:pageConfig->GetEnableSimultaneousTap()];
  [_eventHandler setEnableViewReceiveTouch:pageConfig->GetEnableViewReceiveTouch()];
  [_eventHandler setDisableLongpressAfterScroll:pageConfig->GetDisableLongpressAfterScroll()];
  [_eventHandler setTapSlop:[NSString stringWithUTF8String:pageConfig->GetTapSlop().c_str()]];
  [_eventHandler setLongPressDuration:pageConfig->GetLongPressDuration()];
  [_eventHandler.touchRecognizer setEnableTouchRefactor:pageConfig->GetEnableTouchRefactor()];
  [_eventHandler.touchRecognizer
      setEnableEndGestureAtLastFingerUp:pageConfig->GetEnableEndGestureAtLastFingerUp()];
  // If enable fiber arch, enable touch pseudo as default.
  [_eventHandler.touchRecognizer setEnableTouchPseudo:pageConfig->GetEnableFiberArch()];

  // Set config to IntersectionObserverManager
  [_intersectionObserverManager
      setEnableNewIntersectionObserver:pageConfig_->GetEnableNewIntersectionObserver()];

  // Set config to LynxUIExposure
  [_context.uiOwner.uiContext.uiExposure setObserverFrameRate:pageConfig->GetObserverFrameRate()];
  [_context.uiOwner.uiContext.uiExposure
      setEnableCheckExposureOptimize:pageConfig->GetEnableCheckExposureOptimize()];

  // Set config to LynxUIContext;
  LynxUIContext* uiContext = _context.uiOwner.uiContext;
  [uiContext setDefaultOverflowVisible:pageConfig->GetDefaultOverflowVisible()];
  [uiContext setEnableTextRefactor:pageConfig->GetEnableTextRefactor()];
  [uiContext setEnableTextOverflow:pageConfig->GetEnableTextOverflow()];
  [uiContext setEnableNewClipMode:pageConfig->GetEnableNewClipMode()];
  [uiContext setDefaultImplicitAnimation:pageConfig->GetGlobalImplicit()];
  [uiContext setEnableEventRefactor:pageConfig->GetEnableEventRefactor()];
  [uiContext setEnableA11yIDMutationObserver:pageConfig->GetEnableA11yIDMutationObserver()];

  [uiContext setEnableEventThrough:pageConfig->GetEnableEventThrough()];
  [uiContext setEnableBackgroundShapeLayer:pageConfig->GetEnableBackgroundShapeLayer()];
  [uiContext setEnableExposureUIMargin:pageConfig->GetEnableExposureUIMargin()];
  [uiContext setEnableTextLanguageAlignment:pageConfig->GetEnableTextLanguageAlignment()];
  [uiContext setEnableXTextLayoutReused:pageConfig->GetEnableXTextLayoutReused()];
  [uiContext setEnableFiberArch:pageConfig->GetEnableFiberArch()];
  [uiContext
      setTargetSdkVersion:[NSString
                              stringWithUTF8String:pageConfig->GetTargetSDKVersion().c_str()]];
  // update page config to LynxGenericReportInfo.
  [self updateGenericReportInfo];
}

- (void)updateGenericReportInfo {
  // LepusNG
  [_genericReportInfo updateEnableLepusNG:pageConfig_->GetEnableLepusNG()];
  // Target SDK Version
  [_genericReportInfo
      updatePropOpt:[NSString stringWithUTF8String:pageConfig_->GetTargetSDKVersion().c_str()]
             forKey:kPropLynxTargetSDKVersion];
  // Page Version
  [_genericReportInfo
      updatePropOpt:[NSString stringWithUTF8String:pageConfig_->GetVersion().c_str()]
             forKey:kPropLynxPageVersion];
  // DSL
  NSString* dsl = [NSString stringWithUTF8String:lynx::tasm::GetDSLName(pageConfig_->GetDSL())];
  [_genericReportInfo updateDSL:dsl];
  // mark immutable
  [_genericReportInfo markImmutable];
}

- (NSString*)translatedResourceWithId:(NSString*)resId themeKey:(NSString*)key {
  return [_delegate templateRender:self translatedResourceWithId:resId themeKey:key];
}

- (void)getI18nResourceForChannel:(NSString*)channel withFallbackUrl:(NSString*)url {
  LynxResourceRequest* request =
      [[LynxResourceRequest alloc] initWithUrl:[channel lowercaseString]];
  __weak typeof(self) weakSelf = self;
  [[_providerRegistry getResourceProviderByKey:LYNX_PROVIDER_TYPE_I18N_TEXT]
         request:request
      onComplete:^(LynxResourceResponse* _Nonnull response) {
        if (NSThread.isMainThread) {
          __strong __typeof(weakSelf) strongSelf = weakSelf;
          if (strongSelf != nil) {
            if (response.data == nil) {
              strongSelf->shell_->UpdateI18nResource(std::string([channel UTF8String]), "");
            } else {
              strongSelf->shell_->UpdateI18nResource(std::string([channel UTF8String]),
                                                     std::string([[response data] UTF8String]));
            }
          }
        } else {
          dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf != nil) {
              if (response.data == nil) {
                strongSelf->shell_->UpdateI18nResource(std::string([channel UTF8String]), "");
              } else {
                strongSelf->shell_->UpdateI18nResource(std::string([channel UTF8String]),
                                                       std::string([[response data] UTF8String]));
              }
            }
          });
        }
      }];
}

- (void)setTiming:(uint64_t)timestamp key:(NSString*)key updateFlag:(NSString*)updateFlag {
  [_timingHandler setTiming:timestamp key:key updateFlag:updateFlag];
}

- (void)loadComponent:(NSData*)tem withURL:(NSString*)url withCallbackId:(int32_t)callbackId {
  // validation before report async component url
  if (tem.length > 0) {
    [LynxService(LynxServiceMonitorProtocol)
        reportErrorGlobalContextTag:LynxContextTagLastLynxAsyncComponentURL
                               data:url];
  }
  shell_->LoadComponent([url UTF8String], ConvertNSBinary(tem), callbackId);
}

- (void)onCallJSBFinished:(NSDictionary*)info {
  [_delegate templateRender:self onCallJSBFinished:info];
}

- (void)onJSBInvoked:(NSDictionary*)info {
  [_delegate templateRender:self onJSBInvoked:info];
}

- (void)reportEvents:(std::vector<std::unique_ptr<lynx::tasm::PropBundle>>)stack {
  NSDictionary* extraData = [[self genericReportInfo] toJson];
  __block std::vector<std::unique_ptr<lynx::tasm::PropBundle>> block_stack = std::move(stack);
  dispatch_async(dispatch_get_global_queue(NULL, 0), ^{
    auto captured_stack = std::move(block_stack);
    for (const auto& event : captured_stack) {
      lynx::tasm::PropBundleDarwin* pda = static_cast<lynx::tasm::PropBundleDarwin*>(event.get());
      NSString* eventName = [NSString stringWithUTF8String:pda->tag().c_str()];
      [LynxService(LynxServiceAppLogProtocol) onReportEvent:eventName
                                                      props:pda->dictionary()
                                                  extraData:extraData];
    }
  });
}

- (NSMutableDictionary<NSString*, id>*)getLepusModulesClasses {
  return self.lepusModulesClasses_;
}

- (BOOL)enableBackgroundShapeLayer {
  return pageConfig_ && pageConfig_->GetEnableBackgroundShapeLayer();
}

- (BOOL)enableAirStrictMode {
  return _enableAirStrictMode;
}

- (void)preloadDynamicComponents:(NSArray* _Nonnull)urls {
  std::vector<std::string> preload_urls;
  for (NSString* url : urls) {
    preload_urls.emplace_back(lynx::base::SafeStringConvert([url UTF8String]));
  }
  self->shell_->PreloadDynamicComponents(std::move(preload_urls));
}

- (void)onLynxEvent:(LynxEventDetail*)event {
  [_delegate templateRender:self onLynxEvent:event];
}

@end

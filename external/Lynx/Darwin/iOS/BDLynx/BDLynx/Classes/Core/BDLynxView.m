
//
//  BDLynxView.m
//  BDLynx
//
//  Created by bill on 2020/2/4.
//

#import "BDLynxView.h"
#import <mach/mach_time.h>
#import "BDLLynxModuleProtocol.h"
#import "BDLSDKManager.h"
#import "BDLTemplateManager.h"
#import "BDLynxBridge.h"
#import "BDLynxBridgeModule.h"
#import "BDLynxBundle.h"
#import "BDLynxKitModule.h"
#import "BDLynxProvider.h"
#import "BDLynxViewClient.h"
#import "LynxGroup.h"
#import "LynxLog.h"
#import "LynxTemplateRender.h"
#import "LynxView.h"
#import "NSDictionary+BDLynxAdditions.h"
#import "NavigationModule.h"

#if BDLynxGeckoEnable
#endif

static NSString *const kBDLynxTemplateUrlDomain = @"kBDLynxTemplateUrlDomain";

static inline void dispatch_main_safe(dispatch_block_t block) {
  if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL),
             dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
    block();
  } else {
    dispatch_async(dispatch_get_main_queue(), block);
  }
}

#import "BDLynxProvider.h"

@implementation BDLynxViewBaseParams

- (instancetype)init {
  if (self = [super init]) {
    _fontScale = 1.0;
  }

  return self;
}

@end

@interface BDLynxView () <BDLynxClientLifeCycleDelegate,
                          LynxImageFetcher,
                          LynxResourceFetcher,
                          BDLynxProviderDelegate>

@property(nonatomic, strong) BDLynxViewClient *clientDelegate;
@property(nonatomic, assign) CGRect lynxViewFrame;

@property(nonatomic, strong) LynxConfig *lynxConfig;
@property(nonatomic, strong) BDLynxProvider *lynxProvdier;

@property(nonatomic, copy) NSString *channel;
@property(nonatomic, copy) NSString *sessionID;

@property(nonatomic, copy) void (^lynxBuilderBlock)(LynxViewBuilder *_Nonnull, NSString *_Nonnull);

@end

@implementation BDLynxView

+ (LynxGroup *)defaultGroup {
  static LynxGroup *_group;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _group = [[LynxGroup alloc] initWithName:@"_default"];
  });
  return _group;
}

- (instancetype)initWithFrame:(CGRect)frame {
  return [self initWithFrame:frame builderBlock:nil];
}

- (instancetype)initWithFrame:(CGRect)frame
                 builderBlock:(void (^)(LynxViewBuilder *_Nonnull, NSString *_Nonnull))block {
  self = [super initWithFrame:frame];
  if (self) {
    _lynxViewFrame = frame;
    _lynxBuilderBlock = block;
  }
  return self;
}

#pragma mark - load methods

- (void)p_loadParams:(BDLynxViewBaseParams *)params {
  if (params.initialProperties) {
    LynxTemplateData *initialData;
    if ([params.initialProperties isKindOfClass:[NSString class]]) {
      initialData = [[LynxTemplateData alloc] initWithJson:params.initialProperties];
    } else if ([params.initialProperties isKindOfClass:[NSDictionary class]]) {
      initialData = [[LynxTemplateData alloc] initWithDictionary:params.initialProperties];
    } else if ([params.initialProperties isKindOfClass:LynxTemplateData.class]) {
      initialData = params.initialProperties;
    }
    if (self.prefetchData) {
      [self.lynxView loadTemplate:self.prefetchData
                          withURL:params.localUrl ?: params.sourceUrl
                         initData:initialData];
    } else if (params.sourceUrl) {
      [self.lynxView loadTemplateFromURL:params.sourceUrl initData:initialData];
    } else {
      [self.lynxView loadTemplate:self.data
                          withURL:params.localUrl ?: params.sourceUrl
                         initData:initialData];
    }
  } else {
    if (self.prefetchData) {
      [self.lynxView loadTemplate:self.prefetchData withURL:params.localUrl ?: params.sourceUrl];
    } else if (params.sourceUrl) {
      [self.lynxView loadTemplateFromURL:params.sourceUrl];
    } else {
      [self.lynxView loadTemplate:self.data withURL:params.localUrl ?: params.sourceUrl];
    }
  }
}

// because render has been initialized，then attach lynxView to it directly
- (void)loadParamsUsingRender:(BDLynxViewBaseParams *)params
                       render:(LynxTemplateRender *)lynxTemplateRender {
  if (!_containerID) {
    _containerID = self.lynxView.containerID;
  }
  [lynxTemplateRender setImageFetcherInUIOwner:self];
  [lynxTemplateRender setResourceFetcherInUIOwner:self];
  [self setWidthAndHeightMode:lynxTemplateRender];
  [self.lynxView attachTemplateRender:lynxTemplateRender];
  [self.clientDelegate trackLynxRenderPipelineTrigger:@"page_start_time"];
}

- (void)loadLynxBaseParams:(BDLynxViewBaseParams *)params {
  [self p_loadParams:params];
  [self.clientDelegate trackLynxRenderPipelineTrigger:@"page_start_time"];
}

- (void)reloadWithBaseParams:(BDLynxViewBaseParams *)params {
  [self p_loadParams:params];
}

- (void)loadLynxWithParamsRender:(BDLynxViewBaseParams *)params
                          render:(LynxTemplateRender *)lynxTemplateRender {
  if (!params) return;
  self.params = params;

  if (params.channel) {
    self.channel = params.channel;
  } else {
    self.channel = params.groupID;
  }

  self.sessionID =
      [NSString stringWithFormat:@"%f%d", CFAbsoluteTimeGetCurrent(), arc4random() % 10000];
  if (self.prefetchData) {
    // Hybrid Monitor
    [self.clientDelegate updateChannel:self.channel
                            bundlePath:self.params.bundle
                             sessionID:self.sessionID
                         pageStartTime:[self.clientDelegate currentTimeSince1970]];
    [self.clientDelegate updateBid:params.reportBid pid:params.reportPid];
    [self loadParamsUsingRender:params render:lynxTemplateRender];
  } else if (params.sourceUrl) {
    // Add params to url for reload url from remote without cache
    BOOL hasParams = [params.sourceUrl rangeOfString:@"?"].location != NSNotFound;
    NSString *seperator = hasParams ? @"&" : @"?";
    NSString *url =
        [params.sourceUrl stringByAppendingFormat:@"%@t=%llu", seperator, mach_absolute_time()];
    // Hybrid Monitor
    [self.clientDelegate updateChannel:params.sourceUrl
                            bundlePath:params.bundle
                             sessionID:self.sessionID
                         pageStartTime:[self.clientDelegate currentTimeSince1970]];
    params.sourceUrl = !self.params.disableTimeStamp ? url : params.sourceUrl;
    [self.clientDelegate updateBid:params.reportBid pid:params.reportPid];
    [self loadParamsUsingRender:params render:lynxTemplateRender];
  } else if (self.data) {
    // Hybrid Monitor
    [self.clientDelegate updateChannel:self.channel
                            bundlePath:self.params.bundle
                             sessionID:self.sessionID
                         pageStartTime:[self.clientDelegate currentTimeSince1970]];
    [self.clientDelegate updateBid:params.reportBid pid:params.reportPid];
    [self loadParamsUsingRender:params render:lynxTemplateRender];
  } else {
    if ([self.lynxDelegate respondsToSelector:@selector(viewDidLoadFailedWithUrl:error:)]) {
      [self.lynxDelegate
          viewDidLoadFailedWithUrl:@""
                             error:[NSError errorWithDomain:@"com.bdlynx"
                                                       code:-100
                                                   userInfo:@{
                                                     NSLocalizedFailureReasonErrorKey :
                                                         @"url or data should set for TemplateView",
                                                   }]];
    }
    [self.clientDelegate trackLynxLifeCycleTrigger:@"load_tasm_error"
                                           logType:@"hybrid_monitor"
                                           service:@"hybrid_app_monitor_lynx_timeline_event"];
    NSAssert(false, @"url or data should set for TemplateView");
  }

  [self insertSubview:self.lynxView atIndex:0];
}

- (void)loadLynxWithParams:(BDLynxViewBaseParams *)params {
  if (!params) return;
  self.params = params;

  if (params.channel) {
    self.channel = params.channel;
  } else {
    self.channel = params.groupID;
  }

  self.sessionID =
      [NSString stringWithFormat:@"%f%d", CFAbsoluteTimeGetCurrent(), arc4random() % 10000];
  if (self.prefetchData) {
    // Hybrid Monitor
    [self.clientDelegate updateChannel:self.channel
                            bundlePath:self.params.bundle
                             sessionID:self.sessionID
                         pageStartTime:[self.clientDelegate currentTimeSince1970]];
    [self.clientDelegate updateBid:params.reportBid pid:params.reportPid];
    [self loadLynxBaseParams:params];
  } else if (params.sourceUrl) {
    // Add params to url for reload url from remote without cache
    BOOL hasParams = [params.sourceUrl rangeOfString:@"?"].location != NSNotFound;
    NSString *seperator = hasParams ? @"&" : @"?";
    NSString *url =
        [params.sourceUrl stringByAppendingFormat:@"%@t=%llu", seperator, mach_absolute_time()];
    // Hybrid Monitor
    [self.clientDelegate updateChannel:params.sourceUrl
                            bundlePath:params.bundle
                             sessionID:self.sessionID
                         pageStartTime:[self.clientDelegate currentTimeSince1970]];
    params.sourceUrl = !self.params.disableTimeStamp ? url : params.sourceUrl;
    [self.clientDelegate updateBid:params.reportBid pid:params.reportPid];
    [self loadLynxBaseParams:params];
  } else if (self.data) {
    // Hybrid Monitor
    [self.clientDelegate updateChannel:self.channel
                            bundlePath:self.params.bundle
                             sessionID:self.sessionID
                         pageStartTime:[self.clientDelegate currentTimeSince1970]];
    [self.clientDelegate updateBid:params.reportBid pid:params.reportPid];
    [self loadLynxBaseParams:params];
  } else {
    if ([self.lynxDelegate respondsToSelector:@selector(viewDidLoadFailedWithUrl:error:)]) {
      [self.lynxDelegate
          viewDidLoadFailedWithUrl:@""
                             error:[NSError errorWithDomain:@"com.bdlynx"
                                                       code:-100
                                                   userInfo:@{
                                                     NSLocalizedFailureReasonErrorKey :
                                                         @"url or data should set for TemplateView",
                                                   }]];
    }
    [self.clientDelegate trackLynxLifeCycleTrigger:@"load_tasm_error"
                                           logType:@"hybrid_monitor"
                                           service:@"hybrid_app_monitor_lynx_timeline_event"];
    NSAssert(false, @"url or data should set for TemplateView");
  }

  [self insertSubview:self.lynxView atIndex:0];
}

#pragma mark - reload Lynx
- (void)reloadWithBaseParams:(BDLynxViewBaseParams *)params data:(NSData *)data {
  _params = params;
  [self.lynxView setHidden:NO];
  if (data) {
    _data = data;
  }
  [self p_loadParams:params];
}

- (void)reload {
  [self reloadWithBaseParams:self.params data:self.prefetchData ?: self.data];
}

- (void)updateData:(NSDictionary *)dict {
  if (!dict) return;
  NSError *error = nil;
  [_lynxView updateDataWithString:[[NSString alloc]
                                      initWithData:[NSJSONSerialization
                                                       dataWithJSONObject:dict
                                                                  options:NSJSONWritingPrettyPrinted
                                                                    error:&error]
                                          encoding:NSUTF8StringEncoding]];
}

- (nullable UIView *)viewWithName:(nonnull NSString *)name {
  return [_lynxView viewWithName:name];
}

- (nullable UIView *)findViewWithName:(nonnull NSString *)name {
  return [_lynxView findViewWithName:name];
}

#pragma mark - register
- (void)registerModule:(Class<LynxModule>)module {
  [self.lynxConfig registerModule:module];
}

- (void)registerModule:(Class<LynxModule>)module param:(nullable id)param {
  [self.lynxConfig registerModule:module param:param];
}

- (void)registerUI:(Class)ui withName:(NSString *)name {
  [self.lynxConfig registerUI:ui withName:name];
}

- (void)registerShadowNode:(Class)node withName:(NSString *)name {
  [self.lynxConfig registerShadowNode:node withName:name];
}

#pragma mark - Bridge Handler

- (void)registerHandler:(BDLynxBridgeHandler)handler forMethod:(NSString *)method {
  [self.lynxView.bridge registerHandler:handler forMethod:method];
}

#pragma mark - BDLynxClientLifeCycleDelegate

- (void)viewDidChangeIntrinsicContentSize:(CGSize)size {
  dispatch_main_safe(^{
    if ([self.lynxDelegate respondsToSelector:@selector(viewDidChangeIntrinsicContentSize:)]) {
      [self.lynxDelegate viewDidChangeIntrinsicContentSize:size];
    }
  });
}

- (void)viewDidStartLoading {
  dispatch_main_safe(^{
    if ([self.lynxDelegate respondsToSelector:@selector(viewDidStartLoading)]) {
      [self.lynxDelegate viewDidStartLoading];
    }
  });
}

- (void)viewDidFirstScreen {
  dispatch_main_safe(^{
    if ([self.lynxDelegate respondsToSelector:@selector(viewDidFirstScreen)]) {
      [self.lynxDelegate viewDidFirstScreen];
    }
  });
}

- (void)viewDidFinishLoadWithURL:(NSString *)url {
  dispatch_main_safe(^{
    [self.lynxView triggerLayout];
    self.lynxView.frame = CGRectMake(0, 0, self.lynxView.intrinsicContentSize.width,
                                     self.lynxView.intrinsicContentSize.height);
    if ([self.lynxDelegate respondsToSelector:@selector(viewDidFinishLoadWithURL:)]) {
      [self.lynxDelegate viewDidFinishLoadWithURL:url];
    };
  });
}

- (void)viewDidUpdate {
  dispatch_main_safe(^{
    if ([self.lynxDelegate respondsToSelector:@selector(viewDidUpdate)]) {
      [self.lynxDelegate viewDidUpdate];
    }
  });
}

- (void)viewDidRecieveError:(NSError *)error {
  dispatch_main_safe(^{
    if ([self.lynxDelegate respondsToSelector:@selector(viewDidRecieveError:)]) {
      [self.lynxDelegate viewDidRecieveError:error];
    }
  });
}

- (void)viewDidLoadFailedWithUrl:(NSString *)url error:(NSError *)error {
  dispatch_main_safe(^{
    if ([self.lynxDelegate respondsToSelector:@selector(viewDidLoadFailedWithUrl:error:)]) {
      [self.lynxDelegate viewDidLoadFailedWithUrl:url error:error];
    }
  });
}

- (void)viewDidConstructJSRuntime {
  dispatch_main_safe(^{
    if ([self.lynxDelegate respondsToSelector:@selector(viewDidConstructJSRuntime)]) {
      [self.lynxDelegate viewDidConstructJSRuntime];
    }
  });
}

- (void)bdlynxViewLoadUrlFailed:(NSError *)error {
  if ([self.lynxDelegate respondsToSelector:@selector(bdlynxViewLoadUrlFailed:)]) {
    [self.lynxDelegate bdlynxViewLoadUrlFailed:error];
  }
}

- (void)viewDidPageUpdate {
  dispatch_main_safe(^{
    if ([self.lynxDelegate respondsToSelector:@selector(viewDidPageUpdate)]) {
      [self.lynxDelegate viewDidPageUpdate];
    }
  });
}

#pragma mark - Accessors
- (BDLynxProvider *)lynxProvdier {
  if (!_lynxProvdier) {
    _lynxProvdier = [BDLynxProvider new];
    _lynxProvdier.lynxProviderDelegate = self;
  }
  return _lynxProvdier;
}

- (LynxConfig *)lynxConfig {
  if (!_lynxConfig) {
    _lynxConfig = [[LynxConfig alloc] initWithProvider:self.lynxProvdier];
  }
  return _lynxConfig;
}

- (LynxView *)lynxView {
  if (!_lynxView) {
    if (self.params && self.params.enableGetPreHeight && self.params.containerID &&
        self.params.bdLynxBridge) {
      _lynxView = [[LynxView alloc] initWithoutRender];
      // 创建完成后需要绑定bdLynxBridge 和 cotainerID
      [self.params.bdLynxBridge attachLynxView:_lynxView];
      [_lynxView setBridge:self.params.bdLynxBridge];
      [_lynxView setContainerID:self.params.containerID];
    } else {
      _lynxView = [[LynxView alloc]
          initWithContainer:_containerID
           withBuilderBlock:^(LynxViewBuilder *builder, NSString *containerID) {
             [builder setThreadStrategyForRender:LynxThreadStrategyForRenderAllOnUI];
             builder.config = self.lynxConfig;
             builder.enableAutoExpose = !self.params.disableAutoExpose;
             if (self.dynamicComponentFetcher) {
               builder.fetcher = self.dynamicComponentFetcher;
             }

             [builder.config registerModule:[NavigationModule class] param:nil];

             if (self.params) {
               builder.fontScale = self.params.fontScale;
             } else {
               LLogInfo(@"BDLynxViewBaseParams is nil when building LynxView");
             }

             if (self.params.groupContext || self.params.enableBDLynxModule ||
                 self.params.extraJSPaths || self.params.enableCanvas ||
                 self.params.canvasOptimize) {
               NSMutableArray *preloadScirpt = [[NSMutableArray alloc] init];
               if (self.params.extraJSPaths) {
                 [preloadScirpt addObjectsFromArray:self.params.extraJSPaths];
               }
               if (self.params.enableBDLynxModule) {
                 NSString *bdCorePath = [BDL_SERVICE(BDLLynxModuleProtocol) scriptPath];
                 if (bdCorePath) {
                   [preloadScirpt addObject:bdCorePath];
                 }

                 Class<LynxModule> timor = [BDL_SERVICE_WITH_SELECTOR(
                     BDLLynxModuleProtocol, @selector(lynxModule)) lynxModule];
                 if (timor) {
                   [builder.config registerModule:timor param:containerID];
                 }
                 if (self.params.bdlynxModuleData) {
                   [BDL_SERVICE(BDLLynxModuleProtocol) updateModuleData:self.params.bdlynxModuleData
                                                                context:containerID];
                 }
               }

               NSString *name = self.params.groupContext
                                    ?: [NSString stringWithFormat:@"_default_bdlynx_%d_%ld",
                                                                  self.params.enableCanvas,
                                                                  self.params.canvasOptimize];
               if (self.params.canvasOptimize) {
                 builder.group = [[LynxGroup alloc] initWithName:name
                                               withPreloadScript:preloadScirpt
                                                useProviderJsEnv:false
                                                    enableCanvas:self.params.enableCanvas
                                        enableCanvasOptimization:self.params.canvasOptimize ==
                                                                 BDLynxCanvasOptimizeEnable];
               } else if (self.params.enableCanvas) {
                 builder.group = [[LynxGroup alloc] initWithName:name
                                               withPreloadScript:preloadScirpt
                                                useProviderJsEnv:false
                                                    enableCanvas:self.params.enableCanvas];
               } else {
                 builder.group = [[LynxGroup alloc] initWithName:name
                                               withPreloadScript:preloadScirpt];
               }
             } else {
               if (!self.params.disableShare) {
                 builder.group = [BDLynxView defaultGroup];
               }
             }

             if (self.lynxBuilderBlock) {
               self.lynxBuilderBlock(builder, containerID);
             }
           }];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    _lynxView.client = (id)self.clientDelegate;
#pragma clang diagnostic pop
    _lynxView.imageFetcher = self;
    _lynxView.resourceFetcher = self;
    switch (self.widthMode) {
      case BDLynxViewSizeModeUndefined:
        _lynxView.layoutWidthMode = LynxViewSizeModeUndefined;
        _lynxView.preferredMaxLayoutWidth = self.lynxViewFrame.size.width;
        break;
      case BDLynxViewSizeModeExact:
        _lynxView.layoutWidthMode = LynxViewSizeModeExact;
        _lynxView.preferredLayoutWidth = self.lynxViewFrame.size.width;
        break;
      case BDLynxViewSizeModeMax:
        _lynxView.layoutWidthMode = BDLynxViewSizeModeMax;
        _lynxView.preferredMaxLayoutWidth = self.lynxViewFrame.size.width;
        break;
      default:
        _lynxView.layoutWidthMode = LynxViewSizeModeUndefined;
        _lynxView.preferredMaxLayoutWidth = self.lynxViewFrame.size.width;
        break;
    }
    switch (self.heightMode) {
      case BDLynxViewSizeModeUndefined:
        _lynxView.layoutHeightMode = LynxViewSizeModeUndefined;
        _lynxView.preferredMaxLayoutHeight = self.lynxViewFrame.size.height;
        break;
      case BDLynxViewSizeModeExact:
        _lynxView.layoutHeightMode = LynxViewSizeModeExact;
        _lynxView.preferredLayoutHeight = self.lynxViewFrame.size.height;
        break;
      case BDLynxViewSizeModeMax:
        _lynxView.layoutHeightMode = BDLynxViewSizeModeMax;
        _lynxView.preferredMaxLayoutHeight = self.lynxViewFrame.size.height;
        break;
      default:
        _lynxView.layoutHeightMode = LynxViewSizeModeUndefined;
        _lynxView.preferredMaxLayoutHeight = self.lynxViewFrame.size.height;
        break;
    }
    [_lynxView triggerLayout];
    _lynxView.frame = CGRectMake(0, 0, _lynxView.intrinsicContentSize.width,
                                 _lynxView.intrinsicContentSize.height);
  }
  return _lynxView;
}

- (BDLynxViewClient *)clientDelegate {
  if (!_clientDelegate) {
    _clientDelegate = [[BDLynxViewClient alloc]
        initWithChannel:(self.channel ?: self.params.sourceUrl) ?: @""
             bundlePath:self.params.bundle ?: @""
              sessionID:self.sessionID
          pageStartTime:(CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970) * 1000];
    _clientDelegate.lifeCycleDelegate = self;
  }
  return _clientDelegate;
}

- (NSString *)containerID {
  return self.lynxView.containerID;
}

- (dispatch_block_t)loadImageWithURL:(NSURL *)url
                                size:(CGSize)targetSize
                         contextInfo:(nullable NSDictionary *)contextInfo
                          completion:(LynxImageLoadCompletionBlock)completionBlock {
  if (self.imageLoader) {
    if ([self.imageLoader canRequestURL:url]) {
      __weak __typeof(self) weakSelf = self;
      [self.imageLoader
          requestImage:url
                  size:targetSize
              complete:^(UIImage *img, NSError *error) {
                __strong __typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf.clientDelegate trackLynxRenderPipelineTrigger:@"offline_res_map_start"];
                if (completionBlock) {
                  completionBlock(img, error, url);
                }
              }];
      return ^() {
        [self.lynxDelegate cancelRequestWithURL:url];
      };
    }
  }

  /// 解决图片多宿主操作问题
  if ([self.lynxDelegate respondsToSelector:@selector(loadImageWithURL:
                                                                  size:contextInfo:completion:)]) {
    [self.lynxDelegate loadImageWithURL:url
                                   size:targetSize
                            contextInfo:contextInfo
                             completion:completionBlock];
    return ^() {
      [self.lynxDelegate cancelRequestWithURL:url];
    };
  }

  // 兼容抖音的实现
  if ([self.clientDelegate
          respondsToSelector:@selector(loadImageWithURL:size:contextInfo:completion:)]) {
    return [self.clientDelegate loadImageWithURL:url
                                            size:targetSize
                                     contextInfo:nil
                                      completion:completionBlock];
  }
  return ^() {
    [self.lynxDelegate cancelRequestWithURL:url];
  };
}

- (dispatch_block_t)loadCanvasImageWithURL:(NSURL *)url
                               contextInfo:(nullable NSDictionary *)contextInfo
                                completion:
                                    (nonnull LynxCanvasImageLoadCompletionBlock)completionBlock {
  if (url == nil) {
    return nil;
  }

  if ([self.lynxDelegate respondsToSelector:@selector(bdlynxViewloadTemplateWithUrl:onComplete:)]) {
    [self.lynxDelegate
        bdlynxViewloadTemplateWithUrl:[url absoluteString]
                           onComplete:^(NSData *_Nullable data, NSError *_Nullable error,
                                        NSURL *_Nullable dataPathURL) {
                             if (completionBlock) {
                               completionBlock(data, error, dataPathURL);
                             }
                           }];
    return ^() {
      [self.lynxDelegate cancelRequestWithURL:url];
    };
  } else {
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
}

- (dispatch_block_t)loadResourceWithURL:(NSURL *)url
                                   type:(LynxFetchResType)type
                             completion:(LynxResourceLoadCompletionBlock)completionBlock {
  if (url == nil) {
    return nil;
  }
  if ([self.lynxDelegate respondsToSelector:@selector(bdlynxViewloadTemplateWithUrl:onComplete:)]) {
    [self.lynxDelegate
        bdlynxViewloadTemplateWithUrl:[url absoluteString]
                           onComplete:^(NSData *_Nullable data, NSError *_Nullable error,
                                        NSURL *_Nullable dataPathURL) {
                             if (completionBlock) {
                               completionBlock(NO, data, error, dataPathURL);
                             }
                           }];
    return ^() {
      [self.lynxDelegate cancelRequestWithURL:url];
    };
  } else {
    NSURLSessionDataTask *task = [NSURLSession.sharedSession
          dataTaskWithURL:url
        completionHandler:^(NSData *received, NSURLResponse *response, NSError *error) {
          if (completionBlock) {
            NSURL *responseUrl = [response URL];
            completionBlock(NO, received, error, responseUrl);
          }
        }];
    [task resume];
    return ^() {
      [task cancel];
    };
  }
}

- (NSString *)redirectURL:(NSString *)urlString {
  if ([self.lynxDelegate respondsToSelector:@selector(redirectURL:)]) {
    return [self.lynxDelegate redirectURL:urlString];
  }
  return urlString;
}

- (void)bdlynxViewloadTemplateWithUrl:(NSString *)url onComplete:(LynxTemplateLoadBlock)callback {
  if ([self.lynxDelegate respondsToSelector:@selector(bdlynxViewloadTemplateWithUrl:onComplete:)]) {
    [self.lynxDelegate
        bdlynxViewloadTemplateWithUrl:url
                           onComplete:^(NSData *_Nullable data, NSError *_Nullable error,
                                        NSURL *_Nullable dataPathURL) {
                             if (callback) {
                               if (data != nil) {
                                 callback(data, error);
                               } else {
                                 if (!error) {
                                   error = [NSError
                                       errorWithDomain:kBDLynxTemplateUrlDomain
                                                  code:-1
                                              userInfo:@{
                                                NSLocalizedDescriptionKey : @"Unknown error"
                                              }];
                                 }
                                 if ([self.lynxDelegate
                                         respondsToSelector:@selector(bdlynxViewLoadUrlFailed:)]) {
                                   [self.lynxDelegate bdlynxViewLoadUrlFailed:error];
                                 }
#if DEBUG
                                 __weak typeof(self) weakSelf = self;
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                   [weakSelf toastErrorMessage:[error localizedDescription]
                                                   forDuration:10];
                                 });
#endif
                                 callback(data, error);
                               }
                             }
                           }];
  } else {
    BOOL hasParams = [url rangeOfString:@"?"].location != NSNotFound;
    NSString *seperator = hasParams ? @"&" : @"?";
    NSString *surl =
        !self.params.disableTimeStamp
            ? [url stringByAppendingFormat:@"%@t=%llu", seperator, mach_absolute_time()]
            : url;
    NSURL *nsUrl = [NSURL URLWithString:surl];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession]
          dataTaskWithURL:nsUrl
        completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response,
                            NSError *_Nullable error) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
              if ([self.lynxDelegate respondsToSelector:@selector(bdlynxViewLoadUrlFailed:)]) {
                [self.lynxDelegate bdlynxViewLoadUrlFailed:error];
              }
#if DEBUG
              [self toastErrorMessage:[error localizedDescription] forDuration:10];
#endif
              callback(nil, error);
              return;
            } else if (!data) {
              NSError *error =
                  [NSError errorWithDomain:kBDLynxTemplateUrlDomain
                                      code:-1
                                  userInfo:@{NSLocalizedDescriptionKey : @"Unknown error"}];
              callback(nil, error);
              return;
            } else if (response && [response isKindOfClass:NSHTTPURLResponse.class]) {
              NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
              if (httpResponse.statusCode > 400) {
                NSError *error =
                    [NSError errorWithDomain:kBDLynxTemplateUrlDomain
                                        code:-1
                                    userInfo:@{
                                      NSLocalizedDescriptionKey :
                                          [NSString stringWithFormat:@"Http Code is %ld",
                                                                     (long)httpResponse.statusCode]
                                    }];
                callback(data, error);
                return;
              }
            }
            callback(data, nil);
          });
        }];
    [task resume];
  }
}

- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event {
  UIView *res = [super hitTest:point withEvent:event];
  if ([res isEqual:_lynxView] || [res isEqual:self]) {
    return [_lynxView hitTest:point withEvent:event];
  }
  return res;
}

- (void)updateModuleData:(BDLynxModuleData *)data {
  [BDL_SERVICE(BDLLynxModuleProtocol) updateModuleData:data context:self.containerID];
}

- (void)toastErrorMessage:(NSString *)message forDuration:(NSInteger)duration {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  UIAlertView *toast = [[UIAlertView alloc] initWithTitle:nil
                                                  message:message
                                                 delegate:nil
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil, nil];
  [toast show];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC),
                 dispatch_get_main_queue(), ^{
                   [toast dismissWithClickedButtonIndex:0 animated:YES];
                 });
#pragma clang diagnostic pop
}

// set width and height config in templateRender
- (void)setWidthAndHeightMode:(LynxTemplateRender *)templateRender {
  switch (self.widthMode) {
    case BDLynxViewSizeModeUndefined:
      templateRender.layoutWidthMode = LynxViewSizeModeUndefined;
      templateRender.preferredMaxLayoutWidth = self.lynxViewFrame.size.width;
      break;
    case BDLynxViewSizeModeExact:
      templateRender.layoutWidthMode = LynxViewSizeModeExact;
      templateRender.preferredLayoutWidth = self.lynxViewFrame.size.width;
      break;
    case BDLynxViewSizeModeMax:
      templateRender.layoutWidthMode = LynxViewSizeModeMax;
      templateRender.preferredMaxLayoutWidth = self.lynxViewFrame.size.width;
      break;
    default:
      templateRender.layoutWidthMode = LynxViewSizeModeUndefined;
      templateRender.preferredMaxLayoutWidth = self.lynxViewFrame.size.width;
      break;
  }
  switch (self.heightMode) {
    case BDLynxViewSizeModeUndefined:
      templateRender.layoutHeightMode = LynxViewSizeModeUndefined;
      templateRender.preferredMaxLayoutHeight = self.lynxViewFrame.size.height;
      break;
    case BDLynxViewSizeModeExact:
      templateRender.layoutHeightMode = LynxViewSizeModeExact;
      templateRender.preferredLayoutHeight = self.lynxViewFrame.size.height;
      break;
    case BDLynxViewSizeModeMax:
      templateRender.layoutHeightMode = LynxViewSizeModeMax;
      templateRender.preferredMaxLayoutHeight = self.lynxViewFrame.size.height;
      break;
    default:
      templateRender.layoutHeightMode = LynxViewSizeModeUndefined;
      templateRender.preferredMaxLayoutHeight = self.lynxViewFrame.size.height;
      break;
  }
}

@end

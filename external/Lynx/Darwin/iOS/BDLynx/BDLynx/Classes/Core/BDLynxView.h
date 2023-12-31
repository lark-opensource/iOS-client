//
//  BDLynxView.h
//  BDLynx
//
//  Created by bill on 2020/2/4.
//

#import <UIKit/UIKit.h>
#import "BDLynxBridge.h"

#import "BDLImageLoaderProtocol.h"
#import "BDLynxModuleData.h"
#import "LynxModule.h"

@class LynxView;
@class LynxTemplateRender;
@class BDLynxBridge;
@class LynxViewBuilder;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDLynxViewSizeMode) {
  BDLynxViewSizeModeUndefined = 0,
  BDLynxViewSizeModeExact,
  BDLynxViewSizeModeMax
};

typedef NS_ENUM(NSInteger, BDLynxForceFallbackType) {
  BDLynxForceFallbackTypeUndefined = 0,
  BDLynxForceFallbackTypeH5 = 1,
  BDLynxForceFallbackTypeNative = 2,
};

typedef NS_ENUM(NSInteger, BDLynxCanvasOptimize) {
  BDLynxCanvasOptimizeDefault = 0,
  BDLynxCanvasOptimizeEnable = 1,
  BDLynxCanvasOptimizeDisable = 2,
};

@protocol LynxDynamicComponentFetcher;

@protocol BDLynxClientViewDelegate <NSObject>

@optional
- (void)viewDidChangeIntrinsicContentSize:(CGSize)size;
- (void)viewDidStartLoading;
- (void)viewDidFirstScreen;
- (void)viewDidFinishLoadWithURL:(NSString *)url;
- (void)viewDidUpdate;
- (void)viewDidPageUpdate;
- (void)viewDidRecieveError:(NSError *)error;
- (void)viewDidLoadFailedWithUrl:(NSString *)url error:(NSError *)error;
- (void)viewDidConstructJSRuntime;
- (void)bdlynxViewLoadUrlFailed:(NSError *)error;
- (void)bdlynxViewloadTemplateWithUrl:(NSString *)url
                           onComplete:(LynxCDNResourceLoadCompletionBlock)callback;
- (NSString *)redirectURL:(NSString *)urlString;

/// 自定义图片获取逻辑，解决类似抖音多宿主问题
- (nonnull dispatch_block_t)loadImageWithURL:(nonnull NSURL *)url
                                        size:(CGSize)targetSize
                                 contextInfo:(nullable NSDictionary *)contextInfo
                                  completion:(nonnull LynxImageLoadCompletionBlock)completionBlock;

/// Add Image cancel api
- (void)cancelRequestWithURL:(nonnull NSURL *)url;

@end

@interface BDLynxViewBaseParams : NSObject

@property(nonatomic, copy) NSString *sourceUrl;
@property(nonatomic, copy) NSString *cdnUrl;
@property(nonatomic, copy) NSString *localUrl;
@property(nonatomic, copy) NSString *channel;
@property(nonatomic, copy) NSString *bundle;

@property(nonatomic, copy) NSString *groupID;
@property(nonatomic, copy) NSString *cardID;
@property(nonatomic, copy) NSString *accessKey;
@property(nonatomic, copy) NSString *containerID;

// For Share Group Context
@property(nonatomic, copy) NSString *groupContext;
// For Share Group
@property(nonatomic, strong) NSArray *extraJSPaths;
// for canvas
@property(nonatomic, assign) BOOL enableCanvas;
@property(nonatomic, assign) BDLynxCanvasOptimize canvasOptimize;

@property(nonatomic, assign) BOOL disableAutoExpose;
@property(nonatomic, assign) BOOL enableGetPreHeight;

@property(nonatomic, assign) NSInteger dynamic;

@property(nonatomic, assign) BOOL disableShare;
@property(nonatomic, assign) BOOL disableTimeStamp;
@property(nonatomic, assign) BDLynxForceFallbackType forceFallback;
@property(nonatomic, copy) NSURL *fallbackURL;
@property(nonatomic, strong) id initialProperties;
@property(nonatomic, strong) NSDictionary *globalProps;

// For Monitor report: Bid - businessId
@property(nonatomic, copy) NSString *reportBid;
// For Monitor report: Pid - pageId
@property(nonatomic, copy) NSString *reportPid;

@property(nonatomic, assign) BOOL enableBDLynxModule;

@property(nonatomic, strong) BDLynxModuleData *bdlynxModuleData;

// Default 1.0
@property(nonatomic, assign) CGFloat fontScale;
@property(nonatomic, strong) BDLynxBridge *bdLynxBridge;

@end

@interface BDLynxView : UIView

@property(nonatomic, strong) NSData *data;
@property(nonatomic, strong) NSData *prefetchData;

@property(nonatomic, weak) id<BDLynxClientViewDelegate> lynxDelegate;

@property(nonatomic, copy) NSString *containerID;
@property(nonatomic, strong) LynxView *lynxView;
@property(nonatomic, strong) id<BDLImageLoaderProtocol> imageLoader;
@property(nonatomic, weak) id<LynxDynamicComponentFetcher> dynamicComponentFetcher;

@property(nonatomic, strong) BDLynxViewBaseParams *params;
@property(nonatomic, assign) BDLynxViewSizeMode widthMode;
@property(nonatomic, assign) BDLynxViewSizeMode heightMode;

- (instancetype)initWithFrame:(CGRect)frame;
- (instancetype)initWithFrame:(CGRect)frame
                 builderBlock:(void (^__nullable)(LynxViewBuilder *, NSString *))block;
- (void)loadLynxWithParams:(BDLynxViewBaseParams *)params;
- (void)loadLynxWithParamsRender:(BDLynxViewBaseParams *)params
                          render:(LynxTemplateRender *)lynxTemplateRender;
- (void)reloadWithBaseParams:(BDLynxViewBaseParams *)params;
- (void)updateData:(NSDictionary *)dict;

- (void)registerHandler:(BDLynxBridgeHandler)handler forMethod:(NSString *)method;

/// 根据Lynx 标签name的值获取对应View <image src="{{image}}" class="img" name="xxx"></image>
// prefer using `findViewWithName:` than `viewWithName:`.
// `viewWithName:` will be marked deprecated in 1.6
- (nullable UIView *)viewWithName:(nonnull NSString *)name;
- (nullable UIView *)findViewWithName:(nonnull NSString *)name;

// register instance module
- (void)registerModule:(Class<LynxModule>)module;
- (void)registerModule:(Class<LynxModule>)module param:(nullable id)param;
- (void)registerUI:(Class)ui withName:(NSString *)name;
- (void)registerShadowNode:(Class)node withName:(NSString *)name;

- (void)updateModuleData:(BDLynxModuleData *)data;

@end

NS_ASSUME_NONNULL_END

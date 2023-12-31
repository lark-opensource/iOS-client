//
//  BDXLynxKitProtocol.h
//  BDXServiceCenter-Pods-Aweme
//
//  Created by bill on 2021/3/3.
//

#import <Foundation/Foundation.h>

#import "BDXContext.h"
#import "BDXKitProtocol.h"
#import "BDXServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

// container为LynxView，callback中的code跟BDLynxBridgeStatusCode保持一致
typedef void (^BDXLynxBridgeHandler)(id _Nullable container, NSString *name, NSDictionary *_Nullable params, void (^callback)(NSInteger code, NSDictionary *_Nullable data));

@protocol BDXLynxElement <NSObject>

@property(nonatomic, copy) NSString *lynxElementName;
@property(nonatomic, assign) Class lynxElementClassName;

@end

/**
 * This enum is used to define size measure mode of LynxView.
 * If mode is Undefined, the size will be determined by the content.
 * If mode is Exact, the size will be the size set by outside.
 * If mode is Max, the size will be determined by the content, but not exceed
 * the maximum size.
 */
typedef NS_ENUM(NSInteger, BDXLynxViewSizeMode) { BDXLynxViewSizeModeUndefined = 0, BDXLynxViewSizeModeExact, BDXLynxViewSizeModeMax };

//对接resourceloader，dynamic取值为[0,1,2]代表拉取gecko包时不同的策略
typedef NS_ENUM(NSInteger, BDXDynamicType) {
    BDXGeckoLocal = 0, // 只读取Gecko本地
    BDXGeckoFalcon,    // 读取Gecko(Falcon),若获取到数据则返回并且触发新数据同步,若未能获取数据则尝试新建GurdSyncTask拉取数据
    BDXGeckoGurd,      // 直接尝试新建GurdSyncTask拉取数据
};

@protocol LynxTemplateProvider;
@protocol LynxImageFetcher;
@protocol LynxResourceFetcher;

@interface BDXLynxKitParams : BDXKitParams

// 加载的模版的url, 一般是http开头的链接
@property(nonatomic, copy) NSString *sourceUrl;

@property(nonatomic, copy) NSString *localUrl;

// 离线包对应的accessKey，主要用于对接resourceloader
@property(nonatomic, copy) NSString *accessKey;

// 主模板的channel/bundle
@property(nonatomic, copy) NSString *channel;

@property(nonatomic, copy) NSString *bundle;

// 不读取Gecko下载数据
@property(nonatomic, copy) NSNumber *disableGurd;

// 不读取内置数据
@property(nonatomic, copy) NSNumber *disableBuildin;

// 具有相同group名字的lynxview会共享js context
@property(nonatomic, copy) NSString *groupContext;

// 共享js context的时候，需要额外加载的js文件，一般是一些通用的js库之类的
@property(nonatomic, strong) NSArray *extraJSPaths;

// 这个主要用于对接resourceloader，dynamic取值为[0,1,2]代表拉取gecko包时不同的策略
@property(nonatomic, assign) BDXDynamicType dynamic;

// 是否禁用共享js context
@property(nonatomic, assign) BOOL disableShare;

// 是否启用 canvas
@property(nonatomic, assign) BOOL enableCanvas;

// 前端的data的初始化数据
@property(nonatomic, strong) id initialProperties;

// initialProperties 的别名
@property(nonatomic, copy) NSString* initialPropertiesState;

// 前端可以通过this.data.__globalProp或者lynx.globalProps获取
@property(nonatomic, strong) id globalProps; // type: NSDictionary or LynxTemplateData

// lynxview页面的布局策略
@property(nonatomic, assign) BDXLynxViewSizeMode widthMode;
@property(nonatomic, assign) BDXLynxViewSizeMode heightMode;

// lynx模版的二进制数据，如果没有指定sourceURL，会使用templateData的数据来加载lynx模版
@property(nonatomic, strong) NSData *templateData;

// lynx query参数
@property(nonatomic, copy) NSDictionary *queryItems;

@property(nonatomic, weak) id<LynxTemplateProvider> templateProvider;
@property(nonatomic, weak) id<LynxImageFetcher> imageFetcher;
@property(nonatomic, weak) id<LynxResourceFetcher> resourceFetcher;

@end

@protocol BDXLynxViewProtocol;
@protocol BDXLynxDevtoolProtocol;

@protocol BDXLynxKitProtocol <BDXServiceProtocol>

// Lynx初始化
- (void)initLynxKit;

#if __has_include(<Lynx/LynxDebugger.h>)

// LynxDevtool代理，使用LynxDevtool需要实现BDXLynxDevtoolProtocol
@property(nonatomic) NSMutableSet<id <BDXLynxDevtoolProtocol>>* devtoolDelegateSet;

/**
 设置devtoolDelegate, 处理openDevtoolCard回调，处理后返回YES
 */
- (void)addDevtoolDelegate:(id <BDXLynxDevtoolProtocol>)devtoolDelegate;

/**
 * 初始化LynxDevtool，业务方在处理schema处调用此方法
 * options参数示例：@{@"App" : @"LynxExample", @"AppVersion" : @"1.0.0"}
 */
- (BOOL)enableLynxDevtool:(NSURL *)url withOptions:(NSDictionary *)options;
#endif

/// 创建kitView，后面可以通过kitVIew的configWithContext来进行初始化
/// @param frame view大小
- (nullable UIView<BDXLynxViewProtocol> *)createViewWithFrame:(CGRect)frame;

/// 创建kitView
/// @param frame view大小
/// @param params BDXLynxKitParams
- (nullable UIView<BDXLynxViewProtocol> *)createViewWithFrame:(CGRect)frame params:(BDXLynxKitParams *)params;

/// 预取资源
/// @param sourceURLs 资源url
- (void)prefetchResourceWithURLs:(NSArray<NSString *> *)sourceURLs;

@end

@protocol BDXLynxViewProtocol <BDXKitViewProtocol>

// 注册Handler
- (void)registerHandler:(BDXLynxBridgeHandler)handler forMethod:(NSString *)method;

// 注册 LynxModule
- (void)registerModule:(Class)module;
- (void)registerModule:(Class)module param:(nullable id)param;

// 注册Lynx ShadowNode
- (void)registerShadowNode:(Class)node withName:(NSString *)name;

@optional

- (nullable UIView*)findViewWithName:(nonnull NSString*)name;

@end

#if __has_include(<Lynx/LynxDebugger.h>)
@protocol BDXLynxDevtoolProtocol <NSObject>

- (BOOL)openDevtoolCard:(NSString *)url;

@end
#endif

NS_ASSUME_NONNULL_END

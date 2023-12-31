//
//  BDPRouteMediator.h
//  Timor
//
//  Created by yin on 2018/9/4.
//

#import <Foundation/Foundation.h>
#import "BDPUniqueID.h"


@class BDPWebViewComponent;

@protocol BDPRouteMediatorProtocol <NSObject>

- (BOOL)needUpdateAlertForUniqueID:(BDPUniqueID *)uniqueID;

- (void)onWebviewCreate:(BDPUniqueID *_Nullable)uniqueID webview:(BDPWebViewComponent *_Nullable)webview;

- (void)onWebviewDestroy:(BDPUniqueID *_Nullable)uniqueID webview:(BDPWebViewComponent *_Nullable)webview;

- (NSMutableURLRequest *)appMetaRequestWithURL:(NSString *)url params:(NSDictionary *)params uniqueID:(BDPUniqueID * _Nullable)uniqueID;

- (NSDictionary *)validWifiSecureStrength;

@end


@interface BDPRouteMediator : NSObject

///mina 止血版本配置
@property (nonatomic, copy) NSDictionary * (^configSchemeParameterAppListFetch)();
-(NSString * _Nullable )leastVersionLaunchParams:(BDPUniqueID*) uniqueId;

/// jsapi是否参与灰度
@property (nonatomic, copy) BOOL (^isJSAPIInAllowlist)(NSString *jsapiName);
/// App是否参与灰度
@property (nonatomic, copy) BOOL (^isAppTestForUniqueID)(BDPUniqueID *uniqueID);

/// 判断小程序是否需要检验域名白名单
@property (nonatomic, copy) BOOL (^checkDomainsForUniqueID)(BDPUniqueID *uniqueID);

@property (nonatomic, copy) BOOL (^allowHttpForUniqueID)(BDPUniqueID *uniqueID);

/// fix bug: 后续删掉
@property (nonatomic, copy) BOOL (^setStorageLimitCheck)();

@property (nonatomic, weak) id<BDPRouteMediatorProtocol> delegate;

/// 灰度逻辑
@property (nonatomic, copy) BOOL (^getSystemInfoHeightInWhiteListForUniqueID)(BDPUniqueID *uniqueID);
@property (nonatomic, copy) BOOL (^isVideoAvoidSameLayerRenderForUniqueID)(BDPUniqueID *uniqueID);

/// 单例
+ (instancetype _Nullable )sharedManager;

+ (void)onWebviewCreate:(BDPUniqueID *_Nullable)uniqueID webview:(BDPWebViewComponent *_Nullable)webview;

+ (void)onWebviewDestroy:(BDPUniqueID *_Nullable)uniqueID webview:(BDPWebViewComponent *_Nullable)webview;

+ (BOOL)needUpdateAlertForUniqueID:(BDPUniqueID *)uniqueID;

+ (nonnull NSMutableURLRequest *)appMetaRequestWithURL:(NSString *)url params:(NSDictionary *)params uniqueID:(BDPUniqueID *)uniqueID;

+ (NSDictionary *)validWifiSecureStrength;

@end

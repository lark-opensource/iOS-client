//
//  BulletXDefines.m
//  BulletX-Pods-Aweme
//
//  Created by bill on 2020/9/27.
//

#import "BulletXDefines.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

#pragma mark - ContextInfoKey
BDXContextKey const kBulletContextBulletXEnvKey = @"__bulletEnv";
BDXContextKey const kBulletContextSessionId = @"__sessionId";

BDXContextKey const kBulletContextGlobalPropsKey = @"__globalProps";
BDXContextKey const kBulletContextGlobalPropsKeysKey = @"__globalPropsKeys";
BDXContextKey const kBulletContextAccessKey = @"__accessKey";

BDXContextKey const kBulletContextResourceLoaderSettingKey = @"__resourceLoaderSetting";
BDXContextKey const kBulletContextPreloadImageUrlsKey = @"__resourceLoaderPreloadImageUrls";

// following 4 key will be deprecated
BDXContextKey const kBulletContextAllowListKey = @"__allowList";
BDXContextKey const kBulletContextBlockListKey = @"__blockList";
BDXContextKey const kBulletContextPrefixKey = @"__prefix";
BDXContextKey const kBulletContextInterceptorEnableKey = @"__prefixEnable";

BDXContextKey const kBulletContextPresetLocalURLKey = @"__presetLocalURL";
BDXContextKey const kBulletContextControllerKey = @"controller";
BDXContextKey const kBulletContextMetaResourceKey = @"__gurdResource";

BDXContextKey const kBulletContextAdInfoKey = @"__adInfo";
BDXContextKey const kBulletContextXBridgeKey = @"__bullet_xbridge";

#pragma mark - WebView Setting
BDXContextKey const kBulletContextWebViewConfig = @"__webViewConfig";
BDXContextKey const kBulletContextAdWebViewInitialization = @"__adWebViewInitialization";
BDXContextKey const kBulletContextWebViewPrefetchBusinessKey = @"__webViewPrefetchBusinessKey";
BDXContextKey const kBulletContextWebViewADAutoJumpAllowListKey = @"__webViewADAllowList";
BDXContextKey const kBulletContextWebViewADBlockListKey = @"__webViewADBlockList";
BDXContextKey const kBulletContextWebViewADClickIntervalKey = @"__webViewADClickInterval";

#pragma mark - Monitor
BDXContextKey const kBulletContextAIDKey = @"__aid";
BDXContextKey const kBulletContextDefaultAID = @"688";
BDXContextKey const kBulletContextMonitorConfigKey = @"__monitorConfig";
BDXContextKey const kBulletResourceFromKey = @"__kBulletResourceFromKey";

#pragma mark - Engine
BDXContextKey const kBulletXContextEngineType = @"engine_type";
BDXContextKey const kBulletXContextEngineTypeWeb = @"web";
BDXContextKey const kBulletXContextEngineTypeLynx = @"lynx";
BDXContextKey const kBulletXLifeCycleMonitorExtContextSourceFromKey = @"source_from";

#pragma mark - EventKey

BulletXEventKey const kBulletXEventContainerDidReceiveFirstLoad = @"bullet_container_receiveFirstLoad";

BulletXEventKey const kBulletXEventContainerDidRender = @"bullet_container_render";

BulletXEventKey const kBulletXEventContainerDidAppear = @"bullet_container_appear";

BulletXEventKey const kBulletXEventContainerDidDisappear = @"bullet_container_disappear";

BulletXEventKey const kBulletXEventAppDidBecomeActive = @"bullet_app_become_active";

BulletXEventKey const kBulletXEventAppWillResignActive = @"bullet_app_resign_active";

BulletXEventKey const kBulletXEventContainerDidLoadFinished = @"bullet_container_load_finished";

#pragma mark - Detail Monitor
BDXContextKey const kBulletXLoadDetailMonitorKey = @"kBulletXLoadDetailMonitorKey";

#pragma mark - NotificationKey

BulletXNotificationKey const kBulletXNotificationConfigireStatusBar = @"XBridgeConfigureStatusBarNotification";

#pragma mark - Tracker
BDXContextKey const kBulletContextAppIDKey = @"__app_id";

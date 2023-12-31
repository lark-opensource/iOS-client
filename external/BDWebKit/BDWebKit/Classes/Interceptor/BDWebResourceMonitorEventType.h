//
//  BDWebResourceMonitorEventType.h
//  Pods
//
//  Created by bytedance on 4/18/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Monitor Event Type
extern NSString *const kBDWebViewMonitorResLoaderPerfEventType;
extern NSString *const kBDWebViewMonitorResLoaderPerfTemplateEventType;
extern NSString *const kBDWebViewMonitorResLoaderErrorEventType;
extern NSString *const kBDWebViewMonitorResLoaderErrorTemplateEventType;

// 资源加载器描述 - res_loader_info
extern NSString *const kBDWebviewResLoaderInfoKey;

// x_resource_loader/falcon/forest
extern NSString *const kBDWebviewResLoaderNameKey;
extern NSString *const kBDWebviewResLoaderVersionKey;

// 资源描述 - res_info
extern NSString *const kBDWebviewResInfoKey;

extern NSString *const kBDWebviewResSrcKey;
extern NSString *const kBDWebviewResVersionKey;
// TODO: res-id 暂时不确认对应哪种信息(用于query不同导致url无法聚合的场景)
extern NSString *const kBDWebviewResIDKey;

extern NSString *const kBDWebviewGeckoChannelKey;
extern NSString *const kBDWebviewGeckoBundleKey;
extern NSString *const kBDWebviewGeckoAccessKeyKey;
// 是否同步等待Gecko更新
extern NSString *const kBDWebviewGeckoSyncUpdateKey;
// 是否开启CDN Cache
extern NSString *const kBDWebviewCDNCacheEnableKey;

// 明确资源场景: lynx_template/lynx_child_resource/lynx_external_js/web_main_document/web_child_resource/other
extern NSString *const kBDWebviewResSceneKey;
// 明确资源类型: html/js/css/jpeg
extern NSString *const kBDWebviewResTypeKey;
// res-from value will be gecko/gecko_update/cdn_cache/cdn/builtin/offline
extern NSString *const kBDWebviewResFromKey;
extern NSString *const kBDWebviewIsMemoryKey;

// 预加载相关埋点
extern NSString *const kBDWebviewIsPreloadKey;
extern NSString *const kBDWebviewIsPreloadedKey;
extern NSString *const kBDWebviewIsRequestReusedKey;
extern NSString *const kBDWebviewEnableRequestReuseKey;

// 明确资源加载状态: success/failed
extern NSString *const kBDWebviewResStateKey;
extern NSString *const kBDWebviewResTraceIDKey;
extern NSString *const kBDWebviewResSizeKey;

// Pipeline队列: ['gecko', 'cdn', 'builtin']
extern NSString *const kBDWebviewFetcherListKey;

// Gecko配置信息来源: remote_setting/client_config/custom_config
extern NSString *const kBDWebviewGeckoConfigFromKey;
extern NSString *const kBDWebviewExtraKey;

// key-str for kBDWebviewExtraKey start
extern NSString *const kBDWebviewExtraHTTPResponseHeadersKey;
// end.

// 资源加载性能描述 - res_load_perf
extern NSString *const kBDWebviewResLoadPerfKey;

extern NSString *const kBDWebviewResLoadStartKey;
extern NSString *const kBDWebviewResLoadFinishKey;

// setting、config、pipeline 解析耗时
extern NSString *const kBDWebviewInitStartKey;
extern NSString *const kBDWebviewInitFinishKey;

extern NSString *const kBDWebviewMemoryStartKey;
extern NSString *const kBDWebviewMemoryFinishKey;

extern NSString *const kBDWebviewGeckoTotalStartKey;
extern NSString *const kBDWebviewGeckoTotalFinishKey;
extern NSString *const kBDWebviewGeckoStartKey;
extern NSString *const kBDWebviewGeckoFinishKey;
extern NSString *const kBDWebviewGeckoUpdateStartKey;
extern NSString *const kBDWebviewGeckoUpdateFinishKey;

extern NSString *const kBDWebviewCDNTotalStartKey;
extern NSString *const kBDWebviewCDNTotalFinishKey;
extern NSString *const kBDWebviewCDNCacheStartKey;
extern NSString *const kBDWebviewCDNCacheFinishKey;
extern NSString *const kBDWebviewCDNStartKey;
extern NSString *const kBDWebviewCDNFinishKey;

extern NSString *const kBDWebviewBuiltinStartKey;
extern NSString *const kBDWebviewBuiltinFinishKey;

// 资源加载错误描述
extern NSString *const kBDWebviewResLoadErrorKey;

extern NSString *const kBDWebviewResLoaderErrorCodeKey;
extern NSString *const kBDWebviewResErrorMsgKey;

extern NSString *const kBDWebviewNetLibraryErrorCodeKey;
extern NSString *const kBDWebviewHttpStatusCodeKey;

extern NSString *const kBDWebviewGeckoLibraryReadErrorCodeKey;
extern NSString *const kBDWebviewGeckoLibraryReadErrorMsgKey;
extern NSString *const kBDWebviewGeckoLibraryUpdateErrorCodeKey;
extern NSString *const kBDWebviewGeckoLibraryUpdateErrorMsgKey;

/**
    Integer
    1. disabled_by_config
    2. failed_by_invalid_access_key
    3. failed_by_invalid_channel_bundle
    4. failed_by_channel_dir_empty
    5. failed_by_file_not_exist_and_sync_wait_gecko_update_failed
    6. failed_by_file_not_exist_and_not_wait_gecko_update
**/
extern NSString *const kBDWebviewGeckoErrorCodeKey;
extern NSString *const kBDWebviewGeckoErrorMsgKey;
// 用于RL自定义设置gecko config异常时的信息,方便定位问题
extern NSString *const kBDWebviewGeckoConfigErrorMsgKey;

extern NSString *const kBDWebviewCDNCacheErrorMsgKey;
extern NSString *const kBDWebviewCDNErrorMsgKey;
extern NSString *const kBDWebviewBuiltinErrorMsgKey;


NS_ASSUME_NONNULL_END

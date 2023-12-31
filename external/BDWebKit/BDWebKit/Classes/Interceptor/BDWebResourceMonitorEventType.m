//
//  BDWebResourceMonitorEventType.m
//  BDAlogProtocol
//
//  Created by bytedance on 4/18/22.
//

#import "BDWebResourceMonitorEventType.h"

NSString *const kBDWebViewMonitorResLoaderPerfEventType = @"res_loader_perf";
NSString *const kBDWebViewMonitorResLoaderPerfTemplateEventType = @"res_loader_perf_template";
NSString *const kBDWebViewMonitorResLoaderErrorEventType = @"res_loader_error";
NSString *const kBDWebViewMonitorResLoaderErrorTemplateEventType = @"res_loader_error_template";

// 资源加载器描述 - res_loader_info
NSString *const kBDWebviewResLoaderInfoKey = @"res_loader_info";

NSString *const kBDWebviewResLoaderNameKey = @"res_loader_name";
NSString *const kBDWebviewResLoaderVersionKey = @"res_loader_version";

// 资源描述 - res_info
NSString *const kBDWebviewResInfoKey = @"res_info";

NSString *const kBDWebviewResSrcKey = @"res_src";
NSString *const kBDWebviewResVersionKey = @"res_version";
NSString *const kBDWebviewResIDKey = @"res_id";

NSString *const kBDWebviewGeckoChannelKey = @"gecko_channel";
NSString *const kBDWebviewGeckoBundleKey = @"gecko_bundle";
NSString *const kBDWebviewGeckoAccessKeyKey = @"gecko_access_key";
NSString *const kBDWebviewGeckoSyncUpdateKey = @"gecko_sync_update";
NSString *const kBDWebviewCDNCacheEnableKey = @"cdn_cache_enable";

NSString *const kBDWebviewResSceneKey = @"res_scene";
NSString *const kBDWebviewResTypeKey = @"res_type";
NSString *const kBDWebviewResFromKey = @"res_from";
NSString *const kBDWebviewIsMemoryKey = @"is_memory";
NSString *const kBDWebviewResStateKey = @"res_state";
NSString *const kBDWebviewResTraceIDKey = @"res_trace_id";
NSString *const kBDWebviewResSizeKey = @"res_size";
NSString *const kBDWebviewFetcherListKey = @"fetcher_list";
NSString *const kBDWebviewGeckoConfigFromKey = @"gecko_config_from";
NSString *const kBDWebviewExtraKey = @"extra";

// preload related properties
NSString *const kBDWebviewIsPreloadKey = @"is_preload";
NSString *const kBDWebviewIsPreloadedKey = @"is_preloaded";
NSString *const kBDWebviewIsRequestReusedKey = @"is_request_reused";
NSString *const kBDWebviewEnableRequestReuseKey = @"enable_request_reuse";

// key-str for kBDWebviewExtraKey start
NSString *const kBDWebviewExtraHTTPResponseHeadersKey = @"http_response_headers";
// end.

// 资源加载性能描述 - res_load_perf
NSString *const kBDWebviewResLoadPerfKey = @"res_load_perf";

NSString *const kBDWebviewResLoadStartKey = @"res_load_start";
NSString *const kBDWebviewResLoadFinishKey = @"res_load_finish";

NSString *const kBDWebviewInitStartKey = @"init_start";
NSString *const kBDWebviewInitFinishKey = @"init_finish";

NSString *const kBDWebviewMemoryStartKey = @"memory_start";
NSString *const kBDWebviewMemoryFinishKey = @"memory_finish";

NSString *const kBDWebviewGeckoTotalStartKey = @"gecko_total_start";
NSString *const kBDWebviewGeckoTotalFinishKey = @"gecko_total_finish";
NSString *const kBDWebviewGeckoStartKey = @"gecko_start";
NSString *const kBDWebviewGeckoFinishKey = @"gecko_finish";
NSString *const kBDWebviewGeckoUpdateStartKey = @"gecko_update_start";
NSString *const kBDWebviewGeckoUpdateFinishKey = @"gecko_update_finish";

NSString *const kBDWebviewCDNTotalStartKey = @"cdn_total_start";
NSString *const kBDWebviewCDNTotalFinishKey = @"cdn_total_finish";
NSString *const kBDWebviewCDNCacheStartKey = @"cdn_cache_start";
NSString *const kBDWebviewCDNCacheFinishKey = @"cdn_cache_finish";
NSString *const kBDWebviewCDNStartKey = @"cdn_start";
NSString *const kBDWebviewCDNFinishKey = @"cdn_finish";

NSString *const kBDWebviewBuiltinStartKey = @"builtin_start";
NSString *const kBDWebviewBuiltinFinishKey = @"builtin_finish";

// 资源加载错误描述
NSString *const kBDWebviewResLoadErrorKey = @"res_load_error";

NSString *const kBDWebviewResLoaderErrorCodeKey = @"res_loader_error_code";
NSString *const kBDWebviewResErrorMsgKey = @"res_error_msg";

NSString *const kBDWebviewNetLibraryErrorCodeKey = @"net_library_error_code";
NSString *const kBDWebviewHttpStatusCodeKey = @"http_status_code";

NSString *const kBDWebviewGeckoLibraryReadErrorCodeKey = @"gecko_library_read_error_code";
NSString *const kBDWebviewGeckoLibraryReadErrorMsgKey = @"gecko_library_read_error_msg";
NSString *const kBDWebviewGeckoLibraryUpdateErrorCodeKey = @"gecko_library_update_error_code";
NSString *const kBDWebviewGeckoLibraryUpdateErrorMsgKey = @"gecko_library_update_error_msg";

NSString *const kBDWebviewGeckoErrorCodeKey = @"gecko_error_code";
NSString *const kBDWebviewGeckoErrorMsgKey = @"gecko_error_msg";
NSString *const kBDWebviewGeckoConfigErrorMsgKey = @"gecko_config_error_msg";

NSString *const kBDWebviewCDNCacheErrorMsgKey = @"cdn_cache_error_msg";
NSString *const kBDWebviewCDNErrorMsgKey = @"cdn_error_msg";
NSString *const kBDWebviewBuiltinErrorMsgKey = @"builtin_error_msg";

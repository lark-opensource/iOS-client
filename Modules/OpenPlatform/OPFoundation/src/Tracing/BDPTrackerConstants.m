//
//  BDPTrackerConstants.m
//  Timor
//
//  Created by 维旭光 on 2018/12/17.
//

#import "BDPTrackerConstants.h"

// 通用参数
NSString * const BDPTrackerParamSpecialKey = @"_param_for_special";
NSString * const BDPTrackerAppIDKey = @"app_id";
NSString * const BDPTrackerApplicationIDKey = @"application_id";
NSString * const BDPTrackerAppTypeKey = @"app_type";
NSString * const BDPTrackerVersionTypeKey = @"version_type";
NSString * const BDPTrackerIdentifierKey = @"identifier";
NSString * const BDPTrackerMPNameKey = @"app_name";
NSString * const BDPTrackerLaunchFromKey = @"launch_from";
NSString * const BDPTrackerLibVersionKey = @"js_version";
NSString * const BDPTrackerLibGreyHashKey = @"js_grey_hash";
NSString * const BDPTrackerMPGIDKey = @"mp_gid";
NSString * const BDPTrackerLocationKey = @"location";
NSString * const BDPTrackerBizLocationKey = @"biz_location";
NSString * const BDPTrackerBDPLogKey = @"bdp_log";
NSString * const BDPTrackerSceneKey = @"scene";
NSString * const BDPTrackerSceneTypeKey = @"scene_type";
NSString * const BDPTrackerSubSceneKey = @"sub_scene";
NSString * const BDPTrackerJSEngineVersion = @"js_engine_version";
NSString * const BDPTrackerMPVersion = @"app_version";
NSString * const BDPTrackerTraceID = @"trace_id";
NSString * const BDPTrackerCurrentPagePathKey = @"current_page_path";
NSString * const BDPTrackerCurrentPageQueryKey = @"current_page_query";
NSString * const BDPTrackerSolutionIdKey = @"solution_id";

// Result Type
NSString * const BDPTrackerResultTypeKey = @"result_type";
NSString * const BDPTrackerResultSucc = @"success";
NSString * const BDPTrackerResultFail = @"fail";
NSString * const BDPTrackerResultCancel = @"cancel";
NSString * const BDPTrackerResultNoUpdate = @"no_update";
NSString * const BDPTrackerResultNeedUpdate = @"need_update";
NSString * const BDPTrackerResultTimeout = @"timeout";

// Request Type
NSString * const BDPTrackerRequestTypeKey = @"request_type";
NSString * const BDPTrackerRequestUnknown = @"unknown";
NSString * const BDPTrackerRequestNormal = @"normal";
NSString * const BDPTrackerRequestAsync = @"async";
NSString * const BDPTrackerRequestPreload = @"preload";
NSString * const BDPTrackerRequestPreloadWithExit = @"preloadWithExit";

// Duration
NSString * const BDPTrackerDurationKey = @"duration";
NSString * const BDPTrackerFromAppLaunchStartDurationKey = @"from_app_launch_start_duration";

// Page Path
NSString * const BDPTrackerPagePathKey = @"page_path";
NSString * const BDPTrackerPageDarkMode = @"page_dark_mode";
NSString * const BDPTrackerPageDisableSetDark = @"page_disable_set_dark_ininit";

//URL
NSString * const BDPTrackerURLKey = @"request_url";
NSString * const BDPTrackerHostKey = @"request_host";

// Version
NSString * const BDPTrackerLatestVersionKey = @"mp_latest_version";
NSString * const BDPTrackerCurrentVersionKey = @"mp_current_version";

// Error
NSString * const BDPTrackerErrorMsgKey = @"error_msg";

// 页面退出类型
NSString * const BDPTrackerExitCloseBtn = @"close_btn";
NSString * const BDPTrackerExitNewPage = @"new_page";
NSString * const BDPTrackerExitShare = @"mp_share";
NSString * const BDPTrackerExitLogin = @"login_window";

// 计算事件primary key, 确保不重复
NSString * const BDPTrackerPKEnter = @"enter_exit";
NSString * const BDPTrackerPKDownload = @"download";
NSString * const BDPTrackerPKLoad = @"load";
NSString * const BDPTrackerPKLaunch = @"launch";
NSString * const BDPTrackerPKAppLibJSLoad = @"app_lib_js_load";
NSString * const BDPTrackerPKCPJSLoad = @"cp_js_load";
NSString * const BDPTrackerPKWebViewRender = @"webview_render";
NSString * const BDPTrackerPKLogin = @"login";
NSString * const BDPTrackerPKUserInfo = @"user_info";
NSString * const BDPTrackerPKInit = @"init";
NSString * const BDPTrackerPKPageStay = @"page_enter_stay";
NSString * const BDPTrackerPKDomReady = @"load_domready";

// H5 标记
NSString *const BDPTrackerH5Version = @"is_h5_version";

// 埋点标记
NSString * const BDPTrackerExitType = @"exit_type";


// 启动状态
// 加载初始化
NSString * const BDPTrackerLSLoadInit = @"load_init";
// meta请求中
NSString * const BDPTrackerLSMetaRequesting = @"meta_requesting";
// 包下载中
NSString * const BDPTrackerLSPKGDownloading = @"pkg_downloading";
// 基础库加载中
NSString * const BDPTrackerLSLibJSLoading = @"lib_js_loading";
// app-service.js或game.js加载中
NSString * const BDPTrackerLSCPJSLoading = @"cp_js_loading";
// 渲染中
NSString * const BDPTrackerLSRendering = @"rendering";

/// 包压缩方式
NSString * const BDPTrackCompressType = @"pkg_compress_type";

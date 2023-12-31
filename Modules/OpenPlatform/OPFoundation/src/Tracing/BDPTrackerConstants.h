//
//  BDPTrackerConstants.h
//  Timor
//
//  Created by 维旭光 on 2018/12/17.
//

#import <Foundation/Foundation.h>

#define BDPTrackerApp [NSString stringWithFormat:@"%@%@%@" , @"mic", @"ro_a", @"pp"]
#define BDPTrackerSDKVersionKey [NSString stringWithFormat:@"%@%@%@" , @"min", @"iapp_", @"sdk_version"]

// 通用参数
extern NSString * const BDPTrackerParamSpecialKey;
extern NSString * const BDPTrackerAppIDKey;
extern NSString * const BDPTrackerApplicationIDKey;
extern NSString * const BDPTrackerAppTypeKey;
extern NSString * const BDPTrackerVersionTypeKey;
extern NSString * const BDPTrackerIdentifierKey;
extern NSString * const BDPTrackerMPNameKey;
extern NSString * const BDPTrackerLaunchFromKey;
extern NSString * const BDPTrackerLibVersionKey;
extern NSString * const BDPTrackerLibGreyHashKey;
extern NSString * const BDPTrackerMPGIDKey;
extern NSString * const BDPTrackerLocationKey;
extern NSString * const BDPTrackerBizLocationKey;
extern NSString * const BDPTrackerBDPLogKey;
extern NSString * const BDPTrackerSceneKey;
extern NSString * const BDPTrackerSceneTypeKey;
extern NSString * const BDPTrackerSubSceneKey;
extern NSString * const BDPTrackerCurrentPagePathKey;
extern NSString * const BDPTrackerCurrentPageQueryKey;
// JSV8引擎版本号,为对齐Android通用参数，防止TEA平台显示为null，ios传空字符串
extern NSString * const BDPTrackerJSEngineVersion;
extern NSString * const BDPTrackerMPVersion;
extern NSString * const BDPTrackerTraceID;
extern NSString * const BDPTrackerSolutionIdKey;

// Result Type
extern NSString * const BDPTrackerResultTypeKey;
extern NSString * const BDPTrackerResultSucc;
extern NSString * const BDPTrackerResultFail;
extern NSString * const BDPTrackerResultCancel;
extern NSString * const BDPTrackerResultNoUpdate;
extern NSString * const BDPTrackerResultNeedUpdate;
extern NSString * const BDPTrackerResultTimeout;

// Request Type
extern NSString * const BDPTrackerRequestTypeKey;
extern NSString * const BDPTrackerRequestUnknown;
extern NSString * const BDPTrackerRequestNormal;
extern NSString * const BDPTrackerRequestAsync;
extern NSString * const BDPTrackerRequestPreload;
extern NSString * const BDPTrackerRequestPreloadWithExit;

// Duration
extern NSString * const BDPTrackerDurationKey;
extern NSString * const BDPTrackerPagePathKey;
extern NSString * const BDPTrackerFromAppLaunchStartDurationKey;
extern NSString * const BDPTrackerPageDarkMode;
extern NSString * const BDPTrackerPageDisableSetDark;

// URL
extern NSString * const BDPTrackerURLKey;
extern NSString * const BDPTrackerHostKey;

// Version
extern NSString * const BDPTrackerLatestVersionKey;
extern NSString * const BDPTrackerCurrentVersionKey;

// Error
extern NSString * const BDPTrackerErrorMsgKey;

// 页面退出类型
extern NSString * const BDPTrackerExitCloseBtn;
extern NSString * const BDPTrackerExitNewPage;
extern NSString * const BDPTrackerExitShare;
extern NSString * const BDPTrackerExitLogin;

// 计算事件primary key
extern NSString * const BDPTrackerPKEnter;
extern NSString * const BDPTrackerPKDownload;
extern NSString * const BDPTrackerPKLoad;
extern NSString * const BDPTrackerPKLaunch;
extern NSString * const BDPTrackerPKAppLibJSLoad;
extern NSString * const BDPTrackerPKCPJSLoad;
extern NSString * const BDPTrackerPKWebViewRender;
extern NSString * const BDPTrackerPKLogin;
extern NSString * const BDPTrackerPKUserInfo;
extern NSString * const BDPTrackerPKInit;
extern NSString * const BDPTrackerPKPageStay;
extern NSString * const BDPTrackerPKDomReady;

// H5 标示
extern NSString *const BDPTrackerH5Version;

// 埋点标记
extern NSString * const BDPTrackerExitType;

// 启动状态
// 加载初始化
extern NSString * const BDPTrackerLSLoadInit;
// meta请求中
extern NSString * const BDPTrackerLSMetaRequesting;
// 包下载中
extern NSString * const BDPTrackerLSPKGDownloading;
// 基础库加载中
extern NSString * const BDPTrackerLSLibJSLoading;
// app-service.js加载中
extern NSString * const BDPTrackerLSCPJSLoading;
// 渲染中
extern NSString * const BDPTrackerLSRendering;

/// 包压缩方式
extern NSString * const BDPTrackCompressType;

//
//  TTMicroApp.h
//  TTMicroApp
//
//  Created by 武嘉晟 on 2020/5/7.
//  TTMicroApp/TTMicroApp-Swift.h 文件会自动依赖这个文件，如果出现TTMicroApp-Swift.h找不到OC的内容，在此补充内容

#ifndef TTMicroApp_h
#define TTMicroApp_h

// TTMicroApp-Swift.h 中找不到的类
#import <ECOInfra/NSString+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import "BDPTaskManager.h"
#import <OPPluginManagerAdapter/BDPJSBridgeBase.h>
#import <OPFoundation/BDPModuleProtocol.h>
#import "BDPPackageContext.h"
#import <OPFoundation/BDPJSBridgeProtocol.h>
#import "BDPWebView.h"
#import "BDPJSRuntime.h"
#import "OPMicroAppJSRuntime.h"
#import "OPJSEngineUtilsService.h"

#import "BDPPrivacyAccessNotifier.h"
#import "BDPAppPageController.h"
#import "OPLoadingView.h"
#import <ECOInfra/OPError.h>
#import "OPNoticeView.h"
#import "OPNoticeManager.h"
#import "BDPAppController.h"
#import "BDPPerformanceProfileManager.h"
#import <OPPluginManagerAdapter/OPBridgeRegisterOpt.h>
#import <OPFoundation/TMASessionManager.h>
#import <OPFoundation/BDPRouteMediator.h>

// TTMicroApp-Swift.h 中找不到的 protocol
@protocol BDPEngineProtocol;
@protocol BDPJSBridgeAuthorizationProtocol;
@protocol BDPJSBridgeEngineProtocol;
@protocol BDPModuleProtocol;
@protocol BDPPkgFileManagerHandleProtocol;

@class BDPWebView;

// TTMicroApp-Swift.h 中找不到的 typedef
/// 包开始下载回调
typedef void(^BDPPackageDownloaderBegunBlock)(id<BDPPkgFileManagerHandleProtocol> _Nullable packageReader);

/// 包下载进度回调
typedef void(^BDPPackageDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL);

/// 包下载完成回调
typedef void(^BDPPackageDownloaderCompletedBlock)(OPError * _Nullable error, BOOL cancelled, id<BDPPkgFileManagerHandleProtocol> _Nullable packageReader);

#endif /* TTMicroApp_h */

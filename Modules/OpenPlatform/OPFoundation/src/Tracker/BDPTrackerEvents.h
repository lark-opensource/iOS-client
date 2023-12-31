//
//  BDPTrackerEvents.h
//  Timor
//
//  Created by 维旭光 on 2019/8/11.
//
//  埋点事件列表文件，未来逐步把所有埋点事件统一定义在此，便于统一梳理

#import <Foundation/Foundation.h>

// 小程序状态监控
extern NSString * const BDPTEPageLoadStart;
extern NSString * const BDPTEPageLoadResult;
extern NSString * const BDPTEWebviewInvalidDomain;
extern NSString * const BDPTEVideoComponentError;

// 头条搜索排序模型埋点
extern NSString * const BDPTESearchRankStayPage;
extern NSString * const BDPTESearchRankLoadDetail;

// New
extern NSString *const BDPTEEnterPage;
extern NSString *const BDPTEStayPage;
extern NSString *const BDPTEDownloadStart;
extern NSString *const BDPTEDownloadResult;
extern NSString *const BDPTELoadStart;
extern NSString *const BDPTELoadResult;
extern NSString *const BDPTELaunchStart;
extern NSString *const BDPTELaunchEnd;
extern NSString *const BDPTEEnter;
extern NSString *const BDPTEExit;
extern NSString *const BDPTEJSLoadStart;
extern NSString *const BDPTEJSLoadResult;
extern NSString *const BDPTECPJSLoadStart;
extern NSString *const BDPTECPJSLoadResult;
extern NSString *const BDPTELoadDomReadyStart;
extern NSString *const BDPTELoadDomReadyEnd;
extern NSString *const BDPTELoadFirstContent;

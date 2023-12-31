//
//  BDPTrackerEvents.m
//  Timor
//
//  Created by 维旭光 on 2019/8/11.
//

#import "BDPTrackerEvents.h"

NSString *const BDPTEPageLoadStart = @"mp_page_load_start";
NSString *const BDPTEPageLoadResult = @"mp_page_load_result";
NSString *const BDPTEWebviewInvalidDomain = @"mp_webview_invalid_domain";
NSString *const BDPTEVideoComponentError = @"mp_video_error";

NSString *const BDPTESearchRankStayPage = @"stay_page";
NSString *const BDPTESearchRankLoadDetail = @"load_detail";

// BDPTrackerPKPageStay
NSString *const BDPTEEnterPage = @"mp_enter_page";                  // TODO: H5 减少后台时间
NSString *const BDPTEStayPage = @"mp_stay_page";

// BDPTrackerPKDownload
NSString *const BDPTEDownloadStart = @"mp_download_start";
NSString *const BDPTEDownloadResult = @"mp_download_result";

// BDPTrackerPKLoad
NSString *const BDPTELoadStart = @"mp_load_start";
NSString *const BDPTELoadResult = @"mp_load_result";

// BDPTrackerPKLaunch
NSString *const BDPTELaunchStart = @"mp_launch_start";              // No Report
NSString *const BDPTELaunchEnd = @"openplatform_mp_launch_status"; // 北极星指标，有任何修改，请联系数据同学确认

// BDPTrackerPKEnter
NSString *const BDPTEEnter = @"openplatform_mp_enter_view"; // 北极星指标，有任何修改，请联系数据同学确认
NSString *const BDPTEExit = @"mp_exit";

// BDPTrackerPKAppLibJSLoad
NSString *const BDPTEJSLoadStart = @"mp_js_load_start";             // No Report
NSString *const BDPTEJSLoadResult = @"mp_js_load_result";

// BDPTrackerPKCPJSLoad
NSString *const BDPTECPJSLoadStart = @"mp_cpjs_load_start";         // No Report
NSString *const BDPTECPJSLoadResult = @"mp_cpjs_load_result";

// BDPTrackerPKDomReady
NSString *const BDPTELoadDomReadyStart = @"mp_load_domready_start"; // No Report - TODO: H5 减少后台时间
NSString *const BDPTELoadDomReadyEnd = @"mp_load_domready";

// 从mp_load_result结束到mp_load_domready在5秒内，则为success，大于5s则是timeout
NSString *const BDPTELoadFirstContent = @"mp_first_content";

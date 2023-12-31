//
//  BDWebURLProtocolTask.h
//  BDWebKit
//
//  Created by wuyuqi on 2022/3/1.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "BDWebHTTPCachePolicy.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDWebURLProtocolTask <NSObject>

@property (nonatomic, readonly, strong) NSURLRequest *bdw_request;

// Get from BDWebRequestDecorator, will judge whether schemeHandler should reuse ttnet task.
@property (nonatomic, assign) BOOL bdw_shouldUseNetReuse;

// Get from BDWebRequestDecorator, will be set to NSURLRequest associatedObject
@property (nullable, nonatomic, strong) NSDictionary *bdw_additionalInfo;

// Get from Falcon, will be set to IESWebViewMonitor&HDT
@property (nullable, nonatomic, strong) NSMutableDictionary *bdw_falconProcessInfoRecord;

// Get from TTHttpResponseTimingInfo if task finish with TTNet
@property (nullable, nonatomic, strong) NSDictionary *bdw_ttnetResponseTimingInfoRecord;

// [IESFalconManager webviewWithUserAgent:uaString]
@property (nullable, nonatomic, weak) WKWebView *bdw_webView;

@property (nonatomic, assign) BOOL willRecordForMainFrameModel;

@property (nonatomic, assign) BOOL taskFinishWithTTNet;

@property (nonatomic, assign) BOOL taskFinishWithLocalData;

@property (nonatomic, assign) BOOL taskFromHookAjax;

@property (nonatomic, assign) BOOL useTTNetCommonParams;

@property (nonatomic, assign) BOOL ttnetEnableCustomizedCookie;

@property (nonatomic, assign) BDWebHTTPCachePolicy taskHttpCachePolicy;

@end

NS_ASSUME_NONNULL_END

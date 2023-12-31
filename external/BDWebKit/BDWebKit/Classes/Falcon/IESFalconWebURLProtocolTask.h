//
//  IESFalconWebURLProtocolTask.h
//  BDWebKit
//
//  Created by wuyuqi on 2022/3/1.
//

#import <Foundation/Foundation.h>
#import <BDWebKit/BDWebURLProtocolTask.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESFalconWebURLProtocolTask : NSObject <BDWebURLProtocolTask>

@property (nonatomic, readwrite, strong) NSURLRequest *bdw_request;

@property (nonatomic, assign) BOOL bdw_shouldUseNetReuse;

@property (nullable, nonatomic, strong) NSDictionary *bdw_additionalInfo;

@property (nullable, nonatomic, strong) NSMutableDictionary *bdw_falconProcessInfoRecord;

@property (nullable, nonatomic, strong) NSDictionary *bdw_ttnetResponseTimingInfoRecord;

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

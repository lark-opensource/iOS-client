//
//  BDWebURLSchemeTask.h
//  BDWebKit
//
//  Created by li keliang on 2020/3/13.
//

#import <Foundation/Foundation.h>
#import "BDWebInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

@class BDWebURLSchemeTask;
@protocol BDWebURLSchemeTaskDelegate <NSObject>

- (void)URLSchemeTask:(BDWebURLSchemeTask *)task didReceiveResponse:(NSURLResponse *)response;

- (void)URLSchemeTask:(BDWebURLSchemeTask *)task didLoadData:(NSData *)data;

- (void)URLSchemeTaskDidFinishLoading:(BDWebURLSchemeTask *)task;

- (void)URLSchemeTask:(BDWebURLSchemeTask *)task didFailWithError:(NSError *)error;

@optional
- (void)URLSchemeTask:(BDWebURLSchemeTask *)task didPerformRedirection:(NSURLResponse *)response newRequest:(NSURLRequest *)request;

@end

@interface BDWebURLSchemeTask : NSObject <BDWebURLSchemeTask>

@property (nonatomic, weak) id<BDWebURLSchemeTaskDelegate> delegate;

@property (nonatomic, readwrite, assign) BOOL bdw_shouldUseNetReuse;

@property (nonatomic, readwrite, weak) WKWebView *bdw_webView;

@property (nonatomic, readwrite, strong) NSURLRequest *bdw_request;

@property (nullable, nonatomic, strong) NSDictionary *bdw_additionalInfo;

@property (nullable, nonatomic, strong) NSMutableDictionary *bdw_rlProcessInfoRecord;

@property (nullable, nonatomic, strong) NSDictionary *bdw_ttnetResponseTimingInfoRecord;

@property (nonatomic, copy) BDWebURLSchemeTaskDataProcessor bdw_dataProcessor;

@property (nonatomic, copy) BDWebURLSchemeTaskResponseProcessor bdw_responseProcessor;

@property (nonatomic, weak, nullable) id<BDWebURLSchemeTaskLifeCycleProtocol> bdw_lifecycleDelegate;

@property (nonatomic, assign) BOOL taskHasFinishOrFail;

@property (nonatomic, assign) BOOL canHandle;

@property (nonatomic, assign) BOOL taskFinishWithTTNet;

@property (nonatomic, assign) BOOL taskFinishWithLocalData;

@property (nonatomic, assign) BOOL useTTNetCommonParams;

@property (nonatomic, assign) BOOL ttnetEnableCustomizedCookie;

@property (nonatomic, assign) BOOL willRecordForMainFrameModel;

@property (nonatomic, assign) BDWebHTTPCachePolicy taskHttpCachePolicy;

@end

NS_ASSUME_NONNULL_END

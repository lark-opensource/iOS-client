//
//  HMDHTTPTrackerConfig.h
//  BDAlogProtocol
//
//  Created by 刘诗彬 on 2018/12/19.
//

#import "HMDTrackerConfig.h"

extern NSString * _Nonnull const kHMDModuleNetworkTracker;//网络监控

@interface HMDHTTPTrackerConfig : HMDTrackerConfig
@property (nonatomic, copy, nullable)NSArray *apiAllowList;
@property (nonatomic, copy, nullable)NSArray *apiBlockList;
@property (nonatomic, copy, nullable)NSArray *apiAllowHeaderList;

@property (nonatomic, assign)BOOL enableAPIAllUpload;
@property (nonatomic, assign)BOOL enableAPIErrorUpload;

@property (nonatomic, assign)BOOL enableNSURLProtocolAndChromium;
@property (nonatomic, assign)BOOL ignoreCancelError;
@property (nonatomic, assign)BOOL responseBodyEnabled;
@property (nonatomic, assign)NSUInteger responseBodyThreshold;
// 网络注入采样控制开关
@property (nonatomic, assign) BOOL enableTTNetCDNSample;
// v2 新增配置
@property (nonatomic, copy, nullable) NSString *baseApiAll;
@property (nonatomic, strong, nullable) NSDictionary *requestAllowHeader;
@property (nonatomic, strong, nullable) NSDictionary *responseAllowHeader;
@property (nonatomic, assign) BOOL enableCustomURLCache;
// webview监控开关
@property (nonatomic, assign)BOOL enableWebViewMonitor;

- (NSDictionary * _Nullable)requestAllowHeaderWithHeader:(NSDictionary * _Nullable)requesHeader;
- (NSDictionary * _Nullable)requestAllowHeaderWithHeader:(NSDictionary * _Nullable)requesHeader isMovingLine:(BOOL)isMovingLine;
- (NSDictionary * _Nullable)responseAllowHeaderWitHeader:(NSDictionary * _Nullable)reponseHeader;
- (NSDictionary * _Nullable)responseAllowHeaderWitHeader:(NSDictionary * _Nullable)responseHeader isMovingLine:(BOOL)isMovingLine;

- (BOOL)isURLInBlockList:(NSString * _Nullable)urlString;
- (BOOL)isURLInBlockListWithMainURL:(NSString * _Nullable)mainURL;
- (BOOL)isURLInBlockListWithSchme:(NSString * _Nullable)scheme
                             host:(NSString * _Nullable)host
                             path:(NSString * _Nullable)path;

- (BOOL)isURLInAllowList:(NSString * _Nullable)urlString;
- (BOOL)isURLInAllowListWithMainURL:(NSString * _Nullable)mainURL;
- (BOOL)isURLInAllowListWithScheme:(NSString * _Nullable)scheme
                              host:(NSString * _Nullable)host
                              path:(NSString * _Nullable)path;

- (BOOL)isHeaderInAllowHeaderList:(NSDictionary * _Nullable)requestHeader;

@end


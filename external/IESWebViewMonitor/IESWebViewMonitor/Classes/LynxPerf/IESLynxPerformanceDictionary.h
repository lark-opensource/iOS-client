//
//  IESLynxPerformanceDictionary.h
//  IESWebViewMonitor
//
//  Created by 小阿凉 on 2020/3/2.
//

#import <Foundation/Foundation.h>
#import "IESLynxMonitorConfig.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kLynxMonitorLogType;
extern NSString * const kLynxMonitorEventType;
extern NSString * const kLynxMonitorPid;
extern NSString * const kLynxMonitorBid;
extern NSString * const kLynxMonitorURL;
extern NSString * const kLynxMonitorLynxVersion;
extern NSString * const kLynxMonitorSDKVersion;

extern NSString * const kLynxMonitorNavigationID;
extern NSString * const kLynxMonitorClientMetric;
extern NSString * const kLynxMonitorClientCategory;
extern NSString * const kLynxMonitorClientExtra;
extern NSString * const kLynxMonitorEventName;
extern NSString * const kLynxMonitorState;

extern NSString * const kLynxMonitorLoadStart;
extern NSString * const kLynxMonitorLoadFinish;
extern NSString * const kLynxMonitorLoadFailed;
extern NSString * const kLynxMonitorReceiveError;
extern NSString * const kLynxMonitorFirstScreen;
extern NSString * const kLynxMonitorRuntimeReady;
extern NSString * const kLynxMonitorDidUpdate;
extern NSString * const kLynxMonitorIsContainerReuse;
extern NSString * const kBDHMLynxMonitorAttachTs;
extern NSString * const kBDHMLynxMonitorDetachTs;
extern NSString * const kBDHMLynxMonitorCardVersion;

typedef NSDictionary *_Nullable(^BDHMBaseContextBlock)(NSString * _Nullable url);

@interface IESLynxPerformanceDictionary : NSObject

@property (nonatomic, assign) long pageStartTs;
@property (nonatomic, assign) long startLoadTs;
@property (nonatomic, assign) long loadFinishTs;
@property (nonatomic, assign) long firstScreenTs;
@property (nonatomic, assign) BOOL isFirstLoad;

@property (nonatomic, assign) BOOL hasReportPerf;
@property (nonatomic, assign) BOOL hasDidLoad;

@property (nonatomic, assign) BOOL onFirstLoadPefEnd;
@property (nonatomic, assign) BOOL onFirstScreenEnd;
@property (nonatomic, assign) BOOL onRuntimeReadyEnd;

// attach 
@property (nonatomic, assign) BOOL bdlm_hasAttach;

@property (nonatomic, strong) NSString *bizTag;
@property (nonatomic, strong) NSString *bdwm_virtualAid;

@property (nonatomic) NSDictionary *perf;
@property (nonatomic) IESLynxMonitorConfig *config;

- (instancetype)initWithConfig:(nullable IESLynxMonitorConfig *)config;
- (instancetype)init;
- (void)reportCustomWithDic:(NSDictionary *)dic;

- (void)updateNavigationID:(NSString *)navigationID
                       url:(NSString *)url
              needUpdateCS:(BOOL)needUpdateCS
               startLoadTs:(long)startLoadTs
              loadFinishTs:(long)loadFinishTs
             firstScreenTs:(long)firstScreenTs;

- (void)coverWithDic:(NSDictionary *)srcDic;

- (void)reportPerformance;
- (void)reportDirectlyWithDic:(NSDictionary *)dic evType:(NSString *)eventType;
- (void)reportRequestError:(NSError *)error;
- (void)feCustomReportRequestError:(NSError *)error;
- (void)reportNavigationStart;
- (void)setContainerReuse:(BOOL)isReuse;
- (void)updateAttachTS:(long long)attachTS;
- (void)updateDetachTS:(long long)detachTS;
- (void)updateLynxCardVersion:(NSString *)cardVersion;
- (long long)attachTS;

- (NSString *)fetchCurrentUrl;
- (void)attachNativeBaseContextBlock:(NSDictionary *(^)(NSString *url))block;
- (void)attachContainerUUID:(NSString *)containerUUID;
- (void)reportContainerError:(nullable NSString *)virtualAid errorCode:(NSInteger)code errorMsg:(nullable NSString *)msg bizTag:(nullable NSString *)bizTag;

@end

NS_ASSUME_NONNULL_END

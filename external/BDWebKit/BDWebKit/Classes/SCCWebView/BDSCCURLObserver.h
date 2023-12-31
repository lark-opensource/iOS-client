//
//  BDSCCObserver.h
//  toutiaointoutiao10
//
//  Created by ByteDance on 2022/9/4.
//

#import "BDWSCCWebViewCustomHandler.h"
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDWSCCWebViewConfiguration : NSObject

@property (nonatomic, assign) BOOL enable;

@property (nonatomic, assign) BOOL needCloudChecking;

@property (nonatomic, assign) BOOL hasBeenReach;

@property (nullable, nonatomic, strong) NSString *logID;

@property (nonatomic, assign) BDWebViewSCCReportType reportType;

@property (nullable, nonatomic, strong) id<BDWSCCWebViewCustomHandler> customHandler;

@property (nullable, nonatomic, strong) NSDate *cloudCheckBeginTime;

@property (nullable, nonatomic, strong) NSArray *denyDic;

@property (nullable, nonatomic, strong) NSArray *allowListForJumpAPP;

@property (nullable, nonatomic, strong) NSString *reason;

@property (nullable, nonatomic, strong) NSString *seclinkScene;

@end

@interface BDWSCCURLObserver : NSObject

@property (nullable, atomic, weak) WKWebView *webView;

@property (nullable, atomic, strong) BDWSCCWebViewConfiguration *config;

- (NSString *)filterDomainFromURL:(NSString *)url;

- (void)resetSCCStatusForWebView;

@end

NS_ASSUME_NONNULL_END


//
//  BDSCCObserver.m
//
//  Created by ByteDance on 2022/9/4.
//
#import "BDSCCURLObserver.h"
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import "BDWebSCCManager.h"
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTHttpResponseChromium.h>
#import <TTNetworkManager/NSURLRequest+WebviewInfo.h>
#import <ByteDanceKit/BTDMacros.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>

static NSRegularExpression *kSCCRegexForDomain;
static NSString *kSCCCloudCheckDomain = @"https://scc.bytedance.com/scc_sdk/url_scan_v3";

@implementation BDWSCCWebViewConfiguration

- (instancetype)init {
    self = [super init];
    self.logID = @"";
    self.reason = @"";
    return self;
}

@end

@implementation BDWSCCURLObserver

- (instancetype)init {
    self = [super init];
    if (self) {
        self.config = [[BDWSCCWebViewConfiguration alloc] init];
    }
    NSError *error = NULL;
    kSCCRegexForDomain = [NSRegularExpression regularExpressionWithPattern:@"[^/]+" options:NSRegularExpressionCaseInsensitive error:&error];
    return self;
}

- (NSString*)filterDomainFromURL:(NSString *)url {
    if(!url) {
        return @"";
    }
    NSRange textRange = NSMakeRange(0, url.length);
    NSArray<NSTextCheckingResult *> *array = [kSCCRegexForDomain matchesInString:url options:NSMatchingReportProgress range:textRange];
    
    if(!array||array.count <= 1) {
        return @"";
    }
    NSTextCheckingResult *result = array[1];
    NSString *ns = [url substringWithRange:result.range];
    return ns;
}

#pragma mark - Private

- (void)__processResponse:(id)jsonObj withError:(NSError *)error withURL:(NSString *)url wasteTime:(NSNumber *)wasteTime {    
    self.config.reportType = BDWebViewSCCReportTypeAllow;
    if (error) {
        BDSCCLog(@"server request error");
        self.config.reportType = BDWebViewSCCReportTypeNotice;
        return;
    }
    
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonObj
                                                            options:NSJSONReadingAllowFragments
                                                              error:nil];
    
    if (![NSJSONSerialization isValidJSONObject:jsonDic]) {
        BDSCCLog(@"not valid jason type");
        self.config.reportType = BDWebViewSCCReportTypeNotice;
        return;
    }
    
    NSDictionary *sccResponse = nil;
    if ([jsonDic isKindOfClass:[NSDictionary class]]) {
        sccResponse = (NSDictionary *)jsonDic;
    }
    if (BTD_isEmptyDictionary(sccResponse)) {
        //todo:需要讨论一下这个点怎么搞
        BDSCCLog(@"server request error:json empty");
        self.config.reportType = BDWebViewSCCReportTypeNotice;
        return;
    }
    
    if([sccResponse objectForKey:@"message"]) {
        if (![[sccResponse btd_stringValueForKey:@"message"] isEqualToString:@"ok"]) {
            BDSCCLog(@"server request error:message != ok");
            return;
        }
    }
    
    NSString *label = [sccResponse[@"data"] btd_stringValueForKey:@"label"];
    if (label) {
        if ([label isEqualToString:@"white"] || [label isEqualToString:@"allow"]) {
            BDWebSCCManager *settingRule=[BDWebSCCManager shareInstance];
            [settingRule.domainList setObject:0 forKey:url];
            self.config.reportType = BDWebViewSCCReportTypeAllow;
        } else if ([label isEqualToString:@"black"] || [label isEqualToString:@"deny"]) {
            self.config.reportType = BDWebViewSCCReportTypeDeny;
        } else {
            self.config.reportType = BDWebViewSCCReportTypeNotice;
        }
    }
    if ([sccResponse[@"data"] btd_stringValueForKey:@"reason"]) {
        self.config.reason = [sccResponse[@"data"] btd_stringValueForKey:@"reason"];
    }
    NSString *wasteTimeStr = @"";
    if(wasteTime == nil) {
        wasteTimeStr = @"0";
    } else {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        formatter.maximumFractionDigits = 0;
        wasteTimeStr = [formatter stringFromNumber:wasteTime];
    }
    
}

#pragma mark - KVO handlers

- (void)resetSCCStatusForWebView {
    self.config.needCloudChecking = NO;
    self.config.hasBeenReach = NO;
    self.config.reason = @"";
    self.config.reportType = BDWebViewSCCReportTypeAllow;
    self.config.logID = @"";
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if (!self.config.enable) {
        return;
    }
    
    [self resetSCCStatusForWebView];
    BDWebSCCManager *settingRule = [BDWebSCCManager shareInstance];

    NSURL *newURL = change[NSKeyValueChangeNewKey];
    if (newURL == nil||[newURL isKindOfClass:NSNull.class] ) {
        return;
    }
    NSString *newURLStr = newURL.absoluteString;
    NSString *filterDomain = [self filterDomainFromURL:newURLStr];
    BOOL ifWebViewExistAndFirstPage = self.webView && (self.webView.backForwardList.currentItem.URL == nil);
    if ([newURLStr hasPrefix:@"http"] == NO ) {
        if([self.config.customHandler respondsToSelector:@selector(bdw_URLRiskLevel:forReason:withWebView:forURL:canGoBack:)]) {
            [self.config.customHandler bdw_URLRiskLevel:BDWebViewSCCReportTypeAllow forReason:@"allow_setting" withWebView:self.webView forURL:newURL canGoBack:!ifWebViewExistAndFirstPage];
        }
        return;
    }
    BOOL needSCCRemoteCheck = YES;
    
    if (settingRule.storageList) {
        NSArray *denyDic = self.config.denyDic;
        if (denyDic != nil) {
            for (int i = 0;i < denyDic.count;i++) {
                NSArray *denyList = [denyDic[i] objectForKey:@"urlSet"];
                for (int j = 0;j < denyList.count;j++) {
                    NSError *error = NULL;
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:denyList[j] options:NSRegularExpressionCaseInsensitive error:&error];
                    NSRange range = [regex rangeOfFirstMatchInString:newURLStr options:NSMatchingReportProgress range:NSMakeRange(0, newURLStr.length)];
                    if(range.location == 0 && range.length == newURLStr.length) {
                        return;
                    }
                }
            }
        }
    }

    NSString* fetchRule = nil;
    if (settingRule.storageList) {
        NSArray<NSString*> *allowList = [settingRule.storageList objectForKey:@"allowRule"];
        NSDate* tmpStartData1 = [NSDate date];
        if (allowList != nil) {
            for (int i = 0;i < allowList.count;i++) {
                if ([filterDomain containsString:allowList[i]]) {
                    needSCCRemoteCheck = NO;
                    fetchRule = allowList[i];
                    break;
                }
            }
        }
    }

    if (needSCCRemoteCheck == NO) {
        if([self.config.customHandler respondsToSelector:@selector(bdw_URLRiskLevel:forReason:withWebView:forURL:canGoBack:)]) {
            [self.config.customHandler bdw_URLRiskLevel:BDWebViewSCCReportTypeAllow forReason:@"allow_setting" withWebView:self.webView forURL:newURL canGoBack:!ifWebViewExistAndFirstPage];
        }
        return;
    }
    
    if (settingRule.domainList) {
        if ([settingRule.domainList searchObject:newURLStr] == YES) {
            needSCCRemoteCheck = NO;
            if([self.config.customHandler respondsToSelector:@selector(bdw_URLRiskLevel:forReason:withWebView:forURL:canGoBack:)]) {
                [self.config.customHandler bdw_URLRiskLevel:BDWebViewSCCReportTypeAllow forReason:@"hit local allow list" withWebView:self.webView forURL:newURL canGoBack:ifWebViewExistAndFirstPage];
            }
            return;
        }
    }
    
    if ([self.config.customHandler respondsToSelector:@selector(bdw_willSkipSCCCloudCheck:forURL:)]) {
        if ([self.config.customHandler bdw_willSkipSCCCloudCheck:self.webView forURL:newURL]) {
            needSCCRemoteCheck = NO;
            return;
        }
    }

    /// 2. check scc remote api
    NSString *ts = [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]];
    NSString *scene = BTD_isEmptyString(self.config.seclinkScene)?@"":self.config.seclinkScene;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:@{@"ts":[NSNumber numberWithLong:[ts longLongValue]]
                                                                                    ,@"url":newURLStr?:@"",
                                                                                    @"extra":@"",
                                                                                    @"scene":scene
                                                                                    }];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:NULL];
    NSDate* tmpStartData = [NSDate date];
    self.config.needCloudChecking = YES;
    self.config.cloudCheckBeginTime = [NSDate date];
    NSMutableURLRequest *sccCloudRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kSCCCloudCheckDomain] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    sccCloudRequest.HTTPMethod = @"POST";
    sccCloudRequest.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
    sccCloudRequest.needCommonParams = YES;
    NSString *headStr=@"application/json";
    [sccCloudRequest setValue:headStr forHTTPHeaderField:@"Content-Type"];
    
    @weakify(self);
    TTHttpTask *sccTTNetTask = [[TTNetworkManager shareInstance] requestForWebview:sccCloudRequest
                                                                     autoResume:NO
                                                                enableHttpCache:NO
                                                                 headerCallback:nil
                                                                   dataCallback:nil
                                                           callbackWithResponse:^(NSError * _Nullable error, id  _Nullable obj, TTHttpResponse * _Nullable response) {
        @strongify(self);
        double deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData]*1000;
        TTHttpResponseChromium *targetResponse = (TTHttpResponseChromium *)response;
                        TTHttpResponseChromiumTimingInfo *timingInfo = targetResponse.timingInfo;

        NSDictionary *originRequestLogDic = [NSJSONSerialization JSONObjectWithData:[targetResponse.requestLog dataUsingEncoding:NSUTF8StringEncoding]
                                                                            options:0
                                                                              error:nil];
        
        NSString *trace_id = @"";
        self.config.logID = @"";
        NSMutableDictionary *detailParamDic = [[NSMutableDictionary alloc] init];
        if (!BTD_isEmptyDictionary(originRequestLogDic)) {
            NSDictionary *logTimingDic = [originRequestLogDic btd_dictionaryValueForKey:@"timing"];
            NSDictionary *detailedDurationDic = [logTimingDic btd_dictionaryValueForKey:@"detailed_duration"];
            NSDictionary *logBaseDic = [originRequestLogDic btd_dictionaryValueForKey:@"base"];
            NSDictionary *logHeaderDic = [originRequestLogDic btd_dictionaryValueForKey:@"header"];
            
            // fetch TNC info
            if (!BTD_isEmptyDictionary(logHeaderDic)) {
                self.config.logID = [logHeaderDic btd_stringValueForKey:@"x-tt-logid" default:@""];
                trace_id = [logHeaderDic btd_stringValueForKey:@"x-tt-trace-id" default:@""];
            }
        }
        NSString *strLogID = BTD_isEmptyString(self.config.logID)?@"":self.config.logID;
        strLogID = BTD_isEmptyString(strLogID)?@"":strLogID;
        NSMutableDictionary* dic=[[NSMutableDictionary alloc]initWithObjects:@[[NSNumber numberWithDouble:deltaTime],strLogID,trace_id] forKeys:@[@"scc_passed_time",@"scc_logid",@"scc_trace_id"]];
        [BDTrackerProtocol eventV3:@"scc_cloudservice_result" params:dic];
        if(!self.webView||![self.webView.URL.absoluteString isEqualToString:newURLStr]) {
            return;
        }
        self.config.hasBeenReach = YES;
        [self __processResponse:obj withError:error withURL:newURLStr wasteTime:[NSNumber numberWithDouble:deltaTime]];
    }];
    [sccTTNetTask resume];
}

@end

//
//  TTNetworkManagerChromium.h
//  Pods
//
//  Created by gaohaidong on 11/16/16.
//
//

#import <Foundation/Foundation.h>
#import "TTNetworkManager.h"
#import "TTDnsOuterService.h"

@interface TTNetworkManagerChromium : TTNetworkManager

@property (nonatomic,copy) NSString *defaultUserAgent;
@property (atomic, copy, readwrite) NSString *shareCookieDomainNameList;
@property (atomic, strong, readwrite) NSArray *publicIPv4List;
@property (atomic, strong, readwrite) NSArray *publicIPv6List;
@property (atomic, copy) NSDictionary *concurrentRequestConfig;
@property (nonatomic, strong) TTDnsOuterService *ttnetDnsOuterService;
@property (nonatomic, copy) Monitorblock monitorblock;
@property (nonatomic, copy) GetDomainblock getDomainblock;
@property (nonatomic, copy) FrontierUrlsCallbackBlock frontierUrlsCallbackblock;
@property (nonatomic, assign) BOOL httpDNSEnabled;
@property (nonatomic, assign) TTNetworkManagerImplType currentImpl;
@property (nonatomic, copy) GetNqeResultBlock nqeV2block;

/**
 *enable image check in webview, default value is YES, can reset by TNC, config like:
 {
   "data":{
     "enable_webview_image_check": 0
   },
   "message":"success"
 }
 *0 means disable, other value means enable
 */
@property (atomic, assign) BOOL isWebviewImageCheck;

/**
 *set  domains to support image check in webview , only can be set  on TNC
 *default value is nil,which means all request domains will be checked if isWebviewImageCheck is on
 *NOT support wildcard matching, like * and ?, only support equal match(string matching)
 *TNC config like this:
 {
   "data":{
     "enable_webview_image_check": 1,
     "image_check_domian_list": [
        "lf.snssdk.com", "lq.aweme.com"
     ]
   },
   "message":"success"
 }
 */
@property (atomic, copy) NSArray<NSString *> *imageCheckDomainList;

/**
 *set bypass domain list to NOT check image, mainly for inner domain
 *default value is nil,which means all request domains will be checked if isWebviewImageCheck is on
 *supprot wildcard matching, like * and ?
 *TNC config like this:
  {
    "data":{
      "enable_webview_image_check": 1,
      "image_check_bypass_list":[
        "*.snssdk.com",
        "*.aweme.com"
      ]
    },
    "message":"success"
  }
 */
@property (atomic, copy) NSArray<NSString *> *imageCheckBypassDomainList;

@property (atomic, copy) NSArray *commonParamsL0Level;

- (BOOL)ensureEngineStarted;
- (void *)getEngine;
- (void)setUserIdcInternal:(NSString *)userIdc;
- (void)setUserRegionInternal:(NSString *)userRegion;
- (void)setRegionSourceInternal:(NSString *)regionSource;
- (void)setClientIPInternal:(NSString *)clientIP;
@end

//
//  TTNetworkManagerChromium.m
//  Pods
//
//  Created by gaohaidong on 11/16/16.
//
//

#import "TTNetworkManagerChromium.h"

#import <objc/runtime.h>

#import "RequestRetryResult.h"
#import "TTNetworkManager.h"
#import "TTNetworkUtil.h"
#import "TTHTTPRequestSerializerBase.h"
#import "TTNetworkManagerMonitorNotifier.h"
#import "TTDispatchResult.h"
#import "TTDnsResult.h"
#import "TTDnsQuery.h"
#import "TTHttpRequestChromium.h"
#import "TTHttpResponseChromium.h"
#import "TTHttpTaskChromium.h"
#import "TTConcurrentHttpTask.h"
#import "TTHTTPRequestSerializerBaseChromium.h"
#import "TTHTTPJSONResponseSerializerBaseChromium.h"
#import "TTHTTPResponseSerializerBase.h"
#import "TTHTTPBinaryResponseSerializerBase.h"
#import "TTReqFilterManager.h"
#import "TTCdnCacheVerifyManager.h"
#import "TTNetworkManagerLog.h"
#import "TTURLDispatch.h"
#import "TTNetInitMetrics.h"
#import "TTRegionManager.h"
#import "QueryFilterEngine.h"
#import "NSURLRequest+WebviewInfo.h"

#ifndef DISABLE_REQ_LEVEL_CTRL
#import "TTNetRequestLevelController.h"
#import "TTNetRequestLevelController+TTNetInner.h"
#endif
////////////////////////////

#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/bind.h"
#include "net/nqe/effective_connection_type_observer.h"
#include "net/nqe/network_quality_estimator.h"
#include "net/nqe/rtt_throughput_estimates_observer.h"
#include "base/strings/sys_string_conversions.h"
#include "components/cronet/ios/cronet_environment.h"
#include "components/cronet/url_request_context_config.h"
#include "components/cronet/cronet_global_state.h"
#include "url/url_util.h"

#import <libkern/OSAtomic.h>
#import <Godzippa/NSData+Godzippa.h> // for gzip
#import <BDDataDecorator/NSData+DataDecorator.h>
#import <BDAlogProtocol/BDAlogProtocol.h>

#import "net/tt_net/nqe/tt_network_quality_estimator.h"
#if !defined(DISABLE_NQE_SUPPORT)
#import "net/tt_net/nqe/tt_group_rtt_manager.h"
#endif
#import "net/tt_net/route_selection/tt_app_info.h"
#import "net/tt_net/route_selection/tt_monitor_module.h"
#import "net/tt_net/route_selection/tt_server_config.h"
#if !defined(DISABLE_WIFI_TO_CELL)
#import "net/tt_net/multinetwork/wifi_to_cell/tt_multinetwork_manager.h"
#endif
#import "net/tt_net/net_detect/tt_network_detect_manager.h"
#import "net/tt_net/dns/tt_dns_outer_service.h"


#define CPPSTR(str) str == nil ? "" : str.UTF8String
#define INTSTR(str) str == nil ? 0 : [str intValue]

class ConnectionTypeObserver;
class NQEObserver;
class PacketLossRateObserver;
class MultiNetworkStateObserver;
class TTNetworkQualityLevelObserver;
class ColdStartObserver;
class NetDetectObserver;
class TTDnsResolveObserver;
class TTRequestInfoObserver;

@interface TTHttpResponseChromium ()

- (instancetype)initWithURLFetcher:(const net::URLFetcher *)fetcher;
- (instancetype)initWithRequestLog:(NSString *)requestLog;

@end

base::LazyInstance<std::unique_ptr<cronet::CronetEnvironment>>::Leaky
gChromeNet = LAZY_INSTANCE_INITIALIZER;



class AppInfoProviderImpl : public net::TTAppInfoProvider {
public:
 
    virtual bool GetAppInfo(net::TTAppInfoNode* appInfoNode) {
      TTNetworkManagerChromium* app_info_owner = [TTNetworkManagerChromium shareInstance];
      TTNetworkManagerCommonParamsBlock common_params_block = app_info_owner.commonParamsblock;
      if (!common_params_block) {
        LOGI(@"commonParamsblock is not set, appInfoNode invalid");
        NSCAssert(false, @"commonParamsblock must be set");
        return false;
      }

      NSDictionary<NSString *, NSString *> *commonParamValue = common_params_block();

      appInfoNode->appId = CPPSTR([commonParamValue objectForKey:@"aid"]);
      appInfoNode->deviceId = CPPSTR([commonParamValue objectForKey:@"device_id"]);
      appInfoNode->netAccessType = CPPSTR([commonParamValue objectForKey:@"ac"]);
      appInfoNode->versionCode = CPPSTR([commonParamValue objectForKey:@"version_code"]);
      appInfoNode->update_version_code = CPPSTR([commonParamValue objectForKey:@"update_version_code"]);
      appInfoNode->deviceType = CPPSTR([commonParamValue objectForKey:@"device_type"]);
      appInfoNode->appName = CPPSTR([commonParamValue objectForKey:@"app_name"]);
      appInfoNode->channel = CPPSTR([commonParamValue objectForKey:@"channel"]);
      appInfoNode->osVersion = CPPSTR([commonParamValue objectForKey:@"os_version"]);
      appInfoNode->devicePlatform = CPPSTR([commonParamValue objectForKey:@"device_platform"]);
      appInfoNode->device_model = CPPSTR([commonParamValue objectForKey:@"device_model"]);
      appInfoNode->is_drop_first_tnc = CPPSTR([commonParamValue objectForKey:@"is_drop_first_tnc"]);

      NSString* region = [commonParamValue objectForKey:@"region"];
      if (region) {
          region = [region lowercaseString];
      }
      appInfoNode->region = CPPSTR(region);

      NSString* sysRegion = [commonParamValue objectForKey:@"sys_region"];
      if (sysRegion) {
          sysRegion = [sysRegion lowercaseString];
      }
      appInfoNode->sys_region = CPPSTR(sysRegion);

      NSString* carrierRegion = [commonParamValue objectForKey:@"carrier_region"];
      if (carrierRegion) {
          carrierRegion = [carrierRegion lowercaseString];
      }
      appInfoNode->carrier_region = CPPSTR(carrierRegion);

      appInfoNode->tnc_load_flags = INTSTR([commonParamValue objectForKey:@"tnc_load_flags"]);
      appInfoNode->httpdns_load_flags = INTSTR([commonParamValue objectForKey:@"httpdns_load_flags"]);

      NSDictionary<NSString *, NSString *> *tncRequestHeader = app_info_owner.TncRequestHeaders;
      if (tncRequestHeader != nil && [tncRequestHeader count] > 0) {
          [tncRequestHeader enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
              appInfoNode->headers[std::string(CPPSTR(key))] = std::string(CPPSTR(obj));
          }];
      }

      NSDictionary<NSString *, NSString *> *tncRequestQueries = app_info_owner.TncRequestQueries;
      if (tncRequestQueries != nil && [tncRequestQueries count] > 0) {
          [tncRequestQueries enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
              appInfoNode->queries[std::string(CPPSTR(key))] = std::string(CPPSTR(obj));
          }];
      }
        
      if ([TTNetworkManager shareInstance].tncSdkAppId != nil && ![[TTNetworkManager shareInstance].tncSdkAppId isEqual: @""]) {
        appInfoNode->sdk_app_id = CPPSTR([TTNetworkManager shareInstance].tncSdkAppId);
      } else {
        appInfoNode->sdk_app_id = CPPSTR([commonParamValue objectForKey:@"sdk_app_id"]);
      }

      if ([TTNetworkManager shareInstance].tncSdkVersion != nil && ![[TTNetworkManager shareInstance].tncSdkVersion isEqual: @""]) {
        appInfoNode->sdk_version = CPPSTR([TTNetworkManager shareInstance].tncSdkVersion);
      } else {
        appInfoNode->sdk_version = CPPSTR([commonParamValue objectForKey:@"sdk_version"]);
      }

      appInfoNode->is_main_process = CPPSTR(@"1");

      //get-domain的host
      appInfoNode->host_first = CPPSTR([TTNetworkManager shareInstance].ServerConfigHostFirst);
      if (appInfoNode->host_first.empty()) {
        NSCAssert(false, @"get_domains ServerConfigHostFirst must be set");
      }
      appInfoNode->host_second = CPPSTR([TTNetworkManager shareInstance].ServerConfigHostSecond);
      appInfoNode->host_third = CPPSTR([TTNetworkManager shareInstance].ServerConfigHostThird);
      appInfoNode->domain_httpdns = CPPSTR([TTNetworkManager shareInstance].DomainHttpDns);
      if (appInfoNode->domain_httpdns.empty()) {
        NSCAssert(false, @"DomainHttpDns must be set");
      }
      appInfoNode->domain_netlog = CPPSTR([TTNetworkManager shareInstance].DomainNetlog);
      if (appInfoNode->domain_netlog.empty()) {
        NSCAssert(false, @"DomainNetlog must be set");
      }
      appInfoNode->domain_boe = CPPSTR([TTNetworkManager shareInstance].DomainBoe);
      appInfoNode->domain_boe_https = CPPSTR([TTNetworkManager shareInstance].DomainBoeHttps);
      if (appInfoNode->domain_boe.empty() && appInfoNode->domain_boe_https.empty()) {
        NSCAssert(false, @"At least one of DomainBoe and DomainBoeHttps must be set.");
      }

      appInfoNode->store_idc = CPPSTR([TTNetworkManager shareInstance].StoreIdc);
      appInfoNode->userId = CPPSTR([TTNetworkManager shareInstance].UserId);
      appInfoNode->init_region = CPPSTR([TTNetworkManager shareInstance].appInitialRegionInfo);
      appInfoNode->is_domestic = [TTNetworkManager shareInstance].useDomesticStoreRegion;

      return true;
    }

    virtual void OnClientIPChanged(const std::string& client_ip)  {
        NSString *client_ip_string = [NSString stringWithUTF8String:client_ip.c_str()];
        LOGD(@"OnClientIPChanged: %@", client_ip_string);
        [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] setClientIPInternal:client_ip_string];
    }
    
    virtual void OnPublicIPsChanged(const std::vector<std::string>& ipv4_list,
                                    const std::vector<std::string>& ipv6_list)  {
        gChromeNet.Get()->OnPublicIPsChangedNativeCallback(ipv4_list, ipv6_list);
        NSMutableArray *publicIPv4List = [[NSMutableArray alloc] init];
        NSMutableArray *publicIPv6List = [[NSMutableArray alloc] init];
        for (const auto& it : ipv4_list) {
            [publicIPv4List addObject:[NSString stringWithUTF8String:it.c_str()]];
        }
        for (const auto& it : ipv6_list) {
            [publicIPv6List addObject:[NSString stringWithUTF8String:it.c_str()]];
        }
        
        LOGD(@"OnPublicIPsChanged ipv4_list: %@, ipv6_list: %@", publicIPv4List, publicIPv6List);
        [TTNetworkManagerChromium shareInstance].publicIPv4List = publicIPv4List;
        [TTNetworkManagerChromium shareInstance].publicIPv6List = publicIPv6List;
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:publicIPv4List, @"public_ipv4", publicIPv6List, @"public_ipv6", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kTTNetPublicIPsNotification object:nil userInfo:dict];
    }
    
    virtual void OnStoreIdcChanged(const std::string& store_idc, const std::string& store_region, const std::string& store_region_src, const std::string& sec_uid, const std::string& logid) {
        NSString *idc = [NSString stringWithUTF8String:store_idc.c_str()];
        NSString *region = [NSString stringWithUTF8String:store_region.c_str()];
        NSString *regionSrc = [NSString stringWithUTF8String:store_region_src.c_str()];
        NSString *secUid = [NSString stringWithUTF8String:sec_uid.c_str()];
        NSString *logId = [NSString stringWithUTF8String:logid.c_str()];
        LOGD(@"OnStoreIdcChanged, store idc: %@, store region: %@, source: %@, sec uid: %@, logid: %@", idc, region, regionSrc, secUid, logId);
        
        [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] setUserIdcInternal:idc];
        [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] setUserRegionInternal:region];
        [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] setRegionSourceInternal:regionSrc];
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:idc, @"user_idc", region, @"user_region", regionSrc, @"region_source", secUid, @"sec_uid", logId, @"logid", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kTTNetStoreIdcChangeNotification object:nil userInfo:dict];
    }
};

class NetDetectObserver : public net::TTNetDetectListener {
public:
    void onTTNetDetectFinish(const std::string& info) {
        NSString *net_detect_result = [NSString stringWithUTF8String:info.c_str()];
        LOGD(@"onTTNetDetectFinish: %@", net_detect_result);
        [[NSNotificationCenter defaultCenter] postNotificationName:kTTNetNetDetectResultNotification object:net_detect_result userInfo:nil];
    }
};

class TTRequestInfoObserver : public net::TTRequestInfoProvider {
public:
    void HandleRequestInfoNotify(const net::TTNetBasicRequestInfo& info) override {
        gChromeNet.Get()->HandleRequestInfoNotifyNativeCallback(info);
    }
    
    void AddObserverOnNetworkThread() {
        gChromeNet.Get()->SetRequestInfoDelegate(this);
    }
};

class TTDnsResolveObserver : public net::TTDnsResolveListener {
public:
    void OnTTDnsResolveResult(const std::string& uuid,
                              const std::string& host,
                              int ret,
                              int source,
                              int cache_source,
                              const std::vector<std::string>& ips,
                              const std::string& detailed_info,
                              bool is_native) override {
        if (is_native) {
            gChromeNet.Get()->TTDnsResolveNativeCallback(
                                                         uuid, host, ret, source, cache_source, ips, detailed_info, is_native);
            return;
        }
        NSString *uuid_str = [NSString stringWithUTF8String:uuid.c_str()];
        NSString *host_str = [NSString stringWithUTF8String:host.c_str()];
        NSMutableArray *temp_array = [[NSMutableArray alloc] init];
        for (std::string ip_str : ips) {
            [temp_array addObject:[NSString stringWithUTF8String:ip_str.c_str()]];
        }
        NSArray *ip_array = [temp_array copy];
        NSString *detailed_info_str = [NSString stringWithUTF8String:detailed_info.c_str()];
        [((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).ttnetDnsOuterService handleTTDnsResultWithUUID:uuid_str
                                                                                                                  host:host_str
                                                                                                                   ret:ret
                                                                                                                source:source
                                                                                                           cacheSource:cache_source
                                                                                                                ipList:ip_array
                                                                                                          detailedInfo:detailed_info_str];
    }
    
    void AddObserverOnNetworkThread() {
        gChromeNet.Get()->SetTTDnsResolveListener(this);
    }
};

@interface TTNetURLSessionDelegate : NSObject <NSURLSessionDelegate>
@end

@implementation TTNetURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    SecTrustRef servertrust = challenge.protectionSpace.serverTrust;
    // Get the count of certificate in chain
    CFIndex certificateCount = SecTrustGetCertificateCount(servertrust);
    // Get root certificate
    SecCertificateRef certi= SecTrustGetCertificateAtIndex(servertrust, certificateCount - 1);
    // transform certificate into NSData
    NSData *certidata = CFBridgingRelease(SecCertificateCopyData(certi));

    NSArray* certificate = [TTNetworkManager shareInstance].ServerCertificate;
    for (id certs in certificate) {
        if ([certidata isEqualToData:certs]) {
            NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:servertrust];
            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            return;
        }
    }

    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
}
@end

class ColdStartObserver : public net::TTColdStartListener {
public:
    
    void OnColdStartFinish(bool timeout) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTTNetColdStartFinishNotification object:nil userInfo:nil];
    }
    
    void OnTNCUpdateFailed(const std::vector<std::string>& urls, const std::string& summary) {
        auto size = urls.size();
        LOGD(@"OnTNCUpdateFailed: %ld", size);

        if (size <= 0 || tnc_updating_) {
            return;
        }
        tnc_updating_ = true;
        tnc_update_try_index_ = 0;
        urls_ = urls;
        summary_ = summary;
        
        UpdateTnc();
    }
    
    void OnCronetInitCompleted(const net::CronetInitTimingInfo& timing_info) {
        Monitorblock monitorBlock = ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).monitorblock;
        if (monitorBlock) {
            NSDictionary *dict =  [[TTNetInitMetrics sharedManager] constructTTNetInitTimingInfo: &timing_info];
            if (dict) {
                monitorBlock(dict, @"ttnet_init");
            }
        }
        [TTNetworkManager shareInstance].isInitCompleted = YES;
    }
    
private:
    bool tnc_updating_ = false;
    int tnc_update_try_index_ = 0;
    std::vector<std::string> urls_;
    std::string summary_;
    
    void (^UpdateTncResponse)(NSData *data, NSURLResponse *response, NSError *error) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *url = [NSString stringWithUTF8String:urls_.at(tnc_update_try_index_).c_str()];
        LOGD(@"tnc update complete, try index: %d, url: %@",tnc_update_try_index_, url);
        
        if (data && response) {
            NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = httpResponse.statusCode;
            NSDictionary *allHeaders = httpResponse.allHeaderFields;
            NSString *tncVersion = [allHeaders valueForKey:@"x-ss-etag"];
            NSString *tncCanary = [allHeaders valueForKey:@"x-ss-canary"];
            NSString *tncConfigId = [allHeaders valueForKey:@"x-tt-tnc-config"];
            NSString *tncAbtest = [allHeaders valueForKey:@"x-tt-tnc-abtest"];
            NSString *tncControl = [allHeaders valueForKey:@"x-tt-tnc-control"];
            
            LOGD(@"tnc update complete, try index: %d, status: %ld, tncVersion:%@, tncCanary:%@ tncConfigId:%@ tncAbtest:%@ response: %@", tnc_update_try_index_, statusCode, tncVersion, tncCanary, tncConfigId, tncAbtest, responseStr);
            if (statusCode == 200 && responseStr && responseStr != nil) {
                LOGD(@"tnc update succ, try index: %d, status: %ld, tncVersion:%@, tncCanary:%@ tncConfigId:%@ tncAbtest:%@ response: %@", tnc_update_try_index_, statusCode, tncVersion, tncCanary, tncConfigId, tncAbtest, responseStr);

                gChromeNet.Get()->NotifyTNCConfigUpdated(base::SysNSStringToUTF8(tncVersion), base::SysNSStringToUTF8(tncCanary), base::SysNSStringToUTF8(tncConfigId), base::SysNSStringToUTF8(tncAbtest), base::SysNSStringToUTF8(tncControl), base::SysNSStringToUTF8(responseStr));
                tnc_updating_ = false;
                return;
            }
        }
       
        tnc_update_try_index_++;
        UpdateTnc();
    };

    void UpdateTnc(){
        if (tnc_update_try_index_ > urls_.size() - 1) {
            LOGD(@"tnc update fail, try all, finish");
            tnc_updating_ = false;
            return;
        }

        NSError* error = nil;
        NSString* domainDefaultJSON = [TTNetworkManager shareInstance].getDomainDefaultJSON;
        int opaque = 0;
        if (domainDefaultJSON != nil) {
            NSData* jsonValue = [NSJSONSerialization JSONObjectWithData:[domainDefaultJSON dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
            if (error == nil) {
                id dataValue = [jsonValue valueForKey:@"data"];
                opaque = [[dataValue valueForKey:@"opaque_data_enabled"] intValue];
            } else {
                LOGE(@"parse json error is %@", error);
            }
        }

        std::string url_str = urls_.at(tnc_update_try_index_).append("&tnc_src=7");
        NSString *url = [NSString stringWithUTF8String:url_str.c_str()];
        NSString *summary = [NSString stringWithUTF8String:summary_.c_str()];
        NSURLSession *session = nil;

        NSArray* certificate = [TTNetworkManager shareInstance].ServerCertificate;
        bool useTTNetSession = false;
        if (opaque == 1 && certificate && [certificate count] > 0) {
            session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:[TTNetURLSessionDelegate alloc] delegateQueue:nil];
            useTTNetSession = true;
        } else {
            session = [NSURLSession sharedSession];
        }

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: url]];
        if (summary) {
            [request setValue:summary forHTTPHeaderField:@"x-tt-tnc-summary"];
        }
        [[session dataTaskWithRequest:request completionHandler:UpdateTncResponse] resume];
        if (useTTNetSession)
            [session finishTasksAndInvalidate];
    }
};

#if !defined(DISABLE_NQE_SUPPORT)
class ConnectionTypeObserver : public net::EffectiveConnectionTypeObserver {
public:
    void OnEffectiveConnectionTypeChanged(net::EffectiveConnectionType type) override {
        NSInteger connection_type = type;
        LOGD(@"OnEffectiveConnectionTypeChanged: %ld", connection_type);
        NSDictionary *dict = @{@"connection_type":@(connection_type)};
        [[NSNotificationCenter defaultCenter] postNotificationName:kTTNetConnectionTypeNotification object:nil userInfo:dict];
    }

    void AddObserverOnNetworkThread() {
        LOGD(@"AddObserverOnNetworkThread");
        if (gChromeNet.Get()->GetURLRequestContext()->network_quality_estimator()) {
              gChromeNet.Get()->GetURLRequestContext()->network_quality_estimator()->AddEffectiveConnectionTypeObserver(this);
        }
    }
};
class NQEObserver : public net::RTTAndThroughputEstimatesObserver {
  public:
    NQEObserver(GetNqeResultBlock get_nqe_result_callback) : get_nqe_result_callback_(get_nqe_result_callback) {
    }

    void OnRTTOrThroughputEstimatesComputed(base::TimeDelta http_rtt,
                                            base::TimeDelta transport_rtt,
                                            int32_t downstream_throughput_kbps) {
      int32_t http_rtt_ms = http_rtt.InMilliseconds() <= INT32_MAX
                                    ? static_cast<int32_t>(http_rtt.InMilliseconds())
                                    : INT32_MAX;
      int32_t transport_rtt_ms = transport_rtt.InMilliseconds() <= INT32_MAX
                  ? static_cast<int32_t>(transport_rtt.InMilliseconds())
                  : INT32_MAX;
      if (get_nqe_result_callback_) {
        get_nqe_result_callback_(http_rtt.InMilliseconds(), transport_rtt.InMilliseconds(), downstream_throughput_kbps);
      }
    }

    void AddNQEObserverOnNetworkThread() {
      if (gChromeNet.Get()->GetURLRequestContext()->network_quality_estimator()) {
        gChromeNet.Get()->GetURLRequestContext()->network_quality_estimator()->AddRTTAndThroughputEstimatesObserver(this);
      }
    }
  private:
    GetNqeResultBlock get_nqe_result_callback_;
};

class PacketLossRateObserver : public net::TTPacketLossObserver {
  public:
    PacketLossRateObserver(GetPacketLossResultBlock get_result_callback) : get_result_callback_(get_result_callback) {}

    void OnPacketLossComputed(net::PacketLossAnalyzerProtocol protocol,
                              double send_loss_rate,
                              double send_loss_variance,
                              double receive_loss_rate,
                              double receive_loss_variance) override {
      if (get_result_callback_) {
        get_result_callback_((TTPacketLossProtocol)protocol, send_loss_rate, send_loss_variance, receive_loss_rate, receive_loss_variance);
      }
    }

    void AddObserverOnNetworkThread() {
        net::TTPacketLossEstimator::GetInstance()->AddPacketLossObserver(this);
    }
  private:
    GetPacketLossResultBlock get_result_callback_;
};

class TTNetworkQualityLevelObserver : public net::TTNetworkQualityEstimator::NQLObserver {
  public:
    TTNetworkQualityLevelObserver(GetNqeResultBlock nqe_v2_result_callback) : nqe_v2_result_callback_(nqe_v2_result_callback) {
    }
    void OnNQLChanged(net::TTNetworkQualityLevel nql) override {
        LOGD(@"OnNQLChanged, nql: %d", nql);
        NSDictionary *dict = @{@"nql":@(nql)};
        [[NSNotificationCenter defaultCenter] postNotificationName:kTTNetNetworkQualityLevelNotification object:nil userInfo:dict];
    }

    void OnNetworkQualityRttAndThroughputNotified(
        int effective_hrtt,
        int effective_trtt,
        int effective_rx_throughput) override {
      if (nqe_v2_result_callback_) {
          nqe_v2_result_callback_(effective_hrtt, effective_trtt, effective_rx_throughput);
      }
    }

    void AddObserverOnNetworkThread() {
        LOGD(@"AddObserverOnNetworkThread");
        if (gChromeNet.Get()) {
            gChromeNet.Get()->AddNetworkQualityLevelObserver(this);
        }
    }
  private:
    GetNqeResultBlock nqe_v2_result_callback_;
};

#if !defined(DISABLE_WIFI_TO_CELL)
class MultiNetworkStateObserver : public net::TTMultiNetworkManager::StateChangeObserver {
  public:
    void OnMultiNetworkStateChanged(net::TTMultiNetworkManager::State previous_state,
                                    net::TTMultiNetworkManager::State current_state) override {
        gChromeNet.Get()->CheckMultiNetworkNativeCallback(previous_state, current_state);
        NSInteger pre_state = previous_state;
        NSInteger cur_state = current_state;
        LOGD(@"OnMultiNetworkStateChanged, previous state: %d, current state: %d", previous_state, current_state);
        NSDictionary *dict = @{@"previous_state":@(pre_state),@"current_state":@(cur_state)};
        [[NSNotificationCenter defaultCenter] postNotificationName:kTTNetMultiNetworkStateNotification object:nil userInfo:dict];
    }

    void AddObserverOnNetworkThread() {
        LOGD(@"AddObserverOnNetworkThread");
        if (gChromeNet.Get()) {
            gChromeNet.Get()->AddMultiNetworkStateObserver(this);
        }
    }
};
#endif
#endif
class SendFeedBackMonitor : public net::TTMonitorProvider {
public:
    virtual void SendMonitor(const std::string &json, const std::string &log_type) {
        Monitorblock monitorBlock = ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).monitorblock;
        if (!monitorBlock) {
            return ;
        }
        
        NSString *jsonString = [NSString stringWithUTF8String:json.c_str()];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        if (!jsonData) {
            LOGE(@"jsonData is nil");
            return;
        }
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&error];
        if (!error) {
            NSString *logType = [NSString stringWithUTF8String:log_type.c_str()];
            monitorBlock(dict, logType);
        }
    }
    
    bool ValidApiParams(const std::string& uuid,
                        const std::string& url,
                        const std::string& method) {
        if (url.empty() || uuid.empty() || method.empty()) {
            LOGD(@"HandleApiResult, params emtpy");
            return false;
        }
        
        const char * url_cstr = url.c_str();
        const char * uuid_cstr = uuid.c_str();
        const char * method_cstr = method.c_str();
        
        if (!url_cstr || !uuid_cstr || !method_cstr) {
            LOGD(@"HandleApiResult, params null");
            return false;
        }
        
        return true;
    }
    
    virtual void HandleApiStart(const std::string& uuid,
                                const std::string& url,
                                const std::string& method) {
        if (!ValidApiParams(url, uuid, method)) {
            LOGD(@"HandleApiResult, params emtpy");
            return;
        }
        
        NSString * urlStr = [NSString stringWithUTF8String:url.c_str()];
        NSString * methodStr = [NSString stringWithUTF8String:method.c_str()];
        NSString * uuidStr = [NSString stringWithUTF8String:uuid.c_str()];
        
        LOGD(@"HandleApiResult, uuid: %@ url: %@ method: %@", uuidStr, urlStr, methodStr);
        
        TTHttpRequestChromium * request = [[TTHttpRequestChromium alloc] initWithURL:urlStr method:methodStr multipartForm:nil];
        objc_setAssociatedObject(request, (const void *)@"kTTNetworkMonitorRequestIDKey", uuidStr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [[TTNetworkManagerMonitorNotifier defaultNotifier] notifyForMonitorStartRequest:request hasTriedTimes:0];
    }
    
    virtual void HandleApiResult(const std::string& uuid,
                                 bool succ,
                                 const std::string& url,
                                 const std::string& method,
                                 const std::string& traceCode,
                                 int64_t app_start,
                                 int64_t request_start,
                                 int64_t response_back,
                                 int64_t response_complete,
                                 int64_t request_end,
                                 const net::URLFetcher* fetcher){
        if (!ValidApiParams(url, uuid, method)) {
            LOGD(@"HandleApiResult, params emtpy");
            return;
        }
        
        NSString * urlStr = [NSString stringWithUTF8String:url.c_str()];
        NSString * uuidStr = [NSString stringWithUTF8String:uuid.c_str()];
        NSString * methodStr = [NSString stringWithUTF8String:method.c_str()];
        LOGD(@"HandleApiResult, uuid: %@ succ: %d  url: %@ appstart: %lld", uuidStr, succ, urlStr, app_start);
        
        if (!fetcher) {
            LOGD(@"HandleApiResult, fetcher is null");
            return;
            
        }
                
        TTHttpRequestChromium * request = [[TTHttpRequestChromium alloc] initWithURL:urlStr method:methodStr multipartForm:nil];
        objc_setAssociatedObject(request, (const void *)@"kTTNetworkMonitorRequestIDKey", uuidStr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        NSError * error = nil;
        if (!succ) {
            error = [[NSError alloc] initWithDomain:kTTNetworkErrorDomain code:fetcher->GetError() userInfo:nil];
        }
        
        TTHttpResponseChromium *response = [[TTHttpResponseChromium alloc] initWithURLFetcher:fetcher];
        [[TTNetworkManagerMonitorNotifier defaultNotifier] notifyForMonitorFinishResponse:response forRequest:request error:error response:nil];
        
    }
};

class GetDomainObserver : public net::TTServerConfigObserver {
public:
    GetDomainObserver() {
        net::TTServerConfig *sharedTTServerConfig = net::TTServerConfig::GetInstance();
        sharedTTServerConfig->AddServerConfigObserver(this);
    }
    
    ~GetDomainObserver() {
        net::TTServerConfig *sharedTTServerConfig = net::TTServerConfig::GetInstance();
        sharedTTServerConfig->RemoveServerConfigObserver(this);
    }
    
    virtual void OnServerConfigChanged(UpdateSource source, const std::string &content) {
      NSString *contentString = [NSString stringWithUTF8String:content.c_str()];
      if (!contentString) {
        return;
      }

      NSData *data = [contentString dataUsingEncoding: NSUTF8StringEncoding];
      if (!data) {
        return;
      }

      NSError *jsonError = nil;
      id jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
      if (!jsonError && [jsonDict isKindOfClass:NSDictionary.class]) {
        NSDictionary *dict = (NSDictionary *)jsonDict;
        NSDictionary *data = [dict objectForKey:kTNCData];
        if (![data isKindOfClass:NSDictionary.class]) {
          return;
        }

#ifndef DISABLE_REQ_LEVEL_CTRL
        // For "runtime_req_ctl_config:{p0,p2,...}"
        [[TTNetRequestLevelController shareInstance] getReqCtlConfig:data];
#endif

        int timeout = g_request_timeout;
        id value = [data objectForKey:kTTNetRequestTimeout];
        if (value && [value isKindOfClass:[NSString class]]) {
          timeout = [(NSString *)value intValue];
        } else if (value && [value isKindOfClass:[NSNumber class]]) {
          timeout = [(NSNumber *)value intValue];
        }

        if (timeout != g_request_timeout && timeout > 0) {
          LOGI(@"default request timeout changed from %d to %d", g_request_timeout, timeout);
          g_request_timeout = timeout;
        }

        int count = g_request_count_network_changed;
        id valueCount = [data objectForKey:kTTNetReqCountNetworkChanged];
        if (valueCount && [valueCount isKindOfClass:[NSString class]]) {
          count = [(NSString *)valueCount intValue];
        } else if (valueCount && [valueCount isKindOfClass:[NSNumber class]]) {
          count = [(NSNumber *)valueCount intValue];
        }

        if (count != g_request_count_network_changed) {
          LOGI(@"default request_count_network_changed changed from %d to %d", g_request_count_network_changed, count);
          g_request_count_network_changed = count;
        }

        id ttnet_response_verify_enabled = [data objectForKey:kTTNetResponseVerifyEnabled];
        if (ttnet_response_verify_enabled && [ttnet_response_verify_enabled isKindOfClass:[NSNumber class]]) {
            BOOL verify_enabled = [(NSNumber *)ttnet_response_verify_enabled intValue] > 0;
            [[TTCdnCacheVerifyManager shareInstance] onConfigChange:verify_enabled data:data];
        }

        // handle frontier urls callback
        FrontierUrlsCallbackBlock frontierUrlsCallbackBlock =
          ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).frontierUrlsCallbackblock;
        if (frontierUrlsCallbackBlock) {
          id frontier_urls = [data objectForKey:kTTNetFrontierUrls];
          if (frontier_urls && [frontier_urls isKindOfClass:[NSArray class]]) {
              frontierUrlsCallbackBlock((NSArray *)frontier_urls);
          }
        }
          
        [TTNetworkManagerChromium shareInstance].shareCookieDomainNameList = [data objectForKey:kTTNetShareCookieHostList];

        if ([TTNetworkManagerChromium shareInstance].enableApiHttpIntercept) {
          id apiHttpHostListArray = [data objectForKey:kTTNetApiHttpHostList];
            if (apiHttpHostListArray && [apiHttpHostListArray isKindOfClass:[NSArray class]]) {
                [TTNetworkManager shareInstance].apiHttpHostListArray = (NSArray *)apiHttpHostListArray;
            }
        }
        
        //parse concurrent request config
        id concurrentRequestConfig = [data objectForKey:kTTNetworkConcurrentRequestConfig];
        if (concurrentRequestConfig && [concurrentRequestConfig isKindOfClass:NSDictionary.class]) {
            ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).concurrentRequestConfig = (NSDictionary *)concurrentRequestConfig;
        }
        
        [TTConcurrentHttpTask clearMatchRules:(NSDictionary *)concurrentRequestConfig];
          
        //parse new common parameters v2 config
        id commonParamsConfig = [data objectForKey:kTNCAddCommonParams];
        if (commonParamsConfig && [commonParamsConfig isKindOfClass:NSDictionary.class]) {
            [TTNetworkUtil.class parseCommonParamsConfig:commonParamsConfig];
        }
          
        //parse query filter engine config
        [[QueryFilterEngine shareInstance] parseTNCQueryFilterConfig:data];
        
        //parse L0 common parameter
        id commonParamsL0Array = [data objectForKey:kTNCL0Params];
        if (commonParamsL0Array && [commonParamsL0Array isKindOfClass:NSArray.class]) {
            ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).commonParamsL0Level = commonParamsL0Array;
        }
        
        //parse webview image check config
        id isWebviewImageCheck = [data objectForKey:kTNCWebviewImageCheck];
        if (isWebviewImageCheck && [isWebviewImageCheck isKindOfClass:NSNumber.class]) {
          if ([isWebviewImageCheck integerValue] == 0) {
            ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).isWebviewImageCheck = NO;
          } else {
            ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).isWebviewImageCheck = YES;
          }
        }
        //if enable webview image check(if TNC doesn't set,TTNetworkManager turns on it default), parse domains which need check and bypass
        if (((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).isWebviewImageCheck) {
          id checkDomainList = [data objectForKey:kTNCImageCheckDomainList];
          if (checkDomainList && [checkDomainList isKindOfClass:NSArray.class]) {
            ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).imageCheckDomainList = checkDomainList;
          }
          
          id bypassDomainList = [data objectForKey:kTNCImageCheckBypassDomainList];
          if (bypassDomainList && [bypassDomainList isKindOfClass:NSArray.class]) {
            ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).imageCheckBypassDomainList = bypassDomainList;
          }
        }
      }

      @try {
          NSDictionary *dic = [NSDictionary dictionaryWithObject:data forKey:kTTNetServerConfigChangeDataKey];
          [[NSNotificationCenter defaultCenter] postNotificationName:kTTNetServerConfigChangeNotification object:nil userInfo:dic];
      } @catch (NSException *exception) {
      }

      GetDomainblock getDomainblock = ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).getDomainblock;
      if (!getDomainblock) {
        return;
      }
      getDomainblock(data);
    }

    void OnServerConfigChanged(UpdateSource source, const base::Optional<base::Value>& tnc_config_value) override {
      gChromeNet.Get()->OnServerConfigChangedNativeCallback(source, tnc_config_value);
    }
};

@interface TTNetworkManagerChromium() {
    ColdStartObserver *coldStartObserver_;
    NetDetectObserver *netDetectObserver_;
    TTDnsResolveObserver *ttDnsResolveObserver_;
    TTRequestInfoObserver *requestInfoObserver_;
#if !defined(DISABLE_NQE_SUPPORT)
    ConnectionTypeObserver *connectionTypeObserver_;
    NQEObserver *nqeObserver_;
    PacketLossRateObserver *packetLossRateObserver_;
    TTNetworkQualityLevelObserver *nqlObserver_;
#if !defined(DISABLE_WIFI_TO_CELL)
    MultiNetworkStateObserver *multiNetworkStateObserver_;
#endif
#endif
}

@property (nonatomic, strong) NSMutableDictionary<NSString *, TTHttpTask *> *taskMap;
@property (nonatomic, strong) dispatch_queue_t dispatch_queue;
//In BDTuring verify situation, callbackBlock must dispatch to concurrent queue
@property (nonatomic, strong) dispatch_queue_t concurrent_dispatch_queue;
@property (nonatomic, strong) dispatch_queue_t callback_dispatch_queue;
@property (nonatomic, strong) dispatch_queue_t serial_callback_dispatch_queue;
@property (nonatomic, assign) int max_disk_cache_size;
@property (nonatomic, assign) bool enable_verbose_log;
@property (nonatomic, copy, readwrite) NSString *userIdc;
@property (nonatomic, copy, readwrite) NSString *userRegion;
@property (nonatomic, copy, readwrite) NSString *regionSource;
@property (nonatomic, copy, readwrite) NSString *clientIP;
@property (nonatomic, copy, readwrite) NSString *componentVersion;
@property (atomic, strong) NSLock *taskIdLock;
@property (nonatomic, assign) UInt64 nextTaskId;
@property (atomic, assign) BOOL engineStarted;
@property (atomic, strong) NSCondition *engineStartedCondition;
@property (atomic, copy) NSString *ttnetProxyConfig;
@property (atomic, assign) BOOL ttnetBoeEnabled;
@end

@implementation TTNetworkManagerChromium

@synthesize userIdc = _userIdc;
@synthesize userRegion = _userRegion;
@synthesize regionSource = _regionSource;
@synthesize clientIP = _clinetIP;
@synthesize publicIPv4List = _publicIPv4List;
@synthesize publicIPv6List = _publicIPv6List;
@synthesize shareCookieDomainNameList = _shareCookieDomainNameList;
@synthesize componentVersion = _componentVersion;

+ (instancetype)shareInstance
{
    static id singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (id)init
{
    self = [super init];
    if (self) {

        self.defaultBinaryResponseSerializerClass = NSClassFromString(@"TTHTTPBinaryResponseSerializerBase");
        self.defaultRequestSerializerClass = NSClassFromString(@"TTHTTPRequestSerializerBaseChromium");
        self.defaultJSONResponseSerializerClass = NSClassFromString(@"TTHTTPJSONResponseSerializerBaseChromium");
        self.taskMap = [[NSMutableDictionary alloc] init];
        self.dispatch_queue = dispatch_queue_create("ttnet_dispatch_queue", DISPATCH_QUEUE_SERIAL);
        self.callback_dispatch_queue = dispatch_get_main_queue();
        self.serial_callback_dispatch_queue = dispatch_get_main_queue();

        self.enableHttpCache = YES;

        self.enableHttp2 = YES;
        self.enableQuic = NO;
        self.enableBrotli = NO;

        self.initNetworkThreadPriority = -1;
        
        self.componentVersion = [TTNetworkUtil loadTTNetOCVersionFromPlist];
        self.taskIdLock = [[NSLock alloc] init];
        self.nextTaskId = 0;
        self.engineStarted = NO;
        self.engineStartedCondition = [[NSCondition alloc] init];
        self.ttnetDnsOuterService = [[TTDnsOuterService alloc] init];
        self.currentImpl = TTNetworkManagerImplTypeLibChromium;
        coldStartObserver_ = nullptr;
        netDetectObserver_ = nullptr;
        ttDnsResolveObserver_ = nullptr;
        requestInfoObserver_ = nullptr;
#if !defined(DISABLE_NQE_SUPPORT)
        connectionTypeObserver_ = nullptr;
        nqeObserver_ = nullptr;
        packetLossRateObserver_ = nullptr;
        nqlObserver_ = nullptr;
#if !defined(DISABLE_WIFI_TO_CELL)
        multiNetworkStateObserver_ = nullptr;
#endif
#endif
        
        self.isWebviewImageCheck = NO;
        self.imageCheckPoint = 0.7;
        self.increasingStep = 0.15;
        
        self.scIpv6DetectEnabled = NO;
        self.enableRequestHeaderCaseInsensitive = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground_:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate_:) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (void)setUserIdcInternal:(NSString *)userIdc {
    self.userIdc = userIdc;
}

- (void)setUserRegionInternal:(NSString *)userRegion {
    self.userRegion = userRegion;
}

- (void)setRegionSourceInternal:(NSString *)regionSource {
    self.regionSource = regionSource;
}

- (void)setClientIPInternal:(NSString *)clientIP {
    self.clientIP = clientIP;
}

- (NSString *) defaultUserAgentString {
    if (!self.defaultUserAgent) {
        //bundleForClass won`t work in dynamic lib,use mainBundle
        NSBundle *bundle = [NSBundle mainBundle];
        //NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        // Attempt to find a name for this application
        NSString *appName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
        
        NSData *latin1Data = [appName dataUsingEncoding:NSUTF8StringEncoding];
        appName = [[NSString alloc] initWithData:latin1Data encoding:NSISOLatin1StringEncoding];
        
        // If we couldn't find one, we'll give up (and ASIHTTPRequest will use the standard CFNetwork user agent)
        if (!appName) {
            return nil;
        }
        
        NSString *appVersion = nil;
        NSString *marketingVersionNumber = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *developmentVersionNumber = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        if (marketingVersionNumber && developmentVersionNumber) {
            if ([marketingVersionNumber isEqualToString:developmentVersionNumber]) {
                appVersion = marketingVersionNumber;
            } else {
                appVersion = [NSString stringWithFormat:@"%@ rv:%@",marketingVersionNumber,developmentVersionNumber];
            }
        } else {
            appVersion = (marketingVersionNumber ? marketingVersionNumber : developmentVersionNumber);
        }
        
        NSString *deviceName;
        NSString *OSName;
        NSString *OSVersion;
        NSString *locale = [[NSLocale currentLocale] localeIdentifier];
        
        UIDevice *device = [UIDevice currentDevice];
        deviceName = [device model];
        OSName = [device systemName];
        OSVersion = [device systemVersion];
        
        self.defaultUserAgent = [NSString stringWithFormat:@"%@ %@ (%@; %@ %@; %@) Cronet", appName, appVersion, deviceName, OSName, OSVersion, locale];
    }
    return self.defaultUserAgent;
}


- (void) start {
  static bool isFirst = true;
  [self.taskIdLock lock];
  if (!isFirst) {
    [self.taskIdLock unlock];
    return;
  }
  isFirst = false;
  [self.taskIdLock unlock];

  [TTNetInitMetrics sharedManager].initTTNetStartTime = [[NSDate date] timeIntervalSince1970] * 1000;
  if (![NSThread isMainThread]) {
    /// sync wait here
    dispatch_sync(dispatch_get_main_queue(), ^{
      if (self.dontCallbackInMainThread) {
        self.callback_dispatch_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        self.serial_callback_dispatch_queue = self.dispatch_queue;
      }
      if (!self.defaultUserAgent) {
        self.defaultUserAgent = [self defaultUserAgentString];
      }
      [self startInMainThread_];
      if (self.enable_verbose_log) {
        logging::SetMinLogLevel(logging::LOG_VERBOSE);
      }
    });
  } else {
    if (self.dontCallbackInMainThread) {
      self.callback_dispatch_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
      self.serial_callback_dispatch_queue = self.dispatch_queue;
    }
    if (!self.defaultUserAgent) {
      self.defaultUserAgent = [self defaultUserAgentString];
    }
    [self startInMainThread_];
    if (self.enable_verbose_log) {
      logging::SetMinLogLevel(logging::LOG_VERBOSE);
    }
  }
  [TTNetInitMetrics sharedManager].initTTNetEndTime = [[NSDate date] timeIntervalSince1970] * 1000;

  [self.engineStartedCondition lock];
  self.engineStarted = YES;
  [self.engineStartedCondition broadcast];
  [self.engineStartedCondition unlock];
}

- (void)startInMainThread_ {
    [TTNetInitMetrics sharedManager].mainStartTime = [[NSDate date] timeIntervalSince1970] * 1000;
    cronet::EnsureInitialized();

    std::string user_agent = "Cronet";
    NSString *agent = [TTNetworkManager shareInstance].userAgent;
    if (agent != nil && [agent length] > 0) {
        user_agent = CPPSTR(agent) + std::string(" ") + user_agent;
    }

    gChromeNet.Get().reset(new cronet::CronetEnvironment(user_agent, true));
    cronet::SetAlogFunctionAddress((net::ALogWriteAdapter::tt_alogger_appender)android_funcAddr_bd_log_write_var());

    if (![[TTNetInitMetrics sharedManager] initMSSdk]) {
        LOGD(@"Init mssdk failed.");
    }
    
    net::TTAppInfoProvider* appInfoProvider = new AppInfoProviderImpl();
    net::TTAppInfoManager::GetInstance()->RegisterAppInfoProvider(appInfoProvider);
    
    if (!self.monitorblock) {
        NSCAssert(false, @"MonitorBlock must be set");
    }
    
    if (!([TTNetworkManager shareInstance].ServerConfigHostFirst &&
        [TTNetworkManager shareInstance].ServerConfigHostSecond &&
        [TTNetworkManager shareInstance].ServerConfigHostThird)) {
        NSCAssert(false, @"ServerConfigHostFirst,ServerConfigHostSecond and ServerConfigHostThird must be set");
    }
    SendFeedBackMonitor *sendFeedBackMonitor = new SendFeedBackMonitor();
    net::TTMonitorManager *monitorManger = net::TTMonitorManager::GetInstance();
    if (monitorManger) {
        monitorManger->AddMonitor(sendFeedBackMonitor);
    }
    
    // app level get domain observer
    new GetDomainObserver();
    
    if (!coldStartObserver_) {
        coldStartObserver_ = new ColdStartObserver();
    }
    gChromeNet.Get()->SetColdStartListener(coldStartObserver_);
    
    if (!netDetectObserver_) {
        netDetectObserver_ = new NetDetectObserver();
    }
    gChromeNet.Get()->SetNetDetectListener(netDetectObserver_);

    if (!ttDnsResolveObserver_) {
        ttDnsResolveObserver_ = new TTDnsResolveObserver();
    }
    
    if (!requestInfoObserver_) {
        requestInfoObserver_ = new TTRequestInfoObserver();
    }
    
    // TODO:taoyiyuan Export interface to access best host from route selection.
    
    gChromeNet.Get()->set_http2_enabled(true);
    gChromeNet.Get()->set_quic_enabled(false);
    gChromeNet.Get()->set_ssl_key_log_file_name(base::SysNSStringToUTF8(nil));
//    gChromeNet.Get()->set_http_cache(cronet::URLRequestContextConfig::DISABLED);
    
    if (self.httpDNSEnabled) {
        gChromeNet.Get()->SetHttpDnsEnabled(true);
    }
    
    gChromeNet.Get()->set_sc_ipv6_detect_enabled([TTNetworkManager shareInstance].scIpv6DetectEnabled);
    
    gChromeNet.Get()->set_get_domain_default_json(CPPSTR([TTRegionManager getdomainRegionConfig]));

    gChromeNet.Get()->SetStoreIdcRuleJSON(CPPSTR([TTNetworkManager shareInstance].storeIdcRuleJSON));

    NSArray* certificate = [TTNetworkManager shareInstance].ServerCertificate;
    if (certificate && [certificate count] > 0) {
        std::vector<std::string> server_certificate;
        for (NSData* element in certificate)
            server_certificate.emplace_back((const char*)[element bytes], [element length]);
        gChromeNet.Get()->InstallServerCertificate(server_certificate);
    }

    NSArray<TTClientCertificate *> * clientCertificates = [TTNetworkManager shareInstance].ClientCertificates;
    if (clientCertificates && [clientCertificates count] > 0) {
        for (TTClientCertificate* element in clientCertificates) {
            __block std::vector<std::string> host_lists;
            [element.HostsList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                host_lists.push_back(CPPSTR(obj));
            }];
            gChromeNet.Get()->AddClientCertificate(host_lists,
                std::string((const char*)[element.Certificate bytes], [element.Certificate length]),
                std::string((const char*)[element.PrivateKey bytes], [element.PrivateKey length]));
        }
    }

    NSArray<TTQuicHint *> * quicHints = [TTNetworkManager shareInstance].QuicHints;
    if (quicHints && [quicHints count] > 0) {
        for (TTQuicHint* element in quicHints) {
            gChromeNet.Get()->AddQuicHint(CPPSTR(element.Host), element.Port, element.AlterPort);
        }
    }

    if ([TTNetworkManager shareInstance].enableQuic) {
        gChromeNet.Get()->set_quic_enabled(true);
    }

    if ([TTNetworkManager shareInstance].enableHttp2) {
        gChromeNet.Get()->set_http2_enabled(true);
    }

    if ([TTNetworkManager shareInstance].enableBrotli) {
        gChromeNet.Get()->set_brotli_enabled(true);
    }

    if ([self.ttnetProxyConfig length] > 0) {
      gChromeNet.Get()->SetProxyConfig(base::SysNSStringToUTF8(self.ttnetProxyConfig));
    }
    if (self.ttnetBoeEnabled) {
      gChromeNet.Get()->SetBoeEnabled(true, CPPSTR([TTNetworkManager shareInstance].bypassBoeJSON));
    }

    if (![TTNetworkManager shareInstance].enableHttpCache) {
        gChromeNet.Get()->set_http_cache(cronet::URLRequestContextConfig::HttpCacheType::DISABLED);
    } else {
        if ([TTNetworkManager shareInstance].httpCacheSize > 0) {
            gChromeNet.Get()->SetMaxHttpDiskCacheSize([TTNetworkManager shareInstance].httpCacheSize);
        }
    }
    
    if ([TTNetworkManager shareInstance].initNetworkThreadPriority >= 0) {
        gChromeNet.Get()->SetInitNetworkThreadPriority([TTNetworkManager shareInstance].initNetworkThreadPriority);
    }

    gChromeNet.Get()->Start();
    
    //    NSString *log = [NSString stringWithFormat:@"%@/netlog_%@.json", [self.class applicationDocumentsDirectory], [NSDate date]];
    //    gChromeNet.Get()->StartNetLog(base::SysNSStringToUTF8(log), NO);
    
    if (ttDnsResolveObserver_) {
        gChromeNet.Get()
        ->GetURLRequestContextGetter()
        ->GetNetworkTaskRunner()
        ->PostTask(FROM_HERE,
                   base::Bind(&TTDnsResolveObserver::AddObserverOnNetworkThread,
                              base::Unretained(ttDnsResolveObserver_)));
    }
    
    if (requestInfoObserver_) {
        gChromeNet.Get()
        ->GetURLRequestContextGetter()
        ->GetNetworkTaskRunner()
        ->PostTask(FROM_HERE,
                   base::Bind(&TTRequestInfoObserver::AddObserverOnNetworkThread,
                              base::Unretained(requestInfoObserver_)));
    }


#if !defined(DISABLE_NQE_SUPPORT)
    // This can only be called after CronetEnvironmnet::Start() because the NQE is initialized in InitializeOnNetworkThead().
    if (nqeObserver_) {
        gChromeNet.Get()
        ->GetURLRequestContextGetter()
        ->GetNetworkTaskRunner()
        ->PostTask(FROM_HERE,
                   base::Bind(&NQEObserver::AddNQEObserverOnNetworkThread,
                              base::Unretained(nqeObserver_)));
    }
    if (packetLossRateObserver_) {
        gChromeNet.Get()
        ->GetURLRequestContextGetter()
        ->GetNetworkTaskRunner()
        ->PostTask(FROM_HERE,
                   base::Bind(&PacketLossRateObserver::AddObserverOnNetworkThread,
                              base::Unretained(packetLossRateObserver_)));
    }
    if (!connectionTypeObserver_) {
        connectionTypeObserver_ = new ConnectionTypeObserver();
    }
    gChromeNet.Get()
    ->GetURLRequestContextGetter()
    ->GetNetworkTaskRunner()
    ->PostTask(FROM_HERE,
               base::Bind(&ConnectionTypeObserver::AddObserverOnNetworkThread,
                          base::Unretained(connectionTypeObserver_)));
    if (!nqlObserver_) {
        nqlObserver_ = new TTNetworkQualityLevelObserver(self.nqeV2block);
    }
    nqlObserver_->AddObserverOnNetworkThread();
    
#if !defined(DISABLE_WIFI_TO_CELL)
    if (!multiNetworkStateObserver_) {
        multiNetworkStateObserver_ = new MultiNetworkStateObserver();
    }
    multiNetworkStateObserver_->AddObserverOnNetworkThread();
#endif
#endif
    // Annotate the code to avoid blocking the main thread.
//    if ([TTNetworkManager shareInstance].hostResolverRulesForTesting) {
//        gChromeNet.Get()->SetHostResolverRules(CPPSTR([TTNetworkManager shareInstance].hostResolverRulesForTesting));
//    }
    [TTNetInitMetrics sharedManager].mainEndTime = [[NSDate date] timeIntervalSince1970] * 1000;
}

+ (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = paths.firstObject;
    return basePath;
}

- (void *)getEngine {
  return gChromeNet.Get().get();
}

#pragma mark - Common params

- (NSDictionary *)pickCommonParams:(NSURL *)requestURL {
    NSString *urlString = requestURL.absoluteString;
    NSDictionary * commonParams = nil;
    
    if (self.commonParamsblockWithURL) {
        commonParams = self.commonParamsblockWithURL(urlString);
    } else if (self.enableNewAddCommonParamsStrategy) {
        //new strategy
        NSString *host = requestURL.host;
        NSString *path = [TTNetworkUtil.class getRealPath:requestURL];
        
        if (![TTNetworkUtil.class isMatching:host pattern:kCommonMatch source:self.domainFilterArray]) {
            //do not match domain, won`t add any common parameters
            return nil;
        } else {
            if (self.getCommonParamsByLevelBlock) {
                //first determine whether max common parameter condition is met
                if ([TTNetworkUtil.class isPathMatching:path pathFilterDictionary:self.maxParamsPathFilterDict]) {
                    //add max common paramter
                    return self.getCommonParamsByLevelBlock(0);
                }
                //second determine whether min common paramter condition is met
                if ([TTNetworkUtil.class isPathMatching:path pathFilterDictionary:self.minParamsPathFilterDict]) {
                    //add min common paramter, excluding params in TNC's min_params_exclude config
                    return [TTNetworkUtil.class getMinExcludingCommonParams:self.getCommonParamsByLevelBlock(1)];
                }
                //both mismatch, add common parameter according to enableMinCommonParamsWhenDomainMatch
                if (self.enableMinCommonParamsWhenDomainMatch) {
                    //return self.getCommonParamsByLevelBlock(1);
                    return [TTNetworkUtil.class getMinExcludingCommonParams:self.getCommonParamsByLevelBlock(1)];
                } else {
                    return self.getCommonParamsByLevelBlock(0);
                }
            } else {
                LOGI(@"match domain, but getCommonParamsByLevelBlock not set!");
                return nil;
            }
        }
    } else {
        //old strategy
        if (self.commonParamsblock) {
            commonParams = self.commonParamsblock();
        }
        if (![commonParams isKindOfClass:[NSDictionary class]] ||
            [commonParams count] == 0) {
            commonParams = self.commonParams;
        }
    }
    
    return commonParams;
}

- (NSDictionary *)needCommonParams:(BOOL)need requestURL:(NSURL *)requestURL {
    if (!need) {
        return nil;
    }
    return [self pickCommonParams:requestURL];
}

- (UInt64)nextTaskId {
    UInt64 new_id;
    [self.taskIdLock lock];
    new_id = _nextTaskId++;
    [self.taskIdLock unlock];
    return new_id;
}

- (void)addTaskWithId_:(UInt64)taskId task:(TTHttpTask *)task {
    [self.taskIdLock lock];
    [self.taskMap setValue:task forKey:[@(taskId) stringValue]];
    [self.taskIdLock unlock];
}

- (void)removeTaskWithId_:(UInt64)taskId {
    [self.taskIdLock lock];
    [self.taskMap removeObjectForKey:[@(taskId) stringValue]];
    [self.taskIdLock unlock];
}

- (BOOL)hasTaskIdInMap:(UInt64)taskId {
    [self.taskIdLock lock];
    BOOL result = !![self.taskMap objectForKey:[@(taskId) stringValue]];
    [self.taskIdLock unlock];
    
    return result;
}

// Return YES means the request cannot block current thread, so have to fail
// it. Otherwise, the request will be blocked until the engine is started.
- (BOOL)ensureEngineStarted {
    if (self.engineStarted == NO) {
        BOOL returnValue = NO;
        [self.engineStartedCondition lock];
        while (self.engineStarted == NO) {
            if (![NSThread isMainThread]) {
                LOGE(@"wait engine in subthread");
                if ([self.engineStartedCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:60]]) {
                    returnValue = NO;
                } else {
                    NSAssert(NO, @"This request is blocked over 60 seconds before TTNetworkManager is started!");
                    returnValue = YES;
                    break;
                }
            } else {
                NSAssert(NO, @"This request is shot on main thread before TTNetworkManager is started!");
                returnValue = YES;
                break;
            }
        }
        [self.engineStartedCondition unlock];
        return returnValue;
    }
    return NO;
}

- (BOOL)apiHttpInterceptor:(TTHttpRequest *) request {
    if (self.enableApiHttpIntercept && self.apiHttpHostListArray) {
        Monitorblock monitorBlock = ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).monitorblock;
        if (!monitorBlock) {
            return NO;
        }
        NSURL *nsurl = request.URL;
        if (!nsurl) {
            LOGE(@"NSURL is nil in apiHttpInterceptor");
            return NO;
        }
        NSString *scheme = nsurl.scheme;
        NSString *host = nsurl.host;
        NSString *path = nsurl.path;
        if ([scheme isEqualToString:@"http"]) {
            BOOL isMatched = NO;
            for (NSString *urlSuffixs in self.apiHttpHostListArray) {
                if ([host hasSuffix:urlSuffixs]) {
                    isMatched = YES;
                    break;
                }
            }
            if (isMatched) {
                //scheme为http且endwith命中api_http_host_list
                //上报log_type:api_http，上报字段格式：{url: host+path}
                NSString *logType = @"api_http";
                NSString *host_path = [host stringByAppendingString:path];
                NSDictionary *monitorDict = [NSDictionary dictionaryWithObjectsAndKeys:host_path,@"url",nil];
                monitorBlock(monitorDict, logType);
                return YES;
            }
        }
    }
    return NO;
}


#pragma mark - Response Model Request Use RequestModel

- (TTHttpTask *)requestModel:(TTRequestModel *)model
                    callback:(TTNetworkResponseModelFinishBlock)callback
{
    return [self requestModel:model
            requestSerializer:self.defaultRequestSerializerClass
           responseSerializer:self.defaultResponseModelResponseSerializerClass
                   autoResume:YES
                     callback:callback];
}

- (TTHttpTask *)requestModel:(TTRequestModel *)model
                    callback:(TTNetworkResponseModelFinishBlock)callback
        callbackInMainThread:(BOOL)callbackInMainThread {
    return [self requestModel:model
            requestSerializer:self.defaultRequestSerializerClass
           responseSerializer:self.defaultResponseModelResponseSerializerClass
                   autoResume:YES
                     callback:callback
         callbackInMainThread:callbackInMainThread];
}

- (TTHttpTask *)requestModel:(TTRequestModel *)model
           requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
          responseSerializer:(Class<TTResponseModelResponseSerializerProtocol>)responseSerializer
                  autoResume:(BOOL)autoResume
                    callback:(TTNetworkResponseModelFinishBlock)callback {
    return [self requestModel:model
            requestSerializer:requestSerializer
           responseSerializer:responseSerializer
                   autoResume:autoResume
                     callback:callback
         callbackWithResponse:nil
               dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestModelWithResponse:(TTRequestModel *)model
                       requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                      responseSerializer:(Class<TTResponseModelResponseSerializerProtocol>)responseSerializer
                              autoResume:(BOOL)autoResume
                                callback:(TTNetworkModelFinishBlockWithResponse)callbackWithResponse {
    return [self requestModel:model
            requestSerializer:requestSerializer
           responseSerializer:responseSerializer
                   autoResume:autoResume
                     callback:nil
         callbackWithResponse:callbackWithResponse
               dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestModel:(TTRequestModel *)model
           requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
          responseSerializer:(Class<TTResponseModelResponseSerializerProtocol>)responseSerializer
                  autoResume:(BOOL)autoResume
                    callback:(TTNetworkResponseModelFinishBlock)callback
        callbackInMainThread:(BOOL)callbackInMainThread {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    if (callbackInMainThread) {
        queue = dispatch_get_main_queue();
    }
    return [self requestModel:model
            requestSerializer:requestSerializer
           responseSerializer:responseSerializer
                   autoResume:autoResume
                     callback:callback
         callbackWithResponse:nil
               dispatch_queue:queue];
}

- (TTHttpTask *)requestModel:(TTRequestModel *)model
           requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
          responseSerializer:(Class<TTResponseModelResponseSerializerProtocol>)responseSerializer
                  autoResume:(BOOL)autoResume
                    callback:(TTNetworkResponseModelFinishBlock)callback
               callbackQueue:(dispatch_queue_t)callbackQueue
{
    return [self requestModel:model
            requestSerializer:requestSerializer
           responseSerializer:responseSerializer
                   autoResume:autoResume
                     callback:callback
         callbackWithResponse:nil
               dispatch_queue:callbackQueue];
}

- (TTHttpTask *)requestModel:(TTRequestModel *)model
           requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
          responseSerializer:(Class<TTResponseModelResponseSerializerProtocol>)responseSerializer
                  autoResume:(BOOL)autoResume
                    callback:(TTNetworkResponseModelFinishBlock)callback
        callbackWithResponse:(TTNetworkModelFinishBlockWithResponse)callbackWithResponse
              dispatch_queue:(dispatch_queue_t)dispatch_queue {
#ifdef FULL_API_CONCURRENT_REQUEST
    TTConcurrentHttpTask *concurrentTask = [TTConcurrentHttpTask buildModelConcurrentTask:model
                                                        requestSerializer:requestSerializer
                                                       responseSerializer:responseSerializer
                                                               autoResume:autoResume
                                                                 callback:callback
                                                                     callbackWithResponse:callbackWithResponse
                                                           dispatch_queue:dispatch_queue
                                                                  concurrentRequestConfig:self.concurrentRequestConfig];
    if (concurrentTask) {
        return concurrentTask;
    }
    
    return [self buildModelHttpTask:model
                  requestSerializer:requestSerializer
                 responseSerializer:responseSerializer
                         autoResume:autoResume
                           callback:callback
               callbackWithResponse:callbackWithResponse
                     dispatch_queue:dispatch_queue];
}

- (TTHttpTaskChromium *)buildModelHttpTask:(TTRequestModel *)model
                 requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                responseSerializer:(Class<TTResponseModelResponseSerializerProtocol>)responseSerializer
                        autoResume:(BOOL)autoResume
                          callback:(TTNetworkResponseModelFinishBlock)callback
                      callbackWithResponse:(TTNetworkModelFinishBlockWithResponse)callbackWithResponse
                    dispatch_queue:(dispatch_queue_t)dispatch_queue {
#endif /* FULL_API_CONCURRENT_REQUEST */
    NSDate *startBizTime = [NSDate date];
    if (!requestSerializer) {
        requestSerializer = self.defaultRequestSerializerClass;
    }
    if (!responseSerializer) {
        responseSerializer = self.defaultResponseModelResponseSerializerClass;
    }
    
    
    NSString *requestURL = [[model _requestURL] absoluteString];
    NSURL *nsurl = [TTNetworkUtil.class isValidURL:requestURL callback:callback callbackWithResponse:callbackWithResponse];
    if (!nsurl) {
        return nil;
    }
    NSDictionary *commonParams = [self needCommonParams:!model._isNoNeedCommonParams requestURL:nsurl];
    
    NSDate *startSerializerTime = [NSDate date];
    TTHttpRequest *request = [[requestSerializer serializer] URLRequestWithRequestModel:model commonParams:commonParams];
    if (request) {
        NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
        [request.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(requestSerializer.class)];
        
        request.startBizTime = startBizTime;
    }
        
    if (!request || [self apiHttpInterceptor:request]) {
//        NSAssert(false, @"no request created!");
        NSDictionary *userInfo = nil;
        NSString *reason = nil;
        NSInteger specificErrorCode = 0;
        if (!request) {
            LOGE(@"Can not construct TTHttpRequest!");
            reason = @"Cannot construct TTHttpRequest";
            specificErrorCode = TTNetworkErrorCodeBadURLRequest;
        } else {
            reason = @"request has been intercepted by  the api http interceptor";
            specificErrorCode = TTNetworkErrorCodeApiHttpIntercepted;
        }
        if ([model _host]) {
            userInfo = @{kTTNetSubErrorCode : @(specificErrorCode), NSLocalizedDescriptionKey : reason, NSURLErrorFailingURLErrorKey : [model _host]};
        }
        NSError *resultError =  [NSError errorWithDomain:kTTNetworkErrorDomain code:specificErrorCode userInfo:userInfo];
        if (callback) {
            callback(resultError, nil);
        }

        if (callbackWithResponse) {
            callbackWithResponse(resultError, nil, nil);
        }
        return nil;
    }

    if ([commonParams count] > 0) {
      try {
        [TTHTTPRequestSerializerBase hashRequest:request body:request.HTTPBody];
      } catch (...) {

      }
    }
    
    UInt64 taskId = [self nextTaskId];
    id<TTResponsePreProcessorProtocol> preprocessor = nil;
    if (self.defaultResponseRreprocessorClass) {
        preprocessor = [self.defaultResponseRreprocessorClass processor];
    }
    
    __weak typeof(self) wself = self;
    
    OnHttpTaskCompletedCallbackBlock deserializingAndCallbackBlock = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {

        if (wself.responseFilterBlock) {
          wself.responseFilterBlock(request, response, data, responseError);
        }
        
        [[TTReqFilterManager shareInstance] runResponseFilter:request response:response data:data responseError:&responseError];
        
        //run response filter block to change the raw data if the request meets requirement of DMT
        [[TTReqFilterManager shareInstance] runResponseMutableDataFilter:request response:response data:&data responseError:&responseError];
        
        // deserializing
        NSError *resultError = nil;
        NSDate *startSerializerTime = [NSDate date];
        NSObject<TTResponseModelProtocol> *responseObj = [[responseSerializer serializer] responseObjectForResponse:response
                                                                                                            jsonObj:data
                                                                                                       requestModel:model
                                                                                                      responseError:responseError
                                                                                                        resultError:&resultError];
        NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
        [response.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(responseSerializer.class)];
        
        // callback to upper layer
        TICK;
        dispatch_async(dispatch_queue, ^(void) {
            TOCK;
            if (callback) {
                callback(resultError, responseObj);
            }
            
            if (callbackWithResponse) {
                callbackWithResponse(resultError, responseObj, response);
            }
            
            // monitor request end
            [[TTNetworkManagerMonitorNotifier defaultNotifier] notifyForMonitorFinishResponse:response
                                                                                   forRequest:request
                                                                                        error:responseError
                                                                                     response:data];
        });
        
    }; // end of OnHttpTaskCompletedCallbackBlock deserializingAndCallbackBlock
    
    OnHttpTaskCompletedCallbackBlock oneHttpRequestCompletedCallbackBlock = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {
        
        [wself removeTaskWithId_:taskId];
        //handle verification code related callback
        //only retry 1 time
        BOOL handleBDTuringResult = [wself handleBDTuringCallback:request
                                                         response:response
                                                 redirectCallback:nil
                                                   headerCallback:nil
                                                     dataCallback:nil
                                    deserializingAndCallbackBlock:deserializingAndCallbackBlock];
        
        if (handleBDTuringResult) {
            return;
        }
        
        // do preprocessing
        if (preprocessor) {
            BOOL needRetry = [wself handleResponsePreProcessing_:response data:data error:responseError request:request preprocessor:preprocessor headerCallback:nil dataCallback:nil completedCallback:deserializingAndCallbackBlock];
            
            if (needRetry) {
                LOGD(@"%s preprocessor needs retry the request: %@", __FUNCTION__, request.URL);
                return;
            }
        }
        
        deserializingAndCallbackBlock(response, data, responseError);
    }; // end of OnHttpTaskCompletedCallbackBlock oneHttpRequestCompletedCallbackBlock
    
    TTHttpTaskChromium *task = [[TTHttpTaskChromium alloc] initWithRequest:(TTHttpRequestChromium *)request
                                                                    engine:gChromeNet.Get().get()
                                                            dispatchQueue:self.dispatch_queue
                                                                    taskId:taskId
                                                         completedCallback:oneHttpRequestCompletedCallbackBlock];
    
    [self addTaskWithId_:taskId task:task];
    
    if (autoResume) {
        [task resume];
    }
    
    return task;
}

#pragma mark - Response JSON Request User URL

- (TTHttpTask *)requestForJSONWithURL:(NSString *)URL
                               params:(id)params
                               method:(NSString *)method
                     needCommonParams:(BOOL)commonParams
                             callback:(TTNetworkJSONFinishBlock)callback
{
    return [self requestForJSONWithURL_:URL
                                 params:params
                                 method:method
                       needCommonParams:commonParams
                            headerField:nil
                      requestSerializer:self.defaultRequestSerializerClass
                     responseSerializer:self.defaultJSONResponseSerializerClass
                             autoResume:YES
                          verifyRequest:NO
                     isCustomizedCookie:NO
                               callback:callback
                   callbackWithResponse:nil
                         dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestForJSONWithURL:(NSString *)URL
                               params:(id)params
                               method:(NSString *)method
                     needCommonParams:(BOOL)commonParams
                             callback:(TTNetworkJSONFinishBlock)callback
                 callbackInMainThread:(BOOL)callbackInMainThread {

  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  if (callbackInMainThread) {
    queue = dispatch_get_main_queue();
  }
  return [self requestForJSONWithURL_:URL
                               params:params
                               method:method
                     needCommonParams:commonParams
                          headerField:nil
                    requestSerializer:self.defaultRequestSerializerClass
                   responseSerializer:self.defaultJSONResponseSerializerClass
                           autoResume:YES
                        verifyRequest:NO
                   isCustomizedCookie:NO
                             callback:callback
                 callbackWithResponse:nil
                       dispatch_queue:queue];
}

- (TTHttpTask *)requestForJSONWithURL:(NSString *)URL
                               params:(id)params
                               method:(NSString *)method
                     needCommonParams:(BOOL)commonParams
                    requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                   responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                           autoResume:(BOOL)autoResume
                             callback:(TTNetworkJSONFinishBlock)callback
{
    return [self requestForJSONWithURL_:URL
                                 params:params
                                 method:method
                       needCommonParams:commonParams
                            headerField:nil
                      requestSerializer:requestSerializer
                     responseSerializer:responseSerializer
                             autoResume:autoResume
                          verifyRequest:NO
                     isCustomizedCookie:NO
                               callback:callback
                   callbackWithResponse:nil
                         dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestForJSONWithResponse:(NSString *)URL
                                    params:(id)params
                                    method:(NSString *)method
                          needCommonParams:(BOOL)commonParams
                                  callback:(TTNetworkJSONFinishBlockWithResponse)callback
{
    return [self requestForJSONWithURL_:URL
                                 params:params
                                 method:method
                       needCommonParams:commonParams
                            headerField:nil
                      requestSerializer:self.defaultRequestSerializerClass
                     responseSerializer:self.defaultJSONResponseSerializerClass
                             autoResume:YES
                          verifyRequest:NO
                     isCustomizedCookie:NO
                               callback:nil
                   callbackWithResponse:callback
                         dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestForJSONWithResponse:(NSString *)URL
                                    params:(id)params
                                    method:(NSString *)method
                          needCommonParams:(BOOL)commonParams
                         requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                        responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                autoResume:(BOOL)autoResume
                                  callback:(TTNetworkJSONFinishBlockWithResponse)callback
{
    return [self requestForJSONWithURL_:URL
                                 params:params
                                 method:method
                       needCommonParams:commonParams
                            headerField:nil
                      requestSerializer:requestSerializer
                     responseSerializer:responseSerializer
                             autoResume:autoResume
                          verifyRequest:NO
                     isCustomizedCookie:NO
                               callback:nil
                   callbackWithResponse:callback
                         dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestForJSONWithResponse:(NSString *)URL
                                    params:(id)params
                                    method:(NSString *)method
                          needCommonParams:(BOOL)commonParams
                               headerField:(NSDictionary *)headerField
                         requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                        responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                autoResume:(BOOL)autoResume
                                  callback:(TTNetworkJSONFinishBlockWithResponse)callback {
    return [self requestForJSONWithURL_:URL
                                 params:params
                                 method:method
                       needCommonParams:commonParams
                            headerField:headerField
                      requestSerializer:requestSerializer
                     responseSerializer:responseSerializer
                             autoResume:autoResume
                          verifyRequest:NO
                     isCustomizedCookie:NO
                               callback:nil
                   callbackWithResponse:callback
                         dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestForJSONWithResponse:(NSString *)URL
                                    params:(id)params
                                    method:(NSString *)method
                          needCommonParams:(BOOL)commonParams
                               headerField:(NSDictionary *)headerField
                         requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                        responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                autoResume:(BOOL)autoResume
                             verifyRequest:(BOOL)verifyRequest
                        isCustomizedCookie:(BOOL)isCustomizedCookie
                                  callback:(TTNetworkJSONFinishBlockWithResponse)callback {
    return [self requestForJSONWithURL_:URL
                                 params:params
                                 method:method
                       needCommonParams:commonParams
                            headerField:headerField
                      requestSerializer:requestSerializer
                     responseSerializer:responseSerializer
                             autoResume:autoResume
                          verifyRequest:verifyRequest
                     isCustomizedCookie:isCustomizedCookie
                               callback:nil
                   callbackWithResponse:callback
                         dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestForJSONWithResponse:(NSString *)URL
                                    params:(id)params
                                    method:(NSString *)method
                          needCommonParams:(BOOL)commonParams
                               headerField:(NSDictionary *)headerField
                         requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                        responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                autoResume:(BOOL)autoResume
                             verifyRequest:(BOOL)verifyRequest
                        isCustomizedCookie:(BOOL)isCustomizedCookie
                                  callback:(TTNetworkJSONFinishBlockWithResponse)callback
                      callbackInMainThread:(BOOL)callbackInMainThread {

  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  if (callbackInMainThread) {
    queue = dispatch_get_main_queue();
  }

  return [self requestForJSONWithURL_:URL
                               params:params
                               method:method
                     needCommonParams:commonParams
                          headerField:headerField
                    requestSerializer:requestSerializer
                   responseSerializer:responseSerializer
                           autoResume:autoResume
                        verifyRequest:verifyRequest
                   isCustomizedCookie:isCustomizedCookie
                             callback:nil
                 callbackWithResponse:callback
                       dispatch_queue:queue];

}

- (TTHttpTask *)requestForJSONWithResponse:(NSString *)URL
                                    params:(id)params
                                    method:(NSString *)method
                          needCommonParams:(BOOL)commonParams
                               headerField:(NSDictionary *)headerField
                         requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                        responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                autoResume:(BOOL)autoResume
                             verifyRequest:(BOOL)verifyRequest
                        isCustomizedCookie:(BOOL)isCustomizedCookie
                                  callback:(TTNetworkJSONFinishBlockWithResponse)callback
                             callbackQueue:(dispatch_queue_t)callbackQueue
{
    return [self requestForJSONWithURL_:URL
                                 params:params
                                 method:method
                       needCommonParams:commonParams
                            headerField:headerField
                      requestSerializer:requestSerializer
                     responseSerializer:responseSerializer
                             autoResume:autoResume
                          verifyRequest:verifyRequest
                     isCustomizedCookie:isCustomizedCookie
                               callback:nil
                   callbackWithResponse:callback
                         dispatch_queue:callbackQueue];
}

- (TTHttpTask *)requestForJSONWithURL_:(NSString *)URL
                                params:(id)params
                                method:(NSString *)method
                      needCommonParams:(BOOL)needCommonParams
                           headerField:(NSDictionary *)headerField
                     requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                    responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                            autoResume:(BOOL)autoResume
                         verifyRequest:(BOOL)verifyRequest
                    isCustomizedCookie:(BOOL)isCustomizedCookie
                              callback:(TTNetworkJSONFinishBlock)callback
                  callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                        dispatch_queue:(dispatch_queue_t)dispatch_queue {
    TTConcurrentHttpTask *concurrentTask = [TTConcurrentHttpTask buildJSONConcurrentTask:URL
                                                                  params:params
                                                                  method:method
                                                        needCommonParams:needCommonParams
                                                             headerField:headerField
                                                       requestSerializer:requestSerializer
                                                      responseSerializer:responseSerializer
                                                              autoResume:autoResume
                                                           verifyRequest:verifyRequest
                                                      isCustomizedCookie:isCustomizedCookie
                                                                callback:callback
                                                    callbackWithResponse:callbackWithResponse
                                                          dispatch_queue:dispatch_queue
                                                 concurrentRequestConfig:self.concurrentRequestConfig];
    
    if (concurrentTask) {
        return concurrentTask;
    }
    
    return [self buildJSONHttpTask:URL
                            params:params
                            method:method
                  needCommonParams:needCommonParams
                       headerField:headerField
                 requestSerializer:requestSerializer
                responseSerializer:responseSerializer
                        autoResume:autoResume
                     verifyRequest:verifyRequest
                isCustomizedCookie:isCustomizedCookie
                          callback:callback
              callbackWithResponse:callbackWithResponse
                    dispatch_queue:dispatch_queue];
}


- (TTHttpTaskChromium *)buildJSONHttpTask:(NSString *)URL
                           params:(id)params
                           method:(NSString *)method
                 needCommonParams:(BOOL)needCommonParams
                      headerField:(NSDictionary *)headerField
                requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
               responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                       autoResume:(BOOL)autoResume
                    verifyRequest:(BOOL)verifyRequest
               isCustomizedCookie:(BOOL)isCustomizedCookie
                         callback:(TTNetworkJSONFinishBlock)callback
             callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                   dispatch_queue:(dispatch_queue_t)dispatch_queue {
    NSDate *startBizTime = [NSDate date];
    NSURL *nsurl = [TTNetworkUtil.class isValidURL:URL callback:callback callbackWithResponse:callbackWithResponse];
    if (!nsurl) {
        return nil;
    }
    NSDictionary *commonParams = [self needCommonParams:needCommonParams requestURL:nsurl];
    
    if (!requestSerializer) {
        requestSerializer = self.defaultRequestSerializerClass;
    }
    
    if (!responseSerializer) {
        responseSerializer = self.defaultJSONResponseSerializerClass;
    }
    
    TTHttpRequest *request = nil;
    NSDate *startSerializerTime = [NSDate date];
    if (headerField) {
        request = [[requestSerializer serializer] URLRequestWithURL:URL
                                                        headerField:headerField
                                                             params:params
                                                             method:method
                                              constructingBodyBlock:nil
                                                       commonParams:commonParams];
    } else {
        request =  [[requestSerializer serializer] URLRequestWithURL:URL
                                                              params:params
                                                              method:method
                                               constructingBodyBlock:nil
                                                        commonParams:commonParams];
    }
    if (request) {
        NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
        [request.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(requestSerializer.class)];
        
        request.startBizTime = startBizTime;
    }

    if (!request || [self apiHttpInterceptor:request]) {
//        NSAssert(false, @"no request created!");
        NSDictionary *userInfo = nil;
        NSString *reason = nil;
        NSInteger specificErrorCode = 0;
        if (!request) {
            LOGE(@"Can not construct TTHttpRequest!");
            reason = @"Cannot construct TTHttpRequest";
            specificErrorCode = TTNetworkErrorCodeBadURLRequest;
        } else {
            reason = @"request has been intercepted by  the api http interceptor";
            specificErrorCode = TTNetworkErrorCodeApiHttpIntercepted;
        }
        if (URL) {
            userInfo = @{kTTNetSubErrorCode : @(specificErrorCode), NSLocalizedDescriptionKey : reason, NSURLErrorFailingURLErrorKey : URL};
        }
        NSError *resultError =  [NSError errorWithDomain:kTTNetworkErrorDomain code:specificErrorCode userInfo:userInfo];
        if (callback) {
            callback(resultError, nil);
        }
        if (callbackWithResponse) {
            callbackWithResponse(resultError, nil, nil);
        }
        return nil;
    }

    if ([commonParams count] > 0 || verifyRequest) {
      try {
        [TTHTTPRequestSerializerBase hashRequest:request body:request.HTTPBody];
      } catch (...) {
      }
    }
    
    UInt64 taskId = [self nextTaskId];
    id<TTResponsePreProcessorProtocol> preprocessor = nil;
    if (self.defaultResponseRreprocessorClass) {
        preprocessor = [self.defaultResponseRreprocessorClass processor];
    }
    
    __weak typeof(self) wself = self;
    
    OnHttpTaskCompletedCallbackBlock deserializingAndCallbackBlock = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {

        if (wself.responseFilterBlock) {
          wself.responseFilterBlock(request, response, data, responseError);
        }
        
        [[TTReqFilterManager shareInstance] runResponseFilter:request response:response data:data responseError:&responseError];
        
        //run response filter block to change the raw data if the request meets requirement of DMT
        [[TTReqFilterManager shareInstance] runResponseMutableDataFilter:request response:response data:&data responseError:&responseError];
        
        // deserializing
        
        NSError *resultError = nil;
        NSDate *startSerializerTime = [NSDate date];
        id responseObj = [[responseSerializer serializer] responseObjectForResponse:response
                                                                            jsonObj:data
                                                                      responseError:responseError
                                                                        resultError:&resultError];
        NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
        [response.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(responseSerializer.class)];
        
        // callback to upper layer
        TICK;
        dispatch_async(dispatch_queue, ^(void) {
            TOCK;
            if (callback) {
                callback(resultError, responseObj);
            }
            
            if (callbackWithResponse) {
                callbackWithResponse(resultError, responseObj, response);
            }
            
            // monitor request end
            [[TTNetworkManagerMonitorNotifier defaultNotifier] notifyForMonitorFinishResponse:response
                                                                                   forRequest:request
                                                                                        error:responseError
                                                                                     response:data];
        });
    };
    
    OnHttpTaskCompletedCallbackBlock oneHttpRequestCompletedCallbackBlock = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {
        
        [wself removeTaskWithId_:taskId];
        //handle verification code related callback
        //only retry 1 time
        BOOL handleBDTuringResult = [wself handleBDTuringCallback:request
                                                         response:response
                                                 redirectCallback:nil
                                                   headerCallback:nil
                                                     dataCallback:nil
                                    deserializingAndCallbackBlock:deserializingAndCallbackBlock];
        
        if (handleBDTuringResult) {
            return;
        }
        
        // do preprocessing
        if (preprocessor) {
            BOOL needRetry = [wself handleResponsePreProcessing_:response data:data error:responseError request:request preprocessor:preprocessor headerCallback:nil dataCallback:nil completedCallback:deserializingAndCallbackBlock];
            
            if (needRetry) {
                LOGD(@"%s preprocessor needs retry the request: %@", __FUNCTION__, request.URL);
                return;
            }
        }
        
        deserializingAndCallbackBlock(response, data, responseError);
    };
    
    TTHttpTaskChromium *task = [[TTHttpTaskChromium alloc] initWithRequest:(TTHttpRequestChromium *)request
                                                                    engine:gChromeNet.Get().get()
                                                             dispatchQueue:self.dispatch_queue
                                                                    taskId:taskId
                                                         completedCallback:oneHttpRequestCompletedCallbackBlock];
    task.enableCustomizedCookie = isCustomizedCookie;
    task.taskType = TTNET_TASK_TYPE_API;
    [self addTaskWithId_:taskId task:task];
    
    if (autoResume) {
        [task resume];
    }
    
    return task;
}

#pragma mark - Setter

- (void)setPureChannelForJSONResponseSerializer:(BOOL)pureChannelForJSONResponseSerializer
{
    [super setPureChannelForJSONResponseSerializer:pureChannelForJSONResponseSerializer];
    
}

#pragma mark - Binary Model Request Use URL

- (TTHttpTask *)requestForBinaryWithURL:(NSString *)URL
                                 params:(id)params
                                 method:(NSString *)method
                       needCommonParams:(BOOL)commonParams
                               callback:(TTNetworkObjectFinishBlock)callback
{
    return [self requestForBinaryWithURL_:URL
                                   params:params
                                   method:method
                         needCommonParams:commonParams
                              headerField:nil
                          enableHttpCache:NO
                        requestSerializer:self.defaultRequestSerializerClass
                       responseSerializer:self.defaultBinaryResponseSerializerClass
                               autoResume:YES
                       isCustomizedCookie:NO
                           headerCallback:nil
                             dataCallback:nil
                                 callback:callback
                     callbackWithResponse:nil
                         redirectCallback:nil
                                 progress:nil
                           dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                      params:(id)params
                                      method:(NSString *)method
                            needCommonParams:(BOOL)commonParams
                                    callback:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
{
    return [self requestForBinaryWithURL_:URL
                                   params:params
                                   method:method
                         needCommonParams:commonParams
                              headerField:nil
                          enableHttpCache:NO
                        requestSerializer:self.defaultRequestSerializerClass
                       responseSerializer:self.defaultBinaryResponseSerializerClass
                               autoResume:YES
                       isCustomizedCookie:NO
                           headerCallback:nil
                             dataCallback:nil
                                 callback:nil
                     callbackWithResponse:callbackWithResponse
                         redirectCallback:nil
                                 progress:nil
                           dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                      params:(id)params
                                      method:(NSString *)method
                            needCommonParams:(BOOL)commonParams
                                 headerField:(NSDictionary *)headerField
                             enableHttpCache:(BOOL)enableHttpCache
                           requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                    progress:(NSProgress * __autoreleasing *)progress
                                    callback:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
{
    return [self requestForBinaryWithURL_:URL
                                   params:params
                                   method:method
                         needCommonParams:commonParams
                              headerField:headerField
                          enableHttpCache:enableHttpCache
                        requestSerializer:requestSerializer ?: self.defaultRequestSerializerClass
                       responseSerializer:responseSerializer ?: self.defaultBinaryResponseSerializerClass
                               autoResume:YES
                       isCustomizedCookie:NO
                           headerCallback:nil
                             dataCallback:nil
                                 callback:nil
                     callbackWithResponse:callbackWithResponse
                         redirectCallback:nil
                                 progress:progress
                           dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                      params:(id)params
                                      method:(NSString *)method
                            needCommonParams:(BOOL)needCommonParams
                                 headerField:(NSDictionary *)headerField
                             enableHttpCache:(BOOL)enableHttpCache
                                  autoResume:(BOOL)autoResume
                          isCustomizedCookie:(BOOL)isCustomizedCookie
                           requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                    progress:(NSProgress * __autoreleasing *)progress
                                    callback:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                        callbackInMainThread:(BOOL)callbackInMainThread {
    dispatch_queue_t callback_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    if (callbackInMainThread) {
        callback_queue = dispatch_get_main_queue();
    }
    return [self requestForBinaryWithURL_:URL
                                   params:params
                                   method:method
                         needCommonParams:needCommonParams
                              headerField:headerField
                          enableHttpCache:enableHttpCache
                        requestSerializer:requestSerializer ?: self.defaultRequestSerializerClass
                       responseSerializer:responseSerializer ?: self.defaultBinaryResponseSerializerClass
                               autoResume:autoResume
                       isCustomizedCookie:isCustomizedCookie
                           headerCallback:nil
                             dataCallback:nil
                                 callback:nil
                     callbackWithResponse:callbackWithResponse
                         redirectCallback:nil
                                 progress:progress
                           dispatch_queue:callback_queue];
}

- (TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                      params:(id)params
                                      method:(NSString *)method
                            needCommonParams:(BOOL)commonParams
                                 headerField:(NSDictionary *)headerField
                             enableHttpCache:(BOOL)enableHttpCache
                           requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                    progress:(NSProgress * __autoreleasing *)progress
                                    callback:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                        callbackInMainThread:(BOOL)callbackInMainThread {
  dispatch_queue_t callback_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  if (callbackInMainThread) {
    callback_queue = dispatch_get_main_queue();
  }
  return [self requestForBinaryWithURL_:URL
                                 params:params
                                 method:method
                       needCommonParams:commonParams
                            headerField:headerField
                        enableHttpCache:enableHttpCache
                      requestSerializer:requestSerializer ?: self.defaultRequestSerializerClass
                     responseSerializer:responseSerializer ?: self.defaultBinaryResponseSerializerClass
                             autoResume:YES
                     isCustomizedCookie:NO
                         headerCallback:nil
                           dataCallback:nil
                               callback:nil
                   callbackWithResponse:callbackWithResponse
                       redirectCallback:nil
                               progress:progress
                         dispatch_queue:callback_queue];
}

- (TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                      params:(id)params
                                      method:(NSString *)method
                            needCommonParams:(BOOL)needCommonParams
                                 headerField:(NSDictionary *)headerField
                             enableHttpCache:(BOOL)enableHttpCache
                                  autoResume:(BOOL)autoResume
                           requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                    progress:(NSProgress * __autoreleasing *)progress
                                    callback:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                        callbackInMainThread:(BOOL)callbackInMainThread {
  dispatch_queue_t callback_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  if (callbackInMainThread) {
    callback_queue = dispatch_get_main_queue();
  }
  return [self requestForBinaryWithURL_:URL
                                 params:params
                                 method:method
                       needCommonParams:needCommonParams
                            headerField:headerField
                        enableHttpCache:enableHttpCache
                      requestSerializer:requestSerializer ?: self.defaultRequestSerializerClass
                     responseSerializer:responseSerializer ?: self.defaultBinaryResponseSerializerClass
                             autoResume:autoResume
                     isCustomizedCookie:NO
                         headerCallback:nil
                           dataCallback:nil
                               callback:nil
                   callbackWithResponse:callbackWithResponse
                       redirectCallback:nil
                               progress:progress
                         dispatch_queue:callback_queue];
}

- (TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                      params:(id)params
                                      method:(NSString *)method
                            needCommonParams:(BOOL)needCommonParams
                                 headerField:(NSDictionary *)headerField
                             enableHttpCache:(BOOL)enableHttpCache
                                  autoResume:(BOOL)autoResume
                           requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                    progress:(NSProgress * __autoreleasing *)progress
                                    callback:(TTNetworkObjectFinishBlockWithResponse)callback
                               callbackQueue:(dispatch_queue_t)callbackQueue
{
    return [self requestForBinaryWithURL_:URL
                                   params:params
                                   method:method
                         needCommonParams:needCommonParams
                              headerField:headerField
                          enableHttpCache:enableHttpCache
                        requestSerializer:requestSerializer
                       responseSerializer:responseSerializer
                               autoResume:autoResume
                       isCustomizedCookie:NO
                           headerCallback:nil
                             dataCallback:nil
                                 callback:nil
                     callbackWithResponse:callback
                         redirectCallback:nil
                                 progress:progress
                           dispatch_queue:callbackQueue];
}

- (TTHttpTask *)requestForBinaryWithURL:(NSString *)URL
                                 params:(id)params
                                 method:(NSString *)method
                       needCommonParams:(BOOL)commonParams
                      requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                     responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                             autoResume:(BOOL)autoResume
                               callback:(TTNetworkObjectFinishBlock)callback
{
    return [self requestForBinaryWithURL_:URL
                                   params:params
                                   method:method
                         needCommonParams:commonParams
                              headerField:nil
                          enableHttpCache:NO
                        requestSerializer:requestSerializer
                       responseSerializer:responseSerializer
                               autoResume:autoResume
                       isCustomizedCookie:NO
                           headerCallback:nil
                             dataCallback:nil
                                 callback:callback
                     callbackWithResponse:nil
                         redirectCallback:nil
                                 progress:nil
                           dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                      params:(id)params
                                      method:(NSString *)method
                            needCommonParams:(BOOL)commonParams
                           requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                  autoResume:(BOOL)autoResume
                                    callback:(TTNetworkObjectFinishBlockWithResponse)callback
{
    return [self requestForBinaryWithURL_:URL
                                   params:params
                                   method:method
                         needCommonParams:commonParams
                              headerField:nil
                          enableHttpCache:NO
                        requestSerializer:requestSerializer
                       responseSerializer:responseSerializer
                               autoResume:autoResume
                       isCustomizedCookie:NO
                           headerCallback:nil
                             dataCallback:nil
                                 callback:nil
                     callbackWithResponse:callback
                         redirectCallback:nil
                                 progress:nil
                           dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestForChunkedBinaryWithURL:(NSString *)URL
                                        params:(id)params
                                        method:(NSString *)method
                              needCommonParams:(BOOL)commonParams
                                   headerField:(NSDictionary *)headerField
                               enableHttpCache:(BOOL)enableHttpCache
                             requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                            responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                    autoResume:(BOOL)autoResume
                                headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                                  dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                                      callback:(TTNetworkObjectFinishBlock)callback
{
    return [self requestForBinaryWithURL_:URL
                                   params:params
                                   method:method
                         needCommonParams:commonParams
                              headerField:headerField
                          enableHttpCache:enableHttpCache
                        requestSerializer:requestSerializer
                       responseSerializer:responseSerializer
                               autoResume:autoResume
                       isCustomizedCookie:NO
                           headerCallback:headerCallback
                             dataCallback:dataCallback
                                 callback:callback
                     callbackWithResponse:nil
                         redirectCallback:nil
                                 progress:nil
                           dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestForChunkedBinaryWithResponse:(NSString *)URL
                                             params:(id)params
                                             method:(NSString *)method
                                   needCommonParams:(BOOL)commonParams
                                        headerField:(NSDictionary *)headerField
                                    enableHttpCache:(BOOL)enableHttpCache
                                  requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                 responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                         autoResume:(BOOL)autoResume
                                 isCustomizedCookie:(BOOL)isCustomizedCookie
                                     headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                                       dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                               callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                                   redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback {
    return [self requestForBinaryWithURL_:URL
                                   params:params
                                   method:method
                         needCommonParams:commonParams
                              headerField:headerField
                          enableHttpCache:enableHttpCache
                        requestSerializer:requestSerializer
                       responseSerializer:responseSerializer
                               autoResume:autoResume
                       isCustomizedCookie:isCustomizedCookie
                           headerCallback:headerCallback
                             dataCallback:dataCallback
                                 callback:nil
                     callbackWithResponse:callbackWithResponse
                         redirectCallback:redirectCallback
                                 progress:nil
                           dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestForChunkedBinaryWithResponse:(NSString *)URL
                                             params:(id)params
                                             method:(NSString *)method
                                   needCommonParams:(BOOL)commonParams
                                        headerField:(NSDictionary *)headerField
                                    enableHttpCache:(BOOL)enableHttpCache
                                  requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                 responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                         autoResume:(BOOL)autoResume
                                     headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                                       dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                               callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
{
    return [self requestForBinaryWithURL_:URL
                                   params:params
                                   method:method
                         needCommonParams:commonParams
                              headerField:headerField
                          enableHttpCache:enableHttpCache
                        requestSerializer:requestSerializer
                       responseSerializer:responseSerializer
                               autoResume:autoResume
                       isCustomizedCookie:NO
                           headerCallback:headerCallback
                             dataCallback:dataCallback
                                 callback:nil
                     callbackWithResponse:callbackWithResponse
                         redirectCallback:nil
                                 progress:nil
                           dispatch_queue:self.callback_dispatch_queue];
}

- (TTHttpTask *)requestForChunkedBinaryWithResponse:(NSString *)URL
                                             params:(id)params
                                             method:(NSString *)method
                                   needCommonParams:(BOOL)commonParams
                                        headerField:(NSDictionary *)headerField
                                    enableHttpCache:(BOOL)enableHttpCache
                                  requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                 responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                         autoResume:(BOOL)autoResume
                                     headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                                       dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                               callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback {
  return [self requestForBinaryWithURL_:URL
                                 params:params
                                 method:method
                       needCommonParams:commonParams
                            headerField:headerField
                        enableHttpCache:enableHttpCache
                      requestSerializer:requestSerializer
                     responseSerializer:responseSerializer
                             autoResume:autoResume
                     isCustomizedCookie:NO
                         headerCallback:headerCallback
                           dataCallback:dataCallback
                               callback:nil
                   callbackWithResponse:callbackWithResponse
                       redirectCallback:redirectCallback
                               progress:nil
                         dispatch_queue:self.callback_dispatch_queue];
}

+(NSData*)dataWithInputStream:(NSInputStream*)stream {

  NSMutableData *data = [NSMutableData data];
  [stream open];
  NSInteger result;
  uint8_t buffer[1024];

  while ((result = [stream read:buffer maxLength:1024]) != 0) {
    if (result > 0) {
      // buffer contains result bytes of data to be handled
      [data appendBytes:buffer length:result];
    } else if (result < 0) {
      // The stream had an error. You can get an NSError object using [iStream streamError]
      LOGE(@"#### read the body stream failed: %@", stream.streamError);
      data = nil;
      break;
    }
  }
  [stream close];
  return data;
}

- (TTHttpTask *)requestForWebview:(NSURLRequest *)request
     enableHttpCache:(BOOL)enableHttpCache
      headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
        dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
             callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse {
    return [self requestForWebview:request autoResume:YES enableHttpCache:enableHttpCache headerCallback:headerCallback dataCallback:dataCallback callbackWithResponse:callbackWithResponse];
}

- (TTHttpTask *)requestForWebview:(NSURLRequest *)request
          autoResume:(BOOL)autoResume
     enableHttpCache:(BOOL)enableHttpCache
      headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
        dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
             callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse {
    return [self requestForWebview:request autoResume:autoResume enableHttpCache:enableHttpCache headerCallback:headerCallback dataCallback:dataCallback callbackWithResponse:callbackWithResponse redirectCallback:nil];
}

- (TTHttpTask *)requestForWebview:(NSURLRequest *)request
          autoResume:(BOOL)autoResume
     enableHttpCache:(BOOL)enableHttpCache
      headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
        dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
             callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback {
    return [self requestForWebviewCommon:request mainDocURL:nil autoResume:autoResume enableHttpCache:enableHttpCache headerCallback:headerCallback dataCallback:dataCallback callbackWithResponse:callbackWithResponse redirectCallback:redirectCallback];
}

- (TTHttpTask *)requestForWebview:(NSURLRequest *)request
                       mainDocURL:(NSString *)mainDocURL
                       autoResume:(BOOL)autoResume
                  enableHttpCache:(BOOL)enableHttpCache
                   headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                     dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
             callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                 redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback {
    return [self requestForWebviewCommon:request mainDocURL:mainDocURL autoResume:autoResume enableHttpCache:enableHttpCache headerCallback:headerCallback dataCallback:dataCallback callbackWithResponse:callbackWithResponse redirectCallback:redirectCallback];
}

- (TTHttpTask *)requestForWebviewCommon:(NSURLRequest *)nsRequest
                             mainDocURL:(NSString *)mainDocURL
                             autoResume:(BOOL)autoResume
                        enableHttpCache:(BOOL)enableHttpCache
                         headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                           dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                   callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                       redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback {
    TTConcurrentHttpTask *concurrentTask = [TTConcurrentHttpTask buildWebviewConcurrentTask:nsRequest
                                                                                 mainDocURL:mainDocURL
                                                                                 autoResume:autoResume
                                                                            enableHttpCache:enableHttpCache
                                                                           redirectCallback:redirectCallback
                                                                             headerCallback:headerCallback
                                                                               dataCallback:dataCallback
                                                                       callbackWithResponse:callbackWithResponse
                                                                    concurrentRequestConfig:self.concurrentRequestConfig];
    
    if (concurrentTask) {
        return concurrentTask;
    }
    
    return [self buildWebviewHttpTask:nsRequest
                           mainDocURL:mainDocURL
                           autoResume:autoResume
                      enableHttpCache:enableHttpCache
                       headerCallback:headerCallback
                         dataCallback:dataCallback
                 callbackWithResponse:callbackWithResponse
                     redirectCallback:redirectCallback];
}

- (TTHttpTaskChromium *)buildWebviewHttpTask:(NSURLRequest *)nsRequest
                                  mainDocURL:(NSString *)mainDocURL
                                  autoResume:(BOOL)autoResume
                             enableHttpCache:(BOOL)enableHttpCache
                              headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                                dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                        callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                            redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback {
    NSDate *startBizTime = [NSDate date];
    TTHttpRequestChromium *request = [self generateTTHttpRequest:nsRequest needCommonParams:nsRequest.needCommonParams];
    request.startBizTime = startBizTime;
    if (!request || [self apiHttpInterceptor:request]) {
        NSDictionary *userInfo = nil;
        NSString *reason = nil;
        NSInteger specificErrorCode = 0;
        if (!request) {
            LOGE(@"Can not construct TTHttpRequest!");
            reason = @"Cannot construct TTHttpRequest";
            specificErrorCode = TTNetworkErrorCodeBadURLRequest;
        } else {
            reason = @"request has been intercepted by  the api http interceptor";
            specificErrorCode = TTNetworkErrorCodeApiHttpIntercepted;
        }
        if (request.urlString) {
            userInfo = @{kTTNetSubErrorCode : @(specificErrorCode), NSLocalizedDescriptionKey : reason, NSURLErrorFailingURLErrorKey : request.urlString};
        }
        NSError *resultError =  [NSError errorWithDomain:kTTNetworkErrorDomain code:specificErrorCode userInfo:userInfo];
        if (callbackWithResponse) {
            callbackWithResponse(resultError, nil, nil);
        }
        
        return nil;
    }
    
    id<TTResponsePreProcessorProtocol> preprocessor = nil;
    if (self.defaultResponseRreprocessorClass) {
        preprocessor = [self.defaultResponseRreprocessorClass processor];
    }

    UInt64 taskId = [self nextTaskId];
    __weak typeof(self) wself = self;

    //for improper image checking by AI
    BOOL enableAIImageCheck = self.isWebviewImageCheck;
    NSArray<NSString *> *imageCheckDomainList = self.imageCheckDomainList;
    NSArray<NSString *> *imageCheckBypassDomainList = self.imageCheckBypassDomainList;
    BOOL isDomainMatch = [self.class isCheckingDomain:nsRequest.URL.host
                                      checkDomainList:imageCheckDomainList
                                     bypassDoaminList:imageCheckBypassDomainList];
    __block BOOL hasRecognized = NO;
    __block BOOL isImage = NO;
    __block NSInteger contentLength = 0;
    __block NSMutableData *imageDataBuffer = [NSMutableData data];
    __block BOOL isMallocError = NO;         //appendData and copy will fail in mallocing memory occasional online
    __block NSInteger callbackPoint = 0;      //callback to Client AI when first reached imageCheckPoint, only once
    __block NSInteger callbackDelta = 0;      //callback to Client AI every callbackDelta bytes
    __block NSInteger callbackBase  = 0;      //the length in last callback time
    __block AIImageCheckDidFinishBlock imageCheckFinishBlock = nil;
    __block BOOL hasReachedCheckPoint = NO;  //mark whether imageCheckPoint has been reached
    ///__block int imageCheckResult = TTNetworkErrorCodeEImproperImage;//check result, 1 means improper, 0 means proper, -1 means error occurs while checking
    NSString *requestID = [[NSUUID UUID] UUIDString];
    __block dispatch_queue_t imageCheckSerialQueue = nil;
    
    

    OnHttpTaskHeaderReadCompletedCallbackBlock chunkedHeaderReadCompletedCallbackBlock = nil;
    if (headerCallback) {
        // If headerCallback is set, response will be returned to app level as soon as it is read from the request.
        chunkedHeaderReadCompletedCallbackBlock = ^(TTHttpResponse* response) {
	        //image request will be checked by Client AI if enable
            if (enableAIImageCheck && isDomainMatch) {
                NSString *contentType = [[response allHeaderFields] objectForKey:@"Content-Type"];
                if (!contentType) {
                    hasRecognized = NO;
                } else {
                    if (![contentType hasPrefix:@"application/octet-stream"]) {
                        //binary stream may be image data, it will be recognized in dataBlock
                        hasRecognized = YES;
                    }
          
                    if ([contentType hasPrefix:@"image/"]) {
                        isImage = YES;
              
                        [self.class setImageCheckFinishBlockAndQueue:&imageCheckFinishBlock sendDataSerialQueue:&imageCheckSerialQueue];
                    }
                }
          
                NSString *contentLengthString = [[response allHeaderFields] objectForKey:@"Content-Length"];
                if (contentLengthString) {
                    contentLength = [contentLengthString integerValue] > 0 ? [contentLengthString integerValue] : 0;
                    [self setCallbackPointAndStep:contentLength callbackPoint:&callbackPoint callbackDelta:&callbackDelta];
                } else {
                    LOGD(@"uuid:%@, url:%@, has NO Content-Length", requestID, request.urlString);
                }
            }
            // callback to upper layer
            dispatch_async(wself.serial_callback_dispatch_queue, ^(void) {
                headerCallback(response);
            });
        };
    }

    OnHttpTaskDataReadCompletedCallbackBlock chunkedDataReadCompletedCallbackBlock = nil;
    if (dataCallback) {
        // If dataCallback is set, response data will be returned to app level as soon as it is read from the request.
        // There is no difference with the once-fetch way for errors and response deserialization except that the data
        // field will always be nil in the final completion callback no matter if the request suceeds.
        chunkedDataReadCompletedCallbackBlock = ^(id data) {
            NSAssert(data == nil || [data isKindOfClass:NSData.class], @"Must be NSData!");
            NSUInteger len = [(NSData *)data length];
            if (enableAIImageCheck && isDomainMatch) {
                BOOL isRecognizedInDataBlock = NO;
        
                if (!hasRecognized) {
                    [imageDataBuffer appendData:data];
          
                    //at least 16 bytes to be recognized
                    if (imageDataBuffer.length >= 16) {
                        NSData *recognize16Bytes = [imageDataBuffer subdataWithRange:NSMakeRange(0, 16)];
                        //only take the first 16 bytes to recognize the type
                        ImageType type = [TTNetworkUtil imageTypeDetect:(__bridge CFDataRef)recognize16Bytes];
                        hasRecognized = YES;
                        if (type != ImageTypeUnknown) {
                            isImage = YES;  //image recognized by first 16 bytes
                            isRecognizedInDataBlock = YES;
                            [self.class setImageCheckFinishBlockAndQueue:&imageCheckFinishBlock sendDataSerialQueue:&imageCheckSerialQueue];
                        } else {
                            LOGI(@"unknow image, uuid:%@, url:%@", requestID, request.urlString);
                        }
                    }
                }
                
                if (hasRecognized && isImage && self.addAIImageCheckBlock) {
                    NSUInteger recvedLength = [imageDataBuffer length];
                    if (!isRecognizedInDataBlock) {
                        @try {
                            [imageDataBuffer appendData:data];
                        } @catch (NSException *exception) {
                            LOGE(@"exception occurs at appendData, reason:%@", exception.reason);
                            isMallocError = YES;
                            [self callbackToClientAIForImageCheck:requestID
                                                          request:request
                                                       mainDocURL:mainDocURL
                                                        recvLenth:recvedLength
                                                    contentLength:contentLength
                                                        imageData:imageDataBuffer
                                            imageCheckSerialQueue:imageCheckSerialQueue
                                            imageCheckFinishBlock:imageCheckFinishBlock
                                                      mallocError:isMallocError];
                        }
                    }
        
                    if (!isMallocError) {
                        recvedLength = [imageDataBuffer length];
                        if (contentLength > 0) {
                            // call Client AI for image check when reached imageCheckPoint, only once
                            if (callbackPoint <= recvedLength && recvedLength < contentLength && !hasReachedCheckPoint) {
                                LOGD(@"%@", [NSString stringWithFormat:@"uuid:%@, url:%@, %f%% more than %f%%, call Client AI to check", requestID, request.urlString, ((float)recvedLength/contentLength) * 100, self.imageCheckPoint * 100]);
                
                                [self callbackToClientAIWithExceptionCaught:requestID
                                                                    request:request
                                                                 mainDocURL:mainDocURL
                                                                  recvLenth:recvedLength
                                                              contentLength:contentLength
                                                                  imageData:imageDataBuffer
                                                      imageCheckSerialQueue:imageCheckSerialQueue
                                                      imageCheckFinishBlock:imageCheckFinishBlock
                                                                mallocError:&isMallocError];
            
                                callbackBase = recvedLength;  //mark the first time callback length
                                hasReachedCheckPoint = YES;
                            }
            
                            // call Client AI for image check every increasingStep after reached imageCheckPoint
                            if (callbackBase > 0 && recvedLength - callbackBase >= callbackDelta && recvedLength < contentLength) {
                                LOGD(@"%@", [NSString stringWithFormat:@"uuid:%@, url:%@, %f%% increasing more than %f%%, call Client AI to check", requestID, request.urlString, ((float)recvedLength/contentLength) * 100, self.increasingStep * 100]);
                
                                [self callbackToClientAIWithExceptionCaught:requestID
                                                                    request:request
                                                                 mainDocURL:mainDocURL
                                                                  recvLenth:recvedLength
                                                              contentLength:contentLength
                                                                  imageData:imageDataBuffer
                                                      imageCheckSerialQueue:imageCheckSerialQueue
                                                      imageCheckFinishBlock:imageCheckFinishBlock
                                                                mallocError:&isMallocError];
                  
                                callbackBase = recvedLength;  //reset callbackBase
                            }
              
                            // call Client AI for image check when last byte received
                            if (recvedLength == contentLength && len > 0) {
                                LOGD(@"%@", [NSString stringWithFormat:@"uuid:%@, url:%@, 100%% finished, call Client AI to check", requestID, request.urlString]);
                                [self callbackToClientAIForImageCheck:requestID
                                                              request:request
                                                           mainDocURL:mainDocURL
                                                            recvLenth:recvedLength
                                                        contentLength:contentLength
                                                            imageData:imageDataBuffer
                                                imageCheckSerialQueue:imageCheckSerialQueue
                                                imageCheckFinishBlock:imageCheckFinishBlock
                                                          mallocError:NO];
                            }
                        } else {
                            //No Content-Length header, only call Client AI for image check when last byte received
                            if (len == 0) {
                                [self callbackToClientAIForImageCheck:requestID
                                                              request:request
                                                           mainDocURL:mainDocURL
                                                            recvLenth:recvedLength
                                                        contentLength:recvedLength
                                                            imageData:imageDataBuffer
                                                imageCheckSerialQueue:imageCheckSerialQueue
                                                imageCheckFinishBlock:imageCheckFinishBlock
                                                          mallocError:NO];
                            }
                        }
                    }
                }
            }
            
            if (len > 0) {
                // callback to upper layer
                dispatch_async(wself.serial_callback_dispatch_queue, ^(void) {
                    dataCallback(data);
                });
            }
        };
    }

    BOOL mustCallbackInSerail = dataCallback != nil || headerCallback != nil;

    OnHttpTaskCompletedCallbackBlock deserializingAndCallbackBlock = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {
        NSAssert(data == nil || [data isKindOfClass:NSData.class], @"Must be NSData!");
        NSAssert((!(data == nil && responseError == nil) || dataCallback != nil), @"bad state");

        if (wself.responseFilterBlock) {
            wself.responseFilterBlock(request, response, data, responseError);
        }
      
        [[TTReqFilterManager shareInstance] runResponseFilter:request response:response data:data responseError:&responseError];

        //run response filter block to change the raw data if the request meets requirement of DMT
        [[TTReqFilterManager shareInstance] runResponseMutableDataFilter:request response:response data:&data responseError:&responseError];
      
        // deserializing
        NSError *resultError = nil;
        NSDate *startSerializerTime = [NSDate date];
        id responseObj = [[self.defaultBinaryResponseSerializerClass serializer] responseObjectForResponse:response
                                                                                                      data:data
                                                                                             responseError:responseError
                                                                                               resultError:&resultError];
        NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
        [response.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(self.defaultBinaryResponseSerializerClass.class)];
    
        // callback to upper layer
        TICK;
        dispatch_queue_t dispatch_queue = self.callback_dispatch_queue;
        if (mustCallbackInSerail) {
            dispatch_queue = wself.serial_callback_dispatch_queue;
        }
        dispatch_async(dispatch_queue, ^(void) {
            TOCK;
            if (callbackWithResponse) {
                callbackWithResponse(resultError, responseObj, response);
            }
        
            // monitor request end
            [[TTNetworkManagerMonitorNotifier defaultNotifier] notifyForMonitorFinishResponse:response
                                                                                   forRequest:request
                                                                                        error:responseError
                                                                                     response:data];
        });
    };

    OnHttpTaskCompletedCallbackBlock oneHttpRequestCompletedCallbackBlock = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {
        [wself removeTaskWithId_:taskId];

        // do preprocessing
        if (preprocessor) {
            BOOL needRetry = [wself handleResponsePreProcessing_:response data:data error:responseError request:request preprocessor:preprocessor headerCallback:chunkedHeaderReadCompletedCallbackBlock dataCallback:chunkedDataReadCompletedCallbackBlock completedCallback:deserializingAndCallbackBlock];
            if (needRetry) {
                LOGD(@"%s preprocessor needs retry the request: %@", __FUNCTION__, request.URL);
                return;
            }
        }
    
        deserializingAndCallbackBlock(response, data, responseError);
    };

    OnHttpTaskURLRedirectedCallbackBlock redirectedBlock = nil;
    if (redirectCallback) {
        redirectedBlock = ^(NSString *new_location, TTHttpResponse *old_repsonse) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                redirectCallback(new_location, old_repsonse);
            });
        };
    }

    TTHttpTaskChromium *task = [[TTHttpTaskChromium alloc] initWithRequest:(TTHttpRequestChromium *)request
                                                                    engine:gChromeNet.Get().get()
                                                             dispatchQueue:self.dispatch_queue
                                                                    taskId:taskId
                                                           enableHttpCache:enableHttpCache
                                                         completedCallback:oneHttpRequestCompletedCallbackBlock
                                                    uploadProgressCallback:nil
                                                  downloadProgressCallback:nil];
    task.headerBlock = chunkedHeaderReadCompletedCallbackBlock;
    task.dataBlock = chunkedDataReadCompletedCallbackBlock;
    task.redirectedBlock = redirectedBlock;
    task.isWebviewRequest = YES;

    [self addTaskWithId_:taskId task:task];

    if (autoResume) {
        [task resume];
    }

    return task;
}

- (void)callbackToClientAIWithExceptionCaught:(NSString *)requestID
                                      request:(TTHttpRequestChromium *)request
                                   mainDocURL:(NSString *)mainDocURL
                                    recvLenth:(NSInteger)recvLength
                                contentLength:(NSInteger)contentLength
                                    imageData:(NSData *)imageDataBuffer
                        imageCheckSerialQueue:(dispatch_queue_t)imageCheckSerialQueue
                        imageCheckFinishBlock:(AIImageCheckDidFinishBlock)imageCheckFinishBlock
                                  mallocError:(BOOL *)isMallocError {
    NSData *copyData = nil;
    @try {
        //copy will accidently crash online, meaasge like "NSAllocateMemoryPages(1052354) failed"
        copyData = [imageDataBuffer copy];
    } @catch (NSException *exception) {
        LOGE(@"exception occurs at copying imageData, requestID:%@, reason:%@, userinfo:%@", requestID, exception.reason, exception.userInfo);
        *isMallocError = YES;
    } @finally {
        [self callbackToClientAIForImageCheck:requestID
                                      request:request
                                   mainDocURL:mainDocURL
                                    recvLenth:recvLength
                                contentLength:contentLength
                                    imageData:copyData
                        imageCheckSerialQueue:imageCheckSerialQueue
                        imageCheckFinishBlock:imageCheckFinishBlock
                                  mallocError:*isMallocError];
    }
}

- (void)callbackToClientAIForImageCheck:(NSString *)requestID
                                request:(TTHttpRequestChromium *)request
                             mainDocURL:(NSString *)mainDocURL
                              recvLenth:(NSInteger)recvLength
                          contentLength:(NSInteger)contentLength
                              imageData:(NSData *)imageDataBuffer
                  imageCheckSerialQueue:(dispatch_queue_t)imageCheckSerialQueue
                  imageCheckFinishBlock:(AIImageCheckDidFinishBlock)imageCheckFinishBlock
                            mallocError:(BOOL)mallocError {
    NSAssert(self.addAIImageCheckBlock != nil, @"addAIImageCheckBlock not set");
    NSString *completedFraction = [NSString stringWithFormat:@"%f", (float)recvLength/contentLength];
    NSDictionary *extraInfo = [NSDictionary dictionaryWithObjectsAndKeys:request.urlString, @"url", completedFraction, @"progress", @(mallocError), @"ttnet_malloc_error",
                              mainDocURL, @"main_doc_url", nil];
    if (!imageCheckSerialQueue) {
        imageCheckSerialQueue = dispatch_queue_create("ttnet_image_check_queue", DISPATCH_QUEUE_SERIAL);
    }
    dispatch_async(imageCheckSerialQueue, ^{
        NSDate *startTime = [NSDate date];
        self.addAIImageCheckBlock(requestID, imageDataBuffer, extraInfo, imageCheckFinishBlock);
        LOGD(@"%@", [NSString stringWithFormat:@"Client AI image block check took %f seconds", -[startTime timeIntervalSinceNow]]);
    });
}

- (void)setCallbackPointAndStep:(NSInteger)contentLength callbackPoint:(NSInteger *)callbackPoint callbackDelta:(NSInteger *)callbackDelta {
    if (self.imageCheckPoint > 0 && self.imageCheckPoint <= 1) {
        *callbackPoint = contentLength * self.imageCheckPoint;
    } else {
        //if imageCheckPoint is not in (0, 1], set it to default value, that is 70%
        *callbackPoint = contentLength * 0.7;
    }
      
    if (self.increasingStep > 0 && self.increasingStep < 1) {
        *callbackDelta = contentLength * self.increasingStep;
    } else {
        //if increasingStep is not in (0, 1), set it to default value, that is 15%
        *callbackDelta = contentLength * 0.15;
    }
}

+ (void)setImageCheckFinishBlockAndQueue:(AIImageCheckDidFinishBlock*)finishBlock sendDataSerialQueue:(dispatch_queue_t *)queue {
    if (!*finishBlock) {
        *finishBlock = ^(NSString *uuid, int result, NSDictionary *extraInfo) {
          ///imageCheckResult = result;
          //LOGI(@"++++uuid:%@, url:%@, result:%d, progress:%@,", uuid, [extraInfo objectForKey:@"url"], result, [extraInfo objectForKey:@"progress"]);
        };
    }
    
    if (!*queue) {
        //TTNet send image data to Client AI in this serial queue
        *queue = dispatch_queue_create("ttnet_image_check_queue", DISPATCH_QUEUE_SERIAL);
    }
}

+ (BOOL)isCheckingDomain:(NSString *)requestDomain
         checkDomainList:(NSArray<NSString *> *)imageCheckDomainList
        bypassDoaminList:(NSArray<NSString *> *)imageCheckBypassDomainList {
    if (imageCheckDomainList && [TTNetworkUtil.class isMatching:requestDomain pattern:kPathEqualMatch source:imageCheckDomainList]) {
        return YES;
    } else {
        return ![TTNetworkUtil.class isMatching:requestDomain pattern:kCommonMatch source:imageCheckBypassDomainList];
    }
}

- (TTHttpTask *)requestForBinaryWithURL_:(NSString *)URL
                                  params:(id)params
                                  method:(NSString *)method
                        needCommonParams:(BOOL)needCommonParams
                             headerField:(NSDictionary *)headerField
                         enableHttpCache:(BOOL)enableHttpCache
                       requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                      responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                              autoResume:(BOOL)autoResume
                      isCustomizedCookie:(BOOL)isCustomizedCookie
                          headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                            dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                                callback:(TTNetworkObjectFinishBlock)callback
                    callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                        redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback
                                progress:(NSProgress * __autoreleasing *)progress
                          dispatch_queue:(dispatch_queue_t)callback_queue {
    TTConcurrentHttpTask *concurrentTask = [TTConcurrentHttpTask buildBinaryConcurrentTask:URL
                                                                    params:params
                                                                    method:method
                                                          needCommonParams:needCommonParams
                                                               headerField:headerField
                                                           enableHttpCache:enableHttpCache
                                                         requestSerializer:requestSerializer
                                                        responseSerializer:responseSerializer
                                                                autoResume:autoResume
                                                        isCustomizedCookie:isCustomizedCookie
                                                            headerCallback:headerCallback
                                                              dataCallback:dataCallback
                                                                  callback:callback
                                                      callbackWithResponse:callbackWithResponse
                                                          redirectCallback:redirectCallback
                                                                  progress:progress
                                                            dispatch_queue:callback_queue
                                           redirectHeaderDataCallbackQueue:self.serial_callback_dispatch_queue
                                                   concurrentRequestConfig:self.concurrentRequestConfig];
    
    if (concurrentTask) {
        return concurrentTask;
    }
    
    return [self buildBinaryHttpTask:URL
                              params:params
                              method:method
                    needCommonParams:needCommonParams
                         headerField:headerField
                     enableHttpCache:enableHttpCache
                   requestSerializer:requestSerializer
                  responseSerializer:responseSerializer
                          autoResume:autoResume
                  isCustomizedCookie:isCustomizedCookie
                      headerCallback:headerCallback
                        dataCallback:dataCallback
                            callback:callback
                callbackWithResponse:callbackWithResponse
                    redirectCallback:redirectCallback
                            progress:progress
                      dispatch_queue:callback_queue];
}

- (TTHttpTaskChromium *)buildBinaryHttpTask:(NSString *)URL
                                     params:(id)params
                                     method:(NSString *)method
                           needCommonParams:(BOOL)needCommonParams
                                headerField:(NSDictionary *)headerField
                            enableHttpCache:(BOOL)enableHttpCache
                          requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                         responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                 autoResume:(BOOL)autoResume
                         isCustomizedCookie:(BOOL)isCustomizedCookie
                             headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                               dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                                   callback:(TTNetworkObjectFinishBlock)callback
                       callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                           redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback
                                   progress:(NSProgress * __autoreleasing *)progress
                             dispatch_queue:(dispatch_queue_t)callback_queue {
    NSDate *startBizTime = [NSDate date];
    if (!requestSerializer) {
        requestSerializer = self.defaultRequestSerializerClass;
    }
    if (!responseSerializer) {
        responseSerializer = self.defaultBinaryResponseSerializerClass;
    }
    
    NSURL *nsurl = [TTNetworkUtil.class isValidURL:URL callback:callback callbackWithResponse:callbackWithResponse];
    if (!nsurl) {
        return nil;
    }
    NSDictionary *commonParams = [self needCommonParams:needCommonParams requestURL:nsurl];
    
    //NSObject<TTBinaryResponseSerializerProtocol> *binaryRespSerializer = [requestSerializer serializer];
    TTHttpRequest *request = nil;
    NSDate *startSerializerTime = [NSDate date];
    if (headerField) {
        request = [[requestSerializer serializer] URLRequestWithURL:URL
                                                        headerField:headerField
                                                             params:params
                                                             method:method
                                              constructingBodyBlock:nil
                                                       commonParams:commonParams];
    } else {
        request = [[requestSerializer serializer] URLRequestWithURL:URL
                                                             params:params
                                                             method:method
                                              constructingBodyBlock:nil
                                                       commonParams:commonParams];
    }
    if (request) {
        NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
        [request.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(requestSerializer.class)];
        
        request.startBizTime = startBizTime;
    }
    
    if (!request || [self apiHttpInterceptor:request]) {
//        NSAssert(false, @"no request created!");
        NSDictionary *userInfo = nil;
        NSString *reason = nil;
        NSInteger specificErrorCode = 0;
        if (!request) {
            LOGE(@"Can not construct TTHttpRequest!");
            reason = @"Cannot construct TTHttpRequest";
            specificErrorCode = TTNetworkErrorCodeBadURLRequest;
        } else {
            reason = @"request has been intercepted by  the api http interceptor";
            specificErrorCode = TTNetworkErrorCodeApiHttpIntercepted;
        }
        if (URL) {
            userInfo = @{kTTNetSubErrorCode : @(specificErrorCode), NSLocalizedDescriptionKey : reason, NSURLErrorFailingURLErrorKey : URL};
        }
        NSError *resultError =  [NSError errorWithDomain:kTTNetworkErrorDomain code:specificErrorCode userInfo:userInfo];
        if (callback) {
            callback(resultError, nil);
        }
        if (callbackWithResponse) {
            callbackWithResponse(resultError, nil, nil);
        }
        return nil;
    }

    if ([commonParams count] > 0) {
      try {
        [TTHTTPRequestSerializerBase hashRequest:request body:request.HTTPBody];
      } catch (...) {

      }
    }
    
    id<TTResponsePreProcessorProtocol> preprocessor = nil;
    if (self.defaultResponseRreprocessorClass) {
        preprocessor = [self.defaultResponseRreprocessorClass processor];
    }
    
    UInt64 taskId = [self nextTaskId];
    __weak typeof(self) wself = self;
    
    OnHttpTaskURLRedirectedCallbackBlock redirectedBlock = nil;
    if (redirectCallback) {
      redirectedBlock = ^(NSString *new_location, TTHttpResponse *old_repsonse) {
        dispatch_async(wself.serial_callback_dispatch_queue, ^(void) {
          redirectCallback(new_location, old_repsonse);
        });
      };
    }
    
    OnHttpTaskHeaderReadCompletedCallbackBlock chunkedHeaderReadCompletedCallbackBlock = nil;
    if (headerCallback) {
        // If headerCallback is set, response will be returned to app level as soon as it is read from the request.
        chunkedHeaderReadCompletedCallbackBlock = ^(TTHttpResponse* response) {
            // callback to upper layer
            dispatch_async(wself.serial_callback_dispatch_queue, ^(void) {
                    headerCallback(response);
            });
        };
    }
    
    OnHttpTaskDataReadCompletedCallbackBlock chunkedDataReadCompletedCallbackBlock = nil;
    if (dataCallback) {
        // If dataCallback is set, response data will be returned to app level as soon as it is read from the request.
        // There is no difference with the once-fetch way for errors and response deserialization except that the data
        // field will always be nil in the final completion callback no matter if the request suceeds.
        chunkedDataReadCompletedCallbackBlock = ^(id data) {
            NSAssert(data == nil || [data isKindOfClass:NSData.class], @"Must be NSData!");
            
            NSUInteger len = [(NSData *)data length];
            if (len > 0) {
                // callback to upper layer
                dispatch_async(wself.serial_callback_dispatch_queue, ^(void) {
                    dataCallback(data);
                });
            }
        };
    }

    BOOL mustCallbackInSerail = dataCallback != nil || headerCallback != nil;
    
    OnHttpTaskCompletedCallbackBlock deserializingAndCallbackBlock = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {
        NSAssert(data == nil || [data isKindOfClass:NSData.class], @"Must be NSData!");
        NSAssert((!(data == nil && responseError == nil) || dataCallback != nil), @"bad state");

        if (wself.responseFilterBlock) {
          wself.responseFilterBlock(request, response, data, responseError);
        }
        
        [[TTReqFilterManager shareInstance] runResponseFilter:request response:response data:data responseError:&responseError];

        //run response filter block to change the raw data if the request meets requirement of DMT
        [[TTReqFilterManager shareInstance] runResponseMutableDataFilter:request response:response data:&data responseError:&responseError];
        
        // deserializing
        NSError *resultError = nil;
        NSDate *startSerializerTime = [NSDate date];
        id responseObj = [[responseSerializer serializer] responseObjectForResponse:response
                                                                               data:data
                                                                      responseError:responseError
                                                                        resultError:&resultError];
        NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
        [response.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(responseSerializer.class)];
        
        // callback to upper layer
        TICK;
        dispatch_queue_t dispatch_queue = callback_queue;
        if (mustCallbackInSerail) {
          dispatch_queue = wself.serial_callback_dispatch_queue;
        }
        dispatch_async(dispatch_queue, ^(void) {
          TOCK;
            if (callback) {
                callback(resultError, responseObj);
            }
            
            if (callbackWithResponse) {
                callbackWithResponse(resultError, responseObj, response);
            }
            
            // monitor request end
            [[TTNetworkManagerMonitorNotifier defaultNotifier] notifyForMonitorFinishResponse:response
                                                                                   forRequest:request
                                                                                        error:responseError
                                                                                     response:data];
        });
    };
    
    OnHttpTaskCompletedCallbackBlock oneHttpRequestCompletedCallbackBlock = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {
        [wself removeTaskWithId_:taskId];
        //handle verification code related callback
        //only retry 1 time
        BOOL handleBDTuringResult = [wself handleBDTuringCallback:request
                                                         response:response
                                                 redirectCallback:redirectedBlock
                                                   headerCallback:chunkedHeaderReadCompletedCallbackBlock
                                                     dataCallback:chunkedDataReadCompletedCallbackBlock
                                    deserializingAndCallbackBlock:deserializingAndCallbackBlock];
        
        if (handleBDTuringResult) {
            return;
        }
        
        // do preprocessing
        if (preprocessor) {
            BOOL needRetry = [wself handleResponsePreProcessing_:response data:data error:responseError request:request preprocessor:preprocessor headerCallback:chunkedHeaderReadCompletedCallbackBlock dataCallback:chunkedDataReadCompletedCallbackBlock completedCallback:deserializingAndCallbackBlock];
            if (needRetry) {
                LOGD(@"%s preprocessor needs retry the request: %@", __FUNCTION__, request.URL);
                return;
            }
        }
        
        deserializingAndCallbackBlock(response, data, responseError);
    };
    
    __block NSProgress *downloadProgress = nil;
    if (progress) {
        *progress = [NSProgress progressWithTotalUnitCount:10000];
        downloadProgress = *progress;
    }
    OnHttpTaskProgressCallbackBlock downloadProgressCallback = ^(int64_t current, int64_t total) {
        //LOGD(@" current = %lld, total = %lld", current, total);
        if (downloadProgress) {
            if (downloadProgress.totalUnitCount != total) {
                downloadProgress.totalUnitCount = total;
            }
            
            downloadProgress.completedUnitCount = current;
        }
    };

    TTHttpTaskChromium *task = [[TTHttpTaskChromium alloc] initWithRequest:(TTHttpRequestChromium *)request
                                                                    engine:gChromeNet.Get().get()
                                                             dispatchQueue:self.dispatch_queue
                                                                    taskId:taskId enableHttpCache:enableHttpCache
                                                         completedCallback:oneHttpRequestCompletedCallbackBlock
                                                    uploadProgressCallback:nil
                                                  downloadProgressCallback:downloadProgressCallback];
    task.enableCustomizedCookie = isCustomizedCookie;
    task.headerBlock = chunkedHeaderReadCompletedCallbackBlock;
    task.dataBlock = chunkedDataReadCompletedCallbackBlock;
    task.redirectedBlock = redirectedBlock;
    task.taskType = TTNET_TASK_TYPE_DOWNLOAD;
    
    [self addTaskWithId_:taskId task:task];
    
    if (autoResume) {
        [task resume];
    }
    
    return task;
}


#pragma mark - Upload

- (TTHttpTask *)uploadWithURL:(NSString *)URLString
                   parameters:(id)parameters
    constructingBodyWithBlock:(TTConstructingBodyBlock)bodyBlock
                     progress:(NSProgress * __autoreleasing *)progress
             needcommonParams:(BOOL)needCommonParams
                     callback:(TTNetworkJSONFinishBlock)callback
{
    return [self uploadWithURL:URLString
                   headerField:nil
                    parameters:parameters
     constructingBodyWithBlock:bodyBlock
                      progress:progress
              needcommonParams:needCommonParams
                      callback:callback];
}

- (TTHttpTask *)uploadWithURL:(NSString *)URLString
                  headerField:(NSDictionary *)headerField
                   parameters:(id)parameters
    constructingBodyWithBlock:(TTConstructingBodyBlock)bodyBlock
                     progress:(NSProgress * __autoreleasing *)progress
             needcommonParams:(BOOL)needCommonParams
                     callback:(TTNetworkJSONFinishBlock)callback
{
    
    return [self uploadWithURL:URLString
                    parameters:parameters
                   headerField:headerField
     constructingBodyWithBlock:bodyBlock
                      progress:progress
              needcommonParams:needCommonParams
             requestSerializer:self.defaultRequestSerializerClass
            responseSerializer:self.defaultJSONResponseSerializerClass
                    autoResume:YES
                      callback:callback];
    
}

- (TTHttpTask *)uploadWithURL:(NSString *)URLString
                   parameters:(id)parameters
                  headerField:(NSDictionary *)headerField
    constructingBodyWithBlock:(TTConstructingBodyBlock)bodyBlock
                     progress:(NSProgress * __autoreleasing *)progress
             needcommonParams:(BOOL)needCommonParams
            requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
           responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                   autoResume:(BOOL)autoResume
                     callback:(TTNetworkJSONFinishBlock)callback
{
    return [self uploadWithCommon:URLString parameters:parameters headerField:headerField constructingBodyWithBlock:bodyBlock progress:progress needcommonParams:needCommonParams requestSerializer:requestSerializer useJsonResponseSerializer:YES jsonResponseSerializer:responseSerializer binaryResponseSerializer:nil autoResume:autoResume callback:callback callbackWithResponse:nil timeout:15];
}

- (TTHttpTask *)uploadWithResponse:(NSString *)URLString
                        parameters:(id)parameters
                       headerField:(NSDictionary *)headerField
         constructingBodyWithBlock:(TTConstructingBodyBlock)bodyBlock
                          progress:(NSProgress * __autoreleasing *)progress
                  needcommonParams:(BOOL)needCommonParams
                 requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                        autoResume:(BOOL)autoResume
                          callback:(TTNetworkObjectFinishBlockWithResponse)callback
{
    return [self uploadWithResponse:URLString
                         parameters:parameters
                        headerField:headerField
          constructingBodyWithBlock:bodyBlock
                           progress:progress
                   needcommonParams:needCommonParams
                  requestSerializer:requestSerializer
                 responseSerializer:responseSerializer
                         autoResume:autoResume
                           callback:callback
                            timeout:30];
}

- (TTHttpTask *)uploadWithResponse:(NSString *)URLString
                        parameters:(id)parameters
                       headerField:(NSDictionary *)headerField
         constructingBodyWithBlock:(TTConstructingBodyBlock)bodyBlock
                          progress:(NSProgress * __autoreleasing *)progress
                  needcommonParams:(BOOL)needCommonParams
                 requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                        autoResume:(BOOL)autoResume
                          callback:(TTNetworkObjectFinishBlockWithResponse)callback
                           timeout:(NSTimeInterval)timeout {
    return [self uploadWithCommon:URLString parameters:parameters headerField:headerField constructingBodyWithBlock:bodyBlock progress:progress needcommonParams:needCommonParams requestSerializer:requestSerializer useJsonResponseSerializer:NO jsonResponseSerializer:nil binaryResponseSerializer:responseSerializer autoResume:autoResume callback:nil callbackWithResponse:callback timeout:timeout];
}

- (TTHttpTask *)uploadWithCommon:(NSString *)URLString
                      parameters:(id)parameters
                     headerField:(NSDictionary *)headerField
       constructingBodyWithBlock:(TTConstructingBodyBlock)bodyBlock
                        progress:(NSProgress * __autoreleasing *)progress
                needcommonParams:(BOOL)needCommonParams
               requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
       useJsonResponseSerializer:(BOOL)useJsonResponseSerializer
          jsonResponseSerializer:(Class<TTJSONResponseSerializerProtocol>)jsonResponseSerializer
        binaryResponseSerializer:(Class<TTBinaryResponseSerializerProtocol>)binaryResponseSerializer
                      autoResume:(BOOL)autoResume
                        callback:(TTNetworkJSONFinishBlock)callback
            callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                         timeout:(NSTimeInterval)timeout {
#ifdef FULL_API_CONCURRENT_REQUEST
    TTConcurrentHttpTask *concurrentTask = [TTConcurrentHttpTask buildMemoryUploadConcurrentTask:URLString
                                                                      parameters:parameters
                                                                     headerField:headerField
                                                       constructingBodyWithBlock:bodyBlock
                                                                        progress:progress
                                                                needcommonParams:needCommonParams
                                                               requestSerializer:requestSerializer
                                                       useJsonResponseSerializer:useJsonResponseSerializer
                                                          jsonResponseSerializer:jsonResponseSerializer
                                                        binaryResponseSerializer:binaryResponseSerializer
                                                                      autoResume:autoResume
                                                                        callback:callback
                                                            callbackWithResponse:callbackWithResponse
                                                                         timeout:timeout
                                                                         concurrentRequestConfig:self.concurrentRequestConfig];
    
    if (concurrentTask) {
        return concurrentTask;
    }
    
    return [self buildMemoryUploadHttpTask:URLString
                                parameters:parameters
                               headerField:headerField
                 constructingBodyWithBlock:bodyBlock
                                  progress:progress
                          needcommonParams:needCommonParams
                         requestSerializer:requestSerializer
                 useJsonResponseSerializer:useJsonResponseSerializer
                    jsonResponseSerializer:jsonResponseSerializer
                  binaryResponseSerializer:binaryResponseSerializer
                                autoResume:autoResume
                                  callback:callback
                      callbackWithResponse:callbackWithResponse
                                   timeout:timeout];
}

- (TTHttpTaskChromium *)buildMemoryUploadHttpTask:(NSString *)URLString
                      parameters:(id)parameters
                     headerField:(NSDictionary *)headerField
       constructingBodyWithBlock:(TTConstructingBodyBlock)bodyBlock
                        progress:(NSProgress * __autoreleasing *)progress
                needcommonParams:(BOOL)needCommonParams
               requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
       useJsonResponseSerializer:(BOOL)useJsonResponseSerializer
          jsonResponseSerializer:(Class<TTJSONResponseSerializerProtocol>)jsonResponseSerializer
        binaryResponseSerializer:(Class<TTBinaryResponseSerializerProtocol>)binaryResponseSerializer
                      autoResume:(BOOL)autoResume
                        callback:(TTNetworkJSONFinishBlock)callback
            callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                         timeout:(NSTimeInterval)timeout {
#endif /* FULL_API_CONCURRENT_REQUEST */
    NSDate *startBizTime = [NSDate date];
    if (!requestSerializer) {
        requestSerializer = self.defaultRequestSerializerClass;
    }
    
    NSURL *nsurl = [TTNetworkUtil.class isValidURL:URLString callback:callback callbackWithResponse:callbackWithResponse];
    if (!nsurl) {
        return nil;
    }
    NSDictionary *commonParams = [self needCommonParams:needCommonParams requestURL:nsurl];
    
    TTHttpRequest *request = nil;
    NSDate *startSerializerTime = [NSDate date];
    if (headerField == nil) {
        request = [[requestSerializer serializer]
                   URLRequestWithURL:URLString
                   params:parameters
                   method:@"POST"
                   constructingBodyBlock:bodyBlock
                   commonParams:commonParams];
    } else {
        request = [[requestSerializer serializer]
                   URLRequestWithURL:URLString
                   headerField:headerField
                   params:parameters
                   method:@"POST"
                   constructingBodyBlock:bodyBlock
                   commonParams:commonParams];
    }
    if (request) {
        NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
        [request.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(requestSerializer.class)];
        
        request.startBizTime = startBizTime;
    }
    
    if (!request || [self apiHttpInterceptor:request]) {
        NSDictionary *userInfo = nil;
        NSString *reason = nil;
        NSInteger specificErrorCode = 0;
        if (!request) {
            LOGE(@"Can not construct TTHttpRequest!");
            reason = @"Cannot construct TTHttpRequest";
            specificErrorCode = TTNetworkErrorCodeBadURLRequest;
        } else {
            reason = @"request has been intercepted by  the api http interceptor";
            specificErrorCode = TTNetworkErrorCodeApiHttpIntercepted;
        }
        if (URLString) {
            userInfo = @{kTTNetSubErrorCode : @(specificErrorCode), NSLocalizedDescriptionKey : reason, NSURLErrorFailingURLErrorKey : URLString};
        }
        NSError *resultError =  [NSError errorWithDomain:kTTNetworkErrorDomain code:specificErrorCode userInfo:userInfo];
        if (callback) {
            callback(resultError, nil);
        }

        if (callbackWithResponse) {
            callbackWithResponse(resultError, nil, nil);
        }
        return nil;
    }

    request.timeoutInterval = timeout;
    
    if ([commonParams count] > 0) {
        NSData *body = request.HTTPBody;
        
        if ([request isKindOfClass:TTHttpRequestChromium.class]) {
            TTHttpRequestChromium *chromRequest = (TTHttpRequestChromium*)request;
            if (chromRequest.form) {
                body = [chromRequest.form finalFormDataWithHttpRequest:chromRequest];
            }
        }

      try {
          [TTHTTPRequestSerializerBase hashRequest:request body:body];
      } catch (...) {

      }
    }
    
    UInt64 taskId = [self nextTaskId];
    __weak typeof(self) wself = self;
    
    OnHttpTaskCompletedCallbackBlock completedCallback = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {
        if (wself.responseFilterBlock) {
            wself.responseFilterBlock(request, response, data, responseError);
        }
        
        [[TTReqFilterManager shareInstance] runResponseFilter:request response:response data:data responseError:&responseError];
        
        [wself removeTaskWithId_:taskId];
        
        if (responseError && responseError.code == NSURLErrorCancelled) {
            LOGD(@"%s request was cancelled %@", __FUNCTION__, request.URL);
            //return;
        }

        NSError *resultError = nil;
        id responseObj = nil;
        NSDate *startSerializerTime = [NSDate date];
        if (useJsonResponseSerializer) {
            Class<TTJSONResponseSerializerProtocol> responseSerializer = jsonResponseSerializer ? jsonResponseSerializer : self.defaultJSONResponseSerializerClass;
            responseObj = [[responseSerializer serializer] responseObjectForResponse:response jsonObj:data responseError:responseError resultError:&resultError];
            NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
            [response.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(responseSerializer.class)];
        } else {
            Class<TTBinaryResponseSerializerProtocol> responseSerializer = binaryResponseSerializer ? binaryResponseSerializer : self.defaultBinaryResponseSerializerClass;
            responseObj = [[responseSerializer serializer] responseObjectForResponse:response data:data responseError:responseError resultError:&resultError];
            NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
            [response.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(responseSerializer.class)];
        }
            
        TICK;
        dispatch_async(wself.callback_dispatch_queue, ^(void) {
            TOCK;
            if (callback) {
                callback(resultError, responseObj);
            }
            
            if (callbackWithResponse) {
                callbackWithResponse(resultError, responseObj, response);
            }
            
            // monitor request end
            [[TTNetworkManagerMonitorNotifier defaultNotifier] notifyForMonitorFinishResponse:response
                                                                                   forRequest:request
                                                                                        error:responseError
                                                                                     response:data];
        });
    };
    
    __block NSProgress *uploadProgress = nil;
    if (progress) {
        *progress = [NSProgress progressWithTotalUnitCount:10000];
        uploadProgress = *progress;
    }
    
    OnHttpTaskProgressCallbackBlock uploadProgressCallback = ^(int64_t current, int64_t total) {
        //LOGD(@" current = %lld, total = %lld", current, total);
        if (uploadProgress) {
            if (uploadProgress.totalUnitCount != total) {
                uploadProgress.totalUnitCount = total;
            }
            
            uploadProgress.completedUnitCount = current;
        }
        
    };
    
    TTHttpTaskChromium *task = [[TTHttpTaskChromium alloc] initWithRequest:(TTHttpRequestChromium *)request
                                                                    engine:gChromeNet.Get().get()
                                                             dispatchQueue:self.dispatch_queue
                                                                    taskId:taskId
                                                         completedCallback:completedCallback
                                                    uploadProgressCallback:uploadProgressCallback downloadProgressCallback:nil];
    task.uploadProgress = uploadProgress;
    [self addTaskWithId_:taskId task:task];
    
    if (autoResume) {
        [task resume];
    }

    return task;
}

- (TTHttpTask *)uploadRawDataWithResponse:(NSString *)URLString
                                   method:(NSString *)method
                              headerField:(NSDictionary *)headerField
                                bodyField:(NSData *)bodyField
                                 progress:(NSProgress * __autoreleasing *)progress
                        requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                       responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                               autoResume:(BOOL)autoResume
                                 callback:(TTNetworkObjectFinishBlockWithResponse)callback
                                  timeout:(NSTimeInterval)timeout {
    return [self uploadRawDataWithResponse:URLString method:method headerField:headerField bodyField:bodyField progress:progress requestSerializer:requestSerializer responseSerializer:responseSerializer autoResume:autoResume callback:callback timeout:timeout callbackQueue:self.callback_dispatch_queue];
}

- (TTHttpTask *)uploadRawDataWithResponse:(NSString *)URLString
                                   method:(NSString *)method
                              headerField:(nullable NSDictionary *)headerField
                                bodyField:(NSData *)bodyField
                                 progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                        requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                       responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                               autoResume:(BOOL)autoResume
                                 callback:(nullable TTNetworkObjectFinishBlockWithResponse)callback
                                  timeout:(NSTimeInterval)timeout
                            callbackQueue:(dispatch_queue_t)callbackQueue {
    return [self uploadRawInCommon:URLString method:method headerField:headerField bodyField:bodyField filePath:nil offset:0 length:0 progress:progress requestSerializer:requestSerializer responseSerializer:responseSerializer autoResume:autoResume callback:callback timeout:timeout callbackQueue:callbackQueue];
}

- (TTHttpTask *)uploadRawFileWithResponse:(NSString *)URLString
                                   method:(NSString *)method
                              headerField:(NSDictionary *)headerField
                                 filePath:(NSString *)filePath
                                 progress:(NSProgress * __autoreleasing *)progress
                        requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                       responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                               autoResume:(BOOL)autoResume
                                 callback:(TTNetworkObjectFinishBlockWithResponse)callback
                                  timeout:(NSTimeInterval)timeout {
    return [self uploadRawInCommon:URLString method:method headerField:headerField bodyField:nil filePath:filePath offset:0 length:UINT64_MAX progress:progress requestSerializer:requestSerializer responseSerializer:responseSerializer autoResume:autoResume callback:callback timeout:timeout callbackQueue:self.callback_dispatch_queue];
}

- (TTHttpTask *)uploadRawFileWithResponseByRange:(NSString *)URLString
                                          method:(NSString *)method
                                     headerField:(NSDictionary *)headerField
                                        filePath:(NSString *)filePath
                                          offset:(uint64_t)uploadFileOffset
                                          length:(uint64_t)uploadFileLength
                                        progress:(NSProgress * __autoreleasing *)progress
                               requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                              responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                      autoResume:(BOOL)autoResume
                                        callback:(TTNetworkObjectFinishBlockWithResponse)callback
                                         timeout:(NSTimeInterval)timeout {
     return [self uploadRawInCommon:URLString method:method headerField:headerField bodyField:nil filePath:filePath offset:uploadFileOffset length:uploadFileLength progress:progress requestSerializer:requestSerializer responseSerializer:responseSerializer autoResume:autoResume callback:callback timeout:timeout callbackQueue:self.callback_dispatch_queue];
}

- (TTHttpTask *)uploadRawInCommon:(NSString *)URLString
                           method:(NSString *)method
                      headerField:(NSDictionary *)headerField
                        bodyField:(NSData *)bodyField
                         filePath:(NSString *)filePath
                           offset:(uint64_t)uploadFileOffset
                           length:(uint64_t)uploadFileLength
                         progress:(NSProgress * __autoreleasing *)progress
                requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
               responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                       autoResume:(BOOL)autoResume
                         callback:(TTNetworkObjectFinishBlockWithResponse)callback
                          timeout:(NSTimeInterval)timeout
                    callbackQueue:(dispatch_queue_t)callbackQueue {
#ifdef FULL_API_CONCURRENT_REQUEST
    TTConcurrentHttpTask *concurrentTask = [TTConcurrentHttpTask buildFileUploadConcurrentTask:URLString
                                                                        method:method
                                                                   headerField:headerField
                                                                     bodyField:bodyField
                                                                      filePath:filePath
                                                                        offset:uploadFileOffset
                                                                        length:uploadFileLength
                                                                      progress:progress
                                                             requestSerializer:requestSerializer
                                                            responseSerializer:responseSerializer
                                                                    autoResume:autoResume
                                                                      callback:callback
                                                                       timeout:timeout
                                                                       concurrentRequestConfig:self.concurrentRequestConfig
                                                                                 callbackQueue:callbackQueue];
    
    if (concurrentTask) {
        return concurrentTask;
    }
    
    return [self buildFileUploadHttpTask:URLString
                                  method:method
                             headerField:headerField
                               bodyField:bodyField
                                filePath:filePath
                                  offset:uploadFileOffset
                                  length:uploadFileLength
                                progress:progress
                       requestSerializer:requestSerializer
                      responseSerializer:responseSerializer
                              autoResume:autoResume
                                callback:callback
                                 timeout:timeout
                           callbackQueue:callbackQueue];
}


- (TTHttpTaskChromium *)buildFileUploadHttpTask:(NSString *)URLString
                                         method:(NSString *)method
                                      headerField:(NSDictionary *)headerField
                                        bodyField:(NSData *)bodyField
                                         filePath:(NSString *)filePath
                                           offset:(uint64_t)uploadFileOffset
                                           length:(uint64_t)uploadFileLength
                                         progress:(NSProgress * __autoreleasing *)progress
                                requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                               responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                       autoResume:(BOOL)autoResume
                                         callback:(TTNetworkObjectFinishBlockWithResponse)callback
                                          timeout:(NSTimeInterval)timeout
                                  callbackQueue:(dispatch_queue_t)callbackQueue {
#endif /* FULL_API_CONCURRENT_REQUEST */
    NSDate *startBizTime = [NSDate date];
    if (!requestSerializer) {
        requestSerializer = self.defaultRequestSerializerClass;
    }
    if (!responseSerializer) {
        responseSerializer = self.defaultBinaryResponseSerializerClass;
    }

    if (![[method lowercaseString] isEqualToString:@"post"] && ![[method lowercaseString] isEqualToString:@"put"]) {
        LOGE(@"HTTP method %@ is not supported by uploadRawDataWithResponse, url is %@", URLString, method);
        NSDictionary *userInfo = nil;
        if (URLString) {
            userInfo = @{kTTNetSubErrorCode : @(TTNetworkErrorCodeBadURLRequest),
                         NSLocalizedDescriptionKey : @"HTTP method is not supported to upload",
                         NSURLErrorFailingURLErrorKey : URLString};
        }
        NSError *resultError =  [NSError errorWithDomain:kTTNetworkErrorDomain code:TTNetworkErrorCodeBadURLRequest userInfo:userInfo];
        if (callback) {
            callback(resultError, nil, nil);
        }
        return nil;
    }

    TTHttpRequest *request = nil;
    NSDate *startSerializerTime = [NSDate date];
    if (headerField == nil) {
        request = [[requestSerializer serializer]
                   URLRequestWithURL:URLString
                   params:nil
                   method:method
                   constructingBodyBlock:nil
                   commonParams:nil];
    } else {
        request = [[requestSerializer serializer]
                   URLRequestWithURL:URLString
                   headerField:headerField
                   params:nil
                   method:method
                   constructingBodyBlock:nil
                   commonParams:nil];
    }
    if (request) {
        NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
        [request.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(requestSerializer.class)];
        
        request.startBizTime = startBizTime;
    }
    
    if (!request || [self apiHttpInterceptor:request]) {
        NSDictionary *userInfo = nil;
        NSString *reason = nil;
        NSInteger specificErrorCode = 0;
        if (!request) {
            LOGE(@"Can not construct TTHttpRequest!");
            reason = @"Cannot construct TTHttpRequest";
            specificErrorCode = TTNetworkErrorCodeBadURLRequest;
        } else {
            reason = @"request has been intercepted by  the api http interceptor";
            specificErrorCode = TTNetworkErrorCodeApiHttpIntercepted;
        }
        if (URLString) {
            userInfo = @{kTTNetSubErrorCode : @(specificErrorCode),
                         NSLocalizedDescriptionKey : reason,
                         NSURLErrorFailingURLErrorKey : URLString};
        }
        NSError *resultError =  [NSError errorWithDomain:kTTNetworkErrorDomain code:specificErrorCode userInfo:userInfo];
        if (callback) {
            callback(resultError, nil, nil);
        }
        return nil;
    }

    if (![headerField valueForKey:@"Content-Type"]) {
        [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    }
    if (bodyField) {
        request.HTTPBody = bodyField;
    }
    if (filePath) {
        request.uploadFilePath = filePath;
    }
    request.timeoutInterval = timeout;

    UInt64 taskId = [self nextTaskId];
    __weak typeof(self) wself = self;

    OnHttpTaskCompletedCallbackBlock completedCallback = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {
        if (wself.responseFilterBlock) {
            wself.responseFilterBlock(request, response, data, responseError);
        }

        [[TTReqFilterManager shareInstance] runResponseFilter:request response:response data:data responseError:&responseError];

        [wself removeTaskWithId_:taskId];

        if (responseError && responseError.code == NSURLErrorCancelled) {
            LOGD(@"%s request was cancelled %@", __FUNCTION__, request.URL);
        }

        NSError *resultError = nil;
        NSDate *startSerializerTime = [NSDate date];
        id responseObj = [[responseSerializer serializer] responseObjectForResponse:response
                                                                               data:data
                                                                      responseError:responseError
                                                                        resultError:&resultError];
        NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
        [response.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(responseSerializer.class)];
            
        TICK;
        dispatch_async(callbackQueue, ^(void) {
            TOCK;
            if (callback) {
                callback(resultError, responseObj, response);
            }
                
            // monitor request end
            [[TTNetworkManagerMonitorNotifier defaultNotifier] notifyForMonitorFinishResponse:response
                                                                                   forRequest:request
                                                                                        error:responseError
                                                                                     response:data];
        });
    };

    __block NSProgress *uploadProgress = nil;
    if (progress) {
        *progress = [NSProgress progressWithTotalUnitCount:10000];
        uploadProgress = *progress;
    }

    OnHttpTaskProgressCallbackBlock uploadProgressCallback = ^(int64_t current, int64_t total) {
        if (uploadProgress) {
            if (uploadProgress.totalUnitCount != total) {
                uploadProgress.totalUnitCount = total;
            }
            uploadProgress.completedUnitCount = current;
        }
    };

    TTHttpTaskChromium *task = [[TTHttpTaskChromium alloc] initWithRequest:(TTHttpRequestChromium *)request
                                                                    engine:gChromeNet.Get().get()
                                                             dispatchQueue:self.dispatch_queue
                                                                    taskId:taskId
                                                         completedCallback:completedCallback
                                                    uploadProgressCallback:uploadProgressCallback downloadProgressCallback:nil];
    task.uploadProgress = uploadProgress;
    task.uploadFileOffset = uploadFileOffset;
    task.uploadFileLength = uploadFileLength;
    [self addTaskWithId_:taskId task:task];

    if (autoResume) {
        [task resume];
    }

    return task;
}
#pragma mark - Synchronized apis


- (NSDictionary *)synchronizedRequstForURL:(NSString *)URL
                                    method:(NSString *)method
                               headerField:(NSDictionary *)headerField
                             jsonObjParams:(id)params
                          needCommonParams:(BOOL)needCommonParams
                               needEncrypt:(BOOL)needEncrypt {
    
    return [self synchronizedRequstForURL:URL
                                   method:method
                              headerField:headerField
                            jsonObjParams:params
                         needCommonParams:needCommonParams
                             needResponse:NO
                              needEncrypt:needEncrypt];
}

- (NSDictionary *)synchronizedRequstForURL:(NSString *)URL
                                    method:(NSString *)method
                               headerField:(NSDictionary *)headerField
                             jsonObjParams:(id)params
                          needCommonParams:(BOOL)needCommonParams
                              needResponse:(BOOL)needReponse {
    return [self synchronizedRequstForURL:URL
                                   method:method
                              headerField:headerField
                            jsonObjParams:params
                         needCommonParams:needCommonParams
                             needResponse:needReponse
                              needEncrypt:NO];
}

- (NSDictionary *)synchronizedRequstForURL:(NSString *)URL
                                    method:(NSString *)method
                               headerField:(NSDictionary *)headerField
                             jsonObjParams:(id)params
                          needCommonParams:(BOOL)needCommonParams {
    return [self synchronizedRequstForURL:URL
                                   method:method
                              headerField:headerField
                            jsonObjParams:params
                         needCommonParams:needCommonParams
                             needResponse:NO
                              needEncrypt:NO];
}

- (NSDictionary *)synchronizedRequstForURL:(NSString *)URL
                                    method:(NSString *)method
                               headerField:(NSDictionary *)headerField
                             jsonObjParams:(id)params
                          needCommonParams:(BOOL)needCommonParams
                              needResponse:(BOOL)needResponse
                               needEncrypt:(BOOL)needEncrypt {
    return [self synchronizedRequstForURL:URL method:method headerField:headerField jsonObjParams:params needCommonParams:needCommonParams needResponse:needResponse needEncrypt:needEncrypt needContentEncodingAfterEncrypt:NO];
}

- (NSDictionary *)synchronizedRequstForURL:(NSString *)URL
                                    method:(NSString *)method
                               headerField:(NSDictionary *)headerField
                             jsonObjParams:(id)params
                          needCommonParams:(BOOL)needCommonParams
                              needResponse:(BOOL)needResponse
                               needEncrypt:(BOOL)needEncrypt
           needContentEncodingAfterEncrypt:(BOOL)needContentEncoding {
    return [self synchronizedRequstForURL:URL method:method headerField:headerField jsonObjParams:params needCommonParams:needCommonParams requestSerializer:nil needResponse:needResponse needEncrypt:needEncrypt needContentEncodingAfterEncrypt:needContentEncoding];
}

- (NSDictionary *)synchronizedRequstForURL:(NSString *)URL
                                    method:(NSString *)method
                               headerField:(NSDictionary *)headerField
                             jsonObjParams:(id)params
                          needCommonParams:(BOOL)needCommonParams
                         requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)serializer
                              needResponse:(BOOL)needResponse
                               needEncrypt:(BOOL)needEncrypt
           needContentEncodingAfterEncrypt:(BOOL)needContentEncoding {
    NSDate *startBizTime = [NSDate date];
    if (isEmptyStringForNetworkUtil(URL)) {
        NSDictionary *userInfo = @{kTTNetSubErrorCode : @(TTNetworkErrorCodeBadURLRequest),
                                   NSLocalizedDescriptionKey : @"empty url",
                                   NSURLErrorFailingURLErrorKey : @""};
        NSError *resultError =  [NSError errorWithDomain:kTTNetworkErrorDomain code:TTNetworkErrorCodeBadURLRequest userInfo:userInfo];
        LOGE(@"%@",resultError.description);
        return nil;
    }
    
    NSURL *nsurl = [TTNetworkUtil.class isValidURL:URL callback:nil callbackWithResponse:nil];
    if (!nsurl) {
        return nil;
    }
    NSDictionary *commonParams = [self needCommonParams:needCommonParams requestURL:nsurl];
    NSDate *startSerializerTime = [NSDate date];
    Class<TTHTTPRequestSerializerProtocol> requestSerializer = serializer ? serializer : self.defaultRequestSerializerClass;
    TTHttpRequest *request = [[requestSerializer serializer] URLRequestWithURL:URL
                                                                                    headerField:headerField
                                                                                         params:params
                                                                                         method:method
                                                                          constructingBodyBlock:nil
                                                                                   commonParams:commonParams];
    if (request) {
        NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
        [request.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(requestSerializer.class)];
        
        request.startBizTime = startBizTime;
    }
    if ([self apiHttpInterceptor:request]) {
        NSDictionary *userInfo = nil;
        if (URL) {
            userInfo = @{kTTNetSubErrorCode : @(TTNetworkErrorCodeBadURLRequest),
                         NSLocalizedDescriptionKey : @"the synchronized request has been intercepted by  the api http interceptor",
                         NSURLErrorFailingURLErrorKey : URL};
        }
        NSError *resultError =  [NSError errorWithDomain:kTTNetworkErrorDomain code:TTNetworkErrorCodeApiHttpIntercepted userInfo:userInfo];
        LOGE(@"%@",resultError.description);

        return nil;
    }
    
    NSString *upperCaseMethod = [method uppercaseString];
    if ([upperCaseMethod isEqualToString:@"POST"] && params && !serializer) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        NSError *jsonError = nil;
        if (![NSJSONSerialization isValidJSONObject:params]) {
            LOGE(@"params is not a valid json");
            return nil;
        }
        [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:params options:(NSJSONWritingOptions)0 error:&jsonError]];
    }
    
    // gzip compress body
    
    NSData *body = request.HTTPBody;
    NSData *compressedData = nil;
    if (body) {
        NSError *compressionError = nil;
        compressedData = [body dataByGZipCompressingWithError:&compressionError];
        
        if (compressedData && !compressionError) {
            [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
            [request setHTTPBody:compressedData];
        } else {
            LOGE(@"gzip compression failed!");
            NSAssert(false, @"gzip compression failed!");
            return nil;
        }
    }
    
    if (needEncrypt && compressedData) {
        NSData *resultData = [compressedData bd_dataByDecorated];
        if (resultData != nil) {
            [request setHTTPBody:resultData];
            
            if (!needContentEncoding) {
                [request setValue:nil forHTTPHeaderField:@"Content-Encoding"];
            }else{
                [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
            }
            [request setValue:@"application/octet-stream;tt-data=a" forHTTPHeaderField:@"Content-Type"];
        }
    }
    
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:request.URL];
    if ([cookies count] > 0) {
        NSHTTPCookie *cookie;
        NSString *cookieHeader = nil;
        for (cookie in cookies) {
            if (!cookieHeader) {
                cookieHeader = [NSString stringWithFormat: @"%@=%@",[cookie name],[cookie value]];
            } else {
                cookieHeader = [NSString stringWithFormat: @"%@; %@=%@",cookieHeader,[cookie name],[cookie value]];
            }
        }
        if (cookieHeader) {
            [request setValue:cookieHeader forHTTPHeaderField:@"Cookie"];
            [request setValue:cookieHeader forHTTPHeaderField:@"X-SS-Cookie"];
        }
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    UInt64 taskId = [self nextTaskId];
    
    __block id responseResult = nil;
    __block NSError *errorResult = nil;
    __block NSInteger statusCode = 0;
    __block TTHttpResponseChromium *responseChromium = nil;
    
    OnHttpTaskCompletedCallbackBlock completedCallback = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {

        if (self.responseFilterBlock) {
          self.responseFilterBlock(request, response, data, responseError);
        }
        
        [[TTReqFilterManager shareInstance] runResponseFilter:request response:response data:data responseError:&responseError];
        
        Class<TTJSONResponseSerializerProtocol> responseSerializer = TTHTTPJSONResponseSerializerBase.class;
        
        
        NSError *resultError = nil;
        NSDate *startSerializerTime = [NSDate date];
        id responseObj = [[responseSerializer serializer] responseObjectForResponse:response
                                                                            jsonObj:data
                                                                      responseError:responseError
                                                                        resultError:&resultError];
        NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
        [response.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(responseSerializer.class)];
        [self removeTaskWithId_:taskId];
        
        responseResult = responseObj;
        errorResult = responseError;
        statusCode = response.statusCode;
        responseChromium = response;
        
        dispatch_semaphore_signal(semaphore);
    };
    
    if ([commonParams count] > 0) {
      try {
        [TTHTTPRequestSerializerBase hashRequest:request body:request.HTTPBody];
      } catch (...) {

      }
    }
    
    TTHttpTaskChromium *task = [[TTHttpTaskChromium alloc] initWithRequest:(TTHttpRequestChromium *)request
                                                                    engine:gChromeNet.Get().get()
                                                             dispatchQueue:self.dispatch_queue
                                                                    taskId:taskId
                                                         completedCallback:completedCallback];
    
    [self addTaskWithId_:taskId task:task];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        [task resume];
    });
    
    
    long ret = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 120 * NSEC_PER_SEC));
    if (ret > 0) {
        LOGD(@"wait more than 120 seconds for a url: %@", URL);
        
    }
    
    // monitor request end
    [[TTNetworkManagerMonitorNotifier defaultNotifier]
     notifyForMonitorFinishResponse:responseChromium
     forRequest:request
     error:errorResult
     response:responseResult];
    
    if (needResponse) {
        NSMutableDictionary * rs = [[NSMutableDictionary alloc] init];
        [rs setValue:@(statusCode) forKey:@"status_code"];
        
        if (!errorResult) {
            [rs setValue:responseResult forKey:@"result"];
            
        } else {
            LOGD(@"url:%@ return failed http result error: %@", URL, errorResult);
            if (responseResult) {
                [rs setValue:@YES forKey:@"has_response"];
            }
        }
        return [rs copy];
    } else {
        NSDictionary *result = nil;
        if (!errorResult) {
            result = responseResult;
        }
        return result;
    };
    
}

#pragma mark - Progress download file API

/**
 * For game business to download large files, piecemeal download, real-time display progress.
 */
- (TTHttpTask *)downloadTaskBySlice:(NSString *)URLString
                         parameters:(id)parameters
                        headerField:(NSDictionary *)headerField
                   needCommonParams:(BOOL)needCommonParams
                  requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                   progressCallback:(void (^)(int64_t current, int64_t total))progressCallback
                        destination:(NSURL *)destination
                         autoResume:(BOOL)autoResume
                  completionHandler:(void (^)(TTHttpResponse *response, NSURL *filePath, NSError *error))completionHandler {
    return [self downloadTaskByAppendIfNeed:URLString
                                 parameters:parameters
                                headerField:headerField
                           needCommonParams:needCommonParams
                          requestSerializer:requestSerializer
                                   isAppend:YES
                           progressCallback:progressCallback
                                   progress:nil
                                destination:destination
                                 autoResume:autoResume
                          completionHandler:completionHandler];
}

- (TTHttpTask *)downloadTaskWithRequest:(NSString *)URLString
                             parameters:(id)parameters
                            headerField:(NSDictionary *)headerField
                       needCommonParams:(BOOL)needCommonParams
                               progress:(NSProgress * __autoreleasing *)progress
                            destination:(NSURL *)destination
                      completionHandler:(void (^)(TTHttpResponse *response, NSURL *filePath, NSError *error))completionHandler {
    return [self downloadTaskWithRequest:URLString parameters:parameters headerField:headerField needCommonParams:needCommonParams progress:progress destination:destination autoResume:YES completionHandler:completionHandler];
}

- (TTHttpTask *)downloadTaskWithRequest:(NSString *)URLString
                             parameters:(id)parameters
                            headerField:(NSDictionary *)headerField
                       needCommonParams:(BOOL)needCommonParams
                               progress:(NSProgress * __autoreleasing *)progress
                            destination:(NSURL *)destination
                             autoResume:(BOOL)autoResume
                      completionHandler:(void (^)(TTHttpResponse *response, NSURL *filePath, NSError *error))completionHandler {

    return [self downloadTaskWithRequest:URLString parameters:parameters headerField:headerField needCommonParams:needCommonParams requestSerializer:nil progress:progress destination:destination autoResume:autoResume completionHandler:completionHandler];
}

// can specify request serializer
- (TTHttpTask *)downloadTaskWithRequest:(NSString *)URLString
                             parameters:(id)parameters
                            headerField:(NSDictionary *)headerField
                       needCommonParams:(BOOL)needCommonParams
                      requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                               progress:(NSProgress * __autoreleasing *)progress
                            destination:(NSURL *)destination
                             autoResume:(BOOL)autoResume
                      completionHandler:(void (^)(TTHttpResponse *response, NSURL *filePath, NSError *error))completionHandler {
    return [self downloadTaskByAppendIfNeed:URLString
                                 parameters:parameters
                                headerField:headerField
                           needCommonParams:needCommonParams
                          requestSerializer:requestSerializer
                                   isAppend:NO
                           progressCallback:nil
                                   progress:progress
                                destination:destination
                                 autoResume:autoResume
                          completionHandler:completionHandler];
}

- (TTHttpTask *)downloadTaskByAppendIfNeed:(NSString *)URLString
                                parameters:(id)parameters
                               headerField:(NSDictionary *)headerField
                          needCommonParams:(BOOL)needCommonParams
                         requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                  isAppend:(BOOL)isAppend
                          progressCallback:(void (^)(int64_t current, int64_t total))progressCallback
                                  progress:(NSProgress * __autoreleasing *)progress
                               destination:(NSURL *)destination
                                autoResume:(BOOL)autoResume
                         completionHandler:(void (^)(TTHttpResponse *response, NSURL *filePath, NSError *error))completionHandler {
#ifdef FULL_API_CONCURRENT_REQUEST
    TTConcurrentHttpTask *concurrentTask = [TTConcurrentHttpTask buildDownloadConcurrentTask:URLString
                                                                  parameters:parameters
                                                                 headerField:headerField
                                                            needCommonParams:needCommonParams
                                                           requestSerializer:requestSerializer
                                                                    isAppend:isAppend
                                                            progressCallback:progressCallback
                                                                    progress:progress
                                                                 destination:destination
                                                                  autoResume:autoResume
                                                           completionHandler:completionHandler
                                                                     concurrentRequestConfig:self.concurrentRequestConfig];
    
    if (concurrentTask) {
        return concurrentTask;
    }
    
    return [self buildDownloadHttpTask:URLString
                            parameters:parameters
                           headerField:headerField
                      needCommonParams:needCommonParams
                     requestSerializer:requestSerializer
                              isAppend:isAppend
                      progressCallback:progressCallback
                              progress:progress
                           destination:destination
                            autoResume:autoResume
                     completionHandler:completionHandler];
}

- (TTHttpTaskChromium *)buildDownloadHttpTask:(NSString *)URLString
                                   parameters:(id)parameters
                                  headerField:(NSDictionary *)headerField
                             needCommonParams:(BOOL)needCommonParams
                            requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                     isAppend:(BOOL)isAppend
                             progressCallback:(void (^)(int64_t current, int64_t total))progressCallback
                                     progress:(NSProgress * __autoreleasing *)progress
                                  destination:(NSURL *)destination
                                   autoResume:(BOOL)autoResume
                            completionHandler:(void (^)(TTHttpResponse *response, NSURL *filePath, NSError *error))completionHandler {
#endif /* FULL_API_CONCURRENT_REQUEST */
    NSDate *startBizTime = [NSDate date];
    NSAssert(destination.fileURL, @"destination must be a file NSURL!");
    NSURL *nsurl = [TTNetworkUtil.class isValidURL:URLString callback:nil callbackWithResponse:nil];
    if (!nsurl) {
        NSDictionary *userInfo = nil;
        if (URLString) {
            userInfo = @{kTTNetSubErrorCode : @(TTNetworkErrorCodeBadURLRequest), NSLocalizedDescriptionKey : @"url string is invalid!", NSURLErrorFailingURLErrorKey : URLString};
        }
        NSError *resultError =  [NSError errorWithDomain:kTTNetworkErrorDomain code:TTNetworkErrorCodeBadURLRequest userInfo:userInfo];
        if (completionHandler) {
            completionHandler(nil, nil, resultError);
        }
        return nil;
    }
    NSDictionary *commonParams = [self needCommonParams:needCommonParams requestURL:nsurl];

    if (!requestSerializer) {
        requestSerializer = self.defaultRequestSerializerClass;
    }

    TTHttpRequest *request = nil;
    NSDate *startSerializerTime = [NSDate date];
    if (headerField == nil) {
        request = [[requestSerializer serializer]
                   URLRequestWithURL:URLString
                   params:parameters
                   method:@"GET"
                   constructingBodyBlock:nil
                   commonParams:commonParams];
    } else {
        request = [[requestSerializer serializer]
                   URLRequestWithURL:URLString
                   headerField:headerField
                   params:parameters
                   method:@"GET"
                   constructingBodyBlock:nil
                   commonParams:commonParams];
    }
    if (request) {
        NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startSerializerTime timeIntervalSinceNow]) * 1000];
        [request.serializerTimeInfo setValue:elapsedTime forKey:NSStringFromClass(requestSerializer.class)];
        
        request.startBizTime = startBizTime;
    }
    
    if (!request || [self apiHttpInterceptor:request]) {
        //        NSAssert(false, @"no request created!");
        NSDictionary *userInfo = nil;
        NSString *reason = nil;
        NSInteger specificErrorCode = 0;
        if (!request) {
            LOGE(@"Can not construct TTHttpRequest!");
            reason = @"Cannot construct TTHttpRequest";
            specificErrorCode = TTNetworkErrorCodeBadURLRequest;
        } else {
            reason = @"request has been intercepted by  the api http interceptor";
            specificErrorCode = TTNetworkErrorCodeApiHttpIntercepted;
        }
        if ([request URL]) {
            userInfo = @{kTTNetSubErrorCode : @(specificErrorCode),
                         NSLocalizedDescriptionKey : reason,
                         NSURLErrorFailingURLErrorKey : [request URL]};
        }
        NSError *resultError =  [NSError errorWithDomain:kTTNetworkErrorDomain code:specificErrorCode userInfo:userInfo];

        if (completionHandler) {
            completionHandler(nil, nil, resultError);
        }
        return nil;
    }

    if ([commonParams count] > 0) {
        try {
            [TTHTTPRequestSerializerBase hashRequest:request body:request.HTTPBody];
        } catch (...) {

        }
    }

    UInt64 taskId = [self nextTaskId];
    __weak typeof(self) wself = self;

    OnHttpTaskCompletedCallbackBlock completedCallback = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {
        if (wself.responseFilterBlock) {
            wself.responseFilterBlock(request, response, data, responseError);
        }

        [[TTReqFilterManager shareInstance] runResponseFilter:request response:response data:data responseError:&responseError];

        [wself removeTaskWithId_:taskId];

        if (responseError && responseError.code == NSURLErrorCancelled) {
            LOGD(@"%s request was cancelled %@", __FUNCTION__, request.URL);
            //return;
        }

        NSAssert(data == nil || [data isKindOfClass:NSData.class], @"data must be a NSData!");
        dispatch_queue_t callbackQueue = wself.callback_dispatch_queue;
        if (isAppend) {
            /**
             * downloader's callback just dispatch to global queue.
             */
            callbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        }

        TICK;
        dispatch_async(callbackQueue, ^(void) {
            TOCK;
            if (completionHandler) {
                completionHandler(response, destination, responseError);
            }
                
            // monitor request end
            [[TTNetworkManagerMonitorNotifier defaultNotifier] notifyForMonitorFinishResponse:response
                                                                                   forRequest:request
                                                                                        error:responseError
                                                                                     response:data];
        });
    };

    OnHttpTaskProgressCallbackBlock downloadProgressCallback;
    __block NSProgress *downloadProgress = nil;

    if (isAppend) {
        downloadProgressCallback = progressCallback;
    } else {
        if (progress) {
            *progress = [NSProgress progressWithTotalUnitCount:10000];
            downloadProgress = *progress;
        }
        downloadProgressCallback = ^(int64_t current, int64_t total) {
            //LOGD(@" current = %lld, total = %lld", current, total);
            if (downloadProgress) {
                if (downloadProgress.totalUnitCount != total) {
                    downloadProgress.totalUnitCount = total;
                }
                downloadProgress.completedUnitCount = current;
            }
        };
    }

    TTHttpTaskChromium *task = [[TTHttpTaskChromium alloc] initWithRequest:(TTHttpRequestChromium *)request
                                                                    engine:gChromeNet.Get().get()
                                                             dispatchQueue:self.dispatch_queue
                                                                    taskId:taskId
                                                         completedCallback:completedCallback
                                                    uploadProgressCallback:nil
                                                  downloadProgressCallback:downloadProgressCallback];
    task.fileDestinationURL = destination;
    task.isFileAppend = isAppend;
    task.requestTypeFlags = TTNetRequestTypeDownloadRequest;
    if (!isAppend) {
        task.downloadProgress = downloadProgress;
    }
    [self addTaskWithId_:taskId task:task];

    if (autoResume) {
        [task resume];
    }

    return task;
}

#pragma mark - Handle Pre processing

- (BOOL)handleResponsePreProcessing_:(TTHttpResponse *)response
                                data:(id)responseData
                               error:(NSError *)error
                             request:(TTHttpRequest *)request
                        preprocessor:(id<TTResponsePreProcessorProtocol>)preprocessor
                      headerCallback:(OnHttpTaskHeaderReadCompletedCallbackBlock)headerBlock
                        dataCallback:(OnHttpTaskDataReadCompletedCallbackBlock)dataBlock
                   completedCallback:(OnHttpTaskCompletedCallbackBlock)block {
    
    if (error && [error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        return NO;
    }
    
    [preprocessor preprocessWithResponse:response responseObject:&responseData error:&error ForRequest:request];
    
    if (preprocessor.ttNeedsRetry) {
        // use strict mode when do https or http retry.
        NSURL *url = preprocessor.retryRequest.URL;
        if (!url) {
            return NO;
        }
        NSURLComponents *com = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        BOOL strictMode = NO;
        if ([com.query rangeOfString:@"strict=0"].location != NSNotFound) {
            com.query = [com.query stringByReplacingOccurrencesOfString:@"strict=0" withString:@"strict=1"];
            strictMode = YES;
        }
        preprocessor.retryRequest.URL = com.URL;
        
        request = preprocessor.retryRequest;
        
        if (strictMode) {
          try {
            [TTHTTPRequestSerializerBase hashRequest:request body:request.HTTPBody];
          } catch (...) {

          }
        }
        
        UInt64 taskId = [self nextTaskId];
        
        __block __weak OnHttpTaskCompletedCallbackBlock weakOnHttpTaskCompletedCallbackBlock = nil;
        __weak typeof(self) wself = self;
        OnHttpTaskCompletedCallbackBlock completedCallback = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {
            [wself removeTaskWithId_:taskId];
            
            // monitor request end
            [[TTNetworkManagerMonitorNotifier defaultNotifier]
             notifyForMonitorFinishResponse:response
             forRequest:request
             error:responseError
             response:data];
            
            // do preprocessing
            if (preprocessor) {
                
                OnHttpTaskCompletedCallbackBlock strongBlock = weakOnHttpTaskCompletedCallbackBlock;
                BOOL needRetry = [wself handleResponsePreProcessing_:response data:data error:responseError request:request preprocessor:preprocessor headerCallback:headerBlock dataCallback:dataBlock completedCallback:strongBlock];
                
                if (needRetry) {
                    LOGD(@"%s preprocessor needs retry the request: %@", __FUNCTION__, request.URL);
                    return;
                }
            }
            
            if (block) {
                block(response, data, responseError);
            }
        };
        
        weakOnHttpTaskCompletedCallbackBlock = completedCallback;
        TTHttpTaskChromium* task = [[TTHttpTaskChromium alloc] initWithRequest:(TTHttpRequestChromium *)request
                                                                        engine:gChromeNet.Get().get()
                                                                 dispatchQueue:self.dispatch_queue
                                                                        taskId:taskId
                                                             completedCallback:completedCallback];
        task.headerBlock = headerBlock;
        task.dataBlock = dataBlock;
        
        [self addTaskWithId_:taskId task:task];
        
        [task resume];
        
        return YES;
    }
    
    if (preprocessor.alertHijack) {
        
        NSError *customError = [NSError errorWithDomain:kTTNetworkErrorDomain
                                                   code:TTNetworkErrorCodeNetworkHijacked
                                               userInfo:@{kTTNetworkUserinfoTipKey : kTTNetworkErrorTipNetworkHijacked}];
        
        NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
        if (!userInfo) {
            userInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
        }
        [userInfo setValue:customError forKey:kTTNetworkCustomErrorKey];
        
        if (error && error.domain) {
            error = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
        } else {
            error = [NSError errorWithDomain:kTTNetworkErrorDomain code:TTNetworkErrorCodeNetworkHijacked userInfo:userInfo];
        }
        
        response = nil;
        responseData = nil;
    }
    
    [preprocessor finishPreprocess];
    return NO;
}

#pragma mark - handle retry for verification code callback

- (BOOL)handleBDTuringCallback:(TTHttpRequest *)request
                      response:(TTHttpResponseChromium *)response
              redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback
                headerCallback:(OnHttpTaskHeaderReadCompletedCallbackBlock)headerBlock
                  dataCallback:(OnHttpTaskDataReadCompletedCallbackBlock)dataBlock
 deserializingAndCallbackBlock:(OnHttpTaskCompletedCallbackBlock)deserializingAndCallbackBlock {
    //handle verification code related callback
    BOOL checkResult = NO;
    BOOL isBypassBDTuring = NO;
    id bypassBDTuringHeaderValue = [[request allHTTPHeaderFields] objectForKey:kTTNetBDTuringBypass];
    if (bypassBDTuringHeaderValue && [bypassBDTuringHeaderValue isKindOfClass:NSString.class]) {
        isBypassBDTuring = [(NSString *)bypassBDTuringHeaderValue isEqualToString:@"1"];
    }
    
    RequestRetryResult *retryResult = [[RequestRetryResult alloc] initWithRetryResult:NO addRequestHeaders:nil];
    if (response.statusCode == 200 && [[response allHeaderFields] objectForKey:kTTNetBDTuringVerify] && !isBypassBDTuring) {
        NSDate *startTime = [NSDate date];
        if (self.retryRequestByTuringHeaderCallback) {
            retryResult = self.retryRequestByTuringHeaderCallback(response);
            [[response allHeaderFields] removeObjectForKey:kTTNetBDTuringVerify];
        } else if (self.addResponseHeadersCallback) {
            checkResult = self.addResponseHeadersCallback(response);
            retryResult.requestRetryEnabled = checkResult;
            [[response allHeaderFields] removeObjectForKey:kTTNetBDTuringVerify];
        }
        NSTimeInterval duration = -[startTime timeIntervalSinceNow];//s
        duration *= 1000;//ms
        if (retryResult.requestRetryEnabled) {
            //retry the request
            [self handleVerificationRetry:request
                        addRequestHeaders:retryResult.addRequestHeaders
                   turingCallbackDuration:duration
                         redirectCallback:redirectCallback
                           headerCallback:headerBlock
                             dataCallback:dataBlock
                        completedCallback:deserializingAndCallbackBlock];
        }
    }
    return retryResult.requestRetryEnabled;
}

- (void)handleVerificationRetry:(TTHttpRequest *)request
              addRequestHeaders:(NSDictionary*) addRequestHeaders
         turingCallbackDuration:(NSTimeInterval)turingDuration
               redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback
                 headerCallback:(OnHttpTaskHeaderReadCompletedCallbackBlock)headerBlock
                   dataCallback:(OnHttpTaskDataReadCompletedCallbackBlock)dataBlock
              completedCallback:(OnHttpTaskCompletedCallbackBlock)completedBlock {
    if (addRequestHeaders) {
        for (NSString* addKey in [addRequestHeaders allKeys]) {
            NSString* addValue = [addRequestHeaders objectForKey:addKey];
            if (addKey && addValue) {
                [[request allHTTPHeaderFields] setValue:addValue forKey:addKey];
            }
        }
    }
    [[request allHTTPHeaderFields] setValue:@"1" forKey:kTTNetBDTuringRetry];
    UInt64 taskId = [self nextTaskId];
    
    __block __weak OnHttpTaskCompletedCallbackBlock weakOnHttpTaskCompletedCallbackBlock = nil;
    __weak typeof(self) wself = self;
    OnHttpTaskCompletedCallbackBlock completedCallback = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {
        [wself removeTaskWithId_:taskId];
        
        BDTuringCallbackInfo *turingCallbackInfo = [[BDTuringCallbackInfo alloc] initWithTuringRetry:1 callbackDuration:turingDuration];
        [response setTuringCallbackRelatedInfo:turingCallbackInfo];
        
        if (completedBlock) {
            completedBlock(response, data, responseError);
        }
    };
    
    weakOnHttpTaskCompletedCallbackBlock = completedCallback;
    TTHttpTaskChromium* task = [[TTHttpTaskChromium alloc] initWithRequest:(TTHttpRequestChromium *)request
                                                                    engine:gChromeNet.Get().get()
                                                             dispatchQueue:self.dispatch_queue
                                                                    taskId:taskId
                                                         completedCallback:completedCallback];
    task.redirectedBlock = redirectCallback;
    task.headerBlock = headerBlock;
    task.dataBlock = dataBlock;
    
    [self addTaskWithId_:taskId task:task];
    
    [task resume];
}

#pragma mark - Addtional functions

- (void)enableVerboseLog {
  self.enable_verbose_log = YES;
  if (gChromeNet.Get()) {
    logging::SetMinLogLevel(logging::LOG_VERBOSE);
  }
}

- (void)doRouteSelection {
  LOGI(@"LCS trigger a new request.");
  auto config = net::TTServerConfig::GetInstance();
  if (gChromeNet.Get()) {
    gChromeNet.Get()->GetURLRequestContextGetter()->GetNetworkTaskRunner()->PostTask(FROM_HERE, base::Bind(&net::TTServerConfig::UpdateServerConfig, base::Unretained(config), net::TTServerConfigObserver::UpdateSource::TTFRONTIER));
  }
}

- (void)clearHttpCache {
  if (gChromeNet.Get()) {
//      gChromeNet.Get()->ClearHttpDiskCache();
  }
}

- (int64_t)getHttpDiskCacheSize {
  if (gChromeNet.Get()) {
    return gChromeNet.Get()->GetHttpDiskCacheSize();
  }
  return 0;
}

- (void)setHttpDiskCacheSize:(int)size {
    self.max_disk_cache_size = size;
}

- (void)setProxy:(NSString *)proxy {
  self.ttnetProxyConfig = proxy;
  if (gChromeNet.Get()) {
    return gChromeNet.Get()->SetProxyConfig(base::SysNSStringToUTF8(proxy));
  }
}

- (void)setBoeProxyEnabled:(BOOL)enabled {
  self.ttnetBoeEnabled = enabled;
  if (gChromeNet.Get()) {
    gChromeNet.Get()->SetBoeEnabled(enabled, CPPSTR([TTNetworkManager shareInstance].bypassBoeJSON));
  }
}

- (void)addReferrerScheme:(NSString*)newScheme {
  if (gChromeNet.Get()) {
    const char *cString = [newScheme cStringUsingEncoding:NSUTF8StringEncoding];
    url::AddReferrerScheme(cString, url::SCHEME_WITH_HOST_PORT_AND_USER_INFORMATION);
  }
}

- (void)changeNetworkThreadPriority:(double)priority {
  if (gChromeNet.Get()) {
    gChromeNet.Get()->SetNetworkThreadPriority(priority);
  }
}

- (TTNetEffectiveConnectionType)getEffectiveConnectionType {
#if !defined(DISABLE_NQE_SUPPORT)
    if (gChromeNet.Get()) {
        return (TTNetEffectiveConnectionType)(gChromeNet.Get()->GetEffectiveConnectionType());
    }
#endif
    return EFFECTIVE_CONNECTION_TYPE_UNKNOWN;
}

- (TTNetworkQuality*)getNetworkQuality {
    TTNetworkQuality* networkQuality = [[TTNetworkQuality alloc] init];
#if !defined(DISABLE_NQE_SUPPORT)
    if (gChromeNet.Get()) {
        networkQuality.httpRttMs = gChromeNet.Get()->GetHttpRttMs();
        networkQuality.transportRttMs = gChromeNet.Get()->GetTransportRttMs();
        networkQuality.downstreamThroughputKbps = gChromeNet.Get()->GetDownstreamThroughputKbps();
    }
#endif
    return networkQuality;
}

- (TTNetworkQualityV2*)getNetworkQualityV2 {
    TTNetworkQualityV2* networkQuality = [[TTNetworkQualityV2 alloc] init];
#if !defined(DISABLE_NQE_SUPPORT)
    if (gChromeNet.Get()) {
        networkQuality.level = gChromeNet.Get()->GetNetworkQualityLevel();
        networkQuality.effectivHttpRttMs = gChromeNet.Get()->GetEffectiveHttpRtt();
        networkQuality.effectiveTransportRttMs = gChromeNet.Get()->GetEffectiveTransportRtt();
        networkQuality.effectiveRxThroughputKbps = gChromeNet.Get()->GetEffectiveDownstreamThroughput();
    }
#endif
    return networkQuality;
}

- (TTPacketLossMetrics*)getPacketLossMetrics:(TTPacketLossProtocol)protocol {
    TTPacketLossMetrics* packetLossMetrics = [[TTPacketLossMetrics alloc] init];
#if !defined(DISABLE_NQE_SUPPORT)
    if (gChromeNet.Get()) {
        packetLossMetrics.protocol = protocol;
        packetLossMetrics.upstreamLossRate =
            gChromeNet.Get()->GetUpstreamPacketLossRate((net::PacketLossAnalyzerProtocol)protocol);
        packetLossMetrics.upstreamLossRateVariance =
            gChromeNet.Get()->GetUpstreamPacketLossRateVariance((net::PacketLossAnalyzerProtocol)protocol);
        packetLossMetrics.downstreamLossRate =
            gChromeNet.Get()->GetDownstreamPacketLossRate((net::PacketLossAnalyzerProtocol)protocol);
        packetLossMetrics.downstreamLossRateVariance =
            gChromeNet.Get()->GetDownstreamPacketLossRateVariance((net::PacketLossAnalyzerProtocol)protocol);
    }
#endif
    return packetLossMetrics;
}

- (void)applicationDidEnterBackground_:(UIApplication *)application {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int64_t size = [self getHttpDiskCacheSize];
            int64_t max_size = self.max_disk_cache_size > 0 ? self.max_disk_cache_size : 64 * 1000 * 1000;
            if (size >= max_size) {
              if (gChromeNet.Get()) {
                gChromeNet.Get()->ClearHttpDiskCache();
              }
              LOGD(@"after http size = %lld", size);
            }
        });
    });
}

- (void)applicationWillTerminate_:(UIApplication *)application {
    if (gChromeNet.Get()) {
        gChromeNet.Get()->SetAppWillTerminateEnabled(YES);
    }
}

- (void)setNetworkQualityObserverBlock:(GetNqeResultBlock)block {
#if !defined(DISABLE_NQE_SUPPORT)
    if (!nqeObserver_) {
        nqeObserver_ = new NQEObserver(block);
    } else {
        LOGE(@"SetNetworkQualityObserverBlock can only be called once.");
    }
#endif
}

- (void)setPacketLossObserverBlock:(GetPacketLossResultBlock)block {
#if !defined(DISABLE_NQE_SUPPORT)
    if (!packetLossRateObserver_) {
        packetLossRateObserver_ = new PacketLossRateObserver(block);
    } else {
        LOGE(@"SetPacketLossObserverBlock can only be called once.");
    }
#endif
}

@synthesize hostResolverRulesForTesting = _hostResolverRules;
- (NSString*)hostResolverRulesForTesting {
    return _hostResolverRules;
}

- (void)setHostResolverRulesForTesting:(NSString *)hostResolverRules {
    _hostResolverRules = hostResolverRules;
    if (gChromeNet.Get()) {
        gChromeNet.Get()->SetHostResolverRules(CPPSTR(hostResolverRules));
    }
}

#pragma mark - Interface for media product usage

- (NSDictionary *) generateRangeHeaderField:(NSInteger)offset requestedLength:(NSInteger)requestedLength headerField:(NSDictionary *)headerField {
    NSString *rangeValue = [NSString stringWithFormat:@"bytes=%ld-", offset];
    if (requestedLength > 0) {
        rangeValue = [rangeValue stringByAppendingString:[NSString stringWithFormat:@"%ld", offset + requestedLength - 1]];
    }
    
    NSDictionary *headers = nil;
    if (headerField) {
        headers = headerField;
    } else {
        headers = [[NSMutableDictionary alloc] init];
    }
    [headers setValue:rangeValue forKey:@"Range"];
    
    return headers;
}

- (TTHttpTask *)requestForRangeMediaResource:(NSString *)URL
                                      params:(id)params
                                      method:(NSString *)method
                                      offset:(NSInteger)offset
                             requestedLength:(NSInteger)requestedLength
                            needCommonParams:(BOOL)commonParams
                                 headerField:(NSDictionary *)headerField
                             enableHttpCache:(BOOL)enableHttpCache
                           requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                  autoResume:(BOOL)autoResume
                    onHeaderReceivedCallback:(TTNetworkChunkedDataHeaderBlock)onHeaderReceivedCallback
                          onDataReadCallback:(TTNetworkChunkedDataReadBlock)onDataReadCallback
                     onRequestFinishCallback:(TTNetworkObjectFinishBlock)onRequestFinishCallback {
    NSDictionary *headers = [self generateRangeHeaderField:offset requestedLength:requestedLength headerField:headerField];
    
    return [self requestForChunkedBinaryWithURL:URL
                                         params:params
                                         method:method
                               needCommonParams:commonParams
                                    headerField:headers
                                enableHttpCache:enableHttpCache
                              requestSerializer:requestSerializer
                             responseSerializer:responseSerializer
                                     autoResume:autoResume
                                 headerCallback:onHeaderReceivedCallback
                                   dataCallback:onDataReadCallback
                                       callback:onRequestFinishCallback];
}

- (TTHttpTask *)requestForRangeMediaResourceWithResponse:(NSString *)URL
                                                  params:(id)params
                                                  method:(NSString *)method
                                                  offset:(NSInteger)offset
                                         requestedLength:(NSInteger)requestedLength
                                        needCommonParams:(BOOL)commonParams
                                             headerField:(NSDictionary *)headerField
                                         enableHttpCache:(BOOL)enableHttpCache
                                       requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                      responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                              autoResume:(BOOL)autoResume
                                onHeaderReceivedCallback:(TTNetworkChunkedDataHeaderBlock)onHeaderReceivedCallback
                                      onDataReadCallback:(TTNetworkChunkedDataReadBlock)onDataReadCallback
                                 onRequestFinishCallback:(TTNetworkObjectFinishBlockWithResponse)onRequestFinishCallback {
    NSDictionary *headers = [self generateRangeHeaderField:offset requestedLength:requestedLength headerField:headerField];
    
    return [self requestForChunkedBinaryWithResponse:URL
                                              params:params
                                              method:method
                                    needCommonParams:commonParams
                                         headerField:headers
                                     enableHttpCache:enableHttpCache
                                   requestSerializer:requestSerializer
                                  responseSerializer:responseSerializer
                                          autoResume:autoResume
                                      headerCallback:onHeaderReceivedCallback
                                        dataCallback:onDataReadCallback
                                callbackWithResponse:onRequestFinishCallback];
}

- (TTHttpTask *)requestForBinaryWithStreamTask:(NSString *)URL
                                        params:(id _Nullable)params
                                        method:(NSString *)method
                              needCommonParams:(BOOL)commonParams
                                   headerField:(nullable NSDictionary *)headerField
                               enableHttpCache:(BOOL)enableHttpCache
                                    autoResume:(BOOL)autoResume
                                dispatch_queue:(dispatch_queue_t)dispatch_queue {
    
    return [self requestForBinaryWithStreamTask:URL
                                         params:params
                      constructingBodyWithBlock:nil
                                         method:method
                               needCommonParams:commonParams
                                    headerField:headerField
                                enableHttpCache:enableHttpCache
                                     autoResume:autoResume
                                 dispatch_queue:dispatch_queue];
}

- (TTHttpTask *)requestForBinaryWithStreamTask:(NSString *)URL
                                        params:(id)params
                     constructingBodyWithBlock:(nullable TTConstructingBodyBlock)bodyBlock
                                        method:(NSString *)method
                              needCommonParams:(BOOL)needCommonParams
                                   headerField:(NSDictionary *)headerField
                               enableHttpCache:(BOOL)enableHttpCache
                                    autoResume:(BOOL)autoResume
                                dispatch_queue:(dispatch_queue_t)dispatch_queue {
    return [self requestForBinaryWithStreamTask:URL
                                         params:params
                      constructingBodyWithBlock:bodyBlock
                                         method:method
                               needCommonParams:needCommonParams
                              requestSerializer:self.defaultRequestSerializerClass
                                    headerField:headerField
                                enableHttpCache:enableHttpCache
                                     autoResume:autoResume
                                 dispatch_queue:dispatch_queue];
}

- (nullable TTHttpTask *)requestForBinaryWithStreamTask:(NSString *)URL
                                                 params:(id _Nullable)params
                              constructingBodyWithBlock:(nullable TTConstructingBodyBlock)bodyBlock
                                                 method:(NSString *)method
                                       needCommonParams:(BOOL)needCommonParams
                                      requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                            headerField:(nullable NSDictionary *)headerField
                                        enableHttpCache:(BOOL)enableHttpCache
                                             autoResume:(BOOL)autoResume
                                         dispatch_queue:(dispatch_queue_t)dispatch_queue {
    NSDate *startBizTime = [NSDate date];
    if (!requestSerializer) {
        requestSerializer = self.defaultRequestSerializerClass;
    }
    
    NSURL *nsurl = [TTNetworkUtil.class isValidURL:URL callback:nil callbackWithResponse:nil];
    if (!nsurl) {
        return nil;
    }
    NSDictionary *commonParams = [self needCommonParams:needCommonParams requestURL:nsurl];
    
    TTHttpRequest *request = nil;
    if (headerField) {
        request = [[requestSerializer serializer] URLRequestWithURL:URL
                                                        headerField:headerField
                                                             params:params
                                                             method:method
                                              constructingBodyBlock:bodyBlock
                                                       commonParams:commonParams];
    } else {
        request = [[requestSerializer serializer] URLRequestWithURL:URL
                                                             params:params
                                                             method:method
                                              constructingBodyBlock:bodyBlock
                                                       commonParams:commonParams];
    }
    
    if (!request) {
        LOGE(@"Can not construct TTHttpRequest!");
        return nil;
    }
    
    request.startBizTime = startBizTime;
    
    if ([self apiHttpInterceptor:request]) {
        LOGD(@"request has been intercepted by the api http interceptor");
        return nil;
    }

    if ([commonParams count] > 0) {
        try {
            [TTHTTPRequestSerializerBase hashRequest:request body:request.HTTPBody];
        } catch (...) {
            
        }
    }
    
    UInt64 taskId = [self nextTaskId];
    __weak typeof(self) wself = self;
    OnHttpTaskCompletedCallbackBlock oneHttpRequestCompletedCallbackBlock = ^(TTHttpResponseChromium *response, id data, NSError *responseError) {
        [wself removeTaskWithId_:taskId];
        if (responseError && responseError.code == NSURLErrorCancelled) {
            LOGD(@"%s request was cancelled %@", __FUNCTION__, request.URL);
        }
        
        if (wself.responseFilterBlock) {
            wself.responseFilterBlock(request, response, data, responseError);
        }
        
        [[TTReqFilterManager shareInstance] runResponseFilter:request response:response data:data responseError:&responseError];
        
        // monitor request end
        [[TTNetworkManagerMonitorNotifier defaultNotifier]
         notifyForMonitorFinishResponse:response
         forRequest:request
         error:responseError
         response:data];
    };
    
    TTHttpTaskChromium *task = [[TTHttpTaskChromium alloc] initWithRequest:(TTHttpRequestChromium *)request
                                                                    engine:gChromeNet.Get().get()
                                                             dispatchQueue:dispatch_queue
                                                                    taskId:taskId
                                                           enableHttpCache:enableHttpCache
                                                         completedCallback:oneHttpRequestCompletedCallbackBlock
                                                    uploadProgressCallback:nil
                                                  downloadProgressCallback:nil];
    task.isStreamingTask = YES;
    
    [self addTaskWithId_:taskId task:task];
    
    if (autoResume) {
        [task resume];
    }
    
    return task;
}

- (void)tryStartNetDetect:(NSArray<NSString *> *)urls
                  timeout:(NSInteger)timeout
                  actions:(NSInteger)actions {
    std::vector<std::string> c_urls;
    for (NSString * url_str in urls) {
        c_urls.push_back(base::SysNSStringToUTF8(url_str));
    }
    LOGD(@"tryStartNetDetect");
    gChromeNet.Get()->TryStartNetDetect(c_urls, (int)timeout, (int)actions);
}

- (TTDnsResult*)ttDnsResolveWithHost:(NSString*)host
                               sdkId:(int)sdkId {
    if (![self ensureEngineStarted]) {
        return [self.ttnetDnsOuterService ttDnsResolveWithHost:host sdkId:sdkId];
    }
    return nil;
}

- (TTDispatchResult*)ttUrlDispatchWithUrl:(NSString*)originalUrl {
    NSURL *urlObj = [NSURL URLWithString:originalUrl];
    if (!urlObj) {
        LOGW(@"Url is invalid: %@", originalUrl);
        return nil;
    }
    
    if (![self ensureEngineStarted]) {
        TTURLDispatch *dispatch = [[TTURLDispatch alloc] initWithUrl:originalUrl requestTag:nil];
        [dispatch doDispatch];
        [dispatch await];
        
        // Return nil if finalUrl is invalid.
        NSURL *url = [NSURL URLWithString: [dispatch result].finalUrl];
        if (!url) {
            return nil;
        }

        return [dispatch result];
    }
    return nil;
}

- (void)preconnectUrl:(NSString*)url {
    NSURL *urlObj = [NSURL URLWithString:url];
    if (!urlObj) {
        LOGW(@"Url is invalid: %@", url);
        return;
    }
    
    const std::string& c_url = base::SysNSStringToUTF8(url);
    if (![self ensureEngineStarted] && gChromeNet.Get()) {
        gChromeNet.Get()->PreconnectUrl(c_url);
    }
}

- (void)triggerGetDomainForTesting {
    [self triggerGetDomain:NO];
}

- (void)triggerGetDomain:(BOOL)useLatestParam {
    if (![self ensureEngineStarted] && gChromeNet.Get()) {
        gChromeNet.Get()->TriggerGetDomain(useLatestParam);
    }
}

- (void)addClientOpaqueDataAfterInit:(TTClientCertificate*) cert {
    if (![self ensureEngineStarted] && gChromeNet.Get()) {
        __block std::vector<std::string> host_list;
        [cert.HostsList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            host_list.push_back(CPPSTR(obj));
        }];
        gChromeNet.Get()->AddClientOpaqueDataAfterInit(host_list,
        std::string((const char*)[cert.Certificate bytes], [cert.Certificate length]),
        std::string((const char*)[cert.PrivateKey bytes], [cert.PrivateKey length]));
    }
}

- (void)clearClientOpaqueData {
    if (![self ensureEngineStarted] && gChromeNet.Get()) {
        gChromeNet.Get()->ClearClientOpaqueData();
    }
}

- (void)removeClientOpaqueData:(NSString*)host {
    if (![self ensureEngineStarted] && gChromeNet.Get()) {
        gChromeNet.Get()->RemoveClientOpaqueData(base::SysNSStringToUTF8(host));
    }
}

- (void)notifySwitchToMultiNetwork:(BOOL)enable {
    if (![self ensureEngineStarted] && gChromeNet.Get()) {
#if !defined(DISABLE_WIFI_TO_CELL)
        gChromeNet.Get()->NotifySwitchToMultiNetwork(enable);
#endif
    }
}

- (void)setZstdFuncAddr:(void*)createDCtxAddr
   decompressStreamAddr:(void*)decompressStreamAddr
           freeDctxAddr:(void*)freeDctxAddr
            isErrorAddr:(void*)isErrorAddr
        createDDictAddr:(void*)createDDictAddr
       dctxRefDDictAddr:(void*)dctxRefDDictAddr
          freeDDictAddr:(void*)freeDDictAddr
          dctxResetAddr:(void*)dctxResetAddr {
    NSAssert(createDCtxAddr != nullptr &&
             decompressStreamAddr != nullptr &&
             freeDctxAddr != nullptr &&
             isErrorAddr != nullptr &&
             createDDictAddr != nullptr &&
             dctxRefDDictAddr != nullptr &&
             freeDDictAddr != nullptr &&
             dctxResetAddr != nullptr, @"zstd func is nil");

    if (![self ensureEngineStarted] && gChromeNet.Get()) {
        gChromeNet.Get()->SetZstdFuncAddr(createDCtxAddr, decompressStreamAddr,
                                          freeDctxAddr, isErrorAddr, createDDictAddr,
                                          dctxRefDDictAddr, freeDDictAddr, dctxResetAddr);
    }
}

- (void)triggerSwitchingToCellular {
    if (![self ensureEngineStarted] && gChromeNet.Get()) {
#if !defined(DISABLE_WIFI_TO_CELL)
        gChromeNet.Get()->TriggerSwitchingToCellular();
#endif
    }
}

- (BOOL)enableTTBizHttpDns:(BOOL)enable
                    domain:(NSString*)domain
                    authId:(NSString*)authId
                   authKey:(NSString*)authKey
                   tempKey:(BOOL)tempKey
          tempKeyTimestamp:(NSString*)tempKeyTimestamp {
    if (![self ensureEngineStarted]) {
        
        gChromeNet.Get()->EnableTTBizHttpDns(enable,
                                             base::SysNSStringToUTF8(domain),
                                             base::SysNSStringToUTF8(authId),
                                             base::SysNSStringToUTF8(authKey),
                                             tempKey,
                                             base::SysNSStringToUTF8(tempKeyTimestamp));
        return YES;
    }
    return NO;
}

- (NSString *)filterUrlWithCommonParams:(NSString *)originalUrl {
    if (!originalUrl) {
        return nil;
    }
    TTHttpRequestChromium *request = [[TTHttpRequestChromium alloc] initWithURL:originalUrl method:nil multipartForm:nil];
    NSString *result = [[QueryFilterEngine shareInstance] filterQuery:request];
    return result;
}

- (NSDictionary *)removeL0CommonParams:(NSDictionary *)originalQueryMap {
    if (!originalQueryMap) {
        return nil;
    }
    if (self.commonParamsL0Level) {
        NSMutableDictionary *mutableQueryMap = [NSMutableDictionary dictionaryWithDictionary:originalQueryMap];
        [mutableQueryMap removeObjectsForKeys:self.commonParamsL0Level];
        
        originalQueryMap = [mutableQueryMap copy];
    }
    return originalQueryMap;
}

- (TTHttpRequest *)syncGetDispatchedURL:(NSURLRequest *)nsRequest
                       needCommonParams:(BOOL)needCommonParams
                      needFilterHeaders:(BOOL)needFilterHeaders {
    BOOL addCommonParams = needCommonParams || nsRequest.needCommonParams;
    TTHttpRequestChromium *request = [self generateTTHttpRequest:nsRequest needCommonParams:addCommonParams];
    
    if (needFilterHeaders) {
        // Request Filter
        if ([TTNetworkManager shareInstance].requestFilterBlock) {
            [TTNetworkManager shareInstance].requestFilterBlock(request);
        }
        
        [[TTReqFilterManager shareInstance] runRequestFilter:request];
    }
    
    //get dispatched url
    TTDispatchResult* result = [[TTNetworkManager shareInstance] ttUrlDispatchWithUrl:request.urlString];
    if (result && result.finalUrl) {
        request.urlString = result.finalUrl;
    }
    
    return request;
}

- (TTHttpRequestChromium *)generateTTHttpRequest:(NSURLRequest *)nsRequest needCommonParams:(BOOL)needCommonParams {
    NSString *nsURLString = nsRequest.URL.absoluteString;
    if (needCommonParams) {
        NSDictionary *commonParams = [self pickCommonParams:nsRequest.URL];
        nsURLString = [TTNetworkUtil webviewURLString:nsURLString appendCommonParams:commonParams];
    }
    TTHttpRequestChromium *request = [[TTHttpRequestChromium alloc] initWithURL:nsURLString method:nsRequest.HTTPMethod multipartForm:nil];
    [request setWebviewInfoProperty:nsRequest.webviewInfo];
    request.HTTPBody = nsRequest.HTTPBody;
    request.allHTTPHeaderFields = nsRequest.allHTTPHeaderFields;
    if (nsRequest.HTTPBodyStream) {
        request.HTTPBody = [self.class dataWithInputStream:nsRequest.HTTPBodyStream];
    }
    return request;
}

@end

//
//  TTNetworkDefine.h
//  Pods
//
//  Created by ZhangLeonardo on 15/9/6.
//
//  TTNetworkDefine contains the error description and the define of callback block.

#import "TTResponseModelProtocol.h"
#import "TTHttpMultipartFormData.h"
@class TTHttpResponse;
@class TTDnsResult;

#ifndef TTNetworkManager_TTNetworkDefine_h
#define TTNetworkManager_TTNetworkDefine_h

//autoreleasepool
#define TTNetAutoReleasePoolBegin @autoreleasepool {
#define TTNetAutoReleasePoolEnd }

//enable concurrent request on all TTNetworkManager's interface
//#define FULL_API_CONCURRENT_REQUEST
//#define OC_DISABLE_STORE_IDC

#pragma mark -- callback block
#pragma mark -- response block

/**
 *  ResponseModel
 *
 *  @param error   -- callback error
 *  @param responseModel -- callback response
 */
typedef void (^TTNetworkResponseModelFinishBlock)(NSError * _Nullable error, NSObject<TTResponseModelProtocol> * _Nullable responseModel);

typedef void (^TTNetworkModelFinishBlockWithResponse)(NSError * _Nullable error, NSObject<TTResponseModelProtocol> * _Nullable responseModel, TTHttpResponse * _Nullable response);

/**
 *  JSON response callback
 *
 *  @param error  -- callback error
 *  @param jsonObj -- callback response
 */
typedef void (^TTNetworkJSONFinishBlock)(NSError * _Nullable error, id _Nullable jsonObj);

typedef void (^TTNetworkJSONFinishBlockWithResponse)(NSError * _Nullable error, id _Nullable obj, TTHttpResponse * _Nullable response);

/**
 *  Binary response callback
 *
 *  @param error -- callback error
 *  @param obj -- callback response
 */
typedef void (^TTNetworkObjectFinishBlock)(NSError * _Nullable error, id _Nullable obj);

typedef void (^TTNetworkObjectFinishBlockWithResponse)(NSError * _Nullable error, id _Nullable obj, TTHttpResponse * _Nullable response);

typedef void (^TTNetworkChunkedDataHeaderBlock)(TTHttpResponse * _Nonnull response);

typedef void (^TTNetworkChunkedDataReadBlock)(NSData* _Nonnull obj);

typedef void (^TTNetworkURLRedirectBlock)(NSString * _Nonnull new_location, TTHttpResponse * _Nonnull old_repsonse);

typedef void (^DownloadCompletionHandler)(TTHttpResponse * _Nullable response, NSURL * _Nullable filePath, NSError * _Nullable error);

typedef void (^ProgressCallbackBlock)(int64_t current, int64_t total);

#pragma mark -- callback block
#pragma mark -- Download progress callback block
/**
 *  progress 0 - 100
 *
 *  @param progress -- download progress
 */
typedef void (^TTNetObjectProgressBlock)(int progress);

#pragma mark -- rqeuest block block

/**
 *
 *  if the request body contains file, this block will be called.
 *
 *  @param formData used to build request body which contains file.
 */
typedef void (^TTConstructingBodyBlock)(id<TTMultipartFormData> _Nonnull formData);

#pragma mark -- error

#define kTTNetworkCustomErrorKey @"kTTNetworkCustomErrorKey"
#define kTTNetworkErrorDomain @"kTTNetworkErrorDomain"
#define kTTNetworkUserinfoTipKey @"kTTNetworkUserinfoTipKey"

#define kTTNetworkErrorTipNoNetwork @"No Network"
#define kTTNetworkErrorTipNetworkError @"Network Error"
#define kTTNetworkErrorTipServerError @"Server Error"
#define kTTNetworkErrorTipParseJSONError @"ParseJSON Error"
#define kTTNetworkErrorTipNetworkHijacked  @"Network Hijacked"


typedef NS_ENUM(NSUInteger, TTNetworkManagerApiType){
    
    TTNetworkManagerApiModel = 0,
    
    TTNetworkManagerApiJSON,
    
    TTNetworkManagerApiBinary,
    
    TTNetworkManagerApiMemoryUpload,
    
    TTNetworkManagerApiFileUpload,
    
    TTNetworkManagerApiDownload,
    
    TTNetworkManagerApiWebview
    
};

/**
 * Error code description.
 */
typedef NS_ENUM(NSInteger, TTNetworkErrorCode){
    // The json data returned by server is not dict format.
    TTNetworkErrorCodeNetworkJsonResultNotDictionary = -99,
    // The request has been dropped when user set drop header (cli_need_drop_request:1)
    TTNetworkErrorCodeDropClientRequest = -98,

    // The self-defined error code starts with -9.

    /**
     *  CDN cache error.
     */
    TTNetworkErrorCodeCdnCache = -9,

    /**
     * when enableApiHttpIntercept is set, |api http| in api_http_host_list has been intercepted and
     * report monitor log.
     */
    TTNetworkErrorCodeApiHttpIntercepted = -8,

    /**
     * State is error in client side (such as not initialization)
     */
    TTNetworkErrorCodeIllegalClientState = -7,
    
    /**
     * invalid request url
     */
    TTNetworkErrorCodeBadURLRequest = -6,
    
    /**
     * network has been hijacked.
     */
    TTNetworkErrorCodeNetworkHijacked = -5,
    /**
     *  json parsed failed.
     */
    TTNetworkErrorCodeParseJSONError = -4,
    /**
     * Sever has some errors.
     */
    TTNetworkErrorCodeServerError = -3,
    /**
     * Connection errors.
     */
    TTNetworkErrorCodeNetworkError = -2,
    /**
     * Network is not available.
     */
    TTNetworkErrorCodeNoNetwork = -1,
    /**
     * No error. Success.
     */
    TTNetworkErrorCodeSuccess = 0,

    // The following error codes start with 1 are same with Android's.
    
    TTNetworkErrorCodeUnknown = 1,
    TTNetworkErrorCodeConnectTimeOut = 2,
    TTNetworkErrorCodeSocketTimeOut = 3,
    TTNetworkErrorCodeIOException = 4,
    TTNetworkErrorCodeSocketException = 5,
    TTNetworkErrorCodeResetByPeer = 6,
    TTNetworkErrorCodeBindException = 7,
    TTNetworkErrorCodeConnectExceptioin = 8,
    TTNetworkErrorCodeNoReouteToHost = 9,
    TTNetworkErrorCodeProtUnreachable = 10,
    TTNetworkErrorCodeUnknonwHost = 11,
    
    //errno
    TTNetworkErrorCodeECONNRESET = 12,
    TTNetworkErrorCodeECONNREFUSED = 13,
    TTNetworkErrorCodeEHOSTUNREACH = 14,
    TTNetworkErrorCodeENETUNREACH = 15,
    TTNetworkErrorCodeEADDRNOTAVAIL = 16,
    TTNetworkErrorCodeEADDRINUSE = 17,
    
    TTNetworkErrorCodeNoHttpResponse = 18,
    TTNetworkErrorCodeClientProtocolException = 19,
    TTNetworkErrorCodeFileTooLarge = 20,
    TTNetworkErrorCodeTooManyRedirect = 21,
    
    TTNetworkErrorCodeUnknowClientError = 31,
    TTNetworkErrorCodeNoSpace = 32,
    
    // errno
    TTNetworkErrorCodeENOENT = 33, //no such file or directory
    TTNetworkErrorCodeEDQUOT = 34, //exceed disk quota
    TTNetworkErrorCodeEROFS = 35,
    TTNetworkErrorCodeEACCES = 36, //permission denyed
    TTNetworkErrorCodeEIO = 37,
    TTNetworkErrorCodeEImproperImage = 38 //improper Image in webview
};

typedef NS_ENUM(NSInteger, TTMultiNetworkState) {
    STATE_STOPPED = -1,
    STATE_NO_NETWORK = 0,
    STATE_DEFAULT_CELLULAR,
    STATE_DEFAULT_WIFI_WITH_CELLULAR_DOWN,
    STATE_DEFAULT_WIFI_WITH_CELLULAR_UP,
    STATE_WAIT_CELLULAR_ALWAYS_UP,
    STATE_WAIT_USER_ENABLE,
    STATE_WIFI_WITH_CELLULAR_TRANS_DATA,
    STATE_EVALUATE_CELLULAR,
    STATE_COUNT
};

#define CPPSTR(str) str == nil ? "" : str.UTF8String

#define kTTNetSubErrorCode @"error_num"

#pragma mark -- TNC TTNet config key
#define kTNCData @"data"
#define kTTNetRequestTimeout @"ttnet_request_timeout"
#define kTTNetReqCountNetworkChanged @"ttnet_request_count_network_changed"
#define kTTNetResponseVerifyEnabled @"ttnet_response_verify_enabled"
#define kTTNetFrontierUrls @"frontier_urls"
#define kTTNetShareCookieHostList @"share_cookie_host_list"
#define kTTNetApiHttpHostList @"api_http_host_list"

//definition of host_group and match pattern group on TNC
#define kTNCHostGroup @"host_group"
#define kTNCEqualGroup @"equal_group"
#define kTNCPrefixGroup @"prefix_group"
#define kTNCPatternGroup @"pattern_group"

//definition of concurrent request TNC config key
/**
concurrent request TNC config example:
{
  "data":{
    "concurrent_request_config":{
      "enabled":1,
      "connect_interval":4,
      "retry_for_not_2xx_code":1,
      "match_rules": [
        {
          "host_group":["*.snssdk.com","*.amemv.com"],
          "equal_group":["/api/ad/preload_ad/v3/", "/api/ad/v1/adlink/", "/api/news/feed/v88/"],
          "pattern_group":["/api/news/feed/"],
          "concurrent_hosts":["lf.snssdk.com", "lf-hl.snssdk.com", "lf-lq.snssdk.com"]

        },
        {
          "host_group":["*.snssdk.com"],
          "prefix_group":["/api/2/article/"],
          "pattern_group":["/\\d+/user/info/", "/\\d+/user/logout/"],
          "concurrent_hosts":["x.snssdk.com", "y.snssdk.com", "is.snssdk.com"],
          "fail_count": 2,
          "forbid_seconds": 30,
          "block_code_list": [-192, -199, 400, 500, -111]
        },
        {
          "host_group":["p?.pstatp.com"],
          "pattern_group":["/list/\\d+/\\d+"],
          "concurrent_hosts":["x.pstatp.com", "x.pstatp.com", "p.pstatp.com", "p1.pstatp.com"]
        }
      ]
    }
  },
  "message":"success"
}
*/
#define kTTNetworkConcurrentRequestConfig @"concurrent_request_config"
#define kTTNetworkConcurrentRequestEnabled @"enabled_v2"
//#define kTTNetworkConcurrentRequestEnabled @"enabled" ///old config
#define kTTNetworkConcurrentRequestConnectInterval @"connect_interval"
#define kTTNetworkConcurrentRequestRetryForNot2xxCode @"retry_for_not_2xx_code"
#define kTTNetworkConcurrentRequestMatchRules @"match_rules"
#define kTTNetworkConcurrentRequestConcurrentHosts @"concurrent_hosts"
#define kTTNetworkConcurrentRequestMaxFailCount @"fail_count"
#define kTTNetworkConcurrentRequestForbidSeconds @"forbid_seconds"
#define kTTNetworkConcurrentRequestBlockCodeList @"block_code_list"
#define kTTNetworkConcurrentRequestIsRetry @"is_retry"
#define kTTNetworkConcurrentRequestNoRetry @"no_retry"
#define kTTNetworkConcurrentRequestTasksStart @"start"
#define kTTNetworkConcurrentRequestTasksEnd @"end"
#define kTTNetworkConcurrentRequestTasksHost @"host"
#define kTTNetworkConcurrentRequestTasksDispatchHost @"dpHost"
#define kTTNetworkConcurrentRequestTasksDispatchTime @"dispatch"
#define kTTNetworkConcurrentRequestTasksAlreadySent @"sentAlready"
#define kTTNetworkConcurrentRequestTasksHttpCode @"httpCode"
#define kTTNetworkConcurrentRequestTasksNetError @"netError"

#define kRequestHeadersTransactionId @"transaction-id"
#define kRequestHeadersSequenceNumber @"sequence_number"
#define kRequestHeadersBypassRouteSelection @"x-tt-bp-rs"
#define kResponseHeaderApiSource5xx @"tt-api-source-5xx"

#define kTTNetworkSubRequestConnectInterval @"connect_interval_millis"
#define kTTNetworkSubRequestBypassRouteSelection @"bypass_rs_enabled"
#define kTTNetworkConcurrentRequestRsName @"rs_name"    // enable refine with route selection if not nil

//definition of new common parameter strategy v2's TNC config key
/**
 new common parameter strategy v2's TNC config example:
 {
   "data": {
     "add_common_params": {
       "host_group": [
         "*.snssdk.com",
         "*.amemv.com"
       ],
       "min_params_exclude": [
         "os",
         "abis"
       ],
       "L0_path": {
         "equal_group": [
           "/api/news/feed/",
           "/2/user/info/",
           "/account/info/",
           "/aweme/v2/feed/"
         ],
         "prefix_group": [
           "/api/2/",
           "/passport/"
         ],
         "pattern_group": [
           "/\\d+/user/info/",
           "/\\d+/user/logout/"
         ]
       },
       "L1_path": {
         "equal_group": [
           "/search/content/"
         ],
         "prefix_group": [
           "/search/api/",
           "/webcast/"
         ],
         "pattern_group": [
           "/search/?/info/",
           "/search/\\d+/feed/"
         ]
       }
     }
   },
   "message":"success"
 }*/
#define kTNCAddCommonParams @"add_common_params"
#define kTNCMinParamsExclude @"min_params_exclude"
#define kTNCL0Path @"L0_path"
#define kTNCL1Path @"L1_path"


//definition of verification code callback
#define kTTNetBDTuringVerify @"bdturing-verify"
#define kTTNetBDTuringRetry @"x-tt-bdturing-retry"
#define kTTNetBDTuringRetryApiAllKeyName @"bdturing-retry"
#define kTTNetBDTuringCallbackApiAllKeyName @"turing_callback"
#define kTTNetBDTuringBypass @"x-tt-bypass-bdturing"


//definition of query filter engine config key
#define kTNCQueryFilterEnabled @"query_filter_enabled"
#define kTNCQueryFilterActions @"query_filter_actions"
#define kTNCAction @"action"
#define kTNCActionPriority @"act_priority"
#define kTNCSetReqPriority @"set_req_priority"
#define kTNCParam @"param"
#define kTNCRemoveList @"remove_list"
#define kTNCKeepList @"keep_list"
#define kTNCAddList @"add_list"
#define kTNCEncryptQueryList @"encrypt_query_list"
#define kTNCEncryptBodyEnabled @"encrypt_body_enabled"
#define kTNCActionAdd @"add"
#define kTNCActionRemove @"rm"
#define kTNCActionEncrypt @"encrypt"
#define kTTNetQueryFilterReservedKey @"xxrandomxx_query_filter_reseverd_key"
#define kTNCL0Params @"L0_params"
#define kTTNetQueryFilterTimingInfoKey @"query_filter_time"

//webview image check TNC config
#define kTNCWebviewImageCheck @"enable_webview_image_check"
#define kTNCImageCheckDomainList @"image_must_check_domian_list"
#define kTNCImageCheckBypassDomainList @"image_bypass_check_domain_list"

//#define DISABLE_WIFI_TO_CELL

#endif

//
//  Created by 宋璐 on 2017/5/11.
//  Copyright © 2017年 宋璐. All rights reserved.
//

#ifndef NET_TTNET_ROUTE_SELECTION_TT_DEFAULT_SERVER_CONFIG_H_
#define NET_TTNET_ROUTE_SELECTION_TT_DEFAULT_SERVER_CONFIG_H_

/* for server config module*/
// add by debug
#define ROUTE_SELECTION_SERVER_CONFIG_MAXFAILTIMES 2  //选路重试次数，默认2次
#define ROUTE_SELECTION_SERVER_CONFIG_INTERVAL 1800  //选路间隔，1800s
#define ROUTE_SELECTION_SERVER_CONFIG_HTTPSTIMEOUT \
  60  // HTTPS失败重试时间间隔，60s
#define ROUTE_SELECTION_SERVER_CONFIG_ISENABLED 0  //是否使能选路，默认关闭

#define SERVER_CONFIG_FILE_NAME "server_config.json"
#define SERVER_CONFIG_FILE_MAX_SIZE 10000

/* for common tools module */
#define COMMON_TOOLS_RESPONSE_ERROR_INFO "error"
#define COMMON_TOOLS_MAX_WAIT_TIME_URLREQUEST 15  //发url请求时最长等待时间

/* for set headers module*/
#define REQUEST_HEADERS_TRACE_ID "x-tt-trace-id"
#define REQUEST_HEADERS_TRACE_LOG "x-tt-trace-log"
#define REQUEST_HEADERS_CLIENT_IP "x-client-ip-v4"
#define REQUEST_HEADERS_BYPASS_ROUTE_SELECTION "x-tt-bp-rs"
#define REQUEST_HEADERS_TLB_COMPRESS "x-tlb-decode-req-body-err"
#define REQUEST_HEADERS_TOKEN "x-tt-token"
#define REQUEST_HEADERS_TRANSACTION_ID "transaction-id"
#define REQUEST_HEADERS_BYPASS_BOE "bypass-boe"
#define REQUEST_HEADERS_MSSDK_PREFIX "x-metasec-"
#define REQUEST_HEADERS_TAG "x-tt-request-tag"

// for header set by MDL
#define REQUEST_HEADERS_MDL_TRACE_ID "x-tt-traceid"

#define RESPONSE_HEADERS_IDC_SWITCH "tt-idc-switch"
#define RESPONSE_HEADERS_SERVER_TIMING "server-timing"

#define REQUEST_HEADERS_COMMON_PARAMS "x-common-params-v2"
#define REQUEST_HEADERS_FORCE_HPACK_OPTIMIZATION "force_tt_hpack_optimization"

#define REQUEST_HEADERS_SCENE_TYPE "x-ttnet-scene-type"
#define REQUEST_HEADERS_INIT_REGION "x-tt-app-init-region"

#define RESPONSE_HEADERS_SERVER_STABLE "tt_stable"

// for control headers
#define REQUEST_HEADERS_BYPASS_TTNET_FEATURES "x-metasec-bypass-ttnet-features"
#define REQUEST_HEADERS_BYPASS_MSSDK "x-metasec-bypass-mssdk"

#endif

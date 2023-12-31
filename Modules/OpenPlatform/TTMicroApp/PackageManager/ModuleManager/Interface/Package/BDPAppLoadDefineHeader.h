//
//  BDPAppLoadDefineHeader.h
//  Timor
//
//  Created by 傅翔 on 2019/1/23.
//

#ifndef BDPAppLoadDefineHeader_h
#define BDPAppLoadDefineHeader_h

#import <ECOInfra/BDPLog.h>
#import <ECOInfra/OPError.h>

#define BDP_PKG_LOAD_TAG @"PKG_LOAD"
#define BDP_PKG_LOAD_LOG(...) BDPLogTagInfo(BDP_PKG_LOAD_TAG, ##__VA_ARGS__)

@class OPMonitorCode;

// http响应状态码
#define BDP_APP_HTTP_STATUS_KEY @"BDP_APP_HTTP_STATUS_KEY"
// server返回错误
#define BDP_APP_SERVER_ERROR_KEY @"BDP_APP_SERVER_ERROR_KEY"

// App加载类型, 1meta, 2pkg包
#define BDP_APP_LOAD_TYPE_KEY @"BDP_APP_LOAD_TYPE_KEY"
#define BDP_APP_LOAD_TYPE_META @"META"
#define BDP_APP_LOAD_TYPE_PKG @"PKG"
#define BDP_APP_LOAD_TYPE_UNKNOWN @"UNKNOWN"

#define BDP_APP_LOAD_ERROR_TYPE_N(monitorCode, message, type, status) OPErrorNew(monitorCode, nil, (@{ NSLocalizedDescriptionKey: (message ?: @"unknown"), BDP_APP_LOAD_TYPE_KEY: (type ?: @(0)), BDP_APP_HTTP_STATUS_KEY: (status ?: @(200)) }))

// 服务器返回错误
#define BDP_APP_LOAD_ERROR_SERVER_N(monitorCode, reason, type, serr, status) OPErrorNew(monitorCode, nil, (@{ NSLocalizedDescriptionKey: (reason ?: @"unknown"), BDP_APP_LOAD_TYPE_KEY: (type ?: @"0"), BDP_APP_SERVER_ERROR_KEY: (serr ?: @"0"), BDP_APP_HTTP_STATUS_KEY: (status ?: @(200))}))

#endif /* BDPAppLoadDefineHeader_h */

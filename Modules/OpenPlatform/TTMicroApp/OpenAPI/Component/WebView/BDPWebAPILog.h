//
//  BDPWebAPILog.h
//  TTMicroApp
//
//  Created by ByteDance on 2022/10/13.
//

#import <Foundation/Foundation.h>
#import <ECOInfra/BDPLog.h>

#ifndef BDPWebAPILog_h
#define BDPWebAPILog_h

#define BDPMicroAppTagWebAPI BDPTag.webviewAPI

/* 提供宏定义的参数类型代码提示 */
void BDPWebAPILogDebug(NSString * _Nullable _format, ...);
void BDPWebAPILogInfo(NSString * _Nullable _format, ...);
void BDPWebAPILogWarn(NSString * _Nullable _format, ...);
void BDPWebAPILogError(NSString * _Nullable _format, ...);

#define BDPWebAPILogDebug(_format, ...)  if (BDPDebugLogEnable) { BDPLog(BDPLogLevelDebug, BDPMicroAppTagWebAPI, nil, _format, ##__VA_ARGS__) }
#define BDPWebAPILogInfo(_format, ...)   BDPLog(BDPLogLevelInfo, BDPMicroAppTagWebAPI, nil, _format, ##__VA_ARGS__)
#define BDPWebAPILogWarn(_format, ...)   BDPLog(BDPLogLevelWarn, BDPMicroAppTagWebAPI, nil, _format, ##__VA_ARGS__)
#define BDPWebAPILogError(_format, ...)  BDPLog(BDPLogLevelError, BDPMicroAppTagWebAPI, nil, _format, ##__VA_ARGS__)

#endif /* BDPWebAPILog_h */

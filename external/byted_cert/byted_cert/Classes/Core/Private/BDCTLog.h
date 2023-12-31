//
//  BDCTLog.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/5.
//

#import <BDAlogProtocol/BDAlogProtocol.h>

#define BDCTLog(level, frmt, ...) BDALOG_PROTOCOL_TAG((kBDLogLevel)level, @"byted_cert", frmt, ##__VA_ARGS__);

#define BDCTLogError(frmt, ...) BDCTLog(kLogLevelError, frmt, ##__VA_ARGS__)
#define BDCTLogWarn(frmt, ...) BDCTLog(kLogLevelWarn, frmt, ##__VA_ARGS__)
#define BDCTLogInfo(frmt, ...) BDCTLog(kLogLevelInfo, frmt, ##__VA_ARGS__)
#define BDCTLogDebug(frmt, ...) BDCTLog(kLogLevelDebug, frmt, ##__VA_ARGS__)

//
//  CJPayLoggerDefine.h
//  Pods
//
//  Created by 王新华 on 2022/7/25.
//

#ifndef CJPayLoggerDefine_h
#define CJPayLoggerDefine_h

#import <BDAlogProtocol/BDAlogProtocol.h>

#define CJPayLogInfo(format, ...)  BDALOG_PROTOCOL_INFO_TAG(@"CJPay", format, ##__VA_ARGS__)
#define CJPayLogWarn(format, ...)  BDALOG_PROTOCOL_WARN_TAG(@"CJPay", format, ##__VA_ARGS__)
#define CJPayLogError(format, ...)  BDALOG_PROTOCOL_ERROR_TAG(@"CJPay", format, ##__VA_ARGS__)
#define CJPayLogDebug(format, ...)  BDALOG_PROTOCOL_DEBUG_TAG(@"CJPay", format, ##__VA_ARGS__)
#define CJPayLogFatal(format, ...)  BDALOG_PROTOCOL_FATAL_TAG(@"CJPay", format, ##__VA_ARGS__)

#define CJPayLogAssert(condition, format, ...) \
do {                \
    if (!condition) BDALOG_PROTOCOL_FATAL_TAG(@"CJPay", format, ##__VA_ARGS__) \
    NSAssert(condition, format, ##__VA_ARGS__); \
} while(0);

#endif /* CJPayLoggerDefine_h */

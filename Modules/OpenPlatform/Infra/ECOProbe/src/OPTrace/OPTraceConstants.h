//
//  OPTraceConstants.h
//  ECOProbe
//
//  Created by qsc on 2021/3/31.
//

#import <Foundation/Foundation.h>
/// 序列化时，traceSpan 的 key
FOUNDATION_EXPORT NSString *const kTraceSerializeKeyTrace;
/// 序列化时，traceId 的 key
FOUNDATION_EXPORT NSString *const kTraceSerializeKeyTraceId;
/// 序列化时，trace.createTime 的 key
FOUNDATION_EXPORT NSString *const kTraceSerializeKeyCreateTime;
/// 序列化时，trace.monitorCache 的 key
FOUNDATION_EXPORT NSString *const kTraceSerializeKeyMonitorData;
/// 序列化时，trace.batchEnabled 的 key
FOUNDATION_EXPORT NSString *const kTraceSerializeKeyBatchEnabled;
/// Trace 批量上报时，使用的特定 event_name
FOUNDATION_EXPORT NSString *const kTraceReportKeyEventName;

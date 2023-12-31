//
//  OPMonitor+Serialize.h
//  ECOProbe
//
//  Created by qsc on 2021/3/31.
//

#import <Foundation/Foundation.h>
#import "OPMonitor.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * OPMonitor 序列化提供，将 monitor 转换为 JSON 字符串:
 * "{\"name\":\"monitor_batch_test\",\"metrics\":{\"time\":1617187600765,\"cpu_time\":63783351},\"categories\":{\"wor\":\"ld\",\"trace_id\":\"1-455e9044-fa0761ba\",\"monitor_tags\":\"hello\"}}"
 *
 * {
 *   "name": "monitor_batch_test",
 *   "categories": {
          "key": "value"
 *   },
 *   "metrics":{
          "key": "value"
 *   }
 *
 * }
 */
@interface OPMonitorEvent(Serialize)

/// monitor 序列化为 JSON 字符串
- (NSString * _Nullable)serialize;

@end

NS_ASSUME_NONNULL_END

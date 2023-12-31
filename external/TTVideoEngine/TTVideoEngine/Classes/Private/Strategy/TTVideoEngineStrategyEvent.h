//
//  TTVideoEngineStrategyEvent.h
//  TTVideoEngine
//
//  Created by 黄清 on 2021/10/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEngineStrategyEvent : NSObject

///
/// get log info by videoId
///
- (NSDictionary *)getLogDataAndPopCache:(NSString *)videoId;

- (NSDictionary *)getLogData:(NSString *)videoId;

- (NSDictionary *)getLogDataByTraceId:(NSString *)traceId;

- (nullable NSDictionary *)getLogData:(NSString *)videoId forKey:(NSString *)key;

- (void)removeLogData:(NSString *)videoId;

- (void)removeLogDataByTraceId:(NSString *)traceId;

- (void)event:(NSString *)videoId
        event:(NSInteger)key
        value:(NSInteger)value
         info:(nullable NSString *)logInfo;

@end

NS_ASSUME_NONNULL_END

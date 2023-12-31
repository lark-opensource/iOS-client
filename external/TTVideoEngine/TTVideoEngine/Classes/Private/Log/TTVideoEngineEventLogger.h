//
//  TTVideoEngineEventLogger.h
//  Pods
//
//  Created by guikunzhi on 16/12/26.
//
//

#import "TTVideoEngineEventLoggerProtocol.h"

@interface TTVideoEngineEventLogger : NSObject<TTVideoEnginePerformancePoint, TTVideoEngineEventLoggerProtocol>

+ (void)setIntValueWithKey:(NSInteger)key value:(NSInteger)value;
+ (void)setFloatValueWith:(NSInteger)key value:(float)value;
+ (void)addFeatureGlobal:(NSString *)key value:(id)value;

@end

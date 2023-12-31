//
//  TTVideoEngineEventNetworkPredictorSample.h
//  TTVideoEngine
//
//  Created by shen chen on 2021/7/9.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineEventNetworkSpeedPredictorSampleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class TTVideoEngineEventBase;
@interface TTVideoEngineEventNetworkPredictorSample : NSObject <TTVideoEngineEventNetworkSpeedPredictorSampleProtocol>

@property (nonatomic, weak) id<TTVideoEngineEventLoggerDelegate> delegate;

+ (void)setIntValueWithKey:(NSInteger)key value:(NSInteger)value;
+ (void)setFloatValueWith:(NSInteger)key value:(float)value;

- (instancetype)initWithEventBase:(TTVideoEngineEventBase *)eventBase;

@end

NS_ASSUME_NONNULL_END

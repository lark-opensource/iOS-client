//
//  TTVideoEngineEventNetworkSpeedPredictorSampleProtocol.h
//  TTVideoEngine
//
//  Created by shen chen on 2021/7/9.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineEventLoggerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TTVideoEngineEventNetworkSpeedPredictorSampleProtocol <NSObject>

@required
@property (nonatomic, weak) id<TTVideoEngineEventLoggerDelegate> delegate;

- (void)startRecord;

- (void)stopRecord;

- (void)updateSingleNetworkSpeed:(NSDictionary *)videoInfo audioInfo:(NSDictionary *)audioInfo realInterval:(int)realInterval;

@end

NS_ASSUME_NONNULL_END

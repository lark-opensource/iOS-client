//
//  TTVideoEngineNetworkPredictorReaction.h
//  TTVideoEngine
//
//  Created by shen chen on 2021/7/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TTVideoEngineNetworkPredictorReaction <NSObject>

//预测到的速度发生了改变
- (void)predictorSpeedNetworkChanged:(float)speed timestamp:(int64_t)timestamp;

- (void)updateSingleNetworkSpeed:(NSDictionary *)videoDownDic audioInfo:(NSDictionary *)audioDownDic realInterval:(int)timeInterval;

- (NSInteger)getCurrentVideoBufLength;

- (NSInteger)getCurrentAudioBufLength;

- (NSInteger)getPlayerVideoMaxCacheBufferLength;

- (NSInteger)getPlayerAudioMaxCacheBufferLength;

@end

NS_ASSUME_NONNULL_END

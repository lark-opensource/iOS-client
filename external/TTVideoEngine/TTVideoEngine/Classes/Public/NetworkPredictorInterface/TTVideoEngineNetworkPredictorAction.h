//
//  TTVideoEngineNetworkPredictorAction.h
//  TTVideoEngine
//
//  Created by shen chen on 2021/7/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NetworkPredictAverageSpeedType) {
    NetworkPredictAverageWindowDownloadSpeed = 0,
    NetworkPredictAverageDownloadSpeed = 1,
    NetworkPredictAverageEMADownloadSpeed = 2,
    NetworkPredictAverageEMAStartupDownloadSpeed = 3,
    NetworkPredictAverageEMAStartupEndDownloadSpeed = 4,
};

@protocol TTVideoEngineNetworkPredictorAction <NSObject>

+ (CGFloat)getPredictSpeed;
+ (CGFloat)getAveragePredictSpeed;
+ (CGFloat)getAverageDownLoadSpeed;
+ (CGFloat)getAverageDownLoadSpeedFromSpeedAlgo:(int)mediaType speedType:(NetworkPredictAverageSpeedType)speedType trigger:(bool)trigger;
+ (CGFloat)getSpeedConfidence;
+ (CGFloat)getDownLoadSpeed;
- (void)setSinglePredictSpeedTimeIntervalWithHeader:(NSMutableDictionary *)headerDic;

@end

NS_ASSUME_NONNULL_END

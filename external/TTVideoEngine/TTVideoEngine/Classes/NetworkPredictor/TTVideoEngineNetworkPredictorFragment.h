//
//  TTVideoEngineNetworkPredictorFragment.h
//  TTVideoEngine
//
//  Created by shen chen on 2021/7/7.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineFragment.h"
#import "TTVideoEngineNetworkPredictorAction.h"
#import "TTVideoEngineNetworkSpeedPredictorConfigModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEngineNetworkPredictorFragment : NSObject <TTVideoEngineFragment, TTVideoEngineNetworkPredictorAction>

+ (void)startSpeedPredictor:(NetworkPredictAlgoType)type configModel:(TTVideoEngineNetworkSpeedPredictorConfigModel *)configModel;

+ (CGFloat)getPredictSpeed;
+ (CGFloat)getAveragePredictSpeed;
+ (CGFloat)getAverageDownLoadSpeed;
+ (CGFloat)getDownLoadSpeed;
+ (CGFloat)getSpeedConfidence;
- (void)setSinglePredictSpeedTimeIntervalWithHeader:(NSMutableDictionary *)headerDic;

@end

NS_ASSUME_NONNULL_END

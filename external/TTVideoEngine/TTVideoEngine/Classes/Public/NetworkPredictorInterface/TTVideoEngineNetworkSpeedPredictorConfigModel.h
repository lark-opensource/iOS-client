//
//  TTVideoEngineNetworkSpeedPredictorConfigModel.h
//  TTVideoEngine
//
//  Created by shen chen on 2021/7/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NETWORK_SPEED_PREDICT_OUTPUT_TYPE) {
    NETWORK_SPEED_PREDICT_OUTPUT_SINGLE_DATA = 0,
    NETWORK_SPEED_PREDICT_OUTPUT_MULTI_DATA = 1,
};

@interface TTVideoEngineNetworkSpeedPredictorConfigModel : NSObject

@property (nonatomic, assign) NSInteger singleSpeedInterval; //单维度测速间隔
@property (nonatomic, assign) NSInteger mutilSpeedInterval;
@property (nonatomic, assign) NSInteger speedOutputType;

@property(nonatomic, assign) BOOL enableReport;
@property(nonatomic, assign) NSInteger maxWindowSize;
@property(nonatomic, assign) NSInteger samplingRate;

@end

NS_ASSUME_NONNULL_END

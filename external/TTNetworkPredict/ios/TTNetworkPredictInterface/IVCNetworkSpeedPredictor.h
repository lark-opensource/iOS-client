//
//  IVCNetSpeedPredictor.h
//  Networkmodule
//
//  Created by guikunzhi on 2020/3/30.
//  Copyright © 2020 gkz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVCNetworkSpeedRecord.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NetworkPredictAlgoType) {
    NetworkPredictAlgoTypeHECNET = 0,
    NetworkPredictAlgoTypeHANET = 1,
    NetworkPredictAlgoTypeANET = 2,
    NetworkPredictAlgoTypeLSTMNET = 3,
    NetworkPredictAlgoTypeKFNET = 4,
    NetworkPredictAlgoTypeACNet = 7,
};

@protocol IVCNetworkSpeedPredictor <NSObject>

- (float)getPredictSpeed:(int)mediaType;
- (NSDictionary<NSString *, NSString *> *)getDownloadSpeed:(int)mediaType;
- (float)getLastPredictConfidence;
- (void)update:(NSObject<IVCNetworkSpeedRecord> *)speedRecord streamInfo:(NSDictionary *)streamInfoDic;
- (float)getAverageDownLoadSpeed:(int)media_type speedType:(int)speed_type trigger:(bool)trigger;

@end

NS_ASSUME_NONNULL_END

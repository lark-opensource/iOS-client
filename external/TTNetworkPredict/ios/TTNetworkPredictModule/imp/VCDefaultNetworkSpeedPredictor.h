//
//  VCNetSpeedPredictor.h
//  abrmodule
//
//  Created by guikunzhi on 2020/3/30.
//  Copyright © 2020 gkz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVCNetworkSpeedPredictor.h"

NS_ASSUME_NONNULL_BEGIN

@interface VCDefaultNetworkSpeedPredictor : NSObject<IVCNetworkSpeedPredictor>

- (instancetype)initWithAlgoType:(NetworkPredictAlgoType)algoType;

@end

NS_ASSUME_NONNULL_END

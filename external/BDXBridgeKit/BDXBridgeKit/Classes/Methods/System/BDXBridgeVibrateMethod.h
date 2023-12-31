//
//  BDXBridgeVibrateMethod.h
//  BDXBridgeKit
//
//  Created by yihan on 2021/2/28.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeVibrateMethod : BDXBridgeMethod

@end

@interface BDXBridgeVibrateMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSNumber *duration;
@property (nonatomic, assign) BDXBridgeVibrationStyle style; 

@end

NS_ASSUME_NONNULL_END

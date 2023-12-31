//
//  BDXBridgeConfigureStatusBarMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/15.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeConfigureStatusBarMethod : BDXBridgeMethod

@end

@interface BDXBridgeConfigureStatusBarMethodParamModel : BDXBridgeModel

@property (nonatomic, assign) BDXBridgeStatusStyle style;
@property (nonatomic, assign) BOOL visible;
@property (nonatomic, strong) UIColor *backgroundColor;

@end

NS_ASSUME_NONNULL_END

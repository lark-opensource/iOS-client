//
//  BDPModel+PackageManager.h
//  TTMicroApp
//
//  Created by justin on 2022/12/22.
//

#import <OPFoundation/BDPModel.h>

NS_ASSUME_NONNULL_BEGIN

@class GadgetMeta;

@interface BDPModel (PackageManager)

/// 从GadgetMeta转换为BDPModel
/// @param gadgetMeta 小程序 H5小程序统一的Meta
- (instancetype)initWithGadgetMeta:(GadgetMeta *)gadgetMeta;

/// 转换为GadgetMeta
- (GadgetMeta *)toGadgetMeta;

@end

NS_ASSUME_NONNULL_END

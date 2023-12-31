//
//  BDXBridgeGetAPIParamsMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/10.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeGetAPIParamsMethod : BDXBridgeMethod

@end

@interface BDXBridgeGetAPIParamsMethodResultModel : BDXBridgeModel

@property (nonatomic, copy) NSDictionary *apiParams;

@end

NS_ASSUME_NONNULL_END

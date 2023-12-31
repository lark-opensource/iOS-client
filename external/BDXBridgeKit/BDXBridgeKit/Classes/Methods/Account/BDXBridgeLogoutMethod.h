//
//  BDXBridgeLogoutMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/24.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeLogoutMethod : BDXBridgeMethod

@end

@interface BDXBridgeLogoutMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSDictionary *context;

@end

@interface BDXBridgeLogoutMethodResultModel : BDXBridgeModel

@property (nonatomic, assign) BDXBridgeLogoutStatus status;

@end

NS_ASSUME_NONNULL_END

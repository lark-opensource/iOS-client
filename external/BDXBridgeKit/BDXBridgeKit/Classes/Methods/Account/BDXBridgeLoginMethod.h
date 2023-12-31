//
//  BDXBridgeLoginMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/24.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeLoginMethod : BDXBridgeMethod

@end

@interface BDXBridgeLoginMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSDictionary *context;

@end

@interface BDXBridgeLoginMethodResultModel : BDXBridgeModel

@property (nonatomic, assign) BDXBridgeLoginStatus status;

@end

NS_ASSUME_NONNULL_END

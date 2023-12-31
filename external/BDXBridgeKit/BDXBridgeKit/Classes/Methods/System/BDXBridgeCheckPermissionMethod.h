//
//  BDXBridgeCheckPermissionMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeCheckPermissionMethod : BDXBridgeMethod

@end

@interface BDXBridgeCheckPermissionMethodParamModel : BDXBridgeModel

@property (nonatomic, assign) BDXBridgePermissionType permission;

@end

@interface BDXBridgeCheckPermissionMethodResultModel : BDXBridgeModel

@property (nonatomic, assign) BDXBridgePermissionStatus status;

@end

NS_ASSUME_NONNULL_END

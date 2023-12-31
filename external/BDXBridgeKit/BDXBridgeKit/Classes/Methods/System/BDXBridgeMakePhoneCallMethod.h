//
//  BDXBridgeMakePhoneCallMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeMakePhoneCallMethod : BDXBridgeMethod

@end

@interface BDXBridgeMakePhoneCallMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *phoneNumber;

@end

NS_ASSUME_NONNULL_END

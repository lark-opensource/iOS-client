//
//  BDXBridgeSendSMSMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeSendSMSMethod : BDXBridgeMethod

@end

@interface BDXBridgeSendSMSMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *content;

@end

NS_ASSUME_NONNULL_END

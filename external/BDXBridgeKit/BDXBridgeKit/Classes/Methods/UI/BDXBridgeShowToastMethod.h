//
//  BDXBridgeShowToastMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeShowToastMethod : BDXBridgeMethod

@end

@interface BDXBridgeShowToastMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *message;
@property (nonatomic, assign) BDXBridgeToastType type;
@property (nonatomic, strong) NSNumber *duration;

@end

NS_ASSUME_NONNULL_END

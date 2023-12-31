//
//  BDXBridgeCanIUseMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/10.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeCanIUseMethod : BDXBridgeMethod

@end

@interface BDXBridgeCanIUseMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *method;

@end

@interface BDXBridgeCanIUseMethodResultModel : BDXBridgeModel

@property (nonatomic, assign) BOOL isAvailable;
@property (nonatomic, copy) NSArray *params;
@property (nonatomic, copy) NSArray *results;

@end

NS_ASSUME_NONNULL_END

//
//  BDXBridgeGetMethodListMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/14.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeGetMethodListMethod : BDXBridgeMethod

@end

@interface BDXBridgeGetMethodListMethodResultModel : BDXBridgeModel

@property (nonatomic, copy) NSDictionary *methodList;

@end

NS_ASSUME_NONNULL_END

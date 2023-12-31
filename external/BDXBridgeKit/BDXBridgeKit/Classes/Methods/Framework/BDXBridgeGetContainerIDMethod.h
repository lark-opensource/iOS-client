//
//  BDXBridgeGetContainerIDMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/13.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeGetContainerIDMethod : BDXBridgeMethod

@end

@interface BDXBridgeGetContainerIDMethodResultModel : BDXBridgeModel

@property (nonatomic, copy) NSString *containerID;

@end

NS_ASSUME_NONNULL_END

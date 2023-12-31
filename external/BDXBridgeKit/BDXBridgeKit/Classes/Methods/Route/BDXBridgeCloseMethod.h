//
//  BDXBridgeCloseMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/13.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeCloseMethod : BDXBridgeMethod

@end

@interface BDXBridgeCloseMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *containerID;
@property (nonatomic, assign) BOOL animated;

@end

NS_ASSUME_NONNULL_END

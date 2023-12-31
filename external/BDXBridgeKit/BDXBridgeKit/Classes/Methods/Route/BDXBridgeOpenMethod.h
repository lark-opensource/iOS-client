//
//  BDXBridgeOpenMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/13.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeOpenMethod : BDXBridgeMethod

@end

@interface BDXBridgeOpenMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *schema;
@property (nonatomic, assign) BOOL replace;
@property (nonatomic, assign) BOOL useSysBrowser;

@end

NS_ASSUME_NONNULL_END

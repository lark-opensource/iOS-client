//
//  BDXBridgeScanCodeMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeScanCodeMethod : BDXBridgeMethod

@end

@interface BDXBridgeScanCodeMethodParamModel : BDXBridgeModel

@property (nonatomic, assign) BOOL cameraOnly;
@property (nonatomic, assign) BOOL closeCurrent;

@end

@interface BDXBridgeScanCodeMethodResultModel : BDXBridgeModel

@property (nonatomic, copy) NSString *result;

@end

NS_ASSUME_NONNULL_END

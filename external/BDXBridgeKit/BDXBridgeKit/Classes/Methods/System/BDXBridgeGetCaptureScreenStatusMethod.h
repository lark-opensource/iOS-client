//
//  BDXBridgeGetCaptureScreenStatusMethod.h
//  BDXBridgeKit
//
//  Created by yihan on 2021/5/7.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeGetCaptureScreenStatusMethod : BDXBridgeMethod

@end

@interface BDXBridgeGetCaptureScreenStatusMethodResultModel : BDXBridgeModel

@property (nonatomic, assign) BOOL capturing;

@end

NS_ASSUME_NONNULL_END

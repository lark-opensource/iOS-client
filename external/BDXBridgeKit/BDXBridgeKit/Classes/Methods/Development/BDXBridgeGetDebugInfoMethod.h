//
//  BDXBridgeGetDebugInfoMethod.h
//  BDXBridgeKit
//
//  Created by QianGuoQiang on 2021/5/8.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeGetDebugInfoMethod : BDXBridgeMethod

@end

@interface BDXBridgeGetDebugInfoMethodResultModel : BDXBridgeModel

@property (nonatomic, strong) NSNumber *useBOE;

@property (nonatomic, copy) NSString *boeChannel;

@property (nonatomic, strong) NSNumber *usePPE;

@property (nonatomic, copy) NSString *ppeChannel;

@end

NS_ASSUME_NONNULL_END

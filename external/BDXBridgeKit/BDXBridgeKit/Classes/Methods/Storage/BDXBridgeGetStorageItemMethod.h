//
//  BDXBridgeGetStorageItemMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/20.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeGetStorageItemMethod : BDXBridgeMethod

@end

@interface BDXBridgeGetStorageItemMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *key;

@end

@interface BDXBridgeGetStorageItemMethodResultModel : BDXBridgeModel

@property (nonatomic, strong) id data;

@end

NS_ASSUME_NONNULL_END

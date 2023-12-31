//
//  BDXBridgeSetStorageItemMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/20.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeSetStorageItemMethod : BDXBridgeMethod

@end

@interface BDXBridgeSetStorageItemMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *key;
@property (nonatomic, strong) id data;

@end

NS_ASSUME_NONNULL_END

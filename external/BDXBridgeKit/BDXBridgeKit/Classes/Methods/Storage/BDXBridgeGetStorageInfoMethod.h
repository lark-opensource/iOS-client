//
//  BDXBridgeGetStorageInfoMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/20.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeGetStorageInfoMethod : BDXBridgeMethod

@end

@interface BDXBridgeGetStorageInfoResultModel : BDXBridgeModel

@property (nonatomic, copy) NSArray<NSString *> *keys;

@end

NS_ASSUME_NONNULL_END

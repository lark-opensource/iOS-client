//
//  BDXBridgeGetSettingsMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/10.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeGetSettingsMethod : BDXBridgeMethod

@end

@interface BDXBridgeGetSettingsMethodParamKeyModel : BDXBridgeModel

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *type;

@end

@interface BDXBridgeGetSettingsMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSArray<BDXBridgeGetSettingsMethodParamKeyModel *> *keys;

@end

@interface BDXBridgeGetSettingsMethodResultModel : BDXBridgeModel

@property (nonatomic, copy) NSDictionary *settings;

@end

NS_ASSUME_NONNULL_END

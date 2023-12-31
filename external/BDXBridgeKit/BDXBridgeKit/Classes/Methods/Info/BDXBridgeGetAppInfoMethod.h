//
//  BDXBridgeGetAppInfoMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/17.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeGetAppInfoMethod : BDXBridgeMethod

@end

@interface BDXBridgeGetAppInfoMethodResultModel : BDXBridgeModel

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *installID;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, copy) NSString *appTheme;
@property (nonatomic, copy) NSString *osVersion;
@property (nonatomic, copy) NSNumber *statusBarHeight;
@property (nonatomic, copy) NSString *devicePlatform;
@property (nonatomic, copy) NSString *deviceModel;
@property (nonatomic, copy) NSString *netType;
@property (nonatomic, copy) NSString *carrier;
@property (nonatomic, assign) BOOL isTeenMode;
@property (nonatomic, assign) BOOL is32Bit;

@end

NS_ASSUME_NONNULL_END

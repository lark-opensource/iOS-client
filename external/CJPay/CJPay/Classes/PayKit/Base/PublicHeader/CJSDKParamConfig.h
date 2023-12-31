//
//  CJSDKParamConfig.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/29.
//

#import <Foundation/Foundation.h>

@interface CJSDKParamConfig : NSObject

@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *settingsVersion;
@property (nonatomic, copy) NSString *sdkName;
@property (nonatomic, copy) NSString *merchantId;

+ (CJSDKParamConfig *)defaultConfig;

@end

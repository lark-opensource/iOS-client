//
//  BDPAddressPluginModel.h
//  Timor
//
//  Created by MacPu on 2018/11/4.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDPBaseJSONModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPAddressPluginModel : BDPBaseJSONModel

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *provinceName;
//省份邮编
@property (nonatomic, copy) NSString *provinceCode;
@property (nonatomic, copy) NSString *cityName;
//城市邮编
@property (nonatomic, copy) NSString *cityCode;
@property (nonatomic, copy) NSString *countyName;
//地区邮编
@property (nonatomic, copy) NSString *countryCode;
@property (nonatomic, copy) NSString *cityId;
@property (nonatomic, copy) NSString *detailInfo;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, assign) NSInteger nationalCode;
@property (nonatomic, assign) BOOL isDefault;
@property (nonatomic, assign) long long addrId;

@end

NS_ASSUME_NONNULL_END

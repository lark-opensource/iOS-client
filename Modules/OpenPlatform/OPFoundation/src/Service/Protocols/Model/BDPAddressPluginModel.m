//
//  BDPAddressPluginModel.m
//  Timor
//
//  Created by MacPu on 2018/11/4.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#import "BDPAddressPluginModel.h"

#define SEL_TO_STR(PARAM) NSStringFromSelector(@selector(PARAM))

@implementation BDPAddressPluginModel

+ (JSONKeyMapper *)keyMapper
{
    NSDictionary *mapDic =  @{
                              SEL_TO_STR(name) : @"name",
                              SEL_TO_STR(phoneNumber) : @"phone_number",
                              SEL_TO_STR(provinceName) : @"province_name",
                              SEL_TO_STR(cityName) : @"city_name",
                              SEL_TO_STR(countyName) : @"county_name",
                              SEL_TO_STR(detailInfo) : @"detail_info",
                              SEL_TO_STR(label) : @"label",
                              SEL_TO_STR(nationalCode) : @"national_code",
                              SEL_TO_STR(isDefault) : @"is_default",
                              SEL_TO_STR(addrId) : @"addr_id",
                              SEL_TO_STR(cityId) : @"city_id"
                              };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:mapDic];
}

@end

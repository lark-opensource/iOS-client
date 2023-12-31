//
//  CJPayIntegratedChannelModel.m
//  CJPay
//
//  Created by wangxinhua on 2020/9/6.
//

#import "CJPayIntegratedChannelModel.h"
#import "CJPaySDKMacro.h"
#import "CJPaySubPayTypeGroupInfo.h"

@implementation CJPayIntegratedChannelModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"payChannels": @"paytype_info.pay_channels",
        @"defaultPayChannel": @"paytype_info.default_pay_channel",
        @"userInfo": @"user_info",
        @"promotionProcessInfo": @"promotion_process",
        @"retainInfo": @"retain_info",
        @"subPayTypeSumInfo": @"paytype_info.sub_pay_type_sum_info", //品牌升级后的数据结构
        @"merchantInfo": @"merchant_info",
        @"homePagePictureUrl" : @"paytype_info.home_page_picture_url", //c2c红包背景
        @"subPayTypeGroupInfoList" : @"paytype_info.sub_pay_type_group_info_list",
        @"extParamStr": @"ext_param", // 透传字段
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

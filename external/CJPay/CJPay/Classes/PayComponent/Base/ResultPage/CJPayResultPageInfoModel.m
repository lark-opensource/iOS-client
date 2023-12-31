//
//  CJPayResultPageInfoModel.m
//  CJPaySandBox
//
//  Created by 高航 on 2022/11/24.
//

#import "CJPayResultPageInfoModel.h"

@implementation CJPayPayInfoDesc

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"name" : @"name",
        @"desc" : @"desc",
        @"showNum" : @"show_num",
        @"iconUrl" : @"icon"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayVoucherOptions

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"desc" : @"desc",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayMerchantTips

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"desc" : @"desc",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayButtonInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"desc" : @"desc",
        @"type" : @"type",
        @"action" : @"action"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayAssets

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"bgImage" : @"bg_image",
        @"tipImage" : @"tip_image",
        @"showImage" : @"show_image",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayRenderInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"type" : @"type",
        @"h5Url" : @"h5_url",
        @"lynxUrl" : @"lynx_url",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayDynamicComponents

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"name" : @"name",
        @"url" : @"url",
        @"schema" : @"schema",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayPaymentInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"typeMark" : @"type_mark",
        @"name" : @"name",
        @"desc" : @"desc",
        @"colorType" : @"color_type",
        @"icon" : @"icon",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end


@implementation CJPayResultPageInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"moreShowInfo" : @"more_show_info",
        @"voucherOptions" : @"voucher_options",
        @"merchantTips" : @"merchant_tips",
        @"buttonInfo" : @"button_info",
        @"assets" : @"assets",
        @"dynamicComponents" : @"dynamic_components",
        @"dynamicData" : @"dynamic_data",
        @"showInfos" : @"show_infos",
        @"renderInfo" : @"render_info"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}
@end

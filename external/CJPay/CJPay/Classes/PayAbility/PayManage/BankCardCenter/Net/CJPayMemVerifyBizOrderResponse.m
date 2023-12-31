//
//  CJPayMemVerifyBizOrderResponse.m
//  Pods
//
//  Created by xiuyuanLee on 2020/10/13.
//

#import "CJPayMemVerifyBizOrderResponse.h"

@implementation CJPayMemVerifyBizOrderResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"needSignCard" : @"response.need_sign_card",
        @"signOrderNo" : @"response.sign_order_no",
        @"buttonInfo" : @"response.button_info",
        @"additionalVerifyType": @"response.additional_verify_type",
        @"faceVerifyInfoModel": @"response.face_verify_info",
    }];
    [dic addEntriesFromDictionary:[self basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

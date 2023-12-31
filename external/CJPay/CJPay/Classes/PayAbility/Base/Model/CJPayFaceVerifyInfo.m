//
//  CJPayFaceVerifyInfo.m
//  CJPay
//  支付过程触发人脸的response
//  Created by 尚怀军 on 2020/8/23.
//

#import "CJPayFaceVerifyInfo.h"

@implementation CJPayFaceVerifyInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"verifyType" : @"verify_type",
                @"faceContent" : @"face_content",
                @"agreementURL" : @"agreement_url",
                @"agreementDesc" : @"agreement_desc",
                @"nameMask" : @"name_mask",
                @"verifyChannel" : @"verify_channel",
                @"style" : @"show_style",
                @"buttonDesc" : @"button_desc",
                @"faceScene" : @"face_scene",
                @"skipCheckAgreement" : @"skip_check_agreement",
                @"appId" : @"merchant_app_id",
                @"merchantId" : @"merchant_id",
                @"title": @"title",
                @"iconUrl": @"icon_url",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

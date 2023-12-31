//
//  CJPayUnionPaySignInfo.m
//  Pods
//
//  Created by wangxiaohong on 2021/9/29.
//

#import "CJPayUnionPaySignInfo.h"

#import "CJPayMemberFaceVerifyInfoModel.h"

@implementation CJPayUnionPaySignInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"additionalVerifyType": @"additional_verify_type",
                @"identityVerifyOrderNo": @"identity_verify_order_no",
                @"displayDesc": @"display_desc",
                @"displayIcon" : @"display_icon",
                @"actionPageType": @"action_page_type",
                @"faceVerifyInfoModel": @"face_verify_info",
                @"unionPaySignStatus" : @"union_pay_sign_status",
                @"voucherLabel" : @"voucher_label"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (BOOL)isNeedVerifyLive {
    return [self.additionalVerifyType isEqualToString:@"live_detection"] || self.faceVerifyInfoModel.needLiveDetection;
}

- (BOOL)isNeedAuthUnionPay {
    return [self.unionPaySignStatus isEqualToString:@"invalid"];
}

@end

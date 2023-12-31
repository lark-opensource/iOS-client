//
//  CJPayCreateOneKeySignOrderResponse.m
//  Pods
//
//  Created by 王新华 on 2020/10/14.
//

#import "CJPayCreateOneKeySignOrderResponse.h"
#import "CJPayMemberFaceVerifyInfoModel.h"

@implementation CJPayCreateOneKeySignOrderResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
        @"bankUrl": @"response.bank_url",
        @"memberBizOrderNo": @"response.member_biz_order_no",
        @"postData": @"response.post_data",
        @"status": @"response.ret_status",
        @"signOrder": @"response.sign",
        @"buttonInfo": @"response.button_info",
        @"faceVerifyInfoModel": @"response.face_verify_info",
        @"additionalVerifyType" : @"response.additional_verify_type",
        @"isMiniApp" : @"response.is_mini_app"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dict];
}

- (BOOL)needVerifyPassWord {
    return [self.additionalVerifyType isEqualToString:@"password"];
}

- (BOOL)needLiveDetection {
    if ([self.additionalVerifyType isEqualToString:@"live_detection"] ||
        self.faceVerifyInfoModel.needLiveDetection) {
        return YES;
    }
    return NO;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

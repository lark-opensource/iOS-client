//
//  CJPayGetTicketResponse.m
//  CJPay
//
//  Created by 尚怀军 on 2020/8/20.
//

#import "CJPayGetTicketResponse.h"
#import "CJPayFaceRecogConfigModel.h"

@implementation CJPayGetTicketResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [self basicDict];
    [dic addEntriesFromDictionary:@{
        @"status" : @"response.ret_status",
        @"ticket" : @"response.ticket",
        @"isSigned" : @"response.is_signed",
        @"agreementUrl" : @"response.agreement_url",
        @"agreementDesc" : @"response.agreement_desc",
        @"nameMask" : @"response.name_mask",
        @"scene" : @"response.scene",
        @"memberBizOrderNo" : @"response.member_biz_order_no",
        @"liveRoute" : @"response.live_route",
        @"protocolCheckBox" : @"response.protocol_check_box",
        @"faceScene" : @"response.face_scene"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (NSUInteger)getEnterFromValue {
    return self.isSigned ? 2 : 1;
}

- (NSString *)getLiveRouteTrackStr {
    if ([self.liveRoute isEqualToString:BDPayVerifyChannelAilabStr]) {
        return @"0";
    } else if ([self.liveRoute isEqualToString:BDPayVerifyChannelFacePlusStr]) {
        return @"1";
    } else if ([self.liveRoute isEqualToString:BDPayVerifyChannelAliYunStr]) {
        return @"2";
    } else {
        return @"0";
    }
}

@end

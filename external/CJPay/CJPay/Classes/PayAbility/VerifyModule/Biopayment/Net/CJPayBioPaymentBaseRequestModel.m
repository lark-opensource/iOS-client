//
//  CJPayBioPaymentBaseRequestModel.m
//  BDPay
//
//  Created by 易培淮 on 2020/7/17.
//

#import "CJPayBioPaymentBaseRequestModel.h"
#import "CJPayRequestParam.h"

@implementation CJPayBioPaymentBaseRequestModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.did = [CJPayRequestParam deviceID];
    }
    return self;
}

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"appId": @"appId",
                @"signType": @"signType",
                @"sign": @"sign",
                @"uid": @"uid",
                @"merchantId": @"merchantId",
                @"timestamp": @"timestamp",
                @"did": @"did",
                @"smchId": @"smchId",
                @"memberBizOrderNo" : @"member_biz_order_no",
                @"verifyType" : @"verify_type",
                @"verifyInfo" : @"verify_info",
                @"isOnlyReturnDeviceType" : @"onlyReturnDeviceType",
                @"source" : @"source",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

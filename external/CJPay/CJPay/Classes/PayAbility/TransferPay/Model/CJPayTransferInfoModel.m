//
//  CJPayTransferInfoModel.m
//  Pods
//
//  Created by 尚怀军 on 2022/10/31.
//

#import "CJPayTransferInfoModel.h"

@implementation CJPayTransferInfoModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
        @"appId" : @"app_id",
        @"merchantId" : @"merchant_id",
        @"outTradeNo" : @"out_trade_no",
        @"tradeNo" : @"trade_no",
        @"needFace" : @"need_face",
        @"lynxUrl" : @"lynx_url",
        @"processId" : @"process_id",
        @"faceVerifyInfo" : @"face_verify_info",
        @"needBindCard": @"need_bind_card",
        @"zgAppId": @"zg_app_id",
        @"zgMerchantId": @"zg_merchant_id",
        @"needQueryFaceData": @"need_query_face_data",
        @"needOpenAccount": @"need_open_account",
        @"openAccountUrl": @"open_account_url"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

//
//  CJPayNewIAPOrderCreateResponse.m
//  Pods
//
//  Created by 尚怀军 on 2022/3/8.
//

#import "CJPayNewIAPOrderCreateResponse.h"
#import "CJPayNewIAPOrderCreateModel.h"

@implementation CJPayNewIAPOrderCreateResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
                                     @"appId" : @"response.app_id",
                                     @"merchantId" : @"response.merchant_id",
                                     @"uid" : @"response.uid",
                                     @"tradeNo" : @"response.trade_no",
                                     @"outTradeNo" : @"response.out_trade_no",
                                     @"uuid" : @"response.uuid",
                                     @"uidEncrypt" : @"response.uid_encrypt",
                                     @"tradeAmount" : @"response.trade_amount"
                                     }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}


- (CJPayNewIAPOrderCreateModel *)toNewIAPOrderCreateModel {
    CJPayNewIAPOrderCreateModel *model = [CJPayNewIAPOrderCreateModel new];
    model.code = self.code;
    model.msg = self.msg;
    model.status = self.status;
    model.appId = self.appId;
    model.merchantId = self.merchantId;
    model.uid = self.uid;
    model.tradeNo = self.tradeNo;
    model.outTradeNo = self.outTradeNo;
    model.uuid = self.uuid;
    model.tradeAmount = self.tradeAmount;
    model.uidEncrypt = self.uidEncrypt;
    model.isBackground = NO;
    return model;
}


@end

//
//  CJPayBDCreateOrderResponse+BindCardModel.m
//  CJPay
//
//  Created by wangxiaohong on 2022/12/30.
//

#import "CJPayBDCreateOrderResponse+BindCardModel.h"

@implementation CJPayBDCreateOrderResponse (BindCardModel)

- (CJPayBindCardSharedDataModel *)buildBindCardCommonModel {
    CJPayBindCardSharedDataModel *bindModel = [CJPayBindCardSharedDataModel new];
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    bindModel.startTimestamp = [date timeIntervalSince1970] * 1000;
    bindModel.userInfo = self.userInfo;
    bindModel.merchantId = self.merchant.merchantId;
    bindModel.appId = self.merchant.appId;
    bindModel.cardBindSource = CJPayCardBindSourceTypeBindAndPay;
    bindModel.processInfo = self.processInfo;
    return bindModel;
}

@end

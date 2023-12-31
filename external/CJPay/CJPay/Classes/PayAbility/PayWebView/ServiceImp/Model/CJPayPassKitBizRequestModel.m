//
//  CJPayPassKitBizRequestModel.m
//  CJPay
//
//  Created by 王新华 on 2019/5/20.
//

#import "CJPayPassKitBizRequestModel.h"

@implementation CJPayPassKitBizRequestModel

- (id)copyWithZone:(NSZone *)zone {
    CJPayPassKitBizRequestModel *model = [CJPayPassKitBizRequestModel new];
    model.appID = self.appID;
    model.merchantID = self.merchantID;
//    model.sessionKey = self.sessionKey;
//    bizRequestModel.setPwdType = self.setPwdType;
//    model.smchID = self.smchID;
//    model.authorizeItem = self.authorizeItem;
//    model.bindCardID = self.bindCardID;
    model.uid = self.uid;
//    model.cardNum = self.cardNum;
    model.mobile = self.mobile;
//    model.sence = [self.sence copy];
    return model;
}

@end

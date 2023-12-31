//
//  CJPayFaceRecogConfigModel.m
//  Pods
//
//  Created by 尚怀军 on 2022/10/24.
//

#import "CJPayFaceRecogConfigModel.h"

NSString * const BDPayFacePlusVerifyReturnURL = @"https://cjpaysdk/facelive/callback";
NSString * const BDPayVerifyChannelAilabStr = @"AILABFIA";
NSString * const BDPayVerifyChannelFacePlusStr = @"KSKJFIA";
NSString * const BDPayVerifyChannelAliYunStr = @"ALIYUNFIA";

@implementation CJPayFaceRecogConfigModel

- (CJPayFaceRecognitionStyle)getAlertShowStyle {
    switch (self.popStyle) {
        case CJPayFaceRecogPopStyleRiskVerifyInPay:
            return CJPayFaceRecognitionStyleExtraTestInPayment;
            break;
        case CJPayFaceRecogPopStyleRiskVerifyInBindCard:
            return CJPayFaceRecognitionStyleExtraTestInBindCard;
            break;
        case CJPayFaceRecogPopStyleActivelyArouse:
            return CJPayFaceRecognitionStyleActivelyArouseInPayment;
            break;
        default:
            return CJPayFaceRecognitionStyleOpenBioVerify;
            break;
    }
}

@end

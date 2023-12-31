//
//  CJPayMemberFaceVerifyInfoModel.m
//  Pods
//  绑卡过程触发人脸的response
//  Created by 尚怀军 on 2020/12/31.
//

#import "CJPayMemberFaceVerifyInfoModel.h"
#import "CJPayFaceVerifyInfo.h"

@implementation CJPayMemberFaceVerifyInfoModel

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"verifyType": @"verify_type",
        @"faceContent": @"face_content",
        @"agreementUrl": @"agreement_url",
        @"agreementDesc": @"agreement_desc",
        @"nameMask": @"name_mask",
        @"uid": @"uid",
        @"smchId": @"smch_id",
        @"needLiveDetection": @"need_live_detection"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (CJPayFaceVerifyInfo *)getFaceVerifyInfoModel {
    CJPayFaceVerifyInfo *infoModel = [CJPayFaceVerifyInfo new];
    infoModel.agreementDesc = self.agreementDesc;
    infoModel.agreementURL = self.agreementUrl;
    infoModel.faceContent = self.faceContent;
    infoModel.nameMask = self.nameMask;
    infoModel.verifyType = self.verifyType;
    return infoModel;
}

@end

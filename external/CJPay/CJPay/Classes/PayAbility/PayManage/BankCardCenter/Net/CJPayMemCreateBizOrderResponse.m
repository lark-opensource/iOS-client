//
//  CJPayMemCreateBizOrderResponse.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/13.
//

#import "CJPayMemCreateBizOrderResponse.h"
#import "CJPayBizAuthInfoModel.h"
#import "CJPayUserInfo.h"
#import "CJPaySignCardMap.h"
#import "CJPayBindCardSharedDataModel.h"

@implementation CJPayMemCreateBizOrderResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"memberBizUrl" : @"response.member_biz_url",
        @"memberBizOrderNo" : @"response.member_biz_order_no",
        @"signCardMap" : @"response.sign_card_map",
        @"bizAuthInfoModel" : @"response.busi_authorize_info",
        @"bindPageInfoResponse" : @"response.bind_card_page_info",
        @"retainInfoModel" : @"response.retention_msg"
    }];
    [dic addEntriesFromDictionary:[self basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

- (CJPayUserInfo *)generateUserInfo {
    CJPayUserInfo *userInfo = [CJPayUserInfo new];
    userInfo.authStatus = self.signCardMap.isAuthed;
    userInfo.pwdStatus = self.signCardMap.isSetPwd;
    userInfo.mName = self.signCardMap.idNameMask;
    userInfo.mobile = self.signCardMap.mobileMask;
    userInfo.certificateType = self.bizAuthInfoModel.idType;
    userInfo.uidMobileMask = self.signCardMap.uidMobileMask;
    return userInfo;
}

- (NSString *)protocolDescription {
    return self.signCardMap.protocolDescription;
}

- (NSString *)buttonDescription {
    return self.signCardMap.buttonDescription;
}

- (CJPayBindCardSharedDataModel *)buildCommonModel {
    CJPayBindCardSharedDataModel *model = [CJPayBindCardSharedDataModel new];
    model.skipPwd = self.signCardMap.skipPwd;
    model.signOrderNo = self.signCardMap.memberBizOrderNo;
    model.userInfo = [self generateUserInfo];
    model.userInfo.certificateType = self.signCardMap.idType;
    model.userInfo.mobile = self.signCardMap.mobileMask;
    model.userInfo.uidMobileMask = self.signCardMap.uidMobileMask;
    model.memCreatOrderResponse = [CJPayMemCreateBizOrderResponse new];
    model.memCreatOrderResponse.memberBizOrderNo = self.signCardMap.memberBizOrderNo;
    model.memCreatOrderResponse.signCardMap = self.signCardMap;
    model.memCreatOrderResponse.bizAuthInfoModel = self.bizAuthInfoModel;
    model.bizAuthInfoModel = self.bizAuthInfoModel;
    model.bankListResponse = self.bindPageInfoResponse;
    return model;
}

@end

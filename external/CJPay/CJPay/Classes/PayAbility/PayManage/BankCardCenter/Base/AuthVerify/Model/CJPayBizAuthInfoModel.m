//
//  CJPayBizAuthInfoModel.m
//  Pods
//
//  Created by xiuyuanLee on 2020/11/2.
//

#import "CJPayBizAuthInfoModel.h"

#import "CJPayAuthAgreementContentModel.h"
#import "CJPayMemAgreementModel.h"

@implementation CJPayBizAuthInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"isNeedAuthorize" : @"is_need_authorize",
        @"isAuthed" : @"is_authed",
        @"isConflict" : @"is_conflict",
        @"conflictActionURL" : @"conflict_action_url",
        
        @"idType" : @"busi_auth_info.id_type",
        @"idCodeMask" : @"busi_auth_info.id_code_mask",
        @"idNameMask" : @"busi_auth_info.id_name_mask",
        
        @"authAgreementContentModel" : @"busi_authorize_content",
        
        @"agreements" : @"protocol_group_contents.protocol_list",
        @"guideMessage" : @"protocol_group_contents.guide_message",
        @"protocolCheckBox" : @"response.protocol_check_box",
        @"protocolGroupNames" : @"protocol_group_contents.protocol_group_names"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (NSString *)disagreeContent {
    return self.authAgreementContentModel.disagreeContent;
}

- (NSString *)tipsContent {
    return self.authAgreementContentModel.tipsContent;
}

@end

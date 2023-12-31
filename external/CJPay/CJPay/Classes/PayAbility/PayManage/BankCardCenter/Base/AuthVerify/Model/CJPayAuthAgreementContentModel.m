//
//  CJPayAuthAgreementContentModel.m
//  CJPay
//
//  Created by wangxiaohong on 2020/5/25.
//

#import "CJPayAuthAgreementContentModel.h"

@implementation CJPayAuthAgreementContentModel

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                   @"businessBriefInfo" : @"business_brief_info",
                   @"proposeDesc" : @"propose_desc",
                   @"proposeContents": @"propose_contents",
                   @"agreementContents": @"agreement_contents",
                   @"secondAgreementContents":@"second_agreement_contents",
                   @"disagreeUrl": @"not_agreement_url",
                   @"disagreeContent" : @"not_agreement_content",
                   @"tipsContent" : @"tips_content",
                   @"authorizeItem": @"authorize_item"
               }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

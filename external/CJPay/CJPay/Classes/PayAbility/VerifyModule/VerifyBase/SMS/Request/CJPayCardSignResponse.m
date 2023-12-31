//
//  CJPayCardSignResponse.m
//  CJPay
//
//  Created by wangxiaohong on 2020/3/29.
//

#import "CJPayCardSignResponse.h"

#import "CJPayUserInfo.h"
#import "CJPayErrorButtonInfo.h"
#import "CJPayQuickPayUserAgreement.h"

#import "NSString+CJPay.h"
#import "CJPaySDKMacro.h"

@implementation CJPayCardSignResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
        @"userInfo": @"response.user_info",
        @"card": @"response.card",
        @"buttonInfo": @"response.button_info",
        @"agreements": @"response.agreement",
        @"cardSignInfo": @"response.sign_info"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dict];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (NSArray<CJPayQuickPayUserAgreement *> *)getQuickAgreements
{
    NSMutableArray<CJPayQuickPayUserAgreement *> *models= [NSMutableArray array];
    [self.agreements enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CJPayQuickPayUserAgreement  *model = obj;
        if (model) {
            CJPayQuickPayUserAgreement *agreementModel =  [CJPayQuickPayUserAgreement new];
            agreementModel.title = CJString([model.title cj_removeBookNum]);
            agreementModel.contentURL = model.contentURL;
            agreementModel.defaultChoose = model.defaultChoose;
            [models addObject:agreementModel];
        }
    }];
    return models;
}

@end

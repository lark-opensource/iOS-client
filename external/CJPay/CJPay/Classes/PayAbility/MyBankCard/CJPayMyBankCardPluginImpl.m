//
//  CJPayMyBankCardPluginImpl.m
//  CJPaySandBox
//
//  Created by chenbocheng.moon on 2023/1/19.
//

#import "CJPayMyBankCardPluginImpl.h"
#import "CJPayMyBankCardPlugin.h"
#import "CJPayBankCardListViewController.h"
#import "CJPayBankCardDetailViewController.h"
#import "CJPayPrivateServiceHeader.h"

@interface CJPayMyBankCardPluginImpl()<CJPayMyBankCardPlugin>

@end

@implementation CJPayMyBankCardPluginImpl

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(shared), CJPayMyBankCardPlugin);
});

- (CJPayBankCardListViewController *)openMyCardWithAppId:(NSString *)appId merchantId:(NSString *)merchantId userId:(NSString *)userId extraParams:(NSDictionary *)extraParams {
    return [CJPayBankCardListViewController openWithAppId:appId merchantId:merchantId userId:userId extraParams:extraParams];;
}

- (CJPayBankCardDetailViewController *)openDetailWithCardItemModel:(CJPayBankCardItemViewModel *)cardItemModel {
    return [[CJPayBankCardDetailViewController alloc] initWithCardItemModel:cardItemModel];
}

@end

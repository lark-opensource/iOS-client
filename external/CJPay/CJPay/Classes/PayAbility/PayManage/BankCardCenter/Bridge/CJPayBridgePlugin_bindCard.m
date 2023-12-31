//
//  CJPayBridgePlugin_bindCard.m
//  Aweme
//
//  Created by chenbocheng.moon on 2022/11/25.
//

#import "CJPayBridgePlugin_bindCard.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayUIMacro.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPaySignCardMap.h"
#import "CJPayBizAuthInfoModel.h"
#import "CJPayUserInfo.h"
#import "CJPayMemCreateBizOrderResponse.h"
#import "CJPayBindCardManager.h"
#import "UIViewController+CJPay.h"
#import "CJPayNativeBindCardPlugin.h"
#import "CJPayUnionBindCardPlugin.h"

@implementation CJPayBridgePlugin_bindCard

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_bindCard, bindCard), @"ttcjpay.bindCard");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)bindCardWithParam:(NSDictionary *)param
            callback:(TTBridgeCallback)callback
              engine:(id<TTBridgeEngine>)engine
          controller:(UIViewController *)controller {
    if (callback) {
        [CJPayBindCardManager sharedInstance].stopLoadingBlock = ^(){
            TTBRIDGE_CALLBACK_SUCCESS
        };
    }
    
    NSString *bindType = [param cj_stringValueForKey:@"bind_type"];
    
    if ([bindType isEqualToString:@"bindCardHomePage"]) {
        if (!CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin)) {
            CJPayLogAssert(NO, @"没有接入native绑卡");
            return;
        }
        
        [CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin) bindCardHomePageFromJsbWithParam:param];
    } else if ([bindType isEqualToString:@"unionPayBindCard"]) {
        if(!CJ_OBJECT_WITH_PROTOCOL(CJPayUnionBindCardPlugin)) {
            CJPayLogAssert(NO, @"没有接入云闪付绑卡");
            return;
        }
        
        [CJ_OBJECT_WITH_PROTOCOL(CJPayUnionBindCardPlugin) createPromotionOrder:param];
    } else if ([bindType isEqualToString:@"quickBindCard"]) {
        if (!CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin)) {
            CJPayLogAssert(NO, @"没有接入native绑卡");
            return;
        }
        
        [CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin) quickBindCardFromJsbWithParam:param];
    } else if ([bindType isEqualToString:@"unionPayBindCardFromFirstPage"]) {
        if(!CJ_OBJECT_WITH_PROTOCOL(CJPayUnionBindCardPlugin)) {
            CJPayLogAssert(NO, @"没有接入云闪付绑卡");
            return;
        }
        
        CJPayBindCardSharedDataModel *commonModel = [self p_buildCommonModelWithParams:param];
        
        if (!commonModel) {
            CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"result": @"0"}, nil);
            return;
        }
        
        commonModel.isSyncUnionCard = YES;
        commonModel.bindUnionCardType = CJPayBindUnionCardTypeSyncBind;
        commonModel.bindUnionCardSourceType = CJPayBindUnionCardSourceTypeLynxBindCardFirstPage;
        commonModel.isBindUnionCardNeedLoading = [param cj_boolValueForKey:@"need_loading"];
        commonModel.completion = ^(CJPayBindCardResultModel * _Nonnull cardResult) {
            if (cardResult.result == CJPayBindCardResultSuccess) {
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"result": @"1"}, nil);
            } else {
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"result": @"0"}, nil);
            }
        };
        [[CJPayBindCardManager sharedInstance] bindCardWithCommonModel:commonModel];
    }
}

- (CJPayBindCardSharedDataModel *)p_buildCommonModelWithParams:(NSDictionary *)params {
    NSDictionary *orderMap = [params cj_dictionaryValueForKey:@"create_order_data"];
    NSDictionary *signCardMap = [orderMap cj_dictionaryValueForKey:@"sign_card_map"];
    NSDictionary *bizAuthInfo = [orderMap cj_dictionaryValueForKey:@"busi_authorize_info"];
    NSDictionary *unionPayVoucher = [orderMap cj_dictionaryValueForKey:@"union_pay_voucher"];

    if (!signCardMap) {
        return nil;
    }

    CJPaySignCardMap *signCardMapModel = [[CJPaySignCardMap alloc] initWithDictionary:signCardMap error:nil];
    CJPayBizAuthInfoModel *bizAuthInfoModel =  [[CJPayBizAuthInfoModel alloc] initWithDictionary:bizAuthInfo error:nil];;

    CJPayBindCardSharedDataModel *model = [CJPayBindCardSharedDataModel new];
    model.cardBindSource = CJPayCardBindSourceTypeIndependent;
    model.appId = signCardMapModel.appId;
    model.merchantId = signCardMapModel.merchantId;

    model.skipPwd = signCardMapModel.skipPwd;
    model.signOrderNo = signCardMapModel.memberBizOrderNo;
    model.userInfo = [self p_buildUserInfo:signCardMapModel];
    
    CJPayQuickBindCardModel *bindCardModel = [CJPayQuickBindCardModel new];
    bindCardModel.voucherInfoDict = unionPayVoucher;
    model.quickBindCardModel = bindCardModel;

    model.bankMobileNoMask = signCardMapModel.mobileMask;
    model.referVC = [UIViewController cj_topViewController];
    model.cjpay_referViewController = [UIViewController cj_topViewController];
    
    model.memCreatOrderResponse = [CJPayMemCreateBizOrderResponse new];
    model.memCreatOrderResponse.memberBizOrderNo = signCardMapModel.memberBizOrderNo;
    model.memCreatOrderResponse.signCardMap = signCardMapModel;
    model.memCreatOrderResponse.bizAuthInfoModel = bizAuthInfoModel;
    model.bizAuthInfoModel = bizAuthInfoModel;
    return model;
}

- (CJPayUserInfo *)p_buildUserInfo:(CJPaySignCardMap *)signCardMap {
    CJPayUserInfo *userInfo = [CJPayUserInfo new];
    userInfo.certificateType = signCardMap.idType;
    userInfo.mobile = signCardMap.mobileMask;
    userInfo.uidMobileMask = signCardMap.uidMobileMask;
    userInfo.authStatus = signCardMap.isAuthed;
    userInfo.pwdStatus = signCardMap.isSetPwd;
    userInfo.mName = signCardMap.idNameMask;
    return userInfo;
}

@end

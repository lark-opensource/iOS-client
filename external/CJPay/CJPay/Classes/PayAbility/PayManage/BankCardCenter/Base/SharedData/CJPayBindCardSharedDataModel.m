//
//  CJPayBindCardSharedDataModel.m
//  CJPay
//
//  Created by 尚怀军 on 2019/11/3.
//

#import "CJPayBindCardSharedDataModel.h"

#import "CJPayUserInfo.h"
#import "CJPayProcessInfo.h"
#import "CJPayUnionBindCardCommonModel.h"
#import "CJPayCommonUtil.h"
#import "CJPayBizAuthInfoModel.h"
#import <ByteDanceKit/ByteDanceKit.h>

NSString *const CJPayBindCardShareDataKeyAppId = @"app_id";
NSString *const CJPayBindCardShareDataKeyMerchantId = @"merchant_id";
NSString *const CJPayBindCardShareDataKeyCardBindSource = @"card_bind_source";
NSString *const CJPayBindCardShareDataKeyOuterClose = @"outer_close";
NSString *const CJPayBindCardShareDataKeyFirstStepBackgroundImageURL = @"first_step_background_image_url";
NSString *const CJPayBindCardShareDataKeyFirstStepMainTitle = @"first_step_main_title";
NSString *const CJPayBindCardShareDataKeyProcessInfo = @"process_info";
NSString *const CJPayBindCardShareDataKeyIsCertification = @"is_certification";
NSString *const CJPayBindCardShareDataKeyIsQuickBindCard = @"is_quick_bind_card";
NSString *const CJPayBindCardShareDataKeyIsBizAuthVCShown = @"is_biz_auth_vc_shown";
NSString *const CJPayBindCardShareDataKeyIsQuickBindCardListHidden = @"is_quick_bind_card_list_hidden";
NSString *const CJPayBindCardShareDataKeyJumpQuickBindCard = @"jump_quick_bind_card";
NSString *const CJPayBindCardShareDataKeyQuickBindCardModel = @"quick_bind_card_model";
NSString *const CJPayBindCardShareDataKeyMemCreatOrderResponse = @"mem_creat_order_response";
NSString *const CJPayBindCardShareDataKeyBizAuthInfoModel = @"biz_auth_info_model";
NSString *const CJPayBindCardShareDataKeySpecialMerchantId = @"special_merchant_id";
NSString *const CJPayBindCardShareDataKeyUserInfo = @"user_info";
NSString *const CJPayBindCardShareDataKeySignOrderNo = @"sign_order_no";
NSString *const CJPayBindCardShareDataKeyBankMobileNoMask = @"bank_mobile_no_mask";
NSString *const CJPayBindCardShareDataKeySkipPwd = @"skip_pwd";
NSString *const CJPayBindCardShareDataKeyTitle = @"title";
NSString *const CJPayBindCardShareDataKeySubTitle = @"sub_title";
NSString *const CJPayBindCardShareDataKeyOrderAmount = @"order_amount";
NSString *const CJPayBindCardShareDataKeyFrontIndependentBindCardSource = @"front_independent_bind_card_source";
NSString *const CJPayBindCardShareDataKeyStartTimestamp = @"start_bindcard_timestamp";
NSString *const CJPayBindCardShareDataKeyFirstStepVCTimestamp = @"first_step_vc_timestamp";
NSString *const CJPayBindCardShareDataKeyBindCardInfo = @"bind_card_info";
NSString *const CJPayBindCardShareDataKeyVoucherMsgStr = @"voucher_msg_str";
NSString *const CJPayBindCardShareDataKeyVoucherBankStr = @"voucher_bank_str";
NSString *const CJPayBindCardShareDataKeyDisplayIcon = @"display_icon";
NSString *const CJPayBindCardShareDataKeyDisplayDesc = @"display_desc";
NSString *const CJPayBindCardShareDataKeyIsSyncUnionCard = @"is_sync_union_card";
NSString *const CJPayBindCardShareDataKeyBindUnionCardType = @"bind_union_card_type";
NSString *const CJPayBindCardShareDataKeyUnionBindCardCommonModel = @"union_bind_card_common_model";
NSString *const CJPayBindCardShareDataKeyIsEcommerceAddBankCardAndPay = @"is_ecommerce_add_bank_card_and_pay";
NSString *const CJPayBindCardShareDataKeyTrackerParams = @"tracker_params";
NSString *const CJPayBindCardShareDataKeyTrackInfo = @"track_info";
NSString *const CJPayBindCardShareDataKeyBizAuthType = @"biz_auth_type";
NSString *const CJPayBindCardShareDataKeyOrderInfo = @"order_info";
NSString *const CJPayBindCardShareDataKeyIconURL = @"icon_url";
NSString *const CJPayBindCardShareDataKeyBankListResponse = @"bank_list_response";
NSString *const CJPayBindCardShareDataKeyRetainInfo = @"first_page_retain_info"; //绑卡挽留信息
NSString *const CJPayBindCardShareDataKeyIsHadShowRetain = @"is_had_show_bindcard_retain_info"; //绑卡全流程中是否展示过挽留信息
NSString *const CJPayBindCardShareDataKeyCachedIdentityInfoModel = @"cached_identity_info_model"; //缓存的实名信息，一次绑卡流程中，10分钟内生效
NSString *const CJPayBindCardShareDataKeyLynxBindCardType = @"lynx_bind_card_type";

@implementation CJPayBindCardSharedDataModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[[self p_keyMapperDict] copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

+ (BOOL)propertyIsIgnored:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"useNavVC"] ||
        [propertyName isEqualToString:@"referVC"]) {
        return YES;
    }
    
    return NO;
}

+ (NSDictionary <NSString *, NSString *> *)p_keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"appId" : CJPayBindCardShareDataKeyAppId,
        @"merchantId" : CJPayBindCardShareDataKeyMerchantId,
        @"cardBindSource" : CJPayBindCardShareDataKeyCardBindSource,
        @"outerClose" : CJPayBindCardShareDataKeyOuterClose,
        @"firstStepBackgroundImageURL" : CJPayBindCardShareDataKeyFirstStepBackgroundImageURL,
        @"firstStepMainTitle" : CJPayBindCardShareDataKeyFirstStepMainTitle,
        @"processInfo" : CJPayBindCardShareDataKeyProcessInfo,
        @"isCertification" : CJPayBindCardShareDataKeyIsCertification,
        @"isQuickBindCard" : CJPayBindCardShareDataKeyIsQuickBindCard,
        @"isBizAuthVCShown" : CJPayBindCardShareDataKeyIsBizAuthVCShown,
        @"isQuickBindCardListHidden" : CJPayBindCardShareDataKeyIsQuickBindCardListHidden,
        @"jumpQuickBindCard" : CJPayBindCardShareDataKeyJumpQuickBindCard,
        @"quickBindCardModel" : CJPayBindCardShareDataKeyQuickBindCardModel,
        @"memCreatOrderResponse" : CJPayBindCardShareDataKeyMemCreatOrderResponse,
        @"bizAuthInfoModel" : CJPayBindCardShareDataKeyBizAuthInfoModel,
        @"specialMerchantId" : CJPayBindCardShareDataKeySpecialMerchantId,
        @"userInfo" : CJPayBindCardShareDataKeyUserInfo,
        @"bankMobileNoMask" : CJPayBindCardShareDataKeyBankMobileNoMask,
        @"signOrderNo" : CJPayBindCardShareDataKeySignOrderNo,
        @"skipPwd" : CJPayBindCardShareDataKeySkipPwd,
        @"title" : CJPayBindCardShareDataKeyTitle,
        @"subTitle" : CJPayBindCardShareDataKeySubTitle,
        @"orderAmount" : CJPayBindCardShareDataKeyOrderAmount,
        @"frontIndependentBindCardSource" : CJPayBindCardShareDataKeyFrontIndependentBindCardSource,
        @"startTimestamp" : CJPayBindCardShareDataKeyStartTimestamp,
        @"firstStepVCTimestamp" : CJPayBindCardShareDataKeyFirstStepVCTimestamp,
        @"bindCardInfo" : CJPayBindCardShareDataKeyBindCardInfo,
        @"voucherMsgStr" : CJPayBindCardShareDataKeyVoucherMsgStr,
        @"voucherBankStr" : CJPayBindCardShareDataKeyVoucherBankStr,
        @"displayIcon" : CJPayBindCardShareDataKeyDisplayIcon,
        @"displayDesc" : CJPayBindCardShareDataKeyDisplayDesc,
        @"orderInfo" : CJPayBindCardShareDataKeyOrderInfo,
        @"iconURL" : CJPayBindCardShareDataKeyIconURL,
        @"isSyncUnionCard" : CJPayBindCardShareDataKeyIsSyncUnionCard,
        @"bindUnionCardType" : CJPayBindCardShareDataKeyBindUnionCardType,
        @"unionBindCardCommonModel" : CJPayBindCardShareDataKeyUnionBindCardCommonModel,
        @"isEcommerceAddBankCardAndPay" : CJPayBindCardShareDataKeyIsEcommerceAddBankCardAndPay,
        @"trackerParams" : CJPayBindCardShareDataKeyTrackerParams,
        @"trackInfo" : CJPayBindCardShareDataKeyTrackInfo,
        @"bizAuthType": CJPayBindCardShareDataKeyBizAuthType,
        @"bankListResponse" : CJPayBindCardShareDataKeyBankListResponse,
        @"retainInfo": CJPayBindCardShareDataKeyRetainInfo,
        @"isHadShowRetain" : CJPayBindCardShareDataKeyIsHadShowRetain,
        @"cachedIdentityModel" : CJPayBindCardShareDataKeyCachedIdentityInfoModel,
        @"lynxBindCardType" : CJPayBindCardShareDataKeyLynxBindCardType
    }];
    
    return dict;
}

- (CJPayBizAuthType)bizAuthType {
    if ([self.bizAuthExperiment isEqualToString:@"2"]) {
        return CJPayBizAuthTypeSilent;
    }
    
    return CJPayBizAuthTypeDefault;
}

- (BOOL)isCertification {
    if (self.bindUnionCardType == CJPayBindUnionCardTypeBindAndSign || self.bindUnionCardType == CJPayBindUnionCardTypeSyncBind) {
        return _isCertification;
    }
    
    return _isCertification || (self.bizAuthType == CJPayBizAuthTypeSilent && self.bizAuthInfoModel.isNeedAuthorize);
}

@end

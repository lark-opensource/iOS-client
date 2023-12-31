//
//  CJPayRetainUtil.m
//  Pods
//
//  Created by 王新华 on 2021/8/11.
//

#import "CJPayRetainUtil.h"
#import "CJPayAlertUtil.h"
#import "CJPayPayCancelRetainViewController.h"
#import "CJPayPayCancelLynxRetainViewController.h"
#import "CJPayRetainUtilModel.h"
#import "CJPayKVContext.h"
#import "CJPayStayAlertForOrderModel.h"
#import "CJPayServerEventCenter.h"
#import "CJPayRetainRecommendInfoModel.h"
#import "CJPayRetainInfoV2Config.h"

@implementation CJPayRetainUtil

+ (BOOL)couldShowRetainVCWithSourceVC:(UIViewController *)sourceVC
                      retainUtilModel:(CJPayRetainUtilModel *)retainUtilModel {
    return [self couldShowRetainVCWithSourceVC:sourceVC retainUtilModel:retainUtilModel completion:nil];
}

+ (BOOL)couldShowRetainVCWithSourceVC:(UIViewController *)sourceVC
                      retainUtilModel:(CJPayRetainUtilModel *)retainUtilModel
                           completion:(void (^ _Nullable)(BOOL))completion
{
    CJPayBDRetainInfoModel *retainInfo = retainUtilModel.retainInfo;
    if (retainInfo && !retainInfo.showRetainWindow) { // 服务端下发不应该展示挽留弹窗
        return NO;
    };
    
    CJPayStayAlertForOrderModel *model = [CJPayKVContext kv_valueForKey:CJPayStayAlertShownKey];
    if (model && ![model shouldShowWithIdentifer:retainUtilModel.intergratedTradeNo]) { // 当笔订单已经展示过挽留弹窗，则不再展示
        return NO;
    }
    
    CJPayRetainInfoModel *retainInfoModel = [CJPayRetainInfoModel new];

    @CJWeakify(retainInfoModel)
    void (^confirmBlock)(void) = ^{
        @CJStrongify(retainInfoModel)
        [retainInfoModel trackRetainPopUpWithEvent:retainUtilModel.eventNameForPopUpClick trackDelegate:retainUtilModel.trackDelegate extraParam:retainUtilModel.extraParamForConfirm];
        CJ_CALL_BLOCK(retainUtilModel.confirmActionBlock);
    };
    void (^otherVerifyBlock)(void) = ^{
        @CJStrongify(retainInfoModel)
        [retainInfoModel trackRetainPopUpWithEvent:retainUtilModel.eventNameForPopUpClick trackDelegate:retainUtilModel.trackDelegate extraParam:retainUtilModel.extraParamForOtherVerify];
        CJ_CALL_BLOCK(retainUtilModel.otherVerifyActionBlock);
    };
    void (^closeBlock)(void) = ^{
        @CJStrongify(retainInfoModel)
        [retainInfoModel trackRetainPopUpWithEvent:retainUtilModel.eventNameForPopUpClick trackDelegate:retainUtilModel.trackDelegate extraParam:retainUtilModel.extraParamForClose];
        CJ_CALL_BLOCK(retainUtilModel.closeActionBlock);
    };
    
    CJPayRetainType retainType = retainUtilModel.retainType;
    
    if (!retainUtilModel.isOnlyShowNormalRetainStyle && (retainType == CJPayRetainTypeBonus || retainType == CJPayRetainTypeText || retainUtilModel.positionType == CJPayRetainSkipPwdPage)) {
        //免密场景下的兜底挽留也使用该样式弹窗
        if (retainUtilModel.hasInputHistory) {
            // 用户输入过密码则根据有没有下发功能挽留控制文案
            if ([retainInfo isfeatureRetain]) {
                retainInfoModel.title = retainInfo.recommendInfoModel.title;
            } else {
                retainInfoModel.title = CJPayLocalizedStr(@"确认放弃享受优惠？");
            }
        } else {
            retainInfoModel.title = retainUtilModel.retainInfo.title ?: CJPayLocalizedStr(@"确认放弃享受优惠？");
        }
            
        if (retainType == CJPayRetainTypeBonus) {
            retainInfoModel.voucherContent = retainInfo.retainMsgBonusStr;
            retainInfoModel.retainMsgModels = retainInfo.retainMsgBonusList;
        } else {
            retainInfoModel.voucherContent = retainInfo.retainMsgText;
            retainInfoModel.retainMsgModels = retainInfo.retainMsgTextList;
        }
        retainInfoModel.voucherType = retainInfo.voucherType;
            
        // 免密确认页降级至密码页，挽留弹窗需修改btn文案
        if ([model isSkipPwdDowngradeWithTradeNo:retainUtilModel.intergratedTradeNo]) {
            retainInfoModel.topButtonText = CJPayLocalizedStr(@"继续付款");
        }
            
        // 配置Button标题和action
        if ([retainInfo isfeatureRetain] && retainUtilModel.hasInputHistory) {
            retainInfoModel.topButtonText = retainInfo.recommendInfoModel.topRetainButtonText;
            retainInfoModel.bottomButtonText = retainInfo.recommendInfoModel.bottomRetainButtonText;
            retainInfoModel.topButtonBlock = otherVerifyBlock;
            retainInfoModel.bottomButtonBlock = confirmBlock;
        } else if (retainUtilModel.isTransform && retainInfo.showChoicePwdCheckWay) {
            // 交换两个Button的标题和action
            retainInfoModel.topButtonText = retainInfo.choicePwdCheckWayTitle;
            retainInfoModel.bottomButtonText = retainInfo.retainButtonText ?: CJPayLocalizedStr(@"继续付款");
            retainInfoModel.topButtonBlock = otherVerifyBlock;
            retainInfoModel.bottomButtonBlock = confirmBlock;
        } else {
            retainInfoModel.topButtonText = retainInfo.retainButtonText ?: CJPayLocalizedStr(@"继续付款");
            retainInfoModel.bottomButtonText = retainInfo.showChoicePwdCheckWay ? retainInfo.choicePwdCheckWayTitle : @"";
            retainInfoModel.topButtonBlock = confirmBlock;
            retainInfoModel.bottomButtonBlock = otherVerifyBlock;
        }
        
        retainInfoModel.closeCompletionBlock = closeBlock;
        CJPayPayCancelRetainViewController *retainVC = [[CJPayPayCancelRetainViewController alloc] initWithRetainInfoModel:retainInfoModel];
        retainVC.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet :UIModalPresentationOverFullScreen;
        [retainVC showMask:!retainUtilModel.isUseClearBGColor];

        if ([sourceVC isKindOfClass:CJPayBaseViewController.class]) {
            CJPayBaseViewController *sourceCurrentVC = (CJPayBaseViewController *)sourceVC;
            if ([sourceCurrentVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
                [CJPayCommonUtil cj_catransactionAction:^{
                    [((CJPayNavigationController *)sourceCurrentVC.navigationController) pushViewController:retainVC animated:YES];
                } completion:^{
                    CJ_CALL_BLOCK(completion, YES);
                }];
            } else {
                [retainVC presentWithNavigationControllerFrom:sourceVC useMask:YES completion:^{
                    CJ_CALL_BLOCK(completion, YES);
                }];
            }
        } else {
            [retainVC presentWithNavigationControllerFrom:sourceVC useMask:YES completion:^{
                CJ_CALL_BLOCK(completion, YES);
            }];
        }
        if (!retainUtilModel.notSumbitServerEvent) {
            [self p_notifyServerEventWith:retainUtilModel retainType:retainType];
        }
    } else {
        NSString *title = retainUtilModel.isHasVoucher ? CJPayLocalizedStr(@"继续支付可享受优惠，确定放弃吗") : CJPayLocalizedStr(@"还差一步就支付完成了，确定放弃吗");
        retainInfoModel.outPutActivityLabelForTrack = title;
        [CJPayAlertUtil customDoubleAlertWithTitle:title
                                     content:nil
                              leftButtonDesc:CJPayLocalizedStr(@"放弃")
                             rightButtonDesc:CJPayLocalizedStr(@"继续付款")
                             leftActionBlock:closeBlock
                             rightActioBlock:confirmBlock useVC:sourceVC];
    }
    NSString *retainTypeStr = [self p_getRetainTypeStrBy:retainType];
    NSString *positionStr = [self p_getPositionStrBy:retainUtilModel.positionType];
    [self p_trackRetainVCShowStatusWith:retainUtilModel retainType:retainTypeStr position:positionStr];
    // 弹窗展现埋点
    [retainInfoModel trackRetainPopUpWithEvent:retainUtilModel.eventNameForPopUpShow trackDelegate:retainUtilModel.trackDelegate extraParam:retainUtilModel.extraParamForPopUpShow];
    return YES;
}

+ (BOOL)couldShowLynxRetainVCWithSourceVC:(UIViewController *)sourceVC
                          retainUtilModel:(CJPayRetainUtilModel *)retainUtilModel
                               completion:(void (^)(BOOL))completion {
    
    if (retainUtilModel.retainInfoV2Config.notShowRetain) {
        //当notShowRetain 为 YES的时候不展示挽留弹窗
        return NO;
    }
    
    // 频控还是放在端上进行，若放到lynx不然会打开lynx页面又关闭，闪一下
    CJPayStayAlertForOrderModel *model = [CJPayKVContext kv_valueForKey:CJPayStayAlertShownKey];
    if (model && ![model shouldShowWithIdentifer:retainUtilModel.intergratedTradeNo]) { // 当笔订单已经展示过挽留弹窗，则不再展示
        return NO;
    }
    // 这里设置一个默认值，避免VC打开失败用户退不出去。在成功打开弹窗后，点击了发送了某个事件时会对其进行修改。
    [self p_trackRetainVCShowStatusWith:retainUtilModel retainType:@"retain_type_default" position:[self p_getPositionStrBy:retainUtilModel.positionType]];
    
    // lynx 打开挽留弹窗 场景上下文内容传通过字典传给前端处理。 所以将retainUtilModel.retainInfoV2Config中的属性传递到前端去。 事件也放到CJPayRetainUtil中处理
    // https://bytedance.feishu.cn/docx/AjV4d2SBgoUmCbxksKocc9xunke 验证流程 前端客户端交互
    // https://bytedance.feishu.cn/wiki/wikcnGOXd7JZKSoXkyhkEe7JWCb 标准收银台首页 前端客户端交互
    
    NSString *schema = retainUtilModel.retainInfoV2Config.retainSchema;
    NSDictionary *postFEParams = [retainUtilModel.retainInfoV2Config buildFEParams];
    
    CJPayPayCancelLynxRetainViewController *lynxRetainVC = [[CJPayPayCancelLynxRetainViewController alloc] initWithRetainInfo:postFEParams schema:schema];
    
    lynxRetainVC.eventBlock = ^(NSString * _Nonnull event, NSDictionary * _Nonnull data) {
        CJPayLynxRetainEventType eventType = [retainUtilModel obtainEventType:event];
        NSDictionary *extraData = [data cj_dictionaryValueForKey:@"extra_data"];
        NSString *retainTypeStr = [extraData cj_stringValueForKey:@"retain_type"];
        NSString *positionStr = [extraData cj_stringValueForKey:@"position"];
        
        BOOL openFail = [data cj_boolValueForKey:@"open_fail"];
        if (openFail) {
            // 当打开失败 进行埋点 判断场景
            [CJTracker event:@"walllet_rd_open_cjlynxcard_fail" params:@{}];
        }
        [self p_trackRetainVCShowStatusWith:retainUtilModel retainType:retainTypeStr position:positionStr];
        [self p_postNotificationToEveryPosition:eventType data:data];
        CJ_CALL_BLOCK(retainUtilModel.lynxRetainActionBlock, eventType, data);
    };
    
    [CJTracker event:@"wallet_rd_try_open_lynx_retain" params:@{}];
    
    
    [lynxRetainVC presentWithNavigationControllerFrom:sourceVC useMask:NO completion:^{
        CJ_CALL_BLOCK(completion, YES);
    }];
    
    return YES;
}

+ (void)p_postNotificationToEveryPosition:(CJPayLynxRetainEventType)eventType data:(NSDictionary *)data {
    if (eventType == CJPayLynxRetainEventTypeOnConfirm) {
        NSString *merchantVoucher = [[data cj_dictionaryValueForKey:@"tea_params"] cj_stringValueForKey:@"retain_voucher_msg" defaultValue:@""];
        [[NSNotificationCenter defaultCenter] postNotificationName:CJPayClickRetainPerformNotification object:merchantVoucher];
    }
}

+ (void)p_trackRetainVCShowStatusWith:(CJPayRetainUtilModel *)retainUtilModel retainType:(NSString *)retainTypeStr position:(NSString *)positionStr{
    CJPayStayAlertForOrderModel *model = [CJPayStayAlertForOrderModel new];
    model.tradeNo = retainUtilModel.intergratedTradeNo;
    model.hasShow = YES;
    NSDictionary *retainInfoDic = @{@"is_retained": @(YES), @"retain_type": CJString(retainTypeStr), @"position": CJString(positionStr)};
    model.userRetainInfo = @{@"user_retain_info": CJString([CJPayCommonUtil dictionaryToJson:retainInfoDic])};
    [CJPayKVContext kv_setValue:model forKey:CJPayStayAlertShownKey];
}

+ (void)p_notifyServerEventWith:(CJPayRetainUtilModel *)retainUtilModel retainType:(CJPayRetainType) realRetainType {
    NSMutableDictionary *serverEventDic = [NSMutableDictionary new];
    [serverEventDic cj_setObject:retainUtilModel.processInfoDic forKey:@"process_info"];
    [serverEventDic cj_setObject:@{@"retain_type": CJString([self p_getRetainTypeStrBy:realRetainType]),
                                   @"position": CJString([self p_getPositionStrBy:retainUtilModel.positionType]),
                                   @"retain_msg_bonus": CJString(retainUtilModel.retainInfo.retainMsgBonusStr),
                                   @"retain_msg_text": CJString(retainUtilModel.retainInfo.retainMsgText),
                                   @"show_retain_window": retainUtilModel.retainInfo.showRetainWindow ? @YES : @NO,
                                   @"title": CJString(retainUtilModel.retainInfo.title),
                                   @"retain_plan": CJString(retainUtilModel.retainInfo.retainPlan)
    } forKey:@"retain_info"];
    [serverEventDic cj_setObject:retainUtilModel.intergratedMerchantID forKey:@"merchant_id"];
    [[CJPayServerEventCenter defaultCenter] postEvent:@"retain_counter" intergratedMerchantId:retainUtilModel.intergratedMerchantID extra:[serverEventDic copy] completion:nil];
}

+ (NSString *)p_getRetainTypeStrBy:(CJPayRetainType)realRetainType {
    // 该字段根据是否是补贴挽留传的值不一样。
    NSString *retainTypeStr = @"retain_type_default";
    switch (realRetainType) {
        case CJPayRetainTypeBonus:
            retainTypeStr = @"retain_type_bonus";
            break;
        case CJPayRetainTypeText:
            retainTypeStr = @"retain_type_text";
            break;
        default:
            retainTypeStr = @"retain_type_default";
            break;
    }
    return retainTypeStr;
}

+ (NSString *)p_getPositionStrBy:(CJPayRetainPositionType)positionType {
    NSString *positionString = @"";
    switch (positionType) {
        case CJPayRetainHomePage:
            positionString = @"home_page";
            break;
        case CJPayRetainBiopaymentPage:
            positionString = @"biopayment_page";
            break;
        case CJPayRetainVerifyPage:
            positionString = @"verify_page";
            break;
        case CJPayRetainSkipPwdPage:
            positionString = @"nopwd_page";
            break;
        default:
            break;
    }
    return positionString;
}

+ (BOOL)needShowRetainPage:(CJPayRetainUtilModel *)retainUtilModel {
    CJPayBDRetainInfoModel *retainInfo = retainUtilModel.retainInfo;
    if (!(retainInfo && retainInfo.needVerifyRetain)) { // 服务端下发不应该展示挽留弹窗
        return NO;
    };
    
    CJPayStayAlertForOrderModel *model = [CJPayKVContext kv_valueForKey:CJPayStayAlertShownKey];
    if (model && ![model shouldShowWithIdentifer:retainUtilModel.intergratedTradeNo]) { // 当笔订单已经展示过挽留弹窗，则不再展示
        return NO;
    }
    return YES;
}

+ (NSString *)defaultLynxRetainSchema {
    return @"sslocal://webcast_lynxview?url=https%3A%2F%2Flf-webcast-sourcecdn-tos.bytegecko.com%2Fobj%2Fbyte-gurd-source%2F10181%2Fgecko%2Fresource%2Fcaijing_native_lynx%2Fmybankcard%2Frouter%2Ftemplate.js&page_name=keep_dialog_standard";
}

@end

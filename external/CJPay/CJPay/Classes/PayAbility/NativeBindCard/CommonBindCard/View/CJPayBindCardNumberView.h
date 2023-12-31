//
//  CJPayBindCardNumberView.h
//  Pods
//
//  Created by renqiang on 2021/7/2.
//

#import "CJPayBindCardNumberViewModel.h"
#import "CJPayBindCardFirstStepBaseInputView.h"

@class CJPayQuickBindCardModel;

typedef NS_ENUM(NSInteger, CJPayBindCardNumberViewShowType) {
    CJPayBindCardNumberViewShowTypeOriginal, //未获取焦点时展示样式
    CJPayBindCardNumberViewShowTypeOriginalShowBankCardVoucher, //未获取焦点，并展示特定X银行Y卡营销在下方
    CJPayBindCardNumberViewShowTypeOriginalNoAuth,    // 未实名用户样式
    CJPayBindCardNumberViewShowTypeCardInputFocus, // 输入卡信息展示样式
    CJPayBindCardNumberViewShowTypeShowPhoneInput,  // 输入手机号展示样式
    CJPayBindCardNumberViewShowTypeShowPhoneAuth,   // 展示手机号授权
    CJPayBindCardNumberViewShowTypeShowRecommendBank, //展示推荐银行卡
};
NS_ASSUME_NONNULL_BEGIN

@interface CJPayBindCardNumberView : CJPayBindCardFirstStepBaseInputView

#pragma mark - model
@property (nonatomic, weak) CJPayBindCardNumberViewModel *viewModel;
@property (nonatomic, assign, readonly) CJPayBindCardNumberViewShowType curShowType;
@property (nonatomic, assign) CJPayBindCardNumberViewShowType firstShowType;
@property (nonatomic, assign) BOOL isShowRecommendBanks; //输入卡号框下方是否展示推荐银行
@property (nonatomic, assign) BOOL isShowBankCardVoucher; //展示特定X银行Y卡营销

- (void)changeShowTypeTo:(CJPayBindCardNumberViewShowType)showType;
- (void)updateCardTipsAsVoucherMsgWithResponse:(CJPayMemBankSupportListResponse *)response;
- (void)updateCardTipsWithQuickBindCardModel:(CJPayQuickBindCardModel *)quickBindCardModel;
- (BOOL)isNotInput;

@end

NS_ASSUME_NONNULL_END


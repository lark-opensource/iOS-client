//
//  CJPayPasswordContentViewV2.h
//  CJPaySandBox
//
//  Created by xutianxi on 2023/03/01.
//

#import "CJPayUIMacro.h"
#import "CJPayVerifyPasswordViewModel.h"

NS_ASSUME_NONNULL_BEGIN

//@class CJPayVerifyPasswordViewModel;
@class CJPaySafeInputView;
@class CJPayChoosedPayMethodViewV3;
@class CJPayMarketingMsgView;
@class CJPayDeductDetailView;
@class CJPayErrorInfoActionView;
@class CJPayGuideWithConfirmView;
@class CJPayButton;
@class CJPayDefaultChannelShowConfig;
@class CJPayGuideWithConfirmView;
@class CJPayStyleButton;
//@protocol CJPayPasswordViewProtocol;

// 新样式验密页contentView

typedef NS_ENUM(NSUInteger, CJPayPasswordContentViewStatus) {
    CJPayPasswordContentViewStatusPassword = 0, // 高半屏形态，密码验证
    CJPayPasswordContentViewStatusLowConfirm = 1, // 矮半屏形态，生物、免密验证
    CJPayPasswordContentViewStatusOnlyAddCard = 2 // 新客卡片样式，仅绑卡
};

@interface CJPayPasswordContentViewV3 : UIView<CJPayPasswordViewProtocol>

@property (nonatomic, copy) void(^clickedPayMethodBlock)( NSString * _Nullable); //点击“切换支付方式”事件
@property (nonatomic, copy) void(^clickedCombinedPayBankPayMethodBlock)( NSString * _Nullable); //点击“切换支付方式”事件
@property (nonatomic, copy) void(^otherVerifyPayBlock)( NSString * _Nullable); //点击“切换验证方式”事件
@property (nonatomic, copy) void(^inputCompleteBlock)(NSString *); //密码输入完成事件
@property (nonatomic, copy) void(^confirmBtnClickBlock)(NSString *);//点击“确认按钮”事件
@property (nonatomic, copy) void(^clickedGuideCheckboxBlock)(BOOL); //点击支付中引导checkbox或switch的事件
@property (nonatomic, copy) void(^clickProtocolViewBlock)(void); //点击支付中引导协议区域的事件
@property (nonatomic, copy) void(^forgetPasswordBtnBlock)(NSString * _Nullable); //点击“忘记密码”事件（入参为忘记密码按钮文案）
@property (nonatomic, copy) void(^dynamicViewFrameChangeBlock)(CGRect); //动态布局区域frame变化事件（入参为新frame）

@property (nonatomic, copy) void(^didClickedMoreBankBlock)(void);
@property (nonatomic, copy) void(^didSelectedNewSuggestBankBlock)(int index);

@property (nonatomic, strong, readonly) CJPayMarketingMsgView *marketingMsgView; // 金额和营销展示UI
@property (nonatomic, strong, readonly) CJPayDeductDetailView *deductDetailView; // O项目 「签约信息前置」 签约信息区UI
@property (nonatomic, strong, readonly) CJPayChoosedPayMethodViewV3 *choosedPayMethodView; // 支付方式信息展示UI
@property (nonatomic, strong, readonly) UILabel *inputPasswordTitle; // 请输入支付密码
@property (nonatomic, strong, readonly) CJPaySafeInputView *inputPasswordView; // 密码输入框UI（仅高半屏样式展示）
@property (nonatomic, strong, readonly) CJPayErrorInfoActionView *errorInfoActionView;
@property (nonatomic, strong, readonly) CJPayGuideWithConfirmView *guideView; // 支付中引导UI（仅高半屏样式展示）
@property (nonatomic, strong, readonly) CJPayStyleButton *confirmButton; // 确认按钮UI（仅矮半屏、新客样式展示）
@property (nonatomic, assign, readonly) BOOL isPasswordVerifyStyle;

@property (nonatomic, assign) CJPayPasswordContentViewStatus status; //当前验密页V3的样式，默认为高半屏样式
@property (nonatomic, assign) BOOL isOnlySHowPasswordStyle; //强制仅展示密码验证（高半屏）样式

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel originStatus:(CJPayPasswordContentViewStatus)status;
// 更新当前选中的支付方式（UI展示）
- (void)updatePayConfigContent:(NSArray<CJPayDefaultChannelShowConfig *> *)configs;
- (void)usePasswordVerifyStyle:(BOOL)isPasswordVerifyStyle;
// 更新“支付方式UI组件”的显隐状态
- (void)updateChoosedPayMethodViewHiddenStatus:(BOOL)isHidden;
// 切换验密页形态
- (void)switchPasswordViewStatus:(CJPayPasswordContentViewStatus)status;
// 使用追光下单数据刷新验密页UI
- (void)refreshDynamicViewContent;
// 过高的情况下给签约信息详情页添加scroll
- (void)deductDetailViewNeedScroll:(BOOL)isNeedScroll deductDetailHeight:(CGFloat)deductScrollHeight;
// 新客样式下更新「签约信息前置」UI
- (void)updateDeductViewWhenNewCustomer:(CJPayDefaultChannelShowConfig *)config;
@end

NS_ASSUME_NONNULL_END

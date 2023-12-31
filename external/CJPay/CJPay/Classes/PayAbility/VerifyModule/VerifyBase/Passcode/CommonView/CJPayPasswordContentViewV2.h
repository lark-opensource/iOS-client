//
//  CJPayPasswordContentViewV2.h
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/30.
//

#import "CJPayUIMacro.h"
#import "CJPayVerifyPasswordViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySafeInputView;
@class CJPayChoosedPayMethodView;
@class CJPayMarketingMsgView;
@class CJPayErrorInfoActionView;
@class CJPayGuideWithConfirmView;
@class CJPayButton;
@class CJPayDefaultChannelShowConfig;
//@protocol CJPayPasswordViewProtocol;
// 新样式验密页contentView
@interface CJPayPasswordContentViewV2 : UIView<CJPayPasswordViewProtocol>

@property (nonatomic, copy) void(^clickedPayMethodBlock)( NSString * _Nullable); //点击“切换支付方式”事件
@property (nonatomic, copy) void(^forgetPasswordBtnBlock)(void); //点击“忘记密码”事件
@property (nonatomic, copy) void(^otherVerifyPayBlock)( NSString * _Nullable); //点击“切换验证方式”事件
@property (nonatomic, copy) void(^inputCompleteBlock)(NSString *); //密码输入完成事件
@property (nonatomic, copy) void(^confirmBtnClickBlock)(NSString *);//点击“确认按钮”事件

@property (nonatomic, strong, readonly) CJPayMarketingMsgView *marketingMsgView;
@property (nonatomic, strong, readonly) CJPayChoosedPayMethodView *choosedPayMethodView;
@property (nonatomic, strong, readonly) CJPaySafeInputView *inputPasswordView;
@property (nonatomic, strong, readonly) CJPayErrorInfoActionView *errorInfoActionView;
@property (nonatomic, strong, readonly) CJPayGuideWithConfirmView *guideView;
@property (nonatomic, strong, readonly) CJPayButton *forgetPasswordBtn;

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel;
// 更新当前选中的支付方式（UI展示）
- (void)updatePayConfigContent:(NSArray<CJPayDefaultChannelShowConfig *> *)configs;
- (void)updateForChoosedPayMethod:(BOOL)isHidden;

@end

NS_ASSUME_NONNULL_END

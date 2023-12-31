//
//  CJPayHalfVerifyPasswordV3ViewController.h
//  Pods
//
//  Created by xutianxi on 2023/03/01.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayVerifyPasswordViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBaseVerifyManager;
@class CJPayPasswordContentViewV3;
@protocol CJPayChooseDyPayMethodDelegate;

@interface CJPayHalfVerifyPasswordV3ViewController : CJPayHalfPageBaseViewController

@property (nonatomic, strong, readonly) CJPayVerifyPasswordViewModel *viewModel;
@property (nonatomic, strong) CJPayPasswordContentViewV3 *passwordContentView;
@property (nonatomic, strong, readonly) CJPayButton *otherVerifyButton;

@property (nonatomic, copy) void(^otherVerifyPayBlock)(CJPayPasswordSwitchOtherVerifyType);
@property (nonatomic, copy) void(^inputCompleteBlock)(NSString *);//输完密码，入参为密码
@property (nonatomic, copy) void(^forgetPasswordBtnBlock)(void); //忘记密码按钮点击事件

@property (nonatomic, strong) CJPayBDCreateOrderResponse *response;
@property (nonatomic, weak) CJPayBaseVerifyManager *verifyManager;
@property (nonatomic, weak) id<CJPayChooseDyPayMethodDelegate> changeMethodDelegate; //“更改选中的支付方式”代理
@property (nonatomic, assign) CJPayPasswordSwitchOtherVerifyType otherVerifyType; //右上角按钮对应的验证方式
@property (nonatomic, assign) BOOL isSimpleVerifyStyle; //简化版密码验证页样式，隐藏支付方式，密码切生物时直接拉起生物验证组件
@property (nonatomic, assign) int selectedSuggestIndex; // 选中的推荐卡

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel;
- (void)reset;
- (void)showLoadingStatus:(BOOL)isLoading; // 根据当前loading显隐态来更新页面UI
- (void)updateErrorText:(NSString *)text; // 输错密码后更新错误文案
- (void)showKeyBoardView; // 展示键盘
- (void)retractKeyBoardView;  // 收起键盘
- (void)updateOtherVerifyType:(CJPayPasswordSwitchOtherVerifyType)verifyType btnText:(NSString *)text; // 更新右上角切换验证方式按钮的验证类型和文案
- (void)switchToPasswordVerifyStyle:(BOOL)isPasswordVerifyStyle;
- (void)switchToPasswordVerifyStyle:(BOOL)isPasswordVerifyStyle showPasswordVerifyKeyboard:(BOOL)isShowPasswordVerifyKeyboard; // 切换验密页的高矮形态，isPasswordVerifyStyle=YES则切换为高半屏，否则切换为矮半屏
- (void)updateChoosedPayMethodWhenBindCardPay;
- (void)gotoChooseCardList;

@end

NS_ASSUME_NONNULL_END

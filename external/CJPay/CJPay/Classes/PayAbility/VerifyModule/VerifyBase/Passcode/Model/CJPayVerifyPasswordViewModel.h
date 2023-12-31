//
//  CJPayVerifyPasswordViewModel.h
//  Pods
//
//  Created by chenbocheng on 2022/3/30.
//

#import <Foundation/Foundation.h>
#import "CJPayBDCreateOrderResponse.h"
#import "CJPaySafeInputView.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPayErrorInfoActionView.h"
#import "CJPayMarketingMsgView.h"
#import "CJPayVerifyPassVCConfigModel.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayTrackerProtocol.h"
#import "CJPayChannelBizModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayHalfPageBaseViewController;
@class CJPayVerifyItemRecogFaceOnBioPayment;
@class CJPayForgetPwdOptController;

// 支付方式类型
typedef NS_ENUM(NSInteger, CJPayPasswordSwitchOtherVerifyType) {
    CJPayPasswordSwitchOtherVerifyTypeBio = 0, //展示面容/指纹验证
    CJPayPasswordSwitchOtherVerifyTypeRecogFace = 1 //展示刷脸验证
};

// passwordContentView需遵守的协议，抹平V2、V3的对外差异（passwordV2使用V3视图期间过渡使用，后期删）
@protocol CJPayPasswordViewProtocol <NSObject>

- (void)showKeyBoardView; // 拉起键盘
- (void)retractKeyBoardView;  // 收起键盘
- (void)clearPasswordInput; // 清除密码输入
- (void)updatePayConfigContent:(NSArray<CJPayDefaultChannelShowConfig *> *)configs; // 更新支付方式信息
- (void)updateErrorText:(NSString *)text; // 更新输错密码提示文案
- (void)setPasswordInputAllow:(BOOL)isAllow; // 是否允许键盘输入
- (BOOL)hasInputHistory; // 是否输入过密码

@end

@interface CJPayVerifyPasswordViewModel : NSObject

@property (nonatomic, copy) void(^forgetPasswordBtnBlock)(void); //忘记密码点击事件
@property (nonatomic, copy) void(^otherVerifyPayBlock)( NSString * _Nullable); //其他验证方式点击事件（O项目场景的密码->生物切换不走此block）
@property (nonatomic, copy) void(^inputChangeBlock)(NSString *);
@property (nonatomic, copy) void(^inputCompleteBlock)(NSString *);//输完密码，入参为密码
@property (nonatomic, copy) void(^faceRecogPayBlock)(NSString *); // 刷脸支付的能力

@property (nonatomic, weak) id<CJPayTrackerProtocol> trackDelegate;// 埋点上报代理
@property (nonatomic, strong) CJPayBDCreateOrderResponse *response; //追光下单参数
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *defaultConfig; // 当前选中的支付方式
@property (nonatomic, copy) NSArray<CJPayDefaultChannelShowConfig *> *displayConfigs; // 首次进入验密页（V2、V3样式）时展示的支付方式信息（仅作展示用）
@property (nonatomic, assign) BOOL hideChoosedPayMethodView; //是否强制隐藏“切换支付方式”UI组件（无论后端是否下发对应数据字段）
@property (nonatomic, assign) BOOL cancelRetainWindow; //取消挽留弹窗
@property (nonatomic, assign) BOOL hideMerchantNameLabel; //强制不显示商户信息
@property (nonatomic, assign) BOOL hideMarketingView; //强制不显示金额和营销信息
@property (nonatomic, assign) BOOL hidePasswordFixedTips; //强制不显示密码输入提示文案

@property (nonatomic, strong) CJPayVerifyPassVCConfigModel *configModel; //极速支付触发密码加验时的降级提示
@property (nonatomic, strong) CJPayForgetPwdOptController *forgetPwdController; //忘记密码跳转VC
@property (nonatomic, strong) CJPayOutDisplayInfoModel *outDisplayInfoModel; // O项目「签约信息前置」 签约详情信息

@property (nonatomic, assign) NSInteger passwordInputCompleteTimes; // 密码输入完成的次数
@property (nonatomic, assign) NSInteger confirmBtnClickTimes; // 确认按钮点击次数
@property (nonatomic, assign) BOOL isGuideSelected; // 是否勾选支付中引导
@property (nonatomic, assign) BOOL isFromOpenBioPayVerify; //标志页面由生物识别标准开通流程持有&&支持活体验证的方式开通
@property (nonatomic, assign) BOOL isStillShowingTopRightBioVerifyButton; //右上角按钮强制展示“生物验证”（从生物验证主动降级为密码时使用）
@property (nonatomic, assign) BOOL isPaymentForOuterApp; // 标识是否为端外支付;
@property (nonatomic, strong) CJPayVerifyItemRecogFaceOnBioPayment *bioVerifyItem; //生物识别标准开通流程中的活体验证方式
@property (nonatomic, assign) CGFloat passwordViewHeight; //验密页高度
@property (nonatomic, copy) NSString *downgradePasswordTips; // 降级为密码验证时的提示文案
@property (nonatomic, copy) NSString *passwordFixedTips; // 验密页常驻提示文案

@property (nonatomic, assign) BOOL isDynamicLayout; // 是否自适应高度（动态布局）
@property (nonatomic, assign) BOOL canChangeCombineStatus; // 是否可变更组合支付状态
@property (nonatomic, assign) BOOL isStillShowForgetBtn; // 是否强制固定展示”忘记密码按钮“

//下述UI组件仅在V1样式验密页使用
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) CJPaySafeInputView *inputPasswordView;
@property (nonatomic, strong) CJPayErrorInfoActionView *errorInfoActionView;
@property (nonatomic, strong) CJPayButton *otherVerifyButton;
@property (nonatomic, strong) CJPayButton *forgetPasswordBtn;
@property (nonatomic, strong) CJPayMarketingMsgView *marketingMsgView;

// 跳转忘记密码
- (void)gotoForgetPwdVCFromVC:(CJPayHalfPageBaseViewController *)sourceVC;
- (void)gotoForgetPwdVCFromVC:(CJPayHalfPageBaseViewController *)sourceVC completion:(nullable void(^)(BOOL))completion;
// 更新错误文案（仅V1样式使用）
- (void)updateErrorText:(NSString *)text withTypeString:(NSString *)type currentVC:(UIViewController *)vc;
// 首次展示埋点上报（仅V1样式使用）
- (void)pageFirstAppear;
// 按钮点击埋点
- (void)trackPageClickWithButtonName:(NSString *)buttonName;
- (void)trackPageClickWithButtonName:(NSString *)buttonName params:(NSDictionary *)params;
// 通用埋点上报
- (void)trackWithEventName:(NSString *)eventName params:(NSDictionary *)params;
// 清空输入框、隐藏错误提示
- (void)reset;
- (void)setShowKeyBoardSafeGuard:(BOOL)isShow;
// 降级文案（仅V1样式使用）
- (NSString *)tipText;
// 后端下发默认支付方式是否为组合支付（不代表当前支付方式的组合状态）
- (BOOL)isCombinedPay;
// 判断是否需要展示支付中引导
- (BOOL)isNeedShowGuide;
// 判断是否需要展示支付中生物开通引导
- (BOOL)isNeedShowOpenBioGuide;
// 判断支付中引导是否需要展示确认按钮
- (BOOL)isShowComfirmButton;
// 判断当前支付方式是否需要补签约
- (BOOL)isNeedResignCard;
// 是否展示“选择支付方式”UI组件
- (BOOL)isNeedShowChooseMethodView;
// “忘记密码”按钮是否固定展示
- (BOOL)isNeedShowFixForgetButton;
// 是否展示“输入密码提示文案”
- (BOOL)isNeedShowPasswordFixedTips;
// 默认支付方式的营销信息（埋点用）
- (NSString *)trackActivityLabel;
- (NSString *)isFingerprintDefault;
// 判断生物引导类型
- (NSString *)getBioGuideType;
- (NSString *)getBioGuideTypeStr;

// O 项目新客推荐卡样式相关
- (BOOL)isSuggestCardStyle;
- (BOOL)isHasSuggestCard;
- (NSArray <CJPayChannelBizModel *>*)getSuggestChannelModelList;
- (CJPayDefaultChannelShowConfig *)getSuggestChannelByIndex:(int)index;

@end

NS_ASSUME_NONNULL_END

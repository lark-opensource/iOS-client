//
//  CJPayHalfVerifyPasswordV2ViewController.h
//  Pods
//
//  Created by 徐天喜 on 2022/11/19.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayVerifyPasswordViewModel.h"

NS_ASSUME_NONNULL_BEGIN


@class CJPayBaseVerifyManager;
@class CJPayPasswordContentViewV2;
@class CJPayPasswordContentViewV3;
@protocol CJPayChooseDyPayMethodDelegate;

@interface CJPayHalfVerifyPasswordV2ViewController : CJPayHalfPageBaseViewController

@property (nonatomic, strong, readonly) CJPayVerifyPasswordViewModel *viewModel;
@property (nonatomic, strong) CJPayPasswordContentViewV2 *passwordContentView;
@property (nonatomic, strong) CJPayPasswordContentViewV3 *commonPasswordContentView; //动态化布局期间，V2样式与V3样式共用验密页视图（过渡用）

@property (nonatomic, strong, readonly) CJPayButton *otherVerifyButton;

@property (nonatomic, copy) void(^otherVerifyPayBlock)(CJPayPasswordSwitchOtherVerifyType);
@property (nonatomic, copy) void(^forgetPasswordBtnBlock)(void);
@property (nonatomic, copy) void(^inputCompleteBlock)(NSString *);//输完密码，入参为密码
@property (nonatomic, strong) CJPayBDCreateOrderResponse *response;
@property (nonatomic, weak) CJPayBaseVerifyManager *verifyManager;
@property (nonatomic, weak) id<CJPayChooseDyPayMethodDelegate> changeMethodDelegate; //“更改选中的支付方式”代理
@property (nonatomic, assign) CJPayPasswordSwitchOtherVerifyType otherVerifyType; //右上角按钮对应的验证方式
@property (nonatomic, assign) BOOL isChoosePayTypeDataReady;
@property (nonatomic, copy) NSString *bioDowngradeToPassscodeReason;//生物降级密码验证原因，用于埋点

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel;
- (void)reset;
- (void)updateErrorText:(NSString *)text; // 输错密码后更新错误文案
- (void)showKeyBoardView; // 拉起键盘
- (void)retractKeyBoardView;  // 收起键盘
- (void)updateOtherVerifyType:(CJPayPasswordSwitchOtherVerifyType)verifyType btnText:(NSString *)text; // 更新右上角切换验证方式按钮的验证类型和文案
- (void)changePayMethodWithPayType:(CJPayChannelType)payType bankCardId:(NSString *)bankCardId; // 外部（非六位密码选卡页）更改当前选中的支付方式

- (UIView<CJPayPasswordViewProtocol> *)getPasswordContentView;
@end

NS_ASSUME_NONNULL_END

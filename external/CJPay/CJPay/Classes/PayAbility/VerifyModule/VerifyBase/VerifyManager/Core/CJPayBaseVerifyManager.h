//
//  CJPayBaseVerifyManager.h
//  CJPay
//
//  Created by 王新华 on 10/10/19.
//

#import <Foundation/Foundation.h>
#import "CJPayVerifyManagerHeader.h"
#import "CJPayVerifyItem.h"
#import "CJPayHomeVCProtocol.h"
#import "CJPayBaseVerifyManagerQueen.h"

NS_ASSUME_NONNULL_BEGIN

//密码页面样式
typedef NS_ENUM(NSUInteger, CJPayDouPayPwdPageStyle) {
    CJPayDouPayPwdPageStyleNone = 0, // 默认不设置，根据后端数据决策
    CJPayDouPayPwdPageStyleV3,       // v3追光唤端样式（支持切换支付方式）
    CJPayDouPayPwdPageStyleV2,       // v2样式（支持切换支付方式）
    CJPayDouPayPwdPageStyleV1,       // v1样式
};

@class CJPayBindCardResultModel;
@class CJPayBaseVerifyManagerQueen;
@protocol CJPayChooseDyPayMethodDelegate;
@interface CJPayBaseVerifyManager : NSObject<CJPayWakeVerifyItemProtocol, CJPayVerifyManagerEventFlowProtocol, CJPayVerifyManagerRequestProtocol, CJPayVerifyManagerPayNewCardProtocol, CJPayBaseLoadingProtocol>

@property (nonatomic, weak) id<CJPayHomeVCProtocol> homePageVC;
@property (nonatomic, weak) id<CJPayChooseDyPayMethodDelegate> changePayMethodDelegate;

@property (nonatomic, strong, readonly) CJPayBDCreateOrderResponse *response;
@property (nonatomic, strong, readonly) CJPayOrderConfirmResponse *confirmResponse;
@property (nonatomic, strong, readonly) CJPayDefaultChannelShowConfig *defaultConfig;
@property (nonatomic, strong, readonly) CJPayBDOrderResultResponse *resResponse;
@property (nonatomic, strong, readonly) CJPayVerifyItem *lastConfirmVerifyItem;
@property (nonatomic, strong, readonly) CJPayVerifyItem *lastWakeVerifyItem;
@property (nonatomic, strong) CJPayVerifyItem *lastHandleVerifyItem;
@property (nonatomic, strong, nullable) CJPayBaseVerifyManagerQueen *verifyManagerQueen;
@property (nonatomic, copy) NSString *from;
@property (nonatomic, assign, readonly) CJPayVerifyType lastVerifyType;
@property (nonatomic, copy) NSDictionary *bizParams;
@property (nonatomic, copy) NSString *bizUrl;
@property (nonatomic, copy) NSString *lastPWD; // 开通指纹需要传递该参数
@property (nonatomic, assign) BOOL disableBioPay; // 是否禁用指纹面容支付
@property (nonatomic, weak) id<CJPayBaseLoadingProtocol> loadingDelegate;
@property (nonatomic, assign) BOOL isNeedShowBioTips; //是否在支付结果页展示开通指纹支付tips
@property (nonatomic, strong, readonly) NSMutableArray *verifyTypeArray;
@property (nonatomic, assign) BOOL isOneKeyQuickPay; // 是否是极速支付
@property (nonatomic, copy) void(^signCardStartLoadingBlock)(void); //补签约接口loading样式，不实现走默认confirmbtn loading逻辑
@property (nonatomic, copy) void(^signCardStopLoadingBlock)(void);
@property (nonatomic, assign) BOOL isNeedOpenBioPay; //支付中引导生物识别，是否选中要开通
@property (nonatomic, assign) BOOL isSkipPWDForbiddenOpt; //免密禁用后点击直接开启指纹/面容支付，不显示支付页
@property (nonatomic, assign) BOOL isStandardDouPayProcess; // 是否是抖音支付标准化流程
@property (nonatomic, assign) CJPayDouPayPwdPageStyle pwdPageStyle;

@property (nonatomic, assign) BOOL isNotSufficient;

@property (nonatomic, assign) BOOL isPaymentForOuterApp; // 是否是端外支付

@property (nonatomic, assign, readonly) BOOL isBindCardAndPay;
@property (nonatomic, strong) CJPayBindCardResultModel *bindcardResultModel;

@property (nonatomic, copy) void(^bindCardStartLoadingBlock)(void);
@property (nonatomic, copy) void(^bindCardStopLoadingBlock)(void);
@property (nonatomic, copy) NSString *token;

@property (nonatomic, assign) BOOL notStopLoading;//聚合结果页查单时候，延长loading
@property (nonatomic, assign) BOOL hasChangeSelectConfigInVerify; // 标记是否在验证过程中更改了选中支付方式
@property (nonatomic, copy) NSDictionary *trackInfo;

@property (nonatomic, assign) BOOL isSkipConfirmRequest; // 标记是否跳过确认支付请求（用于下单时已拿到确认支付结果的场景，例如免密接口合并）
@property (nonatomic, assign) BOOL isSkipPwdSelected;//支付中免密引导是否勾选

+ (instancetype)managerWith:(id<CJPayHomeVCProtocol>)homePageVC;
+ (instancetype)managerWith:(id<CJPayHomeVCProtocol>)homePageVC withVerifyItemConfig:(NSDictionary *)verifyItemConfig;

- (nullable CJPayVerifyItem *)getSpecificVerifyType:(CJPayVerifyType)type;// 获取指定的验证方式
// 验证组件使用
- (NSDictionary *)buildConfirmRequestParamsByCurPayChannel;
- (BOOL)needInvokeLoginAndReturn:(CJPayBaseResponse *)response;
- (BOOL)sendEventTOVC:(CJPayHomeVCEvent)event obj:(id)object;
- (void)useLatestResponse;

//根据userInfo.pwdCheckWay获取验证方式
- (CJPayVerifyType)getVerifyTypeWithPwdCheckWay:(NSString *)pwdCheckWay;

- (NSString *)allRiskVerifyTypes;
- (NSString *)lastVerifyCheckTypeName;
- (NSString *)issueCheckType;
/// 其他查单参数
- (NSDictionary *)otherExtsParamsForQueryOrder;
- (void)exitBindCardStatus; //验证过程中选择绑卡，绑卡成功但支付失败时，需处理isBindCardAndPay状态
@end

NS_ASSUME_NONNULL_END

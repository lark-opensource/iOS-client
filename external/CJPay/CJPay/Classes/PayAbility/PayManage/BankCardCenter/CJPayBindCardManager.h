//
//  CJPayBindCardManager.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/24.
//

#import <Foundation/Foundation.h>
#import "CJPayBindCardSharedDataModel.h"
#import "CJPaySettings.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^BDPayBindCardCompletion)(CJPayBindCardResult type, NSString *errorMsg);

@class CJPayBankCardModel;

@interface CJPayBindCardManager : NSObject

//bindCard jsb收到调用后结束loading
@property (nonatomic, copy) void(^stopLoadingBlock)(void);
//Lynx我的银行卡绑卡成功事件
@property (nonatomic, copy) void(^bindCardSuccessBlock)(void);
//smsVerify jsb验证成功
@property (nonatomic, copy) void(^verifySMSCompletionBlock)(void);

+ (instancetype)sharedInstance;

/**
 * 打开银行卡列表
 * merchantId:      财经侧分配给业务方
 * appId:           财经侧分配给业务方
 * userId:          业务方用户的uid
 **/
- (void)openBankCardListWithMerchantId:(NSString *)merchantId
                                 appId:(NSString *)app
                                userId:(NSString *)userId;

/*!
 绑卡流程
 @discussion 绑卡前需要有预下单流程，调用该API，需要自己展示loading态卡住用户操作
 @param commonModel     绑卡流程通用model
 */
- (void)bindCardWithCommonModel:(CJPayBindCardSharedDataModel *)commonModel;
//独立绑卡
- (void)onlyBindCardWithCommonModel:(CJPayBindCardSharedDataModel *)commonModel
                             params:(NSDictionary *)params
                         completion:(BDPayBindCardCompletion)completion
                   stopLoadingBlock:(void(^)(void))stopLoadingBlock;
- (void)pushVC:(UIViewController *)vc commonModel: (CJPayBindCardSharedDataModel *)bindCardCommonModel;

- (void)gotoThrottleViewController:(BOOL)needRemoveSelf
                            source:(NSString *)source
                             appId:(NSString *)appId
                        merchantId:(NSString *)merchantId;

//Lynx我的银行卡jsb调用
- (void)createNormalOrderAndSendSMS:(NSDictionary *)param;
//native我的银行卡调用
- (void)createNormalOrderAndSendSMSWithModel:(CJPayBankCardModel *)cardModel
                                       appId:(NSString *)appId
                                  merchantId:(NSString *)merchantId;
- (BOOL)isLynxReady;

@end

typedef NS_ENUM(NSUInteger, CJPayBindCardPageType) {
    CJPayBindCardPageTypeUnknow = 0,
    // 普通绑卡
    CJPayBindCardPageTypeCommonQuickFrontFirstStep,
    CJPayBindCardPageTypeCommonFourElements,
    // 一键绑卡
    CJPayBindCardPageTypeQuickBindList = 21,
    CJPayBindCardPageTypeQuickAuthVerify,
    CJPayBindCardPageTypeQuickChooseCard,
    // 云闪付绑卡
    CJPayBindCardPageTypeUnionAccredit = 31,
    CJPayBindCardPageTypeUnionChooseCard,
    // 授权页
    CJPayBindCardPageTypeHalfBizAuth = 41,
    // 半屏验短信页
    CJPayBindCardPageTypeHalfVerifySMS = 51,
    // 设置密码第一步页面
    CJPayBindCardPageSetPWDFirstStep = 71
};

// 绑卡流程内部使用方法
@interface CJPayBindCardManager (bindCardInner)

- (CJPayJHInformationConfig *)getJHConfig;

- (void)enterUnionBindCardAndCreateOrderWithFromVC:(UIViewController *)fromVC
                                   completionBlock:(nonnull void (^)(BOOL isOpenedSuccess, UIViewController *firstVC))completionBlock;

- (UIViewController *)openPage:(CJPayBindCardPageType)pageType
                        params:(nullable NSDictionary <NSString *, id> *)params
                    completion:(nullable void(^)(BOOL isOpenedSuccessed, NSString *errMsg))completionBlock;

- (void)modifySharedDataWithDict:(NSDictionary <NSString *, id>*)dict
                      completion:(nullable void(^)(NSArray <NSString *> *modifyedKeysArray))modifyedCompletionBlock;

- (BOOL)cancelBindCard;

- (BOOL)finishBindCard:(CJPayBindCardResultModel *)resultModel
         completionBlock:(void(^_Nullable)(void))completionBlock;

- (void)addPageTypeMaps:(NSDictionary *)dictionary;
// track event
- (NSDictionary *)bindCardTrackerBaseParams;
- (NSString *)bindCardTrackerSource;
- (void)setEntryName:(NSString *)entryName;
- (NSString *)bindCardTeaSource;

@end

NS_ASSUME_NONNULL_END

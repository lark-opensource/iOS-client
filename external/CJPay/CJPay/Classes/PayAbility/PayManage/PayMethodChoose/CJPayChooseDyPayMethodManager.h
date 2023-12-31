//
//  CJPayChooseDyPayMethodManager.h
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/19.
//

#import <Foundation/Foundation.h>
#import "CJPayEnumUtil.h"
#import "CJPaySDKDefine.h"
#import "CJPayTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayDefaultChannelShowConfig;
@class CJPayBDCreateOrderResponse;
@class CJPayFrontCashierContext;

@protocol CJPayChooseDyPayMethodDelegate <NSObject>

// 更改选中的支付方式
- (void)changePayMethod:(CJPayFrontCashierContext *_Nonnull)payContext loadingView:(UIView *_Nullable)view;

@optional
// 发起补签约流程，实现此代理方法则不回调changePayMethod方法，未实现此代理方法，会兜底回调changePayMethod方法
- (void)signPayWithPayContext:(CJPayFrontCashierContext *_Nonnull)payContext loadingView:(UIView *_Nullable)view;
// 展示选卡页
- (void)pushChoosePayMethodVC:(UIViewController *)vc animated:(BOOL)animated;
// 组合支付选择组合的银行卡
- (void)changeCombinedBankPayMethod:(CJPayFrontCashierContext *_Nonnull)payContext loadingView:(UIView *_Nullable)view;;
// 埋点
- (void)trackEvent:(NSString *_Nonnull)event params:(NSDictionary *_Nullable)params;
// 获取payContext.extParams
- (NSDictionary *)payContextExtParams;
// 获取支付方式不可用及原因的记录
- (NSDictionary *)getPayDisabledReasonMap;

@end

@class CJPayChooseDyPayMethodGroupModel;
@interface CJPayChooseDyPayMethodManager : NSObject

@property (nonatomic, weak) id<CJPayChooseDyPayMethodDelegate> delegate;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *response;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *curSelectConfig; //当前选中的支付方式

@property (nonatomic, assign) BOOL needUpdatePayMethodList; //标识是否需要请求queryPayType
@property (nonatomic, assign) BOOL isSignPayPosition; // 标记是签约代扣场景使用的Manager
@property (nonatomic, assign) BOOL isCombinePay; //标识是否是组合支付
@property (nonatomic, assign) BOOL closeChoosePageAfterChangeMethod; //更改支付方式后是否关闭选卡页
@property (nonatomic, assign) CGFloat height; //调用方可指定选卡页高度
@property (nonatomic, assign) BOOL hasChangePayMethod; // 标识是否切换过支付方式

@property (nonatomic, assign) CGFloat payMethodViewHeight; //设定选卡页高度
@property (nonatomic, strong) NSMutableDictionary *payMethodDisabledReasonMap; //支付方式不可用原因list
@property (nonatomic, assign) BOOL isNotCloseChooseVCWhenBindCardSuccess; // 绑卡成功不关闭卡列表页，默认为NO（绑卡成功自动关闭卡列表页）

// 初始化方法
- (instancetype)initWithOrderResponse:(CJPayBDCreateOrderResponse *)response;

- (void)setSelectedBalancePayMethod;
- (void)setSelectedPayMethod:(CJPayDefaultChannelShowConfig *)config;

// 前往卡列表页
- (void)gotoChooseDyPayMethod;

// 前往O项目唤端支付的选卡页
- (void)gotoSignPayChooseDyPayMethod;

- (void)closeSignPayChooseDyPayMethod;

// 从组合支付银行卡前往卡列表页
- (void)gotoChooseDyPayMethodFromCombinedPay:(BOOL)isCombinedPay;

/// 获取支付方式列表数据
/// - Parameters:
///   - needSlient: 是否静默请求（展示loading和toast）
///   - completionBlock: 完成回调
- (void)getPayMethodListSlient:(BOOL)needSlient
                    completion:(nullable void(^)(NSArray<CJPayChooseDyPayMethodGroupModel *> *))completionBlock;

// 埋点上报
- (void)trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params;
//注意会更新delegate的选中支付方式
- (void)didSelectPayMethod:(CJPayDefaultChannelShowConfig *)showConfig loadingView:(UIView *_Nullable)loadingView;
- (void)refreshPayMethodSelectStatus:(CJPayDefaultChannelShowConfig *)config;

@end

NS_ASSUME_NONNULL_END

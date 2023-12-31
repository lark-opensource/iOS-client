//
//  CJPayPerformanceTracker.h
//  Pods
//
//  Created by 王新华 on 2021/10/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * CJPayPerformanceAPISceneKey;
extern CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneStandardPayDeskKey;// 标准收银台
extern CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneEcommercePayDeskKey;// 电商收银台
extern CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneBalanceWithdrawPayDeskKey; // 余额提现
extern CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneBalanceRechargePayDeskKey; // 余额充值
extern CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneBindCardKey; // 余额充值
extern CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneOwnPayKey; // 自有支付
extern CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneBankCardList; // 银行卡列表
extern CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneOuterPay; // 端外充值

#define CJPayPerformanceMonitor [CJPayPerformanceTracker shared]


@interface CJPayPerformanceTracker : NSObject

@property (nonatomic, assign, class) BOOL trackAllStages; // 默认会忽略不在采集规则中的点，优化内存问题，可以通过设置该字段，放开限制。

+ (CJPayPerformanceTracker * _Nullable)shared;

- (void)trackAPIStartWithAPIScene:(CJPayPerformanceAPISceneKey)sceneKey extra:(NSDictionary *)extra;
- (void)trackAPIEndWithAPIScene:(CJPayPerformanceAPISceneKey)sceneKey extra:(NSDictionary *)extra;

- (void)trackRequestStartWithAPIPath:(NSString *)apiPath extra:(NSDictionary *)extra;
- (void)trackRequestEndWithAPIPath:(NSString *)apiPath extra:(NSDictionary *)extra;

- (void)trackPageInitWithVC:(UIViewController *)vc extra:(NSDictionary *)extra;
- (void)trackPageAppearWithVC:(UIViewController *)vc extra:(NSDictionary *)extra;
- (void)trackPageFinishRenderWithVC:(UIViewController *)vc name:(NSString *)name extra:(NSDictionary *)extra ;
- (void)trackPageDisappearWithVC:(UIViewController *)vc extra:(NSDictionary *)extra;
- (void)trackPageDeallocWithVC:(UIViewController *)vc extra:(NSDictionary *)extra;

- (void)trackBtnActionWithBtn:(UIButton *)btn target:(id)target extra:(NSDictionary *)extra;
- (void)trackCellActionWithTableViewCell:(UITableViewCell *)cell extra:(NSDictionary *)extra;
- (void)trackGestureActionWithGesture:(UIGestureRecognizer *)gesture extra:(NSDictionary *)extra;

@end

@class CJPayPerformanceStage;
@class CJPayPerformanceUploadRule;
@interface CJPayPerformanceTracker(Upload)

- (void)p_syncStageToList:(CJPayPerformanceStage *)stage;
- (void)p_uploadEventList;

- (void)debug_notifyProcessSucess:(NSArray<CJPayPerformanceStage *> *)stageList rules:(NSArray<CJPayPerformanceUploadRule *> *)rules; // 供hook使用

@end

NS_ASSUME_NONNULL_END

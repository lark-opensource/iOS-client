//
//  CJPayECController.h
//  Pods
//
//  Created by wangxiaohong on 2020/11/15.
//

#import <Foundation/Foundation.h>
#import "CJPayHomeVCProtocol.h"
#import "CJPayManagerDelegate.h"

@class CJPayFrontCashierContext;
@class CJPayNavigationController;

NS_ASSUME_NONNULL_BEGIN

// 前置收银台使用场景
typedef NS_ENUM(NSInteger, CJPayCashierScene) {
    CJPayCashierSceneEcommerce = 0,   // 电商场景（电商收银台）
    CJPayCashierScenePreStandard = 1,   // 非电商场景（标准前置收银台）
};

@class CJPayECVerifyManager;

@interface CJPayECController : NSObject<CJPayBaseLoadingProtocol>

@property (nonatomic, strong) CJPayECVerifyManager *verifyManager;
@property (nonatomic, strong) CJPayFrontCashierContext *payContext;
@property (nonatomic, strong, readonly) CJPayNavigationController *navigationController;
@property (nonatomic, assign, readonly) CJPayCashierScene cashierScene; //标识前置收银台使用场景

- (void)startPaymentWithParams:(NSDictionary *)params completion:(void (^)(CJPayManagerResultType type, NSString *errorMsg))completion;
- (BOOL)isNewVCBackWillExistPayProcess;
- (BOOL)topVCIsCJPay;

// 返回给电商的性能统计，时间戳
- (NSDictionary *)getPerformanceInfo;

@end

NS_ASSUME_NONNULL_END

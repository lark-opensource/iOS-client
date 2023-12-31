//
//  CJPayIntegratedCashierProcessManager.h
//  CJPay
//
//  Created by wangxinhua on 2020/8/6.
//

#import <Foundation/Foundation.h>
#import "CJPayCreateOrderResponse.h"
#import "CJPayHomePageViewController.h"
#import "CJPayBaseResponse.h"
#import "CJPayUserInfo.h"
#import "CJPayImageLabelStateView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayIntegratedCashierProcessManager : NSObject

@property (nonatomic, weak) CJPayHalfPageBaseViewController<CJPayIntegratedCashierHomeVCProtocol> *homeVC;
@property (nonatomic, weak) UIViewController *backVC;
@property (nonatomic, strong, readonly) CJPayOrderResultResponse *resResponse;
@property (nonatomic, strong) CJPayCreateOrderResponse *orderResponse;
@property (nonatomic, copy, readonly) NSDictionary *createOrderParams;
@property (nonatomic, copy) void(^completionBlock)(CJPayOrderResultResponse *_Nullable response, CJPayOrderStatus orderStatus);
@property (nonatomic, copy) NSDictionary *lynxRetainTrackerParams;
@property (nonatomic, assign) BOOL orderIsInvalid;
@property (nonatomic, assign) BOOL isPaymentForOuterApp;
@property (nonatomic, copy) NSString *combineType;
@property (nonatomic, weak)id<CJPayAPIDelegate> delegate;

- (instancetype)initWith:(CJPayCreateOrderResponse *)response bizParams:(NSDictionary *)bizParams;
 
- (void)confirmPayWithConfig:(CJPayDefaultChannelShowConfig *)defaultConfig;
- (void)updateCreateOrderResponseWithCompletionBlock:(void(^)(NSError *error, CJPayCreateOrderResponse *response))completionBlock;

- (NSDictionary *)buildCommonTrackDic:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END

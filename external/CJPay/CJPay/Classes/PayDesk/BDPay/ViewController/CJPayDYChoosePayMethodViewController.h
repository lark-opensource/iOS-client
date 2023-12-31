//
//  CJPayDYChoosePayMethodViewController.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/18.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayBDMethodTableView.h"
#import "CJPayDYVerifyManagerQueen.h"

@protocol CJPayDYChooseMethodDelegate <NSObject>

- (void)changePayMethodTo:(CJPayDefaultChannelShowConfig *_Nonnull)defaultModel;

@optional
- (void)handleNativeBindAndPayResult:(BOOL)isSuccess isNeedCreateTrade:(BOOL)isNeedCreateTrade;
- (void)bindCard;
- (void)bindCardConfig:(CJPayDefaultChannelShowConfig *_Nullable)bindCardConfig;
- (void)closeDesk;
- (void)bindCardAndPay;

@end

NS_ASSUME_NONNULL_BEGIN

typedef void(^CJPayDYSelectPayMethodCompletion)(CJPayDefaultChannelShowConfig *showConfig);

@class CJPayNotSufficientFundsView;
@interface CJPayDYChoosePayMethodViewController : CJPayHalfPageBaseViewController

@property (nonatomic, weak) id<CJPayDYChooseMethodDelegate> delegate;
@property (nonatomic, weak) CJPayDYVerifyManagerQueen *queen;
@property (nonatomic, assign) BOOL showNotSufficientFundsHeaderLabel;
@property (nonatomic, copy) NSArray<NSString *> *notSufficientFundsIDs;
@property (nonatomic, strong, readonly) CJPayNotSufficientFundsView *notSufficientFundsView;
@property (nonatomic, strong) CJPayBDMethodTableView *payMethodView;

- (instancetype)initWithOrderResponse:(CJPayBDCreateOrderResponse *)response
                        defaultConfig:(CJPayDefaultChannelShowConfig *)config
                          combinedPay:(BOOL)isFromCombinedPay
            selectPayMethodCompletion:(nullable CJPayDYSelectPayMethodCompletion)completion; //completion不为nil时优先走completion逻辑，completion为nil时走changePayMethodTo代理方法

@end

NS_ASSUME_NONNULL_END

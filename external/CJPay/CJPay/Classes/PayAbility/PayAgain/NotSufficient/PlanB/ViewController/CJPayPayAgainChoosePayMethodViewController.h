//
//  CJPayPayAgainChoosePayMethodViewController.h
//  Pods
//
//  Created by wangxiaohong on 2021/6/30.
//

#import "CJPayHalfPageBaseViewController.h"

#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayBytePayMethodCell.h"
#import "CJPayPayAgainViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayPayAgainChoosePayMethodDelegate <NSObject>

@optional
- (void)didClickMethodCell:(UITableViewCell *)cell channelBizModel:(CJPayChannelBizModel *)bizModel;
- (void)trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params;
- (void)didChangeCreditPayInstallment:(NSString *)installment;

@end

@class CJPayIntegratedChannelModel;
@class CJPayPayAgainViewModel;
@interface CJPayPayAgainChoosePayMethodViewController : CJPayHalfPageBaseViewController

@property (nonatomic, copy) NSDictionary *payDisabledFundID2ReasonMap;
@property (nonatomic, assign) BOOL isSkipPwd;  //是否是免密
@property (nonatomic, assign) CJPaySecondPayShowStyle showStyle;
- (instancetype)initWithEcommerceViewModel:(CJPayPayAgainViewModel *)viewModel;

@property (nonatomic, weak) id<CJPayPayAgainChoosePayMethodDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

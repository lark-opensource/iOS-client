//
//  CJPayPayAgainCombinationPaymentViewController.h
//  Pods
//
//  Created by 高航 on 2022/6/20.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPaySDKDefine.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayBytePayMethodCell.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayIntegratedCashierHomeVCProtocol;
@protocol CJPayDefaultChannelShowConfig;

@class CJPayCreateOrderResponse;
@class CJPayDefaultChannelShowConfig;
@class CJPayIntegratedCashierProcessManager;
@class CJPayPayAgainViewModel;

@protocol CJPayPayAgainCombineChoosePayMethodDelegate <NSObject>

@optional
- (void)didClickCombineMethodCell:(UITableViewCell *)cell channelBizModel:(CJPayChannelBizModel *)bizModel;
- (void)trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params;

@end

@interface CJPayPayAgainCombinationPaymentViewController : CJPayHalfPageBaseViewController<CJPayBaseLoadingProtocol>

- (instancetype)initWithViewModel:(CJPayPayAgainViewModel *)viewModel;

@property (nonatomic, copy) NSDictionary *commonTrackerParams; // 通用埋点参数

@property (nonatomic, assign) CJPayChannelType type;
@property (nonatomic, weak) id<CJPayPayAgainCombineChoosePayMethodDelegate> delegate;

#pragma mark - data

@end

NS_ASSUME_NONNULL_END

//
//  CJPayCombinationPaymentViewController.h
//  Pods
//
//  Created by xiuyuanLee on 2021/4/12.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPaySDKDefine.h"
NS_ASSUME_NONNULL_BEGIN

@protocol CJPayMethodTableViewDelegate;
@protocol CJPayIntegratedCashierHomeVCProtocol;
@protocol CJPayDefaultChannelShowConfig;

@class CJPayCreateOrderResponse;
@class CJPayDefaultChannelShowConfig;
@class CJPayIntegratedCashierProcessManager;

@interface CJPayCombinationPaymentViewController : CJPayHalfPageBaseViewController<CJPayBaseLoadingProtocol>

- (instancetype)initWithOrderResponse:(CJPayCreateOrderResponse *)response
                        defaultConfig:(CJPayDefaultChannelShowConfig *)config
                       processManager:(CJPayIntegratedCashierProcessManager *)manager
                                 type:(CJPayChannelType)type;

- (void)notifyNotsufficient:(NSString *)bankCardId;
- (NSArray<CJPayDefaultChannelShowConfig> *)getShouldShowConfigs;
- (void)updateSelectConfig:(nullable CJPayDefaultChannelShowConfig *)selectConfig;

@property (nonatomic, weak) id<CJPayMethodTableViewDelegate> delegate;

@property (nonatomic, copy) void(^payBlock)(CJPayDefaultChannelShowConfig *showConfig);

@property (nonatomic, copy) NSDictionary *commonTrackerParams; // 通用埋点参数

@property (nonatomic, assign) CJPayChannelType type;
@property (nonatomic, assign) CJPayChannelType combineType;

#pragma mark - flags
@property (nonatomic, assign) BOOL showNotSufficientFundsHeaderLabel;

#pragma mark - data
@property (nonatomic, strong) NSMutableArray<NSString *> *notSufficientFundsIDs;

@end

NS_ASSUME_NONNULL_END

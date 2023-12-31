//
//  CJPayCombinePayDetailView.h
//  Pods
//
//  Created by youerwei on 2021/4/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayCombinePayFund;
@interface CJPayCombinePayDetailView : UIView

@property (nonatomic, strong) UILabel *balanceDescLabel;
@property (nonatomic, strong) UILabel *balanceAmountLabel;
@property (nonatomic, strong) UILabel *bankDescLabel;
@property (nonatomic, strong) UILabel *bankAmountLabel;

- (void)updateBalanceMsgWithFund:(CJPayCombinePayFund *)fund;
- (void)updateBankMsgWithFund:(CJPayCombinePayFund *)fund;
- (void)upateDetailViewLayout;

@end

NS_ASSUME_NONNULL_END

//
//  CJPayCombinationPaymentAmountView.h
//  Pods
//
//  Created by xiuyuanLee on 2021/4/12.
//

#import <Foundation/Foundation.h>
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayCombinePaymentAmountModel;

@interface CJPayCombinationPaymentAmountView : UIView

@property (nonatomic, assign, readonly) BOOL notSufficient;

- (instancetype)initWithType:(CJPayChannelType)type;
- (void)updateStyleIfShowNotSufficient:(BOOL)showNotSufficient;
- (void)updateAmount:(CJPayCombinePaymentAmountModel *)amountModel;

@end

NS_ASSUME_NONNULL_END

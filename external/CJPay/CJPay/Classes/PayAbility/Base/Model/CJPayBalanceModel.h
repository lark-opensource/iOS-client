//
//  CJPayBalanceModel.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/23.
//

#import <Foundation/Foundation.h>
#import "CJPayChannelModel.h"
#import <JSONModel/JSONModel.h>

@interface CJPayBalanceModel : CJPayChannelModel

@property(nonatomic, assign) int balanceAmount;
@property(nonatomic, copy, nullable) NSString *balanceQuota;
@property(nonatomic, assign) int freezedAmount;
@property(nonatomic, copy) NSString *mobile;
@property(nonatomic, assign) bool isShowCombinePay;
@property(nonatomic, copy, nullable) NSString *primaryCombinePayAmount;

@end

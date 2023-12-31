//
//  CJPayFrontCashierManager.h
//  CJPay
//
//  Created by 王新华 on 3/9/20.
//

#import <Foundation/Foundation.h>
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayManagerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayFrontCashierManager : NSObject

+ (instancetype)shared;

// 前置收银台选卡
- (void)chooseCardWithCommonModel:(BDChooseCardCommonModel *)commonModel;

// 前置收银台绑卡
- (void)bindCardWithCommonModel:(CJPayBindCardSharedDataModel *)bindCardCommonModel;

@end

NS_ASSUME_NONNULL_END

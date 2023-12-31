//
//  CJPayBankCardDetailViewController.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import "CJPayThemedCommonListViewController.h"
#import "CJPayMemAuthInfo.h"
#import "CJPayBankCardModel.h"
#import "CJPayFullPageBaseViewController+Biz.h"
#import "CJPayQueryUserBankCardRequest.h"
#import "CJPayBankCardItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBankCardDetailViewController : CJPayThemedCommonListViewController

- (instancetype)initWithCardItemModel:(CJPayBankCardItemViewModel *)cardModel;

@end

NS_ASSUME_NONNULL_END

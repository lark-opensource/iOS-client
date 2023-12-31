//
//  CJPayBankCardFooterViewModel.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/29.
//

#import "CJPayBaseListViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBankCardFooterViewModel : CJPayBaseListViewModel

@property(nonatomic, copy) NSString *merchantId;
@property(nonatomic, copy) NSString *appId;
@property (nonatomic, assign) CGFloat cellHeight;
@property (nonatomic, assign) BOOL showGurdTipView;
@property (nonatomic, assign) BOOL showQAView;

@end

NS_ASSUME_NONNULL_END

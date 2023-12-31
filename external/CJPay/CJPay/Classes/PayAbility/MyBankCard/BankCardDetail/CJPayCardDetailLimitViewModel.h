//
//  CJPayCardDetailLimitViewModel.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/23.
//

#import "CJPayBaseListViewModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface CJPayCardDetailLimitViewModel : CJPayBaseListViewModel

@property(nonatomic,copy)NSString *perDayLimitStr;
@property(nonatomic,copy)NSString *perPayLimitStr;

@end

NS_ASSUME_NONNULL_END

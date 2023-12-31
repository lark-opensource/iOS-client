//
//  CJPayBankCardAddViewModel.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import "CJPayBaseListViewModel.h"
#import "CJPayMemAuthInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBankCardAddViewModel : CJPayBaseListViewModel

@property (nonatomic, strong) CJPayMemAuthInfo *userInfo;
@property (nonatomic, copy) NSString *noPwdBindCardDisplayDesc;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSDictionary *trackDic;

@property (nonatomic, copy) void(^didClickBlock)(void);

@end

NS_ASSUME_NONNULL_END

//
//  CJPayBankCardListViewController.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import "CJPayThemedCommonListViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBankCardListViewController : CJPayThemedCommonListViewController

+ (instancetype)openWithAppId:(NSString *)appId merchantId:(NSString *)merhcantId userId:(NSString *)userId  extraParams:(NSDictionary *)extraParams;

- (instancetype)initWithAppId:(NSString *)appId
                   merchantId:(NSString *)merhcantId
                       userId:(NSString *)userId;


@end

NS_ASSUME_NONNULL_END

//
//  CJPayMyBankCardPluginImpl.h
//  CJPaySandBox
//
//  Created by chenbocheng.moon on 2023/1/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayBankCardListViewController;
@class CJPayBankCardDetailViewController;
@class CJPayBankCardItemViewModel;

@interface CJPayMyBankCardPluginImpl : NSObject

- (CJPayBankCardListViewController *)openMyCardWithAppId:(NSString *)appId
                                              merchantId:(NSString *)merchantId
                                                  userId:(NSString *)userId
                                             extraParams:(NSDictionary *)extraParams;

- (CJPayBankCardDetailViewController *)openDetailWithCardItemModel:(CJPayBankCardItemViewModel *)cardItemModel;

@end

NS_ASSUME_NONNULL_END

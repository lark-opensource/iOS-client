//
//  CJPayAgreementModel.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/31.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayQuickPayUserAgreement;
@protocol CJPayQuickPayUserAgreement;
@interface CJPayBankAgreementModel : JSONModel

@property (nonatomic, copy) NSString * bankCode;
@property (nonatomic, copy) NSArray<CJPayQuickPayUserAgreement> * agreementLists;

@end

NS_ASSUME_NONNULL_END

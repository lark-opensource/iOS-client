//
//  CJPayVoucherBankInfo.h
//  Pods
//
//  Created by chenbocheng.moon on 2022/10/17.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayVoucherBankInfo : JSONModel

@property (nonatomic, copy) NSString* iconUrl;
@property (nonatomic, copy) NSString* cardVoucherMsg;
@property (nonatomic, copy) NSString* cardBinVoucherMsg;
@property (nonatomic, copy) NSString* voucherBank;

- (BOOL)hasVoucher;

@end

NS_ASSUME_NONNULL_END

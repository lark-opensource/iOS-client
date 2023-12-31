//
//  CJPayMemBankInfoModel.h
//  Pods
//
//  Created by 尚怀军 on 2020/2/20.
//

#import <JSONModel/JSONModel.h>
#import "CJPayQuickPayChannelModel.h"
NS_ASSUME_NONNULL_BEGIN

@class CJPayBindCardVoucherInfo;
@interface CJPayMemBankInfoModel : JSONModel
@property (nonatomic, copy) NSString *bankCardID;
@property (nonatomic, copy) NSString *bankCode;
@property (nonatomic, copy) NSString *bankName;
@property (nonatomic, copy) NSString *cardType;
@property (nonatomic, copy) NSString *iconURL;
@property (nonatomic, copy) NSString *cardNoMask;
@property (nonatomic, copy) NSString *cardNumStr; // 银行卡号
@property (nonatomic, copy) NSString *perpayLimit;
@property (nonatomic, copy) NSString *perdayLimit;
@property (nonatomic, assign) CGFloat cellHeight;
@property (nonatomic, copy) NSString *cardBinVoucher;
@property (nonatomic, copy) NSDictionary *voucherInfoDict;
@property (nonatomic, strong) CJPayBindCardVoucherInfo *debitBindCardVoucherInfo;
@property (nonatomic, strong) CJPayBindCardVoucherInfo *creditBindCardVoucherInfo;

- (CJPayQuickPayCardModel *)toQuickPayCardModel;

@end

NS_ASSUME_NONNULL_END

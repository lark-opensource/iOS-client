//
//  CJPayQuickBindCardModel.h
//  Pods
//
//  Created by wangxiaohong on 2020/10/12.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayBindCardVoucherInfo;
@class CJPayBindCardTitleInfoModel;
@protocol CJPayBindCardVoucherInfo;

@interface CJPayQuickBindCardModel : JSONModel

@property (nonatomic, copy) NSString *bankCode;
@property (nonatomic, copy) NSString *cardType;
@property (nonatomic, copy) NSString *bankName;
@property (nonatomic, copy) NSString *orderAmount;
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *backgroundUrl;
@property (nonatomic, copy) NSString *bankCardId;
@property (nonatomic, copy) NSDictionary *voucherInfoDict;
@property (nonatomic, copy) NSString *selectedCardType;
@property (nonatomic, copy) NSString *bankRank;
@property (nonatomic, copy) NSString *jumpBankType; // 不支持一键绑卡时可以通过普通绑卡的卡种
@property (nonatomic, copy) NSString *rankType;
@property (nonatomic, copy) NSString *bankInitials;
@property (nonatomic, copy) NSString *bankPopularFlag;
@property (nonatomic, copy) NSString *bankSortNum;
@property (nonatomic, copy) NSString *isSupportOneKey;
@property (nonatomic, copy) NSString *voucherMsg;

@property (nonatomic, strong) CJPayBindCardVoucherInfo *debitBindCardVoucherInfo;
@property (nonatomic, strong) CJPayBindCardVoucherInfo *creditBindCardVoucherInfo;
@property (nonatomic, strong) CJPayBindCardVoucherInfo *unionBindCardVoucherInfo;
@property (nonatomic, assign, readonly) BOOL isUnionBindCard;

- (NSArray *)activityInfoWithCardType:(NSString *)cardType;

@end

NS_ASSUME_NONNULL_END

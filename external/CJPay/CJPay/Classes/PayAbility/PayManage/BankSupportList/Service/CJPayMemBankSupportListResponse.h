//
//  CJPayMemBankSupportListResponse.h
//  Pods
//
//  Created by 尚怀军 on 2020/2/20.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayMemBankInfoModel;
@class CJPayQuickBindCardModel;
@class CJPayBindCardTitleInfoModel;
@class CJPayBindCardRetainInfo;
@class CJPayBindCardTitleInfoModel;
@class CJPayVoucherListModel;
@class CJPayVoucherBankInfo;
@protocol CJPayMemBankInfoModel;
@protocol CJPayQuickBindCardModel;


@interface CJPayMemBankSupportListResponse : CJPayBaseResponse

@property (nonatomic, copy) NSArray<CJPayMemBankInfoModel> *creditBanks;
@property (nonatomic, copy) NSArray<CJPayMemBankInfoModel> *debitBanks;
@property (nonatomic, copy) NSArray<CJPayQuickBindCardModel> *oneKeyBanks;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *noPwdBindCardDisplayDesc;
@property (nonatomic, copy) NSString *voucherMsg;
@property (nonatomic, strong) CJPayVoucherListModel *voucherList;
@property (nonatomic, copy) NSString *voucherBank;
@property (nonatomic, strong) CJPayVoucherBankInfo *voucherBankInfo;
@property (nonatomic, assign) BOOL isSupportOneKey;
@property (nonatomic, copy) NSString *cardNoInputTitle; //绑卡输入框文案信息
@property (nonatomic, strong) CJPayBindCardRetainInfo *retainInfo;
@property (nonatomic, assign) NSInteger oneKeyBanksLength;
@property (nonatomic, copy) NSDictionary *exts;

//绑卡银行排序策略&首页优化
@property (nonatomic, assign) NSInteger recommendBanksLenth;
@property (nonatomic, copy) NSArray<CJPayQuickBindCardModel> *recommendBanks;
@property (nonatomic, strong) CJPayBindCardTitleInfoModel *recommendBindCardTitleModel;

// 一件绑卡前置实验使用
@property (nonatomic, strong) CJPayBindCardTitleInfoModel *bindCardTitleModel;

@end

NS_ASSUME_NONNULL_END

//
//  CJPaySubPayTypeSumInfo.h
//  Pods
//
//  Created by wangxiaohong on 2021/4/12.
//

#import <JSONModel/JSONModel.h>
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPayHomePageBannerModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayFreqSuggestStyleInfo.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPaySubPayTypeInfoModel;
@class CJPayZoneSplitInfoModel;
@interface CJPaySubPayTypeSumInfoModel : JSONModel

// 收银台样式 style 对应值, multi: 多支付漏出样式 single:简化漏出样式  standard: 标准样式  freq_suggest:O项目首页推荐卡样式
@property (nonatomic, copy) NSString *homePageShowStyle;
@property (nonatomic, copy) NSString *homePageGuideText;
@property (nonatomic, assign) BOOL homePageRedDot;
@property (nonatomic, strong) CJPayHomePageBannerModel *homePageBanner;
@property (nonatomic, copy) NSArray<CJPaySubPayTypeInfoModel> *subPayTypeInfoList;
@property (nonatomic, assign, readonly) BOOL isBindedCard; //是否绑过卡，用来区分是否需是新用户
@property (nonatomic, copy) NSString *subPayTypePageSubtitle;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<NSString *> *> *bytepayVoucherMsgMap;
@property (nonatomic, copy) NSString *priceZoneShowStyle; //价格区（例如收银台首页）展示样式："LINE"表示根据支付方式联动展示金额营销，其余情况不展示营销
@property (nonatomic, copy) NSArray<NSNumber*> *cardStyleIndexList;// 二级支付为card类型时，取得两个二级支付渠道的下标
@property (nonatomic, assign) BOOL useSubPayListVoucherMsg;//是否取二级支付营销
@property (nonatomic, strong) CJPayZoneSplitInfoModel *zoneSplitInfoModel; // 聚合卡列表分割区域信息
@property (nonatomic, strong) CJPayFreqSuggestStyleInfo *freqSuggestStyleInfo; // 新卡推荐卡相关信息

- (CJPaySubPayTypeData *)balanceTypeData;
- (CJPaySubPayTypeData *)incomeTypeData;

@end

NS_ASSUME_NONNULL_END

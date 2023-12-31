//
//  CJPayResultPageInfoModel.h
//  CJPaySandBox
//
//  Created by 高航 on 2022/11/24.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayPayInfoDesc : JSONModel//复用为支付通用信息字段

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *iconUrl;//主要用于银行卡icon
@property (nonatomic, copy) NSString *showNum;//用于折叠信息时候的隐藏样式

@end

@interface CJPayVoucherOptions : JSONModel

@property (nonatomic, copy) NSString *desc;

@end

@interface CJPayMerchantTips : JSONModel

@property (nonatomic, copy) NSString *desc;

@end

@interface CJPayButtonInfo : JSONModel
@property (nonatomic, copy) NSString *action;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *type;

@end

@interface CJPayAssets : JSONModel

@property (nonatomic, copy) NSString *bgImage;
@property (nonatomic, copy) NSString *tipImage;
@property (nonatomic, copy) NSString *showImage;

@end

@interface CJPayRenderInfo : JSONModel

@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *h5Url;
@property (nonatomic, copy) NSString *lynxUrl;

@end

@interface CJPayDynamicComponents : JSONModel

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *schema;

@end

@interface CJPayPaymentInfo : JSONModel

@property (nonatomic, copy) NSString *typeMark;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *colortype;
@property (nonatomic, copy) NSString *icon;

@end

@protocol CJPayPayInfoDesc;
@protocol CJPayDynamicComponents;
@interface CJPayResultPageInfoModel : JSONModel

@property (nonatomic, strong) CJPayPayInfoDesc *moreShowInfo;
@property (nonatomic, strong) CJPayVoucherOptions *voucherOptions;
@property (nonatomic, strong) CJPayMerchantTips *merchantTips;
@property (nonatomic, strong) CJPayButtonInfo *buttonInfo;
@property (nonatomic, strong) CJPayAssets *assets;
@property (nonatomic, copy) NSArray<CJPayPayInfoDesc> *showInfos;
@property (nonatomic, copy) NSArray<CJPayDynamicComponents> *dynamicComponents;
@property (nonatomic, copy) NSString *dynamicData;
@property (nonatomic, strong) CJPayRenderInfo *renderInfo;

@end

NS_ASSUME_NONNULL_END

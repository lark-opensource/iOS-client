//
//  CJPayBankActivityInfoModel.h
//  Pods
//
//  Created by xiuyuanLee on 2020/12/30.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBankActivityInfoModel : JSONModel

@property (nonatomic, copy) NSString *iconUrl; // 银行图标链接
@property (nonatomic, copy) NSString *bankCardName; // 银行卡名称
@property (nonatomic, copy) NSString *buttonDesc; // button文案
@property (nonatomic, copy) NSString *jumpUrl; // button点击跳转链接
@property (nonatomic, copy) NSString *activityPageUrl; // 背景点击链接
@property (nonatomic, copy) NSString *benefitDesc;
@property (nonatomic, copy) NSString *benefitAmount;

@property (nonatomic, assign) BOOL isEmptyResource;

@end

NS_ASSUME_NONNULL_END

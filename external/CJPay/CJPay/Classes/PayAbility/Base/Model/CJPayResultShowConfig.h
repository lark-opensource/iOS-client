//
//  CJPayResultShowConfig.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/27.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "CJPayDiscountBanner.h"

@protocol CJPayDiscountBanner;

@interface CJPayResultShowConfigGuideInfo : JSONModel

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *color;
@property (nonatomic, copy) NSString *type;

- (BOOL)isShowText;

@end

@interface CJPayResultShowConfig : JSONModel

@property (nonatomic, copy) NSString *remainTime;    //剩余时间  -1表示无限长   单位秒
@property (nonatomic, copy) NSString *successDesc;
@property (nonatomic, copy) NSString *resultDesc;
@property (nonatomic, copy) NSString *successUrl;
@property (nonatomic, copy) NSString *successBtnDesc;
@property (nonatomic, copy) NSString *successBtnPosition;
@property (nonatomic, assign) int queryResultTimes;
@property (nonatomic, copy) NSString *bgImageURL;
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, strong) CJPayResultShowConfigGuideInfo *bottomGuideInfo;

@property (nonatomic, copy) NSString *withdrawResultPageDesc;
@property (nonatomic, copy) NSString *showStyle; // 展示样式，0：半屏显示; 1：全屏显示；2：弹窗; 4: 抖音红包样式

@property (nonatomic, copy) NSString *middleBannerType;
@property (nonatomic, copy) NSArray <CJPayDiscountBanner> *middleBanners;

@property (nonatomic, copy) NSString *bottomBannerType;
@property (nonatomic, copy) NSArray <CJPayDiscountBanner> *bottomBanners;
@property (nonatomic, assign) BOOL hiddenResultPage;

@end

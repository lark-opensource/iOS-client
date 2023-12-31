//
//  CJPayMemBankActivityResponse.h
//  Pods
//
//  Created by xiuyuanLee on 2020/12/30.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBankActivityInfoModel;
@protocol CJPayBankActivityInfoModel;

@interface CJPayMemBankActivityResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *placeNo;
@property (nonatomic, copy) NSString *mainTitle;
@property (nonatomic, assign) BOOL ifShowSubTitle;
@property (nonatomic, copy) NSString *subTitle;

@property (nonatomic, copy) NSArray<CJPayBankActivityInfoModel> *bankActivityInfoArray;

@end

NS_ASSUME_NONNULL_END

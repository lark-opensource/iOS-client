//
//  CJPayCombinePayInfoModel.h
//  Pods
//
//  Created by 高航 on 2022/6/22.
//

#import <JSONModel/JSONModel.h>
#import "CJPayPrimaryCombinePayInfoModel.h"
#import "CJPaySecondaryCombinePayInfoModel.h"

NS_ASSUME_NONNULL_BEGIN
@protocol CJPayPrimaryCombinePayInfoModel;
@protocol CJPaySecondaryCombinePayInfoModel;
@class CJPayVoucherInfoModel;

@interface CJPayCombinePayInfoModel : JSONModel

@property (nonatomic, copy)NSArray<CJPayPrimaryCombinePayInfoModel> *primaryPayInfoList;
@property (nonatomic, strong)CJPaySecondaryCombinePayInfoModel *secondaryPayInfo;
@property (nonatomic, strong) CJPayVoucherInfoModel *combinePayVoucherInfo;//营销信息
@property (nonatomic, copy) NSArray<NSString *> *combinePayVoucherMsgList;
@property (nonatomic, copy) NSString *standardRecDesc;
@property (nonatomic, copy) NSString *standardShowAmount;

@end

NS_ASSUME_NONNULL_END

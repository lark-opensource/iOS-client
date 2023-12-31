//
//  CJPayBankCardActivityItemViewModel.h
//  Pods
//
//  Created by xiuyuanLee on 2020/12/29.
//

#import "CJPayBaseListViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBankActivityInfoModel;

@interface CJPayBankCardActivityItemViewModel : CJPayBaseListViewModel

// 是否是最后一行营销展示位
@property (nonatomic, assign) BOOL isLastBankActivityRowViewModel;
// 是否曝光过
@property (nonatomic, assign) BOOL isBankCardActivityExposed;

@property (nonatomic, copy) NSArray<CJPayBankActivityInfoModel *> *activityInfoModelArray;

@property (nonatomic, copy) void(^didSelectedBlock)(CJPayBankActivityInfoModel *model);
@property (nonatomic, copy) void(^buttonClickBlock)(CJPayBankActivityInfoModel *model);

@end

NS_ASSUME_NONNULL_END

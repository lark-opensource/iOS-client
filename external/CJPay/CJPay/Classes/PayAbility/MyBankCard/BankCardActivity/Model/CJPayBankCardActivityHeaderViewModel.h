//
//  CJPayBankCardActivityHeaderViewModel.h
//  Pods
//
//  Created by xiuyuanLee on 2020/12/30.
//

#import "CJPayBaseListViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBankCardActivityHeaderViewModel : CJPayBaseListViewModel

@property (nonatomic, copy) NSString *mainTitle;
@property (nonatomic, assign) BOOL ifShowSubTitle;
@property (nonatomic, copy) NSString *subTitle;

@end

NS_ASSUME_NONNULL_END

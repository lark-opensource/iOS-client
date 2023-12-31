//
//  CJPayMyBankCardListViewModel.h
//  Pods
//
//  Created by wangxiaohong on 2020/12/30.
//

#import "CJPayBaseListViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayMyBankCardListViewModel : CJPayBaseListViewModel<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) NSArray<CJPayBaseListViewModel *> *bankCardListViewModels;

@property (nonatomic, copy) void(^allBankCardListBlock)(void);
@property (nonatomic, copy) void(^safeBannerDidClickBlock)(void);


@end

NS_ASSUME_NONNULL_END

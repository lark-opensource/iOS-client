//
//  CJPayCommonListViewController.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/18.
//

#import <UIKit/UIKit.h>
#import "CJPayFullPageBaseViewController.h"
#import "CJPayBaseListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCommonListViewController : CJPayFullPageBaseViewController

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CJPayBaseListDataSource *dataSource;

@property (nonatomic, copy) void(^cellWillDisplayBlock)(CJPayBaseListCellView *cell, CJPayBaseListViewModel *viewModel);

- (void)reloadTableViewData;
- (void)handleWithEventName:(NSString *)eventName data:(id)data;

@end

NS_ASSUME_NONNULL_END

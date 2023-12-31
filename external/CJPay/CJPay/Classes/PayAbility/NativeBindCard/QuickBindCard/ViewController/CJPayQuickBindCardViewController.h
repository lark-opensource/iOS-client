//
//  CJPayQuickBindCardViewController.h
//  Pods
//
//  Created by wangxiaohong on 2020/10/12.
//

#import "CJPayCommonListViewController.h"
#import "CJPayQuickBindCardViewModel.h"
#import "CJPayBindCardVCModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayQuickBindCardModel;
@class CJPayQuickBindCardTableViewCell;
@class CJPayStyleBaseListCellView;

@interface CJPayQuickBindCardViewController : CJPayCommonListViewController

- (void)reloadWithModel:(CJPayBindCardVCLoadModel *)model;

#pragma mark - flag
@property (nonatomic, assign) CJPayBindCardStyle vcStyle;

#pragma mark - view
@property (nonatomic, strong, readonly) CJPayStyleBaseListCellView *tableViewHeader;

#pragma mark - model
// 点击一键绑卡的选项
@property (nonatomic, weak) CJPayBindCardVCModel *bindCardVCModel;

@property (nonatomic, copy) void(^didSelectedBlock)(CJPayQuickBindCardViewModel *viewmodel);
@property (nonatomic, copy) void(^didSelectedTipsBlock)(void);
@property (nonatomic, copy) void(^contentHeightDidChangeBlock)(CGFloat newHeight);

- (CGFloat)getTableViewHeightWithViewModels:(NSArray<CJPayBaseListViewModel *> *)viewModels;
- (NSArray<CJPayBaseListViewModel *> *)getViewModelsWithLoadModel:(CJPayBindCardVCLoadModel *)vcLoadModel;

@end

NS_ASSUME_NONNULL_END

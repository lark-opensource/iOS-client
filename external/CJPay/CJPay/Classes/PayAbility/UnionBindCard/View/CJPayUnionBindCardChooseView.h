//
//  CJPayUnionBindCardChooseView.h
//  Pods
//
//  Created by wangxiaohong on 2021/9/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayUnionBindCardChooseViewModel;
@class CJPayCommonProtocolView;
@class CJPayStyleButton;
@class CJPayBindCardScrollView;
@class CJPayUnionBindCardChooseHeaderView;
@interface CJPayUnionBindCardChooseView : UIView

@property (nonatomic, strong, readonly) CJPayBindCardScrollView *scrollView;
@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) CJPayCommonProtocolView *protocolView;
@property (nonatomic, strong, readonly) CJPayStyleButton *confirmButton;
@property (nonatomic, strong, readonly) CJPayUnionBindCardChooseHeaderView *headerView;
@property (nonatomic, copy) void(^protocolClickBlock)(void);

@property (nonatomic, weak) CJPayUnionBindCardChooseViewModel *viewModel;

- (instancetype)initWithViewModel:(CJPayUnionBindCardChooseViewModel *)viewModel;

- (void)reloadWithViewModel:(CJPayUnionBindCardChooseViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END

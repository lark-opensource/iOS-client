//
//  CJPayBaseListCellView.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/18.
//

#import <UIKit/UIKit.h>

@class CJPayBaseListViewModel;
@class CJPayCommonListViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayBaseListEventHandleProtocol <NSObject>

- (void)handleWithEventName:(NSString *)eventName
                       data:(nullable id)data;

@end

@interface CJPayBaseListCellView : UITableViewCell

@property(nonatomic, weak, readonly) CJPayCommonListViewController *viewController;

@property(nonatomic, strong) UIView *containerView;
@property(nonatomic, strong) CJPayBaseListViewModel *viewModel;
@property(nonatomic, weak) id <CJPayBaseListEventHandleProtocol> eventHandler;

- (void)setupUI;

// cell和viewmodel绑定
- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel;

// 在tableview中被选中时调用
- (void)didSelect;

@end

NS_ASSUME_NONNULL_END

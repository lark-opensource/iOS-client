//
//  CJPayBaseListCellView.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/18.
//

#import "CJPayBaseListCellView.h"
#import "CJPayUIMacro.h"
#import "CJPayBaseListViewModel.h"
#import "CJPayCommonListViewController.h"


@interface  CJPayBaseListCellView()

@property (nonatomic,strong) UIView *topMarginView;
@property (nonatomic,strong) UIView *bottomMarginView;

@end

@implementation CJPayBaseListCellView

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    
    return self;
}

- (void)setupUI {
    self.clipsToBounds = YES;
    
    [self.contentView addSubview:self.containerView];
    [self.contentView addSubview:self.topMarginView];
    [self.contentView addSubview:self.bottomMarginView];
    
    [self p_baseMakeConstraints];
}

- (void)p_baseMakeConstraints {
    CJPayMasMaker(self.topMarginView, {
        make.top.equalTo(self.contentView);
        make.left.equalTo(self.contentView);
        make.width.equalTo(self.contentView);
        make.height.mas_equalTo([self.viewModel getTopMarginHeight]);
    });
    CJPayMasMaker(self.containerView, {
        make.top.equalTo(self.topMarginView.mas_bottom);
        make.left.equalTo(self.contentView);
        make.width.equalTo(self.contentView);
        make.height.mas_equalTo([self.viewModel getViewHeight]);
    });
    CJPayMasMaker(self.bottomMarginView, {
        make.top.equalTo(self.containerView.mas_bottom);
        make.left.equalTo(self.contentView);
        make.width.equalTo(self.contentView);
        make.height.mas_equalTo([self.viewModel getBottomMarginHeight]);
    });
}

// 子类覆写，绑定viewmodel之后更新cell视图
- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    self.viewModel = viewModel;
    viewModel.cell = self;
    self.topMarginView.backgroundColor = [self.viewModel getTopMarginColor];
    self.bottomMarginView.backgroundColor = [self.viewModel getBottomMarginColor];
    
    CJPayMasUpdate(self.topMarginView, {
        make.height.mas_equalTo([self.viewModel getTopMarginHeight]);
    });
    CJPayMasUpdate(self.containerView, {
        make.height.mas_equalTo([self.viewModel getViewHeight]);
    });
    CJPayMasUpdate(self.bottomMarginView, {
        make.height.mas_equalTo([self.viewModel getBottomMarginHeight]);
    });
}

// 在tableview中被选中时调用,子类覆写实现cell被选中时的处理
- (void)didSelect {
    [CJPayPerformanceMonitor trackCellActionWithTableViewCell:self extra:@{}];
}

- (CJPayCommonListViewController *)viewController {
    return self.viewModel.viewController;
}

#pragma mark - lazy load

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [UIView new];
        _containerView.backgroundColor = [UIColor whiteColor];
    }
    return _containerView;
}

- (UIView *)topMarginView {
    if (!_topMarginView) {
        _topMarginView = [UIView new];
    }
    return _topMarginView;
}

- (UIView *)bottomMarginView {
    if (!_bottomMarginView) {
        _bottomMarginView = [UIView new];
    }
    return _bottomMarginView;
}

- (CJPayBaseListViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [CJPayBaseListViewModel new];
    }
    return _viewModel;
}

@end

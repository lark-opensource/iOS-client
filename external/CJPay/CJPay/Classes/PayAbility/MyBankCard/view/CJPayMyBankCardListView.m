//
//  CJPayMyBankCardListView.m
//  Pods
//
//  Created by wangxiaohong on 2020/12/30.
//

#import "CJPayMyBankCardListView.h"

#import "CJPayBaseListDataSource.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayMyBankCardListViewModel.h"
#import "CJPayLocalThemeStyle.h"
#import "CJPayLineUtil.h"
#import "CJPayBankCardItemViewModel.h"
#import "CJPaySettings.h"
#import "CJPaySettingsManager.h"
#import "UIView+CJTheme.h"

@interface CJPayMyBankCardListView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *allLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CJPayBaseListDataSource *dataSource;
@property (nonatomic, strong) UIView *contentBGView;
@property (nonatomic, strong) UIView *allLabelTappedView;
@property (nonatomic, strong) UIView *safeLabelTappedView;
@property (nonatomic, strong) UIImageView *safeImageView;
@property (nonatomic, strong) UILabel *safeLabel;

@property (nonatomic, strong) MASConstraint *tableViewHeightConstraint;

@end

@implementation CJPayMyBankCardListView

- (void)setupUI {
    [super setupUI];
    
    [self.containerView addSubview:self.contentBGView];
    
    [self.contentBGView addSubview:self.titleLabel];
    [self.contentBGView addSubview:self.tableView];
    [self.contentBGView addSubview:self.allLabel];
    [self.contentBGView addSubview:self.arrowImageView];
    
    [self.contentBGView addSubview:self.allLabelTappedView];
    
    BOOL showInsuranceEntrance = [CJPaySettingsManager shared].currentSettings.accountInsuranceEntrance.showInsuranceEntrance;
    if(showInsuranceEntrance){
        [self.contentBGView addSubview:self.safeLabelTappedView];
        [self.contentBGView addSubview:self.safeLabel];
        [self.contentBGView addSubview:self.safeImageView];
        CJPayMasMaker(self.safeImageView, {
            make.centerY.equalTo(self.titleLabel);
            make.left.equalTo(self.titleLabel.mas_right).offset(12);
            make.height.width.mas_equalTo(12);
        });
        
        CJPayMasMaker(self.safeLabel, {
            make.centerY.equalTo(self.titleLabel);
            make.left.equalTo(self.safeImageView.mas_right).offset(2);
        })
        
        CJPayMasMaker(self.safeLabelTappedView, {
            make.left.equalTo(self.titleLabel.mas_right).offset(8);
            make.centerY.equalTo(self.titleLabel);
            make.height.mas_equalTo(21);
            make.right.equalTo(self.safeLabel.mas_right).offset(4);
        });
    };
    
    CJPayMasMaker(self.contentBGView, {
        make.top.bottom.equalTo(self.containerView);
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.contentBGView).offset(16);
        make.left.equalTo(self.contentBGView).offset(12);
    });
    
    CJPayMasMaker(self.arrowImageView, {
        make.right.equalTo(self.contentBGView).offset(-12);
        make.top.equalTo(self.contentBGView).offset(22);
        make.width.mas_equalTo(12);
        make.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.allLabel, {
        make.top.equalTo(self.contentBGView).offset(21);
        make.right.equalTo(self.arrowImageView.mas_left);
        make.centerY.equalTo(self.arrowImageView);
    });
    
    CJPayMasMaker(self.allLabelTappedView, {
        make.top.equalTo(self.allLabel).offset(-10);
        make.left.equalTo(self.allLabel).offset(-10);
        make.right.equalTo(self.contentBGView);
        make.bottom.equalTo(self.allLabel).offset(10);
    });
    
    CJPayMasMaker(self.tableView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(12);
        make.left.equalTo(self.contentBGView).offset(-4);
        make.right.equalTo(self.contentBGView).offset(4);
        make.bottom.equalTo(self.contentBGView);
    });
}

- (void)p_allButtonTapped {
    if ([self.viewModel isKindOfClass:[CJPayMyBankCardListViewModel class]]) {
        CJPayMyBankCardListViewModel *viewModel = (CJPayMyBankCardListViewModel *)self.viewModel;
        CJ_CALL_BLOCK(viewModel.allBankCardListBlock);
    }
}

- (void)p_safeLabelTapped{
    if ([self.viewModel isKindOfClass:[CJPayMyBankCardListViewModel class]]) {
        CJPayMyBankCardListViewModel *viewModel = (CJPayMyBankCardListViewModel *)self.viewModel;
        CJ_CALL_BLOCK(viewModel.safeBannerDidClickBlock);
    }
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    if ([viewModel isKindOfClass:[CJPayMyBankCardListViewModel class]]) {
        CJPayMyBankCardListViewModel *cardListViewModel = (CJPayMyBankCardListViewModel *)viewModel;
        self.tableView.delegate = cardListViewModel;
        self.tableView.dataSource = cardListViewModel;
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[@(0)] = cardListViewModel.bankCardListViewModels;
        
        //取消CALayer的隐式动画，避免闪烁
        [CATransaction setDisableActions:YES];
        [self.tableView reloadData];
        [CATransaction commit];
        
        self.allLabel.text = [NSString stringWithFormat:CJPayLocalizedStr(@"全部(%lu)"),cardListViewModel.bankCardListViewModels.count - 1];
        
        [self p_refreshAllButtonWithViewModel:cardListViewModel];
    }
}

- (void)p_refreshAllButtonWithViewModel:(CJPayMyBankCardListViewModel *)cardListViewModel {
    
    __block NSInteger count = 0;
    __block BOOL isAllButtonShow = NO;
    
    [cardListViewModel.bankCardListViewModels enumerateObjectsUsingBlock:^(CJPayBaseListViewModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[CJPayBankCardItemViewModel class]]) {
            count++;
        }
        if (count > 3) {
            isAllButtonShow = YES;
            *stop = YES;
        }
    }];
    
    self.allLabel.hidden = !isAllButtonShow;
    self.arrowImageView.hidden = !isAllButtonShow;
    self.allLabelTappedView.hidden = !isAllButtonShow;
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        self.titleLabel.textColor = localTheme.addBankButtonTitleColor;
        self.allLabel.textColor = localTheme.unbindCardTextColor;
        [self.arrowImageView cj_setImage:localTheme.addBankButtonNormalArrowImageName];
        
        CJPayThemeModeType currentThemeModel = [self cj_responseViewController].cj_currentThemeMode;
        if (currentThemeModel == CJPayThemeModeTypeDark) {
            self.contentBGView.backgroundColor = [UIColor cj_ffffffWithAlpha:0.03];
            self.contentBGView.layer.borderWidth = 0;
            self.contentBGView.layer.cornerRadius = 4;
            self.safeLabel.textColor = [UIColor cj_17a37eff];
            self.safeLabelTappedView.backgroundColor = [UIColor cj_17a37eWithAlpha:0.12];
        } else if (currentThemeModel == CJPayThemeModeTypeLight) {
            self.contentBGView.backgroundColor = [UIColor clearColor];
            self.contentBGView.layer.borderWidth = CJ_PIXEL_WIDTH;
            self.contentBGView.layer.borderColor = [UIColor cj_161823WithAlpha:0.12].CGColor;
            self.contentBGView.layer.cornerRadius = 4;
            self.safeLabel.textColor = [UIColor cj_418f82ff];
            self.safeLabelTappedView.backgroundColor = [UIColor cj_e1fbf8ff];
        }
    }
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.text = CJPayLocalizedStr(@"我的卡");
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.userInteractionEnabled = YES;
    }
    return _titleLabel;
}

- (UILabel *)allLabel {
    if (!_allLabel) {
        _allLabel = [UILabel new];
        _allLabel.font = [UIFont cj_fontOfSize:13];
        _allLabel.userInteractionEnabled = YES;
    }
    return _allLabel;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [UIImageView new];
        _arrowImageView.userInteractionEnabled = YES;
    }
    return _arrowImageView;
}

- (UIView *)allLabelTappedView {
    if (!_allLabelTappedView) {
        _allLabelTappedView = [UIView new];
        [_allLabelTappedView cj_viewAddTarget:self
                                       action:@selector(p_allButtonTapped)
                                forControlEvents:UIControlEventTouchUpInside];
    }
    return _allLabelTappedView;
}

- (UIView *)contentBGView {
    if (!_contentBGView) {
        _contentBGView = [UIView new];
    }
    return _contentBGView;;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.backgroundColor = UIColor.clearColor;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.scrollEnabled = NO;
    }
    return _tableView;
}

- (UIView *)safeLabelTappedView {
    if(!_safeLabelTappedView) {
        _safeLabelTappedView = [UIView new];
        _safeLabelTappedView.layer.cornerRadius = 2;
        _safeLabelTappedView.layer.masksToBounds = YES;
        [_safeLabelTappedView cj_viewAddTarget:self
                                        action:@selector(p_safeLabelTapped)
                              forControlEvents:UIControlEventTouchUpInside];
    }
    return _safeLabelTappedView;
}

- (UIImageView *)safeImageView {
    if(!_safeImageView) {
        _safeImageView = [UIImageView new];
        [_safeImageView cj_setImage:@"cj_safe_defense_icon"];
    }
    return _safeImageView;
}

- (UILabel *)safeLabel {
    if(!_safeLabel) {
        _safeLabel = [UILabel new];
        _safeLabel.text = CJPayLocalizedStr(@"保障中");
        _safeLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _safeLabel;
}

@end

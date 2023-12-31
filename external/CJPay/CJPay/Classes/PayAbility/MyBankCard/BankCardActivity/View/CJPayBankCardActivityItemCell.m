//
//  CJPayBankCardActivityItemCell.m
//  Pods
//
//  Created by xiuyuanLee on 2020/12/29.
//

#import "CJPayBankCardActivityItemCell.h"
#import "CJPayBankCardActivityItemViewModel.h"
#import "CJPayBankActivityInfoModel.h"
#import "CJPayBankCardBankActivityView.h"
#import "CJPayLineUtil.h"
#import "CJPayServerThemeStyle.h"
#import "CJPayUIMacro.h"
#import "UIView+CJTheme.h"

@interface CJPayBankCardActivityItemCell ()

@property (nonatomic, strong) UIView *contentBGView;
@property (nonatomic, copy) NSArray<CJPayBankCardBankActivityView *> *activityViewsArray;

@end

@implementation CJPayBankCardActivityItemCell

- (void)setupUI {
    [super setupUI];
    
    [self.containerView addSubview:self.contentBGView];
    
    [self.activityViewsArray enumerateObjectsUsingBlock:^(CJPayBankCardBankActivityView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.contentBGView addSubview:obj];
    }];
    
    CJPayMasMaker(self.contentBGView, {
        make.top.bottom.equalTo(self.containerView);
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
    });
    
    [self.activityViewsArray mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:12 leadSpacing:12 tailSpacing:12];
    CJPayMasArrayMaker(self.activityViewsArray, {
        make.top.equalTo(self.contentBGView).offset(8);
        make.height.mas_equalTo(104);
        make.bottom.lessThanOrEqualTo(self.contentBGView);
    });
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
    UIColor *lineColor = localTheme ? localTheme.bankActivityBorderColor : [UIColor cj_161823WithAlpha:0.12];
    if ([self.viewModel isKindOfClass:[CJPayBankCardActivityItemViewModel class]] &&
        [(CJPayBankCardActivityItemViewModel *)self.viewModel isLastBankActivityRowViewModel]) {
        [CJPayLineUtil cj_drawLines:CJPayLineLeft | CJPayLineRight | CJPayLineBottom
                 withRoundedCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight
                             radius:4
                           viewRect:CGRectMake(16, 0, self.cj_width - 32, self.cj_height)
                              color:lineColor];
    } else {
        [CJPayLineUtil cj_drawLines:CJPayLineLeft | CJPayLineRight
                 withRoundedCorners:UIRectCornerAllCorners
                             radius:0
                           viewRect:CGRectMake(16, 0, self.cj_width - 32, self.cj_height)
                              color:lineColor];
    }
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    
    if ([viewModel isKindOfClass:[CJPayBankCardActivityItemViewModel class]]) {
        CJPayBankCardActivityItemViewModel *itemViewModel = (CJPayBankCardActivityItemViewModel *)viewModel;
        
        [self.activityViewsArray enumerateObjectsUsingBlock:^(CJPayBankCardBankActivityView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
            view.didSelectedBlock = itemViewModel.didSelectedBlock;
            view.buttonClickBlock = itemViewModel.buttonClickBlock;
            [view bindBankActivityModel:[itemViewModel.activityInfoModelArray cj_objectAtIndex:idx]];
        }];
        
        self.contentBGView.layer.cornerRadius = itemViewModel.isLastBankActivityRowViewModel ? 4 : 0;
    } else {
        [self.activityViewsArray enumerateObjectsUsingBlock:^(CJPayBankCardBankActivityView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
            CJPayBankActivityInfoModel *activityInfoModel = [CJPayBankActivityInfoModel new];
            activityInfoModel.isEmptyResource = YES;
            [view bindBankActivityModel:activityInfoModel];
        }];
    }
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayThemeModeType currentThemeModel = [self cj_responseViewController].cj_currentThemeMode;
        
        if (currentThemeModel == CJPayThemeModeTypeDark) {
            self.contentBGView.backgroundColor = [UIColor cj_ffffffWithAlpha:0.03];
        } else if (currentThemeModel == CJPayThemeModeTypeLight) {
            self.contentBGView.backgroundColor = [UIColor clearColor];
        }
    }
}

#pragma mark - lazy view
- (UIView *)contentBGView {
    if (!_contentBGView) {
        _contentBGView = [UIView new];
    }
    return _contentBGView;
}

- (NSArray<CJPayBankCardBankActivityView *> *)activityViewsArray {
    if (!_activityViewsArray) {
        _activityViewsArray = @[[CJPayBankCardBankActivityView new], [CJPayBankCardBankActivityView new]];
    }
    return _activityViewsArray;
}

@end

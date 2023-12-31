//
//  CJPayQuickBindCardQuickFrontHeaderView.m
//  Pods
//
//  Created by renqiang on 2021/6/29.
//

#import "CJPayQuickBindCardQuickFrontHeaderView.h"
#import "CJPayQuickBindCardQuickFrontHeaderViewModel.h"
#import "CJPayLineUtil.h"
#import "CJPayUIMacro.h"
#import "CJPayLocalThemeStyle.h"
#import "UIView+CJTheme.h"

@interface CJPayQuickBindCardQuickFrontHeaderView()

#pragma mark - view
@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UIView *bottomLine;

@end

@implementation CJPayQuickBindCardQuickFrontHeaderView

- (void)setupUI {
    [super setupUI];
    
    [self.containerView addSubview:self.mainTitleLabel];
    [self.containerView addSubview:self.subTitleLabel];
    
    self.bottomLine = [CJPayLineUtil addBottomLineToView:self.containerView
                            marginLeft:8
                           marginRight:8
                          marginBottom:0];
    self.bottomLine.backgroundColor = [UIColor cj_161823WithAlpha:0.06];
    
    CJPayMasMaker(self.mainTitleLabel, {
        make.top.equalTo(self.containerView).offset(13);
        make.bottom.lessThanOrEqualTo(self.containerView);
        make.left.equalTo(self.containerView).offset(24);
        make.right.lessThanOrEqualTo(self.containerView);
    });
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(3);
        make.bottom.equalTo(self.containerView).offset(-12);
        make.left.equalTo(self.mainTitleLabel);
        make.right.lessThanOrEqualTo(self.containerView).offset(-16);
    });
}

- (void)drawRect:(CGRect)rect {
    [self.containerView cj_innerRect:CGRectMake(4, 0, self.containerView.cj_width - 16, self.containerView.cj_height)
                          rectCorner:UIRectCornerTopLeft | UIRectCornerTopRight
                        cornerRadius:CGSizeMake(8, 8)
                           fillColor:[UIColor cj_ffffffWithAlpha:1]
                         strokeColor:[UIColor cj_ffffffWithAlpha:1]];
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    if ([viewModel isKindOfClass:[CJPayQuickBindCardQuickFrontHeaderViewModel class]]) {
        CJPayQuickBindCardQuickFrontHeaderViewModel *headerViewModel = (CJPayQuickBindCardQuickFrontHeaderViewModel *)viewModel;
        if (Check_ValidString(headerViewModel.title)) {
            self.mainTitleLabel.text = CJString(headerViewModel.title);
        }
        if (Check_ValidString(headerViewModel.subTitle)) {
            self.subTitleLabel.text = headerViewModel.subTitle;
        } else {
            CJPayMasReMaker(self.mainTitleLabel, {
                make.centerY.equalTo(self.containerView);
                make.left.equalTo(self.containerView).offset(24);
                make.right.lessThanOrEqualTo(self.containerView);
            });
        }
    }
}

#pragma mark - lazy views
- (UILabel *)mainTitleLabel {
    if (!_mainTitleLabel) {
        _mainTitleLabel = [UILabel new];
        _mainTitleLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].quickBindCardTitleTextColor;
        _mainTitleLabel.font = [UIFont cj_boldFontOfSize:14];
    }
    return _mainTitleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].quickBindCardDescTextColor;
        _subTitleLabel.font = [UIFont cj_fontOfSize:12];
        _subTitleLabel.numberOfLines = 0;
    }
    return _subTitleLabel;
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        self.mainTitleLabel.textColor = localTheme.quickBindCardTitleTextColor;
    }
}

@end

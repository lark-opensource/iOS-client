//
//  CJPayQuickBindCardTipsView.m
//  Pods
//
//  Created by xiuyuanLee on 2021/3/4.
//

#import "CJPayQuickBindCardTipsView.h"

#import "CJPayQuickBindCardTipsViewModel.h"
#import "CJPayUIMacro.h"

@interface CJPayQuickBindCardTipsView ()

@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;

@end

@implementation CJPayQuickBindCardTipsView

- (void)setupUI {
    [super setupUI];
    
    [self.containerView addSubview:self.tipsLabel];
    [self.containerView addSubview:self.arrowImageView];
    
    CJPayMasMaker(self.tipsLabel, {
        make.top.equalTo(self.containerView).offset(16);
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
    })
}

- (void)drawRect:(CGRect)rect {
    [self.containerView cj_innerRect:CGRectMake(4, 0, self.containerView.cj_width - 16, self.containerView.cj_height)
                          rectCorner:UIRectCornerBottomLeft | UIRectCornerBottomRight
                        cornerRadius:CGSizeMake(8, 8)
                           fillColor:[UIColor cj_ffffffWithAlpha:1]
                         strokeColor:[UIColor cj_ffffffWithAlpha:1]];
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    
    if ([self.viewModel isKindOfClass:[CJPayQuickBindCardTipsViewModel class]]) {
        CJPayQuickBindCardTipsViewModel *cardTipsViewModel = (CJPayQuickBindCardTipsViewModel *)self.viewModel;
        self.viewStyle = cardTipsViewModel.viewStyle;
        self.tipsLabel.text = [cardTipsViewModel getContent];
        
        CJPayMasReMaker(self.tipsLabel, {
            make.top.equalTo(self.containerView).offset(11);
            make.bottom.equalTo(self.containerView).offset(-11);
            make.left.equalTo(self.containerView).offset(58);
        })
        
        CJPayMasMaker(self.arrowImageView, {
            make.right.equalTo(self.containerView).offset(-16);
            make.centerY.equalTo(self.containerView);
            make.width.height.mas_equalTo(24);
        })
    }
}

- (void)didSelect {
    if (CJOptionsHasValue(self.viewStyle, CJPayBindCardStyleUnfold) && [self.viewModel isKindOfClass:[CJPayQuickBindCardTipsViewModel class]]) {
        CJPayQuickBindCardTipsViewModel *viewModel = (CJPayQuickBindCardTipsViewModel *) self.viewModel;
        CJ_CALL_BLOCK(viewModel.didClickBlock);
    }
}

#pragma mark - lazy views
- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [UILabel new];
        _tipsLabel.font = [UIFont cj_fontOfSize:14];
        _tipsLabel.textColor = [UIColor cj_161823ff];
        _tipsLabel.layer.opacity = 0.5;
        _tipsLabel.numberOfLines = 0;
    }
    return _tipsLabel;
}

- (UIImageView *)arrowImageView
{
    if (!_arrowImageView) {
        _arrowImageView = [UIImageView new];
        [_arrowImageView cj_setImage:@"cj_quick_bindcard_arrow_light_icon"];
    }
    return _arrowImageView;
}

@end

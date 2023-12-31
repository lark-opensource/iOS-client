//
//  CJPayDyPayMethodNumAdjustCell.m
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/25.
//

#import "CJPayDyPayMethodNumAdjustCell.h"
#import "CJPayUIMacro.h"
#import "CJPayDyPayMethodAdjustCellViewModel.h"

@interface CJPayDyPayMethodNumAdjustCell ()

@property (nonatomic, strong) UILabel *descLabel; //描述文案
@property (nonatomic, strong) UIImageView *arrowImageView; // 折叠/展开箭头图标

@property (nonatomic, strong) UIImage *payMethodFoldImage;
@property (nonatomic, strong) UIImage *payMethodUnFoldImage;

@end

@implementation CJPayDyPayMethodNumAdjustCell

- (void)setupUI {
    [super setupUI];
    [self.containerView addSubview:self.descLabel];
    [self.containerView addSubview:self.arrowImageView];
    
    CJPayMasMaker(self.descLabel, {
        make.left.equalTo(self.containerView).offset(44);
        make.centerY.equalTo(self.containerView);
    });
    
    CJPayMasMaker(self.arrowImageView, {
        make.left.equalTo(self.descLabel.mas_right);
        make.centerY.equalTo(self.descLabel);
        make.width.height.mas_equalTo(16);
    });
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    if ([viewModel isKindOfClass:CJPayDyPayMethodAdjustCellViewModel.class]) {
        CJPayDyPayMethodAdjustCellViewModel *adjustViewModel = (CJPayDyPayMethodAdjustCellViewModel *)viewModel;
        
        NSString *defaultFoldDesc = CJPayLocalizedStr(@"更多优惠银行");
        NSString *foldDesc = Check_ValidString(adjustViewModel.addBankCardFoldDesc) ? adjustViewModel.addBankCardFoldDesc : defaultFoldDesc;
        
        if (adjustViewModel.isInFoldStatus) {
            [self.arrowImageView cj_setImage:@"cj_paymethod_unfold_arrow_icon"];
            self.descLabel.text = CJConcatStr(CJPayLocalizedStr(@"展开"), foldDesc);
        } else {
            [self.arrowImageView cj_setImage:@"cj_paymethod_fold_arrow_icon"];
            self.descLabel.text = CJConcatStr(CJPayLocalizedStr(@"收起"), foldDesc);
        }
    }
}

- (void)didSelect {
    if ([self.viewModel isKindOfClass:CJPayDyPayMethodAdjustCellViewModel.class]) {
        CJPayDyPayMethodAdjustCellViewModel *adjustViewModel = (CJPayDyPayMethodAdjustCellViewModel *)self.viewModel;
        CJ_CALL_BLOCK(adjustViewModel.clickBlock, adjustViewModel.isInFoldStatus);
    }
}

- (UILabel *)descLabel {
    if (!_descLabel) {
        _descLabel = [UILabel new];
        _descLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _descLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _descLabel;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [UIImageView new];
    }
    return _arrowImageView;
}

@end

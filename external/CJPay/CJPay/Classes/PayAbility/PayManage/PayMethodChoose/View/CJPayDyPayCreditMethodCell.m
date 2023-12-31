//
//  CJPayDyPayCreditMethodCell.m
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/26.
//

#import "CJPayDyPayCreditMethodCell.h"
#import "CJPayDyPayCreditMethodCellViewModel.h"
#import "CJPayUIMacro.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayBytePayMethodCreditPayCollectionView.h"
#import "CJPayStyleCheckMark.h"
#import "CJPayMethodCellTagView.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayBytePayCreditPayMethodModel.h"
#import "CJPayLineUtil.h"

@interface CJPayDyPayCreditMethodCell ()

@property (nonatomic, strong) UIImageView *creditIconView; //支付方式图标
@property (nonatomic, strong) UILabel *titleLabel; //支付方式名称
@property (nonatomic, strong) UILabel *subTitleLabel; //副标题
@property (nonatomic, strong) UILabel *descTitleLabel; // 描述，用于展示背书文案，可以和副标题同时存在
@property (nonatomic, strong) UIView *disableView; //支付方式不可用蒙层
@property (nonatomic, strong) CJPayStyleCheckMark *confirmImageView; //勾选图案
@property (nonatomic, strong) UIImageView *rightArrowImage; // 右箭头
@property (nonatomic, strong) CJPayMethodCellTagView *discountView; //营销信息（无分期栏时才可能展示）
@property (nonatomic, strong) CJPayBytePayMethodCreditPayCollectionView *collectionView; //月付分期栏
@property (nonatomic, copy) NSArray<CJPayBytePayCreditPayMethodModel> *creditPayMethods;

@property (nonatomic, strong) MASConstraint *titleLabelTopBaseContainerViewConstraint;
@property (nonatomic, strong) MASConstraint *titleLabelCenterYBaseContainerViewConstraint;
@end


@implementation CJPayDyPayCreditMethodCell

- (void)setupUI {
    [super setupUI];
    [self.containerView addSubview:self.creditIconView];
    [self.containerView addSubview:self.titleLabel];
    [self.containerView addSubview:self.subTitleLabel];
    [self.containerView addSubview:self.confirmImageView];
    [self.containerView addSubview:self.rightArrowImage];
    [self.containerView addSubview:self.discountView];
    [self.containerView addSubview:self.collectionView];
    [self.containerView addSubview:self.descTitleLabel];
    [self.containerView addSubview:self.disableView];
    
    CJPayMasMaker(self.creditIconView, {
        make.left.equalTo(self.containerView).offset(16);
        make.centerY.equalTo(self.titleLabel);
        make.width.height.mas_equalTo(18);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.left.equalTo(self.creditIconView.mas_right).offset(10);
        make.right.lessThanOrEqualTo(self.containerView).offset(-32);
        self.titleLabelCenterYBaseContainerViewConstraint = make.centerY.equalTo(self.containerView);
        self.titleLabelTopBaseContainerViewConstraint = make.top.equalTo(self.containerView).offset(10);
    });
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(2);
        make.left.equalTo(self.titleLabel);
        make.right.lessThanOrEqualTo(self.containerView).offset(-8);
    });
    
    CJPayMasMaker(self.confirmImageView, {
        make.centerY.equalTo(self.titleLabel);
        make.right.equalTo(self.containerView).offset(-16);
        make.width.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.rightArrowImage, {
        make.centerY.equalTo(self.titleLabel);
        make.right.equalTo(self.containerView).offset(-16);
        make.width.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.discountView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(2);
        make.left.equalTo(self.titleLabel);
        make.right.lessThanOrEqualTo(self.containerView).offset(-8);
        make.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.collectionView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(12);
        make.height.mas_equalTo(58);
        make.left.equalTo(self.titleLabel);
        make.right.equalTo(self.containerView).offset(-16);
    });
    
    CJPayMasMaker(self.descTitleLabel, {
        make.left.equalTo(self.titleLabel);
        make.right.lessThanOrEqualTo(self.rightArrowImage.mas_left);
        make.bottom.equalTo(self.containerView).offset(-10);
        make.height.mas_equalTo(15);
    });
    
    CJPayMasMaker(self.disableView, {
        make.top.equalTo(self.containerView).offset(1);
        make.left.right.equalTo(self.containerView);
        make.bottom.equalTo(self.containerView).offset(-1);
    });
}

#pragma mark - viewModel
- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    if ([viewModel isKindOfClass:CJPayDyPayCreditMethodCellViewModel.class]) {
        CJPayDyPayCreditMethodCellViewModel *payMethodCellViewModel = (CJPayDyPayCreditMethodCellViewModel *)viewModel;
        [self p_reloadContentWithViewModel:payMethodCellViewModel];
        [self p_updateLayoutWithViewModel:payMethodCellViewModel];
    }
}

- (void)p_reloadContentWithViewModel:(CJPayDyPayCreditMethodCellViewModel *)viewModel {
    CJPayDefaultChannelShowConfig *config = viewModel.showConfig;
    [self.creditIconView cj_setImageWithURL:[NSURL URLWithString:config.iconUrl]
                              placeholder:[UIImage cj_roundImageWithColor:[UIColor cj_skeletonScreenColor]]];
    self.titleLabel.text = CJString(config.title);
    self.subTitleLabel.text = CJString(config.subTitle);
    [self.confirmImageView setSelected:config.isSelected];
    [self.discountView updateTitle:CJString(config.discountStr)];
    self.descTitleLabel.text = CJString(config.descTitle);
}

- (void)p_updateLayoutWithViewModel:(CJPayDyPayCreditMethodCellViewModel *)viewModel {
    
    // 需要展示上方分割线
    if (viewModel.needAddTopLine) {
        [CJPayLineUtil addTopLineToView:self.containerView
                             marginLeft:44
                            marginRight:-16
                              marginTop:-6.25
                                  color:[UIColor cj_161823WithAlpha:0.08]];
    }
    
    CJPayDefaultChannelShowConfig *config = viewModel.showConfig;
    self.subTitleLabel.hidden = YES;
    self.confirmImageView.hidden = !(config.canUse && config.payTypeData.isCreditActivate);
    self.rightArrowImage.hidden = config.payTypeData.isCreditActivate;
    self.disableView.hidden = config.canUse;
    self.descTitleLabel.hidden = !Check_ValidString(config.descTitle);
    self.collectionView.hidden = YES;
    self.discountView.hidden = YES;
    self.descTitleLabel.textColor = config.enable ? [UIColor cj_161823WithAlpha:0.5] : [UIColor cj_161823ff];
    
    if (Check_ValidString(config.subTitle)) {
        self.subTitleLabel.hidden = NO;
        if (Check_ValidString(config.subTitleColor) && [UIColor cj_colorWithHexString:config.subTitleColor]) {
            self.subTitleLabel.textColor = [UIColor cj_colorWithHexString:config.subTitleColor];
        }
    } else if (config.canUse) {
        if (Check_ValidArray(config.payTypeData.creditPayMethods)) {
            self.collectionView.hidden = NO;
            self.collectionView.creditPayMethods = config.payTypeData.creditPayMethods;
            [self.collectionView reloadData];
        } else if (Check_ValidString(config.discountStr)) { // 无分期栏但是有营销时，在标题下方展示营销标签
            self.discountView.hidden = NO;
        }
    }
    
    BOOL shouldLayoutTopBase = Check_ValidString(config.subTitle) ||
                               (config.canUse && Check_ValidString(config.discountStr)) ||
                               (config.canUse && Check_ValidArray(config.payTypeData.creditPayMethods)) ||
                               Check_ValidString(config.descTitle);
    //有副标题｜有背书本案｜有营销｜有分期选项都需要居顶布局
    if (shouldLayoutTopBase) {
        // 有副标题或有营销或有背书文案时不居中展示
        [self.titleLabelTopBaseContainerViewConstraint activate];
        [self.titleLabelCenterYBaseContainerViewConstraint deactivate];
    } else {
        [self.titleLabelTopBaseContainerViewConstraint deactivate];
        [self.titleLabelCenterYBaseContainerViewConstraint activate];
    }
}

- (void)didSelect {
    if ([self.viewModel isKindOfClass:[CJPayDyPayCreditMethodCellViewModel class]]) {
        CJPayDyPayCreditMethodCellViewModel *payMethodModel = (CJPayDyPayCreditMethodCellViewModel *)self.viewModel;
        CJ_CALL_BLOCK(payMethodModel.didSelectedBlock, payMethodModel.showConfig);
    }
}

#pragma mark - lazy init
- (UIImageView *)creditIconView {
    if (!_creditIconView) {
        _creditIconView = [UIImageView new];
    }
    return _creditIconView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.font = [UIFont cj_fontOfSize:15];
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel
{
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.textColor = [UIColor cj_161823ff];
        _subTitleLabel.font = [UIFont cj_fontOfSize:13];
    }
    return _subTitleLabel;
}

- (CJPayStyleCheckMark *)confirmImageView {
    if (!_confirmImageView) {
        _confirmImageView = [[CJPayStyleCheckMark alloc] initWithDiameter:16];
        _confirmImageView.backgroundColor = [UIColor whiteColor];
    }
    return _confirmImageView;
}

- (UIView *)disableView {
    if (!_disableView) {
        _disableView = [UIView new];
        _disableView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.7];
    }
    return _disableView;
}

- (UIImageView *)rightArrowImage {
    if (!_rightArrowImage) {
        _rightArrowImage = [UIImageView new];
        [_rightArrowImage cj_setImage:@"cj_combine_pay_arrow_denoise_icon"];
    }
    return _rightArrowImage;
}

- (CJPayMethodCellTagView *)discountView {
    if (!_discountView) {
        _discountView = [CJPayMethodCellTagView new];
        _discountView.hidden = YES;
    }
    return _discountView;
}

- (CJPayBytePayMethodCreditPayCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[CJPayBytePayMethodCreditPayCollectionView alloc] init];
        _collectionView.scrollAnimated = NO;
        @CJWeakify(self)
        _collectionView.clickBlock = ^(NSString * _Nonnull installment) {
            @CJStrongify(self)
            if ([self.viewModel isKindOfClass:[CJPayDyPayCreditMethodCellViewModel class]]) {
                CJPayDyPayCreditMethodCellViewModel *payMethodModel = (CJPayDyPayCreditMethodCellViewModel *)self.viewModel;
                payMethodModel.creditInstallment = installment;
                [self didSelect];
            }
        };
    }
    return _collectionView;
}

- (UILabel *)descTitleLabel {
    if (!_descTitleLabel) {
        _descTitleLabel = [UILabel new];
        _descTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _descTitleLabel.font = [UIFont cj_fontOfSize:11];
    }
    return _descTitleLabel;
}

@end

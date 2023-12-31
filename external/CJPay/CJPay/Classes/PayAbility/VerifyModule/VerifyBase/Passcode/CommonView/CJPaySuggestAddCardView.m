//
//  CJPaySuggestAddCardView.m
//  CJPaySandBox
//
//  Created by xutianxi on 2023/5/23.
//

#import "CJPaySuggestAddCardView.h"
#import "CJPayBytePayMethodCell.h"
#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"
#import "CJPayMethodCellTagView.h"

@interface CJPaySuggestAddCardView ()

@property (nonatomic, strong) NSMutableArray <CJPayBytePayMethodCell *> *suggestViewArray;
@property (nonatomic, strong) UILabel *moreBankTipsLabel;
@property (nonatomic, strong) UIImageView *rightArrowImage;
@property (nonatomic, assign) CJPaySuggestAddCardViewStyle style;

@end

@implementation CJPaySuggestAddCardView

#pragma mark - init & setup ui

- (instancetype)init {
    return [self initWithStyle:CJPaySuggestAddCardViewStyleWithSuggestCard];
}

- (void)dealloc {
    [_suggestViewArray removeAllObjects];
}

- (instancetype)initWithStyle:(CJPaySuggestAddCardViewStyle)style {
    self = [super init];
    if (self) {
        self.suggestViewArray = [NSMutableArray new];
        self.style = style;
    }
    
    return self;
}

- (void)p_setupUI:(NSArray <CJPayChannelBizModel *>*)modelArray {
    if (modelArray.count == 0)
        return;
    
    self.backgroundColor = [UIColor cj_colorWithHexString:@"#f8f8f8" alpha:0.8];
    self.layer.cornerRadius = 8;
    self.layer.masksToBounds = YES;
    CJPayBytePayMethodCell *lastCellView;
    if (self.style == CJPaySuggestAddCardViewStyleWithoutSuggestCard) {
        CJPayBytePayMethodCell *cell = [CJPayBytePayMethodCell new];
        [self addSubview:cell];
        
        if (Check_ValidString(modelArray[0].discountStr)) {
            modelArray[0].channelConfig.mark = modelArray[0].discountStr;
            modelArray[0].discountStr = @"";
        }
        
        [cell updateContent:modelArray[0]];
        cell.rightArrowImage.hidden = YES;
        CJPayMasUpdate(cell.bankIconView, {
            make.width.height.mas_equalTo(20);
        });
        cell.titleLabel.textColor = [UIColor cj_161823ff];
        cell.titleLabel.font = [UIFont cj_fontOfSize:14];
        cell.confirmImageView.hidden = NO;
        cell.confirmImageView.selected = YES;
        
        CJPayMasMaker(cell, {
            make.top.equalTo(self).offset(4);
            make.right.left.equalTo(self);
            make.height.mas_equalTo(52);
        });
        
        [self addSubview:self.moreBankTipsLabel];
        CJPayMasMaker(self.moreBankTipsLabel, {
            make.top.equalTo(cell.titleLabel.mas_bottom).offset(4);
            make.left.equalTo(cell.titleLabel);
            make.bottom.equalTo(self).offset(-20);
        });
    } else {
        UIView *lastView = self;
        for (int i=0; i<3 && i<modelArray.count; i++) {
            CJPayBytePayMethodCell *cell = [CJPayBytePayMethodCell new];
            [self addSubview:cell];
            if (Check_ValidString(modelArray[i].discountStr)) {
                modelArray[i].channelConfig.mark = modelArray[i].discountStr;
                modelArray[i].discountStr = @"";
            }
            
            [cell updateContent:modelArray[i]];
            cell.rightArrowImage.hidden = YES;
            CJPayMasUpdate(cell.bankIconView, {
                make.width.height.mas_equalTo(20);
            });
            cell.titleLabel.textColor = [UIColor cj_161823ff];
            cell.titleLabel.font = [UIFont cj_fontOfSize:14];
            cell.confirmImageView.hidden = NO;
            if (i == 0) {
                // 默认选择第一个
                cell.confirmImageView.selected = YES;
            }
            [self.suggestViewArray addObject:cell];
            CJPayMasMaker(cell, {
                make.right.left.equalTo(self);
                if (i==0) {
                    make.top.equalTo(self);
                } else {
                    make.top.equalTo(lastView.mas_bottom);
                }
                make.height.mas_equalTo(52);
            });
            [CJPayLineUtil addBottomLineToView:cell marginLeft:44 marginRight:0 marginBottom:1 color:[UIColor cj_161823WithAlpha:0.04]];
            lastView = cell;
            lastCellView = cell;
        }
        
        [self addSubview:self.moreBankTipsLabel];
        CJPayMasMaker(self.moreBankTipsLabel, {
            make.top.equalTo(lastCellView.mas_bottom).offset(16);
            make.left.equalTo(lastCellView.titleLabel);
            make.bottom.equalTo(self).offset(-16);
        });
        [self addSubview:self.rightArrowImage];
        CJPayMasMaker(self.rightArrowImage, {
            make.centerY.equalTo(self.moreBankTipsLabel);
            make.left.equalTo(self.moreBankTipsLabel.mas_right).offset(2);
        });
        
        [self p_addTapGesture];
    }
    
}

- (void)updateContent:(NSArray <CJPayChannelBizModel *>*)modelArray {
    if (!modelArray.count) {
        return;
    }
    [self.suggestViewArray removeAllObjects];
    [self cj_removeAllSubViews];
    
    [self p_setupUI:modelArray];
    return;
}

#pragma mark - click event

- (void)p_tapClick:(UITapGestureRecognizer *)sender {
    if (![sender.view isKindOfClass:CJPayBytePayMethodCell.class]) {
        return;
    }
    
    CJPayBytePayMethodCell *clickedView = (CJPayBytePayMethodCell *)sender.view;
    if (clickedView.confirmImageView.selected) {
        return;
    }
    
    [self.suggestViewArray enumerateObjectsUsingBlock:^(CJPayBytePayMethodCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (clickedView == obj) {
            clickedView.confirmImageView.selected = YES;
            CJ_CALL_BLOCK(self.didSelectedNewSuggestBankBlock, idx);
        } else {
            obj.confirmImageView.selected = NO;
        }
    }];
}

- (void)p_tapMoreBankClick {
    CJ_CALL_BLOCK(self.didClickedMoreBankBlock);
}

#pragma mark - private func

- (void)p_addTapGesture {
    [self.suggestViewArray enumerateObjectsUsingBlock:^(CJPayBytePayMethodCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UITapGestureRecognizer *tapGesture1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_tapClick:)];
        [obj addGestureRecognizer:tapGesture1];
    }];

    UITapGestureRecognizer *tapGesture4 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_tapMoreBankClick)];
    [self.moreBankTipsLabel addGestureRecognizer:tapGesture4];
    self.moreBankTipsLabel.userInteractionEnabled = YES;
}

#pragma mark - getter

- (UIImageView *)rightArrowImage {
    if (!_rightArrowImage) {
        _rightArrowImage = [UIImageView new];
        [_rightArrowImage cj_setImage:@"cj_combine_pay_arrow_denoise_icon"];
    }
    return _rightArrowImage;
}

- (UILabel *)moreBankTipsLabel {
    if (!_moreBankTipsLabel) {
        _moreBankTipsLabel = [UILabel new];
        _moreBankTipsLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _moreBankTipsLabel.font = [UIFont cj_fontOfSize:12];
        [_moreBankTipsLabel setContentHuggingPriority:UILayoutPriorityRequired
                                              forAxis:UILayoutConstraintAxisVertical];
        [_moreBankTipsLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                            forAxis:UILayoutConstraintAxisVertical];
    }
    return _moreBankTipsLabel;
}

@end

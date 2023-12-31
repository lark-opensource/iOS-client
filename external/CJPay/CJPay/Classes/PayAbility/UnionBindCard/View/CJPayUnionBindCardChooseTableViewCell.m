//
//  CJPayUnionBindCardChooseTableViewCell.m
//  Pods
//
//  Created by wangxiaohong on 2021/9/24.
//

#import "CJPayUnionBindCardChooseTableViewCell.h"

#import "CJPayUIMacro.h"
#import "CJPayStyleCheckMark.h"
#import "CJPayUnionCardInfoModel.h"

@interface CJPayUnionBindCardChooseTableViewCell()

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *bankCardLabel;
@property (nonatomic, strong) CJPayStyleCheckMark *selectView;
@property (nonatomic, strong) UILabel *rightLabel;
@property (nonatomic, strong) UIView *disabledView;

@end

@implementation CJPayUnionBindCardChooseTableViewCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    
    self.selectView.selected = isSelected;
}

- (void)updateWithUnionCardInfoModel:(CJPayUnionCardInfoModel *)model {
    [self.iconImageView cj_setImageWithURL:[NSURL URLWithString:CJString(model.iconUrl)]];
    NSString *cardNoMask = @"";
    if (model.cardNoMask.length >= 4) {
        cardNoMask = [model.cardNoMask substringFromIndex:model.cardNoMask.length - 4];
    }
    self.bankCardLabel.text = [NSString stringWithFormat:@"%@%@(%@)", model.bankName, [model.cardType isEqualToString:@"DEBIT"] ? @"储蓄卡" : @"信用卡", CJString(cardNoMask)];
    if ([model.status isEqualToString:@"1"]) {
        self.selectView.hidden = NO;
        self.rightLabel.hidden = YES;
        self.disabledView.hidden = YES;
    } else {
        self.selectView.hidden = YES;
        self.rightLabel.hidden = NO;
        self.disabledView.hidden = NO;
        
        self.rightLabel.text = CJString(model.displayDesc);
    }
}

- (void)p_setupUI {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.contentView addSubview:self.bgView];
    [self.bgView addSubview:self.iconImageView];
    [self.bgView addSubview:self.bankCardLabel];
    [self.bgView addSubview:self.selectView];
    [self.bgView addSubview:self.rightLabel];
    [self.bgView addSubview:self.disabledView];
    
    CJPayMasMaker(self.bgView, {
        make.top.equalTo(self.contentView).offset(6);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.bottom.equalTo(self.contentView).offset(-6);
    });
    
    CJPayMasMaker(self.iconImageView, {
        make.left.equalTo(self.bgView).offset(18);
        make.width.height.mas_equalTo(20);
        make.centerY.equalTo(self.bgView);
    })
    
    CJPayMasMaker(self.bankCardLabel, {
        make.left.equalTo(self.iconImageView.mas_right).offset(8);
        make.centerY.equalTo(self.bgView);
        make.right.lessThanOrEqualTo(self.selectView.mas_left).offset(-28);
    })
    
    CJPayMasMaker(self.selectView, {
        make.right.equalTo(self.bgView).offset(-16);
        make.width.height.mas_equalTo(20);
        make.centerY.equalTo(self.bgView);
    })
    
    CJPayMasMaker(self.rightLabel, {
        make.right.equalTo(self.bgView).offset(-16);
        make.centerY.equalTo(self.bgView);
        make.left.greaterThanOrEqualTo(self.bankCardLabel.mas_right);
    })
    
    CJPayMasMaker(self.disabledView, {
        make.edges.equalTo(self.bgView);
    })
}

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [UIView new];
        _bgView.layer.cornerRadius = 4;
        _bgView.layer.borderWidth = 0.5;
        _bgView.layer.borderColor = [UIColor cj_161823WithAlpha:0.15].CGColor;
        _bgView.backgroundColor = [UIColor cj_colorWithHexString:@"#FFFFFF"];
    }
    return _bgView;
}

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [UIImageView new];
        _iconImageView.layer.cornerRadius = 12;
    }
    return _iconImageView;
}

- (UILabel *)bankCardLabel {
    if (!_bankCardLabel) {
        _bankCardLabel = [UILabel new];
        _bankCardLabel.font = [UIFont cj_fontOfSize:15];
        _bankCardLabel.textColor = [UIColor cj_161823ff];
        _bankCardLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _bankCardLabel;
}

- (CJPayStyleCheckMark *)selectView {
    if (!_selectView) {
        _selectView = [CJPayStyleCheckMark new];
        _selectView.selected = NO;
    }
    return _selectView;
}

- (UILabel *)rightLabel {
    if (!_rightLabel) {
        _rightLabel = [UILabel new];
        _rightLabel.font = [UIFont cj_fontOfSize:12];
        _rightLabel.textColor = [UIColor cj_161823ff];
    }
    return _rightLabel;
}

- (UIView *)disabledView {
    if (!_disabledView) {
        _disabledView = [UIView new];
        _disabledView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.7];
        _disabledView.hidden = YES;
    }
    return _disabledView;
}

@end

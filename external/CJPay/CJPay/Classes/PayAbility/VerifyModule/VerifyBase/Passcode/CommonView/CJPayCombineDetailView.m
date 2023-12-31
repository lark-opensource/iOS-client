//
//  CJPayCombineDetailView.m
//  Pods
//
//  Created by liutianyi on 2022/5/23.
//

#import "CJPayCombineDetailView.h"
#import "CJPayUIMacro.h"
#import "CJPayInfo.h"

@interface CJPayCombineDetailView ()

@property (nonatomic, strong) UILabel *cashTiteLabel;
@property (nonatomic, strong) UILabel *cashAMountLabel;
@property (nonatomic, strong) UILabel *cardTiteLabel;
@property (nonatomic, strong) UILabel *cardAMountLabel;

@end

@implementation CJPayCombineDetailView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)updateWithCombineShowInfo:(NSArray<BDPayCombinePayShowInfo *> *)combineShowInfo {
    self.cashTiteLabel.text = combineShowInfo.firstObject.combineType;
    self.cashAMountLabel.text = combineShowInfo.firstObject.combineMsg;
    self.cardTiteLabel.text = combineShowInfo.lastObject.combineType;
    self.cardAMountLabel.text = combineShowInfo.lastObject.combineMsg;
}

- (void)p_setupUI {
    [self addSubview:self.cashTiteLabel];
    [self addSubview:self.cashAMountLabel];
    [self addSubview:self.cardTiteLabel];
    [self addSubview:self.cardAMountLabel];
    
    CJPayMasMaker(self.cashTiteLabel, {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo(17);
    });
    
    CJPayMasMaker(self.cashAMountLabel, {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo(17);
    });
        
    CJPayMasMaker(self.cardTiteLabel, {
        make.bottom.left.right.equalTo(self);
        make.height.mas_equalTo(17);
    });
        
    CJPayMasMaker(self.cardAMountLabel, {
        make.bottom.left.right.equalTo(self);
        make.height.mas_equalTo(17);
    });
}

- (UILabel *)cashTiteLabel {
    if (!_cashTiteLabel) {
        _cashTiteLabel = [[UILabel alloc] init];
        _cashTiteLabel.font = [UIFont cj_fontOfSize:13];
        _cashTiteLabel.numberOfLines = 1;
        _cashTiteLabel.textAlignment = NSTextAlignmentLeft;
        _cashTiteLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
    }
    return _cashTiteLabel;
}

- (UILabel *)cashAMountLabel {
    if (!_cashAMountLabel) {
        _cashAMountLabel = [[UILabel alloc] init];
        _cashAMountLabel.font = [UIFont cj_fontOfSize:13];
        _cashAMountLabel.numberOfLines = 1;
        _cashAMountLabel.textAlignment = NSTextAlignmentRight;
        _cashAMountLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
    }
    return _cashAMountLabel;
}

- (UILabel *)cardTiteLabel {
    if (!_cardTiteLabel) {
        _cardTiteLabel = [[UILabel alloc] init];
        _cardTiteLabel.font = [UIFont cj_fontOfSize:13];
        _cardTiteLabel.numberOfLines = 1;
        _cardTiteLabel.textAlignment = NSTextAlignmentLeft;
        _cardTiteLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
    }
    return _cardTiteLabel;
}

- (UILabel *)cardAMountLabel {
    if (!_cardAMountLabel) {
        _cardAMountLabel = [[UILabel alloc] init];
        _cardAMountLabel.font = [UIFont cj_fontOfSize:13];
        _cardAMountLabel.numberOfLines = 1;
        _cardAMountLabel.textAlignment = NSTextAlignmentRight;
        _cardAMountLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
    }
    return _cardAMountLabel;
}

@end

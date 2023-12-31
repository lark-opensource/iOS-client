//
//  CJPayUnionBindCardAuthenticationView.m
//  Pods
//
//  Created by chenbocheng on 2021/9/26.
//

#import "CJPayUnionBindCardAuthenticationView.h"

#import "CJPayUIMacro.h"

@interface CJPayUnionBindCardAuthenticationView ()

@property (nonatomic, strong) UIImageView *leftIconOne;
@property (nonatomic, strong) UIImageView *leftIconTwo;
@property (nonatomic, strong) UIImageView *leftIconThree;
@property (nonatomic, strong) UILabel *nameTitleLabel;
@property (nonatomic, strong) UILabel *IDTitleLabel;
@property (nonatomic, strong) UILabel *phoneNumTitleLabel;
@property (nonatomic, strong) UILabel *nameSubTitleLabel;
@property (nonatomic, strong) UILabel *IDSubTitleLabel;
@property (nonatomic, strong) UILabel *phoneNumSubTitleLabel;

@end

@implementation CJPayUnionBindCardAuthenticationView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)updateContentName:(NSString *)name idNum:(NSString *)idNum phoneNum:(NSString *)phoneNum {
    self.nameSubTitleLabel.text = name;
    self.IDSubTitleLabel.text = idNum;
    self.phoneNumSubTitleLabel.text = phoneNum;
}

- (void)p_setupUI {
    [self addSubview:self.leftIconOne];
    [self addSubview:self.leftIconTwo];
    [self addSubview:self.leftIconThree];
    [self addSubview:self.nameTitleLabel];
    [self addSubview:self.IDTitleLabel];
    [self addSubview:self.phoneNumTitleLabel];
    [self addSubview:self.nameSubTitleLabel];
    [self addSubview:self.IDSubTitleLabel];
    [self addSubview:self.phoneNumSubTitleLabel];
    
    CJPayMasMaker(self.nameTitleLabel, {
        make.top.equalTo(self);
        make.left.equalTo(self).offset(20);
        make.height.mas_equalTo(18);
    });
    
    CJPayMasMaker(self.IDTitleLabel, {
        make.top.equalTo(self.nameTitleLabel.mas_bottom).offset(12);
        make.left.height.equalTo(self.nameTitleLabel);
    });
    
    CJPayMasMaker(self.phoneNumTitleLabel, {
        make.top.equalTo(self.IDTitleLabel.mas_bottom).offset(12);
        make.left.height.equalTo(self.nameTitleLabel);
    });
    
    CJPayMasMaker(self.nameSubTitleLabel, {
        make.top.equalTo(self);
        make.left.equalTo(self.phoneNumTitleLabel.mas_right).offset(8);
        make.height.equalTo(self.nameTitleLabel);
    });
    
    CJPayMasMaker(self.IDSubTitleLabel, {
        make.top.height.equalTo(self.IDTitleLabel);
        make.left.equalTo(self.nameSubTitleLabel);
    });
    
    CJPayMasMaker(self.phoneNumSubTitleLabel, {
        make.top.equalTo(self.IDSubTitleLabel.mas_bottom).offset(12);
        make.left.height.equalTo(self.IDSubTitleLabel);
    });
    
    CJPayMasMaker(self.leftIconOne, {
        make.left.equalTo(self);
        make.centerY.equalTo(self.nameTitleLabel);
        make.height.width.mas_equalTo(12);
    });
    
    CJPayMasMaker(self.leftIconTwo, {
        make.left.height.width.equalTo(self.leftIconOne);
        make.centerY.equalTo(self.IDTitleLabel);
    });
    
    CJPayMasMaker(self.leftIconThree, {
        make.left.height.width.equalTo(self.leftIconOne);
        make.centerY.equalTo(self.phoneNumTitleLabel);
    });
}

#pragma mark -lazeView
- (UIImageView *)leftIconOne {
    if (!_leftIconOne) {
        _leftIconOne = [UIImageView new];
        [_leftIconOne cj_setImage:@"cj_auth_select_icon"];
    }
    return _leftIconOne;
}

- (UIImageView *)leftIconTwo {
    if (!_leftIconTwo) {
        _leftIconTwo = [UIImageView new];
        [_leftIconTwo cj_setImage:@"cj_auth_select_icon"];
    }
    return _leftIconTwo;
}

- (UIImageView *)leftIconThree {
    if (!_leftIconThree) {
        _leftIconThree = [UIImageView new];
        [_leftIconThree cj_setImage:@"cj_auth_select_icon"];
    }
    return _leftIconThree;
}

- (UILabel *)nameTitleLabel {
    if (!_nameTitleLabel) {
        _nameTitleLabel = [UILabel new];
        _nameTitleLabel.font = [UIFont cj_fontOfSize:13];
        _nameTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _nameTitleLabel.text = CJPayLocalizedStr(@"姓名");
    }
    return _nameTitleLabel;
}

- (UILabel *)IDTitleLabel {
    if (!_IDTitleLabel) {
        _IDTitleLabel = [UILabel new];
        _IDTitleLabel.font = [UIFont cj_fontOfSize:13];
        _IDTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _IDTitleLabel.text = CJPayLocalizedStr(@"身份证号");
    }
    return _IDTitleLabel;
}

- (UILabel *)phoneNumTitleLabel {
    if (!_phoneNumTitleLabel) {
        _phoneNumTitleLabel = [UILabel new];
        _phoneNumTitleLabel.font = [UIFont cj_fontOfSize:13];
        _phoneNumTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _phoneNumTitleLabel.text = @"手机号信息";
    }
    return _phoneNumTitleLabel;
}

- (UILabel *)nameSubTitleLabel {
    if (!_nameSubTitleLabel) {
        _nameSubTitleLabel = [UILabel new];
        _nameSubTitleLabel.font = [UIFont cj_fontOfSize:13];
        _nameSubTitleLabel.textColor = [UIColor cj_161823ff];
    }
    return _nameSubTitleLabel;
}

- (UILabel *)IDSubTitleLabel {
    if (!_IDSubTitleLabel) {
        _IDSubTitleLabel = [UILabel new];
        _IDSubTitleLabel.font = [UIFont cj_fontOfSize:13];
        _IDSubTitleLabel.textColor = [UIColor cj_161823ff];
    }
    return _IDSubTitleLabel;
}

- (UILabel *)phoneNumSubTitleLabel {
    if (!_phoneNumSubTitleLabel) {
        _phoneNumSubTitleLabel = [UILabel new];
        _phoneNumSubTitleLabel.font = [UIFont cj_fontOfSize:13];
        _phoneNumSubTitleLabel.textColor = [UIColor cj_161823ff];
    }
    return _phoneNumSubTitleLabel;
}

@end

//
//  BDPXScreenNavigationBar.h
//  TTMicroApp
//
//  Created by qianhongqiang on 2022/8/10.
//

#import "BDPXScreenNavigationBar.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>
#import <Masonry/Masonry.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>

CGFloat const kBDPLeftRightViewMarginSize = 10.f;

@interface BDPXScreenNavigationBar()

@property (nonatomic, strong, readwrite, nullable) BDPUniqueID *uniqueID;

@property (nonatomic, strong, readwrite) UIButton *backButton;
@property (nonatomic, strong, readwrite) UIButton *closeButton;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UIView *contentView;

@property (nonatomic, assign) BOOL barTransparent;
@property (nonatomic, strong) UIColor *barBackgroundColor;

@end

@implementation BDPXScreenNavigationBar

- (instancetype)initWithFrame:(CGRect)frame UniqueID:(BDPUniqueID *)uniqueID {
    self = [super initWithFrame:frame];
    if (self) {
        _uniqueID = uniqueID;
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    
    self.backgroundColor = UDOCColor.bgBody;
//    self.clipsToBounds = YES;
    
    [self addSubview:self.backButton];
    [self addSubview:self.titleLabel];
    [self addSubview:self.closeButton];
    
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.left.equalTo(self).offset(kBDPLeftRightViewMarginSize);
        make.width.height.mas_equalTo(28);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        if(![EEFeatureGating boolValueForKey:EEFeatureGatingKeyXscreenLayoutFixDisable]) {
            make.left.greaterThanOrEqualTo(self.backButton.mas_right).offset(60);
            make.right.lessThanOrEqualTo(self.closeButton.mas_left).offset(-60);
        }
        make.height.mas_equalTo(24);
    }];
    
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.right.equalTo(self).offset(-kBDPLeftRightViewMarginSize);
        make.width.height.mas_equalTo(28);
    }];
}

#pragma mark - NavigationBar Style

- (void)setNavigationBarTransparent:(BOOL)transparent {
    _barTransparent = transparent;
    if (transparent) {
        self.backgroundColor = [UIColor clearColor];
    } else {
        self.backgroundColor = _barBackgroundColor ? : UDOCColor.bgBody;
    }
}

- (void)setNavigationBarBackgroundColor:(UIColor *)backgroundColor {
    _barBackgroundColor = backgroundColor;
    if (!_barTransparent) {
        self.backgroundColor = _barBackgroundColor;
    }
}

#pragma mark - NavigationBar Items

- (void)setNavigationBarTitle:(NSString *)title {
    [self.titleLabel setText:title ? : @""];
}

- (void)setNavigationBarBackButtonHidden:(BOOL)hidden {
    self.backButton.hidden = hidden;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_backButton setImage:[UDOCIconBridge leftOutlined] forState:UIControlStateNormal];
    }
    return _backButton;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_closeButton setImage:[UDOCIconBridge closeOutlined] forState:UIControlStateNormal];
    }
    return _closeButton;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_titleLabel setFont:[UIFont systemFontOfSize:17.f weight:UIFontWeightMedium]];
        _titleLabel.textColor = UDOCColor.textTitle;
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _titleLabel;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.backgroundColor = [UIColor clearColor];
    }
    return _contentView;
}

@end

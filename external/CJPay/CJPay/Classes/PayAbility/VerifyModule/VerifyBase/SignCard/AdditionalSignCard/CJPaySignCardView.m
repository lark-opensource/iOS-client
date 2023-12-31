//
//  CJPaySignCardView.m
//  CJPaySandBox
//
//  Created by 王晓红 on 2023/7/26.
//

#import "CJPaySignCardView.h"

#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPaySignCardInfo.h"

@interface CJPaySignCardView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) CJPayButton *closeButton;
@property (nonatomic, strong, readwrite) CJPayStyleButton *confirmButton;

@end

@implementation CJPaySignCardView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.closeButton];
    [self addSubview:self.titleLabel];
    [self addSubview:self.confirmButton];
    
    CJPayMasMaker(self.closeButton, {
        make.left.top.equalTo(self).inset(12);
        make.width.height.mas_equalTo(20);
    })
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self).offset(40);
        make.left.right.equalTo(self).inset(20);
    })
    
    CJPayMasMaker(self.confirmButton, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(24);
        make.height.mas_equalTo(44);
        make.left.right.equalTo(self.titleLabel);
        make.bottom.equalTo(self).offset(-20);
    })
}

- (void)updateWithSignCardInfo:(CJPaySignCardInfo *)signCardInfo {
    self.titleLabel.text = CJString(signCardInfo.titleMsg);
    [self.confirmButton cj_setBtnTitle:CJString(signCardInfo.buttonText)];
}

- (CJPayButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [CJPayButton new];
        [_closeButton cj_setImageName:@"cj_close_denoise_icon" forState:UIControlStateNormal];
    }
    return _closeButton;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [CJPayStyleButton new];
        [_confirmButton cj_setBtnTitleColor:[UIColor whiteColor]];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
    }
    return _confirmButton;
}

@end

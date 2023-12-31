//
//  CJPayCustomKeyboardTopView.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/29.
//

#import "CJPayCustomKeyboardTopView.h"
#import "CJPayUIMacro.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayButton.h"

@interface CJPayCustomKeyboardTopView()

@property (nonatomic,strong) CJPayButton *leftButton;
@property (nonatomic,strong) CJPayButton *rightButton;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation CJPayCustomKeyboardTopView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.rightButton];
    CJPayMasMaker(self.rightButton, {
        make.right.equalTo(self).offset(-16);
        make.top.equalTo(self).offset(6);
        make.height.mas_equalTo(24);
    });
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self addSubview:self.imageView];
        [self setInsuranceURLString:[CJPayAccountInsuranceTipView keyboardLogo]];
        [self.imageView cj_setImageWithURL:[NSURL URLWithString:[CJPayAccountInsuranceTipView keyboardLogo]] placeholder:nil completion:^(UIImage * _Nonnull image, NSData * _Nonnull data, NSError * _Nonnull error) {
            if (image && !error) {
                self.imageView.hidden = NO;
            }
        }];
        CJPayMasMaker(self.imageView, {
            make.centerX.equalTo(self);
            make.top.equalTo(self).offset(12);
            make.size.mas_equalTo(CGSizeMake(183, 12));
        });
    }
    
}

- (void)setInsuranceURLString:(NSString *)insuranceUrlString {
    if (Check_ValidString(insuranceUrlString)) {
        [self.imageView cj_setImageWithURL:[NSURL URLWithString:insuranceUrlString]
                               placeholder:nil
                                completion:^(UIImage * _Nonnull image, NSData * _Nonnull data, NSError * _Nonnull error) {
            if (image && !error) {
                self.imageView.hidden = NO;
            }
        }];
    }
}

- (void)setCompletionBtnHidden:(BOOL)hidden {
    self.rightButton.hidden = hidden;
}

- (void)leftButtonClick {
    CJ_CALL_BLOCK(self.completionBlock);
}

- (void)rightButtonClick {
    CJ_CALL_BLOCK(self.completionBlock);
}

- (CJPayButton *)leftButton {
    if (!_leftButton) {
        _leftButton = [[CJPayButton alloc] init];
        [_leftButton cj_setImageName:@"cj_pm_down_arrow_icon" forState:UIControlStateNormal];
        _leftButton.cjEventInterval = 1;
        [_leftButton addTarget:self action:@selector(leftButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _leftButton;
}

- (CJPayButton *)rightButton {
    if (!_rightButton) {
        _rightButton = [[CJPayButton alloc] init];
        _rightButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        [_rightButton setTitleColor:[UIColor cj_161823ff] forState:UIControlStateNormal];
        [_rightButton setTitle:CJPayLocalizedStr(@"完成") forState:UIControlStateNormal];
        _rightButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        _rightButton.cjEventInterval = 1;
        [_rightButton addTarget:self action:@selector(rightButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rightButton;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.hidden = YES;
    }
    return _imageView;
}

@end

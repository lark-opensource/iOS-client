//
//  CJPayPasswordNormalView.m
//  arkcrypto-minigame-iOS
//
//  Created by chenbocheng on 2022/4/14.
//

#import "CJPayPasswordNormalView.h"
#import "CJPayPasswordBaseContentView.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPayFixKeyboardView.h"
#import "CJPayUIMacro.h"

@interface CJPayPasswordNormalView ()

@property (nonatomic, strong) CJPayVerifyPasswordViewModel *viewModel;
@property (nonatomic, strong) CJPayPasswordBaseContentView *baseContentView;
//ipad
@property (nonatomic, strong) CJPayFixKeyboardView *ipadKeyboardView;
@property (nonatomic, strong) UILabel *ipadTitleLabel;
@property (nonatomic, assign) BOOL isForceNormal;

@end


@implementation CJPayPasswordNormalView


- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel isForceNormal:(BOOL)isForceNormal {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.isForceNormal = isForceNormal;
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    if (CJ_Pad) {
        [self ipad_setupUI];
        return;
    }
    [self addSubview:self.baseContentView];
    [self addSubview:self.viewModel.errorInfoActionView];
    [self addSubview:self.viewModel.forgetPasswordBtn];
    
    self.viewModel.forgetPasswordBtn.titleLabel.font = [UIFont cj_fontOfSize:12];
    
    CJPayMasMaker(self.baseContentView, {
        make.top.left.right.equalTo(self);
    });
    
    CJPayMasMaker(self.viewModel.errorInfoActionView, {
        make.top.equalTo(self.baseContentView.mas_bottom).offset(8);
        make.left.equalTo(self).offset(20);
        make.height.mas_equalTo(17);
    });
    
    CJPayMasMaker(self.viewModel.forgetPasswordBtn, {
        make.top.equalTo(self.baseContentView.mas_bottom).offset(8);
        make.right.equalTo(self).offset(-20);
        make.height.mas_equalTo(17);
    });
}

- (void)ipad_setupUI {
    [self addSubview:self.ipadTitleLabel];
    [self addSubview:self.viewModel.errorInfoActionView];
    [self addSubview:self.viewModel.inputPasswordView];
    [self addSubview:self.viewModel.forgetPasswordBtn];
    [self addSubview:self.ipadKeyboardView];
    
    CJPayMasMaker(self.ipadTitleLabel, {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self.mas_top).offset(86);
    });
    
    CJPayMasMaker(self.viewModel.errorInfoActionView, {
        make.top.equalTo(self.mas_top).offset(128);
        make.centerX.equalTo(self);
    });

    CJPayMasMaker(self.viewModel.inputPasswordView, {
        make.top.equalTo(self).offset(158.5);
        make.centerX.equalTo(self);
        make.left.equalTo(self).offset(20).priorityMedium();
        make.right.equalTo(self).offset(-20).priorityMedium();
        make.width.mas_lessThanOrEqualTo(328).priorityHigh();
        make.height.mas_equalTo(48);
    });
    
    CJPayMasMaker(self.viewModel.forgetPasswordBtn, {
        make.top.equalTo(self.viewModel.inputPasswordView.mas_bottom).offset(24);
        make.centerX.equalTo(self);
        make.height.mas_equalTo(13);
    });
    
    self.viewModel.inputPasswordView.allowBecomeFirstResponder = NO;
    CJPayMasMaker(self.ipadKeyboardView, {
        make.left.right.equalTo(self);
        make.height.mas_equalTo(220);
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom);
        } else {
            make.bottom.equalTo(self);
        }
    });
    @CJWeakify(self);
    self.ipadKeyboardView.safeKeyboard.numberClickedBlock = ^(NSInteger number) {
        @CJStrongify(self);
        [self.viewModel.inputPasswordView inputNumber:number];
    };
    self.ipadKeyboardView.safeKeyboard.deleteClickedBlock = ^{
        @CJStrongify(self);
        if (self) {
            [self.viewModel.inputPasswordView deleteBackWord];
        }
    };
}

#pragma mark - lazy views

- (CJPayPasswordBaseContentView *)baseContentView {
    if (!_baseContentView) {
        _baseContentView = [[CJPayPasswordBaseContentView alloc] initWithViewModel:self.viewModel isForceNormal:self.isForceNormal];
    }
    return _baseContentView;
}

//ipad

- (CJPayFixKeyboardView *)ipadKeyboardView {
    if (!_ipadKeyboardView) {
        _ipadKeyboardView = [CJPayFixKeyboardView new];
    }
    return _ipadKeyboardView;
}

- (UILabel *)ipadTitleLabel {
    if (!_ipadTitleLabel) {
        _ipadTitleLabel = [UILabel new];
        _ipadTitleLabel.text = CJPayLocalizedStr(@"输入支付密码");
        _ipadTitleLabel.font = [UIFont cj_boldFontOfSize:24];
        _ipadTitleLabel.textColor = [UIColor cj_161823ff];
    }
    return _ipadTitleLabel;
}

@end

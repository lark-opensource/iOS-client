//
//  CJPayHalfVerifyPasswordWithOpenBioGuideViewController.m
//  Pods
//
//  Created by chenbocheng on 2022/4/1.
//

#import "CJPayHalfVerifyPasswordWithOpenBioGuideViewController.h"
#import "CJPayPasswordWithOpenBioGuideView.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPayUIMacro.h"

@interface CJPayHalfVerifyPasswordWithOpenBioGuideViewController ()

@property (nonatomic, strong) CJPayVerifyPasswordViewModel *viewModel;
@property (nonatomic, strong) CJPayPasswordWithOpenBioGuideView *baseContenView;

@end

@implementation CJPayHalfVerifyPasswordWithOpenBioGuideViewController

#pragma mark - life cycle

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel {
    return [self initWithAnimationType:HalfVCEntranceTypeNone viewModel:viewModel];
}

- (instancetype)initWithAnimationType:(HalfVCEntranceType)animationType viewModel:(CJPayVerifyPasswordViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.animationType = animationType;
        self.viewModel = viewModel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
}

#pragma mark - private method

- (void)p_setupUI {
    [self.contentView addSubview:self.baseContenView];
    
    CJPayMasMaker(self.baseContenView, {
        make.edges.equalTo(self.contentView);
    });
    
    [self.navigationBar addSubview:self.viewModel.forgetPasswordBtn];
    CJPayMasMaker(self.viewModel.forgetPasswordBtn, {
        make.right.equalTo(self.navigationBar).offset(-16);
        make.centerY.equalTo(self.navigationBar);
        make.height.mas_equalTo(20);
    });
    
}

- (void)p_onConfirmClick {
    if (self.viewModel.inputPasswordView.contentText.length != 6) {
        return;
    }
    self.viewModel.confirmBtnClickTimes = self.viewModel.confirmBtnClickTimes + 1;
    [self.viewModel trackPageClickWithButtonName:@"1"];
    CJ_CALL_BLOCK(self.viewModel.inputCompleteBlock, self.viewModel.inputPasswordView.contentText);
    [CJKeyboard resignFirstResponder:self.viewModel.inputPasswordView];

    if ([self.viewModel.response.topRightBtnInfo.action isEqualToString:@"forget_pwd_verify"]) {
        self.viewModel.otherVerifyButton.hidden = YES;
    }
    [self.viewModel reset];
}

- (BOOL)p_isShowMarketing {
    return [self.viewModel.response.payInfo.voucherType integerValue] != 0;
}

- (BOOL)p_isShowGuideButton {
    return self.viewModel.response.preBioGuideInfo.isShowButton;
}

- (BOOL)p_isShowCombinePay {
    return self.viewModel.response.payInfo.isCombinePay;
}

#pragma mark - override

- (CGFloat)containerHeight {
    if ([self p_isShowGuideButton]) {
        return CJ_HALF_SCREEN_HEIGHT_HIGH;
    } else {
        return CJ_HALF_SCREEN_HEIGHT_MIDDLE;
    }
}

#pragma mark - lazy views

- (CJPayPasswordWithOpenBioGuideView *)baseContenView {
    if (!_baseContenView) {
        _baseContenView = [[CJPayPasswordWithOpenBioGuideView alloc] initWithViewModel:self.viewModel];
        @CJWeakify(self)
        _baseContenView.onConfirmClickBlock = ^{
            @CJStrongify(self)
            [self p_onConfirmClick];
        };
    }
    return _baseContenView;
}

@end


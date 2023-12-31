//
//  CJPayHalfVerifyPasswordNormalViewController.m
//  Pods
//
//  Created by chenbocheng on 2022/3/30.
//

#import "CJPayHalfVerifyPasswordNormalViewController.h"
#import "CJPayPasswordNormalView.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPayUIMacro.h"
#import "CJPayVerifyItem.h"

@interface CJPayHalfVerifyPasswordNormalViewController ()

@property (nonatomic,strong) CJPayVerifyPasswordViewModel *viewModel;
@property (nonatomic, strong) CJPayPasswordNormalView *baseContenView;

@end

@implementation CJPayHalfVerifyPasswordNormalViewController

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

#pragma mark - public method

- (void)showPasswordVerifyKeyboard {
    [CJKeyboard becomeFirstResponder:self.viewModel.inputPasswordView];
}

#pragma mark - private method

- (void)p_setupUI {
    [self.contentView addSubview:self.baseContenView];

    CJPayMasMaker(self.baseContenView, {
        make.edges.equalTo(self.contentView);
    });
    
    if (CJ_Pad) {
        self.navigationBar.titleLabel.hidden = YES;
    }
}

- (BOOL)p_isShowCombinePay {
    return self.viewModel.response.payInfo.isCombinePay;
}

#pragma mark - override

- (CGFloat)containerHeight {
    if ([self p_isShowCombinePay]) {
        return CJ_HALF_SCREEN_HEIGHT_MIDDLE;
    } else {
        return CJ_HALF_SCREEN_HEIGHT_LOW;
    }
}

#pragma mark - lazy views

- (CJPayPasswordNormalView *)baseContenView {
    if (!_baseContenView) {
        _baseContenView = [[CJPayPasswordNormalView alloc] initWithViewModel:self.viewModel isForceNormal:self.isForceNormal];
    }
    return _baseContenView;
}

@end

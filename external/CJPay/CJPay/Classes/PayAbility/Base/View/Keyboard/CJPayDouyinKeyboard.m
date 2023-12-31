//
//  AWEIMDouyinNumberKeyboard.m
//  Aweme
//
//  Created by wangxinhua on 2022/11/24.
//

#import "CJPayDouyinKeyboard.h"
#import "CJPayUIMacro.h"
#import "UIImage+CJPay.h"
#import "UIColor+CJPay.h"
#import "CJPayLoadingButton.h"
#import "UIView+CJTheme.h"

static const NSInteger kDotButtonTag = 10;

@interface CJPayDouyinKeyboard ()

@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UIButton *delButton;
@property (nonatomic, strong) UIButton *dotButton;
@property (nonatomic, strong) UIStackView *zeroAndDotStackView;
@property (nonatomic, strong) NSMutableArray *buttonArr;

@end


@implementation CJPayDouyinKeyboard

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
        _keyBoardType = CJPayDouyinNumberKeyboardTypeMoney;
    }
    return self;
}

- (void)p_setupUI {
    //    1   2   3  <
    //    4   5   6
    //    7   8   9
    //    0          确定
    
    CGFloat minItemWidth = (CJ_SCREEN_WIDTH - 5 * kKeyBoardButtonMargin) / 4;
    CGFloat safeAreaHeight = [UIDevice btd_isIPhoneXSeries] ? 34 : 0;
    CGFloat minItemHeight = (kKeyboardHeight - safeAreaHeight - 5 * kKeyBoardButtonMargin) / 4;
    //    1 - 9 0 . 布局
    UIStackView *firstLineStackView = [self p_createStackView:UIStackViewDistributionFillEqually];
    [firstLineStackView addArrangedSubview:[self p_buildButtonWithTitle:@"1" andTag:1]];
    [firstLineStackView addArrangedSubview:[self p_buildButtonWithTitle:@"2" andTag:2]];
    [firstLineStackView addArrangedSubview:[self p_buildButtonWithTitle:@"3" andTag:3]];
    self.buttonArr = [NSMutableArray array];
    [self.buttonArr addObjectsFromArray:firstLineStackView.arrangedSubviews];

    UIStackView *secondLineStackView = [self p_createStackView:UIStackViewDistributionFillEqually];
    [secondLineStackView addArrangedSubview:[self p_buildButtonWithTitle:@"4" andTag:4]];
    [secondLineStackView addArrangedSubview:[self p_buildButtonWithTitle:@"5" andTag:5]];
    [secondLineStackView addArrangedSubview:[self p_buildButtonWithTitle:@"6" andTag:6]];
    [self.buttonArr addObjectsFromArray:secondLineStackView.arrangedSubviews];

    UIStackView *thirdLineStackView = [self p_createStackView:UIStackViewDistributionFillEqually];
    [thirdLineStackView addArrangedSubview:[self p_buildButtonWithTitle:@"7" andTag:7]];
    [thirdLineStackView addArrangedSubview:[self p_buildButtonWithTitle:@"8" andTag:8]];
    [thirdLineStackView addArrangedSubview:[self p_buildButtonWithTitle:@"9" andTag:9]];
    [self.buttonArr addObjectsFromArray:thirdLineStackView.arrangedSubviews];

    self.zeroAndDotStackView = [self p_createStackView:UIStackViewDistributionFill];
    UIButton *zeroButton = [self p_buildButtonWithTitle:@"0" andTag:0];
    self.dotButton = [self p_buildButtonWithTitle:@"." andTag:kDotButtonTag];
    [self.zeroAndDotStackView addArrangedSubview:zeroButton];
    [self.zeroAndDotStackView addArrangedSubview:self.dotButton];
    [self.buttonArr addObjectsFromArray:self.zeroAndDotStackView.arrangedSubviews];

    CJPayMasMaker(self.dotButton, {
        make.size.mas_equalTo(CGSizeMake(minItemWidth, minItemHeight));
    });

    UIStackView *leftContainerView = [[UIStackView alloc] init];
    leftContainerView.distribution = UIStackViewDistributionFillEqually;
    leftContainerView.axis = UILayoutConstraintAxisVertical;
    leftContainerView.spacing = 6.f;
    leftContainerView.backgroundColor = [UIColor clearColor];
    [leftContainerView addArrangedSubview:firstLineStackView];
    [leftContainerView addArrangedSubview:secondLineStackView];
    [leftContainerView addArrangedSubview:thirdLineStackView];
    [leftContainerView addArrangedSubview:self.zeroAndDotStackView];

    UIStackView *rightContainerView = [[UIStackView alloc] init];
    rightContainerView.distribution = UIStackViewDistributionFill;
    rightContainerView.axis = UILayoutConstraintAxisVertical;
    rightContainerView.alignment = UIStackViewAlignmentFill;
    rightContainerView.spacing = 6;
    rightContainerView.backgroundColor = [UIColor clearColor];
    [rightContainerView addArrangedSubview:self.delButton];
    [rightContainerView addArrangedSubview:self.confirmButton];
    
    CJPayMasMaker(self.delButton, {
        make.size.mas_equalTo(CGSizeMake(minItemWidth, minItemHeight));
    });
    [self.buttonArr addObject:self.delButton];
    
    UIStackView *containerView = [[UIStackView alloc] initWithArrangedSubviews:@[leftContainerView, rightContainerView]];
    containerView.distribution = UIStackViewDistributionFill;
    containerView.axis = UILayoutConstraintAxisHorizontal;
    containerView.spacing = kKeyBoardButtonMargin;
    
    [self addSubview:containerView];
    self.backgroundColor = [UIColor clearColor];

    CJPayMasMaker(containerView, {
        make.edges.equalTo(self).insets(UIEdgeInsetsMake(kKeyBoardButtonMargin + 2, kKeyBoardButtonMargin, [UIDevice btd_isIPhoneXSeries] ? 34 + kKeyBoardButtonMargin : kKeyBoardButtonMargin, kKeyBoardButtonMargin));
    });
}

- (void)setKeyBoardType:(CJPayDouyinNumberKeyboardType)keyBoardType {
    if (_keyBoardType == keyBoardType) {
        return;
    }
    switch (keyBoardType) {
        case CJPayDouyinNumberKeyboardTypeQuantity:{
            [self.zeroAndDotStackView removeArrangedSubview:self.dotButton];
            [self.dotButton removeFromSuperview];
        }
            break;
        case CJPayDouyinNumberKeyboardTypeMoney:{
            [self.zeroAndDotStackView addArrangedSubview:self.dotButton];
        }
            break;
            
        default:
            break;
    }
    _keyBoardType = keyBoardType;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (UIStackView *)p_createStackView:(UIStackViewDistribution)distribution {
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.distribution = distribution;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.spacing = 6.f;
    return stackView;
}


- (UIButton *)p_buildButtonWithTitle:(NSString *)title andTag:(NSInteger)tag {
    UIButton *button = [[UIButton alloc] init];
    [button setTitle:title forState:UIControlStateNormal];
    button.backgroundColor = [UIColor whiteColor];
    button.titleLabel.font = [UIFont cj_denoiseBoldFontOfSize:22];
    button.layer.cornerRadius = 4;
    button.clipsToBounds = YES;
    [button setTitleColor:[UIColor cj_161823ff] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(p_buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundImage:[UIImage cj_imageWithColor:[UIColor cj_ffffffWithAlpha:1]] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage cj_imageWithColor:[UIColor cj_161823WithAlpha:0.1]] forState:UIControlStateHighlighted];
    [button setBackgroundImage:[UIImage cj_imageWithColor:[UIColor cj_161823WithAlpha:0.1]] forState:UIControlStateSelected];
    
    button.tag = tag;
    return button;
}

- (void)p_buttonClicked:(UIButton *)button {
    [self p_shakeFeedback];
    switch (button.tag) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
        case 9:
        case kDotButtonTag:
            !self.inputStrBlock ?: self.inputStrBlock(button.titleLabel.text);
            break;
        default:
            NSAssert(NO, @"键盘输入不合法");
            break;
    }
}

- (void)p_didDeleteLast {
    [self p_shakeFeedback];
    !self.deleteBlock ?: self.deleteBlock();
}

- (void)p_shakeFeedback {
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle: UIImpactFeedbackStyleMedium];
        [feedbackGenerator prepare];
        [feedbackGenerator impactOccurred];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    if (newWindow == nil) {
        !self.dismissBlock ?: self.dismissBlock();
    }
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[UIButton alloc] init];
    }
    return _confirmButton;
}

- (UIButton *)delButton {
    if (!_delButton) {
        _delButton = [[UIButton alloc] init];
        _delButton.layer.cornerRadius = 4;
        _delButton.clipsToBounds = YES;
        _delButton.backgroundColor = [UIColor whiteColor];
        [_delButton addTarget:self action:@selector(p_didDeleteLast) forControlEvents:UIControlEventTouchUpInside];
        [_delButton setBackgroundImage:[UIImage cj_imageWithColor:[UIColor cj_ffffffWithAlpha:1]] forState:UIControlStateNormal];
        [_delButton setBackgroundImage:[UIImage cj_imageWithColor:[UIColor cj_161823WithAlpha:0.1]] forState:UIControlStateHighlighted | UIControlStateSelected];
    }
    return _delButton;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        
        for (UIButton *button in self.buttonArr) {
            [button setTitleColor:localTheme.amountKeyboardTitleColor forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage cj_imageWithColor:localTheme.amountKeyboardButtonColor]
                              forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage cj_imageWithColor:localTheme.amountKeyboardButtonSelectColor]
                                                         forState:UIControlStateHighlighted];
            [button setBackgroundImage:[UIImage cj_imageWithColor:localTheme.amountKeyboardButtonSelectColor]
                              forState:UIControlStateSelected];
        }
        
        [_delButton setImage:[UIImage cj_imageWithName:localTheme.amountKeyboardDeleteIcon]
                    forState:UIControlStateNormal];
        [_delButton setImage:[UIImage cj_imageWithName:localTheme.amountKeyboardDeleteIcon]
                    forState:UIControlStateHighlighted];
    }
}

@end

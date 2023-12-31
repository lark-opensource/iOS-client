//
//  ACCMusicSimpleAlertView.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/12.
//

#import "ACCMusicSimpleAlertView.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCMusicSimpleAlertView()

@property (nonatomic, copy) dispatch_block_t confirmAction;
@property (nonatomic, copy) dispatch_block_t cancelAction;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) ACCAnimatedButton *confirmButton;
@property (nonatomic, strong) ACCAnimatedButton *cancelButton;

@property (nonatomic, strong) UIView *horizontalLine;
@property (nonatomic, strong) UIView *verticalLine;
@property (nonatomic, assign) BOOL isAnimating;

@end

@implementation ACCMusicSimpleAlertView
#pragma mark - public

+ (void)showAlertOnView:(UIView *)view withTitle:(NSString *)title confirmButtonTitle:(NSString *)confirmTitle cancelButtonTitle:(NSString *)cancelTitle confirmBlock:(dispatch_block_t)actionBlock cancelBlock:(dispatch_block_t)cancelBlock{
    ACCMusicSimpleAlertView *alert = [[ACCMusicSimpleAlertView alloc] initWithFrame:[UIScreen mainScreen].bounds
                                                                          withTitle:title
                                                                 confirmButtonTitle:confirmTitle
                                                                  cancelButtonTitle:cancelTitle
                                                                       confirmBlock:actionBlock
                                                                        cancelBlock:cancelBlock];
    [alert showOnView:view];
}

- (instancetype)initWithFrame:(CGRect)frame
                    withTitle:(NSString *)title
           confirmButtonTitle:(NSString *)confirmTitle
            cancelButtonTitle:(NSString *)cancelTitle
                 confirmBlock:(dispatch_block_t)actionBlock
                  cancelBlock:(dispatch_block_t)cancelBlock{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.text = title;
        [self.confirmButton setTitle:confirmTitle forState:UIControlStateNormal];
        [self.cancelButton setTitle:cancelTitle forState:UIControlStateNormal];
        self.confirmAction = actionBlock;
        self.cancelAction = cancelBlock;
        [self setupUI];
    }
    return self;
}

- (void)showOnView:(UIView *)view
{
    if (!view) return;
    if (self.isAnimating) return;
    if (!self.superview) {
        [view addSubview:self];
    }
    
    self.isAnimating = YES;
    self.containerView.alpha = 0;
    self.containerView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.containerView.alpha = 1;
        self.containerView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.isAnimating = NO;
    }];
}

- (void)p_dismiss
{
    if (!self.superview) return;
    if (self.isAnimating) return;
    self.isAnimating = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self endEditing:YES];
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.containerView.alpha = 0;
            self.containerView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            self.isAnimating = NO;
            [self removeFromSuperview];
        }];
    });
}

#pragma mark

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    //make other vision weaken dim
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [self addSubview:self.containerView];
    
    [self.containerView addSubview:self.titleLabel];
    [self.containerView addSubview:self.confirmButton];
    [self.containerView addSubview:self.cancelButton];
    [self.containerView addSubview:self.horizontalLine];
    [self.containerView addSubview:self.verticalLine];
    
    ACCMasMaker(self.containerView, {
        make.center.equalTo(self);
        make.width.mas_equalTo(280);
        make.height.mas_equalTo(120);
    });
    ACCMasMaker(self.titleLabel, {
        make.centerX.equalTo(self.containerView);
        make.height.mas_equalTo(24);
        make.top.equalTo(self.containerView).offset(24);
    });
    ACCMasMaker(self.horizontalLine, {
        make.width.centerX.equalTo(self.containerView);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(24);
        make.height.mas_equalTo(0.5);
    });
    ACCMasMaker(self.verticalLine, {
        make.centerX.bottom.equalTo(self.containerView);
        make.width.mas_equalTo(0.5);
        make.height.mas_equalTo(47.5);
    });
    ACCMasMaker(self.cancelButton, {
        make.left.bottom.equalTo(self.containerView);
        make.top.equalTo(self.horizontalLine.mas_bottom);
        make.right.equalTo(self.verticalLine.mas_left);
    });
    ACCMasMaker(self.confirmButton, {
        make.right.bottom.equalTo(self.containerView);
        make.top.equalTo(self.horizontalLine.mas_bottom);
        make.left.equalTo(self.verticalLine.mas_right);
    });
}

- (void)didMoveToSuperview
{
    if (self.superview) {
        ACCMasMaker(self, {
            make.edges.equalTo(self.superview);
        });
    }
}

#pragma mark - Actions

- (void)didClickConfirmButton:(id)sender
{
    ACCBLOCK_INVOKE(self.confirmAction);
    [self p_dismiss];
}

- (void)didClickCancelButton:(id)sender
{
    ACCBLOCK_INVOKE(self.cancelAction);
    [self p_dismiss];
}

#pragma mark - getter

- (UIView *)containerView
{
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = ACCResourceColor(ACCColorBGReverse);
        _containerView.layer.cornerRadius = 12;
    }
    return _containerView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [ACCFont() acc_systemFontOfSize:17 weight:ACCFontWeightMedium];
        _titleLabel.textColor = ACCResourceColor(ACCColorTextReverse);
    }
    return _titleLabel;
}

- (ACCAnimatedButton *)confirmButton
{
    if (!_confirmButton) {
        _confirmButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        [_confirmButton addTarget:self action:@selector(didClickConfirmButton:) forControlEvents:UIControlEventTouchUpInside];
        _confirmButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:17 weight:ACCFontWeightMedium];
        [_confirmButton setTitleColor:ACCResourceColor(ACCColorTextReverse) forState:UIControlStateNormal];
    }
    return _confirmButton;
}

- (ACCAnimatedButton *)cancelButton
{
    if (!_cancelButton) {
        _cancelButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        [_cancelButton addTarget:self action:@selector(didClickCancelButton:) forControlEvents:UIControlEventTouchUpInside];
        [_cancelButton setTitleColor:ACCResourceColor(ACCColorTextReverse2) forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:17];
    }
    return _cancelButton;
}

- (UIView *)horizontalLine
{
    if (!_horizontalLine) {
        _horizontalLine = [[UIView alloc] init];
        _horizontalLine.backgroundColor = ACCResourceColor(ACCColorLineReverse2);
    }
    return _horizontalLine;
}

- (UIView *)verticalLine
{
    if (!_verticalLine) {
        _verticalLine = [[UIView alloc] init];
        _verticalLine.backgroundColor = ACCResourceColor(ACCColorLineReverse2);
    }
    return _verticalLine;
}

@end


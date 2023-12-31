//
//  BDUGDialogBaseView.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/14.
//

#import "BDUGDialogBaseView.h"
#import "BDUGShareDialogBundle.h"
#import "BDUGShareAdapterSetting.h"
#import "UIColor+UGExtension.h"
#import <ByteDanceKit/ByteDanceKit.h>

#define kTTconfirmButtonHeight  44
#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height

#define kTTDialogViewBaseAlphaAnimationDuration 0.1f
#define kTTDialogViewBaseScaleAnimationDuration 0.45f

@interface BDUGDialogBaseView ()

@property (nonatomic, assign) NSInteger dialogHeight;
@property (nonatomic, assign) NSInteger dialogWidth;
@property (nonatomic, copy) NSString *confirmTitle;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIButton *closeButton; // 关闭按钮
@property (nonatomic, strong) UIButton *confirmButton; // 购买按钮
@property (nonatomic, strong) UIColor *actionButtonColor;
@property (nonatomic, strong) UIView *contentView; //记录外部传进来的内容视图
///签到成功回调
@property (nonatomic, copy) BDUGDialogViewBaseEventHandler confirmHandler;
///失败回调
@property (nonatomic, copy) BDUGDialogViewBaseEventHandler cancelHandler;

//当前视图正在显示
@property(nonatomic, assign) BOOL isShowing;

/**
 选择某个 action 的回调
 */
@property (nonatomic, copy) BDUGDialogViewBaseActionHandler actionHandler;

/**
 action 的名字数组
 */
@property (nonatomic, copy) NSArray<NSString *> *actions;

/**
 action 对应的具体数据，例如 action 按钮的文字、样式、响应跳转的地址
 */
@property (nonatomic, copy) NSDictionary<NSString *,NSDictionary *> *actionsDetail;

@end

@implementation BDUGDialogBaseView

const NSInteger kBDUGDialogContentOffsetY = 28;

- (instancetype)initDialogViewWithTitle:(NSString *)title
                         confirmHandler:(BDUGDialogViewBaseEventHandler)confirmHandler
                          cancelHandler:(BDUGDialogViewBaseEventHandler)cancelHandler
{
    return [self initDialogViewWithTitle:title buttonColor:nil confirmHandler:confirmHandler cancelHandler:cancelHandler];
}

- (instancetype)initDialogViewWithTitle:(NSString *)title
                            buttonColor:(UIColor *)buttonColor
                         confirmHandler:(BDUGDialogViewBaseEventHandler)confirmHandler
                          cancelHandler:(BDUGDialogViewBaseEventHandler)cancelHandler
{
    if (self = [super initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)]) {
        _confirmTitle = [title copy];
        _confirmHandler = [confirmHandler copy];
        _cancelHandler = [cancelHandler copy];
        _actionButtonColor = buttonColor;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}

- (void)addDialogContentView:(UIView *)view
{
    self.contentView = view;
    _dialogWidth = self.contentView.frame.size.width;
    _dialogHeight = kBDUGDialogContentOffsetY + self.contentView.frame.size.height + kTTconfirmButtonHeight;
    [self.containerView addSubview:self.contentView];
    self.contentView.btd_top = kBDUGDialogContentOffsetY;
    [self setUpView];
}

- (void)addDialogContentView:(UIView *)view atTop:(BOOL)top
{
    if (!top) {
        [self addDialogContentView:view];
    } else {
        self.contentView = view;
        _dialogWidth = self.contentView.frame.size.width;
        _dialogHeight = self.contentView.frame.size.height + kTTconfirmButtonHeight;
        [self.containerView addSubview:self.contentView];
        self.contentView.btd_top = 0;
        [self setUpView];
        if (@available(iOS 8.0, *)) {
            UIImage *closeIcon = [UIImage imageNamed:@"token_dialog_close_white" inBundle:BDUGShareDialogBundle.resourceBundle compatibleWithTraitCollection:nil];
            [self.closeButton setImage:closeIcon forState:UIControlStateNormal];
        } else {
            // Fallback on earlier versions
        }
    }
}

- (void)setContainerViewColor:(UIColor *)color
{
    self.containerView.backgroundColor = color;
}

- (void)orientationChange:(NSNotification *)notification
{
    if (self.isShowing) {
        [self hide];
    }
}

- (void)setUpView
{
    // 添加关闭手势
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeAction:)]];
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.containerView];
    // 关闭
    [self.containerView addSubview:self.closeButton];
    if (self.confirmTitle) {
        // confirmTitle 有值，说明是只有一个按钮（无 actions）样式，故只需要添加确认按钮
        [self.containerView addSubview:self.confirmButton];
    } else {
        // 多个按钮的样式
        // 单个 action 按钮的宽度
        CGFloat actionButtonWidth = _containerView.btd_width / self.actions.count;
        __weak __typeof(self) weakSelf = self;
        [self.actions enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            
            UIButton *actionButton = [strongSelf buildActionButtonWithActionDetial:strongSelf.actionsDetail[obj] index:idx actionButtonWidth:actionButtonWidth];
            [strongSelf.containerView addSubview:actionButton];
        }];
    }
}

- (UIButton *)buildActionButtonWithActionDetial:(NSDictionary *)actionDetail index:(NSInteger)index actionButtonWidth:(CGFloat)actionButtonWidth {
    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    actionButton.frame = CGRectMake(actionButtonWidth * index, _containerView.btd_height - kTTconfirmButtonHeight, actionButtonWidth, kTTconfirmButtonHeight);
    NSNumber *style = (NSNumber *)actionDetail[@"style"];
    BOOL isDefaultMode = (style && [style isKindOfClass:[NSNumber class]]) ? (style.integerValue == 0) : YES;
    actionButton.backgroundColor = [UIColor colorWithHexString:@"ffffff"];
    [actionButton setTitleColor:[UIColor colorWithHexString:@"222222"] forState:UIControlStateNormal];
    if (isDefaultMode) {
        // 默认模式需要在按钮上添加一条线 否则按钮会和背景成为一体
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, actionButtonWidth, 1.f / [UIScreen mainScreen].scale)];
        lineView.backgroundColor = [UIColor colorWithHexString:@"d8d8d8"];
        [actionButton addSubview:lineView];
    }
    actionButton.clipsToBounds = YES;
    [actionButton setTitle:actionDetail[@"text"] forState:UIControlStateNormal];
    actionButton.titleLabel.font = [UIFont systemFontOfSize:16];
    actionButton.tag = index;
    [actionButton addTarget:self action:@selector(actionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [actionButton addTarget:self action:@selector(preventHightEffect:) forControlEvents:UIControlEventAllTouchEvents];
    return actionButton;
}

-(UIView *)containerView
{
    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _dialogWidth, _dialogHeight)];
        _containerView.center = self.center;
        _containerView.layer.cornerRadius = 6.0;
        _containerView.clipsToBounds = YES;
        _containerView.backgroundColor = [UIColor colorWithHexString:@"#ffffff"];
    }
    return _containerView;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        if (@available(iOS 8.0, *)) {
            UIImage *closeIcon = [UIImage imageNamed:@"token_dialog_close" inBundle:BDUGShareDialogBundle.resourceBundle compatibleWithTraitCollection:nil];
            _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(_containerView.btd_width - closeIcon.size.width - 8, 8, closeIcon.size.width, closeIcon.size.height)];
            _closeButton.btd_hitTestEdgeInsets = UIEdgeInsetsMake(0, -8, -8, 0);
            [_closeButton addTarget:self action:@selector(closeAction:) forControlEvents:UIControlEventTouchUpInside];
            [_closeButton setImage:closeIcon forState:UIControlStateNormal];
        } else {
            // Fallback on earlier versions
        }
    }
    return _closeButton;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _confirmButton.frame = CGRectMake(0, _containerView.btd_height - kTTconfirmButtonHeight, _containerView.btd_width, kTTconfirmButtonHeight);
        if (_actionButtonColor) {
            _confirmButton.backgroundColor = _actionButtonColor;
        } else {
            _confirmButton.backgroundColor = [UIColor colorWithHexString:@"f85959"];
        }
        
        _confirmButton.clipsToBounds = YES;
        [_confirmButton setTitleColor:[UIColor colorWithHexString:@"ffffff"] forState:UIControlStateNormal];
//        _confirmButton.highlightedTitleColors = @[[[UIColor colorWithHexString:@"FFFFFF"] colorWithAlphaComponent:0.5],
//                                                  [[UIColor colorWithHexString:@"CACACA"] colorWithAlphaComponent:0.5]];
//        _confirmButton.highlightedBackgroundColors = @[[UIColor colorWithHexString:@"DE4F4F"],
//                                                       [[UIColor colorWithHexString:@"935656"] colorWithAlphaComponent:0.5]];
        [_confirmButton setTitle:_confirmTitle forState:UIControlStateNormal];
        _confirmButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_confirmButton addTarget:self action:@selector(confirmAction:) forControlEvents:UIControlEventTouchUpInside];
        [_confirmButton addTarget:self action:@selector(preventHightEffect:) forControlEvents:UIControlEventAllTouchEvents];
    }
    return _confirmButton;
}

#pragma mark - actions

- (void)closeAction:(id)sender {
    BOOL isClickedByGesture = [sender isKindOfClass:[UIGestureRecognizer class]];
    if (isClickedByGesture) {
        CGPoint touchPoint = [(UIGestureRecognizer *)sender locationInView:self];
        if (CGRectContainsPoint(self.containerView.frame, touchPoint)) {
            return;
        }
    }
    if (self.cancelHandler) {
        self.cancelHandler(self);
    }
}

- (void)confirmAction:(UIButton *)sender {
    if (self.confirmHandler) {
        self.confirmHandler(self);
    }
}

- (void)actionButtonClicked:(UIButton *)sender {
    if (self.actionHandler) {
        self.actionHandler(self, sender.tag);
    }
}

- (void)preventHightEffect:(UIButton *)sender
{
    sender.highlighted = NO;
}


#pragma mark - showing helper

- (UIView *)findSuperViewInVisibleWindow
{
    UIWindow * window = nil;
    if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        window = [[UIApplication sharedApplication].delegate window];
    }
    if (![window isKindOfClass:[UIView class]]) {
        window = [UIApplication sharedApplication].keyWindow;
    }
    if (!window) {
        window = [[UIApplication sharedApplication].windows firstObject];
    }
    return window;
}

#pragma mark - show/hide

- (void)show {
    BDUGShareDialogBlock showBlock = ^() {
        [self showView];
    };
    BDUGShareDialogBlock hideBlock = ^() {
        [self hide];
    };
    if ([BDUGShareAdapterSetting sharedService].shareDialogDelegate && [[BDUGShareAdapterSetting sharedService].shareDialogDelegate respondsToSelector:@selector(shareAbilityNeedShowDialog:hideAction:)]) {
        [[BDUGShareAdapterSetting sharedService].shareDialogDelegate shareAbilityNeedShowDialog:showBlock hideAction:hideBlock];
    } else {
        showBlock();
    }
}

- (void)showView
{
    if (self.superview) return;
    UIView * superView = [self findSuperViewInVisibleWindow];
    for (UIView *subView in superView.subviews) {
        if ([subView isKindOfClass:self.class] &&
            [(BDUGDialogBaseView *)subView isShowing]) {
            //如果上面已经有一个口令识别弹窗，且isShowing，不重复弹出。
            return;
        }
    }
    [superView addSubview:self];
    [self setIsShowing:YES];
    
    self.userInteractionEnabled = NO;
    self.containerView.transform = CGAffineTransformMakeScale(.00001f, .00001f);
    self.alpha = 0.f;
    
    [UIView animateWithDuration:kTTDialogViewBaseAlphaAnimationDuration animations:^{
        self.alpha = 1.f;
    }];
    
    if (@available(iOS 7.0, *)) {
        [UIView animateWithDuration:kTTDialogViewBaseScaleAnimationDuration
                              delay:0.f
             usingSpringWithDamping:0.78
              initialSpringVelocity:0.8
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.containerView.transform = CGAffineTransformIdentity;
                             self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
                         } completion:^(BOOL finished) {
                             self.userInteractionEnabled = YES;
                         }];
    } else {
        // Fallback on earlier versions
    }
}

- (void)hide
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setIsShowing:NO];
    self.userInteractionEnabled = NO;
    self.alpha = 1.f;
    
    [UIView animateWithDuration:kTTDialogViewBaseAlphaAnimationDuration animations:^{
        self.alpha = 0.f;
    } completion:nil];
    
    if (@available(iOS 7.0, *)) {
        [UIView animateWithDuration:kTTDialogViewBaseScaleAnimationDuration
                              delay:0.0f
             usingSpringWithDamping:0.78
              initialSpringVelocity:0.8
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.containerView.transform = CGAffineTransformMakeScale(.00001f, .00001f);
                         } completion:^(BOOL finished) {
                             [self removeFromSuperview];
                             if ([BDUGShareAdapterSetting sharedService].shareDialogDelegate && [[BDUGShareAdapterSetting sharedService].shareDialogDelegate respondsToSelector:@selector(shareAbilityDidHideDialog)]) {
                                 [[BDUGShareAdapterSetting sharedService].shareDialogDelegate shareAbilityDidHideDialog];
                             }
                         }];
    } else {
        // Fallback on earlier versions
    }
}

@end

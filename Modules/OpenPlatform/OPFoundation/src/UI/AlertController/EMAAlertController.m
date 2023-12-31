//
//  EMAAlertController.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/22.
//

#import "EMAAlertController.h"
#import "UIColor+EMA.h"
#import "BDPUtils.h"
#import "UIImage+EMA.h"
#import "UIFont+EMA.h"
#import "UIView+BDPExtension.h"
#import "BDPResponderHelper.h"
#import "BDPDeviceHelper.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <objc/runtime.h>
#import "UIImage+BDPExtension.h"
#import <OPFoundation/OPFoundation-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

@interface UIView (EMAAlertControllerHelper)

@property (nonatomic, assign) UIEdgeInsets viewEdgeInsets;

@property (nonatomic, strong, getter=superview) UIView *bindSuperview;

@end

@implementation UIView (EMAAlertControllerHelper)

- (void)setViewEdgeInsets:(UIEdgeInsets)viewEdgeInsets {
    objc_setAssociatedObject(self, @selector(viewEdgeInsets), [NSValue valueWithUIEdgeInsets:viewEdgeInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)viewEdgeInsets {
    NSValue *value = objc_getAssociatedObject(self, @selector(viewEdgeInsets));
    return value ? value.UIEdgeInsetsValue : UIEdgeInsetsZero;
}

- (void)setBindSuperview:(UIView *)bindSuperview {
    if ([bindSuperview isKindOfClass:UIView.class] && self.superview != bindSuperview) {
        [self removeFromSuperview];
        [bindSuperview addSubview:self];
    }
}

@end

@interface CALayer (EMAAlertControllerHelper)

@property (nonatomic, strong, getter=superlayer) CALayer *bindSuperlayer;

@end

@implementation CALayer (EMAAlertControllerHelper)

- (void)setBindSuperlayer:(CALayer *)bindSuperlayer {
    if ([bindSuperlayer isKindOfClass:CALayer.class] && self.superlayer != bindSuperlayer) {
        [self removeFromSuperlayer];
        [bindSuperlayer addSublayer:self];
    }
}

@end

@implementation EMAAlertControllerConfig

- (instancetype)init {
    if (self = [super init]) {
        // 默认配置
        _lineColor = UDOCColor.lineDividerDefault;
        _lineWidth = BDPDeviceHelper.ssOnePixel;

        _alertWidth = MIN(OPWindowHelper.fincMainSceneWindow.bdp_width - 36.0 * 2, 303);
        _actionSheetWidth = MIN(OPWindowHelper.fincMainSceneWindow.bdp_width - 36.0 * 2, 303);
        _actionSheetBottomMargin = 8;
        _actionSheetCancelButtonTopMargin = 8;

        _headerEdgeInsets = UIEdgeInsetsMake(24, 20, 24, 20);
        _titleEdgeInsets = UIEdgeInsetsZero;
        _titleAligment = NSTextAlignmentCenter;
        _messageEdgeInsets = UIEdgeInsetsZero;
        _textviewEdgeInsets = UIEdgeInsetsZero;
        _headerItemSpaceMargin = 10;

        _alertButtonHeight = 50;
        _actionSheetButtonHeight = 50;
        _textviewHeight = 30;

        _textviewPlaceholderColor = UDOCColor.textPlaceholder;
        _textviewMaxLength = NSIntegerMax;
        _textviewFont = UIFont.ema_text14;
        _textviewTextColor = UDOCColor.textTitle;
    }
    return self;
}

@end

@protocol EMAAlertActionDelegate <NSObject>
@required
- (void)onActionButtonClicked:(EMAAlertAction *)action;
- (void)onActionButtonTouch:(UITouch *)touch event:(UIEvent *)event isTouchUp:(BOOL)isTouchUp;

@end

@interface EMAAlertTitleButton : UIButton<UIPointerInteractionDelegate>
- (void)enablePointerInteraction;
@end

@implementation EMAAlertTitleButton

- (void)enablePointerInteraction {
    if( @available(iOS 13.4, *)) {
        [self addInteraction:[[UIPointerInteraction alloc] initWithDelegate:self]];
        self.pointerInteractionEnabled = YES;
    }
}

- (nullable UIPointerRegion *)pointerInteraction:(UIPointerInteraction *)interaction regionForRequest:(UIPointerRegionRequest *)request defaultRegion:(UIPointerRegion *)defaultRegion  API_AVAILABLE(ios(13.4)){
    return [UIPointerRegion regionWithRect: self.bounds identifier: nil];
}

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region  API_AVAILABLE(ios(13.4)){
    return [UIPointerStyle styleWithEffect:[UIPointerHoverEffect effectWithPreview:[[UITargetedPreview alloc] initWithView:self]] shape:nil];
}
@end

@interface EMAAlertAction ()

@property (nonatomic, weak) id<EMAAlertActionDelegate> delegate;
@property (nonatomic, copy) EMAAlertActionBlock actionHandler;

@property (nonatomic, strong, readwrite) UIButton *titleButton;
@property (nonatomic, assign, readwrite) BOOL highlighted;

@end

@implementation EMAAlertAction

+ (instancetype)actionWithTitle:(NSString *)title style:(UIAlertActionStyle)style handler:(void (^)(EMAAlertAction *))handler {

    EMAAlertAction *action = [super actionWithTitle:title style:style handler:nil];
    EMAAlertTitleButton *alertButton = [EMAAlertTitleButton buttonWithType:UIButtonTypeCustom];
    [alertButton enablePointerInteraction];
    action.titleButton = alertButton;
    action.titleButton.backgroundColor = [UIColor clearColor];
    action.titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [action.titleButton setBackgroundImage:[UIImage bdp_imageWithUIColor:UDOCColor.fillPressed] forState:UIControlStateHighlighted];
    [action.titleButton setTitle:title forState:UIControlStateNormal];
    [action.titleButton addTarget:action action:@selector(touchUp:event:) forControlEvents:UIControlEventTouchUpInside];
    [action.titleButton addTarget:action action:@selector(touchUp:event:) forControlEvents:UIControlEventTouchUpOutside];
    [action.titleButton addTarget:action action:@selector(touch:event:) forControlEvents:UIControlEventTouchDragInside];
    [action.titleButton addTarget:action action:@selector(touch:event:) forControlEvents:UIControlEventTouchDragOutside];
    [action.titleButton addTarget:action action:@selector(touch:event:) forControlEvents:UIControlEventTouchDown];

    action.titleButtonEdgeInsets = UIEdgeInsetsZero;

    action.lineView = [UIView new];

    action.actionHandler = handler;

    if (style == UIAlertActionStyleCancel) {
        [action.titleButton setTitleColor:UDOCColor.textTitle forState:UIControlStateNormal];
        action.highlighted = YES;
    }else if (style == UIAlertActionStyleDestructive) {
        [action.titleButton setTitleColor:UDOCColor.functionDanger500 forState:UIControlStateNormal];
        action.highlighted = NO;
    }else {
        [action.titleButton setTitleColor:UDOCColor.primaryPri500 forState:UIControlStateNormal];
        action.highlighted = NO;
    }
    if (@available(iOS 13.4, *)) {
        action.titleButton.pointerInteractionEnabled = YES;
    }
    return action;
}

- (void)setHighlighted:(BOOL)highlighted {
    if (_highlighted != highlighted) {
        _highlighted = highlighted;
    }
//    if (_highlighted) {
//        self.titleButton.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
//    }else {
//        self.titleButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
//    }
}

- (void)performAction {
    [self.delegate onActionButtonClicked:self];
    if (self.actionHandler) {
        self.actionHandler(self);
    }
}

- (void)touchUp:(UIButton *)sender event:(UIEvent *)event {
    if ([self.delegate respondsToSelector:@selector(onActionButtonTouch:event:isTouchUp:)]) {
        [self.delegate onActionButtonTouch:[[event touchesForView:sender] anyObject] event:event isTouchUp:YES];
    }
}

- (void)touch:(UIButton *)sender event:(UIEvent *)event {
    if ([self.delegate respondsToSelector:@selector(onActionButtonTouch:event:isTouchUp:)]) {
        [self.delegate onActionButtonTouch:[[event touchesForView:sender] anyObject] event:event isTouchUp:NO];
    }
}

@end

@interface EMAAlertController () <EMAAlertActionDelegate, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UITextFieldDelegate>

@property (nullable, nonatomic, copy) NSString *message;
@property (nullable, nonatomic, copy) NSString *textviewPlaceholder;

@property (nonatomic, strong, readwrite) UIView *containerView;
@property (nonatomic, strong, readwrite) UIView *containerBackgroundView;
@property (nonatomic, strong, readwrite) UIView *alertView;

@property (nonatomic, strong, readwrite) UIView *actionSheetTopView;
@property (nonatomic, strong, readwrite) UIView *actionSheetCancelView;

@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *messageLabel;
@property (nonatomic, strong, readwrite) EMAAlertTextView *textview;

@property (nonatomic, strong, readwrite) EMAAlertAction *currentHighlightedAction;

@property (nonatomic, strong, readwrite) EMAAlertControllerConfig *config;

@property (nonatomic, strong, readwrite) EMAAlertAction *customBgTapAction;


@property (nonatomic, strong, readwrite) UIView *headerView;
@property (nonatomic, strong, readwrite) UIScrollView *contentContainerView;
@property (nonatomic, strong, readwrite) UIScrollView *actionContainerView;
@property (nonatomic, strong, readwrite) UIViewController *showFromViewController;
@property (nonatomic, strong, readwrite) UIControl *tapControl;

@property (nonatomic, strong, readwrite) NSMutableArray *textFieldArr;
@property (nonatomic, strong, readwrite) NSMutableArray *contentViewArr;

@property (nonatomic, strong, readwrite) NSMutableArray<EMAAlertAction *> *originActionArr;
@property (nonatomic, strong, readwrite) NSMutableArray<EMAAlertAction *> *actionArr;
@property (nonatomic, strong, readwrite) EMAAlertAction *cancelAction;

@property (nonatomic, strong, readwrite) id currentSelectedFlag;
@property (nonatomic, assign, readwrite) BOOL hasBuildViewHierarchy;

@property (nonatomic, assign, readwrite) CGRect keyboardScreenFrame;
@property (nonatomic, assign, readwrite) BOOL appearing;
@property (nonatomic, assign, readwrite) BOOL appeared;

@property (nullable, nonatomic, readwrite) NSMutableArray<UIView *> *widgetViewArray;

@property (nonatomic, assign) CGFloat minActionContainerHeight;
@property (nonatomic, assign) UIEdgeInsets layoutInsets;

@end

@implementation EMAAlertController

+ (instancetype)alertControllerWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle {
    return [self alertControllerWithTitle:title message:message preferredStyle:preferredStyle config:nil];
}

+ (instancetype)alertControllerWithTitle:(nullable NSString *)title
                     textviewPlaceholder:(nullable NSString *)textviewPlaceholder
                          preferredStyle:(UIAlertControllerStyle)preferredStyle
                                  config:(EMAAlertControllerConfig *)config
{
    return [[self alloc] initWithTitle:title message:nil textviewPlaceholder:textviewPlaceholder preferredType:preferredStyle config:config];
}

+ (instancetype)alertControllerWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle config:(EMAAlertControllerConfig *)config {
    return [[self alloc] initWithTitle:title message:message textviewPlaceholder:nil preferredType:preferredStyle config:config];
}

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
          textviewPlaceholder:(NSString *)textviewPlaceholder
                preferredType:(UIAlertControllerStyle)preferredStyle
                       config:(EMAAlertControllerConfig *)config
{
    self = [super init];
    if (self) {

        self.transitioningDelegate = self;
        self.keyboardScreenFrame = CGRectZero;

        if (config) {
            _config = config;
        }else {
            _config = EMAAlertControllerConfig.new;
        }
        _preferredStyle = preferredStyle;
        self.title = title;
        _message = message;
        _textviewPlaceholder = textviewPlaceholder.copy;

        self.modalPresentationStyle = UIModalPresentationCustom;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [self setupViews];
        [self setupAnimations];
    }
    return self;
}

- (void)setupViews {
    self.containerView = [[UIControl alloc] init];
    [(UIControl *)self.containerView addTarget:self action:@selector(onBackgroundTap) forControlEvents:UIControlEventTouchUpInside];

    self.containerBackgroundView = UIView.new;
    self.containerBackgroundView.backgroundColor = UDOCColor.bgMask;

    self.headerView = [[UIView alloc] init];
    self.contentContainerView = [[UIScrollView alloc] init];
    self.actionContainerView = [[UIScrollView alloc] init];

    if (self.preferredStyle == UIAlertControllerStyleAlert) {
        self.alertView = self.headerView;
        self.alertView.backgroundColor = UDOCColor.bgFloat;
        self.alertView.layer.cornerRadius = 8;
        self.alertView.layer.masksToBounds = YES;

    }else if (self.preferredStyle == UIAlertControllerStyleActionSheet) {
        self.alertView = [[UIView alloc] init];

        self.actionSheetTopView = self.headerView;
        self.actionSheetTopView.backgroundColor = UDOCColor.bgBody;
        self.actionSheetTopView.layer.cornerRadius = 8;
        self.actionSheetTopView.layer.masksToBounds = YES;

        self.actionSheetCancelView = [[UIView alloc] init];
        self.actionSheetCancelView.backgroundColor = UDOCColor.bgBody;
        self.actionSheetCancelView.layer.cornerRadius = 8;
        self.actionSheetCancelView.layer.masksToBounds = YES;
    }

    if (!BDPIsEmptyString(self.title)) {
        [self addLabelWithConfigurationHandler:^(UILabel *label) {
            label.textColor = UDOCColor.textTitle;
            label.numberOfLines = 3;
            label.font = UIFont.ema_title17;
            label.lineBreakMode = NSLineBreakByTruncatingTail;
            label.textAlignment = self.config.titleAligment;
            label.text = self.title;
            label.viewEdgeInsets = self.config.titleEdgeInsets;

            self.titleLabel = label;
        }];
    }

    if (!BDPIsEmptyString(self.message)) {
        [self addLabelWithConfigurationHandler:^(UILabel *label) {
            label.textColor = UDOCColor.textTitle;
            label.numberOfLines = 0;
            label.font = [UIFont ema_textWithSize:16];
            label.lineBreakMode = NSLineBreakByTruncatingTail;
            label.textAlignment = NSTextAlignmentCenter;
            label.text = self.message;
            label.viewEdgeInsets = self.config.messageEdgeInsets;

            self.messageLabel = label;
        }];
    }

    if (!BDPIsEmptyString(self.textviewPlaceholder)) {
        [self addTextViewWithConfigurationHandler:^(EMAAlertTextView *textView) {
            textView.placeholder = self.textviewPlaceholder;
            textView.placeholderColor = self.config.textviewPlaceholderColor;
            textView.maxLength = self.config.textviewMaxLength;
            textView.font = self.config.textviewFont;
            textView.textColor = self.config.textviewTextColor;
            self.textview = textView;
        } height:self.config.textviewHeight viewEdgeInsets:self.config.textviewEdgeInsets];
    }
}

- (void)setupAnimations {
    self.doPresentAnimation = ^(EMAAlertController *alert, void (^completion)(BOOL finished)) {
        alert.containerBackgroundView.alpha = 0;
        alert.containerView.alpha = 0;
        if (alert.preferredStyle == UIAlertControllerStyleActionSheet) {
            alert.containerView.transform = CGAffineTransformMakeTranslation(0, alert.alertView.bdp_height);
        }else {
            alert.containerView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
        }
        [UIView animateWithDuration:0.2 animations:^{
            alert.containerBackgroundView.alpha = 1;
            alert.containerView.alpha = 1;
            alert.containerView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            if (completion) {
                completion(finished);
            }
        }];
    };

    self.doDismissAnimation = ^(EMAAlertController *alert, void (^completion)(BOOL finished)) {
        [UIView animateWithDuration:0.2 animations:^{
            alert.containerBackgroundView.alpha = 0;
            alert.containerView.alpha = 0;
            if (alert.preferredStyle == UIAlertControllerStyleActionSheet) {
                alert.containerView.transform = CGAffineTransformMakeTranslation(0, alert.alertView.bdp_height);
            }
        } completion:^(BOOL finished) {
            alert.containerBackgroundView.alpha = 1;
            alert.containerView.alpha = 1;
            alert.containerView.transform = CGAffineTransformIdentity;
            if (completion) {
                completion(finished);
            }
        }];
    };
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.config.alertWidth = MIN(OPWindowHelper.fincMainSceneWindow.bdp_width - 36 * 2, 303);
    self.config.actionSheetWidth = MIN(OPWindowHelper.fincMainSceneWindow.bdp_width - 36 * 2, 303);
    
    self.view.bdp_size = CGSizeZero;
    self.view.backgroundColor = [UIColor clearColor];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(willKeyboardHide:) name:UIKeyboardWillHideNotification object:nil];
    [center addObserver:self selector:@selector(willKeyboardChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (BOOL)shouldAutorotate {
    return NO;     // 禁止屏幕旋转
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // willAppear到didAppear有一段用于动画的时间，showInWindow使用该段时间来执行动画
    // showInWindow在didAppear中调用会导致showAlertView的这个过程的动画延迟或者丢失，所以要放在willAppear中调用
    [self showInWindow:self.appeared?NO:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self removeFromWindow:animated];
}

// 适配iPad分屏/转屏，在viewWillTransitionToSize中刷新布局
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self updateView];
    } completion:nil];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.config.supportedInterfaceOrientations != UIInterfaceOrientationMaskPortrait) {
        return self.config.supportedInterfaceOrientations;
    }
    return [super supportedInterfaceOrientations];
}

#pragma mark - Events
- (void)onBackgroundTap
{
    if (self.customBgTapAction) {
        [self.customBgTapAction performAction];
    }else {
        if (self.preferredStyle == UIAlertControllerStyleActionSheet) {
            [self.cancelAction performAction];
        }
    }

    [self.containerView.window endEditing:YES];
}

#pragma mark - Show & Update & Dismiss & Remove
- (void)showInWindow:(BOOL)animated {
    self.appearing = YES;
    [self buildViewHierarchy];
    [self updateView];

    if (self.preferredStyle == UIAlertControllerStyleAlert) {
        // 默认滚动到currentHighlightedAction位置
        CGFloat contentOffsetY = self.currentHighlightedAction.titleButton.bdp_centerY - self.actionContainerView.bdp_height/2;
        if (contentOffsetY < 0) {
            contentOffsetY = 0;
        }else if (contentOffsetY > self.actionContainerView.contentSize.height - self.actionContainerView.bdp_height) {
            contentOffsetY = self.actionContainerView.contentSize.height - self.actionContainerView.bdp_height;
        }
        self.actionContainerView.contentOffset = CGPointMake(0, contentOffsetY);
    }

    if (animated && self.doPresentAnimation) {
        self.doPresentAnimation(self, ^(BOOL finished) {

        });
    }

    self.containerView.accessibilityViewIsModal = YES;

    if (self.textFields.count > 0) {
        // 自动弹出键盘
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.textFields.firstObject becomeFirstResponder];
        });
    }else  {
        if(self.canBecomeFirstResponder) [self becomeFirstResponder];
    }
    self.appeared = YES;
}

- (void)removeFromWindow:(BOOL)animated {
    [self.containerView.window endEditing:YES];     // Deal with the warning: rejected resignFirstResponder when being removed from hierarchy
    self.appearing = NO;
    if (animated && self.doDismissAnimation) {
        self.doDismissAnimation(self, ^(BOOL finished) {
            [self.containerView removeFromSuperview];
            [self.containerBackgroundView removeFromSuperview];
        });
    }else {
        [self.containerView removeFromSuperview];
        [self.containerBackgroundView removeFromSuperview];
    }

}

- (void)dismissViewController {
    self.customBlockAfterViewUpdated = nil;
    self.customActionBlockWhenUpdateView = nil;
    self.customContentViewBlockWhenUpdateView = nil;

    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }else {
        if (self.navigationController) {
            NSMutableArray *childViewControllers = self.navigationController.childViewControllers.mutableCopy;
            [childViewControllers removeObject:self];
            [self.navigationController setViewControllers:childViewControllers animated:YES];
        }else {
            [self willMoveToParentViewController:nil];
            [self.view removeFromSuperview];
            [self removeFromParentViewController];
        }
    }
}

- (void)buildViewHierarchy {
    // headerView
    self.contentContainerView.bindSuperview = self.headerView;
    self.actionContainerView.bindSuperview = self.headerView;
    self.actionArr.firstObject.lineView.bindSuperview = self.headerView;

    // contentContainerView
    for (UIView *view in self.contentViewArr) {
        view.bindSuperview = self.contentContainerView;
    }

    // actionContainerView
    for (NSUInteger i = 0; i < self.actionArr.count; i++) {
        EMAAlertAction *action = self.actionArr[i];
        action.titleButton.bindSuperview = self.actionContainerView;
        if (i > 0) {
            action.lineView.bindSuperview = self.actionContainerView;
        }
    }

    // AlertView
    if (self.preferredStyle == UIAlertControllerStyleActionSheet) {
        if (self.cancelAction) {
            self.cancelAction.titleButton.bindSuperview = self.actionSheetCancelView;
            self.actionSheetCancelView.bindSuperview = self.alertView;
        }
        self.actionSheetTopView.bindSuperview = self.alertView;
    }

    // 由于第一次的buildViewHierarchy调用是在viewWillAppear中进行的
    // 此时self.view还未真正地被添加到视图层级中
    // self.view.window为nil，所以不能通过其来查找targetWindow
    // 通过self.presentingViewController.view.window来查找
    UIWindow *targetWindow = self.presentingViewController.view.window ?: OPWindowHelper.fincMainSceneWindow;

    self.containerBackgroundView.bindSuperview = targetWindow;

    self.alertView.bindSuperview = self.containerView;
    for (UIView * view in self.widgetViewArray) {
        view.bindSuperview = self.containerView;
    }
    self.containerView.bindSuperview = targetWindow;
    [targetWindow bringSubviewToFront:self.containerView];

    self.hasBuildViewHierarchy = YES;
}

- (void)updateContentViewWithWidth:(CGFloat)width {
    CGFloat contentContainerViewHeight = self.config.headerEdgeInsets.top;
    for (NSUInteger i = 0; i < self.contentViewArr.count; i++) {
        UIView *contentView = self.contentViewArr[i];
        if (i > 0) {
            contentContainerViewHeight += self.config.headerItemSpaceMargin;
        }

        contentView.frame = CGRectMake(self.config.headerEdgeInsets.left + contentView.viewEdgeInsets.left,
                                       contentContainerViewHeight + contentView.viewEdgeInsets.top,
                                       width - self.config.headerEdgeInsets.left - self.config.headerEdgeInsets.right - contentView.viewEdgeInsets.left - contentView.viewEdgeInsets.right,
                                       contentView.bdp_height);

        // 文本控件根据内容自动调整高度
        if ([contentView isKindOfClass:UILabel.class]) {
            CGSize fitSize = [contentView sizeThatFits:CGSizeMake(contentView.bdp_width, CGFLOAT_MAX)];
            contentView.bdp_height = fitSize.height;
        }

        if (self.customContentViewBlockWhenUpdateView) {
            self.customContentViewBlockWhenUpdateView(self, i, contentView);  // 定制逻辑
        }

        contentContainerViewHeight = contentView.bdp_bottom + contentView.viewEdgeInsets.bottom;
    }

    if (self.contentViewArr.count > 0) {
        contentContainerViewHeight += self.config.headerEdgeInsets.bottom;
    }else {
        contentContainerViewHeight = 0;
    }

    self.contentContainerView.contentSize = CGSizeMake(width, contentContainerViewHeight);
    self.contentContainerView.bdp_height = contentContainerViewHeight;
}

- (void)updateActionListViewVerticallyWithWidth:(CGFloat)width {
    CGFloat actionListViewHeight = 0;
    CGFloat buttonHeight = self.preferredStyle == UIAlertControllerStyleAlert ? self.config.alertButtonHeight : self.config.actionSheetButtonHeight;
    for (NSUInteger i = 0; i < self.actionArr.count; i++) {
        EMAAlertAction *action = self.actionArr[i];

        if(i > 0 && action.lineView && self.config.lineWidth > 0){
            action.lineView.frame = CGRectMake(0, actionListViewHeight + self.config.actionButtonSpaceMargin, width, self.config.lineWidth);
            actionListViewHeight = action.lineView.bdp_bottom;
        }
        action.titleButton.frame = CGRectMake(self.config.actionButtonSpaceMargin + action.titleButtonEdgeInsets.left,
                                              actionListViewHeight + self.config.actionButtonSpaceMargin  + action.titleButtonEdgeInsets.top,
                                              width - self.config.actionButtonSpaceMargin*2 - action.titleButtonEdgeInsets.left - action.titleButtonEdgeInsets.right,
                                              buttonHeight);

        action.lineView.backgroundColor = self.config.lineColor;

        if (self.customActionBlockWhenUpdateView) {
            self.customActionBlockWhenUpdateView(self, action);  // 定制逻辑
        }

        actionListViewHeight = action.titleButton.bdp_bottom + action.titleButtonEdgeInsets.bottom;
        if (i == self.actionArr.count - 1) {
            actionListViewHeight += self.config.actionButtonSpaceMargin;
        }

        if (i == 1) {
            self.minActionContainerHeight = action.titleButton.bdp_centerY;
        }
    }
    self.actionContainerView.contentSize = CGSizeMake(width, actionListViewHeight);
    self.actionContainerView.bdp_height = actionListViewHeight;
}

- (void)updateActionListViewHorizontallyWithWidth:(CGFloat)width {
    CGFloat actionListViewHeight = 0;
    CGFloat buttonHeight = self.preferredStyle == UIAlertControllerStyleAlert ? self.config.alertButtonHeight : self.config.actionSheetButtonHeight;

    EMAAlertAction *leftAction = self.actionArr[0];
    EMAAlertAction *rightAction = self.actionArr[1];

    // 横向布局

    leftAction.titleButton.frame = CGRectMake(self.config.actionButtonSpaceMargin + leftAction.titleButtonEdgeInsets.left,
                                              actionListViewHeight + self.config.actionButtonSpaceMargin + leftAction.titleButtonEdgeInsets.top,
                                              (width - self.config.actionButtonSpaceMargin * 3)/2 - leftAction.titleButtonEdgeInsets.left - leftAction.titleButtonEdgeInsets.right,
                                              buttonHeight);
    leftAction.lineView.backgroundColor = self.config.lineColor;

    if (self.customActionBlockWhenUpdateView) {
        self.customActionBlockWhenUpdateView(self, leftAction);  // 定制逻辑
    }



    CGFloat right = leftAction.titleButton.bdp_right + leftAction.titleButtonEdgeInsets.right + self.config.actionButtonSpaceMargin;
    rightAction.lineView.backgroundColor = self.config.lineColor;
    rightAction.lineView.frame = CGRectMake(right , actionListViewHeight, self.config.lineWidth, 0);
    if (rightAction.lineView > 0) {
        right = rightAction.lineView.bdp_right + self.config.actionButtonSpaceMargin;
    }
    rightAction.titleButton.frame = CGRectMake(right + rightAction.titleButtonEdgeInsets.left,
                                               actionListViewHeight + self.config.actionButtonSpaceMargin + rightAction.titleButtonEdgeInsets.top,
                                               width - right - rightAction.titleButtonEdgeInsets.left - rightAction.titleButtonEdgeInsets.right - self.config.actionButtonSpaceMargin,
                                               buttonHeight);

    if (self.customActionBlockWhenUpdateView) {
        self.customActionBlockWhenUpdateView(self, rightAction); // 定制逻辑
    }

    actionListViewHeight = MAX(leftAction.titleButton.bdp_bottom + leftAction.titleButtonEdgeInsets.bottom, rightAction.titleButton.bdp_bottom + rightAction.titleButtonEdgeInsets.bottom)+ self.config.actionButtonSpaceMargin;
    rightAction.lineView.bdp_height = actionListViewHeight;

    self.minActionContainerHeight = actionListViewHeight;

    self.actionContainerView.contentSize = CGSizeMake(width, actionListViewHeight);
    self.actionContainerView.bdp_height = actionListViewHeight;
}

- (void)updateActionListViewWithWidth:(CGFloat)width {
    if (self.preferredStyle == UIAlertControllerStyleAlert && self.actionArr.count == 2) {
        [self updateActionListViewHorizontallyWithWidth:width];
    }else {
        [self updateActionListViewVerticallyWithWidth:width];
    }
}

- (void)adaptViewHeightWithWidth:(CGFloat)width {
    CGFloat contentContainerViewHeight = self.contentContainerView.bdp_height;
    CGFloat actionListViewHeight = self.actionContainerView.bdp_height;
    CGFloat MIN_ACTION_CONTAINER_HEIGHT = self.minActionContainerHeight;

    // Line
    CGFloat firstLineHeight = (contentContainerViewHeight > 0 && actionListViewHeight > 0 && self.actionArr.firstObject.lineView)?self.config.lineWidth:0;

    // 超长内容适配
    CGFloat MAX_VIEW_HEIGHT = self.containerView.bdp_height - self.layoutInsets.top - self.layoutInsets.bottom - 30 * 2;
    CGFloat buttonHeight = self.preferredStyle == UIAlertControllerStyleAlert ? self.config.alertButtonHeight : self.config.actionSheetButtonHeight;
    if (self.preferredStyle == UIAlertControllerStyleActionSheet && self.cancelAction) {
        MAX_VIEW_HEIGHT -= (self.config.actionSheetBottomMargin + buttonHeight + self.config.actionSheetCancelButtonTopMargin);
    }
    if (contentContainerViewHeight + firstLineHeight + actionListViewHeight > MAX_VIEW_HEIGHT) {
        if (actionListViewHeight <= buttonHeight * 2) {
            contentContainerViewHeight = MAX_VIEW_HEIGHT - firstLineHeight - actionListViewHeight;
        }else {
            if (MAX_VIEW_HEIGHT - contentContainerViewHeight - firstLineHeight > MIN_ACTION_CONTAINER_HEIGHT) {
                actionListViewHeight = MAX_VIEW_HEIGHT - contentContainerViewHeight - firstLineHeight;
            }else {
                actionListViewHeight = MIN_ACTION_CONTAINER_HEIGHT;
                contentContainerViewHeight = MAX_VIEW_HEIGHT - firstLineHeight- actionListViewHeight;
            }
        }
    }

    self.contentContainerView.frame = CGRectMake(0, 0, width, contentContainerViewHeight);
    self.actionArr.firstObject.lineView.frame = CGRectMake(0, contentContainerViewHeight, width, firstLineHeight);
    self.actionContainerView.frame = CGRectMake(0, contentContainerViewHeight + firstLineHeight, width, actionListViewHeight);

    self.headerView.bdp_size = CGSizeMake(width, self.actionContainerView.bdp_bottom);
}

- (void)updateView {
    self.containerView.frame = self.containerView.superview.bounds;
    self.containerBackgroundView.frame = self.containerView.frame;

    CGFloat width = self.preferredStyle == UIAlertControllerStyleAlert ? self.config.alertWidth : self.config.actionSheetWidth;

    // SafeArea & keyboard
    if (!CGRectEqualToRect(self.keyboardScreenFrame, CGRectZero)) {
        CGFloat bottomInset = self.containerView.bdp_height - self.keyboardScreenFrame.origin.y;
        self.layoutInsets = UIEdgeInsetsMake(UIApplication.sharedApplication.statusBarFrame.size.height, 0, bottomInset, 0);
    } else {
        self.layoutInsets = self.containerView.window.safeAreaInsets;
    }

    // ContentView List
    [self updateContentViewWithWidth:width];

    // Action List
    [self updateActionListViewWithWidth:width];

    [self adaptViewHeightWithWidth:width];


    if (self.preferredStyle == UIAlertControllerStyleAlert) {
        self.alertView.center = CGPointMake(self.containerView.bdp_width / 2, self.layoutInsets.top + (self.containerView.bdp_height - self.layoutInsets.top - self.layoutInsets.bottom)/2);
    }else {
        //actionSheet:屏幕底部显示
        CGFloat actionsheetHeight = self.headerView.bdp_bottom;
        if (self.cancelAction) {
            CGFloat buttonHeight = self.preferredStyle == UIAlertControllerStyleAlert ? self.config.alertButtonHeight : self.config.actionSheetButtonHeight;
            _actionSheetCancelView.frame = CGRectMake(0, self.actionSheetTopView.bdp_bottom + self.config.actionSheetCancelButtonTopMargin, width, buttonHeight);
            self.cancelAction.titleButton.frame = _actionSheetCancelView.bounds;

            actionsheetHeight = _actionSheetCancelView.bdp_bottom;
        }

        self.alertView.frame = CGRectMake((self.containerView.bdp_width - width) / 2, self.containerView.bdp_height - actionsheetHeight - self.layoutInsets.bottom - self.config.actionSheetBottomMargin, width, actionsheetHeight);
    }

    // 定制逻辑
    if (_messageLabel) {
        _messageLabel.textAlignment = NSTextAlignmentCenter;
    }

    if (self.customBlockAfterViewUpdated) {
        self.customBlockAfterViewUpdated(self);
    }
}

#pragma mark - Action List
- (void)addAction:(EMAAlertAction *)action {
    if (!action) {
        return;
    }

    // UIAlertController can only have one action with a style of UIAlertActionStyleCancel
    NSAssert((action.style != UIAlertActionStyleCancel || !self.cancelAction), @"UIAlertController can only have one action with a style of UIAlertActionStyleCancel");

    if (!self.originActionArr) {
        self.originActionArr = [NSMutableArray array];
    }
    [self.originActionArr addObject:action];

    action.delegate = self;

    if (!self.actionArr) {
        self.actionArr = [NSMutableArray array];
    }
    [self addActionIntoActionArr:action];

    for (EMAAlertAction *action in self.actionArr) {
        action.highlighted = (action == self.currentHighlightedAction);
    }

    // 已经完成视图构建后再添加Action需要再次构建和更新视图
    if (self.hasBuildViewHierarchy) {
        [self buildViewHierarchy];
        [self updateView];
    }
}

- (void)addActionIntoActionArr:(EMAAlertAction *)action {
    if (action.style == UIAlertActionStyleCancel) {
        self.cancelAction = action;

        // UIAlertController can only have one action with a style of UIAlertActionStyleCancel
        if (self.preferredStyle != UIAlertControllerStyleActionSheet) {
            // Remove the old action with style of UIAlertActionStyleCancel
            if (self.actionArr.firstObject.style == UIAlertActionStyleCancel) {
                [self.actionArr removeObjectAtIndex:0];
            }else if (self.actionArr.lastObject.style == UIAlertActionStyleCancel) {
                [self.actionArr removeObjectAtIndex:self.actionArr.count-1];
            }

            if (self.actionArr.count >= 2) {
                [self.actionArr addObject:action]; // When more than 2 actions, Action with style of UIAlertActionStyleCancel should be placed at the last position
            }else {
                [self.actionArr insertObject:action atIndex:0]; // When less than 3 actions, Action with style of UIAlertActionStyleCancel should be placed at the first position
            }
        }
    }else {
        if (self.actionArr.count >= 2 && self.actionArr.firstObject.style == UIAlertActionStyleCancel) {
            [self.actionArr addObject:action];
            [self.actionArr addObject:self.actionArr.firstObject];
            [self.actionArr removeObjectAtIndex:0];
        }else if (self.actionArr.count >= 2 && self.actionArr.lastObject.style == UIAlertActionStyleCancel) {
            [self.actionArr insertObject:action atIndex:self.actionArr.count-1];
        }else {
            [self.actionArr addObject:action];
        }
    }
}

- (void)setPreferredAction:(EMAAlertAction *)preferredAction {
    if (_preferredAction != preferredAction) {
        _preferredAction = preferredAction;

        if (self.preferredAction) {
            self.cancelAction.highlighted = NO;
            self.preferredAction.highlighted = YES;
        }else {
            self.cancelAction.highlighted = YES;
        }
    }
}

- (NSArray<EMAAlertAction *> *)actions {
    return self.originActionArr.copy;
}

- (EMAAlertAction *)currentHighlightedAction {
    if (self.preferredAction) {
        return self.preferredAction;
    }else {
        return self.cancelAction;
    }
}

#pragma mark - Content List
- (void)addTextFieldWithConfigurationHandler:(void (^)(UITextField *))configurationHandler {

    if (!self.textFieldArr) {
        self.textFieldArr = [NSMutableArray array];
    }

    UITextField *textField = [[UITextField alloc] init];
    [self.textFieldArr addObject:textField];
    textField.borderStyle = UITextBorderStyleNone;
    textField.layer.cornerRadius = 2;
    textField.backgroundColor = UDOCColor.udtokenInputBgDisabled;
    textField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 8, 0)];
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.bdp_height = self.config.textviewHeight;

    [self addContentView:textField viewEdgeInsets:self.config.textviewEdgeInsets];

    if (configurationHandler) {
        configurationHandler(textField);
    }
}

- (NSArray<UITextField *> *)textFields {
    return self.textFieldArr.copy;
}

- (void)addContentView:(UIView *)contentView viewEdgeInsets:(UIEdgeInsets)viewEdgeInsets {
    [self insertContentView:contentView atIndex:self.contentViewArr.count viewEdgeInsets:viewEdgeInsets];
}

- (void)insertContentView:(UIView *)contentView atIndex:(NSUInteger)index viewEdgeInsets:(UIEdgeInsets)viewEdgeInsets {
    if (!contentView) {
        return;
    }

    if (!self.contentViewArr) {
        self.contentViewArr = [NSMutableArray array];
    }
    contentView.viewEdgeInsets = viewEdgeInsets;

    if ([contentView isKindOfClass:UITextField.class]) {
        ((UITextField *)contentView).delegate = self;
    }

    [self.contentViewArr insertObject:contentView atIndex:index];
}

- (NSArray<UIView *> *)contentViews {
    return self.contentViewArr.copy;
}

- (void)addTextViewWithConfigurationHandler:(void (^ __nullable)(EMAAlertTextView *textView))configurationHandler height:(CGFloat)height {
    [self addTextViewWithConfigurationHandler:configurationHandler height:height viewEdgeInsets:self.config.textviewEdgeInsets];
}

- (void)addTextViewWithConfigurationHandler:(void (^ __nullable)(EMAAlertTextView *textView))configurationHandler height:(CGFloat)height viewEdgeInsets:(UIEdgeInsets)viewEdgeInsets {
    EMAAlertTextView *textView = [[EMAAlertTextView alloc] init];
    textView.layer.cornerRadius = 4.0;
    [UDOCLayerBridge setBoderColorWithLayer:textView.layer color:UDOCColor.lineBorderCard];
    textView.layer.borderWidth = 0.5;
    textView.bdp_height = height;

    [self addContentView:textView viewEdgeInsets:viewEdgeInsets];

    if (configurationHandler) {
        configurationHandler(textView);
    }
}

- (void)addLabelWithConfigurationHandler:(void (^ __nullable)(UILabel *label))configurationHandler {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont ema_textWithSize:16];
    label.textColor = UDOCColor.textTitle;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.textAlignment = NSTextAlignmentCenter;

    [self addContentView:label viewEdgeInsets:UIEdgeInsetsZero];

    if (configurationHandler) {
        configurationHandler(label);
    }
}

- (void)addWidgetView:(UIView *)widgetView {
    if (!widgetView) {
        return;
    }
    if (!self.widgetViewArray) {
        self.widgetViewArray = [NSMutableArray array];
    }

    [self.widgetViewArray addObject:widgetView];
}

- (NSArray<UIView *> *)widgetViews {
    return self.widgetViewArray.copy;
}

#pragma mark - EMAAlertActionDelegate
- (void)onActionButtonClicked:(EMAAlertAction *)action {
    [self dismissViewController];
}

- (void)onActionButtonTouch:(UITouch *)touch event:(UIEvent *)event isTouchUp:(BOOL)isTouchUp {

    BOOL touchInActions = NO;

    // 支持滑动选择
    BOOL isInnerContainer = CGRectContainsPoint(self.actionContainerView.bounds, [touch locationInView:self.actionContainerView]);
    for (EMAAlertAction *action in self.originActionArr) {
        if (action.titleButton.superview) {
            CGPoint point = [touch locationInView:action.titleButton];
            if (CGRectContainsPoint(action.titleButton.bounds, point) && (isInnerContainer || (self.preferredStyle == UIAlertControllerStyleActionSheet && action.style == UIAlertActionStyleCancel))) {
                if (isTouchUp) {
                    action.titleButton.highlighted = NO;
                    [action performAction];
                }else {
                    touchInActions = YES;
                    [self handleActionTouchIn:action];
                }
            }else {
                action.titleButton.highlighted = NO;
            }
        }
    }

    if (isTouchUp) {
        self.currentSelectedFlag = nil;
    }else {
        if (!touchInActions) {
            self.currentSelectedFlag = NSNull.null;
        }
    }
}

- (void)handleActionTouchIn:(EMAAlertAction *)action {
    if (self.currentSelectedFlag != action) {
        action.titleButton.highlighted = YES;

        if (self.currentSelectedFlag) {
            // 触感反馈
            UIImpactFeedbackGenerator *feedBackGenertor = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            [feedBackGenertor impactOccurred];
        }

        self.currentSelectedFlag = action;
    }
}

#pragma mark - Keyboard & Responder
- (void)willKeyboardHide:(NSNotification *)notification {
    self.keyboardScreenFrame = CGRectZero;
    [self updateViewWhenKeyboardChangeFrame:notification];

    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.canBecomeFirstResponder) [self becomeFirstResponder];
    });
}

- (void)willKeyboardChangeFrame:(NSNotification *)notification {
    self.keyboardScreenFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self updateViewWhenKeyboardChangeFrame:notification];
}

- (void)updateViewWhenKeyboardChangeFrame:(NSNotification *)notification {
    CGFloat duration = [notification.userInfo bdp_doubleValueForKey:UIKeyboardAnimationDurationUserInfoKey];
    UIViewAnimationCurve animationCurve = [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = UIViewAnimationCurveEaseIn | UIViewAnimationCurveEaseOut | UIViewAnimationCurveLinear;
    switch (animationCurve) {
        case UIViewAnimationCurveEaseInOut:
            options = UIViewAnimationOptionCurveEaseInOut;
            break;
        case UIViewAnimationCurveEaseIn:
            options = UIViewAnimationOptionCurveEaseIn;
            break;
        case UIViewAnimationCurveEaseOut:
            options = UIViewAnimationOptionCurveEaseOut;
            break;
        case UIViewAnimationCurveLinear:
            options = UIViewAnimationOptionCurveLinear;
            break;
        default:
            options = animationCurve << 16;
            break;
    }

    [UIView animateWithDuration:duration delay:0.f options:options animations:^{
        [self updateView];

        if (self.keyboardScreenFrame.size.height > 0) {
            [self fitFirstResponderPosition];
        }
    } completion:^(BOOL finished) {

    }];
}

- (void)fitFirstResponderPosition {
    // 自动适应当前输入框位置
    for (UIView *view in self.contentViewArr) {
        if (view.canBecomeFirstResponder && view.isFirstResponder) {
            if (!CGRectContainsPoint(self.contentContainerView.bounds, view.center)) {
                CGFloat targteOffsetY = view.bdp_centerY - self.contentContainerView.bdp_height/2;
                if (targteOffsetY < 0) {
                    targteOffsetY = 0;
                }else if (targteOffsetY > self.contentContainerView.contentSize.height - self.contentContainerView.bdp_height) {
                    targteOffsetY = self.contentContainerView.contentSize.height - self.contentContainerView.bdp_height;
                }
                [self.contentContainerView setContentOffset:CGPointMake(0, targteOffsetY) animated:NO];
            }
            break;
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSUInteger index = [self.contentViewArr indexOfObject:textField];
    if (index >= 0) {
        for (NSUInteger i = index + 1; i < self.contentViewArr.count; i++) {
            UIView *view = self.contentViewArr[i];
            if ([view isKindOfClass:UITextField.class] || [view isKindOfClass:UITextView.class]) {
                [view becomeFirstResponder];
                return YES;
            }
        }
    }
    return [self enterPressed];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (string.length == 1 && string.UTF8String[0] == '\t') {
        NSUInteger index = [self.contentViewArr indexOfObject:textField];
        if (index >= 0) {
            for (NSUInteger i = index + 1; i < self.contentViewArr.count; i++) {
                UIView *view = self.contentViewArr[i];
                if ([view isKindOfClass:UITextField.class] || [view isKindOfClass:UITextView.class]) {
                    [view becomeFirstResponder];
                    return NO;
                }
            }
            for (NSUInteger i = 0; i < index; i++) {
                UIView *view = self.contentViewArr[i];
                if ([view isKindOfClass:UITextField.class] || [view isKindOfClass:UITextView.class]) {
                    [view becomeFirstResponder];
                    return NO;
                }
            }
        }
    }
    return YES;
}

#pragma mark - UIViewControllerTransitioningDelegate
- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self == presented ? self : nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self == dismissed ? self : nil;
}

#pragma mark - UIViewControllerAnimatedTransitioning
- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return 0;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];

    UIView* toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView* fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];

    if (toViewController == self) {
        [[transitionContext containerView] addSubview:toView];
    } else if (fromViewController == self) {
        [[transitionContext containerView] insertSubview:toView belowSubview:fromView];
    }

    [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
}

#pragma mark - KeyCommands 支持物理键盘的事件
- (BOOL)canBecomeFirstResponder
{
    return self.appearing;
}

- (NSArray *)keyCommands
{
    static NSArray *commands;

    static dispatch_once_t once;
    dispatch_once(&once, ^{
        UIKeyCommand *const enter = [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:0 action:@selector(enterPressed)];
        UIKeyCommand *const escape = [UIKeyCommand keyCommandWithInput:UIKeyInputEscape modifierFlags:0 action:@selector(dismissViewController)];
        commands = @[enter, escape];
    });

    return commands;
}

- (BOOL)enterPressed {
    if (self.preferredAction && [self.actionArr containsObject:self.preferredAction]) {
        [self.preferredAction performAction];
    }else {
        // Only one UIAlertActionStyleDefault or UIAlertActionStyleDestructive action
        EMAAlertAction *targetAction = nil;
        for (EMAAlertAction *action in self.actionArr) {
            if (action.style == UIAlertActionStyleDefault || action.style == UIAlertActionStyleDestructive) {
                if (targetAction) {
                    return NO; // More than one UIAlertActionStyleDefault or UIAlertActionStyleDestructive action
                }
                targetAction = action;
            }
        }
        if (targetAction) {
            [targetAction performAction];
            return YES;
        }
    }
    return NO;
}

#pragma mark - Utils
- (void)setContainerBackgroundView:(UIView *)containerBackgroundView {
    if (_containerBackgroundView != containerBackgroundView) {

        [_containerBackgroundView removeFromSuperview];

        _containerBackgroundView = containerBackgroundView;
    }
}


@end

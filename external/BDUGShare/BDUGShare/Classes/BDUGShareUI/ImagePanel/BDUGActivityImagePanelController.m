//
//  BDUGActivityImagePanelController.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2020/5/6.
//  Copyright © 2020 xunianqiang. All rights reserved.
//

#import "BDUGActivityImagePanelController.h"
#import <Aspects/Aspects.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <Gaia/GAIAEngine.h>
#import "BDUGActivityProtocol.h"
#import "BDUGShareAdapterSetting.h"
#import "UIColor+UGExtension.h"
#import "BDUGShareMacros.h"
#import "BDUGShareBaseUtil.h"
#import "BDUGSharePanelContent.h"

static const CGFloat kBDUGActivityPanelSingleRowHeight = 98.f;
static const CGFloat kBDUGActivityPanelLeftPadding = 8.f;
static const CGFloat kBDUGActivityPanelRowTopMargin = 10.f;

#define kTTContactAdditionalHeight  40

static const CGFloat kBDUGActivityPanelItemImageViewTopPadding = 6.f;
static const CGFloat kBDUGActivityPanelItemImageViewWidth = 60.f;

static const CGFloat kBDUGActivityPanelCancelButtonHeight = 44.f;

NSString *const kImagePanelWillTransitionToSize = @"kImagePanelWillTransitionToSize";

#pragma mark - BDUGActivityImagePanelThemedButton

@interface BDUGActivityImagePanelThemedButton : UIButton

@property (nonatomic, strong) id<BDUGActivityProtocol> activity;
@property (nonatomic, strong) id<BDUGActivityContentItemProtocol> contentItem;
@property (nonatomic, strong) NSIndexPath *itemIndexPath;
@property (nonatomic, strong) UIImageView *itemImageView;
@property (nonatomic, strong) UILabel *itemTitleLabel;

@end

@implementation BDUGActivityImagePanelThemedButton

- (instancetype)initWithFrame:(CGRect)frame
                         item:(id<BDUGActivityProtocol>)activity
                itemIndexPath:(NSIndexPath *)itemIndexPath {
    self = [super initWithFrame:frame];
    if (self) {
        self.activity = activity;
        self.contentItem = [activity contentItem];
        [(NSObject *)self.contentItem addObserver:self
                                       forKeyPath:@"selected"
                                          options:NSKeyValueObservingOptionNew
                                          context:nil];
        self.itemIndexPath = itemIndexPath;
        CGFloat imgWidth = kBDUGActivityPanelItemImageViewWidth;
        if ([activity respondsToSelector:@selector(customWidth)]) {
            imgWidth = [activity customWidth];
        }
        self.itemImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,kBDUGActivityPanelItemImageViewTopPadding, imgWidth, imgWidth)];
        self.itemImageView.btd_centerX = [self PanelItemWidth] / 2;
        [self addSubview:self.itemImageView];
        
        self.itemTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [self PanelItemWidth], 14)];
        self.itemTitleLabel.font = [UIFont systemFontOfSize:10.0f];
        self.itemTitleLabel.textColor = [UIColor colorWithHexString:@"#222222"];
        self.itemTitleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.itemTitleLabel];
        
        [self refreshUI];
    }
    
    return self;
}

- (CGFloat)PanelItemWidth {
    //    if ([self.activity respondsToSelector:@selector(customItemWidth)]) {
    //        return [self.activity customItemWidth];
    //    }
    if ([UIScreen mainScreen].bounds.size.width < 375) {
        return 68;
    } else {
        return 80;
    }
}

- (void)dealloc {
    [(NSObject *)self.contentItem removeObserver:self forKeyPath:@"selected"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.contentItem && [keyPath isEqualToString:@"selected"]) {
        [self refreshUI];
    }
}

- (void)refreshUI {
    self.itemImageView.image = nil;
    self.itemImageView.layer.borderColor = nil;
    self.itemImageView.layer.masksToBounds = NO;
    self.itemImageView.layer.borderWidth = 0;
    self.itemImageView.layer.cornerRadius = 0;
    self.itemImageView.clipsToBounds = YES;
    
    UIImage *image;
    if ([self.activity.contentItem respondsToSelector:@selector(activityImage)] && self.activity.contentItem.activityImage) {
        image = self.activity.contentItem.activityImage;
    } else if ([self.activity respondsToSelector:@selector(activityImageName)]) {
        NSString * imageName = [self.activity activityImageName];
        if (imageName.length > 0) {
            image = [UIImage imageNamed:imageName];
        }
    }
    self.itemImageView.image = image;
    
    NSString * title = [self.activity contentTitle];
    if ([self.contentItem conformsToProtocol:@protocol(BDUGActivityContentItemSelectedDigProtocol)]) {
        int64_t count = [(id<BDUGActivityContentItemSelectedDigProtocol>)self.contentItem count];
        self.itemTitleLabel.text = [NSString stringWithFormat:@"%@%lld", title, count];
    }else {
        self.itemTitleLabel.text = title;
    }
    
    self.itemTitleLabel.btd_bottom = self.btd_height - 20.0;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted) {
        [UIView animateWithDuration:0.5
                              delay:0
             usingSpringWithDamping:0.3
              initialSpringVelocity:0.1
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.itemImageView.transform = CGAffineTransformMakeScale(0.9, 0.9);
                         } completion:nil];
    } else {
        [UIView animateWithDuration:0.5
                              delay:0
             usingSpringWithDamping:0.3
              initialSpringVelocity:0.1
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.itemImageView.transform = CGAffineTransformIdentity;
                         } completion:nil];
    }
}

- (NSString *)accessibilityLabel {
    return self.itemTitleLabel.text;
}

@end

#pragma mark - BDUGActivityPanelControllerWindow

@interface BDUGActivityImagePanelControllerWindow : UIWindow

@property (strong, nonatomic) BDUGActivityImagePanelController *panel;

@end

@implementation BDUGActivityImagePanelControllerWindow

@end

#pragma mark - BDUGActivityPanelRootViewController

@interface BDUGActivityImagePanelRootViewController : UIViewController

@property (nonatomic, assign) BOOL supportAutorotate;
@property (nonatomic, assign) UIInterfaceOrientationMask supportOrientation;

@end

@implementation BDUGActivityImagePanelRootViewController

- (BOOL)shouldAutorotate {
    return self.supportAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.supportOrientation;
}

@end

#pragma mark - BDUGActivityPanelController

@interface BDUGActivityImagePanelController () {
    CGFloat _itemWidth;
}

@property (strong, nonatomic) NSMutableArray <NSMutableArray *> *itemViews;
@property (strong, nonatomic) UIView *panelView;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIScrollView *imageScrollView;
@property (strong, nonatomic) UIView *maskView;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) BDUGActivityImagePanelControllerWindow *backWindow;
@property (strong, nonatomic) BDUGActivityImagePanelRootViewController *rootViewController;
@property (strong, nonatomic) NSArray <NSArray *> *items;
@property (strong, nonatomic) NSString *cancelTitle;
@property (strong, nonatomic) UIWindow *originalKeyWindow;
@property (nonatomic, assign) BOOL isWaitingActivityData;

@property (nonatomic, strong) UILabel *panelTitleLabel;

@property (nonatomic, strong) BDUGSharePanelContent *panelContent;
@end

@implementation BDUGActivityImagePanelController

#pragma mark -- Life cycle

- (void)dealloc {
    [self removeNotification];
}

- (instancetype)initWithItems:(NSArray<NSArray *> *)items panelContent:(BDUGSharePanelContent *)panelContent {
    self = [super init];
    if (self) {
        self.itemViews = [NSMutableArray array];
        self.items = items;
        _panelContent = panelContent;
        self.cancelTitle = panelContent.cancelBtnText;
        
        [self createComponents];
        [self addNotification];
    }
    return self;
}

#pragma mark -- Notification

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rootViewWillTransitionToSize:)
                                                 name:kImagePanelWillTransitionToSize
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationStautsBarDidRotate)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationStautsBarDidRotate {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self willTransitionToSize:[UIApplication sharedApplication].delegate.window.bounds.size];
    });
}

- (void)rootViewWillTransitionToSize:(NSNotification *)noti {
    CGSize size = [noti.object CGSizeValue];
    [self willTransitionToSize:size];
}

- (void)willTransitionToSize:(CGSize)size {
    if ([UIDevice btd_OSVersionNumber] < 8){
        CGRect frame = CGRectZero;
        frame.size = size;
        self.backWindow.frame = frame;
    }
}

- (void)refreshStatusBarOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    id<AspectToken> aspectToken = [UIViewController aspect_hookSelector:@selector(shouldAutorotate) withOptions:AspectPositionInstead usingBlock:^(id<AspectInfo> info){
        BOOL result = NO;
        [[info originalInvocation] setReturnValue:&result];
    }error:nil];
    NSArray *windowsArray = [UIApplication sharedApplication].windows;
    NSMutableArray *tokenArray = [[NSMutableArray alloc] initWithCapacity:windowsArray.count];
    for (UIWindow *window in windowsArray) {
        id<AspectToken> token = [window.rootViewController aspect_hookSelector:@selector(shouldAutorotate) withOptions:AspectPositionInstead usingBlock:^(id<AspectInfo> info){
            BOOL result = NO;
            [[info originalInvocation] setReturnValue:&result];
        }error:nil];
        if (token) {
            [tokenArray addObject:token];
        }
    }
    [[UIApplication sharedApplication] setStatusBarOrientation:interfaceOrientation animated:NO];
    if (aspectToken) {
        [aspectToken remove];
    }
    for (id<AspectToken> token in tokenArray) {
        [token remove];
    }
}

- (CGAffineTransform)transformForRotationAngle:(UIInterfaceOrientation)statusBarOri {
    if (statusBarOri == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    } else if (statusBarOri == UIInterfaceOrientationLandscapeLeft) {
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if (statusBarOri == UIInterfaceOrientationLandscapeRight) {
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}

#pragma mark -- TTSharePanelTransformMessage

- (void)message_sharePanelIfNeedTransform:(BOOL)isMovieFullScreen
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGRect windowFrame = [UIApplication sharedApplication].keyWindow.bounds;
    _backWindow.frame = windowFrame;
    
    if (isMovieFullScreen) {
        _backWindow.transform = [self transformForRotationAngle:orientation];
    } else {
        _backWindow.transform = CGAffineTransformIdentity;
    }
    _backWindow.frame = windowFrame;
    _backWindow.rootViewController.view.frame = _backWindow.bounds;
    
}

#pragma mark - Create UI components

- (void)createComponents {
    //Root view controller
    self.rootViewController = [[BDUGActivityImagePanelRootViewController alloc] init];
    self.rootViewController.supportAutorotate = self.panelContent.supportAutorotate;
    self.rootViewController.supportOrientation = self.panelContent.supportOrientation;
    UIInterfaceOrientation rightOrientation  = [[UIApplication sharedApplication] statusBarOrientation];
    
    //Back window
    self.backWindow = [[BDUGActivityImagePanelControllerWindow alloc] init];
    
    CGRect windowFrame = [UIApplication sharedApplication].keyWindow.bounds;
    self.originalKeyWindow = [UIApplication sharedApplication].keyWindow;
    if (windowFrame.size.width != [UIScreen mainScreen].bounds.size.width && windowFrame.size.height != [UIScreen mainScreen].bounds.size.width) {
        windowFrame = [UIApplication sharedApplication].delegate.window.bounds;
        self.originalKeyWindow = [UIApplication sharedApplication].delegate.window;
    }
    
    //todo: 横屏问题。 主动询问movieView是否全屏，视情况旋转
//    SAFECALL_MESSAGE(TTSharePanelTransformMessage, @selector(message_sharePanelIfNeedTransformWithBlock:), message_sharePanelIfNeedTransformWithBlock:self.fullScreenTransformHandlerBlock);
    
    self.backWindow.rootViewController = self.rootViewController;
    self.backWindow.windowLevel = UIWindowLevelNormal;
    self.backWindow.backgroundColor = [UIColor clearColor];
    [self.backWindow makeKeyAndVisible];
    self.backWindow.frame = windowFrame;
    self.backWindow.rootViewController.view.frame = self.backWindow.bounds;
    
    //旋转后，刷新原来的statusbar的方向
    if ([UIDevice btd_OSVersionNumber] < 10) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self refreshStatusBarOrientation:rightOrientation];
        });
    } else {
        [self refreshStatusBarOrientation:rightOrientation];
    }
    self.backWindow.hidden = YES;
    
    [self.rootViewController.view addSubview:self.maskView];
    [self.maskView addSubview:self.panelView];
    [self.maskView addSubview:self.cancelButton];
    [self.maskView addSubview:self.imageScrollView];
    
    //Create scroll views
    [self.items enumerateObjectsUsingBlock:^(NSArray * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableArray * itemViews = [NSMutableArray array];
        //Scroll view
        UIScrollView *scrollView = [self createScrollViewWithSection:idx];
        [self.panelView addSubview:scrollView];
        
        //Current scroll view's item views
        [self.items[idx] enumerateObjectsUsingBlock:^(id  _Nonnull jobj, NSUInteger jidx, BOOL * _Nonnull jstop) {
            NSIndexPath * indexPath = [NSIndexPath indexPathForRow:jidx inSection:idx];
            BDUGActivityImagePanelThemedButton *itemView = [self itemViewWithIndex:indexPath item:self.items[idx][jidx]];
            [itemViews addObject:itemView];
            [scrollView addSubview:itemView];
        }];
        [self.itemViews addObject:itemViews];
        
        BOOL isLastSection = ((self.items.count - 1) == idx);
        if (!isLastSection) {
            //Separate line view
            UIView *separateLineView = [self createSeparateLineViewWithSection:idx];
            separateLineView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
            separateLineView.btd_width = self.panelView.btd_width;
            separateLineView.btd_top = scrollView.btd_bottom - [UIDevice btd_onePixel];
            separateLineView.btd_height = [UIDevice btd_onePixel];
            [self.panelView addSubview:separateLineView];
        }
    }];
    
    self.imageView.image = self.panelContent.shareContentItem.image;
    self.imageView.btd_height = self.imageView.btd_width * self.imageView.image.size.height / self.imageView.image.size.width;
}

- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:self.backWindow.bounds];
        _maskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _maskView.backgroundColor = [UIColor colorWithHexString:@"000000" alpha:0.3];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelButtonAction:)];
        [_maskView addGestureRecognizer:tap];
    }
    return _maskView;
}

- (UIView *)panelView {
    if (!_panelView) {
        NSUInteger line = self.items.count;
        CGFloat backViewHeight = kBDUGActivityPanelSingleRowHeight * line + kBDUGActivityPanelRowTopMargin * 2 + [UIDevice btd_onePixel] * (line - 1);
        _panelView = [[UIView alloc] initWithFrame:CGRectMake(kBDUGActivityPanelLeftPadding, 0, self.maskView.btd_width - kBDUGActivityPanelLeftPadding * 2, backViewHeight)];
        _panelView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        _panelView.backgroundColor = [UIColor colorWithHexString:@"ffffff"];
        _panelView.layer.cornerRadius = 8.f;
    }
    return _panelView;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(kBDUGActivityPanelLeftPadding, 0, self.maskView.btd_width - kBDUGActivityPanelLeftPadding * 2, kBDUGActivityPanelCancelButtonHeight)];
        _cancelButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
        [_cancelButton setTitleColor:[UIColor colorWithHexString:@"222222"] forState:UIControlStateNormal];
        _cancelButton.backgroundColor = [UIColor colorWithHexString:@"ffffff"];
        _cancelButton.layer.cornerRadius = 8.f;
        [_cancelButton setTitle:self.cancelTitle forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

- (UIScrollView *)imageScrollView {
    if (!_imageScrollView) {
        _imageScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(60, 36, self.maskView.btd_width - 60 * 2, 0)];
        _imageScrollView.showsVerticalScrollIndicator = NO;
        _imageView = [[UIImageView alloc] initWithFrame:_imageScrollView.bounds];
        [_imageScrollView addSubview:_imageView];
    }
    return _imageScrollView;
}

- (UIScrollView *)createScrollViewWithSection:(NSUInteger)section {
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, kBDUGActivityPanelSingleRowHeight * section + kBDUGActivityPanelRowTopMargin + section * [UIDevice btd_onePixel], self.panelView.btd_width, kBDUGActivityPanelSingleRowHeight)];
    scrollView.tag = section;
    scrollView.alwaysBounceHorizontal = YES;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.contentSize = CGSizeMake([self PanelItemWidth] * [self.items[section] count], kBDUGActivityPanelSingleRowHeight);
    if (@available(iOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    return scrollView;
}

- (UIView *)createSeparateLineViewWithSection:(NSUInteger)section {
    UIView *separateLine = [[UIView alloc] init];
    separateLine.backgroundColor = [UIColor colorWithHexString:@"dddddd"];
    return separateLine;
}

- (CGFloat)PanelItemWidth {
    if ([UIScreen mainScreen].bounds.size.width < 375) {
        return 68;
    } else {
        return 80;
    }
}

- (BDUGActivityImagePanelThemedButton *)itemViewWithIndex:(NSIndexPath *)indexPath item:(id<BDUGActivityProtocol>)item {
    BDUGActivityImagePanelThemedButton *view = nil;
    CGRect frame;
    CGFloat amount = [(NSArray *)self.items[0] count];
    if (self.items.count == 1 && amount < 4) {
        CGFloat width = self.panelView.btd_width;
        CGFloat devideWidth = width / amount;
        CGFloat centerX = devideWidth * indexPath.row + devideWidth/2.0;
        frame = CGRectMake(centerX - [self PanelItemWidth] / 2, 0, [self PanelItemWidth], kBDUGActivityPanelSingleRowHeight);
        view = [[BDUGActivityImagePanelThemedButton alloc] initWithFrame:frame item:item itemIndexPath:indexPath];
    }else {
        frame = CGRectMake(indexPath.row * [self PanelItemWidth], 0, [self PanelItemWidth], kBDUGActivityPanelSingleRowHeight);
        view = [[BDUGActivityImagePanelThemedButton alloc] initWithFrame:frame item:item itemIndexPath:indexPath];
    }
    id <BDUGActivityContentItemProtocol> contentItem = [item contentItem];
    if ([contentItem conformsToProtocol:@protocol(BDUGActivityContentItemSelectedDigProtocol)]) {
        [view addTarget:self action:@selector(selectedDigIconButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        id<BDUGActivityContentItemSelectedDigProtocol> selectedItem = (id<BDUGActivityContentItemSelectedDigProtocol>)item.contentItem;
        view.selected = selectedItem.selected;
    } else {
        [view addTarget:self action:@selector(buttonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return view;
}

#pragma mark -- Item action

- (void)selectedDigIconButtonAction:(BDUGActivityImagePanelThemedButton *)sender {
    id<BDUGActivityProtocol> activity = self.items[sender.itemIndexPath.section][sender.itemIndexPath.row];
    
    if ([self.delegate respondsToSelector:@selector(activityPanel:clickedWith:)]) {
        [self.delegate activityPanel:self clickedWith:activity];
    }
    __weak typeof(self) weakSelf = self;
    [activity performActivityWithCompletion:^(id<BDUGActivityProtocol> activity, NSError *error, NSString *desc) {
        if ([weakSelf.delegate respondsToSelector:@selector(activityPanel:completedWith:error:desc:)]) {
            [weakSelf.delegate activityPanel:weakSelf completedWith:activity error:error desc:desc];
        }
    }];
}

- (void)buttonClickAction:(BDUGActivityImagePanelThemedButton *)sender {
    id<BDUGActivityProtocol> activity = self.items[sender.itemIndexPath.section][sender.itemIndexPath.row];
    
    if ([self.delegate respondsToSelector:@selector(activityPanel:clickedWith:)]) {
        [self.delegate activityPanel:self clickedWith:activity];
    }
    [self cancelWithItem:activity];
}

- (void)cancelButtonAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(activityPanel:clickedWith:)]) {
        [self.delegate activityPanel:self clickedWith:nil];
    }
    [self cancelWithItem:nil];
    if ([self.delegate respondsToSelector:@selector(activityPanelDidCancel:)]) {
        [self.delegate activityPanelDidCancel:self];
    }
}

- (void)cancelWithItem:(id<BDUGActivityProtocol>)activity {
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.39 :0.575 :0.565 :1]];
    [UIView animateWithDuration:0.24 animations:^{
        self.panelView.btd_bottom = self.maskView.btd_height + self.panelView.btd_height;
        self.backWindow.alpha = 0.0f;
        self.imageScrollView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.originalKeyWindow makeKeyAndVisible];
        self.backWindow.hidden = YES;
        self.backWindow.panel = nil;
        
        if (!self.isWaitingActivityData) {
            [self performActivity:activity];
        }
    }];
    [CATransaction commit];
}

- (void)setNeedsWaitForData {
    self.isWaitingActivityData = YES;
}

- (void)preparedActivity:(id<BDUGActivityProtocol>)activity{
    void (^block)(void) = ^{
        [self performActivity:activity];
    };
    
    if (!self.backWindow.hidden) {  // 动画未结束
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            block();
        });
    } else {
        block();
    }
}

- (void)performActivity:(id<BDUGActivityProtocol>)activity {
    __weak typeof(self) weakSelf = self;
    [activity performActivityWithCompletion:^(id<BDUGActivityProtocol> activity, NSError *error, NSString *desc) {
        if ([weakSelf.delegate respondsToSelector:@selector(activityPanel:completedWith:error:desc:)]) {
            [weakSelf.delegate activityPanel:weakSelf completedWith:activity error:error desc:desc];
        }
    }];
}

#pragma mark -- Public

- (void)show {
    self.backWindow.panel = self;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kUpdateConversationListNotification" object:nil];
    self.rootViewController.view.accessibilityViewIsModal = YES;
    
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.itemViews.firstObject.firstObject);
    
    self.panelView.btd_top = self.maskView.btd_height;
    self.cancelButton.btd_top = self.panelView.btd_bottom + 6;
    self.backWindow.alpha = 0.0f;
    self.backWindow.hidden = NO;
    
    CGFloat bottomSafeAreaInset = [BDUGShareBaseUtil mainWindow].btd_safeAreaInsets.bottom;
    CGFloat cancelButtonTargetBottom = self.maskView.btd_height - 8 - bottomSafeAreaInset;
    CGFloat panelViewTargetBottom = cancelButtonTargetBottom - self.cancelButton.btd_height - 6;
    CGFloat imageMaxHeight = panelViewTargetBottom - 36 - self.panelView.btd_height - 20;
    if (self.imageView.btd_height > imageMaxHeight) {
        self.imageScrollView.btd_height = imageMaxHeight;
        self.imageScrollView.contentSize = CGSizeMake(0, self.imageView.btd_height);
        self.imageScrollView.scrollEnabled = YES;
    } else {
        self.imageScrollView.btd_height = self.imageView.btd_height;
        self.imageScrollView.scrollEnabled = NO;
    }
    self.imageScrollView.alpha = 0;
    
    
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.14 :1 :0.34 :1]];
    [UIView animateWithDuration:0.48 animations:^{
        self.cancelButton.btd_bottom = cancelButtonTargetBottom;
        self.panelView.btd_bottom = panelViewTargetBottom;
        self.backWindow.alpha = 1.0f;
        self.imageScrollView.alpha = 1;
    }];
    [CATransaction commit];
}

- (void)hide {
    [self cancelWithItem:nil];
}

@end

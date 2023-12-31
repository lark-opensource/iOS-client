//
//  BDPToolBarView.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/16.
//

#import "BDPAppContainerController.h"
#import "BDPBadgeLabel.h"
#import "BDPBaseContainerController.h"
#import <OPFoundation/BDPBundle.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPMacroUtils.h>
#import "BDPPermissionController.h"
#import "BDPPrivacyAccessNotifier.h"
#import <OPFoundation/BDPResponderHelper.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import "BDPTaskManager.h"
#import "BDPTimorClient+Business.h"
#import "BDPToolBarView.h"
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <OPFoundation/UIImage+BDPExtension.h>
#import <OPFoundation/BDPNotification.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import "BDPAppPageController.h"
#import <OPFoundation/BDPCommon.h>
#import <Masonry/Masonry.h>
#import <OPFoundation/EEFeatureGating.h>
#import <OPFoundation/BDPAppMetaUtils.h>
#import <OPFoundation/BDPMonitorEvent.h>


#import <LarkUIKit/LarkUIKit-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

#define kBDPToolBarViewBtnSize 20.f
#define kBDPToolBarViewHeight 44.f
#define kBDPToolBarViewWidth 80.f
#define kBDPToolBarViewWidth_1 90.f

@interface BDPToolBarView () <MenuPanelDelegate, AppMenuPrivacyDelegate, AlternateAnimatorDelegate>

@property (nonatomic, strong, readwrite, nullable) BDPUniqueID *uniqueID;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) BDPBadgeLabel *badgeLabel;

@property (nonatomic, strong) PrivacyAlternateAnimator * privacyAnimator;

@property (nonatomic, strong) ToolBarMoreButtonDelegate * moreButtonDelegate;

@property (nonatomic, strong) AppMenuCompactAdditionView * compactAdditionView;

@property (nonatomic, weak) id<OPContainerProtocol> container;

@property (nonatomic, weak) id<BDPNavLeaveComfirmHandler> leaveComfirmHandler;

// 产品埋点需要上报的按钮数组
@property (nonatomic, strong) NSMutableArray<NSString *> *reportMenuItems;
@property (nonatomic, strong) NSMutableArray<NSString *> *addtionViewReportItems;
@end

@implementation BDPToolBarView

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID
{ 
    BOOL isHideMoreButton = [[BDPTimorClient sharedClient].currentNativeGlobalConfiguration hideMenu];
    self = [super initWithFrame:CGRectMake(0, 0, isHideMoreButton ? kBDPToolBarViewWidth / 2.0 : kBDPToolBarViewWidth, kBDPToolBarViewHeight)];
    if (self) {
        _uniqueID = uniqueID;
        _moreButtonDelegate = [[ToolBarMoreButtonDelegate alloc] init];

        self.container = [OPApplicationService.current getContainerWithUniuqeID:uniqueID];

        [self setupViews];
        [BDPCurrentTask.toolBarManager addToolBar:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdateMoreButtonBadge:) name:kBDPCommonMoreBtnBadgeUpdateNotification object:nil];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.h5Style == BDPToolBarViewH5StyleApp) {
        CGFloat top = (kBDPToolBarViewHeight - kBDPToolBarViewBtnSize) / 2.0;
        _moreButton.frame = CGRectMake(8, top, kBDPToolBarViewBtnSize, kBDPToolBarViewBtnSize);
        CGSize size = [_badgeLabel suitableSize];
        _badgeLabel.frame = CGRectMake(_moreButton.frame.origin.x + 21, _moreButton.frame.origin.y + 1.5, size.width, size.height);
        _closeButton.frame = CGRectMake(CGRectGetWidth(self.frame) - kBDPToolBarViewBtnSize - 19 , top, kBDPToolBarViewBtnSize, kBDPToolBarViewBtnSize);
    } else {
        CGFloat top = (kBDPToolBarViewHeight - kBDPToolBarViewBtnSize) / 2.0;
        if ([OPGadgetRotationHelper enableGadgdetRotation:self.uniqueID]) {
            // 这边正确方式应该是根据按钮的superView尺寸来计算, 因为横屏下, BDPToolBarView尺寸会受到系统导航栏约束,
            // 使用定值是无法正确布局.
            top = (self.frame.size.height - kBDPToolBarViewBtnSize) / 2.0;
        }
        _moreButton.frame = CGRectMake(4, top, kBDPToolBarViewBtnSize, kBDPToolBarViewBtnSize);
        CGSize size = [_badgeLabel suitableSize];
        _badgeLabel.frame = CGRectMake(0, 0, size.width, size.height);
        _badgeLabel.center = CGPointMake(_moreButton.frame.origin.x + _moreButton.frame.size.width - 6, _moreButton.frame.origin.y + 6);
        _closeButton.frame = CGRectMake(CGRectGetWidth(self.frame) - kBDPToolBarViewBtnSize - 15, top, kBDPToolBarViewBtnSize, kBDPToolBarViewBtnSize);
    }
    _moreButton.contentMode = UIViewContentModeScaleAspectFit;
    _closeButton.contentMode = UIViewContentModeScaleAspectFit;
    if ([OPSDKFeatureGating shouldFixToolBarPosition:self.uniqueID]) {
        // iOS 默认的 rightBarButtonItem 位置太偏左，这里通过一些 trick 的方式来实现位置偏移
        // 从 iOS 11 后 UIBarButtonSystemItemFixedSpace 已失效，此处实现 rightBarButtonItem 在导航栏中显示时位置修正
        // 目前未找到更好的替代方法，但下方代码的健壮性足够，查找不准确的最坏结果时位置偏移不成功，仍可操作，但不会乱偏移
        UIView *view = self;
        
        if ([OPSDKFeatureGating shouldFixToolBarLayoutError]) {
            // https://meego.feishu.cn/larksuite/issue/detail/10011677?parentUrl=%2Flarksuite%2FissueView%2FSBg67fTcn
            CGFloat systemVersion = [UIDevice currentDevice].systemVersion.floatValue;
            if (systemVersion >= 11.0f && systemVersion < 13.0f) {
                
                // toolbar在iOS11-12上,toolbar的父视图的宽度被缩小了，这是导致'x''...'按钮反转的原因,这边需要限制最小宽度为需要的宽度
                UIView *superView = view.superview;
                if([superView isKindOfClass:[UIStackView class]]) {
                    BOOL replaceConstraintFlag = NO;
                    for (NSLayoutConstraint *constraint in superView.constraints) {
                        if (constraint.firstItem == view && constraint.firstAttribute == NSLayoutAttributeWidth) {
                            [superView removeConstraint:constraint];

                            NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:superView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kBDPToolBarViewWidth];

                            [superView addConstraint:widthConstraint];
                            replaceConstraintFlag = YES;
                        }
                    }
                    if(!replaceConstraintFlag) {
                        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:superView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kBDPToolBarViewWidth];

                        [superView addConstraint:heightConstraint];
                    }
                }
                
                // 与上面类似,toolbar自身的高度被另外一个系统约束限制为0,导致事件不能被响应
                for (NSLayoutConstraint *constraint in view.constraints) {
                    if (constraint.firstItem == view && constraint.firstAttribute == NSLayoutAttributeHeight && constraint.constant == 0) {
                        [view removeConstraint:constraint];
                        
                        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kBDPToolBarViewHeight];
                        
                        [view addConstraint:heightConstraint];
                    }
                }
            }
        }

        
        while (![view isKindOfClass:[UINavigationBar class]] && [view superview] != nil)
        {
            view = [view superview];
            if ([view isKindOfClass:[UIStackView class]] && [view superview] != nil)
            {
                NSArray<NSLayoutConstraint *> *constraints = view.superview.constraints;
                for (NSLayoutConstraint *constraint in constraints) {
                    // UIStackView(包裹了ToolBar) 右侧与父容器的布局关系需要修改
                    // 查找该规则：<NSLayoutConstraint:0x6000023f0230 _UIButtonBarStackView:0x7fcddac3ac30.trailing == UILayoutGuide:0x60000396a680.trailing>
                    if (constraint.firstItem == view && constraint.firstAttribute == NSLayoutAttributeTrailing) {
                        
                        // 删除原来的 trailing 约束
                        [view.superview removeConstraint:constraint];
                        
                        // 添加新的 trailing 约束，UIStackView 右侧距离父容器右侧偏移
                        CGFloat rightMargin = -6;
                        NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint
                                                                  constraintWithItem:view
                                                                  attribute:NSLayoutAttributeTrailing
                                                                  relatedBy:NSLayoutRelationEqual
                                                                  toItem:view.superview
                                                                  attribute:NSLayoutAttributeTrailing
                                                                  multiplier:1.0
                                                                  constant:rightMargin];
                        trailingConstraint.priority = UILayoutPriorityRequired;
                        [view.superview addConstraint:trailingConstraint];
                        
                        break;
                    }
                }
            }
        }
    }
}

- (void)setHidden:(BOOL)hidden
{
    if (self.hidden != hidden) {
        // 已调用隐藏ToolBar接口，则不再显示
        if (BDPCurrentTask.toolBarManager.hidden && hidden == NO) {
            return;
        }
        [super setHidden:hidden];
    }
}

- (void)setupViews
{
    UIImage *closeImage = [UDOCIconBridge getIconByKeyWithKey:UDOCIConKeyUDOCIConKeyCloseOutlined];
    UIImage * moreImage = [UDOCIconBridge getIconByKeyWithKey:UDOCIConKeyUDOCIConKeyCloseMoreOutlined];
    self.layer.borderColor = [UIColor clearColor].CGColor;
    self.backgroundColor = [UIColor clearColor];
    closeImage = [closeImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    moreImage = [moreImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    UIButton *closeButton = [[UIButton alloc] init];
    closeButton.accessibilityIdentifier = @"gadget.page.closeButton";
    closeButton.accessibilityIdentifier = OPNavigationBarItemConsts.closeButtonKey;
    closeButton.tintColor = [UIColor blackColor];
    closeButton.backgroundColor = [UIColor clearColor];
    [closeButton setImage:closeImage forState:UIControlStateNormal];
    [closeButton setAdjustsImageWhenHighlighted:NO];
    [closeButton addTarget:self action:@selector(closeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:closeButton];
    _closeButton = closeButton;
    [closeButton addBDPPointerInteraction];
    
    if (![[BDPTimorClient sharedClient].currentNativeGlobalConfiguration hideMenu]) {
        UIButton *moreButton = nil;
        ToolBarMoreButton * toolBarMoreButton = [[ToolBarMoreButton alloc] init];
        NSString * containerPathString = [self containerMoreButtonBadgePathString];
        [toolBarMoreButton setBadgeObserveFor:containerPathString];
        moreButton = toolBarMoreButton;
        
        moreButton.accessibilityIdentifier = OPNavigationBarItemConsts.moreButtonKey;
        moreButton.tintColor = [UIColor blackColor];
        moreButton.backgroundColor = [UIColor clearColor];
        [moreButton setImage:moreImage forState:UIControlStateNormal];
        [moreButton setAdjustsImageWhenHighlighted:NO];
        [moreButton addTarget:self action:@selector(fireMenu:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:moreButton];
        _moreButton = moreButton;
        [moreButton addBDPPointerInteraction];

        _privacyAnimator = [[PrivacyAlternateAnimator alloc] initWithTargetView:moreButton];
        _privacyAnimator.delegate = _moreButtonDelegate;
        _privacyAnimator.dataSource = _moreButtonDelegate;

        BDPBadgeLabel *badgeLabel = [BDPBadgeLabel new];
        badgeLabel.maxNum = 999;
        [self addSubview:badgeLabel];
        _badgeLabel = badgeLabel;
        [_privacyAnimator startNotifier];
    }
}

/// 获取容器按钮的Path，LarkBadge需要使用这个Path
- (NSString *)containerBadgePathString {
    /// 容器的PathString，这个需要注册在LarkBaseService的BadgeImpl结构体中，请不要随便改变
    /// demo工程请注册在BadgeImpl.swift中
    NSString * parentString = @"app_id";
    if (self.uniqueID != nil) {
        parentString = [parentString stringByAppendingString:self.uniqueID.appID];
        return parentString;
    } else {
        BDPLogWarn(@"appid is nil when make a containerPathString");
        return parentString;
    }
}

- (NSString *)containerMoreButtonBadgePathString {
    /// 容器菜单的PathString，这个需要注册在LarkBaseService的BadgeImpl结构体中，请不要随便改变
    /// demo工程请注册在BadgeImpl.swift中
    NSString * buttonPathString = @".app_more";
    NSString * containerPathString = [self containerBadgePathString];
    return [containerPathString stringByAppendingString:buttonPathString];
}

/// 创建一个菜单操作句柄
- (id<MenuPanelOperationHandler>)makeMenuOperationHandler{
    BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
    UIViewController *containerVC = task.containerVC;
    id<MenuPanelOperationHandler> handler = [MenuPanelHelper getMenuPanelHandlerIn:containerVC for: MenuPanelStyleTraditionalPanel];
    handler.delegate = self;
    return handler;
}

- (void)setH5Style:(BDPToolBarViewH5Style)h5Style
{
    _h5Style = h5Style;
    [self.closeButton removeFromSuperview];
    [self.moreButton removeFromSuperview];
    [self setupViews];
    CGFloat width = (h5Style == BDPToolBarViewH5StyleApp) ? kBDPToolBarViewWidth_1 : kBDPToolBarViewWidth;
    BOOL isHideMoreButton = [[BDPTimorClient sharedClient].currentNativeGlobalConfiguration hideMenu];
    self.frame = CGRectMake(0, 0, isHideMoreButton ? width / 2.0 : width, kBDPToolBarViewHeight);
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (CGRect)closeButtonFrame {
    if (self.closeButton) {
        if (self.superview) {
            return [self convertRect:self.closeButton.frame toView:self.superview];
            
        } else {
            // 没superview的情况下手动计算rect
            CGRect frame = self.closeButton.frame;
            frame.origin.x += self.frame.origin.x;
            frame.origin.y += self.frame.origin.y;
            return frame;
        }
        
    } else {
        return CGRectZero;
    }
}

- (CGRect)moreButtonFrame {
    if (self.moreButton) {
        if (self.superview) {
            return [self convertRect:self.moreButton.frame toView:self.superview];
            
        } else {
            // 没superview的情况下手动计算rect
            CGRect frame = self.moreButton.frame;
            frame.origin.x += self.frame.origin.x;
            frame.origin.y += self.frame.origin.y;
            return frame;
        }
        
    } else {
        return CGRectZero;
    }
}

- (CGRect)originMoreButtonFrame {
    return self.moreButton.frame;
}

- (void)setMoreButtonBadgeNum:(NSUInteger)moreButtonBadgeNum
{
    _moreButtonBadgeNum = moreButtonBadgeNum;
    [self.badgeLabel setNum:moreButtonBadgeNum];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)resetToAppropriateFrame {
    // 与初始化逻辑保持一致
    BOOL isHideMoreButton = [[BDPTimorClient sharedClient].currentNativeGlobalConfiguration hideMenu];
    CGSize expectBounds = CGSizeMake(isHideMoreButton ? kBDPToolBarViewWidth / 2.0 : kBDPToolBarViewWidth, kBDPToolBarViewHeight);
    if (!CGSizeEqualToSize(self.frame.size, expectBounds)) {
        self.frame = CGRectMake(0, 0, expectBounds.width, expectBounds.height);
    }
}

- (BOOL)isAppropriateSize {
    BOOL isHideMoreButton = [[BDPTimorClient sharedClient].currentNativeGlobalConfiguration hideMenu];
    CGSize expectBounds = CGSizeMake(isHideMoreButton ? kBDPToolBarViewWidth / 2.0 : kBDPToolBarViewWidth, kBDPToolBarViewHeight);
    return CGSizeEqualToSize(self.frame.size, expectBounds);
}

#pragma mark - ToolBar Style
/*-----------------------------------------------*/
//           ToolBar Style - 工具栏状态
/*-----------------------------------------------*/
- (void)setToolBarStyle:(BDPToolBarViewStyle)style
{
    _toolBarStyle = style;
    UIColor *tintColor = UDOCColor.textTitle;
    if (style == BDPToolBarViewStyleDark) {
        tintColor = [UIColor whiteColor];
    } else if (style == BDPToolBarViewStyleLight) {
        tintColor = [UIColor blackColor];
    }
    _closeButton.tintColor = tintColor;
    _moreButton.tintColor = tintColor;
}

- (void)closeButtonClicked:(id)sender
{
    BDPMonitorWithNameAndCode(@"mp_close_btn_click", GDMonitorCodeLifecycle.gadget_close, self.uniqueID)
    .setPlatform(OPMonitorReportPlatformSlardar|OPMonitorReportPlatformTea)
    .flush();

    [self toobarButtonClickFlush:OPNavigationBarItemMonitorCodeBridge.closeButton];
    
    // 事件托管后，返回事件直接交给业务，流程终止，直接return
    BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
    if (task.takeoverExitEvent) {
        BDPMicroAppJSRuntimeEngine engine = task.context;
        BDPAppContainerController *containerVC = (BDPAppContainerController *)task.containerVC;
        BDPAppPageController *appVC = [containerVC.appController currentAppPage];
        if ([engine respondsToSelector:@selector(bdp_fireEvent:sourceID:data:)]) {
            NSInteger sourceID = appVC.appPage.appPageID;
            [engine bdp_fireEvent:@"onExitMiniProgramListener"
                         sourceID:sourceID
                             data:@{@"scene":@"navibutton"}];
        }
        return;
    }
    
    // 二次确认弹框
    if ([OPSDKFeatureGating enableLeaveComfirm]) {
        if (self.leaveComfirmHandler && [self.leaveComfirmHandler respondsToSelector:@selector(handleLeaveComfirmAction:confirmCallback:)]) {
            __weak typeof(self) weakSelf = self;
            BOOL handled = [self.leaveComfirmHandler handleLeaveComfirmAction:BDPLeaveComfirmActionClose confirmCallback:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf closeApp];
            }];
            if (handled) {
                return;
            }
        }
    }
    // 将埋点和事件分离，方便二次弹框点击'确认'时调用关闭
    [self closeApp];
}

- (void)closeApp {
    // 走新容器的退出逻辑
    if (self.container) {
        [self.container removeTemporaryTab];
        [self.container unmountWithMonitorCode:GDMonitorCode.close_button_dismiss];
    } else {
        // 暂时保留这段旧代码，能够解决问题: 小程序VC退出失败时，但 container 已销毁
        // Trick Code - 暂时通过 NextResponder 兼容加载失败 Task 为 nil 的情况, 重构一起解决
        BDPBaseContainerController * containerVC = (BDPBaseContainerController *)self.nextResponder;
        while (containerVC && ![containerVC isKindOfClass:[BDPBaseContainerController class]]) {
            containerVC = (BDPBaseContainerController *)containerVC.nextResponder;
        }
        if (containerVC && [containerVC isKindOfClass:[BDPBaseContainerController class]]) {
            if ([OPSDKFeatureGating isGadgetContainerRemoveCode:self.uniqueID]) {
            id<BDPBasePluginDelegate> routePlugin = [BDPTimorClient.sharedClient.gadgetUniversalRoutePlugin sharedPlugin];
            /// 检查是否达到了路由的前置条件
            if ([routePlugin conformsToProtocol:@protocol(GadgetUniversalRouteDelegate)] && containerVC.navigationController != nil) {
                id<GadgetUniversalRouteDelegate> routeDelegate = (id<GadgetUniversalRouteDelegate>)routePlugin;
                [routeDelegate popWithViewController:(BDPBaseContainerController *)containerVC animated:YES complete:^(OPError * _Nullable error) {
                    if (error != nil) {
                        BDPLogWarn(@"pop app fail, msg=%@", error.description);
                    } else {
                        BDPLogInfo(@"pop app success");
                    }
                }];
            }
            } else {
            [containerVC dismissSelf:GDMonitorCode.close_button_dismiss];
            }
        }
    }
}


#pragma mark - MorePanel

- (void)fireMenu:(id)sender {
    [self moreBtnClickedToShowNewMenu];
    [self toobarButtonClickFlush:OPNavigationBarItemMonitorCodeBridge.moreButton];
}

- (void)moreBtnClickedToShowNewMenu {

    if (self.uniqueID == nil) {
        NSString * errMSg = @"uniqueID is nil";
        BDPLogWarn(errMSg);
        NSAssert(NO, errMSg);
        return;
    }

    BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
    BDPAppContainerController *containerVC = (BDPAppContainerController *)task.containerVC;

    AppMenuContext * context = [[AppMenuContext alloc] initWithUniqueID:self.uniqueID containerController:containerVC];

    MenuPanelSourceViewModel * sourceView = [[MenuPanelSourceViewModel alloc] initWithSourceView: self.moreButton];

    NSString * parentString = [self containerMoreButtonBadgePathString];
    
    /// 用户反馈小程序menuItem隐藏需求
    BDPCommon *common = BDPCurrentCommon;
    BDPModel *model = common.model;
    NSDictionary *extra_dict = model.extraDict;
    /// 小程序meta中包含的信息为三端的pluginID信息，需要从中间提取iOS对应的pluginID信息
    NSDictionary *disabled_menus_for_all = [extra_dict bdp_dictionaryValueForKey:@"disabled_menus"];
    NSArray* disabled_menus = [disabled_menus_for_all bdp_arrayValueForKey:@"ios"];
    NSMutableArray *new_disabled_menus = @[].mutableCopy;
    [disabled_menus enumerateObjectsUsingBlock: ^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
        if ([obj isKindOfClass:[NSString class]]) {
            [new_disabled_menus addObject:obj];
        }
    }];
    disabled_menus = new_disabled_menus;
    
    id<MenuPanelOperationHandler> handler = [self makeMenuOperationHandler];
    [handler resetItemModelsWith:@[]]; // 在Show之前先清空一下handler可能缓存的数据模型
    [handler updateMenuItemsToBeRemovedWith:disabled_menus];
    [handler makePluginsWith:context];
    /// ⚠️在赋值新的句柄之前，先要置灰旧的菜单按钮，不能直接hide，有可能这个菜单上还present了新的模态视图⚠️
    [self.menuHandler disableCurrentAllItemModelsWith:YES];
    self.menuHandler = handler;
    [handler showFrom:sourceView parentPath:[[MenuBadgePath alloc] initWithPath: parentString] animation:YES complete:nil];

    // 埋点上报
    [BDPTracker event:@"mp_more_btn_click" attributes:nil uniqueID:self.uniqueID];
}

/// 更新菜单的操作句柄，更新将会包含插件和数据模型
/// 此方法必须在主线程调用，否则不会产生更新，触发一些奇怪的问题
- (void)updateMenuHanlderIfNeeded {
    // 当启用菜单插件，而且也启用了提前预加载插件的FG才会继续执行，预计3.48全量之后删除
    if ([EEFeatureGating boolValueForKey:kMenuPluginPrefetchEnableFGKey]) {
        BOOL isHideMoreButton = [[BDPTimorClient sharedClient].currentNativeGlobalConfiguration hideMenu];
        if (isHideMoreButton) {
            BDPLogWarn(@"isHideMoreButton is true when updateMenuHanlderIfNeeded");
            return;
        }
        if (![NSThread isMainThread]) {
            NSString * errMSg = @"updateMenuHanlderIfNeeded must be executed in main thread, but now you aren't in main thread";
            BDPLogWarn(errMSg);
            NSAssert(NO, errMSg);
            return;
        }

        if (self.uniqueID == nil) {
            NSString * errMSg = @"uniqueID is nil";
            BDPLogWarn(errMSg);
            NSAssert(NO, errMSg);
            return;
        }

        BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
        BDPBaseContainerController *containerVC = (BDPBaseContainerController *)task.containerVC;
        AppMenuContext * context = [[AppMenuContext alloc] initWithUniqueID:self.uniqueID containerController:containerVC];

        // 如果还没有菜单操作句柄，则生产一个
        if (self.menuHandler == nil) {
            self.menuHandler = [self makeMenuOperationHandler];
        }
        [self.menuHandler resetItemModelsWith:[[NSArray alloc] init]];
        [self.menuHandler makePluginsWith:context];
    }
}

- (void)moreBtnClicked:(id)sender
{
    BDPMonitorWithName(@"openplatform_click_more_btn_old", self.uniqueID)
            .setPlatform(OPMonitorReportPlatformSlardar)
            .flush();
    NSAssert(NO, @"should not excute this");
    [self moreBtnClickedToShowNewMenu];
}

// 及时禁用菜单面板
- (void)dealloc {
    if (self.menuHandler != nil) {
        /// 当BDPToolBarView销毁时，我们需要将菜单按钮全部禁用
        [self.menuHandler disableCurrentAllItemModelsWith:YES];
        /// 如果菜单没有弹出模态视图，那么我们可以直接让菜单消失
        if (self.menuHandler.presentedViewController == nil) {
            [self.menuHandler hideWithAnimation:NO complete:nil];
        }
        self.menuHandler = nil;
    }
}
#pragma mark - Hit test
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return [super hitTest:point withEvent:event];
}

#pragma mark - notification

- (void)onUpdateMoreButtonBadge:(NSNotification *)notification
{
    BDPUniqueID *uniqueID = [notification.userInfo bdp_objectForKey:kBDPCommonMoreBtnBadgeUpdateUniqueIDKey ofClass:BDPUniqueID.class];
    if ([uniqueID isEqual:self.uniqueID]) {
        NSUInteger num = [notification.userInfo bdp_unsignedIntegerValueForKey:kBDPCommonMoreBtnBadgeUpdateNumKey];
        self.moreButtonBadgeNum = num;
    }
}

#pragma mark - MenuPanelDelegate
- (void)menuPanelHeaderDidChangedWithView:(MenuAdditionView *)view {
    // 这边检查一下'评分'按钮是否需要上报
    NSArray *addtionViewItems = [OPMenuItemModelbridge addtionViewItemCodeList:view];
    self.addtionViewReportItems = [NSMutableArray arrayWithArray:BDPSafeArray(addtionViewItems)];
}

- (void) menuPanelDidHide {
    BDPLogInfo(@"kMenuPluginEnableFGKey is true in menuPanelDidHide")
}

- (void)menuPanelDidShow {
    // 产品埋点
    NSMutableArray *allReportButtonList = [NSMutableArray array];
    [allReportButtonList addObjectsFromArray:BDPSafeArray(self.addtionViewReportItems)];
    [allReportButtonList addObjectsFromArray:BDPSafeArray(self.reportMenuItems)];
    NSString *buttonListString = [allReportButtonList componentsJoinedByString:@","];
    BDPLogInfo(@"menuPanel did show, report current items: %@", buttonListString);
    BDPMonitorWithName(@"openplatform_mp_container_menu_view", self.uniqueID)
        .setPlatform(OPMonitorReportPlatformTea)
        .addCategoryValue(@"button_list", BDPSafeString(buttonListString))
        .addCategoryValue(@"application_id", OPSafeString(self.uniqueID.appID))
        .flush();
}

- (void) menuPanelItemModelsDidChangedWithModels:(NSArray<id<MenuItemModelProtocol>> *)models {
    if ([EEFeatureGating boolValueForKey:kMenuPluginPrefetchEnableFGKey]) {
        // 如果kMenuPluginEnableFGKey打开，那么使用的插件机制，我们需要更新红点
        NSArray<id<MenuItemModelProtocol>> * modelsCopy = [models copy];
        NSUInteger count = modelsCopy.count;
        for (NSUInteger index = 0; index < count; index ++) {
            id<MenuItemModelProtocol> model = modelsCopy[index];
            if ((self.moreButton != nil) && ([self.moreButton isKindOfClass:[ToolBarMoreButton class]])) {
                ToolBarMoreButton * toolBarMoreButton = (ToolBarMoreButton *)self.moreButton;
                [toolBarMoreButton updateBadgeNumberFor: model.itemIdentifier isDisplay:model.badgeNumber > 0];
            }
        }
    } else {
        // 如果kMenuPluginEnableFGKey没打开，那么没使用的插件机制，走的老逻辑,那么我们什么也不用做
        BDPLogInfo(@"kMenuPluginEnableFGKey & kMenuPluginPrefetchEnableFGKey are false in menuPanelItemModelsDidChanged");
    }

    // 产品埋点
    NSMutableArray<NSString *> *tmp = [NSMutableArray array];
    // 这边将各按钮的Code保存
    for (NSObject *item in models) {
        if ([item isKindOfClass:[MenuItemModel class]]) {
            NSString *code = [OPMenuItemModelbridge menuItemCodeString:(MenuItemModel *)item];
            [tmp addObject:BDPSafeString(code)];
        }
    }
    self.reportMenuItems = tmp;
}

#pragma mark - AppMenuPrivacyDelegate
- (void) actionFor:(BDPMorePanelPrivacyType)type {
    if (self.menuHandler == nil) {
        return;
    }
    WeakSelf;
    [self.menuHandler hideWithAnimation:YES complete:^{
        StrongSelfIfNilReturn;
        __weak BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
        __weak BDPBaseContainerController *containerVC = (BDPBaseContainerController *)task.containerVC;
        __weak BDPCommon *appCommon = BDPCommonFromUniqueID(self.uniqueID);
        switch (type) {
            case BDPMorePanelPrivacyTypeMicrophone:
                [containerVC.subNavi pushViewController:[[BDPPermissionController alloc] initWithAuthProvider:appCommon.auth] animated:YES];
                break;
            case BDPMorePanelPrivacyTypeLocation:
                [containerVC.subNavi pushViewController:[[BDPPermissionController alloc] initWithAuthProvider:appCommon.auth] animated:YES];
                break;
            default:
                break;
        }
    }];

}

#pragma mark - AlternateAnimatorDelegate
- (void) animationWillStartFor:(UIView *)view {
    if (self.menuHandler == nil || ![[[UIDevice currentDevice] model] hasPrefix:@"iPad"] || self.compactAdditionView == nil) {
        return;
    }
    MenuAdditionView * additionView = [[MenuAdditionView alloc] initWithCustomView:self.compactAdditionView];
    [self.menuHandler updatePanelFooterFor:additionView];
}

- (void) animationDidEndFor:(UIView *)view {
    if (self.menuHandler == nil || ![[[UIDevice currentDevice] model] hasPrefix:@"iPad"] || self.compactAdditionView == nil) {
        return;
    }
    [self.menuHandler updatePanelFooterFor:nil];
}

- (void) animationDidAddSubViewFor:(UIView *)targetView subview:(UIView *)subview {
    if (self.menuHandler == nil || ![[[UIDevice currentDevice] model] hasPrefix:@"iPad"] || self.compactAdditionView == nil) {
        return;
    }
    [subview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(targetView);
        make.leading.mas_equalTo(targetView);
        make.trailing.mas_lessThanOrEqualTo(targetView);
    }];
    MenuAdditionView * additionView = [[MenuAdditionView alloc] initWithCustomView:self.compactAdditionView];
    [self.menuHandler updatePanelFooterFor:additionView];
}

- (void) animationDidRemoveSubViewFor:(UIView *)targetView subview:(UIView *)subview {
    if (self.menuHandler == nil || ![[[UIDevice currentDevice] model] hasPrefix:@"iPad"] || self.compactAdditionView == nil) {
        return;
    }
    MenuAdditionView * additionView = [[MenuAdditionView alloc] initWithCustomView:self.compactAdditionView];
    [self.menuHandler updatePanelFooterFor:additionView];
}

#pragma mark - leave comfirm
- (void)addLeaveComfirmHandler:(id<BDPNavLeaveComfirmHandler>)handler {
    _leaveComfirmHandler = handler;
}

#pragma mark - private
/// 产品化埋点: 工具栏按钮点击事件上报. '关闭'/'更多'按钮
/// @param buttonId 埋点ID. 产品侧定义的code.见链接
/// https://bytedance.feishu.cn/sheets/shtcncTYngXV6omM6ltYTzccpOD
- (void)toobarButtonClickFlush:(NSString *)buttonId {
    BDPMonitorWithName(@"openplatform_mp_container_click", self.uniqueID)
        .setPlatform(OPMonitorReportPlatformTea)
        .addCategoryValue(@"application_id", BDPSafeString(self.uniqueID.appID))
        .addCategoryValue(@"click", @"button")
        .addCategoryValue(@"target", @"none")
        .addCategoryValue(@"button_id", buttonId)
        .flush();
}
@end

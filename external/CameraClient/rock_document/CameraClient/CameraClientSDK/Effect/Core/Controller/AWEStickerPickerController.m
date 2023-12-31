//
//  AWEStickerPickerController.m
//  CameraClient
//
//  Created by zhangchengtao on 2019/12/16.
//

#import "AWEStickerPickerController.h"
#import "ACCConfigKeyDefines.h"
#import "AWEStickerPickerSearchView.h"
#import "AWEStickerPickerUIConfigurationProtocol.h"
#import "AWEStickerPickerController+LayoutManager.h"
#import "ACCPropExploreExperimentalControl.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>

#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/AWEStickerPickerModel.h>
#import <CameraClient/AWEStickerPickerModel+Favorite.h>
#import <CameraClient/AWEStickerPickerControllerPluginProtocol.h>
#import <CameraClient/AWEStickerPickerLogMarcos.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

#import <Masonry/View+MASAdditions.h>

static const NSTimeInterval kAnimationDuration = 0.25;

static inline BOOL useSearchOptimization() {
    return ACCConfigBool(kConfigBool_studio_optimize_prop_search_experience);
}

@interface AWEStickerPickerController ()
<
AWEStickerPickerModelDelegate,
AWEStickerPickerModelDataSource,
AWEStickerPickerViewDelegate
>

@property (nonatomic, strong, readwrite) UIView *contentView; // 内容视图

@property (nonatomic, strong) UIView *clearView; // 空白区域，点击关闭面板

@property (nonatomic, strong, readwrite) AWEStickerPickerView *panelView; // 面板视图

@property (nonatomic, strong, readwrite) AWEStickerPickerSearchView *searchView; // 搜索面板视图

@property (nonatomic, strong) UIView<AWEStickerPickerEffectOverlayProtocol> *loadingView;

@property (nonatomic, strong) UIView<AWEStickerPickerEffectErrorViewProtocol> *errorView;
@property (nonatomic, strong) UIView *errorViewContainer;

@property (nonatomic, strong, readwrite) AWEStickerPickerModel *model;

@property (nonatomic, assign) CGFloat panelViewHeight; // 面板高度

@property (nonatomic, strong) id<AWEStickerPickerUIConfigurationProtocol> UIConfig;

/// 当前选中的道具位置，section 是分类下标，item 是特效下标
@property (nonatomic, strong) NSIndexPath *selectIndexPath;

@property (nonatomic, assign, readwrite) BOOL isSearchViewKeyboardShown;

@property (nonatomic, assign, readwrite) BOOL isSearchViewShown;


@end

@implementation AWEStickerPickerController

- (instancetype)initWithPanelName:(NSString *)panelName
                         UIConfig:(id<AWEStickerPickerUIConfigurationProtocol>) UIConfig
                   currentSticker:(IESEffectModel * _Nullable)currentSticker
              currentChildSticker:(IESEffectModel * _Nullable)currentChildSticker
                          plugins:(NSArray<id<AWEStickerPickerControllerPluginProtocol>> * _Nullable)plugins
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        NSAssert(UIConfig, @"UIConfig could not be nil !!!");
        self.UIConfig = UIConfig;
        self.panelViewHeight = [self.UIConfig.effectUIConfig effectListViewHeight] + [self.UIConfig.categoryUIConfig categoryTabListViewHeight];
        // 插件
        _plugins = [plugins copy];
        
        // 创建Model
        _model = [[AWEStickerPickerModel alloc] initWithPanelName:panelName currentSticker:currentSticker currentChildSticker:currentChildSticker];
        _model.delegate = self;

        // 搜索面板
        _isSearchViewShown = NO;
        _isSearchViewKeyboardShown = NO;
    }
    return self;
}

- (void)insertPlugin:(id<AWEStickerPickerControllerPluginProtocol>)plugin {
    NSMutableArray * tmpPlugins = [NSMutableArray arrayWithArray:self.plugins];
    [tmpPlugins btd_addObject:plugin];
    _plugins = [tmpPlugins copy];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    [self setupContentView];
    [self setupDismssBgView];
    [self setupPanelView];
    if (self.isOnRecordingPage && [self shouldSupportSearchFeature] != ACCPropPanelSearchEntranceTypeNone) {
        [self setupSearchView];
    }
    [self setupConstraints];
    [self updateConterntViewFrameForShow];
    [self.view layoutIfNeeded];
    
    AWEStickerPickerLogInfo(@"viewDidLoad isLoaded=%d|isLoading=%d", self.model.isLoaded, self.model.isLoading);
    NSAssert((self.model.isLoaded && self.model.isLoading) == NO, @"model load status is invalid!!!");
    // 加载道具列表数据
    if (self.model.isLoaded) {
        [self.panelView updateCategory:self.model.stickerCategoryModels];
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        // 选中默认tab，默认选中非收藏的第一个tab
        [self selectDefaultCategory];
    } else if (self.model.isLoading) {
        // Show loading
        [self showLoadingView];
    } else {
        self.model.stickerCategoryListLoadMode = AWEStickerCategoryListLoadModeNormal;
        [self.model loadStickerCategoryList];
    }
    
    // Notify plugins viewDidLoad.
    for (id<AWEStickerPickerControllerPluginProtocol> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(controllerViewDidLoad:)]) {
            [plugin controllerViewDidLoad:self];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.view.accessibilityViewIsModal = YES;
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.model.isLoaded) {
        // 默认应用热门第1位道具
        [self applyHotCategoryFirstPropIfNeed];
    }
}

- (void)showLoadingView {
    if ([self.UIConfig respondsToSelector:@selector(panelLoadingView)]) {
        self.loadingView = [self.UIConfig panelLoadingView];
    }
    [self.loadingView showOnView:self.panelView];
}

- (void)hideLoadingView {
    [self.loadingView dismiss];
    self.loadingView = nil;
}

- (void)showErrorView {
    if ([self.UIConfig respondsToSelector:@selector(panelErrorView)]) {
        self.errorView = [self.UIConfig panelErrorView];
        self.errorViewContainer = [[UIView alloc] init];
        [self.errorView showOnView:self.errorViewContainer];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onErrorTap)];
        [self.errorViewContainer addGestureRecognizer:tap];
    }
    [self.panelView addSubview:self.errorViewContainer];
    [self.errorViewContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.panelView);
    }];
}

- (void)hideErrorView {
    [self.errorView dismiss];
    self.errorView = nil;
    [self.errorViewContainer removeFromSuperview];
    self.errorViewContainer = nil;
}

- (void)onErrorTap {
    if ([self.errorView respondsToSelector:@selector(effectErrorViewDidClick)]) {
        [self.errorView effectErrorViewDidClick];
    }
    self.model.stickerCategoryListLoadMode = AWEStickerCategoryListLoadModeReload;
    [self loadStickerCategory];
    [self hideErrorView];
}

#pragma mark - Public

- (NSString *)panelName {
    return self.model.panelName;
}

- (IESEffectModel *)currentSticker {
    return self.model.currentSticker;
}

- (void)loadStickerCategory {
    [self.model loadStickerCategoryList];
}

- (void)loadStickerCategoryIfNeeded
{
    [self.model loadStickerCategoryListIfNeeded];
}

- (void)reloadData {
    [self.panelView reloadData];
}

- (void)setCurrentEffect:(IESEffectModel *)effect {
    self.model.currentSticker = effect;
}

- (void)cancelSelect {
    self.model.currentSticker = nil;
}

- (CGFloat)contentHeight {
    CGFloat height = CGRectGetHeight(self.contentView.frame);
    return height;
}

- (NSIndexPath * _Nullable)currentStickerIndexPath {
    return self.selectIndexPath;
}

- (void)showOnView:(UIView *)view animated:(BOOL)animated completion:(void (^)(void))completion {
    if (!view) {
        if (completion) {
            completion();
        }
        return;
    }
    
    // Notify plugins controller will show on view.
    for (id<AWEStickerPickerControllerPluginProtocol> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(controller:willShowOnView:)]) {
            [plugin controller:self willShowOnView:view];
        }
    }
    
    [view addSubview:self.view];
    [self.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(view);
    }];

    if ([self.delegate respondsToSelector:@selector(stickerPickerControllerSendSignalShowRecordButtonAbovePropPanel)]) {
        [self.delegate stickerPickerControllerSendSignalShowRecordButtonAbovePropPanel];
    }

    [self updateConterntViewFrameForDismiss];
    [self.view layoutIfNeeded];
    
    void (^finishHandler)(void) = ^{
        // Notify plugins controller did show on view.
        for (id<AWEStickerPickerControllerPluginProtocol> plugin in self.plugins) {
            if ([plugin respondsToSelector:@selector(controller:didShowOnView:)]) {
                [plugin controller:self didShowOnView:view];
            }
        }

        if (completion) {
            completion();
        }
    };
    
    [self updateConterntViewFrameForShow];

    if (animated) {
        [UIView animateWithDuration:kAnimationDuration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            finishHandler();
        }];
    } else {
        [self.view layoutIfNeeded];
        finishHandler();
    }
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion {    
    // Notifify plugins will dismiss from view.
    UIView *view = self.view.superview;
    for (id<AWEStickerPickerControllerPluginProtocol> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(controller:willDimissFromView:)]) {
            [plugin controller:self willDimissFromView:view];
        }
    }

    void (^finishHandler)(void) = ^{
        [self.view removeFromSuperview];
        if ([self.delegate respondsToSelector:@selector(stickerPickerControllerDidDismiss:)]) {
            [self.delegate stickerPickerControllerDidDismiss:self];
        }
        
        // Notifify plugins did dismiss from view.
        for (id<AWEStickerPickerControllerPluginProtocol> plugin in self.plugins) {
            if ([plugin respondsToSelector:@selector(controller:didDismissFromView:)]) {
                [plugin controller:self didDismissFromView:view];
            }
        }
        
        if (completion) {
            completion();
        }
    };
    [self updateConterntViewFrameForDismiss];
    
    if (animated) {
        NSTimeInterval duration = animated ? kAnimationDuration : 0.f;
        [UIView animateWithDuration:duration animations:^{
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            finishHandler();
        }];
    } else {
        [self.view layoutIfNeeded];
        finishHandler();
    }
}

- (void)setDataSource:(id<AWEStickerPickerControllerDataSource>)dataSource {
    _dataSource = dataSource;
    self.model.dataSource = self;
}

#pragma mark - Private

- (void)setupContentView {
    self.contentView = [[UIView alloc] init];
    [self.view addSubview:self.contentView];
}

- (void)setupDismssBgView {
    // 空白区域关闭面板使用
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClearBackgroundPress:)];
    self.clearView = [[UIView alloc] init];
    [self.clearView addGestureRecognizer:tapRecognizer];

    // 无障碍化设置
    [self.clearView setExclusiveTouch:YES];
    self.clearView.isAccessibilityElement = YES;
    self.clearView.accessibilityLabel = ACCLocalizedCurrentString(@"com_mig_turn_off_effects");
    self.clearView.accessibilityTraits = UIAccessibilityTraitButton;
    [self.contentView addSubview:self.clearView];
}

- (void)setupPanelView {
    // 道具面板容器视图
    self.panelView = [[AWEStickerPickerView alloc] initWithUIConfig:self.UIConfig];
    self.panelView.model = self.model;
    self.panelView.isOnRecordingPage = self.isOnRecordingPage;
    self.panelView.delegate = self;
    self.panelView.favoriteTabIndex = self.favoriteTabIndex;
    self.panelView.layer.mask = [self topRoundCornerShapeLayerWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, [self panelViewHeight])];
    [self.contentView addSubview:self.panelView];
}

- (void)setupSearchView {
    // 搜索面板容器视图
    self.searchView = [[AWEStickerPickerSearchView alloc] initWithIsTab:NO];
    self.searchView.model = self.model;
    self.searchView.hidden = YES;
    self.searchView.backgroundColor = self.UIConfig.effectUIConfig.effectListViewBackgroundColor;
    self.searchView.layer.mask = [self topRoundCornerShapeLayerWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, [self panelViewHeight])];
    [self.searchView updateUIConfig:self.UIConfig];
    [self.contentView addSubview:self.searchView];
}

- (void)setupConstraints {
    [self updateConterntViewFrameForDismiss];
    
    // clear
    [self.clearView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    
    // panel
    [self.panelView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.contentView);
        make.height.mas_equalTo(self.panelViewHeight);
    }];

    if (self.isOnRecordingPage && [self shouldSupportSearchFeature] != ACCPropPanelSearchEntranceTypeNone) {
        // search
        if (useSearchOptimization()) {
            [self.searchView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.contentView);
                make.top.equalTo(self.contentView.mas_top).mas_offset(ACC_SCREEN_HEIGHT - [self panelViewHeight]);
                make.height.mas_equalTo([self panelViewHeight]);
            }];
        } else {
            [self.searchView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.bottom.equalTo(self.contentView);
                make.height.mas_equalTo([self panelViewHeight]);
            }];
        }
    }
}

/// 计算更新 panelContentView 的 frame
- (void)updateConterntViewFrame:(BOOL)show {
    [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.width.height.equalTo(self.view);
        if (show) {
            make.top.equalTo(self.view);
        } else {
            make.top.equalTo(self.view.mas_bottom);
        }
    }];
    //[self.view layoutIfNeeded];
}

- (void)updateConterntViewFrameForShow {
    [self updateConterntViewFrame:YES];
}

- (void)updateConterntViewFrameForDismiss {
    [self updateConterntViewFrame:NO];
}

- (void)onClearBackgroundPress:(UITapGestureRecognizer *)tap {
    if (self.isSearchViewShown) {
        // force textfield to resign as first responder
        [self.searchView onClearBGClicked];
    }

    if ([self.delegate respondsToSelector:@selector(stickerPickerControllerDidTapDismissBackgroundView:)]) {
        [self.delegate stickerPickerControllerDidTapDismissBackgroundView:self];
    }

    if (self.dismissWhenTapInEmpty) {
        [self dismissAnimated:YES completion:nil];
    }
}

- (void)clearStickerApplyButtonClicked:(UIButton *)clearButton {
    IESEffectModel *sticker = self.model.currentSticker;
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:didDeselectSticker:)]) {
        [self.delegate stickerPickerController:self didDeselectSticker:sticker];
    }
    
    if ([self.delegate respondsToSelector:@selector(stickerPickerControllerDidTapClearStickerButton:)]) {
        [self.delegate stickerPickerControllerDidTapClearStickerButton:self];
    }
    
    self.model.currentSticker = nil;
}

/**
 * 选中默认tab，默认选中非收藏的第一个tab
 */
- (void)selectDefaultCategory
{
    
    // 通知插件即将设置defaultCategory
    for (id<AWEStickerPickerControllerPluginProtocol> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(controllerWillSelecteDefaultCategory:)]) {
            [plugin controllerWillSelecteDefaultCategory:self];
        }
    }
    
    if (self.defaultTabSelectedIndex < self.model.stickerCategoryModels.count) {
        self.panelView.defaultSelectedIndex = self.defaultTabSelectedIndex;
    }
}

- (void)applyHotCategoryFirstPropIfNeed
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerControllerShouldApplyFirstHotSticker:)]) {
        if (![self.delegate stickerPickerControllerShouldApplyFirstHotSticker:self]) {
            return;
        }
        
        // 查找热门分类下的第一个道具并应用, 排除游戏道具、带引导的道具
        __block AWEStickerCategoryModel *hotCategoryModel = nil;
        [self.model.stickerCategoryModels enumerateObjectsUsingBlock:^(AWEStickerCategoryModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isHotTab]) {
                hotCategoryModel = obj;
                *stop = YES;
            }
        }];

        IESEffectModel *firstSticker = [hotCategoryModel.stickers btd_find:^BOOL(IESEffectModel * _Nonnull obj) {
            BOOL game = obj.isEffectControlGame;
            BOOL guide = !ACC_isEmptyString([obj.pixaloopSDKExtra acc_stringValueForKey:@"guide_video_path"]);
            return !(game || guide);
        }];

        [self pickerViewDidSelectSticker:firstSticker category:hotCategoryModel isAutoApply:YES];
    }
}

- (CAShapeLayer *)topRoundCornerShapeLayerWithFrame:(CGRect)frame
{
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    CGFloat maskRadius = 8;
    shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:frame
                                            byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                  cornerRadii:CGSizeMake(maskRadius, maskRadius)].CGPath;
    return shapeLayer;
}

#pragma mark - AWEStickerPickerModelDelegate

- (BOOL)stickerPickerModel:(AWEStickerPickerModel *)model shouldApplySticker:(IESEffectModel *)sticker
{
    // 检查是否允许选中指定道具。
    // Check if should select sticker.
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:shouldSelectSticker:)]) {
        if (![self.delegate stickerPickerController:self shouldSelectSticker:sticker]) {
            return NO;
        }
    }
    
    return YES;
}

// 道具分类加载开始
- (void)stickerPickerModelDidBeginLoadCategories:(AWEStickerPickerModel *)model {
    // 通知插件道具开始分类数据加载
    for (id<AWEStickerPickerControllerPluginProtocol> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(controllerDidBeginLoadCategories:)]) {
            [plugin controllerDidBeginLoadCategories:self];
        }
    }
    
    // Notify delegate that begin load categories.
    if ([self.delegate respondsToSelector:@selector(stickerPickerControllerDidBeginLoadCategories:)]) {
        [self.delegate stickerPickerControllerDidBeginLoadCategories:self];
    }
    
    if ([self isViewLoaded]) {
        // Dismiss Error
        [self hideErrorView];
        
        // Show loading
        [self showLoadingView];
    }
}

// 道具分类加载成功
- (void)stickerPickerModelDidFinishLoadCategories:(AWEStickerPickerModel *)model {
    // 通知插件道具分类数据加载成功
    for (id<AWEStickerPickerControllerPluginProtocol> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(controllerDidFinishLoadStickerCategories:)]) {
            [plugin controllerDidFinishLoadStickerCategories:self];
        }
    }
    
    // Notify delegate that categories were load success.
    if ([self.delegate respondsToSelector:@selector(stickerPickerControllerDidFinishLoadCategories:)]) {
        [self.delegate stickerPickerControllerDidFinishLoadCategories:self];
    }
    
    if ([self isViewLoaded]) {
        // Dismiss Loading
        [self hideLoadingView];
        
        [self.panelView updateCategory:self.model.stickerCategoryModels];
        
        // 选中默认tab，默认选中非收藏的第一个tab
        [self selectDefaultCategory];
        // 默认应用热门第1位道具
        [self applyHotCategoryFirstPropIfNeed];
    }
}

// 道具分类加载失败
- (void)stickerPickerModelDidFailLoadCategories:(AWEStickerPickerModel *)model withError:(NSError *)error {
    if (error) {
        AWEStickerPickerLogError(@"sticker picker model load category failed, panel=%@|error=%@", self.panelName, error);
    }
    
    // 通知插件道具分类数据加载失败
    for (id<AWEStickerPickerControllerPluginProtocol> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(controller:didFailLoadStickerCategoriesWithError:)]) {
            [plugin controller:self didFailLoadStickerCategoriesWithError:error];
        }
    }
    
    // Notify delegate that categories were load failed.
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:didFailLoadCategoriesWithError:)]) {
        [self.delegate stickerPickerController:self didFailLoadCategoriesWithError:error];
    }
    
    if ([self isViewLoaded]) {
        // Dismiss Loading
        [self hideLoadingView];
        
        // Show Error
        [self showErrorView];
    }
}

- (void)stickerPickerModelDidSelectNewSticker:(IESEffectModel *)newSticker oldSticker:(IESEffectModel *)oldSticker {
    // Update Cell selection status
    [self.panelView updateSelectedStickerForId:newSticker.effectIdentifier];

    // Update the selection status of SearchView and SearchTab
    if (self.isOnRecordingPage && [self shouldSupportSearchFeature] != ACCPropPanelSearchEntranceTypeNone) {
        [self.searchView updateSelectedStickerForId:newSticker.effectIdentifier];
        [self.panelView.searchTab.searchView updateSelectedStickerForId:newSticker.effectIdentifier];
    }
        
    // Notify plugins
    [self.plugins enumerateObjectsUsingBlock:^(id<AWEStickerPickerControllerPluginProtocol>  _Nonnull plugin, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([plugin respondsToSelector:@selector(controller:didSelectNewSticker:oldSticker:)]) {
            [plugin controller:self didSelectNewSticker:newSticker oldSticker:oldSticker];
        }
    }];
    
    // 可下载道具（非聚合道具）才回调 delegate
    BOOL isDownloadableSticker = newSticker.fileDownloadURLs.count > 0 && newSticker.fileDownloadURI.length > 0;
    if (isDownloadableSticker) {
        if ([self.delegate respondsToSelector:@selector(stickerPickerController:didSelectSticker:)]) {
            [self.delegate stickerPickerController:self didSelectSticker:newSticker];
        }
    }

    if ([self shouldShowSubviews]) {
        [self updateSubviewsAlpha:1];
    } else {
        [self updateSubviewsAlpha:0];
    }
    if (newSticker == nil) {
        self.selectIndexPath = nil;
    }
}

- (void)stickerPickerModelDidUpdateSticker:(IESEffectModel *)sticker favoriteStatus:(BOOL)selected error:(NSError *)error {
    if (error) {
        AWEStickerPickerLogError(@"sticker picker model update failed, selected=%d|error=%@", selected, error);
    }
    // 添加新的收藏，`收藏` tab 需要进行动画
    if (selected && !error) {
        // 只有当前显示`收藏` tab 的情况下才去执行动画
        __block NSIndexPath *favoriteTabIndexPath = nil;
        [self.model.stickerCategoryModels enumerateObjectsUsingBlock:^(AWEStickerCategoryModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.favorite) {
                favoriteTabIndexPath = [NSIndexPath indexPathForItem:idx inSection:0];
                *stop = YES;
            }
        }];
        if (favoriteTabIndexPath) {
            [self.panelView executeFavoriteAnimationForIndex:favoriteTabIndexPath];
        }
    }
}

// 点击道具列表项
- (void)pickerViewDidSelectSticker:(IESEffectModel *)sticker
                          category:(AWEStickerCategoryModel *)category
                       isAutoApply:(BOOL)isAutoApply
{
    if (!sticker) {
        return;
    }
    
    // 记录点击的道具
    self.model.stickerWillSelect = sticker;
    
    // 反选道具
    // Deselect the sticker.
    if ([self.model.currentSticker.effectIdentifier isEqualToString:sticker.effectIdentifier]) {
        if ([self.delegate respondsToSelector:@selector(stickerPickerController:didDeselectSticker:)]) {
            [self.delegate stickerPickerController:self didDeselectSticker:sticker];
        }
        self.model.currentSticker = nil;
        self.selectIndexPath = nil;
        return;
    }

    BOOL isDownloadableSticker = sticker.fileDownloadURLs.count > 0 && sticker.fileDownloadURI.length > 0;
    BOOL willDownload = isDownloadableSticker && !sticker.downloaded;

    NSMutableDictionary *additionalParams = [NSMutableDictionary dictionary];
    if (category.isSearch) {
        additionalParams[@"search_id"] = self.model.searchID;
        additionalParams[@"search_method"] = self.model.searchMethod;
        additionalParams[@"is_panel_unfold"] = self.searchView.textField.isFirstResponder ? @(1) : @(0);
    }
    if (isAutoApply) {
        additionalParams[@"is_auto"] = @(1);
    }
    
    // 即将选中指定道具
    // Call delegate will select sticker.
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:willSelectSticker:willDownload:additionalParams:)]) {
        [self.delegate stickerPickerController:self willSelectSticker:sticker willDownload:willDownload additionalParams:additionalParams];
    }
    
    // 如果是可下载道具，走下载逻辑。
    // Download the sticker if it is downloadable.
    if (isDownloadableSticker) {
        // 判断是否强绑定音乐道具，如果是强绑定音乐道具，强制每次都去拉取音乐
        if (sticker.downloaded && ![sticker acc_isForceBindingMusic]) {
            // 如果道具已下载直接选中
            // Set currentSticker if downloaded.
            self.model.currentSticker = sticker;
            [self.model updateDownloadedCell:sticker];
        } else {
            // 如果道具未下载，记录要选中的道具并触发下载
            [self.model downloadStickerIfNeed:sticker];
        }
    } else {
        // 不可下载的道具（聚合道具等）直接选中
        self.model.currentSticker = sticker;
    }
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model didBeginDownloadSticker:(IESEffectModel *)sticker {
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:didBeginDownloadSticker:)]) {
        [self.delegate stickerPickerController:self didBeginDownloadSticker:sticker];
    }
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model didFinishDownloadSticker:(IESEffectModel *)sticker {
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:didFinishDownloadSticker:)]) {
        [self.delegate stickerPickerController:self didFinishDownloadSticker:sticker];
    }

    if (self.isSearchViewKeyboardShown) {
        [self.searchView triggerKeyboardToHide];
    }
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model didFailDownloadSticker:(IESEffectModel *)sticker withError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:didFailDownloadSticker:withError:)]) {
        [self.delegate stickerPickerController:self didFailDownloadSticker:sticker withError:error];
    }
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
didBeginLoadStickersWithCategory:(AWEStickerCategoryModel *)categoryModel
                  tabIndex:(NSInteger)tabIndex {
    AWEStickerPickerLogDebug(@"didBeginLoadStickersWithCategory|categoryName=%@|tabIndex=%zi", categoryModel.categoryName, tabIndex);
    [self.panelView updateLoadingWithTabIndex:tabIndex];
    
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:didBeginLoadStickersWithCategory:)]) {
        [self.delegate stickerPickerController:self didBeginLoadStickersWithCategory:categoryModel];
    }
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
didFinishLoadStickersWithCategory:(AWEStickerCategoryModel *)categoryModel
                  tabIndex:(NSInteger)tabIndex {
    AWEStickerPickerLogDebug(@"didFinishLoadStickersWithCategory|categoryName=%@|tabIndex=%zi", categoryModel.categoryName, tabIndex);
    [self.panelView updateFetchFinishWithTabIndex:tabIndex];
    
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:didFinishLoadStickersWithCategory:)]) {
        [self.delegate stickerPickerController:self didFinishLoadStickersWithCategory:categoryModel];
    }
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
didFailLoadStickersWithCategory:(AWEStickerCategoryModel *)categoryModel
                  tabIndex:(NSInteger)tabIndex
                     error:(NSError *)error {
    AWEStickerPickerLogError(@"didFailLoadStickersWithCategory|categoryName=%@|tabIndex=%zi|error=%@", categoryModel.categoryName, tabIndex, error);
    [self.panelView updateFetchErrorWithTabIndex:tabIndex];
    
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:didFailLoadStickersWithCategory:error:)]) {
        [self.delegate stickerPickerController:self
               didFailLoadStickersWithCategory:categoryModel
                                         error:error];
    }
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
didUpdateStickersWithCategory:(AWEStickerCategoryModel *)categoryModel
                  tabIndex:(NSInteger)tabIndex {
    AWEStickerPickerLogDebug(@"didUpdateStickersWithCategory|categoryName=%@|tabIndex=%zi", categoryModel.categoryName, tabIndex);
    [self.panelView reloadData];
}

#pragma mark - Search

- (void)stickerPickerModel:(AWEStickerPickerModel *)model trackWithEventName:(NSString *)eventName params:(NSMutableDictionary *)params
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:trackWithEventName:params:)]) {
        [self.delegate stickerPickerController:self trackWithEventName:eventName params:params];
    }
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model didTapHashtag:(NSString *)hashtag
{
    [self.searchView updateSearchText:hashtag];
    [self.searchView.textField sendActionsForControlEvents:UIControlEventEditingChanged];
}

- (void)stickerPickerModelSendSearchCategoryModel:(AWEStickerPickerModel *)model
{
    // this is a realtime data fetching from API, only update the categoryModel in searchView
    [self.searchView updateCategoryModel:self.model.searchCategoryModel isUseHot:self.model.isUseHot];
    [self.panelView.searchTab.searchView updateCategoryModel:self.model.searchCategoryModel isUseHot:self.model.isUseHot];
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model triggerKeyboardToShow:(BOOL)shown
{
    if (!self.isSearchViewKeyboardShown && self.isViewLoaded && self.view.superview) {//只有多列道具面板在显示中且当前textfield不是焦点时才触发，避免后续横滑面板入口弹起多列面板时默认触发键盘弹起
        [self prepareShowSearchViewAnimation];
        [self.searchView textFieldBecomeFirstResponder];
    }

    [self.searchView updateSearchSource:self.model.source];
    [self.searchView updateSearchText:self.model.searchText];
    [self.searchView updateCategoryModel:self.model.searchCategoryModel isUseHot:self.model.isUseHot];

    [self.panelView.searchTab.searchView updateSearchSource:self.model.source];
    [self.panelView.searchTab.searchView updateSearchText:self.model.searchText];
    [self.panelView.searchTab.searchView updateCategoryModel:self.model.searchCategoryModel isUseHot:self.model.isUseHot];
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model showKeyboardWithNotification:(NSNotification *)notification
{
    self.isSearchViewShown = YES;
    self.isSearchViewKeyboardShown = YES;

    [self.searchView enableCollectionViewToScroll:NO];
    [self showSearchViewWithNotification:notification];
    [self.searchView trackRecommendedListDidShow];
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model triggerKeyboardToHide:(BOOL)hidden
{
    [self.searchView updateSearchSource:self.model.source];
    [self.panelView.searchTab.searchView updateSearchSource:self.model.source];
    
    [self.searchView textFieldResignFirstResponder];

    [self.searchView updateSearchText:self.model.searchText];
    [self.searchView updateCategoryModel:self.model.searchCategoryModel isUseHot:self.model.isUseHot];

    [self.panelView.searchTab.searchView updateSearchText:self.model.searchText];
    [self.panelView.searchTab.searchView updateCategoryModel:self.model.searchCategoryModel isUseHot:self.model.isUseHot];
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model hideKeyboardWithNotification:(NSNotification *)notification source:(AWEStickerPickerSearchViewHideKeyboardSource)source
{
    if (source == AWEStickerPickerSearchViewHideKeyboardSourceScroll) {
        self.isSearchViewKeyboardShown = NO;
        return;
    }
    
    [self.searchView enableCollectionViewToScroll:YES];
    [self.panelView.searchTab.searchView enableCollectionViewToScroll:YES];
    [self.panelView.searchTab.searchView trackRecommendedListDidShow];

    if (self.isOnRecordingPage && [self shouldSupportSearchFeature] == ACCPropPanelSearchEntranceTypeTab) {
        self.isSearchViewShown = YES;
        self.isSearchViewKeyboardShown = NO;
        [self hideSearchViewWithNotification:notification];
    } else {
        if (source == AWEStickerPickerSearchViewHideKeyboardSourceCancel) {
            self.isSearchViewShown = NO;
            [self hideSearchViewWithNotification:notification];
            self.isSearchViewKeyboardShown = NO;
        } else {
            self.isSearchViewShown = YES;
            self.isSearchViewKeyboardShown = NO;
            [self remainOnSearchViewWithNotification:notification];

        }
    }
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model willDisplaySticker:(IESEffectModel *)sticker indexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:willDisplaySticker:atIndexPath:additionalParams:)]) {
        NSMutableDictionary *additionalParams = [NSMutableDictionary dictionary];
        if (self.isSearchViewShown) {
            additionalParams[@"search_id"] = self.model.searchID;
            additionalParams[@"search_method"] = self.model.searchMethod;
            additionalParams[@"is_panel_unfold"] = self.searchView.textField.isFirstResponder ? @(1) : @(0);
        }

        [self.delegate stickerPickerController:self willDisplaySticker:sticker atIndexPath:indexPath additionalParams:additionalParams];
    }
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
          didSelectSticker:(IESEffectModel *)sticker
                  category:(AWEStickerCategoryModel *)category
                 indexPath:(NSIndexPath *)indexPath
{
    self.selectIndexPath = indexPath;
    [self pickerViewDidSelectSticker:sticker category:category isAutoApply:NO];
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model willDisplayLoadingView:(BOOL)show
{
    [self.searchView showLoadingView:show];
    [self.panelView.searchTab.searchView showLoadingView:show];
}

- (void)stickerPickerModelUpdateSearchViewToPackUp:(AWEStickerPickerModel *)model
{
    [self hideSearchViewWithNotification:nil];
}

#pragma mark - Search View Animation Handlers

- (void)prepareShowSearchViewAnimation
{
    // initial state
    [self.searchView updateSubviewsAlpha:0];
    self.searchView.hidden = NO;

    self.searchView.backgroundColor = self.UIConfig.effectUIConfig.effectListViewBackgroundColor;

    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[self fadeOutTimingFunction]];
    [UIView animateWithDuration:0.02 delay:0 options:UIViewAnimationOptionTransitionNone animations:^{
        [self updateSubviewsAlpha:0];
    } completion:nil];
    [CATransaction commit];
}

- (CGFloat)panelHeightIfKeyboardIsShown
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat itemHeight = screenWidth * 71.5 / 375.0f;
    CGFloat insetHeight = (screenWidth - itemHeight * 5) / 2.0f;

    if ([UIDevice acc_isIPad]) {
        itemHeight = 414.0f * 71.5 / 375.0f;
        insetHeight = (414.0f - itemHeight * 5) / 2.0f;
    }

    if (useSearchOptimization()) {
        itemHeight = itemHeight * 1.5;
    }
    
    return insetHeight + itemHeight + 14.0; // 14.0 is for prop name label height
}

- (void)showSearchViewWithNotification:(NSNotification *)notification
{
    if (!notification) {
        return;
    }
    if (useSearchOptimization()) {
        [self p_optimizeShowSearchViewWithNotification:notification];
        return;
    }

    
    CGRect keyboardBounds;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    NSTimeInterval duration = [[notification.userInfo  acc_objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[notification.userInfo acc_objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];

    [CATransaction begin];
    if (useSearchOptimization()) {
        CGFloat optimizeHeight = keyboardBounds.size.height + 64 + [self panelHeightIfKeyboardIsShown];

        [self.searchView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(optimizeHeight);
        }];
        self.searchView.layer.mask = [self topRoundCornerShapeLayerWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, optimizeHeight)];
        [self.searchView layoutIfNeeded];
        
        [UIView animateWithDuration:duration delay:0 options:(curve << 16) animations:^{
            self.contentView.transform = CGAffineTransformMakeTranslation(0, [self panelViewHeight] - (keyboardBounds.size.height + 64 + [self panelHeightIfKeyboardIsShown]));
            [self refreshExploreViewLayout];
        } completion:nil];
    } else {
        [UIView animateWithDuration:duration delay:0 options:(curve << 16) animations:^{
            self.contentView.transform = CGAffineTransformMakeTranslation(0, [self panelViewHeight] - (keyboardBounds.size.height + 64 + [self panelHeightIfKeyboardIsShown]));
            [self refreshExploreViewLayout];
        } completion:nil];
    }
    
    [UIView animateKeyframesWithDuration:duration delay:0 options:0 animations:^{
        /**
         1. Fade Out
         */
        [CATransaction begin];
        [CATransaction setAnimationTimingFunction:[self fadeOutTimingFunction]];
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:(0.09 / duration) animations:^{
            [self.panelView updateSubviewsAlpha:0];
        }];
        [CATransaction commit];

        /**
         2. Fade In
         */
        [CATransaction begin];
        [CATransaction setAnimationTimingFunction:[self fadeInTimingFunction]];
        [UIView addKeyframeWithRelativeStartTime:(0.09 / duration) relativeDuration:(0.21 / duration) animations:^{
            [self.searchView updateSubviewsAlpha:1];
        }];
        [CATransaction commit];
    } completion:nil];

    [CATransaction commit];
}

- (void)p_optimizeShowSearchViewWithNotification:(NSNotification *)notification
{
    CGRect keyboardBounds;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    UIViewAnimationCurve curve = [[notification.userInfo acc_objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    [CATransaction begin];
    [UIView animateKeyframesWithDuration:0 delay:0 options:0 animations:^{
        /**
         Fade Out && Fade In
         */
        [self.panelView updateSubviewsAlpha:0];
        [self.searchView updateSubviewsAlpha:1];
    } completion:nil];
    [CATransaction commit];
    
    CGFloat optimizeHeight = keyboardBounds.size.height + 64 + [self panelHeightIfKeyboardIsShown];
    /**
     expand search view
     */
    [self.searchView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(optimizeHeight);
        make.top.equalTo(self.contentView.mas_top).mas_offset(ACC_SCREEN_HEIGHT - (keyboardBounds.size.height + 64 + [self panelHeightIfKeyboardIsShown]));
    }];
    self.searchView.layer.mask = [self topRoundCornerShapeLayerWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, optimizeHeight)];
    
    [UIView animateWithDuration:0.25 delay:0 options:(curve << 16) animations:^{
        [self.contentView layoutIfNeeded];
        [self refreshExploreViewLayout];
    } completion:nil];
}

- (void)hideSearchViewWithNotification:(NSNotification * _Nullable)notification
{
    if (useSearchOptimization()) {
        [self p_optimizeHideSearchViewWithNotification:notification];
        return;
    }
    
    NSTimeInterval duration = 0.25;
    UIViewAnimationCurve curve = UIViewAnimationCurveEaseInOut;

    if (notification) {
        duration = [[notification.userInfo  acc_objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        curve = [[notification.userInfo acc_objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    }

    // initial state
    [self.searchView updateSubviewsAlpha:1];
    self.searchView.hidden = NO;

    [CATransaction begin];
    
    [UIView animateWithDuration:duration delay:0 options:(curve << 16) animations:^{
        self.contentView.transform = CGAffineTransformIdentity;
    } completion:nil];

    [UIView animateKeyframesWithDuration:duration delay:0 options:0 animations:^{
        /**
         1. Fade Out
         */
        [CATransaction begin];
        [CATransaction setAnimationTimingFunction:[self fadeOutTimingFunction]];
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:(0.09 / duration) animations:^{
            [self.searchView updateSubviewsAlpha:0];
            [self refreshExploreViewLayout];
        }];
        [CATransaction commit];

        /**
         2. Fade In
         */
        [CATransaction begin];
        [CATransaction setAnimationTimingFunction:[self fadeInTimingFunction]];
        [UIView addKeyframeWithRelativeStartTime:(0.09 / duration) relativeDuration:(0.21 / duration) animations:^{
            [self.panelView updateSubviewsAlpha:1];
            self.searchView.backgroundColor = [UIColor clearColor];
        }];
        [CATransaction commit];

        [CATransaction begin];
        if ([self shouldShowSubviews]) {
            if (self.isOnRecordingPage && [self shouldSupportSearchFeature] == ACCPropPanelSearchEntranceTypeTab) {
                [CATransaction setAnimationTimingFunction:[self fadeInTimingFunction]];
                [UIView addKeyframeWithRelativeStartTime:(0.09 / duration) relativeDuration:(0.21 / duration) animations:^{
                    [self updateSubviewsAlpha:1];
                }];
            } else {
                [self updateFavoriteButtonLeftConstraint:NO];
                if (self.isSearchViewKeyboardShown) {
                    // from high to low
                    [CATransaction begin];
                    [CATransaction setDisableActions:YES];
                    [self.view layoutIfNeeded];
                    [CATransaction commit];

                    [CATransaction setAnimationTimingFunction:[self fadeInTimingFunction]];
                    [UIView addKeyframeWithRelativeStartTime:(0.09 / duration) relativeDuration:(0.21 / duration) animations:^{
                        [self updateSubviewsAlpha:1];
                    }];
                } else {
                    // from low to low
                    [CATransaction begin];
                    [CATransaction setAnimationTimingFunction:[self fadeInTimingFunction]];
                    [UIView addKeyframeWithRelativeStartTime:(0.09 / duration) relativeDuration:(0.21 / duration) animations:^{
                        [self updateSubviewsAlpha:1];
                    }];
                    [CATransaction commit];

                    [CATransaction begin];
                    [CATransaction setAnimationTimingFunction:[[CAMediaTimingFunction alloc] initWithControlPoints:0.46 :0.0 :0.18 :1.0]];
                    [UIView addKeyframeWithRelativeStartTime:(0.09 / duration) relativeDuration:(0.21 / duration) animations:^{
                        [self.view layoutIfNeeded];
                    }];
                    [CATransaction commit];
                }
            }
        }

        [CATransaction commit];

    } completion:^(BOOL finished) {
        self.searchView.hidden = YES;
    }];

    [CATransaction commit];
}

- (void)p_optimizeHideSearchViewWithNotification:(NSNotification * _Nullable)notification
{
    NSTimeInterval duration = 0.25;
    UIViewAnimationCurve curve = UIViewAnimationCurveEaseInOut;

    if (notification) {
        duration = [[notification.userInfo  acc_objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        curve = [[notification.userInfo acc_objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    }

    /**
     pack up search view
     */
    [self.searchView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).mas_offset(ACC_SCREEN_HEIGHT - [self panelViewHeight]);
        make.height.mas_equalTo([self panelViewHeight]);
    }];
    
    [UIView animateWithDuration:0.25 delay:0 options:(curve << 16) animations:^{
        [self.contentView layoutIfNeeded];
        [self refreshExploreViewLayout];
    } completion:^(BOOL finished) {
        [CATransaction begin];
        [UIView animateKeyframesWithDuration:0 delay:0 options:0 animations:^{
            /**
             Fade Out && Fade In6
             */
            [self.searchView updateSubviewsAlpha:0];
            [self.panelView updateSubviewsAlpha:1];
            self.searchView.backgroundColor = [UIColor clearColor];

            if ([self shouldShowSubviews]) {
                if (self.isOnRecordingPage && [self shouldSupportSearchFeature] == ACCPropPanelSearchEntranceTypeTab) {
                    [self updateSubviewsAlpha:1];
                } else {
                    [self updateFavoriteButtonLeftConstraint:NO];
                    if (self.isSearchViewKeyboardShown) {
                        // from high to low
                        [self.view layoutIfNeeded];
                        [self updateSubviewsAlpha:1];
                    } else {
                        // from low to low
                        [self updateSubviewsAlpha:1];
                        [self.view layoutIfNeeded];
                    }
                }
            }

        } completion:^(BOOL finished) {
            self.searchView.hidden = YES;
        }];

        [CATransaction commit];
    }];
}

- (void)remainOnSearchViewWithNotification:(NSNotification * _Nullable)notification
{
    NSTimeInterval duration = 0.25;
    UIViewAnimationCurve curve = UIViewAnimationCurveEaseInOut;

    if (notification) {
        duration = [[notification.userInfo  acc_objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        curve = [[notification.userInfo acc_objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    }

    // initial state
    self.searchView.backgroundColor = self.UIConfig.effectUIConfig.effectListViewBackgroundColor;
    [self.searchView updateSubviewsAlpha:1];
    self.searchView.hidden = NO;

    [CATransaction begin];
    [UIView animateWithDuration:duration delay:0 options:(curve << 16) animations:^{
        self.contentView.transform = CGAffineTransformIdentity;
    } completion:nil];

    [UIView animateKeyframesWithDuration:duration delay:0 options:0 animations:^{
        /**
         1. Fade Out
         */
        [CATransaction begin];
        [CATransaction setAnimationTimingFunction:[self fadeOutTimingFunction]];
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:(0.09 / duration) animations:^{
            [self.searchView updateSubviewsAlpha:0];
        }];
        [CATransaction commit];

        /**
         2. Fade In
         */
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self updateFavoriteButtonLeftConstraint:YES];
        [self.view layoutIfNeeded];
        [CATransaction commit];

        [CATransaction begin];
        [CATransaction setAnimationTimingFunction:[self fadeInTimingFunction]];
        [UIView addKeyframeWithRelativeStartTime:(0.09 / duration) relativeDuration:(0.21 / duration) animations:^{
            [self.searchView updateSubviewsAlpha:1];
            if ([self shouldShowSubviews]) {
                [self updateSubviewsAlpha:1];
            }
        }];
        [CATransaction commit];
    } completion:nil];

    [CATransaction commit];
}

#pragma mark - AWEStickerPickerModelDataSource
- (NSArray<AWEDouyinStickerCategoryModel *> *)categoryArray
{
    return self.dataSource.categoryArray;
}

- (AWEStickerCategoryModel *)favoriteCategoryModel
{
    return self.dataSource.favoriteCategoryModel;
}

- (BOOL)categoryListIsLoading
{
    return self.dataSource.categoryListIsLoading;
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
fetchCategoryListForPanelName:(NSString *)panelName
         completionHandler:(void (^)(NSArray<AWEStickerCategoryModel* > * _Nullable categoryList, NSArray<NSString *> * _Nullable urlPrefix, NSError * _Nullable error))completionHandler {
    [self.dataSource stickerPickerController:self fetchCategoryListForPanelName:panelName completionHandler:completionHandler];
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
fetchEffectListForPanelName:(NSString *)panelName
               categoryKey:(NSString *)categoryKey
         completionHandler:(void (^)(NSArray<IESEffectModel* > * _Nullable effectList, NSError * _Nullable error))completionHandler {
    [self.dataSource stickerPickerController:self fetchEffectListForPanelName:panelName categoryKey:categoryKey completionHandler:completionHandler];
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
 fetchFavoriteForPanelName:(NSString *)panelName
         completionHandler:(void (^)(NSArray<IESEffectModel *> * _Nullable effectList, NSError * _Nullable error))completionHandler {
    [self.dataSource stickerPickerController:self fetchFavoriteForPanelName:panelName completionHandler:completionHandler];
}

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
changeFavoriteWithEffectIDs:(NSArray<NSString *> *)effectIDS
                 panelName:(NSString *)panelName
                  favorite:(BOOL)favorite
         completionHandler:(void (^)(NSError * _Nullable error))completionHandler {
    if ([self.dataSource respondsToSelector:@selector(stickerPickerController:changeFavoriteWithEffectIDs:panelName:favorite:completionHandler:)]) {
        [self.dataSource stickerPickerController:self changeFavoriteWithEffectIDs:effectIDS panelName:panelName favorite:favorite completionHandler:completionHandler];
    } else {
        NSAssert(NO, @"dataSource has not implement method!!");
        NSError *error = [NSError errorWithDomain:@"com.aweme.cameraclient.sticker" code:-1 userInfo:@{
            NSLocalizedFailureReasonErrorKey: @"dataSource has not implement method",
        }];
        completionHandler(error);
    }
}


#pragma mark - AWEStickerPickerViewDelegate

- (void)stickerPickerView:(AWEStickerPickerView *)stickerPickerView didSelectTabIndex:(NSInteger)index {
    AWEStickerCategoryModel *category = [self.model.stickerCategoryModels objectAtIndex:index];
    self.model.currentCategoryModel = category;

    self.isSearchViewShown = NO;
    if (self.isOnRecordingPage && [self shouldSupportSearchFeature] == ACCPropPanelSearchEntranceTypeTab) {
        if (category.isSearch) {
            self.isSearchViewShown = YES;
        }
    }

    if ([self shouldShowSubviews]) {
        [self updateSubviewsAlpha:1];
    } else {
        [self updateSubviewsAlpha:0];
    }
    
    // 通知插件即将设置defaultCategory
    for (id<AWEStickerPickerControllerPluginProtocol> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(controller:didSelectCategory:)]) {
            [plugin controller:self didSelectCategory:category];
        }
    }

    if ([self.delegate respondsToSelector:@selector(stickerPickerController:didSelectCategory:)]) {
        [self.delegate stickerPickerController:self didSelectCategory:category];
    }
}

- (BOOL)stickerPickerView:(AWEStickerPickerView *)stickerPickerView isStickerSelected:(IESEffectModel *)sticker {
    return [self.model.currentSticker.effectIdentifier isEqualToString:sticker.effectIdentifier];
}

- (void)stickerPickerView:(AWEStickerPickerView *)stickerPickerView
         didSelectSticker:(IESEffectModel *)sticker
                 category:(AWEStickerCategoryModel *)category
                indexPath:(NSIndexPath *)indexPath {
    self.selectIndexPath = indexPath;
    [self pickerViewDidSelectSticker:sticker category:category isAutoApply:NO];
}

- (void)stickerPickerViewDidClearSticker:(AWEStickerPickerView *)stickerPickerView {
    IESEffectModel *sticker = self.model.currentSticker;
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:didDeselectSticker:)]) {
        [self.delegate stickerPickerController:self didDeselectSticker:sticker];
    }
    
    if ([self.delegate respondsToSelector:@selector(stickerPickerControllerDidTapClearStickerButton:)]) {
        [self.delegate stickerPickerControllerDidTapClearStickerButton:self];
    }
    
    self.selectIndexPath = nil;
    self.model.currentSticker = nil;
}

- (void)stickerPickerView:(AWEStickerPickerView *)stickerPickerView
       willDisplaySticker:(IESEffectModel *)sticker
                indexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:willDisplaySticker:atIndexPath:additionalParams:)]) {
        NSMutableDictionary *additionalParams = [NSMutableDictionary dictionary];
        if (self.isSearchViewShown) {
            additionalParams[@"search_id"] = self.model.searchID;
            additionalParams[@"search_method"] = self.model.searchMethod;
            additionalParams[@"is_panel_unfold"] = self.searchView.textField.isFirstResponder ? @(1) : @(0);
        }

        [self.delegate stickerPickerController:self willDisplaySticker:sticker atIndexPath:indexPath additionalParams:additionalParams];
    }
}

- (void)stickerPickerView:(AWEStickerPickerView *)stickerPickerView finishScrollingTopBottom:(BOOL)finished
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:finishScrollingTopBottom:)]) {
        [self.delegate stickerPickerController:self finishScrollingTopBottom:finished];
    }
}

- (void)stickerPickerView:(AWEStickerPickerView *)stickerPickerView finishScrollingLeftRight:(BOOL)finished
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerController:finishScrollingLeftRight:)]) {
        [self.delegate stickerPickerController:self finishScrollingLeftRight:finished];
    }
}

#pragma mark - AB Experiments

- (ACCPropPanelSearchEntranceType)shouldSupportSearchFeature
{
    if ([[ACCPropExploreExperimentalControl sharedInstance] hiddenSearchEntry])  {
        return ACCPropPanelSearchEntranceTypeNone;
    }
    return ACCConfigEnum(kConfigInt_new_search_effect_config, ACCPropPanelSearchEntranceType);
}

@end

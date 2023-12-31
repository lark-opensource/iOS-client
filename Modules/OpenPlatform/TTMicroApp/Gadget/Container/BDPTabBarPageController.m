//
//  BDPTabBarPageController.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/27.
//

#import "BDPTabBarPageController.h"
#import "BDPTask.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPSDKConfig.h>
#import "BDPTaskManager.h"
#import "BDPTabBarConfig.h"
#import <OPFoundation/BDPCommonManager.h>
#import "BDPXScreenManager.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPModuleManager.h>
#import "BDPAppPageController.h"
#import "BDPNavigationController.h"
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPResponderHelper.h>
#import <OPFoundation/BDPBundle.h>
#import <BDWebImage/BDWebImage.h>

#import <OPFoundation/UIView+BDPBorders.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/UIImage+BDPExtension.h>
#import <OPFoundation/UIColor+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import "UITabBar+BDPBadgeView.h"
#import <OPFoundation/UITabBarItem+BDPExtension.h>
#import <OPFoundation/EEFeatureGating.h>

#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

static const NSInteger kTitleLengthMax = 6;
static NSString *const kTabBarBlackColor = @"#E6E6E6";
static NSString *const kTabBarStyleWhite = @"white";
static const CGFloat kTabBarBorderWidth = .5f;
NSString *const BDPTabBarImageSizeString = @"{32,32}";
static CGFloat const kTabBarItemFontSize = 10;
static CGFloat const kTabBarHeight = 56;

@interface BDPTabBarPageController ()

@property (nonatomic, strong) BDPUniqueID *uniqueID;
@property (nonatomic, strong) BDPAppPageURL *page;
@property (nonatomic, strong) BDPTabBarConfig *tabBarConfig;

@property (nonatomic, assign) NSInteger lastClickedIndex;
@property (nonatomic, assign) CGFloat tabbarVisibleHeight;
@property (nonatomic, assign) CGFloat tabbarInvisibleHeight;

@property (nonatomic, assign) BOOL isAppeared;
@property (nonatomic, assign) BOOL isTabBarVisible;
@property (nonatomic, assign) BOOL isTabBarDoubleClick;

// 以下确保都在主线程即可不上锁
@property (nonatomic, assign) NSInteger configImageCount;                               // 要加载的config中的image总数
@property (nonatomic, assign) NSInteger loadedConfigImageCount;                         // 已加载的config中的image数量
@property (nonatomic, assign, readonly) BOOL didLoadAllConfigImages;                    // 是否已加载完所有config要加载的image
@property (nonatomic, strong) NSMutableArray<dispatch_block_t> *setTabBarImageActions;  // 若config image还没有设置完, 就调用了setTabImage api, 则先保存到这里

@property (nonatomic, weak, nullable) OPContainerContext *containerContext;

@property (nonatomic, assign) BOOL hasSetTabBarBorderStyleByAPI;

@property (nonatomic, assign) BOOL needSkipFirstSelect; //是否要跳过setSelectedIndex方法,Tab VC 设置controllers时默认选中第一个Tab，默认会触发setSelectedIndex一次

@property (nonatomic, assign) BOOL tabbar_relaunch_fix_disable;

@end

@implementation BDPTabBarPageController

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID
                            page:(BDPAppPageURL *)page
                        delegate:(id<UITabBarControllerDelegate>)delegate
                containerContext:(OPContainerContext *)containerContext
{
    self = [self init];
    if (self) {
        self.containerContext = containerContext;
        _page = page;
        _uniqueID = uniqueID;
        _needSkipFirstSelect = NO;
        _tabbar_relaunch_fix_disable = [EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetTabBarRelaunchFixDisable];

        self.delegate = delegate;
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
        _tabBarConfig = task.config.tabBar;

        [self setupTabBar];
        [self setupTabBarSelectIndex];
        
        /// 当tabBar初始化完成时，发送事件onTabBarReady，携带数据tab_bar_ready = 2
        NSDictionary *params = @{@"tab_bar_ready": @(TabBarStatusTypeReady)};
        [task.context bdp_fireEventV2:@"onTabBarReady" data:params];
    }
    return self;
}

- (void)setupTabBar
{
    if (self.uniqueID.isAppSupportDarkMode) {
        [self.view setBackgroundColor:UDOCColor.bgBase];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
    }
    
    WeakSelf;
    [self.view opSetDynamicWithHandler:^(UITraitCollection * _Nonnull traitCollection) {
        StrongSelfIfNilReturn;
        if (self.hasSetTabBarBorderStyleByAPI) {
            return;
        }
        [self setTabBarBorderStyle:self.tabBarConfig.themeBorderStyle borderColor:nil];
    }];
    self.tabBar.barTintColor = self.tabBarConfig.themeBackgroundColor;
    self.tabBar.backgroundColor = self.tabBarConfig.themeBackgroundColor;
    self.tabBar.backgroundImage = [[UIImage alloc] init];
    self.tabBar.shadowImage = [[UIImage alloc] init];
    self.tabBar.translucent = NO;
    
    NSMutableArray *subControllers = [[NSMutableArray alloc] initWithCapacity:self.tabBarConfig.list.count];
    self.configImageCount = self.tabBarConfig.list.count * 2; // tabItem normal+selected, 如果未来还有其他状态，对应修改下
    
    dispatch_block_t executeSetTabBarImageActionBlk = ^{
        StrongSelfIfNilReturn;
        if (self.didLoadAllConfigImages && self->_setTabBarImageActions.count) {
            for (dispatch_block_t action in self->_setTabBarImageActions) {
                action();
            }
            self->_setTabBarImageActions = nil;
        }
    };
    
    for (BDPTabBarPageConfig *pageConfig in self.tabBarConfig.list) {
        //2019-4-3 修复tabPage不能获取query参数问题
        NSString *pagePath = pageConfig.pagePath;
        if (self.page != nil && [pagePath isEqualToString:self.page.path]) {
            pagePath = self.page.absoluteString;
        }
        // Controller
        BDPAppPageController *controller = [[BDPAppPageController alloc] initWithUniqueID:self.uniqueID pageURL:pagePath containerContext:self.containerContext];
        BDPNavigationController *nav = [[BDPNavigationController alloc] initWithRootViewController:controller barBackgroundHidden:YES containerContext:self.containerContext];
        [nav useCustomAnimation];
        
        NSString *title = [pageConfig.text bdp_subStringForMaxWordLength:kTitleLengthMax withBreak:YES];
        UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:nil selectedImage:nil];
        __weak typeof(tabBarItem) weakBarItem = tabBarItem;
        [self loadImageWithPath:pageConfig.iconPath inOrder:NO completion:^(UIImage *image) {
            StrongSelfIfNilReturn;
            self.loadedConfigImageCount++;
            typeof(weakBarItem) barItem = weakBarItem;
            if (!barItem) { return; }
            barItem.image = image;
            executeSetTabBarImageActionBlk();
        }];
        [self loadImageWithPath:pageConfig.selectedIconPath inOrder:NO completion:^(UIImage *image) {
            StrongSelfIfNilReturn;
            self.loadedConfigImageCount++;
            typeof(weakBarItem) barItem = weakBarItem;
            if (!barItem) { return; }
            barItem.selectedImage = image;
            executeSetTabBarImageActionBlk();
        }];
        [self applyTabBarTitleStyleForItem:tabBarItem];
        // Tab标题为空时，将图标垂直居中展示
        if (BDPIsEmptyString(title)) {
            tabBarItem.imageInsets = UIEdgeInsetsMake(6.f, 0, -6.f, 0);
        }
        
        nav.tabBarItem = tabBarItem;
        [subControllers addObject:nav];
    }

    // self.viewControllers 会触发setSelectedIndex：0，与预期的defaultSelectIndex不一致
    // 不一致时会导致第0个VC对应的viewDidLoad 提前触发，导致一些列view提前创建，TTi时间变长；
    // 判断当前是否有默认选中Tab，如果有就并且FG为YES，就跳过第一次setSelectedIndex中的setTabBarVisible方法
    NSInteger defaultSelectIndex = [self defaultTabBarSelectIndex];
    if (defaultSelectIndex != NSNotFound && OPSDKFeatureGating.enableOptimizeSelectNotFirstTab) {
        self.needSkipFirstSelect = YES;
    }
    self.viewControllers = subControllers;
    // 重置，后续正常执行setSelectedIndex方法
    self.needSkipFirstSelect = NO;
    self.isTabBarVisible = YES;
    
    [self updateTabbarItemsStyle];
}

- (NSInteger)defaultTabBarSelectIndex {
    if (!self.uniqueID || !self.page) {
        return NSNotFound;
    }

    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    NSInteger index = [task.config tabBarIndexOfPath:self.page.path];
    return index;
}

- (void)setupTabBarSelectIndex
{
    NSInteger index = [self defaultTabBarSelectIndex];
    if (index != NSNotFound) {
        self.selectedIndex = index;
    }
}

- (CGFloat)tabBarItemFontSize {
    CGFloat fontSize = kTabBarItemFontSize;
    return fontSize;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.uniqueID.isAppSupportDarkMode) {
        [self.view setBackgroundColor:UDOCColor.bgBase];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
    }
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    // 这里之所以要把对最上面vc重新push一遍，是因为tabbarVC 重新present的时候，会把tabbar 显示出来。
    // 这里添加到 super 前，不会影响正常的VC生命周期。
    // 调研发现 ios 系统也是这么干的。。。
    BDPNavigationController *navi = (BDPNavigationController *)self.selectedViewController;
    if ([navi isKindOfClass:[BDPNavigationController class]] && navi.viewControllers.count > 1) {
        UIViewController *lastPage = [navi.viewControllers lastObject];
        if(OPSDKFeatureGating.enableTabPopPushIfNeed) {
            // 只有tabbar 显示出来时才需要进行pop 和push 操作
            if(!self.tabBar.isHidden) {
                [navi origin_popViewControllerAnimated:NO];
                [navi origin_pushViewController:lastPage animated:NO];
            }
        } else {
            [navi origin_popViewControllerAnimated:NO];
            [navi origin_pushViewController:lastPage animated:NO];
        }
    }
    
    [super viewWillAppear:animated];
    // TabBarController使用VC独立的Nav，因此将TabBarController自带的导航栏隐藏
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    if ([BDPXScreenManager isXScreenMode:self.uniqueID]) {
        self.view.backgroundColor = [UIColor clearColor];
    } else {
        if (self.uniqueID.isAppSupportDarkMode) {
            [self.view setBackgroundColor:UDOCColor.bgBase];
        } else {
            [self.view setBackgroundColor:[UIColor whiteColor]];
        }
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.isAppeared) {
        self.isAppeared = YES;

        // 旧逻辑下的变量，新逻辑下没有意义
        self.tabbarVisibleHeight = self.view.bdp_height;
        self.tabbarInvisibleHeight = self.view.bdp_height + self.tabBar.bdp_height;
    }
    [self setTabBarVisible:self.isTabBarVisible animated:NO completion:nil];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    // 产品需求：定制 Tabbar 高度 https://bytedance.feishu.cn/docs/doccnngyCl2PTKdmePT9ALwA7Nb?appid=2#caPvX0
    if (![BDPDeviceHelper isPadDevice]) {
        CGFloat tabBarHeight = [BDPResponderHelper safeAreaInsets:self.view.window].bottom + kTabBarHeight;
        CGRect tabBarFrame = self.tabBar.frame;

        // 刷新页面的时候tabbar根据visible状态改变位置
        CGFloat tabBarY = self.isTabBarVisible ? self.view.bounds.size.height - tabBarHeight : self.view.bounds.size.height;

        self.tabBar.frame = CGRectMake(tabBarFrame.origin.x, tabBarY, tabBarFrame.size.width, tabBarHeight);
    }
    
    [self updateTabbarItemsStyle];
    
    if (self.isAppeared) {
        if (self.selectedIndex<self.viewControllers.count) {

            // 此处持有的view变成nav vc栈中的root vc的view
            UIView *view = [self naviRootView];
            view.bdp_height = self.view.bdp_height;

            if (!self.isTabBarVisible) {
                self.tabBar.hidden = YES;
            }
            
        } else {
            //print error information here if selected index is illegal, to get rid of crash
            BDPLogError(@"selectedIndex is illegal, %d", self.selectedIndex)
        }
    }
}

/// 输入appPageController，获取此page中所含有的tabBarPageController，如果不存在则输出nil
+ (nullable BDPTabBarPageController *)getTabBarVCForAppPageController:(BDPAppPageController *)appPageController {
    BDPAppPageController *pageVC = appPageController;
    BDPTabBarPageController *tabBarController;
    // 判断当前VC是否是导航控制器（Navi）的第一个VC；如果不是，则不可能有tabBar
    if (pageVC.navigationController.viewControllers.firstObject != pageVC && pageVC.hidesBottomBarWhenPushed) {
        return nil;
    }
    if ([pageVC.navigationController.tabBarController isKindOfClass:[BDPTabBarPageController class]]) {
        tabBarController = (BDPTabBarPageController *)pageVC.navigationController.tabBarController;
        return tabBarController;
    } else {
        for (UIViewController *vc in [pageVC.navigationController.viewControllers reverseObjectEnumerator]) {
            if ([vc isKindOfClass:[BDPTabBarPageController class]]) {
                tabBarController = (BDPTabBarPageController *)vc;
                break;
            }
            return tabBarController;
        }
    }
    return nil;
}

+ (TabBarStatus)getTabBarVCStatusWithTask:(nullable BDPTask *)task forPagePath:(nullable NSString *)pagePath {
    TabBarStatus status = TabBarStatusTypeNoTabBar;
    if (task == nil || pagePath == nil) {
        return status;
    }
    BDPAppPageController *appPageController = [task.pageManager appPageWithPath:pagePath].parentController;
    BDPTabBarPageController *tabBarVC = [BDPTabBarPageController getTabBarVCForAppPageController:appPageController];
    if (tabBarVC) {
        status = TabBarStatusTypeReady;
    } else if (task.config.tabBar) {
        status = TabBarStatusTypeNotReady;
    }
    return status;
}

// 向navigation controller中push的view的大小都需要和nav vc的view对齐
// 所以在修改view大小的时候，应该修改nav vc中root vc的view
- (UIView *)naviRootView {
    NSUInteger index = self.selectedIndex;
    /*
        飞书小程序tab item应该在2到5个之间，
        详情见https://open.feishu.cn/document/uYjL24iN/uEDNuEDNuEDN#6321fcb9
     */
    if (index < 0 || index >= self.viewControllers.count) {
        BDPLogError(@"selectedIndex is out of bounds");
        return self.viewControllers[0].view;
    }

    UIViewController *vc = self.viewControllers[index];
    if ([vc isKindOfClass:UINavigationController.class]) {
        return ((UINavigationController *)vc).viewControllers.firstObject.view;
    }

    return vc.view;
}

- (void)loadImageWithPath:(NSString *)imagePath inOrder:(BOOL)inOrder completion:(void (^)(UIImage *image))completion
{
    WeakSelf;
    if (!imagePath.length && completion) {
        completion(nil);
        return;
    }
    /// 增加获取cdn图片作为image的方法，同时兼容原有的本地路径图片读取
    /// isNetworkFile-判断路径是否为cdn链接的flag
    BOOL isNetworkFile = [imagePath hasPrefix:@"http://"] || [imagePath hasPrefix:@"https://"];
    
    /// cdn链接的处理
    if (isNetworkFile) {
        NSURL *imageURL = [[NSURL alloc] initWithString:imagePath];
        /// bugfix:修复小程序tabBar在小程序relaunch之后失效的问题，FG开启走原逻辑进行止血
        if (self.tabbar_relaunch_fix_disable) {
            /// 先加载默认图片
            UIImage *originImage = [self getDefaultImageWithName:@"icon_tab_default"];
            completion(originImage);
        }
        /// 异步请求cdn图片
        BDWebImageRequest *request = [[BDWebImageRequest alloc] initWithURL:imageURL];
        [BDWebImageManager.sharedManager requestImage:imageURL options:request.option complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            UIImage *result = [[image scaledToSize:CGSizeFromString(BDPTabBarImageSizeString)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            completion(result);
        }];
        return;
    }
    
    /// 非cdn链接的处理方式
    /// 标准化文件操作收敛
    OPFileSystemContext *context = [[OPFileSystemContext alloc] initWithUniqueId:self.uniqueID trace:nil tag:@"setTabBarItem"];
    OPFileObject *fileObj = [[OPFileObject alloc] initWithRawValue:imagePath];
    if (!fileObj) {
        context.trace.error(@"resolve OPFileObject failed, imagePath: %@", imagePath);
        completion(nil);
        return;
    }

    /// 异步读取，读取包内文件时如果流式包还没下载完，需要等待锁，此时不能 block 主线程。
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSData *data = [OPFileSystem readFile:fileObj context:context error:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (!data || error) {
                context.trace.error(@"read file data failed, hasData: %@, error: %@", @(data != nil), error.description);
                completion(nil);
                return;
            }

            UIImage *originImage = [UIImage imageWithData:data];
            if (!originImage) {
                context.trace.error(@"construct image failed, dataLength: %@", @(data.length));
                completion(nil);
                return;
            }
            UIImage *image = [[originImage scaledToSize:CGSizeFromString(BDPTabBarImageSizeString)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            completion(image);
        });
    });
}

- (void)removeTabBarItem:(NSString * _Nullable)pagePath completion:(void (^)(BOOL success, NSString * message, int callBackCode))completion
{
    NSUInteger selectedIndex = self.selectedIndex;
    NSString * selectedPagePath = nil;
    
    if (self.tabBarConfig.list.count>2) {
        if (selectedIndex < self.self.tabBarConfig.list.count) {
            BDPTabBarPageConfig * selectedPageConfig = self.tabBarConfig.list[selectedIndex];
            selectedPagePath = [selectedPageConfig isKindOfClass:[BDPTabBarPageConfig class]] ? selectedPageConfig.pagePath : nil;
        } else {
            //log selected Index is invalid
            BDPLogInfo(@"[BDP-JSAPI-removeTabBarItem]: selected Index is invalid");
            completion(NO, @"selected index is invalid", AddTabBarItemAPICodeIndexToAddItemIsInvalid);
        }
        
        // API迁移变更：这里使用 BDPSafeString() 的方法应该是误用，修正为 !BDPIsEmptyString()
        if (!BDPIsEmptyString(pagePath)) {
            if ([pagePath isEqualToString:selectedPagePath]) {
                //log here, pagePage is using, can't be removed
                BDPLogInfo(@"[BDP-JSAPI-removeTabBarItem]: pagePage is using, can't be removed");
                completion(NO, @"can not remove the current tab",AddTabBarItemAPICodeDeleteSelectingPage);
            } else {
                NSMutableArray<BDPTabBarPageConfig *> *listToKeep = @[].mutableCopy;
                __block NSUInteger indexToRemove = NSNotFound;
                [self.tabBarConfig.list enumerateObjectsUsingBlock:^(BDPTabBarPageConfig * _Nonnull config, NSUInteger idx, BOOL * _Nonnull stop) {
                    //
                    if([pagePath isEqualToString:config.pagePath]){
                        indexToRemove = idx;
                    } else {
                        [listToKeep addObject:config];
                    }
                }];
                
                if(![EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetTabBarRemoveFixDisable]) {
                    if(indexToRemove == NSNotFound) { // 尝试删除了一个不存在的tab
                        completion(NO, @"target tab not found", AddTabBarItemAPICodeDeleteNotFoundPage);
                        return;
                    }
                }
                
                self.tabBarConfig.list = listToKeep;
                NSMutableArray * viewControllersToKeep = @[].mutableCopy;
                [self.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (idx==indexToRemove) {
                        
                    } else {
                        [viewControllersToKeep addObject:obj];
                    }
                }];
                self.viewControllers = viewControllersToKeep;
                completion(YES, nil, OPGeneralAPICodeOk);
            }
        }else{
            //pagePath is invalid
            BDPLogInfo(@"[BDP-JSAPI-removeTabBarItem]: pagePath is invalid");
            completion(NO, @"page path is invalid", AddTabBarItemAPICodeGetNilPagePath);
        }
    } else {
        //log tabbar count less than 2, can't be remove
        BDPLogInfo(@"[BDP-JSAPI-removeTabBarItem]: tabbar count less than 2, can't be remove");
        completion(NO, @"at least 2 tabs should be remained", AddTabBarItemAPICodeLeast2TabsNeed);
    }
}

- (void)addTabBarItem:(NSInteger)index pagePath:(NSString * _Nullable)pagePath text:(NSString * _Nullable)text dark:(NSDictionary * _Nullable)dark light:(NSDictionary * _Nullable)light completion:(void (^)(BOOL success, NSString * message, int callBackCode))completion {
    
    NSString *lightIconPath = [light bdp_stringValueForKey:@"iconPath"];
    if (BDPIsEmptyString(lightIconPath)) {
        completion(NO, @"no page lightIcon iconPath", AddTabBarItemAPICodeGetNilLightIconPath);
        return;
    }
    NSString *lightSelectedIconPath = [light bdp_stringValueForKey:@"selectedIconPath"];
    if (BDPIsEmptyString(lightSelectedIconPath)) {
        completion(NO, @"no page lightIcon selectedIconPath", AddTabBarItemAPICodeGetNilLightSelectedIconPath);
        return;
    }
    NSString *darkIconPath = [dark bdp_stringValueForKey:@"iconPath"];
    if (self.uniqueID.isAppSupportDarkMode && BDPIsEmptyString(darkIconPath)) {
        completion(NO, @"no page darkIcon iconPath", AddTabBarItemAPICodeGetNilDarkIconPath);
        return;
    }
    NSString *darkSelectedIconPath = [dark bdp_stringValueForKey:@"selectedIconPath"];
    if (self.uniqueID.isAppSupportDarkMode && BDPIsEmptyString(darkSelectedIconPath)) {
        completion(NO, @"no page darkIcon selectedIconPath", AddTabBarItemAPICodeGetNilTabDarkSelectedIconPath);
        return;
    }
    int preCountOfTabBarItem = (int)self.tabBarConfig.list.count;
    if (preCountOfTabBarItem >= 5) {
        completion(NO, @"at most 5 tabs should be remained", AddTabBarItemAPICodeAtMost5TabsCanBeAdded);
        return;
    }
    if (index < 0 || index > preCountOfTabBarItem) {
        completion(NO, @"index is invalid", AddTabBarItemAPICodeIndexToAddItemIsInvalid);
        return;
    }
    for (BDPTabBarPageConfig *config in self.tabBarConfig.list) {
        if ([pagePath isEqualToString:config.pagePath]) {
            completion(NO, @"this tab already exists", AddTabBarItemAPICodePagePathAlreadyExists);
            return;
        }
    }
    
    BDPTabBarPageConfig *lightConfig = [[BDPTabBarPageConfig alloc] init];
    lightConfig.iconPath = lightIconPath;
    lightConfig.selectedIconPath = lightSelectedIconPath;
    lightConfig.pagePath = pagePath;
    BDPTabBarPageConfig *darkConfig = [[BDPTabBarPageConfig alloc] init];
    darkConfig.iconPath = darkIconPath;
    darkConfig.selectedIconPath = darkSelectedIconPath;
    darkConfig.pagePath = pagePath;
    
    NSMutableArray<BDPTabBarPageConfig *> *newConfigList = @[].mutableCopy;
    BDPTabBarPageConfig *newTabBarPageConfig = [[BDPTabBarPageConfig alloc] init];
    newTabBarPageConfig.pagePath = pagePath;
    if (self.uniqueID.isAppDarkMode) {
        newTabBarPageConfig.iconPath = darkIconPath;
        newTabBarPageConfig.selectedIconPath = darkSelectedIconPath;
    } else {
        newTabBarPageConfig.iconPath = lightIconPath;
        newTabBarPageConfig.selectedIconPath = lightSelectedIconPath;
    }
    // tabBarConfig进行darkmode适配
    [newTabBarPageConfig bindThemeConfigWithDark:darkConfig light:lightConfig];
    newTabBarPageConfig.text = text;
    [self.tabBarConfig.list enumerateObjectsUsingBlock:^(BDPTabBarPageConfig * _Nonnull config, NSUInteger idx, BOOL * _Nonnull stop) {
        if(idx == index){
            [newConfigList addObject:newTabBarPageConfig];
            [newConfigList addObject:config];
        } else {
            [newConfigList addObject:config];
        }
    }];
    // 如果添加的位置在list.count，即末尾的位置
    if (index == preCountOfTabBarItem) {
        [newConfigList addObject:newTabBarPageConfig];
    }
    self.tabBarConfig.list = newConfigList;
    
    BDPAppPageController *newcontroller = [[BDPAppPageController alloc] initWithUniqueID:self.uniqueID pageURL:pagePath containerContext:self.containerContext];
    BDPNavigationController *nav = [[BDPNavigationController alloc] initWithRootViewController:newcontroller barBackgroundHidden:YES containerContext:self.containerContext];
    [nav useCustomAnimation];
    UITabBarItem *newItem = [[UITabBarItem alloc] init];
    [nav setTabBarItem:newItem];

    NSMutableArray * newControllers = @[].mutableCopy;
    [self.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull controller, NSUInteger idx, BOOL * _Nonnull stop) {
        if(idx == index){
            [newControllers addObject:nav];
            [newControllers addObject:controller];
        } else {
            [newControllers addObject:controller];
        }
    }];
    if (index == preCountOfTabBarItem) {
        [newControllers addObject:nav];
    }
    self.viewControllers = newControllers;
    
    /// 使用该API添加的tabBarItem在setTabBarItem中不会置位hasSetSelectedImageByAPI和hasSetImageByAPI两条属性
    /// 因为该API适配了darkmode，所以需要在darkMode切换时使用configTheme配置
    newItem.bdp_itemAddedByAPI = YES;
    
    [self setTabBarItem:index text:text iconPath:newTabBarPageConfig.iconPath selectedIconPath:newTabBarPageConfig.selectedIconPath completion:(void (^)(BOOL))^{}];
    /// iOS中使用setTabBarItem这个API当text为nil或者为""时tabbarItem会下沉6px
    /// 为了使本需求中三端统一，这里重置imageInsets
    newItem.imageInsets = UIEdgeInsetsZero;
    [self applyTabBarTitleStyleForItem:newItem];
    completion(YES, nil, OPGeneralAPICodeOk);
}

- (void)applyTabBarTitleStyleForItem:(UITabBarItem *)item {
    // Title & SelectedTitle
    UIColor *color;
    UIColor *selectedColor;
    color = self.tabBarConfig.themeColor;
    selectedColor = self.tabBarConfig.themeSelectedColor;
    CGFloat fontSize = [self tabBarItemFontSize];
    NSDictionary *titleAttributes = @{NSForegroundColorAttributeName:color, NSFontAttributeName: [UIFont systemFontOfSize:fontSize]};
    NSDictionary *selectedTitleAttributes = @{NSForegroundColorAttributeName:selectedColor, NSFontAttributeName: [UIFont systemFontOfSize:fontSize]};
    [item setTitleTextAttributes:titleAttributes forState:UIControlStateNormal];
    [item setTitleTextAttributes:selectedTitleAttributes forState:UIControlStateSelected];
}

#pragma mark - StatusBar
/*------------------------------------------*/
//            StatusBar - 状态栏
/*------------------------------------------*/
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.selectedViewController preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden
{
    return [self.selectedViewController prefersStatusBarHidden];
}

#pragma mark - Orientation
/*------------------------------------------*/
//          Orientation - 屏幕旋转
/*------------------------------------------*/
- (BOOL)shouldAutorotate
{
    return [self.selectedViewController shouldAutorotate];;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.selectedViewController supportedInterfaceOrientations];
}

#pragma mark - TabBar API

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    self.isTabBarDoubleClick = false;

    NSInteger selectedIndex = [self.tabBar.items indexOfObject:item];
    UIViewController *vc = self.viewControllers[selectedIndex];
    if (!vc || ![vc isKindOfClass:[BDPNavigationController class]]) {
        return;
    }
    
    BDPAppPageController *controller = ((BDPNavigationController *)vc).viewControllers.lastObject;
    if (!controller || ![controller isKindOfClass:[BDPAppPageController class]]) {
        return;
    }

    // 双击
    if ([self checkIsDoubleClick:selectedIndex]) {
        [self fireTabBarTapEvent:@"onTabbarDoubleTap" vc:controller];
        self.isTabBarDoubleClick = true;
        return;
    }

    // 单击
    if (selectedIndex == self.selectedIndex) {
        WeakSelf;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            StrongSelfIfNilReturn;
            if(self.isTabBarDoubleClick) {
                return;
            }
            [self fireTabBarTapEvent:@"onTabItemTap" vc:controller];
        });
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    super.selectedIndex = selectedIndex;
    self.lastClickedIndex = selectedIndex;
    if (!_needSkipFirstSelect) {
        [self setTabBarVisible:self.isTabBarVisible animated:NO completion:nil];
    }
}

- (void)fireTabBarTapEvent:(NSString *)eventName vc:(BDPAppPageController *)viewController
{
    NSString *path = viewController.appPage.bap_path;
    NSString *indexStr = [NSString stringWithFormat:@"%lu", (unsigned long)self.selectedIndex];
    NSString *tabItemTitle = self.tabBar.items[self.selectedIndex].title ?: @"";
    
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    [task.context bdp_fireEvent:eventName
                       sourceID:NSNotFound
                       data:@{@"pagePath": path ?: @"",
                              @"index":indexStr,
                              @"text":tabItemTitle}];
}

/**
 处理UITabBarController双击事件，满足的条件：
 - 当前index已选中
 - 双击当前已选中的tabbar
 - 双击时间间隔小于0.3s

 @param index 当前的index
 @return 是否双击了当前tabBarItem
 */
- (BOOL)checkIsDoubleClick:(NSInteger)index
{
    static NSTimeInterval lastClickTime = 0;

    if (self.lastClickedIndex != index) {
        self.lastClickedIndex = index;
        return NO;
    }

    NSTimeInterval clickTime = [NSDate timeIntervalSinceReferenceDate];
    if (clickTime - lastClickTime > 0.3) {
        lastClickTime = clickTime;
        return NO;
    }

    lastClickTime = clickTime;
    return YES;
}

/// 设置TabBar的Item
/// @param index tabBar的index
/// @param text tabBar的text
/// @param iconPath tabBar的iconPath
/// @param selectedIconPath tabBar的selectedIconPath
/// @param completion
- (void)setTabBarItem:(NSInteger)index text:(NSString *)text iconPath:(NSString *)iconPath selectedIconPath:(NSString *)selectedIconPath completion:(nonnull void (^)(BOOL))completion
{
    WeakSelf;
    dispatch_block_t action = ^{
        StrongSelfIfNilReturn;
        if (index >= self.tabBar.items.count) {
            if (completion) {
                BDPLogError(@"tabBar index %d out of itemsNum %d", index, self.tabBar.items.count)
                completion(NO);
            }
            return;
        }
        UITabBarItem *item = self.tabBar.items[index];
        /// setTabBarItem始终显示icon，可隐藏text
        /// text为空或者不传是不处理；传空格或多个空格是置空
        if (!BDPIsEmptyString(text)) {
            if (BDPIsEmptyString([text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]])) {
                item.title = nil;
                item.imageInsets = UIEdgeInsetsMake(6.f, 0, -6.f, 0);
            } else {
                item.title = text;
                item.imageInsets = UIEdgeInsetsZero;
                [self updateTabbarItemsStyle];
            }
            [self.tabBar updateBadgePositionOnItemIndex:index];
        }
        
        __weak typeof(item) weakItem = item;
        
        /// bugfix:修复tabBar在小程序relaunch之后失效的问题，默认走新逻辑，setTabBarItem时再加载默认图片，FG打开止血
        if (!self.tabbar_relaunch_fix_disable) {
            UIImage *originImage = [self getDefaultImageWithName:@"icon_tab_default"];
            /// 如果当前item不存在icon，则先加载默认图片
            if (!item.image) {
                item.image = originImage;
            }
            if (!item.selectedImage) {
                item.selectedImage = originImage;
            }
        }
        
        [self loadImageWithPath:iconPath inOrder:YES completion:^(UIImage *image) {
            __strong typeof(weakItem) item = weakItem;
            if (image) {
                if (!item.bdp_itemAddedByAPI) {
                    /// 这里的置位是为了防止configTheme失效，在darkmode切换时image被重置
                    item.bdp_hasSetImageByAPI = YES;
                }
                item.image = image;
            } else if (self.tabbar_relaunch_fix_disable) {
                /// bugfix:修复tabBar在小程序relaunch之后失效的问题，FG开关打开后走原逻辑止血 - 如果tabBarItem已经存在了image，那么不去设置默认图片
                if (!item.image) {
                    item.image = [self getDefaultImageWithName:@"icon_tab_default"];
                }
            }
        }];
        
        [self loadImageWithPath:selectedIconPath inOrder:YES completion:^(UIImage *image) {
            __strong typeof(weakItem) item = weakItem;
            if (image) {
                if (!item.bdp_itemAddedByAPI) {
                    item.bdp_hasSetSelectedImageByAPI = YES;
                }
                item.selectedImage = image;
            } else if (self.tabbar_relaunch_fix_disable) {
                /// bugfix:修复tabBar在小程序relaunch之后失效的问题，FG开关打开后走原逻辑止血 - 如果tabBarItem已经存在了image，那么不去设置默认图片
                if (!item.selectedImage) {
                    item.selectedImage = [self getDefaultImageWithName:@"icon_tab_selected_default"];
                }
            }
        }];
        if (completion) {
            completion(YES);
        }
    };
    
    if (!self.didLoadAllConfigImages) { // 如果config中的image设置还没有执行完, 则先存起来
        [self.setTabBarImageActions addObject:action];
    } else {
        action();
    }
}

- (void)setTabBarStyle:(NSString * _Nullable)textColor textSelectedColor:(NSString * _Nullable)textSelectedColor backgroundColor:(NSString * _Nullable)backgroundColor borderStyle:(NSString * _Nullable)borderStyle borderColor:(NSString * _Nullable)borderColor completion:(void (^)(BOOL))completion {
    CGFloat fontSize = [self tabBarItemFontSize];
    for (UITabBarItem *item in self.tabBar.items) {
        if (!BDPIsEmptyString(textColor)) {
            [item setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithHexString:textColor], NSFontAttributeName: [UIFont systemFontOfSize:fontSize]}
                                forState:UIControlStateNormal];
        }
        if (!BDPIsEmptyString(textSelectedColor)) {
            [item setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithHexString:textSelectedColor], NSFontAttributeName: [UIFont systemFontOfSize:fontSize]}                    forState:UIControlStateSelected];
        }
    }
    
    if (!BDPIsEmptyString(backgroundColor)) {
        /*
         Xcode13打包产物在iOS15上,backgroundImage所处的UIImageView的alpha值被被更改,页面滑动至最底部时被更改至0(透明),包括导航栏等等存在滑动时透明度被变更的问题
         导致黑色样式在最底部时会变成白色背景
         将背景色同时设置到tabbar的背景色上
         */
        self.tabBar.backgroundImage = [UIImage bdp_imageWithUIColor:[UIColor colorWithHexString:backgroundColor]];
        self.tabBar.backgroundColor = [UIColor colorWithHexString:backgroundColor];
    }
    
    if (!BDPIsEmptyString(borderStyle) || !BDPIsEmptyString(borderColor)) {
        [self setTabBarBorderStyle:borderStyle borderColor:borderColor];
        self.hasSetTabBarBorderStyleByAPI = YES;
    }
    
    if (completion) {
        completion(YES);
    }
    
    [self updateTabbarItemsStyle];
}

/// 设置tabBar可见性的实现（分为两个部分：可见性设置和相应可见性的高度设置）
- (void)setTabBarVisible:(BOOL)visible animated:(BOOL)animated completion:(void (^)(BOOL))completion
{
    /// 无需更新，即可见性和相应高度符合预期，无需操作
    if (![self needUpdateTabBarVisible:visible]) {
        if (completion) {
            completion(YES);
        }
        return;
    }

    /// 设置tabBar的可见性和相应高度
    self.isTabBarVisible = visible;
    CGFloat superViewHeight = self.tabBar.superview.bdp_height;
    CGFloat offsetY = visible ? superViewHeight - self.tabBar.bdp_height : superViewHeight;

    /// default animate duration: 0.3s, zero duration means no animation
    CGFloat duration = (animated)? 0.3 : 0.0;
    
    
    NSUInteger selectedIndex = self.selectedIndex;
    if (selectedIndex < 0 || selectedIndex >= self.viewControllers.count) {
        BDPLogError(@"[Gadget] invalid selectedIndex %lu", selectedIndex);
        return;
    }

    /// 以下两行为旧逻辑下的变量，新逻辑下不起作用，全量后删除
    CGFloat viewHeightValue = visible ? self.tabbarVisibleHeight : self.tabbarInvisibleHeight;
    UIView *view = self.viewControllers[selectedIndex].view;

    view = [self naviRootView];

    if (!visible) {
        [UIView animateWithDuration:duration animations:^{
            self.tabBar.bdp_top = offsetY;
            view.bdp_height = self.view.bdp_height;
        } completion:^(BOOL finished) {
            if (completion) {
                completion(finished);
                /// 在hide tabbar情况下，等tabbar下沉之后再hidden防止动画被覆盖
                self.tabBar.hidden = YES;
                /// 在动画内触发的子视图布局判断使用了self.tabBar.hidden，在completion内才会触发状态改变。所以在self.tabBar.hidden变化后需要需要重新布局
                [view setNeedsLayout];
            }
        }];
    } else {
        [UIView animateWithDuration:duration animations:^{
            self.tabBar.bdp_top = offsetY;
            view.bdp_height = self.view.bdp_height;
        } completion:^(BOOL finished) {
            if (completion) {
                completion(finished);
            }
            [view setNeedsLayout];
        }];
        /// 在show tabbar情况下，等tabbar上浮之前设置为不hidden防止动画覆盖
        self.tabBar.hidden = NO;
    }
}

- (BOOL)needUpdateTabBarVisible:(BOOL)tabBarVisible
{
    if (self.isTabBarVisible == tabBarVisible) {
        if ((tabBarVisible && self.tabBar.frame.origin.y == self.view.bounds.size.height - self.tabBar.bdp_height) || (!tabBarVisible && self.tabBar.frame.origin.y == self.view.bounds.size.height)) {
            BDPLogInfo(@"tabbar可见性与view高度符合预期，不用更新tabbar可见状态");
            return NO;
        }
    }

    return YES;
}

- (void)setTabBarBorderStyle:(NSString *)borderStyle borderColor:(NSString * _Nullable)borderColorStr
{
    UIColor *borderColor = nil;
    // 优先使用 borderColor
    if (!BDPIsEmptyString(borderColorStr)) {
        borderColor = [UIColor colorWithHexString:borderColorStr];
    }
    if (!borderColor) {
        // borderColor 无法使用时使用 borderStyle
        if ([borderStyle isEqualToString:kTabBarStyleWhite]) {
            borderColor = [UIColor whiteColor];
        } else {
            borderColor = [UIColor colorWithHexString:kTabBarBlackColor];
            if (self.uniqueID.isAppDarkMode) {
                borderColor = UDOCColor.lineDividerDefault.op_alwaysDark;
            }
        }
    }
    [self.tabBar bdp_addBorderForEdges:UIRectEdgeTop width:kTabBarBorderWidth color:borderColor];
    
    // 需要更新红点，否则会被 icon 盖住
    for (NSInteger index = 0; index < self.tabBar.items.count; index++) {
        [self.tabBar updateBadgePositionOnItemIndex:index];
    }
}

- (void)updateTabbarItemsStyle {
    // 目前的基于系统的Tabbar 已经难以满足产品的定制需求，如果仍要继续定制，建议重写 Tab 实现，放弃使用系统实现。
    
    // 产品需求：定制 Tabbar item 的文字宽度限制规则 https://bytedance.feishu.cn/docs/doccnngyCl2PTKdmePT9ALwA7Nb?appid=2#caPvX0
    if (self.tabBar.items.count > 0) {
        
        CGFloat tabBarItemWith = self.tabBar.frame.size.width / self.tabBar.items.count;
        CGFloat tabBarItemPadding = 12; // 左右两侧需要空12宽度
        CGFloat tabBarItemTitleMaxWith = tabBarItemWith - tabBarItemPadding * 2;   // 标题的最大宽度
        
        for (UITabBarItem *item in self.tabBar.items) {
            
            if (![BDPDeviceHelper isPadDevice]) {
                // 按照视觉要求, 特定的文本位置，-5 是 iOS 系统 Title 的位置与视觉要求的位置的偏移量。由于iOS系统并未提供Title的真实位置参数，该值根据iOS系统Tab的默认高度偏移而来。
                item.titlePositionAdjustment = UIOffsetMake(0, -5);
            }
            
            // 适配文本超长
            NSDictionary<NSAttributedStringKey,id> *attributes = [item titleTextAttributesForState:UIControlStateNormal];
            if (!attributes) {
                attributes = @{
                    NSFontAttributeName: [UIFont systemFontOfSize:[self tabBarItemFontSize]]
                };
            }
            [item bdp_applyTitleMaxWidth:tabBarItemTitleMaxWith attributes:attributes];
        }
    }
    
    
}

-(UIImage *)getDefaultImageWithName:(NSString*)iconName {
    UIImage *originImage = [[UIImage alloc] init];
    /// UI提供了light、dark两种默认图标，但并不是所有小程序都支持darkmode，因此需要区分
    if (self.uniqueID.isAppSupportDarkMode) {
        originImage = [UIImage imageNamed:[iconName stringByAppendingString:@"_darksupport"] inBundle:[BDPBundle mainBundle] compatibleWithTraitCollection:nil];
    } else {
        originImage = [UIImage imageNamed:iconName inBundle:[BDPBundle mainBundle] compatibleWithTraitCollection:nil];
    }
    UIImage *image = [[originImage scaledToSize:CGSizeFromString(BDPTabBarImageSizeString)] imageWithRenderingMode:UIImageRenderingModeAutomatic];
    return image;
}

- (void)temporaryHiddenAndRecover {
    // 暂时隐藏
    self.tabBar.hidden = YES;
    
    // 延迟触发恢复
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSUInteger index = self.selectedIndex;

        if (index < 0 || index >= self.viewControllers.count) {
            BDPLogError(@"[OP] tabbarController selected index is out of bounds");
            return;
        }

        UIViewController *vc = self.viewControllers[index];
        if ([vc isKindOfClass:UINavigationController.class]) {
            UINavigationController *navVc = (UINavigationController *)vc;
            
            // 仅导航容器的根视图需要控制恢复
            if (navVc.viewControllers.count == 1) {
                self.tabBar.hidden = !self.isTabBarVisible;
            }
        }
    });
}

#pragma mark - Computed Property
- (BOOL)didLoadAllConfigImages {
    return self.loadedConfigImageCount == self.configImageCount;
}

#pragma mark - LazyLoading
- (NSMutableArray<dispatch_block_t> *)setTabBarImageActions {
    if (!_setTabBarImageActions) {
        _setTabBarImageActions = [[NSMutableArray<dispatch_block_t> alloc] init];
    }
    return _setTabBarImageActions;
}

/// 适配iPad分转屏，重设badge位置
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if ([BDPDeviceHelper isPadDevice]) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self.tabBar bdp_layoutBadgeIfNeeded];
        } completion:nil];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        BDPLogInfo(@"traitCollectionDidChange. previous:%@, current:%@", @(previousTraitCollection.userInterfaceStyle), @(self.traitCollection.userInterfaceStyle));
        if (!self.uniqueID.isAppSupportDarkMode) {
            // 不支持 DarkMode
            BDPLogInfo(@"%@ not support dark mode", self.uniqueID);
            return;
        }
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            
            [self.tabBarConfig applyDarkMode:self.traitCollection.userInterfaceStyle==UIUserInterfaceStyleDark];
            
            // 为什么不直接用动态图片：实测发现 selectedImage 这个属性不支持动态图片
            WeakSelf;
            [self.tabBar.items enumerateObjectsUsingBlock:^(UITabBarItem * _Nonnull tabBarItem, NSUInteger idx, BOOL * _Nonnull stop) {
                StrongSelfIfNilReturn;
                WeakObject(tabBarItem);
                
                BDPTabBarPageConfig *pageConfig = (idx < self.tabBarConfig.list.count) ? self.tabBarConfig.list[idx] : nil;
                
                if (!tabBarItem.bdp_hasSetImageByAPI) {
                    [self loadImageWithPath:pageConfig.iconPath inOrder:NO completion:^(UIImage *image) {
                        StrongSelfIfNilReturn;
                        StrongObjectIfNilReturn(tabBarItem);
                        if (tabBarItem.bdp_hasSetImageByAPI) {
                            // 被其他设置覆盖，不用再设置了
                            return;
                        }
                        /// 在mode切换时，如果image为空，那么将显示一个默认的icon
                        if (!image) {
                            image = [self getDefaultImageWithName:@"icon_tab_default"];
                        }
                        tabBarItem.image = image;
                    }];
                }
                
                if (!tabBarItem.bdp_hasSetSelectedImageByAPI) {
                    [self loadImageWithPath:pageConfig.selectedIconPath inOrder:NO completion:^(UIImage *image) {
                        StrongSelfIfNilReturn;
                        StrongObjectIfNilReturn(tabBarItem);
                        if (tabBarItem.bdp_hasSetSelectedImageByAPI) {
                            // 被其他设置覆盖，不用再设置了
                            return;
                        }
                        /// 在mode切换时，如果selectedImage为空，那么将显示一个默认的icon
                        if (!image) {
                            image = [self getDefaultImageWithName:@"icon_tab_selected_default"];
                        }
                        tabBarItem.selectedImage = image;
                    }];
                }
            }];
        }
    }
}

@end

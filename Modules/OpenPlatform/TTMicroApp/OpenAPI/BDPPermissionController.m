//
//  BDPPermissionController.m
//  Timor
//
//  Created by CsoWhy on 2018/4/23.
//

#import <OPFoundation/BDPAuthorization+BDPUtils.h>
#import <OPFoundation/BDPBundle.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPDeviceManager.h>
#import "BDPNavigationController.h"
#import "BDPPermissionController.h"
#import <OPFoundation/BDPResponderHelper.h>
#import <OPFoundation/BDPSDKConfig.h>
#import "BDPStreamingAudioRecorder.h"
#import <OPFoundation/BDPStyleCategoryDefine.h>
#import <OPFoundation/BDPSwitch.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/UIView+BDPAppearance.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/EEFeatureGating.h>
#import <OPFoundation/BDPApplicationManager.h>
#import <OPFoundation/BDPSandBoxHelper.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

#define kLocalWidth self.view.bounds.size.width
#define kTableViewCellHeight 48
#define kAppBadgeCellHeight 96
#define kViewTag_CellDescriptionLabel 123456
#define kViewTag_HeaderTitleLabel 654321
#define kViewTag_CellTitleLabel 123321

/// 项目类型
typedef NS_ENUM(NSInteger, BDPPermissionItemType) {
    BDPPermissionItemDefault = 0,    // 开关项
    BDPPermissionItemDescription,   // 描述项
    BDPPermissionItemWithDescription,   // 开关+描述
};

/// 权限项目信息
@interface BDPPermissionItem : NSObject

@property (nonatomic, assign) BDPPermissionItemType itemType; // 项目类型
@property (nonatomic, copy) NSString *title;                // 标题
@property (nonatomic, assign) BOOL on;                      // 开关状态
@property (nonatomic, copy) NSAttributedString *detailDesctiption; // 开关描述，不为空时cell中会增加描述
@property (nonatomic, strong) NSString *scope;              // 值为 @"scope.xxxxx"
@property (nonatomic, assign) CGFloat cellHeight;           // 行高

@end

// 权限组
@interface BDPPermissionItemGroup : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSMutableArray <BDPPermissionItem *> *items;

@end

#import <OPFoundation/BDPI18n.h>

@interface BDPPermissionController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) BDPJSBridgeCallback jsCallback;
@property (nonatomic, strong) BDPAuthorization *auth;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray <BDPPermissionItemGroup *> *scopeGroups;
@property (nonatomic, strong) NSDictionary <NSString *, NSDictionary *> *allScopeInfoDict;

@end

@implementation BDPPermissionController

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)initWithAuthProvider:(BDPAuthorization *)provider {
    return [self initWithCallback:nil authProvider:provider];
}

- (instancetype)initWithCallback:(BDPJSBridgeCallback)callback authProvider:(BDPAuthorization *)provider {
    self = [super init];
    if (self) {
        _auth = provider;
        _jsCallback = callback;
        [self setupData];
    }
    return self;
}

- (void)dealloc
{
    NSDictionary *usedScopesDict = _auth.usedScopesDict;
    // 支持宿主自定义已授权信息
    BDPPlugin(authorizationPlugin, BDPAuthorizationPluginDelegate);
    if ([authorizationPlugin respondsToSelector:@selector(bdp_customGetSettingUsedScopesDict:)]) {
        usedScopesDict = [authorizationPlugin bdp_customGetSettingUsedScopesDict:usedScopesDict];
    }
    if (_jsCallback) {
        _jsCallback(BDPJSBridgeCallBackTypeSuccess, @{@"authSetting" : usedScopesDict ?: @{}});
    }
}


#pragma mark - Setup Data Source

- (void)setupData {
    NSDictionary *allScopeInfoDict = [self allScopeInfoDict]; // 本地文件记录的scope信息
    BDPPermissionItemGroup *defaultGroup = [BDPPermissionItemGroup new];
    BDPPermissionItemGroup *screenRecordGroup = [BDPPermissionItemGroup new];
    BDPPermissionItemGroup *appBadgeGroup = [BDPPermissionItemGroup new];
    BDPPermissionItemGroup *freeAuthGroup = [BDPPermissionItemGroup new];
    BOOL authFreeFG = [BDPAuthorization authorizationFree];
    // 对scope进行分组，方便展示
    [_auth.usedScopesDict enumerateKeysAndObjectsUsingBlock:^(NSString *scope, NSNumber *isOn, BOOL *stop) {
        BOOL isEnableAppBadge = YES;

        if (scope && [scope isKindOfClass:[NSString class]] && [scope isEqualToString:BDPScopeAppBadge] && ![EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetOpenAppBadge]) {
            isEnableAppBadge = NO;
        }

        NSString *scopeKey = [BDPAuthorization transfromScopeToInnerScope:scope];
        NSDictionary *scopeInfo = scopeKey ? [allScopeInfoDict bdp_dictionaryValueForKey:scopeKey] : nil;
        if (scopeInfo && isEnableAppBadge) {
            BDPPermissionItem *item = [BDPPermissionItem new];
            item.title = scopeInfo[@"name"];
            item.on = [isOn boolValue];
            item.scope = scope;
            item.cellHeight = kTableViewCellHeight;
            if ([scope isEqualToString:BDPScopeScreenRecord]) {
                // 录屏开关下面加多一行描述
                BDPPermissionItem *despItem = [BDPPermissionItem new];
                despItem.itemType = BDPPermissionItemDescription;
                NSString *desp = [scopeInfo bdp_stringValueForKey:@"description_new"];
                despItem.detailDesctiption = [self detailDescriptionStringWithText:desp];
                [screenRecordGroup.items addObject:item];
                [screenRecordGroup.items addObject:despItem];
            } else if (authFreeFG && [scope isEqualToString:BDPScopeAppBadge]) {
                NSString *desp = [scopeInfo bdp_stringValueForKey:@"description_new"];
                item.itemType = BDPPermissionItemWithDescription;
                item.detailDesctiption = [self detailDescriptionStringWithText:desp];
                [appBadgeGroup.items addObject:item];
            } else {
                [defaultGroup.items addObject:item];
            }
            
            if (authFreeFG && ![_auth modForScope:scopeKey] && ![scope isEqualToString:BDPScopeAppBadge] && !freeAuthGroup.items.count) {
                BDPPermissionItem *despItem = [BDPPermissionItem new];
                despItem.itemType = BDPPermissionItemDescription;
                NSString *appName = BDPSandBoxHelper.appDisplayName;
                NSString *description = BDPI18n.LittleApp_AppAuth_ExemptAuthorization;
                description = [description stringByReplacingOccurrencesOfString:@"{{APP_DISPLAY_NAME}}" withString:appName];
                despItem.detailDesctiption = [self detailDescriptionStringWithText:description];
                [freeAuthGroup.items addObject:despItem];
                return;
            }
        }
    }];
    
    NSMutableArray <BDPPermissionItemGroup *> *groups = [NSMutableArray arrayWithCapacity:3];
    if (authFreeFG && appBadgeGroup.items.count) [groups addObject:appBadgeGroup];
    if (authFreeFG && freeAuthGroup.items.count) {
        [groups addObject:freeAuthGroup];
    } else if (defaultGroup.items.count) {
        [groups addObject:defaultGroup];
    }
    if (screenRecordGroup.items.count) [groups addObject:screenRecordGroup];
    if (groups.count) {
        // 判断标题显示的group
        int titleGroupIndex = 0;
        if (authFreeFG && appBadgeGroup.items.count && groups.count > 1) {
            titleGroupIndex = 1;
        }
        if (BDPIsEmptyString(_auth.source.name)) {
            groups[titleGroupIndex].title = BDPI18n.LittleApp_TTMicroApp_PrmssnInUse;
        } else {
            NSString *desp = BDPI18n.AppDetail_Setting_PermissionTitle;
            groups[titleGroupIndex].title = [desp stringByReplacingOccurrencesOfString:@"{{app_name}}" withString:_auth.source.name];
        }
    }
    self.scopeGroups = [groups copy];
}


- (NSAttributedString *)detailDescriptionStringWithText:(NSString *)text {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 20;
    NSRange fullRange = NSMakeRange(0, text.length);
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:fullRange];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.6 alpha:1] range:fullRange];
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:fullRange];
    return attributedString;
}


- (NSDictionary<NSString *, NSDictionary *> *)allScopeInfoDict {
    if (!_allScopeInfoDict) {
        /*
        NSString *resource = [[BDPBundle mainBundle] pathForResource:@"ez" ofType:@"dat"];
        NSData *plistData = BDPDecodeDataFromPath(resource);
        if (plistData) {
            NSError *error;
            NSPropertyListFormat format;
            NSDictionary* dict =  [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:&format error:&error];
            _allScopeInfoDict = [dict bdp_dictionaryValueForKey:@"Scope"];
        }
         */
        _allScopeInfoDict = [[_auth scope] copy];
    }
    
    return _allScopeInfoDict.copy;
}

#pragma mark - View & Layout
/*-----------------------------------------------*/
//          View & Layout - 加载及布局相关
/*-----------------------------------------------*/
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self fitSizeForTipLabel];
    _tableView.frame = self.view.bounds;
}

- (void)setupView
{
    //Title & Color
    self.view.backgroundColor = UDOCColor.bgBase;
    
    if (!self.scopeGroups.count) {
        _tipLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _tipLabel.font = [UIFont systemFontOfSize:16];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.textColor = UDOCColor.textPlaceholder;
        _tipLabel.numberOfLines = 0;
        if (BDPIsEmptyString(_auth.source.name)) {
            _tipLabel.text = BDPI18n.LittleApp_TTMicroApp_NotUsingPrmssn;
        } else {
            _tipLabel.text = [NSString stringWithFormat:BDPI18n.permissions_not_request, _auth.source.name];
        }
        [self fitSizeForTipLabel];
        [self.view addSubview:_tipLabel];
        return;
    }

    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
//    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell_PermissionScope"];
    [_tableView setAllowsSelection:NO];
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
    _tableView.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0);
    _tableView.separatorColor = UDOCColor.lineDividerDefault;
    _tableView.backgroundColor = UDOCColor.bgBase;
    [self.view addSubview:_tableView];
    [self caculateCellHeight];

    __weak typeof(self) weakSelf = self;
    [_auth fetchAuthorizeData:YES completion:^(NSDictionary * _Nullable result, NSDictionary * _Nullable bizData, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (bizData && [bizData isKindOfClass:[NSDictionary class]] && bizData.count > 0) {
            BOOL hasNewData = [bizData bdp_boolValueForKey:@"hasNewData"];
            if (hasNewData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf setupData];
                    [strongSelf caculateCellHeight];
                    [strongSelf.tableView reloadData];
                });
            }
        }
    }];
}

- (void)caculateCellHeight {
    // 计算cell行高，提前计算会导致viewDidLoad被调用
    UILabel *calculationLabel = [UILabel new];
    calculationLabel.numberOfLines = 0;
    for (BDPPermissionItemGroup *group in self.scopeGroups) {
        for (BDPPermissionItem *item in group.items) {
            if (item.itemType == BDPPermissionItemDescription) {
                // 计算行高，使用真实label来计算
                calculationLabel.attributedText = item.detailDesctiption;
                CGSize textSize = [calculationLabel sizeThatFits:CGSizeMake(kLocalWidth - 30, 10000)];
                item.cellHeight = textSize.height * 1.09 + 30;
            } else if (item.itemType == BDPPermissionItemWithDescription) {
                item.cellHeight = kAppBadgeCellHeight;
            }
        }
    }
}

- (void)fitSizeForTipLabel {
    UILabel *tipLabel = _tipLabel;
    CGFloat width = self.view.bdp_width;
    CGFloat height = [tipLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height;
    tipLabel.frame = CGRectMake(0, (self.view.bdp_height - height)/2.0, self.view.bdp_width, height);
}

#pragma mark - NavigationBar Style
/*-----------------------------------------------*/
//        NavigationBar Style - 导航栏样式
/*-----------------------------------------------*/
- (void)updateNavigationBarStyle:(BOOL)animated
{
    BDPNavigationController *superNavi = (BDPNavigationController *)self.navigationController;
    if ([superNavi isKindOfClass:[BDPNavigationController class]]) {
        
        NSString *title = BDPI18n.settings;
        NSDictionary *titleAttributes = @{NSForegroundColorAttributeName:UDOCColor.textTitle};
        UIColor *navigationBarBackgroundColor = UDOCColor.bgBody;
        UIColor *navigationBarTintColor = UDOCColor.textTitle;

        [superNavi setNavigationItemTitle:title viewController:self];
        [superNavi setNavigationBarTitleTextAttributes:titleAttributes viewController:self];
        [superNavi setNavigationBarBackgroundColor:navigationBarBackgroundColor];
        [superNavi setNavigationItemTintColor:navigationBarTintColor viewController:self];
        [self updateNavigationBar:navigationBarBackgroundColor];
    }
}

- (void)updateNavigationBar:(UIColor *)backgroundColor {
    // https://developer.apple.com/forums/thread/682420
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = backgroundColor;
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
}

#pragma mark - tableView Delegate
/*-----------------------------------------------*/
//          TableView Delegate - 列表相关
/*-----------------------------------------------*/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const cellIdentifier = @"TableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.textLabel.textColor = UDOCColor.textTitle;
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.backgroundColor = UDOCColor.bgBody;
        UILabel *descriptionLabel = [UILabel new];
        descriptionLabel.textColor = UDOCColor.textTitle;
        descriptionLabel.backgroundColor = UDOCColor.bgBody;
        descriptionLabel.numberOfLines = 0;
        descriptionLabel.tag = kViewTag_CellDescriptionLabel;
        [cell.contentView addSubview:descriptionLabel];
        descriptionLabel.hidden = YES;
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.font = [UIFont systemFontOfSize:16];
        titleLabel.backgroundColor = UDOCColor.bgBody;
        titleLabel.textColor = UDOCColor.textTitle;
        titleLabel.tag = kViewTag_CellTitleLabel;
        [cell.contentView addSubview:titleLabel];
        titleLabel.hidden = YES;
    }
    BDPPermissionItemGroup *group = self.scopeGroups[indexPath.section];
    BDPPermissionItem *item = group.items[indexPath.row];
    UILabel *descriptionLabel = [cell.contentView viewWithTag:kViewTag_CellDescriptionLabel];
    UILabel *titleLabel = [cell.contentView viewWithTag:kViewTag_CellTitleLabel];
    if (item.itemType == BDPPermissionItemDefault) {
        // 默认行：开关样式
        cell.textLabel.text = item.title;
        descriptionLabel.hidden = YES;
        [self getSwitchView:cell forRowAtIndexPath:indexPath item:item];
        
    } else if (item.itemType == BDPPermissionItemWithDescription) {
        titleLabel.text = item.title;
        titleLabel.hidden = NO;
        CGSize titleSize = [titleLabel sizeThatFits:CGSizeMake(titleLabel.frame.size.width, MAXFLOAT)];
        titleLabel.frame = CGRectMake(15, 13, titleSize.width, titleSize.height);
        descriptionLabel.hidden = NO;
        descriptionLabel.attributedText = item.detailDesctiption;
        CGSize descriptionSize = [descriptionLabel sizeThatFits:CGSizeMake(descriptionLabel.frame.size.width, MAXFLOAT)];
        descriptionLabel.frame = CGRectMake(15, titleSize.height + 21, cell.contentView.frame.size.width - 28 - 15, descriptionSize.height);
        [self getSwitchView:cell forRowAtIndexPath:indexPath item:item];
    } else {
        // 描述行
        titleLabel.hidden = YES;
        descriptionLabel.hidden = NO;
        descriptionLabel.attributedText = item.detailDesctiption;
        descriptionLabel.frame = CGRectInset(cell.contentView.bounds, 15, 0);
        descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        cell.accessoryView = nil;
    }
    return cell;
}

- (BDPSwitch *)getSwitchView:(UITableViewCell *)cell
           forRowAtIndexPath:(NSIndexPath *)indexPath
                        item:(BDPPermissionItem *)item {
    BDPSwitch *switchView = (BDPSwitch *)cell.accessoryView;
    if (!switchView) {
        switchView = [[BDPSwitch alloc] init];
        switchView.bdp_styleCategories = @[BDPStyleCategoryPositive, BDPStyleCategoryPositive];
        switchView.center = CGPointMake(kLocalWidth - switchView.bounds.size.width / 2 - 15, kTableViewCellHeight / 2);
        [switchView addTarget:self action:@selector(switchOnChange:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = switchView;
    }
    switchView.on = item.on;
    switchView.tag = [self tagWithIndexPath:indexPath];
    return switchView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.scopeGroups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    BDPPermissionItemGroup *group = self.scopeGroups[section];
    return group.items.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    BDPPermissionItemGroup *group = self.scopeGroups[section];
    CGFloat defaultHeight = BDPIsEmptyString(group.title)? 8:42;
    if(group.title) {
        UIView *headerView = [self tableView:tableView viewForHeaderInSection:section];
        UILabel *titleLabel = [headerView viewWithTag:kViewTag_HeaderTitleLabel];
        if(titleLabel) {
//            CGSize maximumLabelSize = CGSizeMake(kLocalWidth, CGFLOAT_MAX);
            CGSize expectSize = [titleLabel textRectForBounds:titleLabel.bounds
                                       limitedToNumberOfLines:0].size;
            if(ceil(expectSize.height) <= 18) {
                return 42;
            }
            return ceil(expectSize.height) + 35;
        }
    }
    return defaultHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BDPPermissionItemGroup *group = self.scopeGroups[indexPath.section];
    BDPPermissionItem *item = group.items[indexPath.row];
    return item.cellHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString * const headerIdentifier = @"TableViewHeader";
    UIView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerIdentifier];
    if (!headerView) {
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kLocalWidth, 20)];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(headerView.bounds, 15, 0)];
        titleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
        titleLabel.font = [UIFont systemFontOfSize:12];
        titleLabel.tag = kViewTag_HeaderTitleLabel;
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        titleLabel.numberOfLines = 0;
        [headerView addSubview:titleLabel];
    }
    UILabel *titleLabel = [headerView viewWithTag:kViewTag_HeaderTitleLabel];
    BDPPermissionItemGroup *group = self.scopeGroups[section];
    titleLabel.text = group.title;
    return headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    /// 这里仅仅是为了把footerView的高度设置为0
    static NSString * const footerIdentifier = @"TableViewFooter";
    UIView *footerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:footerIdentifier];
    if (!footerView) {
        footerView = [UIView new];
    }
    return footerView;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    BDPPermissionItemGroup *group = self.scopeGroups[section];
    return group.title;
}

- (NSInteger)tagWithIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section << 16) + indexPath.row;
}

- (NSIndexPath *)indexPathWithTag:(NSInteger)tag {
    return [NSIndexPath indexPathForRow:tag & 0x0000FFFF inSection:(tag & 0xFFFF0000) >> 16];
}


#pragma mark - Action
/*-----------------------------------------------*/
//                Action - 按钮响应
/*-----------------------------------------------*/
- (void)switchOnChange:(UISwitch *)switchView
{
    NSIndexPath *indexPath = [self indexPathWithTag:switchView.tag];
    BDPPermissionItemGroup *group = self.scopeGroups[indexPath.section];
    BDPPermissionItem *item = group.items[indexPath.row];
    item.on = switchView.on;
    
    // 更新Auth数据
    [_auth updateScope:[BDPAuthorization transfromScopeToInnerScope:item.scope] approved:switchView.on];
    
    // 关闭音频权限时，停止录音
    if ([item.scope isEqualToString:BDPScopeRecord]) {
        [[BDPStreamingAudioRecorder shareInstance] forceStopRecorder];
    }
    if ([item.scope isEqualToString:BDPScopeAppBadge]) {
        BDPUniqueID *uniqueID = _auth.source.uniqueID;
        NSMutableDictionary *trackerParams = [NSMutableDictionary dictionary];
        if (uniqueID.appType == BDPTypeNativeApp) {
            [trackerParams setValue:@"MP" forKey:@"application_type"];
        } else if (uniqueID.appType == BDPTypeWebApp) {
            [trackerParams setValue:@"H5" forKey:@"application_type"];
        }
        [trackerParams setValue:(switchView.on ? @"open" : @"close") forKey:@"action"];
        [trackerParams setValue:@"mp_setting" forKey:@"source"];
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        NSString *appName = common.model.name ? common.model.name : @"";
        [trackerParams setValue:appName forKey:@"appname"];
        [trackerParams setValue:uniqueID.appID forKey:@"app_id"];
        [BDPTracker event:@"app_setting_set_Badge" attributes:trackerParams.copy uniqueID:uniqueID];
    }
}

#pragma mark - StatusBar
/*------------------------------------------*/
//            StatusBar - 状态栏
/*------------------------------------------*/
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - Orientation
/*------------------------------------------*/
//          Orientation - 屏幕旋转
/*------------------------------------------*/
- (BOOL)shouldAutorotate
{
    return [BDPDeviceManager shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end


@implementation BDPPermissionItemGroup

- (instancetype)init {
    self = [super init];
    if (self) {
        _items = [NSMutableArray array];
    }
    return self;
}

@end


@implementation BDPPermissionItem

@end

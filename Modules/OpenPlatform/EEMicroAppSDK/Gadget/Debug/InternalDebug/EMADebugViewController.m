//
//  EMADebugViewController.m
//  EEMicroAppSDK
//
//  Created by 殷源 on 2018/10/26.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "EERoute.h"
#import <OPFoundation/EMAAlertController.h>
#import "EMAAppEngine.h"
#import "EMADebugLaunchTracing.h"
#import "EMADebugUtil+Business.h"
#import "EMADebugViewController.h"
#import <OPFoundation/EMASandBoxHelper.h>
#import <CommonCrypto/CommonDigest.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <Masonry/Masonry.h>
#import <TTRoute/TTRoute.h>
#import <OPFoundation/BDPCommonManager.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPVersionManager.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <ECOProbe/OPMonitorService.h>
#import <OPSDK/OPSDK-Swift.h>
#import <OPBlock/OPBlock-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <TTMicroApp/OPVersionDirHandler.h>

#define CELL_ID_NORMAL @"CELL_ID_NORMAL"
#define INDEX_PATH_SEGMENT 1000000

static NSString * const kEMADebugHelpUrl = @"https://bytedance.feishu.cn/space/doc/A9neinNs903UZFLN1YOQVc";

@interface EMADebugViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) BDPCommon *common;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray<NSArray<EMADebugConfig *> *> *sections;

@end

@implementation EMADebugViewController

- (instancetype)initWithCommon:(BDPCommon *)common {
    if (self = [super init]) {
        self.common = common;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Debug";

    [self setupViews];
    [self reloadDatas];
}

- (void)setupViews {
    id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
    if ([delegate respondsToSelector:@selector(canOpenURL:fromScene:)]) {
        if([delegate canOpenURL:[NSURL URLWithString:kEMADebugHelpUrl] fromScene:OpenUrlFromSceneDebugPage]) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"帮助" style:UIBarButtonItemStylePlain target:self action:@selector(onHelpButtonClick)];
        }
    }

    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    [self.view addSubview:self.tableView];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(self.view);
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.shadowImage = [UIImage new];

    [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)reloadDatas {
    if (!EMADebugUtil.sharedInstance.enable) {
        return;
    }

    NSMutableArray *sectionInfo = [NSMutableArray array];
    [sectionInfo addObject:[EMADebugConfig configWithID:nil name:@"JSSDK版本" type:EMADebugConfigTypeNone defaultValue:BDPVersionManager.localLibVersionString noCache:YES]];
    if (self.common) {
        BDPTask *task = BDPTaskFromUniqueID(self.common.uniqueID);
        [sectionInfo addObject:[EMADebugConfig configWithID:nil name:@"小程序uniqueID" type:EMADebugConfigTypeNone defaultValue:self.common.uniqueID.fullString noCache:YES]];
        [sectionInfo addObject:[EMADebugConfig configWithID:nil name:@"小程序版本" type:EMADebugConfigTypeNone defaultValue:[NSString stringWithFormat:@"%@%@", self.common.model.version, [EMAAppEngine.currentEngine.onlineConfig isMicroAppTestForUniqueID:self.common.uniqueID]?@"(灰度)":@""] noCache:YES]];
        [sectionInfo addObject:[EMADebugConfig configWithID:nil name:@"页面路径" type:EMADebugConfigTypeNone defaultValue:task.currentPage.absoluteString noCache:YES]];
        [sectionInfo addObject:[EMADebugConfig configWithID:nil name:@"URL" type:EMADebugConfigTypeNone defaultValue:self.common.schema.originURL.absoluteString noCache:YES]];
        [sectionInfo addObject:[EMADebugConfig configWithID:nil name:@"scene" type:EMADebugConfigTypeNone defaultValue:self.common.schema.scene noCache:YES]];
        [sectionInfo addObject:[EMADebugConfig configWithID:nil name:@"适配DarkMode" type:EMADebugConfigTypeNone defaultValue:@(self.common.uniqueID.isAppSupportDarkMode).stringValue noCache:YES]];
        
        NSString *appConfig = task.config.toDictionary.description;
        [sectionInfo addObject:[EMADebugConfig configWithID:nil name:@"AppConfig" type:EMADebugConfigTypeNone defaultValue:appConfig noCache:YES]];
        [sectionInfo addObject:[EMADebugConfig configWithID:nil name:@"是否使用了分包" type:EMADebugConfigTypeNone defaultValue:@(self.common.isSubpackageEnable).stringValue noCache:YES]];
    }

    NSMutableArray *section0 = [NSMutableArray array];
    [section0 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigForceOpenAppDebug]];    // 开启应用调试（VConsole）
    [section0 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDEnableDebugLog]];
    [section0 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigUploadEvent]];
    [section0 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDEnableLaunchTracing]];
    // 如果没有新版调试小程序的权限，那么就开启一个可以显示性能调试窗口的开关
    if (!OPDebugFeatureGating.debugAvailable) {
        [section0 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigShowMainWindowPerformanceDebugView]];
    }
    [section0 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDOpenAppByID]];
    [section0 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDOpenAppBySchemeURL]];
    [section0 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDOpenAppByIPPackage]];
    [section0 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDOpenAppDemo]];
    [section0 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDRecentOpenURL]];

    NSMutableArray *section1 = [NSMutableArray array];
    [section1 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDClearMicroAppProcesses]];
    [section1 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDClearMicroAppFileCache]];
    [section1 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDClearMicroAppFolders]];
    [section1 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDClearH5ApppFolders]];
    [section1 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDClearPermission]];
    [section1 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigDoNotUseAuthDataFromRemote]];
    [section1 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDClearCookies]];
    [section1 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDForceColdStartMicroApp]];
    [section1 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDDoNotGrayApp]];
    [section1 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDReloadCurrentGadgetPage]];
    [section1 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDTriggerMemoryWarning]];
    [section1 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDOPAppLaunchDataDeleteOld]];

    NSMutableArray *section2 = [NSMutableArray array];

    if (![EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseBuildInJSSDK].boolValue) {
        [section2 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDClearJSSDKFileCache]];
        [section2 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDShowJSSDKUpdateTips]];
        [section2 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseSpecificJSSDKURL]];
    }

    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseSpecificJSSDKURL].boolValue) {
        [section2 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDSpecificJSSDKURL]];
    }else {
        [section2 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseBuildInJSSDK]];
        if (![EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseBuildInJSSDK].boolValue) {
            [section2 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDForceUpdateJSSDK]];
            [section2 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseStableJSSDK]];
            [section2 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDDoNotCompressJS]];
        }
    }


    NSMutableArray *section3 = [NSMutableArray array];
//    [section3 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseAmapLocation]];
    [section3 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDDisableAppCharacter]];
    [section3 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDForcePrimitiveNetworkChannel]];
    [section3 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigForceOverrideRequestID]];
    
    if (EMASandBoxHelper.gadgetDebug) {
        [section3 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDChangeHostSessionID]];
    }
    NSMutableArray *section4 = [NSMutableArray array];
    [section4 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugH5ConfigIDAppID]];
    [section4 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugH5ConfigIDLocalH5Address]];


    NSMutableArray *sectionBlock = [NSMutableArray array];
    [sectionBlock addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugBlockTest]];
    [sectionBlock addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDShowBlockPreviewUrl]];
    [sectionBlock addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugBlockDetail]];
    
    [sectionBlock addObject:[EMADebugConfig configWithID:nil name:@"Block JSSDK版本" type:EMADebugConfigTypeNone defaultValue:[BDPVersionManager localLibVersionString:OPAppTypeBlock] noCache:YES]];
    [sectionBlock addObject:[EMADebugConfig configWithID:nil name:@"消息卡片模版 JSSDK版本" type:EMADebugConfigTypeNone defaultValue:[BDPVersionManager localLibVersionString:OPAppTypeSDKMsgCard] noCache:YES]];

    [sectionBlock addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseSpecificBlockJSSDKURL]];
    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseSpecificBlockJSSDKURL].boolValue) {
        [sectionBlock addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDSpecificBlockJSSDKURL]];
    }


    NSMutableArray *section5 = [NSMutableArray array];
    [section5 addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDDisableDebugTool]];

    NSMutableArray *sectionRemoteDebugger = [NSMutableArray array];
    [sectionRemoteDebugger addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDEnableRemoteDebugger]];
    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDEnableRemoteDebugger].boolValue) {
        [sectionRemoteDebugger addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDRemoteDebuggerURL]];
    }

    NSMutableArray *sectionWorker = [NSMutableArray array];
    NSString *commentVersion = [OpenPluginCommnentJSManager currentCommentVersion];
    NSString *commentVersionDesc = @"";
    if (commentVersion) {
        commentVersionDesc = [NSString stringWithFormat:@"%@[%@]", commentVersion, ([OpenPluginCommnentJSManager commentUseOnlineSDK] ? @"在线":@"内置")];
    }
    [sectionWorker addObject:[EMADebugConfig configWithID:nil name:@"评论JSSDK版本" type:EMADebugConfigTypeNone defaultValue:commentVersionDesc noCache:YES]];

    NSMutableArray *sectionWorkerType = [NSMutableArray array];
    [sectionWorkerType addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDShowWorkerTypeTips]];
    [sectionWorkerType addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDWorkerDonotUseNetSetting]];
    [sectionWorkerType addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseNewWorker]];
    [sectionWorkerType addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseVmsdk]];
    [sectionWorkerType addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseVmsdkQjs]];

    NSMutableArray *sectionMessageCard = [NSMutableArray array];
    [sectionMessageCard addObject:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigMessageCardDebugTool]];

    self.sections = @[sectionInfo, section0, section1, section2, section3, section4, sectionRemoteDebugger, sectionBlock, section5, sectionWorker, sectionWorkerType, sectionMessageCard];

    [self.tableView reloadData];
}

- (void)onHelpButtonClick {
    [self dismissViewControllerAnimated:NO completion:nil];
    id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
    if ([delegate respondsToSelector:@selector(openURL:fromScene:uniqueID:fromController:)]) {
        [delegate openURL:[NSURL URLWithString:kEMADebugHelpUrl] fromScene:OpenUrlFromSceneDebugPage uniqueID:self.common.uniqueID fromController:self];
    }
}

- (void)onCellSwitch:(UISwitch *)switchView {
    NSUInteger section = switchView.tag / INDEX_PATH_SEGMENT;
    NSUInteger row = switchView.tag % INDEX_PATH_SEGMENT;

    EMADebugConfig *config = self.sections[section][row];
    config.boolValue = switchView.isOn;

    [self reloadDatas];

    if ([config.configID isEqualToString:kEMADebugConfigIDUseSpecificJSSDKURL]) {
        [EMADebugUtil.sharedInstance checkJSSDKDebugConfig];
    } else if ([config.configID isEqualToString:kEMADebugConfigIDUseSpecificBlockJSSDKURL]) {
        [EMADebugUtil.sharedInstance checkBlockJSSDKDebugConfig:!switchView.isOn];
    } else if ([config.configID isEqualToString:kEMADebugConfigIDDoNotGrayApp]) {
        [EMADebugUtil.sharedInstance clearMicroAppFileCache];
    } else if ([config.configID isEqualToString:kEMADebugConfigIDForceUpdateJSSDK]) {
        [EMADebugUtil.sharedInstance checkJSSDKDebugConfig];
    } else if ([config.configID isEqualToString:kEMADebugConfigIDUseStableJSSDK]) {
        [EMADebugUtil.sharedInstance checkJSSDKDebugConfig];
    } else if ([config.configID isEqualToString:kEMADebugConfigIDDoNotCompressJS]) {
        [EMADebugUtil.sharedInstance checkJSSDKDebugConfig];
    } else if ([config.configID isEqualToString:kEMADebugConfigIDUseBuildInJSSDK]) {
        [EMADebugUtil.sharedInstance checkJSSDKDebugConfig];
    } else if ([config.configID isEqualToString:kEMADebugConfigIDForcePrimitiveNetworkChannel]) {
        exit(0);
    } else if ([config.configID isEqualToString:kEMADebugConfigIDEnableDebugLog]) {
        BDPDebugLogEnable = config.boolValue;
    } else if ([config.configID isEqualToString:kEMADebugConfigIDEnableRemoteDebugger]) {
        [EMADebugUtil.sharedInstance checkAndSetDebuggerConnection];
    } else if ([config.configID isEqualToString:kEMADebugConfigIDEnableLaunchTracing]) {
        [[EMADebugLaunchTracing sharedInstance] updateDebugConfig];
    } else if ([config.configID isEqualToString:kEMADebugConfigUploadEvent]) {
        OPMonitorService.defaultService.config.reportDebugEnable = config.boolValue;
        GDMonitorService.gadgetMonitorService.config.reportDebugEnable = config.boolValue;
    } else if ([config.configID isEqualToString:kEMADebugConfigForceOpenAppDebug]) {
        BDPSDKConfig.sharedConfig.forceAppDebugOpen = switchView.isOn;
    } else if ([config.configID isEqualToString:kEMADebugConfigDoNotUseAuthDataFromRemote]) {
        if (switchView.isOn) {
            // 先清理一下本地的授权数据
            [EMADebugUtil.sharedInstance clearMicroAppPermission];
        }
    } else if ([config.configID isEqualToString:kEMADebugConfigShowMainWindowPerformanceDebugView]) {
        if (switchView.isOn) {
            [OPDebugWindow startDebugWithWindow:[OPWindowHelper fincMainSceneWindow]];
        } else {
            [OPDebugWindow closeDebugWithWindow:[OPWindowHelper fincMainSceneWindow]];
        }
    } else if ([config.configID isEqualToString:kEMADebugBlockDetail]) {
        BlockDebugConfig.shared.openBlockDetailDebug = switchView.isOn;
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    EMADebugConfig *config = self.sections[indexPath.section][indexPath.row];

    cell.textLabel.text = config.configName;

    if (config.configType == EMADebugConfigTypeNone) {
        cell.accessoryView = nil;
        cell.detailTextLabel.text = config.stringValue;
        cell.accessoryType = UITableViewCellAccessoryNone;

        if (!BDPIsEmptyString(config.stringValue)) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }else if (config.configType == EMADebugConfigTypeBool) {
        UISwitch *switchView = [UISwitch new];
        [switchView setOn:config.boolValue];
        [switchView addTarget:self action:@selector(onCellSwitch:) forControlEvents:UIControlEventValueChanged];
        switchView.tag = indexPath.section * INDEX_PATH_SEGMENT + indexPath.row;

        cell.accessoryView = switchView;
        cell.detailTextLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }else if (config.configType == EMADebugConfigTypeString) {
        cell.accessoryView = nil;
        cell.detailTextLabel.text = [config stringValue];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    EMADebugConfig *config = self.sections[indexPath.section][indexPath.row];
    return config.configType == EMADebugConfigTypeNone && !BDPIsEmptyString(config.stringValue);
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    EMADebugConfig *config = self.sections[indexPath.section][indexPath.row];
    [SCPasteboardOCBridge setGeneralWithToken:OPSensitivityEntryTokenDebug string: config.stringValue];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    EMADebugConfig *config = self.sections[indexPath.section][indexPath.row];

    if (config.configType == EMADebugConfigTypeNone) {
        [self didSelectNoneTypeConfig:config];
    } else if (config.configType == EMADebugConfigTypeString) {
        [self didSelectStringTypeConfig:config];
    }
}

- (void)didSelectNoneTypeConfig:(EMADebugConfig *)config {
    if ([config.configID isEqualToString:kEMADebugConfigIDClearMicroAppProcesses]) {
        [EMADebugUtil.sharedInstance clearMicroAppProcesses];
    }else if ([config.configID isEqualToString:kEMADebugConfigIDClearPermission]) {
        [EMADebugUtil.sharedInstance clearMicroAppPermission];
    }else if ([config.configID isEqualToString:kEMADebugConfigIDClearCookies]) {
        [EMADebugUtil.sharedInstance clearAppAllCookies];
    }else if ([config.configID isEqualToString:kEMADebugConfigIDClearMicroAppFileCache]) {
        [EMADebugUtil.sharedInstance clearMicroAppFileCache];
    }else if ([config.configID isEqualToString:kEMADebugConfigIDClearMicroAppFolders]) {
        [EMADebugUtil.sharedInstance clearMicroAppFolders];
    }else if ([config.configID isEqualToString:kEMADebugConfigIDClearH5ApppFolders]) {
        [EMADebugUtil.sharedInstance clearH5AppFolders];
    }else if ([config.configID isEqualToString:kEMADebugConfigIDClearJSSDKFileCache]) {
        [EMADebugUtil.sharedInstance clearJSSDKFileCache];
    }else if ([config.configID isEqualToString:kEMADebugConfigIDDisableDebugTool]) {
        EMAAlertController *alertViewController = [EMAAlertController alertControllerWithTitle:@"禁用方法" message:@"退出【小程序引擎升级体验群】，重启应用后悬浮球消失。加群可以再次开启调试悬浮球。如果需要临时禁用，请使用【临时禁用调试悬浮球】开关。" preferredStyle:UIAlertControllerStyleAlert];
        [alertViewController addAction:[EMAAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertViewController animated:YES completion:nil];
    }else if ([config.configID isEqualToString:kEMADebugConfigIDGetHostSessionID]) {
        [SCPasteboardOCBridge setGeneralWithToken:OPSensitivityEntryTokenDebug string: EMAAppEngine.currentEngine.account.userSession];
        [UDToastForOC showTipsWith:@"已复制到剪贴板" on:self.view.window];
    } else if ([config.configID isEqualToString:kEMADebugConfigIDOpenAppDemo]) {
        [EERoute.sharedRoute openURLByPushViewController:[NSURL URLWithString:config.stringValue] window:self.view.window];
    } else if ([config.configID isEqualToString:kEMADebugConfigIDRecentOpenURL]) {
           [EERoute.sharedRoute openURLByPushViewController:[NSURL URLWithString:config.stringValue] window:self.view.window];
    } else if([config.configID isEqualToString:kEMADebugConfigIDReloadCurrentGadgetPage]){
        [EMADebugUtil.sharedInstance reloadCurrentGadgetPage];
    } else if([config.configID isEqualToString:kEMADebugConfigIDTriggerMemoryWarning]){
        [EMADebugUtil.sharedInstance triggerMemorywarning];
    }
    else {
        if (!BDPIsEmptyString(config.stringValue)) {
            EMAAlertController *alertViewController = [EMAAlertController alertControllerWithTitle:config.configName message:config.stringValue preferredStyle:UIAlertControllerStyleAlert];
            [alertViewController addAction:[EMAAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(EMAAlertAction *action) {
                [SCPasteboardOCBridge setGeneralWithToken:OPSensitivityEntryTokenDebug string: config.stringValue];
                [UDToastForOC showTipsWith:@"已复制到剪贴板" on:self.view.window];
            }]];
            [alertViewController addAction:[EMAAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertViewController animated:YES completion:nil];
        }
    }
}

- (void)didSelectStringTypeConfig:(EMADebugConfig *)config {
    __weak typeof(self) weakSelf = self;
    EMAAlertController *alertViewController = [EMAAlertController alertControllerWithTitle:config.configName message:nil preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(alertViewController) weakAlertViewController = alertViewController;
    [alertViewController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = [config stringValue];
        textField.clearButtonMode = UITextFieldViewModeAlways;
    }];
    [alertViewController addAction:[EMAAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertViewController addAction:[EMAAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(EMAAlertAction * _Nonnull action) {
        NSString *text = weakAlertViewController.textFields[0].text;
        if (text.length > 0) {
            config.stringValue = text;
            [weakSelf.tableView reloadData];

            if ([config.configID isEqualToString:kEMADebugConfigIDUseSpecificJSSDKURL] || [config.configID isEqualToString:kEMADebugConfigIDSpecificJSSDKURL]) {
                [EMADebugUtil.sharedInstance checkJSSDKDebugConfig];
            } else if ([config.configID isEqualToString:kEMADebugConfigIDUseSpecificBlockJSSDKURL] || [config.configID isEqualToString:kEMADebugConfigIDSpecificBlockJSSDKURL]) {
                [EMADebugUtil.sharedInstance checkBlockJSSDKDebugConfig:YES];
            } else if ([config.configID isEqualToString:kEMADebugConfigIDOpenAppByID]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [EERoute.sharedRoute openURLByPushViewController:[NSURL URLWithString:[NSString stringWithFormat:@"sslocal://microapp?app_id=%@", config.stringValue]] window:self.view.window];
                });
            }else if ([config.configID isEqualToString:kEMADebugConfigIDOpenAppBySchemeURL]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [EERoute.sharedRoute openURLByPushViewController:[NSURL URLWithString:config.stringValue] window:self.view.window];
                });
            }else if ([config.configID isEqualToString:kEMADebugConfigIDOpenAppByIPPackage]) {
                //[EMADebugUtil.sharedInstance clearMicroAppProcesses];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    // 通过URL生成一个唯一的AppID
                    const char *str = [text UTF8String];
                    unsigned char result[CC_MD5_DIGEST_LENGTH];
                    CC_MD5(str, (CC_LONG)strlen(str), result);
                    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH];
                    for (int i = 0; i < CC_MD5_DIGEST_LENGTH/2; i++) {
                        [output appendFormat:@"%02x", result[i]];
                    }
                    NSString *appID = [NSString stringWithFormat:@"tt%@", output.lowercaseString];
                    NSDictionary *urlDic = @{@"id":appID,
                                             @"name":@"TestAPP",
                                             @"icon":@"http://10.1.99.40:18242/__dist__.zip:80/icon.png",
                                             @"version":@(arc4random()),
                                             @"url":text
                                             };
                    [EERoute.sharedRoute openURLByPushViewController:[NSURL URLWithString:[NSString stringWithFormat:@"sslocal://microapp?url=%@&isdev=1", [urlDic JSONRepresentation].URLEncodedString]] window:self.view.window];
                });
            } else if ([config.configID isEqualToString:kEMADebugConfigIDChangeHostSessionID]) {
                [EMADebugUtil.sharedInstance clearMicroAppProcesses];
            } else if ([config.configID isEqualToString:kEMADebugConfigIDEnableRemoteDebugger]) {
                [EMADebugUtil.sharedInstance checkAndSetDebuggerConnection];
            } else if ([config.configID isEqualToString:kEMADebugConfigIDOPAppLaunchDataDeleteOld]) {
                [BDPSDKConfig sharedConfig].appLaunchInfoDeleteOldDataDays = [config.stringValue copy];
            }
        } else {
            if ([config.configID isEqualToString:kEMADebugConfigIDChangeHostSessionID] ||
                [config.configID isEqualToString:kEMADebugH5ConfigIDLocalH5Address]) {
                config.stringValue = text;
                [weakSelf.tableView reloadData];
            }
        }
    }]];
    [self presentViewController:alertViewController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_ID_NORMAL];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleValue1 reuseIdentifier: CELL_ID_NORMAL];
    }
    cell.accessibilityIdentifier = [NSString stringWithFormat:@"gadget.debug.cell-%d-%d", indexPath.section, indexPath.row];
    return cell;
}

@end

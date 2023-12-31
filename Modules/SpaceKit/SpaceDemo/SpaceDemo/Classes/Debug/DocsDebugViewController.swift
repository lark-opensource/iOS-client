//
//  DocsDebugViewController.swift
//  Docs
//
//  Created by xurunkang on 2018/8/20.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

#if DEBUG || BETA
import UIKit
import SpaceKit
import CreationLogger
import FLEX
import EENavigator
import LarkFeatureGating
import SKCommon
import SKFoundation
import LarkAppConfig


class DocsDebugViewController: DocsDebugBaseViewController {
    enum DataSourceSectionTitle: String {
        case userInfo = "用户信息"
        case log = "日志"
        case debugTools = "调试工具"
        case appEnv = "应用环境"
        case guideDebug = "引导调试"
        case simpleAndFullPkg = "精简和完整资源包"
        case exit = "轻轻的我走了, 正如我轻轻的来"
    }
    var fgService: LarkFeatureGating?

    enum CellTitle: String {
        case userInfo = "用户信息"
        case log = "日志"
        case debugTools = "调试工具"
        case appEnv = "应用环境"
        case guideDebug = "引导调试"
        case simpleAndFullPkg = "精简和完整资源包"
        case exit = "轻轻的我走了, 正如我轻轻的来"
    }
    
//    lazy var bitableAutoOpenManager: BitableAutoOpenTestManager = {
//        let bitableAutoOpenManager = BitableAutoOpenTestManager()
//        return bitableAutoOpenManager
//    }()
    
    init(fgService: LarkFeatureGating? = nil) {
        self.fgService = fgService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configDebugDataSource() {
        self.debugDataSouce.append((
            DataSourceSectionTitle.userInfo.rawValue,
            [
                DocsDebugCellItem(title: "UserID", type: .id, detail: User.current.info?.userID ?? "你猜"),
                DocsDebugCellItem(title: "DeviceID", type: .id, detail: AppUtil.shared.deviceID),
                DocsDebugCellItem(title: "InstallID", type: .id, detail: AppUtil.shared.installID),
                DocsDebugCellItem(title: "离线资源包版本", type: .id, detail: DocsSDK.offlineResourceVersion() ?? ""),
                DocsDebugCellItem(title: "SpaceKitVersion", type: .id, detail: SpaceKit.version),
                DocsDebugCellItem(title: "AppVersion", type: .id, detail: getAppVersion())
            ]
        ))

        self.debugDataSouce.append((
            DataSourceSectionTitle.log.rawValue,
            [
                DocsDebugCellItem(title: "上传日志"),
                DocsDebugCellItem(title: "查看日志"),
                DocsDebugCellItem(title: "控制台筛选器")
            ]
        ))

        self.debugDataSouce.append((
            DataSourceSectionTitle.debugTools.rawValue,
            [
                DocsDebugCellItem(title: "FLEX 调试", type: .switchButton(isOn: DocsDebugConstant.isFlexOn, tag: DocsDebugConstant.SwitchButtonTag.flex.rawValue)),
                DocsDebugCellItem(title: "vConsole 调试", type: .switchButton(isOn: DocsDebugConstant.isVconsoleEnable, tag: DocsDebugConstant.SwitchButtonTag.vconsoleEnable.rawValue)),
                DocsDebugCellItem(title: "FPS测试工具", type: .switchButton(isOn: isFPSMonitorExist(), tag: DocsDebugConstant.SwitchButtonTag.fpsEnable.rawValue)),
                DocsDebugCellItem(title: "Slide字体下载", type: .switchButton(isOn: DocsDebugConstant.showSlideFontDownload, tag: DocsDebugConstant.SwitchButtonTag.slideShowDownload.rawValue)),
                DocsDebugCellItem(title: "统一跳转"),
                DocsDebugCellItem(title: DebugCellTitle.cleanDriveCache.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.driveLocalPreview.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.cleanWikiDb.rawValue, type: .id),
                DocsDebugCellItem(title: "Drive性能测试工具", type: .switchButton(isOn: false, tag: DocsDebugConstant.SwitchButtonTag.driveTest.rawValue)),
                DocsDebugCellItem(title: DebugCellTitle.larkFGDebug.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.minaFGDebug.rawValue, type: .id),
                DocsDebugCellItem(title: "关闭wiki目录树协同", type: .switchButton(isOn: DocsDebugConstant.isShutdownedWikiTreeSync, tag: DocsDebugConstant.SwitchButtonTag.wikiTreeSync.rawValue)),
                DocsDebugCellItem(title: "打开wiki目录树节点areaId和sortId", type: .switchButton(isOn: DocsDebugConstant.shouldShowWikiTreeNodeDetail,
                                                                                              tag: DocsDebugConstant.SwitchButtonTag.wikiTreeNodeDetail.rawValue))
            ]
        ))

        self.debugDataSouce.append((
            DataSourceSectionTitle.appEnv.rawValue,
            [
                DocsDebugCellItem(title: "研发环境", type: .id, detail: ConfigurationManager.shared.env.descriptionText),
                DocsDebugCellItem(title: "QM账号",
                                  type: .switchButton(isOn: UserDefaults.standard.bool(forKey: UserDefaultKeys.isQMAccount),
                                                      tag: DocsDebugConstant.SwitchButtonTag.isQMAccount.rawValue)),
                DocsDebugCellItem(title: "使用本地离线资源包", type: .switchButton(isOn: DocsDebugConstant.isProtocolEnable, tag: DocsDebugConstant.SwitchButtonTag.protocolEnable.rawValue)),
                DocsDebugCellItem(title: "代理到前端", type: .switchButton(isOn: DocsDebugConstant.isAgentToFrontend, tag: DocsDebugConstant.SwitchButtonTag.isSetAgentToFrontend.rawValue)),
                DocsDebugCellItem(title: "Gecko 资源拉取", type: .switchButton(isOn: DocsDebugConstant.isGeckoApplyDisable, tag: DocsDebugConstant.SwitchButtonTag.geckoEnable.rawValue)),
                DocsDebugCellItem(title: "统计数据上报加密", type: .switchButton(isOn: DocsDebugConstant.isEnableStatisticsEncryption,
                                                                              tag: DocsDebugConstant.SwitchButtonTag.enableStatisticsEnctyption.rawValue)),
                DocsDebugCellItem(title: "使用指定离线资源包(重启后生效)", type: .switchButton(isOn: DocsDebugConstant.isCustomOfflineResourceEnable,
                                                                                          tag: DocsDebugConstant.SwitchButtonTag.enableCustomOfflineResourceEnable.rawValue)),
                DocsDebugCellItem(title: "使用指定注入js url", type: .switchButton(isOn: DocsDebugConstant.isUseThirdPartyJavascriptEnable,
                tag: DocsDebugConstant.SwitchButtonTag.enableCustomThirdPartyJavascriptEnable.rawValue)),
                DocsDebugCellItem(title: "使用远端RN包", type: .switchButton(isOn: DocsDebugConstant.useRemoteRNResource, tag: DocsDebugConstant.SwitchButtonTag.useRemoteRNResource.rawValue)),
                DocsDebugCellItem(title: "代理到RN(先启用远端)", type: .switchButton(isOn: DocsDebugConstant.remoteRNAddress, tag: DocsDebugConstant.SwitchButtonTag.remoteRNAddress.rawValue))
            ]
        ))

        self.debugDataSouce.append((
            DataSourceSectionTitle.guideDebug.rawValue,
            [
                DocsDebugCellItem(title: "清空引导缓存，不将完成情况同步到远端", type: .switchButton(isOn: DocsDebugConstant.verifiesAllOnboardings,
                                                                                              tag: DocsDebugConstant.SwitchButtonTag.verifiesAllOnboardings.rawValue)),
                DocsDebugCellItem(title: "Space 新手引导（需要清空缓存）", type: .switchButton(isOn: DocsDebugConstant.homeNewerGuideEnable,
                                                                                              tag: DocsDebugConstant.SwitchButtonTag.homeNewerGuideEnable.rawValue))
            ]
        ))

        let curResInfo = DocsSDK.getCurUsingPkgInfo()
        self.debugDataSouce.append((
              DataSourceSectionTitle.simpleAndFullPkg.rawValue,
              [
                DocsDebugCellItem(title: "当前是否在用精简包", type: .id, detail: "\(curResInfo.isSlim)"),
                DocsDebugCellItem(title: "当前使用的资源包版本", type: .id, detail: "\(curResInfo.version)"),
                DocsDebugCellItem(title: "当前使用包名称", type: .id, detail: "\(curResInfo.name)"),
                DocsDebugCellItem(title: "内嵌精简包版本", type: .id, detail: "\(curResInfo.simplePkgVersion)"),
                DocsDebugCellItem(title: "内嵌精简包对应的完整包版本", type: .id, detail: "\(curResInfo.fullPkgVersion)"),
                DocsDebugCellItem(title: "当前手动指定的资源包版本", type: .id, detail: "\(curResInfo.specialVersion)"),

                DocsDebugCellItem(title: DebugCellTitle.specialPkgInfo.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.grayscalePkgInfo.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.geckoPkgInfo.rawValue, type: .id),
                DocsDebugCellItem(title: "内嵌完整包是否ready", type: .id, detail: "\(curResInfo.fullPkgIsReady)"),
                DocsDebugCellItem(title: "灰度包是否ready", type: .id, detail: "\(curResInfo.isGrayscaleExist)"),
                DocsDebugCellItem(title: "灰度包版本", type: .id, detail: "\(curResInfo.grayscaleVersion)"),
                DocsDebugCellItem(title: DebugCellTitle.removeLocalFullPkgResource.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.removeLocalGrayscalePkgResource.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.forceUseSimplePkg.rawValue,
                                  type: .switchButton(isOn: DocsDebugConstant.isUseSimplePackage,
                                                      tag: DocsDebugConstant.SwitchButtonTag.useSimpleFEPackage.rawValue))

              ]
          ))

        self.debugDataSouce.append((
            DataSourceSectionTitle.exit.rawValue,
            [
                DocsDebugCellItem(title: "返回", type: .back)
            ]
        ))
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let data = debugDataSouce[indexPath.section]
        let cellItem = cellItemFor(indexPath)
        let sectionTitle = data.0
        if sectionTitle == DataSourceSectionTitle.userInfo.rawValue { // 用户信息
            didSelectUserInfo(indexPath: indexPath)
        } else if sectionTitle == DataSourceSectionTitle.log.rawValue { // 日志相关
            didSelectLog(indexPath: indexPath)
        } else if sectionTitle == DataSourceSectionTitle.debugTools.rawValue { // 调试工具
            if cellItem.title == DebugCellTitle.driveLocalPreview.rawValue {
                gotoDriveLocalPreview()
            } else if cellItem.title == DebugCellTitle.larkFGDebug.rawValue {
                let vc = FGDebugVC()
                vc.modalPresentationStyle = .fullScreen
                Navigator.shared.present(UINavigationController(rootViewController: vc))
            } else if cellItem.title == DebugCellTitle.minaFGDebug.rawValue {
                let nav = UINavigationController(rootViewController: MinaFGVC())
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            } else {
                didSelectDebugTool(indexPath: indexPath)
            }
        } else if sectionTitle == DataSourceSectionTitle.appEnv.rawValue {
            didSelectEnv(indexPath: indexPath)
        } else if sectionTitle == DataSourceSectionTitle.simpleAndFullPkg.rawValue {
            if cellItem.title == DebugCellTitle.removeLocalFullPkgResource.rawValue {
                removeFullPkgFiles()
            } else if cellItem.title == DebugCellTitle.removeLocalGrayscalePkgResource.rawValue {
                removeGrayscalePkgFiles()
            } else if cellItem.title == DebugCellTitle.specialPkgInfo.rawValue {
                showSpecialPkgInfo()
            } else if cellItem.title == DebugCellTitle.grayscalePkgInfo.rawValue {
                showGrayscalePkgInfo()
            } else if cellItem.title == DebugCellTitle.geckoPkgInfo.rawValue {
                showGeckoPkgInfo()
            }
        } else if sectionTitle == DataSourceSectionTitle.exit.rawValue { // 退出按钮
            didSelectBack()
        }
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            cell.isUserInteractionEnabled = true
            cell.contentView.alpha = 1.0
    }
    // swiftlint:disable cyclomatic_complexity
    @objc
    override func didClickSwitchButton(sender: UISwitch) {
        switch sender.tag {
        case DocsDebugConstant.SwitchButtonTag.flex.rawValue:
            switchFLEXManager()
        case DocsDebugConstant.SwitchButtonTag.fpsEnable.rawValue:
            openFPSMonitor(sender.isOn)
        case DocsDebugConstant.SwitchButtonTag.protocolEnable.rawValue:
            OpenAPI.offlineConfig.protocolEnable = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.geckoEnable.rawValue:
            OpenAPI.offlineConfig.geckoFetchEnable = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.vconsoleEnable.rawValue:
            VconsoleManager.switchState = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.enableStatisticsEnctyption.rawValue:
            OpenAPI.enableStatisticsEncryption = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.isSetAgentToFrontend.rawValue:
            OpenAPI.docs.isSetAgentToFrontend = sender.isOn
            if sender.isOn {
                showAgentToFrontendAlert()
            }
        case DocsDebugConstant.SwitchButtonTag.enableCustomOfflineResourceEnable.rawValue:
            showCustomOfflineResourceAlert(sender)
        case DocsDebugConstant.SwitchButtonTag.enableCustomThirdPartyJavascriptEnable.rawValue:
            showCustomJavascriptResourceAlert(sender)
        case DocsDebugConstant.SwitchButtonTag.isSetAgentToFrontend.rawValue:
            OpenAPI.docs.isSetAgentToFrontend = sender.isOn
            if sender.isOn {
                showAgentToFrontendAlert()
            }
        case DocsDebugConstant.SwitchButtonTag.bitableTest.rawValue:
            autoTestOpenBitable(isOn: sender.isOn)
        case DocsDebugConstant.SwitchButtonTag.slideShowDownload.rawValue:
            OpenAPI.docs.slideShowDownload = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.homeNewerGuideEnable.rawValue:
            OpenAPI.docs.homeNewerGuideEnable = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.verifiesAllOnboardings.rawValue:
            OpenAPI.docs.verifiesAllOnboardings = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.driveTest.rawValue:
            autoTestOpenDrive(isOn: sender.isOn)
        case DocsDebugConstant.SwitchButtonTag.wikiTreeSync.rawValue:
            shutdownWikiTreeSync(isOn: sender.isOn)
        case DocsDebugConstant.SwitchButtonTag.wikiTreeNodeDetail.rawValue:
            showWikiTreeNodeDetail(isOn: sender.isOn)
        case DocsDebugConstant.SwitchButtonTag.useRemoteRNResource.rawValue:
            OpenAPI.docs.remoteRN = sender.isOn
            if sender.isOn == false {
                UserDefaults.standard.setValue(nil, forKey: "RCTDevMenu")
            }
        case DocsDebugConstant.SwitchButtonTag.remoteRNAddress.rawValue:
            if sender.isOn {
                showRemoteRNAddressAlert()
            } else {
                OpenAPI.docs.RNHost = ""
                OpenAPI.docs.remoteRNAddress = false
            }
        case DocsDebugConstant.SwitchButtonTag.isQMAccount.rawValue:
            UserDefaults.standard.set(sender.isOn, forKey: UserDefaultKeys.isQMAccount)
        case DocsDebugConstant.SwitchButtonTag.useSimpleFEPackage.rawValue:
            SpecialVersionResourceService.updateIsUseSimplePackage(on: sender.isOn)
        default: break
        }
    }
}
#endif

//
//  VersionManager+TFUpgrade.swift
//  LarkVersion
//
//  Created by ByteDance on 2023/4/17.
//

import Foundation

extension VersionManager {
    // 显示TF升级弹窗
    func showUpgradeTFAlert(urlString: String,
                            showLater: Bool,
                            isTestFlight: Bool,
                            mainWindow: UIWindow) {
        Self.logger.info("new version: Show tf updagrade alert view")

        if let controller = self.alertController {
            controller.dismiss(animated: false, completion: nil)
            Self.logger.info("new version: There's already a tf alert view and remove it")
        }

        let laterTitle = isTestFlight ?
        BundleI18n.LarkVersion.Lark_Core_BetaVersionInvitation_WeakPromptWithTF_Later_Button() :
          BundleI18n.LarkVersion.Lark_Legacy_UpgradeLater
        let upgradeTitle = isTestFlight ? upgradeTextTF() : BundleI18n.LarkVersion.Lark_Legacy_immediate
        self.showUpgradeAlertUI(title: titleTF(),
                              note: descTF(),
                              showLater: showLater,
                              laterTitle: laterTitle,
                              laterHandler: { [weak self] in
            self?.laterTF()
        }, upgradeTitle: upgradeTitle, upgradeHandler: { [weak self] in
            self?.upgradeTF(with: urlString)
        }, mainWindow: mainWindow)

        TrackTestflight()
    }

    // 获取TestFlight更新Title
    func titleTF() -> String {
        var title = ""
        if (isTFAppInstalled()) {
            // 已安装TestFlight，飞书（非飞书）弹框引导下载的TestFlight
            title = self.hasDownloadedTF ?
            BundleI18n.LarkVersion.Lark_Core_BetaVersionInvitation_StrongPromptWithTF_Title() :
            BundleI18n.LarkVersion.Lark_Core_BetaVersionInvitation_WeakPromptWithTF_Title()
            if (self.versionInfo?.testFlightNotice == .emergency) {
                title = self.hasDownloadedTF ?
                BundleI18n.LarkVersion.Lark_Core_UpgradeRequired_StrongPromptWithTF_Title() :
                BundleI18n.LarkVersion.Lark_Core_UpgradeRequired_WeakPromptWithTF_Title()
            }
        } else {
            // 未安装TestFlight
            title = BundleI18n.LarkVersion.Lark_Core_BetaVersionInvitation_StrongPromptWithoutTF_Title()
            if (self.versionInfo?.testFlightNotice == .emergency) {
                title = BundleI18n.LarkVersion.Lark_Core_UpgradeRequired_StrongPromptWithoutTF_Title()
            }

        }
        return title
    }
    
    // 获取TestFlight更新Desc
    func descTF() -> String {
        var desc = ""
        if (isTFAppInstalled()) {
            // 已安装TestFlight，飞书（非飞书）弹框引导下载的TestFlight
            desc = self.hasDownloadedTF ?
            BundleI18n.LarkVersion.Lark_Core_BetaVersionInvitation_StrongPromptWithTF_Desc() :
            BundleI18n.LarkVersion.Lark_Core_BetaVersionInvitation_WeakPromptWithTF_Desc()
            if (self.versionInfo?.testFlightNotice == .emergency) {
                desc = self.hasDownloadedTF ?
                BundleI18n.LarkVersion.Lark_Core_UpgradeRequired_StrongPromptWithTF_Desc() :
                BundleI18n.LarkVersion.Lark_Core_UpgradeRequired_WeakPromptWithTF_Desc()
            }
        } else {
            // 未安装TestFlight
            desc = BundleI18n.LarkVersion.Lark_Core_BetaVersionInvitation_StrongPromptWithoutTF_Desc()
            if (self.versionInfo?.testFlightNotice == .emergency) {
                desc = BundleI18n.LarkVersion.Lark_Core_UpgradeRequired_StrongPromptWithoutTF_Desc()
            }

        }
        return desc
    }
    
    /// upgrade点击事件
    func upgradeTF(with urlString: String) {
        Self.logger.info("new version: User chooses tf upgrade")
        self.upgradeLastTapLaterTime = Date().timeIntervalSince1970
        
        guard isTFAppInstalled() else {
            // 跳转到appstore的testflight的下载页面
            var tfUpgradeUrl: String
            if let versionSetting = getVersionSettingConfig(),
                let url = versionSetting[VersionManager.tfDownloadUrlKey] as? String,
               !url.isEmpty {
                tfUpgradeUrl = url
            }else {
                tfUpgradeUrl = VersionManager.tfDownloadUrl
            }
            
            UpgradeTracker.trackPublicTestflightDownloadClick(clickType: .appstoreClick)
            self.hasDownloadedTF = true
            self.openUpgradeURL(with: tfUpgradeUrl)
            return
        }
        // 跳转到testflight的飞书下载页面
        if (self.hasDownloadedTF) {
            UpgradeTracker.trackPublicTestflightDownloadAfterClick(clickType: .downloadClick)
        } else {
            UpgradeTracker.trackPublicDemoDownloadClick(clickType: .downloadClick)
        }
        self.openUpgradeURL(with: urlString)
    }
    
    /// later点击事件
    func laterTF() {
        Self.logger.info("new version: User chooses tf later")
        self.upgradeLastTapLaterTime = Date().timeIntervalSince1970
        if (isTFAppInstalled()) {
            if (self.hasDownloadedTF) {
                UpgradeTracker.trackPublicTestflightDownloadAfterClick(clickType: .cancleClick)
            }
            else {
                UpgradeTracker.trackPublicDemoDownloadClick(clickType: .cancleClick)
            }
        } else {
            UpgradeTracker.trackPublicTestflightDownloadClick(clickType: .cancleClick)
        }
        self.isCancelTFAlert = true
    }
    
    // upgrade按钮文案
    func upgradeTextTF() -> String {
        Self.logger.info("new version: isTestFlightVersion: \(isTestFlightVersion())")

        var upgradeDesc = ""
        if (isTFAppInstalled()) {
            // 已安装TestFlight，飞书（非飞书）弹框引导下载的TestFlight
            upgradeDesc = self.hasDownloadedTF ?
            BundleI18n.LarkVersion.Lark_Core_BetaVersionInvitation_StrongPromptWithTF_InstallNow_Button() :
            BundleI18n.LarkVersion.Lark_Core_BetaVersionInvitation_WeakPromptWithTF_InstallNow_Button()
            if (isTestFlightVersion()) {
                upgradeDesc = self.hasDownloadedTF ?
                BundleI18n.LarkVersion.Lark_Core_UpgradeRequired_StrongPromptWithTF_UpgradeNow_Button() :
                BundleI18n.LarkVersion.Lark_Core_UpgradeRequired_WeakPromptWithTF_UpgradeNow_Button()
            }
        } else {
            // 未安装TestFlight
            upgradeDesc = BundleI18n.LarkVersion.Lark_Core_BetaVersionInvitation_StrongPromptWithoutTF_AppStore_Button()
            if (isTestFlightVersion()) {
                upgradeDesc = BundleI18n.LarkVersion.Lark_Core_UpgradeRequired_StrongPromptWithoutTF_AppStore_Button()
            }
        }
        return upgradeDesc
    }
    
    // 升级弹窗弹出埋点上报
    func TrackTestflight() {
        // 是否有TestFlight APP
        if (isTFAppInstalled()) {
            // 通过引导下载的TestFlight
            if (self.hasDownloadedTF) {
                UpgradeTracker.trackPublicTestflightDownloadAfterView()
            } else {
                UpgradeTracker.trackPublicDemoDownloadView()
            }
            self.isShowTFAlert = true
        } else {
            UpgradeTracker.trackPublicTestflightDownloadView()
        }
    }
    
    // 是否有TestFlight
    func isTFAppInstalled() -> Bool {
        if let url = NSURL(string: "itms-beta://") {
            return UIApplication.shared.canOpenURL(url as URL)
        }
        return false
    }
    
    // 是否是TestFlight下载的飞书版本
    private func isTestFlightVersion() -> Bool {
        let channelTF = Bundle.main.infoDictionary?["DOWNLOAD_CHANNEL"] as? String ?? ""
        return channelTF == "testflight"
    }
}

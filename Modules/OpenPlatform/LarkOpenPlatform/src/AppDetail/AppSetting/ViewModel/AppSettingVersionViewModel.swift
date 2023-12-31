//
//  AppSettingVersionViewModel.swift
//  LarkAppCenter
//
//  Created by tujinqiu on 2020/2/5.
//

import UIKit
import Swinject
import LarkLocalizations
import EEMicroAppSDK
import LKCommonsLogging
import LarkOPInterface
import LarkContainer

enum AppSettingVersionState {
    case fetchingMeta
    case metaFailed
    case hasNewVersion
    case downloading
    case downloadFailed
    case restart
    case newest
}

protocol AppSettingVersionViewModelDelegate: AnyObject {
    func versionViewModelChanged()
    func versionViewModelVersionStateChanged()
    func restartApp(appID: String)
}

class AppSettingVersionViewModel {
    static let logger = Logger.oplog(AppSettingVersionViewModel.self, category: "app_setting")
    /// 单独分区的间隔距离
    static let marginInset: CGFloat = 8.0
    static var cellHeight: CGFloat = 60
    // 按钮显示多行的情况
    static var largeCellHeight: CGFloat = 70
    static var maxBtnWidth: CGFloat = 142

    private let resolver: UserResolver
    var appID: String
    var scene : AppSettingOpenScene
    var latestVersion: String?
    /// 是否需要展示单独的间隔
    var isShowMarginInset: Bool = true
    private var hasGetAppMeta = false
    var didUserClickUprade: Bool = false
    // 是否已经记录和检查更新埋点，fetchmetaanddownload会多次回调状态
    var didTrackNotNewCheckResult: Bool = false
    var isFirstUpgrade : Bool = true
    var version: String = "" {
        didSet {
            Self.logger.info("app setting versionViewModel set version:\(version)")
            delegate?.versionViewModelChanged()
        }
    }

    var state: AppSettingVersionState {
        didSet {
            Self.logger.info("app setting versionViewModel set state:\(state)")
            delegate?.versionViewModelVersionStateChanged()
            if state == .restart {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.25) {
                    self.delegate?.restartApp(appID: self.appID)
                }
            }
        }
    }

    var microAppUpdateStatus: MicroAppUpdateStatus = .none
    weak var delegate: AppSettingVersionViewModelDelegate?

    init(appID: String, scene: AppSettingOpenScene, resolver: UserResolver) {
        self.resolver = resolver
        self.appID = appID
        self.scene = scene
        self.state = .fetchingMeta
    }

    func fetchMeta() {
        Self.logger.info("app setting versionViewModel fetch Meta")
        if self.scene == .H5 {
            // 网页应用不需要请求小程序包管理，直接使用关于页接口的版本号
            self.state = .newest
            return
        }
        self.state = .fetchingMeta
        if let service = try? resolver.resolve(assert: MicroAppService.self) {
            service.fetchMetaAndDownload(appID: appID, statusChanged: { (status, latestVersion) in
                Self.logger.info("app setting versionViewModel fetch Meta result,status:\(status),version:\(latestVersion)")
                self.microAppUpdateStatus = status
                switch self.microAppUpdateStatus {
                case .none, .fetchingMeta:
                    self.state = .fetchingMeta
                case .metaFailed:
                    self.state = .metaFailed
                case .newestVersion:
                    self.state = .newest
                case .downloading:
                    // fetchMetaAnddownload 返回的loading相关状态，在用户未点击时均模拟为hasNewVersion
                    self.state = self.didUserClickUprade ? .downloading : .hasNewVersion
                case .downloadSuccess:
                    self.state = self.didUserClickUprade ? .restart : .hasNewVersion
                case .downloadFailed:
                    self.state = self.didUserClickUprade ? .downloadFailed : .hasNewVersion
                }
                self.latestVersion = latestVersion
                self.handleMonitorEvent()
            })
        }
    }

    func download() {
        Self.logger.info("app setting versionViewModel download")
        if let service = try? resolver.resolve(assert: MicroAppService.self) {
            service.download(appID: appID, statusChanged: { (status, latestVersion) in
                self.microAppUpdateStatus = status
                switch self.microAppUpdateStatus {
                case .none, .fetchingMeta:
                    self.state = .fetchingMeta
                case .metaFailed:
                    self.state = .metaFailed
                case .newestVersion:
                    self.state = .newest
                case .downloading:
                    self.state = .downloading
                case .downloadSuccess:
                    self.state = .restart
                case .downloadFailed:
                    self.state = .downloadFailed
                }
                self.latestVersion = latestVersion
                self.handleMonitorEvent()
            })
        }
    }

    private func handleMonitorEvent() {
        // 首次获取meta信息
        if self.state != .fetchingMeta,
            self.hasGetAppMeta == false,
            let latestVersion = self.latestVersion {
            self.hasGetAppMeta = true
            AppDetailUtils(resolver: resolver).internalDependency?.post(eventName: AppDetailMonitorName.gadget_about_enter, params: [
                "app_id": self.appID,
                "current_version": self.version,
                "latest_version": latestVersion
            ])
        }
        // 显示重启按钮
        if self.state == .hasNewVersion, let latestVersion = self.latestVersion {
            AppDetailUtils(resolver: resolver).internalDependency?.post(eventName: AppDetailMonitorName.gadget_about_show_restart, params: [
                "app_id": self.appID,
                "latest_version": latestVersion
            ])
        }
        // 显示失败按钮
        if self.state == .downloadFailed, let latestVersion = self.latestVersion {
            AppDetailUtils(resolver: resolver).internalDependency?.post(eventName: AppDetailMonitorName.gadget_about_show_download_failed, params: [
                "app_id": self.appID,
                "latest_version": latestVersion
            ])
        }
        // 埋点
        if self.microAppUpdateStatus == .downloadSuccess {
            if self.didUserClickUprade {
                OPMonitor("openplatform_application_about_click")
                    .addCategoryValue("app_type", appTypeString())
                    .addCategoryValue("click", "upgrade_result")
                    .addCategoryValue("target", "none")
                    .addCategoryValue("result", "success")
                    .addCategoryValue("application_id", appID)
                    .setPlatform([.tea, .slardar])
                    .flush()
            }
        }
        switch self.state {
        case.fetchingMeta:
            break;
        case .metaFailed:
            OPMonitor("openplatform_application_about_click")
                .addCategoryValue("app_type", appTypeString())
                .addCategoryValue("click", "version_check_result")
                .addCategoryValue("target", "none")
                .addCategoryValue("application_id", appID)
                .addCategoryValue("result", "failure")
                .setPlatform([.tea, .slardar])
                .flush()
        case .hasNewVersion:
            if !self.didTrackNotNewCheckResult {
                OPMonitor("openplatform_application_about_click")
                    .addCategoryValue("app_type", appTypeString())
                    .addCategoryValue("click", "version_check_result")
                    .addCategoryValue("target", "none")
                    .addCategoryValue("application_id", appID)
                    .addCategoryValue("result", "not_new")
                    .setPlatform([.tea, .slardar])
                    .flush()
                self.didTrackNotNewCheckResult = true
            }
        case .downloading:
            break;
        case .downloadFailed:
            if self.didUserClickUprade {
                OPMonitor("openplatform_application_about_click")
                    .addCategoryValue("app_type", appTypeString())
                    .addCategoryValue("click", "upgrade_result")
                    .addCategoryValue("target", "none")
                    .addCategoryValue("result", "fail")
                    .addCategoryValue("application_id", appID)
                    .setPlatform([.tea, .slardar])
                    .flush()
            }
        case .restart:
            break;
        case .newest:
            OPMonitor("openplatform_application_about_click")
                .addCategoryValue("app_type", appTypeString())
                .addCategoryValue("click", "version_check_result")
                .addCategoryValue("target", "none")
                .addCategoryValue("application_id", appID)
                .addCategoryValue("result", "new")
                .setPlatform([.tea, .slardar])
                .flush()
        }
    }

    func getCellHeight() -> CGFloat {
        let cellHeight = shouldShowDoubleLine() ? AppSettingVersionViewModel.largeCellHeight : AppSettingVersionViewModel.cellHeight
        return  isShowMarginInset ? cellHeight : cellHeight - AppSettingVersionViewModel.marginInset
    }

    /// 是否显示两行：非中文语言显示两行（其他语言的长度不太确定，分最多两行显示，避免过早长度溢出）
    func shouldShowDoubleLine() -> Bool {
        let currentLanguage = LanguageManager.currentLanguage
        if currentLanguage != .zh_CN {
            if microAppUpdateStatus == .downloading ||
                microAppUpdateStatus == .downloadSuccess ||
                microAppUpdateStatus == .downloadFailed ||
                microAppUpdateStatus == .metaFailed {
                return true
            }
        }
        return false
    }

    func didUserClickedStateView(){
        switch self.state {
        case .fetchingMeta:
            break
        case .metaFailed:
            OPMonitor("openplatform_application_about_click")
                .addCategoryValue("app_type", appTypeString())
                .addCategoryValue("click", "version_recheck")
                .addCategoryValue("target", "none")
                .addCategoryValue("application_id", appID)
                .setPlatform([.tea, .slardar])
                .flush()
            fetchMeta()
            self.state = .fetchingMeta
        case .hasNewVersion:
            let is_first_time = self.isFirstUpgrade ? "true" : "false"
            OPMonitor("openplatform_application_about_click")
                .addCategoryValue("app_type", appTypeString())
                .addCategoryValue("click", "upgrade")
                .addCategoryValue("target", "none")
                .addCategoryValue("is_first_time", is_first_time)
                .addCategoryValue("application_id", appID)
                .setPlatform([.tea, .slardar])
                .flush()
            if self.microAppUpdateStatus == MicroAppUpdateStatus.downloading {
                self.state = .downloading
            } else if self.microAppUpdateStatus == MicroAppUpdateStatus.downloadFailed {
                self.state = .downloadFailed
                if !self.didUserClickUprade {
                    OPMonitor("openplatform_application_about_click")
                        .addCategoryValue("app_type", appTypeString())
                        .addCategoryValue("click", "upgrade_result")
                        .addCategoryValue("target", "none")
                        .addCategoryValue("result", "fail")
                        .addCategoryValue("application_id", appID)
                        .setPlatform([.tea, .slardar])
                        .flush()
                }
            } else if (self.microAppUpdateStatus == MicroAppUpdateStatus.downloadSuccess || self.microAppUpdateStatus == MicroAppUpdateStatus.newestVersion)  {
                if !self.didUserClickUprade {
                    OPMonitor("openplatform_application_about_click")
                        .addCategoryValue("app_type", appTypeString())
                        .addCategoryValue("click", "upgrade_result")
                        .addCategoryValue("target", "none")
                        .addCategoryValue("result", "success")
                        .addCategoryValue("application_id", appID)
                        .setPlatform([.tea, .slardar])
                        .flush()
                }
                self.state = .restart
            }
            if let lVersion = latestVersion {
                AppDetailUtils(resolver: resolver).internalDependency?.post(eventName: AppDetailMonitorName.gadget_about_tap_restart, params: [
                    "app_id": self.appID,
                    "latest_version": lVersion
                ])
            }
            self.didUserClickUprade = true
        case .downloading:
            break
        case .downloadFailed:
            self.isFirstUpgrade = false
            self.state = .downloading
            let is_first_time = self.isFirstUpgrade ? "true" : "false"
            OPMonitor("openplatform_application_about_click")
                .addCategoryValue("app_type", appTypeString())
                .addCategoryValue("click", "upgrade")
                .addCategoryValue("target", "none")
                .addCategoryValue("is_first_time", is_first_time)
                .addCategoryValue("application_id", appID)
                .setPlatform([.tea, .slardar])
                .flush()
            download()
            // 点击失败按钮
            if let lVersion = latestVersion {
                AppDetailUtils(resolver: resolver).internalDependency?.post(eventName: AppDetailMonitorName.gadget_about_tap_download_failed, params: [
                    "app_id": self.appID,
                    "latest_version": lVersion
                ])
            }
        case .restart:
            break
        case .newest:
            break
        }
    }

    private func appTypeString() -> String {
        let appType: String
        switch scene {
        case .H5:
            appType = "web_app"
        case .MiniApp:
            appType = "mp"
        }
        return appType
    }
}

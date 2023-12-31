//
//  VersionManager.swift
//  LarkVersion
//
//  Created by 姚启灏 on 2018/8/21.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxCocoa
import LarkUIKit
import LarkContainer
import EENavigator
import LarkNavigator
import LarkSDKInterface
import LKCommonsLogging
import LarkAccountInterface
import RustPB
import LarkStorage
import LKCommonsTracker
import Homeric
import LarkFeatureGating
import LarkSetting
import LarkDialogManager

enum LarkUpgradeType: String {
    case versionUpgrade                //appstore包升级到appstore包、inhouse包升级到inhouse包
    case testflightUpgrade             //appstore包(testflight包)升级到testflight包
}

final class VersionManager {
    static var logger = Logger.log(VersionManager.self, category: "LarkVersion")
    static let requestField = UserSettingKey.make(userKeyLiteral: "version_update_config")
    static let tfDownloadUrl = "https://beta.itunes.apple.com"
    static let tfDownloadUrlKey = "testflight_download_url"

    var versionInfo: RustPB.Basic_V1_GetNewVersionResponse?
    var hasDownloadedTF: Bool = false  // 是否是当次启动下载的TestFlight APP
    var isShowTFAlert: Bool = false    // 是否已经展示过有TestFlight的弹框逻辑
    var isCancelTFAlert: Bool = false  // 是否手动关闭TF引导弹框

    let userResolver: UserResolver
    let dialogManager: DialogManagerService
    private let dependency: LarkVersionDependency
    private let disposeBag = DisposeBag()
    private let minVersionRequestInterval: Double = 10 // 两次请求默认间隔10s
    private let minPopupInterval: Double = (30 * 60) // 两次弹窗默认间隔30min
    private let popupDelayTime: Double = (1.0) // 弹窗延迟触发时长1s

    private var versionLastRequestTime: Double = 0// 上次请求version数据成功的时间戳
    private var hasShownAlert: Bool = false
    private var popupMode: UpgradePopupMode = .auto
    private var upgradeType: LarkUpgradeType = .versionUpgrade
    private var appStoreReceiptURL: URL?
    private var featureGatingService: FeatureGatingService?

    // 记录上次的 AlertController
    weak var alertController: UIViewController?

    let versionHelper: VersionControlHelper

    var shouldUpdate: Bool = false {
        didSet {
            isShouldUpdate.onNext(shouldUpdate)
        }
    }
    var isShouldUpdate: BehaviorSubject<Bool> = BehaviorSubject<Bool>(value: false)

    private var shouldNotice: Bool = false {
        didSet {
            shouldNoticeVar.onNext(shouldNotice)
        }
    }
    var shouldNoticeVar: BehaviorSubject<Bool> = BehaviorSubject<Bool>(value: false)

    private var alwaysNotice: Bool = false

    @KVConfig(key: KVKeys.Version.lastUpgradeTapLaterTime, store: KVStores.Version.glboal)
    var upgradeLastTapLaterTime: Double

    @KVConfig(key: KVKeys.Version.lastRemoveUpdateNoticeVersion, store: KVStores.Version.glboal)
    var lastRemoveNoticeVersion: String

    @KVConfig(key: KVKeys.Version.lastUpdateShowAlertVersion, store: KVStores.Version.glboal)
    var lastUpdateShowAlertVersion: String

    init(userResolver: UserResolver, versionHelper: VersionControlHelper, dependency: LarkVersionDependency) throws {
        self.userResolver = userResolver
        self.dialogManager = try userResolver.resolve(assert: DialogManagerService.self)
        self.featureGatingService = try? self.userResolver.resolve(assert: FeatureGatingService.self)
        self.versionHelper = versionHelper
        self.dependency = dependency
    }

    private func updateLastRemoveNoticeVersion() {
        guard let version = versionInfo else {
            return
        }
        self.lastRemoveNoticeVersion = version.data.version
    }
}

extension VersionManager {
    func loadData() {
        Self.logger.info("new version: Trigger version update check in launch phase")
        observeNewVersionChanged(launchFirst: true)

        Self.logger.info("new version: Add version observer")
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                Self.logger.info("new version: Trigger version update check by enter foreground")
                switch self.upgradeType {
                case .testflightUpgrade:
                    guard self.featureGatingService?.staticFeatureGatingValue(with: "core.ios.testflight") == true else {
                        Self.logger.info("new version: fg core.ios.testflight close")
                        return
                    }
                    // tf弹窗逻辑：如果是弱引导，未安装TestFlight不弹框
                    if (self.versionInfo?.testFlightNotice == .weak &&
                        !self.isTFAppInstalled()) {
                        Self.logger.info("new version: testFlightNotice is weak")
                        return
                    }
                case .versionUpgrade: break
                }
                self.triggerVersionUpdateCheck()
            }).disposed(by: disposeBag)
    }

    func addCheckTrigger(_ trigger: VersionCheckTrigger) {
        trigger.observable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                Self.logger.info("check new version, source: \(trigger.source.rawValue)")
                guard let self = self else { return }
                self.triggerVersionUpdateCheck()
            })
            .disposed(by: disposeBag)
    }

    func tryToCleanUpNotice() {
        if shouldNotice, !alwaysNotice {
            shouldNotice = false
            updateLastRemoveNoticeVersion()
        }
    }

    /// 应用场景：用户在设置页中手动点击选项弹出「升级弹窗」
    /// 触发流程：设置 -> 关于飞书内测 -> 发现新版本
    /// 依赖前提：self.versionInfo 有新版数据时才可以被调用
    func updateLark() {
        Self.logger.info("new version: User call update")
        self.popupMode = .click
        showUpgradeAlert()
    }

    /// 暴露的供外部调用的升级弹窗的接口
    /// NOTE: 不要在此添加业务条件过滤
    func showUpgradeAlert() {
        guard self.versionInfo?.hasNew_p ?? false else {
            Self.logger.info("new version: Check version info failed. Cannot show alert")
            return
        }
        prepareShowUpgradeAlert()
    }
}

// MARK: - Private Method
extension VersionManager {
    /// 拉取、检查是否有新版本
    /// - Parameter launchFirst: 代表是否为冷启动后首次触发
    private func observeNewVersionChanged(launchFirst: Bool = false) {
        guard let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self),
              featureGatingService.staticFeatureGatingValue(with: "suite_about_softwareupdate")
        else {
            Self.logger.info("No need fetch new version info, fg is false")
            return
        }
        versionHelper.getVersionInfo()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (info) in
                Self.logger.info("new version: Get new info, has new version: \(info.hasNew_p)")
                guard let `self` = self else { return }
                guard info.hasNew_p else {
                    self.resetVersionInfo()
                    return
                }

                self.versionInfo = info
                self.upgradeType = (self.versionInfo?.isTestFlight ?? false) ? .testflightUpgrade : .versionUpgrade
                self.versionLastRequestTime = Date().timeIntervalSince1970

                switch self.upgradeType {
                case .testflightUpgrade:
                    self.shouldUpdate = false
                    self.alwaysNotice = false
                    self.shouldNotice = false
                    guard self.featureGatingService?.staticFeatureGatingValue(with: "core.ios.testflight") == true else {
                        Self.logger.info("new version: fg core.ios.testflight close")
                        return
                    }
                    // tf弹窗逻辑：如果是弱引导，未安装TestFlight不弹框
                    if (info.testFlightNotice == .weak &&
                        !self.isTFAppInstalled()) {
                        Self.logger.info("new version: testFlightNotice is weak")
                        return
                    }
                    
                    // tf场景强制升级必弹窗
                    if self.isForceUpgrade() {
                        self.prepareShowUpgradeAlert()
                        return
                    }
                case .versionUpgrade:
                    if info.plan.noticePlan == 1 {
                        self.alwaysNotice = true
                        self.shouldNotice = true
                    } else {
                        // 是否显示通知，需要有新版本，且“version”通知没有消失过，同一版本不重复出现红点提醒
                        self.shouldNotice = self.lastRemoveNoticeVersion != info.data.version
                    }
                    self.shouldUpdate = true
                    // 强制升级弹窗仅冷启动触发
                    if self.isForceUpgrade() {
                        if (launchFirst) {
                            self.prepareShowUpgradeAlert()
                        } else {
                            Self.logger.info("new version: Force upgrade need first launch")
                        }
                        return
                    }
                }

                self.handleLaterUpgradeAlertOperation()
            }).disposed(by: self.disposeBag)
    }

    /// 避免接口下发的 versioninfo 由有到无，且当次进程没有关闭时，仍然会展示更新提醒的情况
    private func resetVersionInfo() {
        self.versionInfo = nil
        self.shouldUpdate = false
        self.alwaysNotice = false
        self.shouldNotice = false
    }

    private func handleLaterUpgradeAlertOperation() {
        guard let info = self.versionInfo else {
            Self.logger.info("new version: Check info failed in handle phase")
            return
        }

        // 带"稍后"弹窗的过滤条件
        guard self.canShowAlertOnCurrentVC() else {
            Self.logger.info("new version: Current page cannnot show later upgrade alert")
            return
        }
        
        switch self.upgradeType {
        case .testflightUpgrade:
            // tf强制升级必弹框
            if (self.isForceUpgrade()) {
                self.prepareShowUpgradeAlert()
                return
            }
        case .versionUpgrade: break
        }


        // popupPlan == 1 且 popup时间间隔大于最小周期，表示需要立即弹窗;
        // popupPlan == 2 且 当前版本未曾弹过窗，表示需要立即弹窗
        let popupInterval = self.getPopupInterval()
        let isNewAlertVersion = (self.lastUpdateShowAlertVersion != info.data.version)
        Self.logger.info("new version: PopupPlan = \(info.plan.popupPlan); " +
                         "PopupInterval = \(popupInterval)s(min=\(self.minPopupInterval)s); " +
                         "LastShowVersion = \(self.lastUpdateShowAlertVersion); " +
                         "NowShowVersion = \(info.data.version)")

        //popupPlan:1 多次弹窗，2 单次弹窗
        if info.plan.popupPlan == 1, popupInterval > self.minPopupInterval {
            self.prepareShowUpgradeAlert(delayTime: self.popupDelayTime, checkPosition: true)
        } else if info.plan.popupPlan == 2, isNewAlertVersion {
            self.prepareShowUpgradeAlert(delayTime: self.popupDelayTime, checkPosition: true)
        } else {
            Self.logger.info("new version: Skip alert by no valid popup plan")
        }
    }

    /// 启动中触发的版本检测操作
    private func triggerVersionUpdateCheck() {
        Self.logger.info("new version: Trigger version update check")

        // 当前没有正在显示的 alertController 或者其不在 window 上则重新请求新版本
        guard self.alertController == nil || self.alertController?.view.window == nil else {
            Self.logger.info("new version: Alert is showing or alert's window = nil")
            return
        }

        // 触发请求的判断条件：未展示过弹窗 + 大于最小弹窗间隔时长 + 合适的场景(Feed首页)
        let canPopup: Bool = getPopupInterval() > self.minPopupInterval
        let hasShown: Bool = self.hasShownAlert
        let canShow: Bool = canShowAlertOnCurrentVC()
        
        switch self.upgradeType {
        case .testflightUpgrade:
            if (canShow && !self.isCancelTFAlert) {
                //1.通过引导下载tf并且没安装tf，会一直弹窗
                if (self.hasDownloadedTF && !self.isTFAppInstalled()) {
                    self.prepareShowUpgradeAlert(delayTime: self.popupDelayTime, checkPosition: true)
                    return
                }
                //2.通过引导下载tf并且没有弹过tf弹窗，必弹一次弹窗
                if (self.hasDownloadedTF && !self.isShowTFAlert) {
                    self.prepareShowUpgradeAlert(delayTime: self.popupDelayTime, checkPosition: true)
                    return
                }
            }
        case .versionUpgrade:
            guard !hasShown, canPopup, canShow else {
                Self.logger.info("new version: No need to check version update. " +
                                 "< canPopup = \(canPopup); hasShownAlert = \(hasShown); correctPage = \(canShow) >")
                return
            }
        }
    
        // 本地数据若未过期则直接使用
        let needRequest: Bool = getVersionRequestInterval() > self.minVersionRequestInterval
        if needRequest {
            observeNewVersionChanged()
        } else {
            handleLaterUpgradeAlertOperation()
        }
    }

    /// 解析版本信息，决定‘是否’显示以及‘怎么’显示新本的提醒
    /// - Parameter delayTime: 显示‘延时’
    /// - Parameter checkPosition: 是否判断当前所处页面为Feed首页
    private func prepareShowUpgradeAlert(delayTime: Double = 0, checkPosition: Bool = false) {
        guard let info = self.versionInfo else {
            Self.logger.info("new version: Check info failed in preparation")
            return
        }

        let version = info.data.version
        let verStr = version.hasPrefix("iOS@") ? String(version.suffix(max(version.count - 4, 0))) : version
        let customTitle = info.plan.snoozePlan == 1 ? BundleI18n.LarkVersion.Lark_Legacy_UpgradeNewVersionTitle(verStr) :
                                                      BundleI18n.LarkVersion.Lark_Legacy_SafetyUpgradeNotesTitle

        dialogManager.addTask(task: DialogTask(onShow: { [weak self] in
            guard let self = self else {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                if checkPosition && !self.canShowAlertOnCurrentVC() {
                    Self.logger.info("new version: Prepare to show alert actively, but current page should not show")
                    return
                }

                guard let mainWindow = self.userResolver.navigator.mainSceneWindow else {
                    assertionFailure()
                    Self.logger.info("new version: Failed to read mainwindow")
                    return
                }

                switch self.upgradeType {
                case .testflightUpgrade:
                    self.showUpgradeTFAlert(urlString: info.data.downloadURL,
                                            showLater: !self.isForceUpgrade(),
                                            isTestFlight: info.isTestFlight,
                                            mainWindow: mainWindow)
                case .versionUpgrade:
                    UpgradeTracker.trackShowUpgradeView()

                    /// 如果是自动弹出的版本检测，需要先看管理员配置，再看版本更新内容
                    var note = info.data.releaseNotes
                    if (self.popupMode == .auto && !info.data.noticeContent.isEmpty) {
                        note = info.data.noticeContent
                    }
                    self.showUpgradeAlert(title: info.data.title.count > 0 ? info.data.title : customTitle,
                                          note: note,
                                          urlString: info.data.downloadURL,
                                          showLater: !self.isForceUpgrade(),
                                          mainWindow: mainWindow)
                }
            }
        }))
    }
    
    /// 显示升级弹窗
    ///
    /// - Parameters:
    ///   - subtitle: 弹窗副标题
    ///   - note: release note
    ///   - urlString: 升级的URL
    ///   - showLater: 是否显示“稍后”
    private func showUpgradeAlert(title: String,
                                  note: String,
                                  urlString: String,
                                  showLater: Bool,
                                  mainWindow: UIWindow) {
        Self.logger.info("new version: Show updagrade alert view")

        UpgradeTracker.trackPublicUpgradePopupView(popupType: (showLater ? .nonMandatoryUpgrade : .mandatoryUpgrade),
                                                   popupMode: self.popupMode)

        self.showUpgradeAlertUI(title: title,
                              note: note,
                              showLater: showLater,
                              laterHandler: { [weak self] in
            UpgradeTracker.trackPublicUpgradePopupClick(popupClick: .cancel,
                                                        popupType: (showLater ? .nonMandatoryUpgrade : .mandatoryUpgrade),
                                                        popupMode: self?.popupMode ?? .auto)
            self?.later()
        }, upgradeHandler: { [weak self] in
            UpgradeTracker.trackPublicUpgradePopupClick(popupClick: .upgrade,
                                                        popupType: (showLater ? .nonMandatoryUpgrade : .mandatoryUpgrade),
                                                        popupMode: self?.popupMode ?? .auto)
            self?.upgrade(with: urlString)
        }, mainWindow: mainWindow)
    }

    /// 点击稍后升级需要将点击时间存下来，用于处理半小时不重复弹窗的问题
    func later() {
        Self.logger.info("new version: User chooses later")
        trackLater()
        self.upgradeLastTapLaterTime = Date().timeIntervalSince1970
    }

    /// 点击立即升级
    ///
    /// - Parameter urlString: 新版本的URL
    func upgrade(with urlString: String) {
        Self.logger.info("new version: User chooses upgrade")
        trackUpgrade()
        UpgradeTracker.trackUpgradeAction()
        self.openUpgradeURL(with: urlString)
    }

    func openUpgradeURL(with urlStr: String) {
        guard let url = URL(string: urlStr) else {
            Self.logger.info("new version: Init url failed")
            return
        }
        Self.logger.info("new version: Start to install ipa, url: \(urlStr)")

        // iOS8+ OTA 方式安装app并不会主动退到后台, 需要退到后台后才能进行安装
        let suspend = {
            UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        }

        UIApplication.shared.open(url, options: [ :]) { _ in suspend() }
    }
    
    /// 判断当前页面是否可以自动弹出升级提醒弹窗, 目前只允许在首页自动弹出
    private func canShowAlertOnCurrentVC() -> Bool {
        return dependency.enableShowUpgradeAlert()
    }

    /// 判断"允许稍后"升级规则，兜底逻辑默认应该为"允许稍后"，0代表强升，1代表稍后
    func isForceUpgrade() -> Bool {
        guard let info = self.versionInfo, info.plan.hasSnoozePlan else {
            Self.logger.info("new version: Check info failed for force upgrade alert rule")
            return false
        }
        return info.plan.snoozePlan != 1
    }

    /// 两次弹窗弹出的时间间隔
    private func getPopupInterval() -> Double {
        return Date().timeIntervalSince1970 - self.upgradeLastTapLaterTime
    }

    /// 两次升级接口请求的时间间隔
    private func getVersionRequestInterval() -> Double {
        return Date().timeIntervalSince1970 - self.versionLastRequestTime
    }

    func getVersionSettingConfig() -> [String: Any]? {
        do {
            let settingService = try? self.userResolver.resolve(assert: SettingService.self)
            guard let setting = try settingService?.setting(with: VersionManager.requestField) else {
                Self.logger.info("new version: get version setting config error")
                return nil
            }
            return setting
        } catch {
            Self.logger.info("new version: get version setting config error")
            return nil
        }
    }
}

// MARK: - Tracker
private extension VersionManager {
    @inline(__always)
    func trackLater() {
        Tracker.post(TeaEvent(Homeric.NEW_VERSION_TAP_LATER))
    }

    @inline(__always)
    func trackUpgrade() {
        Tracker.post(TeaEvent(Homeric.NEW_VERSION_TAP_UPGRADE))
    }
}

extension VersionManager {
    /// 显示升级弹窗
    ///
    /// - Parameters:
    ///   - subtitle: 弹窗副标题
    ///   - note: release note
    ///   - urlString: 升级的URL
    ///   - showLater: 是否显示“稍后”
    func showUpgradeAlertUI(title: String,
                          note: String,
                          showLater: Bool,
                          laterTitle: String? = nil,
                          laterHandler: UpgradeEventHandler?,
                          upgradeTitle: String? = nil,
                          upgradeHandler: UpgradeEventHandler?,
                          mainWindow: UIWindow) {
        if let controller = self.alertController {
            controller.dismiss(animated: false, completion: nil)
            Self.logger.info("new version: There's already a alert view and remove it")
        }

        let upgradeViewModel = UpgradeViewModel(title: title,
                                                note: note,
                                                showLater: showLater,
                                                laterButtonTitle: laterTitle,
                                                upgradeButtonTitle: upgradeTitle)
        let customVC = UpgradeViewController(upgradeViewModel: upgradeViewModel)
        if #available(iOS 13.0, *) {
            /// 通过该属性设置，可以避免点蒙层关闭弹窗
            customVC.isModalInPresentation = true
        }
        customVC.modalPresentationStyle = .overFullScreen
        customVC.modalTransitionStyle = .crossDissolve
        if #available(iOS 13.0, *), UpgradeViewController.isAlert(window: mainWindow)  {
            /// iPad 全屏alert采用 formSheet ，否则宽度无法跟在它之后的弹窗宽度对齐
            customVC.modalPresentationStyle = .formSheet
        }

        // 升级信息回来时可能在编辑态，所以需要尝试关闭键盘
        userResolver.navigator.present(customVC, from: mainWindow, animated: true) {
            mainWindow.endEditing(true)
        }
        self.alertController = customVC
        self.hasShownAlert = true

        customVC.upgradeView.laterHandler = { [weak self, weak alertController] in
            guard let `self` = self else { return }
            // 记录下弹窗版本
            if let versionInfo = self.versionInfo {
                self.lastUpdateShowAlertVersion = versionInfo.data.version
            }
            alertController?.dismiss(animated: true, completion: nil)
            self.dialogManager.onDismiss()
            laterHandler?()
        }

        customVC.upgradeView.upgradHandler = { [weak self, weak alertController] in
            guard let `self` = self else { return }
            // 记录下弹窗版本
            if let versionInfo = self.versionInfo {
                self.lastUpdateShowAlertVersion = versionInfo.data.version
            }
            /// 如果是强制升级，弹窗不进行消失处理
            if (!self.isForceUpgrade()) {
                alertController?.dismiss(animated: true, completion: nil)
                self.dialogManager.onDismiss()
            }
            upgradeHandler?()
        }
    }
}

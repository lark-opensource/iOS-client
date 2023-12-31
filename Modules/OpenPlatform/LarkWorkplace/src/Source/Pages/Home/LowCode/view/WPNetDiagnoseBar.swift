//
//  WPNetDiagnoseBar.swift
//  LarkWorkplace
//
//  Created by 窦坚 on 2022/5/9.
//

import UIKit
import RxSwift
import ECOProbe
import EENavigator
import AppContainer
import LarkSetting
import LarkNavigator
import LarkContainer
import LKCommonsLogging
import UniverseDesignIcon
import UniverseDesignNotice
import UniverseDesignFont

/// 用于处理点击事件 & 横幅状态变更事件
protocol WPNetDiagnoseBarDelegate: NSObjectProtocol {

    var jumpFromViewController: UIViewController { get }

    func netDiagnoseBarStatusDidChange(_ netDiagnoseBar: WPNetDiagnoseBar)
}

/// 工作台网络诊断横幅，当网络异常时出现在 naviBar 下方
final class WPNetDiagnoseBar: UIView {
    static let logger = Logger.log(WPNetDiagnoseBar.self)

    var containerType: WPPortal.PortalType?

    private(set) var barStatus: StatusType = .hide

    private let disposeBag = DisposeBag()

    weak var delegate: WPNetDiagnoseBarDelegate?

    private var noticeView: UDNotice = UDNotice(config: UDNoticeUIConfig(
        backgroundColor: UIColor.ud.functionDangerFillSolid02,
        attributedText: NSAttributedString(string: "")
    ))

    private let dependency: WPDependency
    private let configService: WPConfigService
    private let pushCenter: PushNotificationCenter

    init(dependency: WPDependency, configService: WPConfigService, pushCenter: PushNotificationCenter) {
        self.dependency = dependency
        self.configService = configService
        self.pushCenter = pushCenter
        super.init(frame: .zero)
        setupView()
        subscribeNetStatus()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickBar))
        addGestureRecognizer(tap)
        noticeView.isUserInteractionEnabled = false
        addSubview(noticeView)
        noticeView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        updateUI()
    }

    private func updateUI() {
        let title = barStatus.diagnoseTitle()
        let isArrowShow = barStatus.canJump()
        let attributeTitle = NSAttributedString(string: title, attributes: [
            .font: UDFont.netStatusBarFont,
            .foregroundColor: UIColor.ud.textTitle
        ])
        var config = UDNoticeUIConfig(backgroundColor: UIColor.ud.functionDangerFillSolid02, attributedText: attributeTitle)
        config.leadingIcon = UDIcon.getIconByKey(.errorColorful, size: Layout.leadingIconSize)
        if isArrowShow {
            // UDNotice trailingButtonIcon 内部根据设计规范指定了 icon 颜色： .ud.iconN2
            config.trailingButtonIcon = UDIcon.getIconByKey(.rightOutlined, size: Layout.trailingIconSize)
        }
        noticeView.updateConfigAndRefreshUI(config)
    }

    /// 订阅网络状态变更事件流
    private func subscribeNetStatus() {
        pushCenter
            .observable(for: PushNetStatus.self, replay: true)
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self](message) in
                guard let `self` = self else { return }
                self.updateBarStatus(newNetStatus: message.netStatus)
            }).disposed(by: disposeBag)
    }

    /// 通过代理传出点击横幅事件
    /// - Parameter fromVC: 当前 VC，用于弹出新 VC
    @objc private func onClickBar(fromVC: UIViewController) {
        Self.logger.info("did tap netDiagnoseBar", additionalData: ["barStatus": "\(barStatus)"])
        /// 网络诊断横幅跳转埋点
        let monitor = OPMonitor(
            name: "op_workplace_event",
            code: EPMClientOpenPlatformAppCenterNetDiagnoseCode.network_status_tips_clicked
        )
        switch barStatus {
        case .hide:
            assertionFailure("should not run here")
        case .diagnose:
            if let from = delegate?.jumpFromViewController {
                dependency.navigator.showDiagnoseSettingVC(from: from)
            }
            monitor.addCategoryValue("target", "network_diagnose_page").flush()
        case .checkNetSetting:
            if let url = URL(string: "App-Prefs:root=WIFI"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { result in
                    Self.logger.info("jump check net setting result", additionalData: ["result": "\(result)"])
                }
            }
            monitor.addCategoryValue("target", "WIFI_setting_page").flush()
        case .serviceUnavailable:
            break // do nothing
        }
    }

    /// 根据网络状态更新横幅状态
    private func updateBarStatus(newNetStatus: Rust.NetStatus) {
        Self.logger.info("update bar status when net status change", additionalData: [
            "barStatus": "\(barStatus)",
            "netStatus": "\(newNetStatus)"
        ])
        self.pageViewReport(newNetStatus: newNetStatus)
        let barStatus = newNetStatus.barStatus()
        self.barStatus = barStatus
        updateUI()
        delegate?.netDiagnoseBarStatusDidChange(self)
    }
}

// MARK: 埋点相关
extension WPNetDiagnoseBar {

    private enum ReportNetStatusLevel: String {
        case netUnavailable = "net_unavailable"
        case deviceNetUnavailable = "device_net_unavailable"
        case serviceUnavailable = "service_unavailable"
    }

    private enum ReportSceneType: String {
        case h5Workplace = "h5_workplace"
        case oldWorkplace = "old_workplace"
        case templateWorkplace = "template_workplace"
        case unknown = "unknown"
    }

    /// 网络诊断横幅 PV 点
    /// - Parameter newNetStatus: 网络状态
    private func pageViewReport(newNetStatus: Rust.NetStatus) {
        let monitor = OPMonitor(
            name: "op_workplace_event",
            code: EPMClientOpenPlatformAppCenterNetDiagnoseCode.network_status_tips_show
        )
        var networkLevel: String
        switch newNetStatus {
        case .netUnavailable:
            networkLevel = ReportNetStatusLevel.netUnavailable.rawValue
        case .offline:
            networkLevel = ReportNetStatusLevel.deviceNetUnavailable.rawValue
        case .serviceUnavailable:
            networkLevel = ReportNetStatusLevel.serviceUnavailable.rawValue
        @unknown default:
            // bar hide, no need to report.
            return
        }
        var scene: String
        if let containerType = containerType {
            switch containerType {
            case .web:
                scene = ReportSceneType.h5Workplace.rawValue
            case .normal:
                scene = ReportSceneType.oldWorkplace.rawValue
            case .lowCode:
                scene = ReportSceneType.templateWorkplace.rawValue
            default:
                scene = ReportSceneType.unknown.rawValue
            }
        } else {
            scene = ReportSceneType.unknown.rawValue
        }
        monitor.addCategoryValue("clickable", barStatus.canJump())
            .addCategoryValue("networkLevel", networkLevel)
            .addCategoryValue("scene", scene)
            .flush()
    }
}

// MARK: UI 相关
extension WPNetDiagnoseBar {

    /// 布局样式
    enum Layout {
        static let barHeight: CGFloat = 44.0

        static let leadingIconSize: CGSize = CGSize(width: 16.0, height: 16.0)
        static let trailingIconSize: CGSize = CGSize(width: 16.0, height: 16.0)
    }

    /// bar status
    enum StatusType: String {
        // 隐藏
        case hide
        // 点击进行网络诊断，显示 前网络不可用，可运行网络诊断
        case diagnose
        // 点击进入系统设置页，显示 当前网络未连接，请检查你的网络设置
        case checkNetSetting
        // 无点击事件，显示 服务暂不可用，正在重试中...
        case serviceUnavailable

        var shouldHideStatusBar: Bool {
            switch self {
            case .hide:
                return true
            case .diagnose, .checkNetSetting, .serviceUnavailable:
                return false
            }
        }

        func diagnoseTitle() -> String {
            switch self {
            case .hide:
                return ""
            case .diagnose:
                return BundleI18n.LarkWorkplace.OpenPlatform_WorkplaceNetwork_NetErrDiagnosis
            case .checkNetSetting:
                return BundleI18n.LarkWorkplace.OpenPlatform_WorkplaceNetwork_NetConnectionErr
            case .serviceUnavailable:
                return BundleI18n.LarkWorkplace.OpenPlatform_WorkplaceNetwork_ChatTableHeaderServiceUnavailable
            }
        }

        func canJump() -> Bool {
            switch self {
            case .checkNetSetting, .diagnose:
                return true
            case .hide, .serviceUnavailable:
                return false
            }
        }
    }
}

extension Rust.NetStatus {
    func barStatus() -> WPNetDiagnoseBar.StatusType {
        switch self {
        case .excellent, .evaluating, .weak:
            return .hide
        case .netUnavailable:
            return .diagnose
        case .offline:
            return .checkNetSetting
        case .serviceUnavailable:
            return .serviceUnavailable
        @unknown default:
            return .hide
        }
    }
}

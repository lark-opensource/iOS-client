//
//  WPPageStateView.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/6/5.
// 设计稿：https://app.zeplin.io/project/5d75f6e0d402aa1a8f8bc242/screen/5ec5f08440a1ee4c8c8d0122
//

import UIKit
import ECOProbeMeta
import UniverseDesignFont
import UniverseDesignEmpty
import UniverseDesignLoading

final class WPPageStateView: UIView {

    typealias Action = () -> Void

    // Equatable 仅比较枚举类型是否相等，忽略参数
    enum State: Equatable {
        enum Param {
            struct NoApp: Equatable {

                let action: Action?

                static func create(action: Action?) -> NoApp {
                    NoApp(action: action)
                }

                // 仅比较枚举类型是否相等，忽略参数
                static func == (
                    lhs: WPPageStateView.State.Param.NoApp,
                    rhs: WPPageStateView.State.Param.NoApp
                ) -> Bool {
                    true
                }
            }

            struct LoadFail: Equatable {
                let text: String?
                let showReloadBtn: Bool
                let action: Action
                let monitorCode: OPMonitorCodeProtocol?

                static func create(
                    text: String? = nil,
                    showReloadBtn: Bool = false,
                    action: @escaping Action
                ) -> LoadFail {
                    LoadFail(text: text, showReloadBtn: showReloadBtn, action: action, monitorCode: nil)
                }

                static func create(
                    monitorCode: OPMonitorCodeProtocol,
                    showReloadBtn: Bool = false,
                    action: @escaping Action
                ) -> LoadFail {
                    LoadFail(
                        text: WPErrorPageInfoHelper.errorMessage(with: monitorCode, isCodeChangeLine: true),
                        showReloadBtn: showReloadBtn,
                        action: action,
                        monitorCode: monitorCode
                    )
                }

                // 仅比较枚举类型是否相等，忽略参数
                static func == (
                    lhs: WPPageStateView.State.Param.LoadFail,
                    rhs: WPPageStateView.State.Param.LoadFail
                ) -> Bool {
                    true
                }
            }

            struct SearchNoRet: Equatable {
                let text: String

                static func create(text: String) -> SearchNoRet {
                    SearchNoRet(text: text)
                }

                // 仅比较枚举类型是否相等，忽略参数
                static func == (
                    lhs: WPPageStateView.State.Param.SearchNoRet,
                    rhs: WPPageStateView.State.Param.SearchNoRet
                ) -> Bool {
                    true
                }
            }
        }

        case hidden
        case loading
        case noContent
        case noApp(_ param: Param.NoApp)
        case loadFail(_ param: Param.LoadFail)
        case noBadgeApp
        case searchNoRet(_ param: Param.SearchNoRet)
        /// 提示版本过低（用于模板化工作台）
        case verExpired

        /// 预览
        case previewExpired
        case previewPermission
        case previewDeleted
    }

    var state: State = .hidden {
        didSet {
            let config: UDEmptyConfig
            switch state {
            case .hidden:
                config = UDEmptyConfig(type: .initial)
            case .loading:
                config = UDEmptyConfig(type: .initial)
            case .noContent:
                config = UDEmptyConfig(type: .noContent)
            case .noApp(let param):
                let str = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_NoAppMsg
                let desc = UDEmptyConfig.Description(descriptionText: str)
                let btnTitle = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AddAppBttn
                let btnCfg: (String?, (UIButton) -> Void)?
                if let act = param.action {
                    btnCfg = (btnTitle, { _ in act() })
                } else {
                    btnCfg = nil
                }
                config = UDEmptyConfig(description: desc, type: .noApplication, primaryButtonConfig: btnCfg)
            case .loadFail(let param):
                config = onStateUpdateToLoadFaile(param: param)
                loadFailedReport(param: param)
            case .noBadgeApp:
                let str = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_BadgeNoApp
                let desc = UDEmptyConfig.Description(descriptionText: str)
                config = UDEmptyConfig(description: desc, type: .noApplication)
            case .searchNoRet(let param):
                let fullStr = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Search_No_Result(param.text)
                let range = fullStr.range(of: param.text)
                let nsRange: NSRange?
                if let range = range {
                    nsRange = NSRange(range, in: fullStr)
                } else {
                    nsRange = nil
                }
                // UDEmpty 会覆盖属性字符串的颜色
                let desc = UDEmptyConfig.Description(descriptionText: fullStr, operableRange: nsRange)
                config = UDEmptyConfig(description: desc, type: .searchFailed)
            case .verExpired:
                let str = BundleI18n.LarkWorkplace.OpenPlatform_Workplace_ClientVerLowDesc_Mobile
                let desc = UDEmptyConfig.Description(descriptionText: str)
                config = UDEmptyConfig(description: desc, type: .platformUpgrading1)
            case .previewExpired:
                let str = BundleI18n.LarkWorkplace.OpenPlatform_WpPreview_LinkExpDesc
                let desc = UDEmptyConfig.Description(descriptionText: str)
                config = UDEmptyConfig(description: desc, type: .noPreview)
            case .previewPermission:
                let str = BundleI18n.LarkWorkplace.OpenPlatform_WpPreview_NoPermErr
                let desc = UDEmptyConfig.Description(descriptionText: str)
                config = UDEmptyConfig(description: desc, type: .noAccess)
            case .previewDeleted:
                let str = BundleI18n.LarkWorkplace.OpenPlatform_WpPreview_WpDeleted
                let desc = UDEmptyConfig.Description(descriptionText: str)
                config = UDEmptyConfig(description: desc, type: .noPreview)
            }

            isHidden = (state == .hidden)
            loadingView.isHidden = (state != .loading)

            updateConfig(config)
        }
    }

    private lazy var emptyView: UDEmpty = {
        UDEmpty(config: UDEmptyConfig(type: .initial))
    }()

    private lazy var loadingView: UIView = {
        UDLoading.loadingImageView(lottieResource: nil)
    }()

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        customInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        customInit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        loadingView.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(frame.height / 3)
        }
    }

    private func customInit() {
        backgroundColor = UIColor.ud.bgBody

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        addGestureRecognizer(tap)

        addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(frame.height / 3)
        }

        state = .hidden
    }

    @objc
    private func onTap(_ sender: UITapGestureRecognizer) {
        switch state {
        case .loadFail(let param):
            param.action()
        default:
            break
        }
    }

    private func updateConfig(_ config: UDEmptyConfig) {
        emptyView.update(config: config)
    }

    private func onStateUpdateToLoadFaile(param: State.Param.LoadFail) -> UDEmptyConfig {
        var str: String
        if let text = param.text {
            str = text.isEmpty ? BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_FailRefreshMsg : text
        } else {
            str = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_FailRefreshMsg
        }
        let btnConfig: (String?, ((UIButton) -> Void))?
        if param.showReloadBtn {
            let btnTitle = BundleI18n.LarkWorkplace.OpenPlatform_Workplace_ReloadBttn
            btnConfig = (btnTitle, { _ in
                param.action()
            })
        } else {
            btnConfig = nil
        }
        let attributes: [NSAttributedString.Key: Any] = [.font: UDFont.body2]
        let desc = UDEmptyConfig.Description(
            descriptionText: NSAttributedString(string: str, attributes: attributes),
            textAlignment: .center
        )
        return UDEmptyConfig(
            description: desc,
            type: .loadingFailure,
            labelHandler: param.action,
            primaryButtonConfig: btnConfig
        )
    }

    private func loadFailedReport(param: State.Param.LoadFail) {
        let monitor = WPMonitor().setCode(WPMCode.workplace_show_load_fail)
        if let monitorCode = param.monitorCode {
            monitor.setInfo([
                "error_monitor_domain": monitorCode.domain,
                "error_monitor_code": "\(monitorCode.code)"
            ])
            if let text = param.text, !text.isEmpty {
                monitor.setInfo(true, key: "distributed_message")
            } else {
                // 需要重点关注这种情况
                monitor.setInfo(false, key: "distributed_message")
            }
        } else {
            monitor.setInfo(false, key: "distributed_message")
        }
        monitor.flush()
    }
}

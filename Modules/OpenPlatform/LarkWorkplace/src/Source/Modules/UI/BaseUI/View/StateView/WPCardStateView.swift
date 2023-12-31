//
//  WPCardStateView.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/2/24.
//

import UIKit
import ECOProbeMeta
import LarkLocalizations
import UniverseDesignFont
import UniverseDesignEmpty
import UniverseDesignColor
import UniverseDesignShadow
import UniverseDesignButton

private let stateImageSize: CGFloat = 50
private let appNamePlaceHolder: String = "{{app_name}}"

final class WPCardStateView: UIView {

    enum DisplayMode {
        // 极端模式
        case extremelyLight
        // 极简模式
        case light
        // 无图模式
        case noIcon
        // 有图模式
        case icon
        // 获取当前展示模式
        static func mode(height: CGFloat) -> DisplayMode {
            if height < 80 {
                return .extremelyLight
            } else if height < 102 {
                return .light
            } else if height < 156 {
                return .noIcon
            } else {
                return .icon
            }
        }
    }

    enum State: Equatable {
        enum Param: Equatable {
            struct LoadFailParam: Equatable {
                let name: String
                let message: String
                let monitorCode: OPMonitorCodeProtocol?

                static func create(
                    name: String,
                    message: String
                ) -> LoadFailParam {
                    LoadFailParam(name: name, message: message, monitorCode: nil)
                }

                /// 使用埋点获取下发的错误页文案
                /// - Parameters:
                ///   - name: 小组件名
                ///   - monitorCode: monitorCode
                /// - Returns: LoadFaildParam
                static func create(
                    name: String,
                    monitorCode: OPMonitorCodeProtocol
                ) -> LoadFailParam {
                    let message = WPErrorPageInfoHelper.errorMessage(with: monitorCode)
                        ?? WPErrorPageInfoHelper.errorMessage(with: WPMCode.workplace_block_show_fail)
                    return LoadFailParam(
                        name: name,
                        message: message ?? "",
                        monitorCode: monitorCode
                    )
                }

                static func == (
                    lhs: WPCardStateView.State.Param.LoadFailParam,
                    rhs: WPCardStateView.State.Param.LoadFailParam
                ) -> Bool {
                    true
                }
            }
        }
        /// 加载中
        case loading
        /// “{{name}}”加载失败，点击刷新
        case loadFail(_ param: Param.LoadFailParam)
        /// 版本过低
        case updateTip
        /// 正常状态
        case running

        var isLoadFail: Bool {
            switch self {
            case .loadFail:
                return true
            default:
                return false
            }
        }
    }

    enum LoadingStyle {
        case spin
        case skeleton
    }

    // MARK: - public property

    /// Loading 样式
    let loadingStyle: LoadingStyle

    /// 设置 state，自动更新加载状态，需要主线程调用
    var state: State {
        didSet {
            onStateUpdate(state)
        }
    }

    /// 裁切圆角（解决阴影和圆角没法同时生效问题）
    var radius: CGFloat = 0.0 {
        didSet {
            contentWrapper.layer.cornerRadius = radius
        }
    }

    /// 默认阴影开关 （解决阴影和圆角没法同时生效问题）
    var shadowEnable: Bool = true {
        didSet {
            if shadowEnable {
                layer.ud.setShadow(type: UDShadowType.s2Down)
            } else {
                layer.ud.setShadowColor(UIColor.clear)
            }
        }
    }

    var bgColorEnable: Bool = true {
        didSet {
            if bgColorEnable {
                contentWrapper.backgroundColor = UIColor.ud.bgFloat
            } else {
                contentWrapper.backgroundColor = UIColor.clear
            }
        }
    }

    var borderEnable: Bool = true {
        didSet {
            if borderEnable {
                contentWrapper.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
                contentWrapper.layer.borderWidth = WPUIConst.BorderW.px1
            } else {
                contentWrapper.layer.borderWidth = 0.0
            }
        }
    }

    /// 加载失败时的点击重试事件回调
    var reloadAction: (() -> Void)?

    // MARK: - private property

    // Clip 容器
    private lazy var contentWrapper: UIView = {
        let ins = UIView()
        ins.backgroundColor = UIColor.ud.bgFloat
        ins.clipsToBounds = true
        return ins
    }()

    // 骨架屏 Loading 动画
    private lazy var skeletonLoadingView: SkeletonLoadingView = SkeletonLoadingView()

    // 三点 loading 动画（ GIF ）
    private lazy var spinLoadingView: SpinLoadingView = SpinLoadingView()

    // state 容器
    private lazy var stateContainer: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .center
        return view
    }()

    // state 图片
    private lazy var stateImageView: UIImageView = UIImageView()

    // state 文字   字体应当使用 UD Token 初始化
    // swiftlint:disable init_font_with_token
    private lazy var stateTextLabel: UILabel = {
        let label = UILabel()
        label.font = .ud.body2
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .center
        return label
    }()
    // swiftlint:enable init_font_with_token

    private lazy var actionButton: UILabel = {
        let label = UILabel()
        label.font = .ud.body2
        label.textColor = .ud.textLinkNormal
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.sizeToFit()
        label.text = BundleI18n.LarkWorkplace.OpenPlatform_Workplace_ClickToRefreshBttn
        return label
    }()

    // MARK: - life cycle
    init(frame: CGRect = .zero, state: State = .running, loadingStyle: LoadingStyle = .skeleton) {
        self.state = state
        self.loadingStyle = loadingStyle
        super.init(frame: frame)
        subviewsInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.shadowPath = CGPath(rect: bounds, transform: nil)

        if bounds.size.height < 156 {
            stateImageView.isHidden = true
        } else {
            stateImageView.isHidden = false
            stateImageView.snp.updateConstraints { make in
                make.height.equalTo(stateImageSize)
            }
        }
    }

    private func subviewsInit() {
        addSubview(contentWrapper)

        contentWrapper.addSubview(stateContainer)
        stateContainer.addArrangedSubview(stateImageView)
        stateContainer.setCustomSpacing(4.0, after: stateImageView)
        stateContainer.addArrangedSubview(stateTextLabel)

        contentWrapper.addSubview(skeletonLoadingView)
        contentWrapper.addSubview(spinLoadingView)

        contentWrapper.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        skeletonLoadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        spinLoadingView.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.center.equalToSuperview()
        }

        stateContainer.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
        stateImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(stateImageSize)
        }
        stateTextLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        addGestureRecognizer(tap)

        backgroundColor = UIColor.clear
        actionButton.isHidden = true
        state = .running
        shadowEnable = true
    }

    private func onStateUpdate(_ state: State) {
        switch state {
        case .loading:
            self.isHidden = false
            hideLoading(false)
            stateContainer.isHidden = true
        case .loadFail(let param):
            onStateUpdateToLoadFaile(param: param)
            loadFailedReport(param: param)
        case .updateTip:
            self.isHidden = false
            hideLoading(true)
            stateContainer.isHidden = false
            stateImageView.isHidden = false
            if !stateContainer.arrangedSubviews.contains(stateImageView) {
                stateContainer.insertSubview(stateImageView, at: 0)
                stateContainer.setCustomSpacing(4.0, after: stateImageView)
            }
            stateImageView.image = UDEmptyType.platformUpgrading1.defaultImage()
            stateTextLabel.numberOfLines = 0
            stateTextLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_IOSUpdtVerMsg(
                LanguageManager.bundleDisplayName
            )
            actionButton.isHidden = true
            if stateContainer.arrangedSubviews.contains(actionButton) {
                stateContainer.removeArrangedSubview(actionButton)
            }
        case .running:
            self.isHidden = true
            hideLoading(true)
            stateContainer.isHidden = true
        }
    }

    private func hideLoading(_ hide: Bool) {
        switch loadingStyle {
        case .skeleton:
            skeletonLoadingView.isHidden = hide
            skeletonLoadingView.animating = !hide

            spinLoadingView.isHidden = true
            spinLoadingView.animating = false
        case .spin:
            skeletonLoadingView.isHidden = true
            skeletonLoadingView.animating = false

            spinLoadingView.isHidden = hide
            spinLoadingView.animating = !hide
        }
    }

    @objc
    private func tap(_ sender: UIButton) {
        if case .loadFail = state {
            reloadAction?()
        }
    }

    private func onStateUpdateToLoadFaile(param: State.Param.LoadFailParam) {
        self.isHidden = false
        hideLoading(true)
        stateContainer.isHidden = false
        stateImageView.image = UDEmptyType.loadingFailure.defaultImage()
        stateTextLabel.text = loadFailedMessage(name: param.name, message: param.message)
        switch DisplayMode.mode(height: frame.height) {
        case .extremelyLight:
            if stateContainer.arrangedSubviews.contains(stateImageView) {
                stateContainer.removeArrangedSubview(stateImageView)
                stateImageView.isHidden = true
            }
            stateTextLabel.numberOfLines = 1
            if stateContainer.arrangedSubviews.contains(actionButton) {
                stateContainer.removeArrangedSubview(actionButton)
                actionButton.isHidden = true
            }
        case .light:
            if stateContainer.arrangedSubviews.contains(stateImageView) {
                stateContainer.removeArrangedSubview(stateImageView)
                stateImageView.isHidden = true
            }
            stateTextLabel.numberOfLines = 1
            if reloadAction != nil, !stateContainer.arrangedSubviews.contains(actionButton) {
                stateContainer.setCustomSpacing(4.0, after: stateTextLabel)
                stateContainer.addArrangedSubview(actionButton)
                actionButton.isHidden = false
            }
        case .noIcon:
            if stateContainer.arrangedSubviews.contains(stateImageView) {
                stateContainer.removeArrangedSubview(stateImageView)
                stateImageView.isHidden = true
            }
            stateTextLabel.numberOfLines = 2
            if reloadAction != nil, !stateContainer.arrangedSubviews.contains(actionButton) {
                stateContainer.setCustomSpacing(4.0, after: stateTextLabel)
                stateContainer.addArrangedSubview(actionButton)
                actionButton.isHidden = false
            }
        case .icon:
            if !stateContainer.arrangedSubviews.contains(stateImageView) {
                stateContainer.insertSubview(stateImageView, at: 0)
                stateContainer.setCustomSpacing(4.0, after: stateImageView)
            }
            stateTextLabel.numberOfLines = 2
            if reloadAction != nil, !stateContainer.arrangedSubviews.contains(actionButton) {
                stateContainer.setCustomSpacing(4.0, after: stateTextLabel)
                stateContainer.addArrangedSubview(actionButton)
                actionButton.isHidden = false
            }
        }
    }

    private func loadFailedMessage(name: String, message: String) -> String {
        let isNameValid = !name.isEmpty
        let isMessageValid = !message.isEmpty
        if isNameValid && isMessageValid && message.contains(appNamePlaceHolder) {
            // 只有当「小组件输入组件名不为空/空字符串」&&「获取下发message不为空/空字符串」&& message 中有“{{app_name}}”时
            // 用 组件名 去替换文案中的 {{app_name}}
            return message.replacingOccurrences(of: appNamePlaceHolder, with: name)
        } else if isNameValid {
            // 当「小组件输入组件名不为空/空字符串」&&（「获取下发message为空/空字符串」|| message 中无“{{app_name}}”）时
            // 使用默认兜底文案 “{{app_name}}加载失败”
            return BundleI18n.LarkWorkplace.OpenPlatform_Workplace_BlcLoadFailedSpec(name)
        } else {
            // 其他情况均使用兜底文案 “加载失败”
            return BundleI18n.LarkWorkplace.loading_failed
        }
    }

    private func loadFailedReport(param: State.Param.LoadFailParam) {
        let monitor = WPMonitor().setCode(WPMCode.workplace_show_load_fail)
        if let monitorCode = param.monitorCode {
            monitor.setInfo([
                "error_monitor_domain": monitorCode.domain,
                "error_monitor_code": "\(monitorCode.code)"
            ])
            if !param.message.isEmpty {
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

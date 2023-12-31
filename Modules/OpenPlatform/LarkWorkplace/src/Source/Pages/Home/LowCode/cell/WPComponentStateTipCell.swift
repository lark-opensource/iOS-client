//
//  WPTemplateLoadingCoverCell.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/4/11.
//

import LarkUIKit
import ECOProbe
import UniverseDesignEmpty
import LKCommonsLogging

enum WPComponentErrorState: Int {
    // swiftlint:disable identifier_name
    case load_fail = 1
    case need_update = 2
    // swiftlint:enable identifier_name
}

final class WPComponentStateTipCell: UICollectionViewCell {
    static let logger = Logger.log(WPComponentStateTipCell.self)

    private lazy var stateView: WPCardStateView = { WPCardStateView()}()
    private lazy var emptyView: UDEmpty = { UDEmpty(config: UDEmptyConfig(type: .initial)) }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(stateView)
        contentView.addSubview(emptyView)
        stateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20 - favoriteModuleHeaderBottomGap)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview()
        }
    }

    func update(groupComponent: GroupComponent, trace: OPTraceProtocol?, retryAction: @escaping (() -> Void)) {
        Self.logger.info("update component: \(groupComponent), state: \(groupComponent.componentState))")
        switch groupComponent.componentState {
        case .loading:
            stateView.isHidden = false
            emptyView.isHidden = true
            stateView.state = .loading
        case .loadFailed:
            stateView.isHidden = false
            emptyView.isHidden = true
            stateView.reloadAction = retryAction
            stateView.state = .loadFail(
                .create(
                    name: "",
                    message: ""
                )
            )
            monitorShowErrorView(groupComponent: groupComponent, errorState: .load_fail, trace: trace)
        case .notSupport:
            stateView.isHidden = false
            emptyView.isHidden = true
            stateView.state = .updateTip
            monitorShowErrorView(groupComponent: groupComponent, errorState: .need_update, trace: trace)
        case .running:
            stateView.isHidden = true
            emptyView.isHidden = true
        case .noApp:
            stateView.isHidden = true
            emptyView.isHidden = false
            let desc = BundleI18n.LarkWorkplace.OpenPlatform_QuickAccessBlc_NoRecentlyUsedApps
            let config: UDEmptyConfig = .init(
                description: .init(descriptionText: desc),
                imageSize: 60,
                spaceBelowImage: 8,
                spaceBelowDescription: 0,
                type: .noApplication
            )
            emptyView.update(config: config)
        }

        if let blockGroup = groupComponent as? BlockLayoutComponent {
            // Block 组件的背景在 Block 内部，stateView 需要展示背景和阴影
            stateView.shadowEnable = true
            stateView.bgColorEnable = true
            stateView.borderEnable = true
            stateView.radius = blockGroup.styles?.backgroundRadius ?? 0
        } else {
            // 其它组件背景使用的是装饰视图，无需在占位 Cell 中显示
            stateView.shadowEnable = false
            stateView.bgColorEnable = false
            stateView.borderEnable = false
            stateView.radius = 0
        }
    }
}

extension WPComponentStateTipCell {
    private func monitorShowErrorView(
        groupComponent: GroupComponent,
        errorState: WPComponentErrorState,
        trace: OPTraceProtocol?
    ) {
        let isRetry = groupComponent.lastComponentState == .loadFailed
        WPMonitor().setCode(WPMCode.workplace_native_component_show_error_view)
            .setNetworkStatus()
            .setTrace(trace)
            .setInfo([
                "component_type": groupComponent.groupType.rawValue,
                "component_id": groupComponent.componentID,
                "error_state": errorState.rawValue,
                "is_retry": isRetry
            ])
            .flush()
    }
}

//
//  SearchBlockTableViewCell.swift
//  LarkSearch
//
//  Created by Patrick on 2022/4/14.
//

import Foundation
import Blockit
import OPSDK
import OPBlockInterface
import LarkOPInterface
import LarkAccountInterface
import SnapKit
import LarkReleaseConfig
import UIKit
import UniverseDesignIcon
import LarkSearchFilter
import UniverseDesignLoading
import UniverseDesignEmpty
import LKCommonsLogging

struct SearchBlockInfoForCell {
    let container: UIView
    let isFolding: Bool
    let isFirstLoad: Bool
    let shouldReload: ((IndexPath?) -> Void)?
    let viewModel: SearchCellViewModel?
    let uniqueId: OPAppUniqueID?
}

enum SearchBlockResultType {
    case success
    case fail(errorCode: Int, errorMessage: String)
    case cancel(errorCode: Int, errorMessage: String)

    var name: String {
        switch self {
        case .success: return "success"
        case .fail: return "fail"
        case .cancel: return "cancel"
        }
    }
}

enum SearchBlockMonitorCode {
    static let startDisplay = OPMonitorCode(domain: "client.open_platform.blockit.host",
                                            code: 10_000,
                                            level: OPMonitorLevelNormal,
                                            message: "start_display_block")

    static let hideBlockLoading = OPMonitorCode(domain: "client.open_platform.blockit.host",
                                                code: 10_001,
                                                level: OPMonitorLevelNormal,
                                                message: "recevice_hide_block_loading")

    static let displayResult = OPMonitorCode(domain: "client.open_platform.blockit.host",
                                             code: 10_002,
                                             level: OPMonitorLevelNormal,
                                             message: "display_block_result")
}

final class SearchBlockMonitor {

    private let opMonitor = OPMonitor("op_blockit_event")

    /// 设置 Code
    @discardableResult
    func setCode(_ code: OPMonitorCodeProtocol) -> SearchBlockMonitor {
        _ = opMonitor.setMonitorCode(code)
        return self
    }

    /// 设置 Info
    @discardableResult
    func setInfo(_ info: [String: Any]) -> SearchBlockMonitor {
        for (key, value) in info {
            _ = opMonitor.addCategoryValue(key, value)
        }
        return self
    }

    /// 设置 Info
    @discardableResult
    func setInfo(_ value: Any?, key: String) -> SearchBlockMonitor {
        _ = opMonitor.addCategoryValue(key, value)
        return self
    }

    /// 设置 Trace ( trace_id )
    @discardableResult
    func setTrace(_ trace: OPTraceProtocol?) -> SearchBlockMonitor {
        _ = opMonitor.tracing(trace)
        return self
    }

    /// 上报
    func flush(
        fileName: String = #fileID,
        functionName: String = #function,
        line: Int = #line
    ) {
        opMonitor.flush(fileName: fileName, functionName: functionName, line: line)
    }
}

final class SearchBlockTableViewCell: UITableViewCell, SearchTableViewCellProtocol {
    static let logger = Logger.log(SearchBlockTableViewCell.self, category: "LarkSearch.SearchBlockTableViewCell")
    enum RetryType {
        case reload, remount
    }
    final class ErrorView: UIView {
        enum Status {
            case retry, fail, loading, none
        }
        var didTapReloadButton: ((RetryType) -> Void)?
        var status: Status = .none {
            didSet {
                guard oldValue != status else { return }
                didSetStatus()
            }
        }
        var retryType: RetryType = .reload
        private lazy var iconView: UIImageView = {
            let view = UIImageView()
            view.image = UDEmptyType.loadingFailure.defaultImage()
            return view
        }()

        private lazy var reloadButton: UIButton = {
            let button = UIButton(type: .system)
            button.setAttributedTitle(getReloadButtonAttributedString(), for: .normal)
            button.addTarget(self, action: #selector(didClickReloadButton), for: .touchUpInside)
            return button
        }()

        private lazy var failLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 14)
            label.text = BundleI18n.LarkSearch.Lark_Legacy_LoadingFailed
            return label
        }()

        private let loadingView = UDLoading.presetSpin(loadingText: BundleI18n.LarkSearch.Lark_Shared_ASL_SearchResultBlock_Loading, textDistribution: .horizonal)

        private func getReloadButtonAttributedString() -> NSAttributedString {
            let font = UIFont.systemFont(ofSize: 14)
            var title = NSMutableAttributedString()
            let firstPart = NSAttributedString(string: BundleI18n.LarkSearch.Lark_Shared_ASL_SearchResultBlock_FailedToLoad, attributes: [.font: font, .foregroundColor: UIColor.ud.textCaption])
            let secondPart = NSAttributedString(string: BundleI18n.LarkSearch.Lark_Shared_ASL_SearchResultBlock_Refresh, attributes: [.font: font, .foregroundColor: UIColor.ud.primaryContentDefault])
            title.append(firstPart)
            title.append(secondPart)
            return title
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupView()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupView() {
            backgroundColor = .ud.bgBody

            addSubview(iconView)
            iconView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(CGSize(width: 100, height: 100))
            }
            addSubview(reloadButton)
            reloadButton.snp.makeConstraints { make in
                make.top.equalTo(iconView.snp.bottom).offset(12)
                make.centerX.equalToSuperview()
            }
            addSubview(failLabel)
            failLabel.snp.makeConstraints { make in
                make.top.equalTo(iconView.snp.bottom).offset(12)
                make.centerX.equalToSuperview()
            }
            addSubview(loadingView)
            loadingView.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            reset()
        }

        @objc
        private func didClickReloadButton() {
            didTapReloadButton?(retryType)
        }

        private func reset() {
            reloadButton.isHidden = true
            iconView.isHidden = true
            failLabel.isHidden = true
            loadingView.isHidden = true
            loadingView.reset()
        }

        private func didSetStatus() {
            reset()
            switch status {
            case .none: break
            case .fail:
                failLabel.isHidden = false
                iconView.isHidden = false
            case .retry:
                reloadButton.isHidden = false
                iconView.isHidden = false
            case .loading:
                loadingView.isHidden = false
            }
        }
    }
    var isRecommend: Bool = false
    var viewModel: SearchCellViewModel?
    var shouldReload: ((IndexPath?) -> Void)?
    private(set) var currentUniqueId: OPAppUniqueID?
    private var currentBlockInfo: OPBlockInfo?

    private(set) var isFolding = true
    private(set) var isFirstLoad = true
    private var otherHeight: CGFloat {
        return frame.height - blockRenderView.frame.height
    }
    private var blockWidth: CGFloat {
        return blockRenderView.frame.width
    }

    var heightConstraint: Constraint?
    private var lastHeight: CGFloat = 0

    private lazy var titleView: UILabel = {
        let title = UILabel()
        title.font = .systemFont(ofSize: 14, weight: .medium)
        return title
    }()

    lazy var blockRenderView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var unfoldButton: UIButton = {
        let button = UIButton(type: .system)
        button.isHidden = true
        button.addTarget(self, action: #selector(didTapUnfoldButton), for: .touchUpInside)
        button.setAttributedTitle(getUnfoldButtonAttributedString(), for: .normal)
        return button
    }()

    private let gradientView: BaseSearchFilterBar.GradientView = {
        let view = BaseSearchFilterBar.GradientView()
        view.isHidden = true
        let backgroundColor = UIColor.ud.bgBody
        view.colors = [backgroundColor.withAlphaComponent(0), backgroundColor, backgroundColor]
        view.gradientLayer.locations = [0, 0.4, 1]
        return view
    }()

    private lazy var errorView: ErrorView = {
        let view = ErrorView()
        view.didTapReloadButton = { [weak self] (retryType) in
            guard let self = self,
                  let blockViewModel = self.viewModel as? SearchBlockViewModel,
                  let currentUniqueId = self.currentUniqueId else { return }
            self.errorView.status = .loading
            switch retryType {
            case .reload:
                blockViewModel.blockService?.reloadPage(id: currentUniqueId)
            case .remount:
                blockViewModel.blockService?.unMountBlock(id: currentUniqueId)
                self.mountBlockView(withViewModel: blockViewModel)
            }
        }
        view.isHidden = true
        return view
    }()

    static let defaultHeight: CGFloat = 450
    private var contentHeight: CGFloat = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        isFolding = true
        isFirstLoad = true
        shouldReload = nil
        viewModel = nil
        currentUniqueId = nil
        lastHeight = 0
        heightConstraint?.update(offset: Self.defaultHeight)
        unfoldButton.isHidden = true
        gradientView.isHidden = true
    }

    func capture() -> SearchBlockInfoForCell {
        return SearchBlockInfoForCell(container: blockRenderView, isFolding: isFolding, isFirstLoad: isFirstLoad, shouldReload: shouldReload, viewModel: viewModel, uniqueId: currentUniqueId)
    }

    func set(withBlockInfo blockInfo: SearchBlockInfoForCell) {
        isFirstLoad = blockInfo.isFirstLoad
        isFolding = blockInfo.isFolding
        blockRenderView = blockInfo.container
        shouldReload = blockInfo.shouldReload
        viewModel = blockInfo.viewModel
        currentUniqueId = blockInfo.uniqueId
    }

    func set(viewModel: SearchCellViewModel,
             currentAccount: User?,
             searchText: String?) {
        guard isFirstLoad else { return }
        guard let blockViewModel = viewModel as? SearchBlockViewModel else { return }
        self.viewModel = blockViewModel
        mountBlockView(withViewModel: blockViewModel)
        errorView.isHidden = false
        errorView.status = .loading
        errorView.isHidden = false
        isFirstLoad = false
        if !blockViewModel.title.isEmpty {
            titleView.text = blockViewModel.title
        } else {
            titleView.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.left.equalToSuperview().inset(16)
                make.size.equalTo(CGSize(width: 0, height: 0))
            }
        }
    }

    private func setupView() {
        let containerGuide = UILayoutGuide()
        contentView.addLayoutGuide(containerGuide)
        containerGuide.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            heightConstraint = make.height.equalTo(Self.defaultHeight).priority(.high).constraint
        }
        contentView.addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.left.equalToSuperview().inset(16)
        }
        contentView.addSubview(blockRenderView)
        blockRenderView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(12)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
        contentView.addSubview(gradientView)
        gradientView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(60)
        }
        contentView.addSubview(unfoldButton)
        unfoldButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        contentView.addSubview(errorView)
        errorView.snp.makeConstraints { make in
            make.edges.equalTo(blockRenderView)
        }
        contentView.roundCorners(corners: [.topLeft, .topRight], radius: 8.0)
        roundCorners(corners: [.topLeft, .topRight], radius: 8.0)
        contentView.clipsToBounds = true
        clipsToBounds = true
    }

    private func getUnfoldButtonAttributedString() -> NSAttributedString {
        let font = UIFont.systemFont(ofSize: 14)
        let color = UIColor.ud.primaryContentDefault
        let buttonTitle = NSMutableAttributedString(string: "\(BundleI18n.LarkSearch.Lark_Shared_ASL_SearchResultBlock_ShowAll) ", attributes: [.font: font, .foregroundColor: color])
        buttonTitle.addImageAttachment(image: UDIcon.getIconByKey(.downBottomOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(color), font: font)
        return buttonTitle
    }

    private func mountBlockView(withViewModel viewModel: SearchBlockViewModel) {
        guard let blockInfo = viewModel.blockInfo,
              let appId = viewModel.appId else {
            errorView.status = .fail
            errorView.isHidden = false
            return
        }
        let slot = OPViewRenderSlot(view: self.blockRenderView, defaultHidden: false)
        let uniqueID = OPAppUniqueID(appID: appId, identifier: blockInfo.blockTypeID, versionType: .current, appType: .block)
        currentUniqueId = uniqueID
        currentBlockInfo = blockInfo
        var config = OPBlockContainerConfig(uniqueID: uniqueID,
                                            blockLaunchMode: .default,
                                            previewToken: "",
                                            host: "search")
        config.useCustomRenderLoading = true
        let data = OPBlockContainerMountData(scene: .global_search)
        monitorStartDisplay(uniqueID: blockInfo.blockTypeID, blockId: blockInfo.blockID, appId: appId, trace: config.trace)
        Self.logger.info("Search block mount \(uniqueID)")
        viewModel.blockService?.mountBlock(byEntity: blockInfo,
                                          slot: slot,
                                          data: data,
                                          config: config,
                                          plugins: [],
                                          delegate: self)
    }

    private func monitorStartDisplay(uniqueID: String, blockId: String, appId: String, trace: OPTraceProtocol) {
        SearchBlockMonitor()
            .setCode(SearchBlockMonitorCode.startDisplay)
            .setTrace(trace)
            .setInfo([
                "host": "search",
                "identifier": uniqueID,
                "block_id": blockId,
                "app_id": appId
            ])
            .flush()
    }

    private func monitorDisplayResult(uniqueID: String, blockId: String, resultTye: SearchBlockResultType, appId: String, trace: OPTraceProtocol) {
        var trackInfo: [String: Any?] = [
            "host": "search",
            "identifier": uniqueID,
            "block_id": blockId,
            "result_type": resultTye.name,
            "app_id": appId
        ]
        switch resultTye {
        case .success: ()
        case .fail(let errorCode, let errorMessage):
            trackInfo["error_code"] = errorCode
            trackInfo["error_msg"] = errorMessage
        case .cancel(let errorCode, let errorMessage):
            trackInfo["error_code"] = errorCode
            trackInfo["error_msg"] = errorMessage
        }
        SearchBlockMonitor()
            .setCode(SearchBlockMonitorCode.displayResult)
            .setTrace(trace)
            .setInfo(trackInfo)
            .flush()
    }

    @objc
    private func didTapUnfoldButton() {
        heightConstraint?.update(offset: contentHeight + otherHeight)
        if let viewModel = viewModel as? SearchBlockViewModel {
            shouldReload?(viewModel.indexPath)
        }
        unfoldButton.isHidden = true
        gradientView.isHidden = true
        isFolding = false
    }

    private func contentDidChange(withHeight height: CGFloat) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let blockViewModel = self.viewModel as? SearchBlockViewModel else {
                return
            }
            let newHeight = height
            defer {
                self.lastHeight = newHeight
            }
            guard self.lastHeight != newHeight else { return }
            if self.isFolding {
                if newHeight <= Self.defaultHeight - self.otherHeight, newHeight > 0 {
                    self.heightConstraint?.update(offset: newHeight + self.otherHeight)
                    self.unfoldButton.isHidden = true
                    self.gradientView.isHidden = true
                } else if newHeight > Self.defaultHeight - self.otherHeight {
                    self.heightConstraint?.update(offset: Self.defaultHeight)
                    self.unfoldButton.isHidden = false
                    self.gradientView.isHidden = false
                }
            } else {
                self.heightConstraint?.update(offset: newHeight + self.otherHeight)
                self.unfoldButton.isHidden = true
                self.gradientView.isHidden = true
            }
            self.contentHeight = newHeight
            self.shouldReload?(blockViewModel.indexPath)
        }
    }

    private func handleError(_ error: OPError) {
        switch error.monitorCode {
        case OPBlockitMonitorCodeMountLaunchGuideInfo.fetch_guide_info_biz_error,
            OPBlockitMonitorCodeMountLaunchGuideInfo.check_guide_info_unknown,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.usable,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.not_auth,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.deactivate,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.uninstall,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.offline,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.delete,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.no_permissions,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.disable_install_unpublish_app,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.disable_install_unshelve_app,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.disable_install_other_tenant_selfbuilt_app,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.install_not_start,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.install_in_deactivate,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.install_in_init,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.install_update_not_start,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.install_expire_stop,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.install_lark_expire_stop,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.in_block_visible,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.disable_apply_visible,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.disable_install_isv_app,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.not_support_ability,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.bind_app_not_exist,
            OPBlockitMonitorCodeMountLaunchGuideInfoServer.need_upgrade_status:
            self.errorView.status = .none
            self.errorView.isHidden = true
        case OPBlockitMonitorCodeMountEntity.fetch_block_entity_network_error,
            OPBlockitMonitorCodeMountLaunchGuideInfo.fetch_guide_info_network_error,
            OPBlockitMonitorCodeMountLaunchMeta.load_meta_fail,
            OPBlockitMonitorCodeMountLaunchPackage.load_package_fail:
            self.errorView.status = .retry
            self.errorView.retryType = .remount
            self.errorView.isHidden = false
        default:
            self.errorView.status = .fail
            self.errorView.isHidden = false
        }
    }
}

extension SearchBlockTableViewCell: OPBlockHostProtocol {
    func didReceiveLogMessage(_ sender: OPBlockEntityProtocol, level: OPBlockDebugLogLevel, message: String, context: OPBlockContext) {

    }

	func onBlockLoadReady(_ sender: OPBlockEntityProtocol, context: OPBlockContext) {}

    func contentSizeDidChange(_ sender: OPBlockEntityProtocol, newSize: CGSize, context: OPBlockContext) {
        let zoomScale = context.additionalInfo["zoomScale"] as? CGFloat ?? 1.0
        contentDidChange(withHeight: newSize.height * zoomScale)
    }

    func hideBlockHostLoading(_ sender: OPBlockEntityProtocol) {

    }
}

extension SearchBlockTableViewCell: BlockitLifeCycleDelegate {
    func onBlockMountSuccess(container: OPBlockContainerProtocol, context: OPBlockContext) {
        guard #available(iOS 13.0, *) else { return }
        if UITraitCollection.current.userInterfaceStyle == UIUserInterfaceStyle.dark {
            container.notifyThemeChange(theme: "dark")
        } else {
            container.notifyThemeChange(theme: "light")
        }
    }

    func onBlockMountFail(error: OPError, context: OPBlockContext) {
        DispatchQueue.main.async { [weak self] in
            self?.handleError(error)
        }
    }

    func onBlockUnMount(context: OPBlockContext) {}

    func onBlockDestroy(context: OPBlockContext) {}

    func onBlockLoadStart(context: OPBlockContext) {}

    func onBlockConfigLoad(config: OPBlockProjectConfig, context: OPBlockContext) {}

    func onBlockLaunchSuccess(context: OPBlockContext) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.errorView.isHidden = true
            if let blockInfo = self.currentBlockInfo, let currentUniqueId = self.currentUniqueId {
                self.monitorDisplayResult(uniqueID: blockInfo.blockTypeID,
                                          blockId: blockInfo.blockID,
                                          resultTye: .success,
                                          appId: currentUniqueId.appID,
                                          trace: context.trace)
            }
        }
    }

    func onBlockLaunchFail(error: OPError, context: OPBlockContext) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.handleError(error)
            if let blockInfo = self.currentBlockInfo, let currentUniqueId = self.currentUniqueId {
                self.monitorDisplayResult(uniqueID: blockInfo.blockTypeID,
                                          blockId: blockInfo.blockID,
                                          resultTye: .fail(errorCode: error.code, errorMessage: error.monitorCode.message),
                                          appId: currentUniqueId.appID,
                                          trace: context.trace)
            }
        }
    }

    func onBlockPause(context: OPBlockContext) {}

    func onBlockResume(context: OPBlockContext) {}

    func onBlockShow(context: OPBlockContext) {}

    func onBlockHide(context: OPBlockContext) {}

    func onBlockUpdateReady(info: OPBlockUpdateInfo, context: OPBlockContext) {}

    func onBlockCreatorSuccess(info: BlockInfo, context: OPBlockContext) {}

    func onBlockCreatorFailed(context: OPBlockContext) {}
}

extension SearchBlockTableViewCell: OPBlockWebLifeCycleDelegate {
    // 页面开始, 会发送多次
    // 每次开始加载新页面触发
    func onPageStart(url: String?, context: OPBlockContext) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.errorView.status = .loading
            self.errorView.isHidden = false
        }
    }
    // 页面加载成功, 会发送多次
    // 每次路由跳转新页面加载成功触发
    func onPageSuccess(url: String?, context: OPBlockContext) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.errorView.isHidden = true
        }
    }

    // 页面加载失败，会发送多次
    // 每次路由跳转新页面加载失败触发
    func onPageError(url: String?, error: OPError, context: OPBlockContext) {
        DispatchQueue.main.async { [weak self] in
            self?.handleError(error)
        }
    }

    // 页面运行时崩溃，会发送多次
    // 目前web场景会发送此事件，每次收到web的ProcessDidTerminate触发
    func onPageCrash(url: String?, context: OPBlockContext) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.errorView.status = .fail
            self.errorView.retryType = .reload
            self.errorView.isHidden = false
        }

    }

    // block 内容大小发生变化，会发送多次
    func onBlockContentSizeChanged(height: CGFloat, context: OPBlockContext) {
        let zoomScale = context.additionalInfo["zoomScale"] as? CGFloat ?? 1.0
        contentDidChange(withHeight: height * zoomScale)
    }
}

extension CGFloat {
    func pixelsToPoints() -> CGFloat {
        return self / UIScreen.main.scale
    }
}

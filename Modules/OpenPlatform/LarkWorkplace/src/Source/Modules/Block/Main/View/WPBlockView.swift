//
//  WPBlockView.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/2/28.
//

// swiftlint:disable file_length

import UIKit
import LarkOPInterface
import LarkInteraction
import OPBlockInterface
import OPSDK
import UniverseDesignShadow
import Blockit
import LarkContainer
import UniverseDesignTag
import LarkSetting
import RxSwift
import LarkAccountInterface
import LKCommonsLogging
import LarkNavigation
import LarkWorkplaceModel

struct WPBlockLogMessage {
    enum Level: String {
        case info
        case warn
        case error
    }
    let level: Level
    let content: String

    func formatString(withLevel: Bool) -> String {
        let prefix = withLevel ? "[\(level.rawValue)]" : ""
        let str = prefix + content.replacingOccurrences(of: "\"", with: "")
        return str
    }
}

struct ExtraBlockInfo {
    let containerID: String?
}

extension BlockModel {
    var defaultHeaderSetting: WPTemplateHeader.Setting {
        let content = WPTemplateHeader.Content(title: title, titleIconUrl: "", redirectUrl: nil, tagType: .none)
        return WPTemplateHeader.Setting(style: .none, content: content)
    }
}

final class WPBlockView: UIView {
    static let logger = Logger.log(WPBlockView.self)

    // WPBlockView 目前层级太深，解偶成本较高，后续单独处理
    let userResolver: UserResolver
    private let blockService: BlockitService?
    let userService: PassportUserService?
    let traceService: WPTraceService?
    let pageDisplayStateService: WPHomePageDisplayStateService?
    private let configService: WPConfigService?

    private var prefetchData: WPBlockPrefetchData?

    let dataManager: AppCenterDataManager?

    var isShareEnable: Bool = false
    let shareStateMachine = ShareStateMachine()
    private(set) var shareStateObservable: PublishSubject<[String]>?
    private(set) var shareForwardInfo = ShareForwardInfo()

    enum BlockStatus: String {
        case success
        case error
        case loading
    }

    enum TimerStatus: String {
        case none
        case valid
        case invalid
    }

    // 常量定义
    enum Const {
        // 宿主名称
        static let blockHost = "workplace"
        static let templateConfigKey = "templateConfig"
        // Auto 最小高度限制范围
        static let autoBlockMinHeight: CGFloat = .leastNonzeroMagnitude
    }

    /// 是否预加载block数据
    private var enablePrefetchBlock: Bool {
        return configService?.fgValue(for: .enablePrefetchBlock) ?? false
    }

    var enableBlockitTimeoutOptimize: Bool {
        return configService?.fgValue(for: .enableBlockitTimeoutOptimize) ?? false
    }

    var enableBlockConsole: Bool {
        return configService?.fgValue(for: .blockConsoleOn) ?? false
    }

    /// 小组件更新机制配置
    var updateConfig: BlockCheckUpdateConfig {
        return configService?.settingValue(BlockCheckUpdateConfig.self) ?? BlockCheckUpdateConfig.defaultValue
    }
    
    /// block自动高度最大限制
    var maxAutoHeightConfig: BlockAutoMaxHeightConfig {
        return configService?.settingValue(BlockAutoMaxHeightConfig.self) ?? BlockAutoMaxHeightConfig.defaultValue
    }

    private let disposeBag = DisposeBag()

    var blockContext: OPBlockContext?
    var blockUpdateInfo: OPBlockUpdateInfo?

    @available(*, deprecated, message: "be compatible for monitor")
    var tenantId: String? {
        return userService?.userTenant.tenantID ?? ""
    }

    // MARK: - life cycle
    init(
        userResolver: UserResolver,
        model: BlockModel,
        extraInfo: ExtraBlockInfo? = nil,
        canShowRecommand: Bool = false,
        trace: OPTrace?,
        portalId: String? = nil,
        prefetchData: WPBlockPrefetchData? = nil
    ) {
        self.userResolver = userResolver
        self.blockModel = model
        self.extraInfo = extraInfo
        self.headerSetting = model.defaultHeaderSetting
        self.canShowRecommand = canShowRecommand
        self.prefetchData = prefetchData
        self.workplaceTrace = trace
        self.portalId = portalId

        // dependency init
        self.blockService = try? userResolver.resolve(assert: BlockitService.self)
        self.traceService = try? userResolver.resolve(assert: WPTraceService.self)
        self.userService = try? userResolver.resolve(assert: PassportUserService.self)
        self.pageDisplayStateService = try? userResolver.resolve(assert: WPHomePageDisplayStateService.self)
        self.configService = try? userResolver.resolve(assert: WPConfigService.self)
        self.dataManager = try? userResolver.resolve(assert: AppCenterDataManager.self)
        let navigationService = try? userResolver.resolve(assert: NavigationService.self)

        self.retryAction = BlockRetryAction(
            appId: model.appId,
            blockId: model.blockId,
            blockTypeId: model.blockTypeId,
            navigationService: navigationService,
            configService: configService
        )
        super.init(frame: .zero)

        retryAction.action = { [weak self] in self?.loadCurrentBlock() }
        retryAction.stateProvider = { [weak self] in return self?.stateView.state }

        subviewsInit()
        gestureInit()
        observerInit()
        loadCurrentBlock()
        self.subscribeStatusForUpdate()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        Self.logger.debug("[wp] deinit: \(type(of: self))")
        blockService?.unMountBlock(id: blockModel.uniqueId)
    }

    // MARK: - override

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.shadowPath = CGPath(rect: bounds, transform: nil)
        blockInnerWrapper.layer.shadowPath = CGPath(rect: blockInnerWrapper.bounds, transform: nil)
    }

    // theme listener
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        themeDidChange()
    }

    // MARK: - public

    /// 加载的 Block 数据结构
    private(set) var blockModel: BlockModel

    /// 外部传入额外的 Block 信息
    let extraInfo: ExtraBlockInfo?

    /// 事件回调 Delegate
    weak var delegate: WPBlockViewDelegate?

    /// 是否为内置 Header 样式
    var isInnerTitleStyle: Bool? {
        switch headerSetting.style {
        case .none:
            return nil
        case .inside:
            return true
        case .outside:
            return false
        }
    }

    /// Header 右侧点击区域
    var targetViewForPad: UIView {
        blockHeader.actionArea
    }

    /// 是否在展示中
    var visible: Bool = false {
        didSet {
            guard oldValue != visible else {
                return
            }
			Self.logger.info("[wp] block cell visible change: \(blockModel.uniqueId)-\(visible)")
            if visible {
				// 此处逻辑跟调用blockit onshow无关，block cell滚动至可见时触发retry检测
                retryAction.tryTriggerRetry(with: .scrollToVisible)
            }
        }
    }
	// 宿主vc是否appear, 只与block内部的onshow、onhide事件相关
	var blockVCShow: Bool = false {
		didSet {
			guard oldValue != blockVCShow else {
				return
			}
            Self.logger.info("[wp] trigger block lifecycle: \(blockModel.uniqueId)-\(blockVCShow)")
            let lifeCycleTrigger = innerBlockContainer?.containerContext.blockContext.lifeCycleTrigger
            (lifeCycleTrigger as? OPBlockHostCustomLifeCycleTriggerProtocol)?.hostViewControllerDidAppear(blockVCShow)
		}
	}

    var canShowRecommand: Bool {
        didSet {
            updateStyleWithBlockSettings()
            updateRecommandTagView()
        }
    }

    /// 获取操作菜单选项
    func getActionItems() -> [ActionMenuItem] {
        if !Thread.isMainThread {
            assertionFailure("invoke in background thread is not thread safe!")
        }
        return actionItems
    }

    func getConsoleLogItems() -> [WPBlockLogMessage] {
        if !Thread.isMainThread {
            assertionFailure("invoke in background thread is not thread safe!")
        }
        return logMessages
    }

    func clearConsoleLogItems() {
        if !Thread.isMainThread {
            assertionFailure("invoke in background thread is not thread safe!")
        }
        logMessages.removeAll()
    }

    // MARK: - internal properties

    /// 操作菜单选项（长按或者 ... 触发）
    var actionItems: [ActionMenuItem] = []

    var logMessages: [WPBlockLogMessage] = []

    /// Block Meta 中解析的 json 配置
    var blockSettings: BlockSettings?

    /// Block 开始加载时间戳
    var blockLoadStartDate: Date = Date()

    /// Block 加载超时监听 Timer
    var loadingTimer: Timer?

    /// 获取 Block 内部的 Trace
    var blockTrace: OPTrace?

    /// 重试逻辑
    let retryAction: BlockRetryAction

    /// block加载失败归因用，判断加载超时原因：blockit没有回调、业务没有调用hideBlockLoading or工作台异常逻辑导致
    var blockitTimeout: Bool = true

    var blockBizTimeout: Bool = true

    /// State 视图（ Error 态、升级提示等）
    lazy var stateView: WPCardStateView = {
        let view = WPCardStateView()
        view.reloadAction = { [weak self] in
            guard let self = self else { return }
            self.monitor_trace()
            /// 用户点击触发重试
            self.retryAction.tryTriggerRetry(with: .userClick)
        }
        return view
    }()

    /// OPBlock 内部的 Block Container，相对于操作 Block 的一个句柄
    var innerBlockContainer: OPBlockContainerProtocol?

    /// 解析出的 Block Header 相关配置
    var headerSetting: WPTemplateHeader.Setting

    var portalId: String?

    // MARK: - private properties

    /// 监听 Block 容器 Size 变化的 Observation
    private var resizeObservation: NSKeyValueObservation?

    /// 工作台Trace
    private var workplaceTrace: OPTrace?

    // MARK: - private subviews

    /// 整体的 wrapper，透明，用于 self 同时展示阴影和圆角
    private lazy var blockOuterWrapper: UIView = {
        let view = UIView()
        view.clipsToBounds = false
        return view
    }()

    /// BlockView 的 wrapper，透明，用于 Block 同时展示阴影和圆角
    private lazy var blockInnerWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    /// Block - Header（编辑器配置和开发者统一使用这个header）
    private(set) lazy var blockHeader: WPTemplateHeader = {
        let header = WPTemplateHeader()
        header.actionDelegate = self
        return header
    }()

    /// Block Render Slot（请勿移除 @objc，否则 KVO 可能会出现 Crash）
    @objc var blockRenderView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    /// 推荐 tag，无 header 的推荐 block 加在 innerWrapper 上，有 header 的加在 header 上
    private lazy var recommandTagView: UDTag = {
        let tagView = UDTag(text: "", textConfig: UDTagConfig.TextConfig())
        tagView.wp_updateType(.recommandBlock)
        tagView.isHidden = true
        return tagView
    }()
}

// MARK: - init

extension WPBlockView {

    private func subviewsInit() {
        setupStyles()
        setupViewHierarchy()
        setupViewConstraints()
        updateStyleWithBlockSettings()
    }

    private func setupStyles() {
        backgroundColor = .clear
    }

    private func setupViewHierarchy() {
        /* view hierarchy
         - blockOuterWrapper
            - blockHeader
            - recommendTagView
            - blockInnerWrapper
                - blockRenderView
         - stateView
        */
        addSubview(blockOuterWrapper)
        addSubview(stateView)

        blockOuterWrapper.addSubview(blockHeader)
        blockOuterWrapper.addSubview(blockInnerWrapper)
        blockOuterWrapper.addSubview(recommandTagView)
        blockInnerWrapper.addSubview(blockRenderView)
    }

    private func setupViewConstraints() {
        blockOuterWrapper.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        blockHeader.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        blockInnerWrapper.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(blockHeader.snp.bottom).offset(0)
        }
        blockRenderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stateView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        recommandTagView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(18)
        }
    }

    private func observerInit() {
        resizeObservation = observe(
            \.blockRenderView.bounds,
            options: [.new, .old],
            changeHandler: { [weak self] (_, change) in
                guard let self = self, let newSize = change.newValue else {
                    return
                }
                guard let oldSize = change.oldValue, !oldSize.equalTo(.zero) else {
                    // 首次回调不触发
                    return
                }
                if self.blockModel.isAutoSizeBlock, newSize.width == oldSize.width {
                    // 自适应高度的 Block，高度触发 resize, 不回调
                    return
                }
                do {
                    self.monitor_trace(info: ["size_change": "\(change)"])
                    let height: Any = self.blockModel.isAutoSizeBlock ? TMPLBlockStyles.autoHightValue : newSize.height
                    try self.trigger(api: .onContainerResize, params: [
                        "width": newSize.width,
                        "height": height
                    ])
                } catch {
                    self.monitor_trace(error: error)
                }
            }
        )
    }

    func updateBlockState(_ state: WPCardStateView.State) {
        stateView.state = state
        blockOuterWrapper.isHidden = (state != .running)
    }

    /// Update block styles with block settings declared by developer.
    /// Use default settings if block's config file haven't been ready.
    func updateStyleWithBlockSettings() {
        updateHeaderStyleWithBlockSettings()
        updateContainerStyleWithBlockSettings()
    }

    /// Update block header hidden state, constraints, content with settings set by developer.
    /// Use default settings if block's config file haven't been loaded.
    private func updateHeaderStyleWithBlockSettings() {
        // -- Update block header hidden state and constraints --
        switch headerSetting.style {
        case .none:
            blockHeader.isHidden = true
            blockHeader.snp.updateConstraints { (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(0)
            }
        case .inside:
            blockHeader.isHidden = false
            blockHeader.snp.updateConstraints { (make) in
                make.left.right.equalToSuperview().inset(14)
                make.height.equalTo(commonInnerTitleHeight)
            }
        case .outside:
            blockHeader.isHidden = false
            blockHeader.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(-4)
                make.right.equalToSuperview().offset(2)
                make.height.equalTo(commonOutterTitleHeight + commonOutterTitleGap)
            }
        }
        // -- Update block header content && block header action menu --
        blockHeader.showActionArea = !actionItems.isEmpty
        /// 因为这时常用区域的状态（默认态、编辑态）可能和parseHeader时不同，比如在load完之后状态被修改，因此需要重新获取一下tagType
        let tagType: WPCellTagType = canShowRecommand && blockModel.isTemplateRecommand ? .recommandBlock : .none
        let content = WPTemplateHeader.Content(
            title: headerSetting.content?.title ?? "",
            titleIconUrl: headerSetting.content?.titleIconUrl ?? "",
            redirectUrl: headerSetting.content?.redirectUrl,
            tagType: tagType
        )
        self.headerSetting = WPTemplateHeader.Setting(style: headerSetting.style, content: content)
        blockHeader.refresh(setting: self.headerSetting)
    }

    /// Update block containers' border and background color with block settings declared by developer
    /// When block's config file isn't ready, use default block settings.
    /// Block in different bussiness scene have different appearance.
    private func updateContainerStyleWithBlockSettings() {
        let supportDarkMode = blockSettings?.darkmode ?? false
        let showFrame = blockSettings?.showFrame ?? true

        switch blockModel.scene {
        case .templateComponent:
            let cornerRadius = blockModel.styles?.backgroundRadius ?? 0.0
            if headerSetting.style == .outside {
                layer.ud.setShadowColor(UIColor.clear)

                if showFrame {
                    //blockInnerWrapper.layer.ud.setShadow(type: UDShadowType.s2Down)
                    blockRenderView.layer.cornerRadius = cornerRadius
                    let bgColor = supportDarkMode ? UIColor.ud.bgFloat : UIColor.ud.bgFloat.alwaysLight
                    blockRenderView.backgroundColor = bgColor
                    blockRenderView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
                    blockRenderView.layer.borderWidth = WPUIConst.BorderW.px1
                } else {
                    blockInnerWrapper.layer.ud.setShadowColor(UIColor.clear)

                    /// 由于第一次reloadHeader拿不到blockSettings，showFrame默认是true
                    /// 所以在后续获取到的showFrame是false时要重新设置一下blockRenderView背景和边框透明
                    blockRenderView.layer.cornerRadius = 0
                    blockRenderView.backgroundColor = UIColor.clear
                    blockRenderView.layer.ud.setBorderColor(UIColor.clear)
                    blockRenderView.layer.borderWidth = 0
                }
                blockOuterWrapper.clipsToBounds = false
                blockOuterWrapper.layer.cornerRadius = 0.0
                blockOuterWrapper.backgroundColor = UIColor.clear
                blockOuterWrapper.layer.borderWidth = 0.0

                stateView.radius = cornerRadius
                stateView.shadowEnable = true
                stateView.borderEnable = true
            } else {
                if showFrame {
                    //layer.ud.setShadow(type: UDShadowType.s2Down)

                    blockOuterWrapper.clipsToBounds = true
                    blockOuterWrapper.layer.cornerRadius = cornerRadius
                    blockOuterWrapper.backgroundColor = UIColor.ud.bgFloat
                    blockOuterWrapper.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
                    blockOuterWrapper.layer.borderWidth = WPUIConst.BorderW.px1
                } else {
                    layer.ud.setShadowColor(UIColor.clear)

                    /// 由于第一次reloadHeader拿不到blockSettings，showFrame默认是true
                    /// 所以在后续获取到的showFrame是false时要重新设置一下blockOuterWrapper背景和边框透明
                    blockOuterWrapper.clipsToBounds = false
                    blockOuterWrapper.layer.cornerRadius = 0
                    blockOuterWrapper.backgroundColor = UIColor.clear
                    blockOuterWrapper.layer.ud.setBorderColor(UIColor.clear)
                    blockOuterWrapper.layer.borderWidth = 0
                }

                blockInnerWrapper.layer.ud.setShadowColor(UIColor.clear)

                stateView.radius = cornerRadius
                stateView.shadowEnable = !showFrame
                stateView.borderEnable = true

                blockRenderView.layer.cornerRadius = 0.0
                let bgColor =
                    showFrame ? (supportDarkMode ? UIColor.clear : UIColor.ud.bgFloat.alwaysLight) : UIColor.clear
                blockRenderView.backgroundColor = bgColor
            }
        // Block demo样式要求
        case .demoBlock:
            let cornerRadius = blockModel.styles?.backgroundRadius ?? 0.0

            layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
            layer.shadowOffset = CGSize(width: 0, height: 4)
            layer.shadowOpacity = 1.0
            layer.shadowRadius = 16

            blockInnerWrapper.layer.ud.setShadowColor(UIColor.clear)

            blockOuterWrapper.clipsToBounds = true
            blockOuterWrapper.layer.cornerRadius = cornerRadius
            blockOuterWrapper.backgroundColor = UIColor.ud.bgFloat
            blockOuterWrapper.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
            blockOuterWrapper.layer.borderWidth = WPUIConst.BorderW.px1

            stateView.radius = cornerRadius
            stateView.shadowEnable = false
            blockRenderView.layer.cornerRadius = 0.0
            blockRenderView.backgroundColor = supportDarkMode ? UIColor.clear : UIColor.ud.bgFloat.alwaysLight
        default:
            // 原版工作台 Block，style 只可能是 .none or .blockInside
            //layer.ud.setShadow(type: UDShadowType.s2Down)

            blockInnerWrapper.layer.ud.setShadowColor(UIColor.clear)

            blockOuterWrapper.clipsToBounds = true
            blockOuterWrapper.layer.cornerRadius = WorkPlaceWidgetCell.widgetRadius
            blockOuterWrapper.backgroundColor = UIColor.ud.bgFloat
            blockOuterWrapper.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
            blockOuterWrapper.layer.borderWidth = WPUIConst.BorderW.px1

            stateView.radius = WorkPlaceWidgetCell.widgetRadius
            stateView.shadowEnable = false
            blockRenderView.layer.cornerRadius = 0.0
            blockRenderView.backgroundColor = supportDarkMode ? UIColor.clear : UIColor.ud.bgFloat.alwaysLight
        }
    }

    func updateRecommandTagView() {
        if headerSetting.style == .none && canShowRecommand && blockModel.isTemplateRecommand {
            recommandTagView.isHidden = false
            return
        } else {
            recommandTagView.isHidden = true
        }
    }

    private func subscribeStatusForUpdate() {
        Self.logger.info("[wp]subscribe status for update", additionalData: [
            "blockCheckUpdateEnable": "\(updateConfig.blockCheckUpdateEnable)",
            "isInBlackList": "\(updateConfig.blockCheckUpdateBlackList.contains(blockModel.appId))",
            "appId": "\(self.blockModel.appId)"
        ])

        // swiftlint:disable closure_body_length
        pageDisplayStateService?.subscribePageState()
            .subscribe(onNext: { [weak self] state in
                guard let `self` = self,
                      self.updateConfig.blockCheckUpdateEnable,
                      !self.updateConfig.blockCheckUpdateBlackList.contains(self.blockModel.appId) else {
                    return
                }

                Self.logger.info("[wp]page display state changed", additionalData: [
                    "currentState": "\(state.rawValue)"
                ])
                switch state {
                case .selected:
                    if let updateInfo = self.blockUpdateInfo {
                        Self.logger.info("[wp]start update block", additionalData: [
                            "updateInfoType": "\(updateInfo)",
                            "appId": "\(self.blockModel.appId)"
                        ])
                        self.loadCurrentBlock()
                    }
                    return
                case .show, .hide:
                    if let blockContext = self.blockContext {
                        Self.logger.info("[wp]start check block update", additionalData: [
                            "appId": "\(self.blockModel.appId)"
                        ])
                        blockContext.blockAbilityHandler?.checkBlockUpdate()
                    }
                    return
                default:
                    return
                }
        })
        .disposed(by: disposeBag)
        // swiftlint:enable closure_body_length
    }
}

// MARK: - block

extension WPBlockView {

    private func clearCurrentBlock() {
        Self.logger.info("[wp] block clear: \(blockModel.uniqueId)")
        blockSettings = nil
        headerSetting = blockModel.defaultHeaderSetting
        actionItems.removeAll()
        blockService?.unMountBlock(id: blockModel.uniqueId)
        blockTrace = nil
        loadingTimer?.invalidate()
        loadingTimer = nil
        blockitTimeout = true
        blockBizTimeout = true
        blockContext = nil
        blockUpdateInfo = nil
    }

    /// 加载 Block 数据，需在主线程调用
    func loadCurrentBlock(forceUpdateMeta: Bool = false) {
        clearCurrentBlock()
        updateBlockState(.loading)
        if !enableBlockitTimeoutOptimize { startTimer() }
        Self.logger.info("[wp] block mount: \(blockModel.uniqueId)")

        let config = OPBlockContainerConfig(
            uniqueID: blockModel.uniqueId,
            blockLaunchMode: .default,
            previewToken: blockModel.previewToken ?? "",
            host: Const.blockHost
        )

        blockTrace = config.trace
        monitor_setup(forceUpdate: forceUpdateMeta)
        if let workplaceTrace = self.workplaceTrace {
            blockService?.linkBlockTrace(
                hostTrace: workplaceTrace as OPTraceProtocol,
                blockTrace: config.trace as OPTraceProtocol
            )
        }
        config.customApis = WPBlockAPI.allApis(for: enableBlockitTimeoutOptimize)
        config.blockLaunchType = forceUpdateMeta ? .forceUpdate : .default
        config.containerID = extraInfo?.containerID
        config.isCustomLifecycle = true
        config.useCacheWhenEntityFetchFails = true
        config.showPickerInWindow = true
        if enableBlockitTimeoutOptimize { config.bizTimeoutInterval = retryAction.retryConfig.loadingTimeout }

        if let templateConfig = blockModel.editorProps?.templateConfig?.dictionaryObject {
            config.dataCollection = [Const.templateConfigKey: templateConfig]
        }

        let blockInfo = OPBlockInfo(
            blockID: blockModel.blockId,
            blockTypeID: blockModel.uniqueId.identifier,
            sourceData: blockModel.sourceData ?? [:]
        )
        config.blockInfo = blockInfo
        let slot = OPViewRenderSlot(view: self.blockRenderView, defaultHidden: false)
        let data = OPBlockContainerMountData(scene: .undefined)
        let plugins = [
            BlockCellPlugin(delegate: self, enableBlockitTimeoutOptimize: enableBlockitTimeoutOptimize)
        ]

        let guideInfoProvider = BlockGuideInfoProvider(blockGuideInfo: prefetchData?.blockGuideInfo)
        let entityProvider = BlockEntityProvider(blockInfo: prefetchData?.blockEntity)
        if enablePrefetchBlock,
           prefetchData?.blockEntity != nil,
           let blockitParam = try? BlockitParamBuilder()
            .setMountType(mountType: .entity)
            .setBlockID(blockID: blockModel.blockId)
            .setBlockTypeID(blockTypeID: blockModel.blockTypeId)
            .setSlotView(slot: slot)
            .setData(data: data)
            .setConfig(config: config)
            .setPlugins(plugins: plugins)
            .setDelegate(delegate: self)
            .addDataProvider(dataProvider: guideInfoProvider)
            .addDataProvider(dataProvider: entityProvider)
            .build() {
            blockService?.mountBlock(byParam: blockitParam)
        } else {
            /// 兜底逻辑
            Self.logger.warn("use previous api to mount block", additionalData: [
                "enablePrefetchBlock": "\(enablePrefetchBlock)",
                "hasEntity": "\(prefetchData?.blockEntity != nil)"
            ])
            if blockModel.isStandardBlock {
                blockService?.mountBlock(
                    byEntity: blockInfo,
                    slot: slot,
                    data: data,
                    config: config,
                    plugins: plugins,
                    delegate: self
                )
            } else {
                let blkId = blockModel.blockId
                blockService?.mountBlock(
                    byID: blkId,
                    slot: slot,
                    data: data,
                    config: config,
                    plugins: plugins,
                    delegate: self
                )
            }
        }
    }

    private func startTimer() {
        let timer = Timer(
            timeInterval: TimeInterval(retryAction.retryConfig.loadingTimeout) / 1_000.0,
            target: self,
            selector: #selector(blockLoadTimeout(_:)),
            userInfo: nil,
            repeats: false
        )
        RunLoop.main.add(timer, forMode: .common)
        loadingTimer = timer
    }

    /// Block 加载超时处理
    @objc private func blockLoadTimeout(_ sender: Timer) {
        self.loadingTimer?.invalidate()
        self.loadingTimer = nil
        // 超时视为加载失败
        switch stateView.state {
        case .loadFail:
            break
        default:
            self.monitor_blockShowFail(["error_code": 100 /* timeout */])
            updateBlockState(.loadFail(.create(
                name: self.parseHeaderSetting().content?.title ?? self.blockModel.title,
                monitorCode: WPMCode.workplace_block_show_fail
            )))
        }
        /// 超时尝试触发 retry
        retryAction.tryTriggerRetry(with: .loadingTimeout)
    }

    /// 触发一个自定义的 API（ Native -> Block ）
    func trigger(api: WPBlockAPI.OnAPI, params: [AnyHashable: Any]) throws {
        try innerBlockContainer?.bridge.sendEvent(
            eventName: api.rawValue,
            params: params,
            callback: nil
        )
    }

    func shouldHandleBlockEvent(context: OPBlockContext) -> Bool {
        return context.trace == blockTrace
    }
}

// MARK: - HeaderViewDelegate

extension WPBlockView: HeaderViewDelegate {
    /// 标题点击
    func onTitleClick(_ view: WPTemplateHeader, url: String) {
        event_blockClick(.blockTitle)
        delegate?.onTitleClick(self, link: url)
    }
    /// 交互按钮点击
    func onActionClick(_ view: WPTemplateHeader) {
        event_blockClick(.more)
        delegate?.onActionClick(self)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension WPBlockView: UIGestureRecognizerDelegate {
    // 添加手势识别
    private func gestureInit() {
        // 右键或长按手势，用于展示菜单选项
        let ges1 = RightOrLongGestureRecognizer(target: self, action: #selector(press(_:)))
        // 点击手势，目前仅用于埋点
        let ges2 = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        ges1.delegate = self
        ges2.delegate = self
        addGestureRecognizer(ges1)
        blockRenderView.addGestureRecognizer(ges2)
    }

    @objc
    private func press(_ sender: UIGestureRecognizer) {
        if blockModel.scene == .templateCommon {
            delegate?.onLongPress(self, gesture: sender)
            return
        }

        if sender.state == .began {
            delegate?.onLongPress(self, gesture: sender)
        }
    }

    @objc
    private func tap(_ sender: UITapGestureRecognizer) {
        event_blockClick(.block)
    }

    // 让 WPBlockView 手势能与其它 View 的手势共存
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    // 防止长按时，触发 LynxView 的点击事件
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if gestureRecognizer is RightOrLongGestureRecognizer {
            // 如果是 WPBlockView 的长按(右键)手势，中断其它手势的识别
            return true
        }
        return false
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // swiftlint:disable unused_optional_binding
        if let _ = gestureRecognizer as? UILongPressGestureRecognizer {
            // swiftlint:enable unused_optional_binding
            return delegate?.longGestureShouldBegin(gestureRecognizer) ?? true
        }
        return true
    }
}

// MARK: - OPBlockHostProtocol

extension OPBlockDebugLogLevel {
    var wpLevel: WPBlockLogMessage.Level {
        switch self {
        case .info: return .info
        case .warn: return .warn
        case .error: return .error
        @unknown default:
            return .info
        }
    }
}

// MARK: - BlockCellPluginDelegate

extension WPBlockView: BlockCellPluginDelegate {
    func handleAPI(
        _ plugin: BlockCellPlugin,
        api: WPBlockAPI.InvokeAPI,
        param: [AnyHashable: Any],
        callback: @escaping WPBlockAPICallback
    ) {
        monitor_blockAPIInvoke(api)
        switch api {
        case .addMenuItem:
            addMenuItem(param: param, callback: callback)
        case .removeMenuItem:
            removeMenuItem(param: param, callback: callback)
        case .updateMenuItem:
            updateMenuItem(param: param, callback: callback)
        case .getHostInfo:
            getHostInfo(callback)
        case .getContainerRect:
            getContainerRect(callback)
        case .hideBlockLoading:
            hideBlockLoading(callback)
        case .tryHideBlock:
            Self.logger.info("[WPBlockView] old-api jsb tryHideBlock success")
            delegate?.tryHideBlock(self)
        default:
            delegate?.handleAPI(plugin, api: api, param: param, callback: callback)
        }
    }

    /// 添加一个开发者 BlockHeader 菜单项
    private func addMenuItem(param: [AnyHashable: Any], callback: @escaping WPBlockAPICallback) {
        // swiftlint:disable closure_body_length
        DispatchQueue.main.async {
            do {
                let data = try JSONSerialization.data(withJSONObject: param, options: [])
                let info = try JSONDecoder().decode(BlkAPIDataAddMenuItem.self, from: data)
                guard let key = info.menuItem.key, !key.isEmpty else {
                    let opError = OPError.error(
                        monitorCode: WPMCode.workplace_internal_error.wp_mCode,
                        message: "empty key"
                    )
                    callback(.failure(opError))
                    return
                }
                guard !info.menuItem.iconUrl.isEmpty else {
                    let opError = OPError.error(
                        monitorCode: WPMCode.workplace_internal_error.wp_mCode,
                        message: "empty iconUrl"
                    )
                    callback(.failure(opError))
                    return
                }
                // swiftlint:disable contains_over_first_not_nil
                guard self.actionItems.firstIndex(where: { $0.key == key }) == nil else {
                    // swiftlint:enable contains_over_first_not_nil
                    let opError = OPError.error(
                        monitorCode: WPMCode.workplace_internal_error.wp_mCode,
                        message: "exist key"
                    )
                    callback(.failure(opError))
                    return
                }
                let item = ActionMenuItem.developerItem(origin: info.menuItem, action: { [weak self] obj in
                    self?.onDeveloperItemClick(item: obj)
                })
                let acitonEmpty = self.actionItems.isEmpty
                self.actionItems.append(item)
                if acitonEmpty {
                    // 之前没有acitonItem不展示入口，此时新增item需要刷新展示入口
                    self.blockHeader.showActionArea = true
                }
                callback(.success(nil))
            } catch {
                let opError = error.newOPError(
                    monitorCode: WPMCode.workplace_internal_error.wp_mCode,
                    message: "invalid params"
                )
                callback(.failure(opError))
            }
        }
        // swiftlint:enable closure_body_length
    }

    /// 开发者 BlockHeader 菜单项点击事件回调
    func onDeveloperItemClick(item: TMPLMenuItem) {
        do {
            let mData = try JSONEncoder().encode(item)
            let mParam = try JSONSerialization.jsonObject(with: mData, options: [])
            guard let dict = mParam as? [AnyHashable: Any] else {
                monitor_trace()
                return
            }
            try trigger(api: .onMenuItemTap, params: dict)
        } catch {
            monitor_trace(error: error)
        }
    }

    /// 移除一个开发者 BlockHeader 菜单项
    private func removeMenuItem(param: [AnyHashable: Any], callback: @escaping WPBlockAPICallback) {
        DispatchQueue.main.async {
            guard let key = param["key"] as? String, !key.isEmpty else {
                let opError = OPError.error(
                    monitorCode: WPMCode.workplace_internal_error.wp_mCode,
                    message: "empty key"
                )
                callback(.failure(opError))
                return
            }
            let beforeActionNotEmpty = !self.actionItems.isEmpty
            self.actionItems = self.actionItems.filter({ $0.key != key })
            if beforeActionNotEmpty, self.actionItems.isEmpty {
                self.blockHeader.showActionArea = false
            }
            callback(.success(nil))
        }
    }

    /// 更新一个开发者 BlockHeader 菜单项
    private func updateMenuItem(param: [AnyHashable: Any], callback: @escaping WPBlockAPICallback) {
        // swiftlint:disable closure_body_length
        DispatchQueue.main.async {
            do {
                let data = try JSONSerialization.data(withJSONObject: param, options: [])
                let info = try JSONDecoder().decode(BlkAPIDataUpdateMenuItem.self, from: data)
                let key = info.menuItem.key
                guard !key.isEmpty else {
                    let opError = OPError.error(
                        monitorCode: WPMCode.workplace_internal_error.wp_mCode,
                        message: "empty key"
                    )
                    callback(.failure(opError))
                    return
                }
                guard let idx = self.actionItems.firstIndex(where: { $0.key == key }) else {
                    let opError = OPError.error(
                        monitorCode: WPMCode.workplace_internal_error.wp_mCode,
                        message: "key not found"
                    )
                    callback(.failure(opError))
                    return
                }
                self.actionItems[idx].updateDeveloperItem(with: info.menuItem)
                callback(.success(nil))
            } catch {
                let opError = error.newOPError(
                    monitorCode: WPMCode.workplace_internal_error.wp_mCode,
                    message: "invalid params"
                )
                callback(.failure(opError))
            }
        }
        // swiftlint:enable closure_body_length
    }

    private func getHostInfo(_ callback: @escaping WPBlockAPICallback) {
        DispatchQueue.main.async {
            do {
                let blockRenderWidth = self.blockRenderView.bounds.size.width
                let blockRenderHeight = self.blockRenderView.bounds.size.height

                let info = BlkCBDataHostInfo(
                    host: BlkCBDataHostInfo.HostValue,
                    viewWidth: blockRenderWidth,
                    viewHeight: blockRenderHeight
                )

                let data = try JSONEncoder().encode(info)
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any]
                callback(.success(dict))
            } catch {
                let opError = error.newOPError(
                    monitorCode: WPMCode.workplace_internal_error.wp_mCode,
                    message: "invalid params"
                )
                callback(.failure(opError))
            }
        }
    }

    private func getContainerRect(_ callback: @escaping WPBlockAPICallback) {
        DispatchQueue.main.async {
            let blockRenderWidth = self.blockRenderView.bounds.size.width
            let blockRenderHeight = self.blockRenderView.bounds.size.height
            let rect: [AnyHashable: Any]
            if self.blockModel.isAutoSizeBlock {
                rect = [
                    "width": blockRenderWidth,
                    "height": TMPLBlockStyles.autoHightValue
                ]
            } else {
                rect = [
                    "width": blockRenderWidth,
                    "height": blockRenderHeight
                ]
            }
            callback(.success(rect))
        }
    }

    func hideBlockLoading(_ callback: WPBlockAPICallback?) {
        blockBizTimeout = false
        monitorHideBlockLoading()
        DispatchQueue.main.async {
            self.monitor_trace()
            guard self.blockSettings?.useStartLoading == true else {
                // 没有配置 useStartLoading，调用 api 无效
                let opError = OPError.error(
                    monitorCode: OPBlockitAPIMonitorCode.hideBlockLoading_config_missing,
                    message: "config missing"
                )
                callback?(.failure(opError))
                return
            }
            guard let timer = self.loadingTimer, timer.isValid, self.stateView.state == .loading else {
                // timer 已经超时，或者其它原因已经不在 loading 态了 直接返回success
                callback?(.success(nil))
                return
            }
            if self.stateView.state != .running {
                self.monitor_blockShowContent(useStartLoading: true)
            }
            self.updateBlockState(.running)

            self.loadingTimer?.invalidate()
            self.loadingTimer = nil

            callback?(.success(nil))
        }
    }
}

extension WPBlockView {
    class ShareStateMachine {
        static let logger = Logger.log(ShareStateMachine.self)

        enum State {
            case emptyState
            case startGetShareInfo
            case getShareInfoSuccess
            case getShareInfoTimeout
        }

        enum Event {
            case start
            case success
            case timeout
        }

        private(set) var state: State = .emptyState

        @discardableResult func proceed(with event: Event) -> Bool {
            switch (state, event) {
            case (.emptyState, .start):
                state = .startGetShareInfo
            case (.startGetShareInfo, .success):
                state = .getShareInfoSuccess
            case (.startGetShareInfo, .timeout):
                state = .getShareInfoTimeout
            case (.getShareInfoSuccess, .start), (.getShareInfoTimeout, .start):
                state = .startGetShareInfo
            case (.getShareInfoSuccess, .timeout), (.getShareInfoTimeout, .success):
                return false
            default:
                assertionFailure("should not be here")
                Self.logger.error("unexpected state change attempt: \(state) -> \(event)")
                return false
            }
            return true
        }
    }

    struct ShareForwardInfo {
        var receivers: [WPMessageReceiver] = []
        var leaveMessage: String?
    }

    func share(receivers: [WPMessageReceiver], leaveMessage: String?) -> Observable<[String]>? {
        postBlockShare(receivers: receivers)
        do {
            // send get block share info request
            try trigger(api: .getBlockShareInfo, params: [:])
            shareStateObservable = PublishSubject<[String]>()
            shareForwardInfo = ShareForwardInfo(receivers: receivers, leaveMessage: leaveMessage)
            // start timer
            shareStateMachine.proceed(with: .start)
            let timeoutCallback = DispatchWorkItem(block: { [weak self] in self?.checkIfGetShareInfoTimeout() })
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(5), execute: timeoutCallback)
        } catch {
            monitor_trace(error: error)
            return nil
        }
        return shareStateObservable?.asObservable()
    }

    private func checkIfGetShareInfoTimeout() {
        let stateProceedSuccess = shareStateMachine.proceed(with: .timeout)
        if !stateProceedSuccess { return }
        // get block share info timeout
        Self.logger.error("get block share info timeout.", additionalData: identityInfo)
        shareStateObservable?.onError(NSError(domain: "block share timeout", code: -1))
    }
}

// swiftlint:enable file_length

//
//  BTContainer+Status.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/14.
//

import SKFoundation
import SKCommon
import LarkUIKit
import SKUIKit
import SKBrowser
import UniverseDesignTheme

enum UpdateStatusStage {
    case animationBeginStage              // 动画开始之前的阶段
    case animationEndStage                // 动画结束时的阶段
    case finalStage                       // 最终稳定阶段(动画 finished 后会调用一次)
}

enum ViewContainerType {
    case hasViewCatalogNoToolBar
    case noViewCatalogNoToolBar
    case hasViewCatalogHasToolBar
}

enum HeaderMode {
    case fixedHidden
    case fixedShow
    case canSwitch                      // 可以切换，webview 底部会超出屏幕，上下 switch 时 webview 整体向上平移，不会触发 webview resize
    case canSwitchFixBottom             // 可以切换，但是 webview 底部不会超出屏幕，因此上下 switch 时会触发 webview resize
}

enum HostType {
    case normal
    case templatePreview
}

enum ContainerState {
    case normal
    case statePgae  // 失败页，权限申请页
}

enum FullScreenType {
    case none                           // 不全屏
    case webFullScreen                  // web 全部全屏，导航栏和状态栏不显示
    case webFullScreenShowNaviBar       // web 全部全屏，但是显示导航栏
    case webFullScreenShowStatusBar     // web 全屏到状态栏以下
}

struct BTContainerStatus {
    // MARK: ----------基本属性----------
    fileprivate(set) var statusVersion: Int = 0
    
    // 是否隐藏 Base 头
    fileprivate(set) var baseHeaderHidden: Bool = false
    
    // 是否隐藏 Block 目录
    fileprivate(set) var blockCatalogueHidden: Bool = true
    
    // 是否隐藏 ToolBar
    fileprivate(set) var toolBarHidden: Bool = false
    
    // VC 尺寸变化（包括了横竖屏切换）
    fileprivate(set) var containerSize: CGSize = .zero {
        didSet {
            updateProperties()
        }
    }
    
    // mainContainer 尺寸变化
    fileprivate(set) var mainContainerSize: CGSize = .zero {
        didSet {
            updateProperties()
        }
    }
    
    // 顶部容器的高度
    fileprivate(set) var topContainerHeight: CGFloat = 56 {
        didSet {
            updateProperties()
        }
    }
    // Base 头的高度
    fileprivate(set) var headerTitleHeight: CGFloat = 0 {
        didSet {
            updateProperties()
        }
    }
    
    // 强制 Web 全屏（新收集表）
    fileprivate var forceFullScreen: Bool = false {
        didSet {
            updateProperties()
        }
    }
    // 屏幕方向
    fileprivate(set) var orientation: UIInterfaceOrientation = .unknown {
        didSet {
            updateProperties()
        }
    }
    // 来自前端设置的 sceneModel
    fileprivate(set) var sceneModel: ContainerSceneModel = ContainerSceneModel() {
        didSet {
            updateProperties()
        }
    }
    // 加载场景
    fileprivate(set) var hostType: HostType = .normal {
        didSet {
            updateProperties()
        }
    }
    
//    fileprivate(set) var loadStatus: LoadStatus = .unknown {
//        didSet {
//            updateProperties()
//        }
//    }
    
    fileprivate(set) var containerState: ContainerState = .normal {
        didSet {
            updateProperties()
        }
    }
    
    fileprivate(set) var darkMode: Bool = Self.isDarkMode() {
        didSet {
            updateProperties()
        }
    }
    
    // web 内加载失败
    fileprivate var webFailed: Bool = false {
        didSet {
            updateProperties()
        }
    }
    
    // container 框架数据加载超时
    fileprivate var containerTimeout: Bool = false {
        didSet {
            updateProperties()
        }
    }
    
    // 记录分享不显示 Header
    fileprivate var recordNoHeader: Bool = false {
        didSet {
            updateProperties()
        }
    }
    
    // 记录分享卡片正在显示
    fileprivate var indRecordShow: Bool = false {
        didSet {
            updateProperties()
        }
    }
    
    // MARK: ----------计算属性----------
    // 是否是宽屏模式
    var isRegularMode: Bool {
        get {
            containerSize.width >= BTContainer.Constaints.regularModeMinWidth
        }
    }
    
    var blockCatalogueWidth: CGFloat {
        get {
            if isRegularMode {
                return min(containerSize.width / 2, BTContainer.Constaints.blockCatalogueMaxWidth)
            } else {
                return containerSize.width - BTContainer.Constaints.viewContainerRemainWidth
            }
        }
    }
    
    var mainViewContainerEnable: Bool {
        get {
            isRegularMode || blockCatalogueHidden
        }
    }
    
    // 根据当前是否显示 block container 决定的实际宽度
    var targetBlockAreaWidth: CGFloat {
        get {
            return (self.isRegularMode && !blockCatalogueHidden) ? (blockCatalogueWidth) : 0
        }
    }
    
    var headerMode: HeaderMode {
        get {
            // 当AI 配置面板弹出时，固定header
            if sceneModel.showAiConfigForm == true {
                if baseHeaderHidden {
                    return .fixedHidden
                } else {
                    return .fixedShow
                }
            }
            if hostType == .templatePreview {
                return .fixedShow
            }
            if !Display.pad, orientation.isLandscape {
                return .fixedHidden    // iPhone 横屏固定，不允许上下切换 Header
            }
            if UserScopeNoChangeFG.LYL.disableFixHeaderModeCheckFullScreen {
                if fullScreenType != .none {
                    return .fixedHidden    // 全屏模式，强制隐藏
                }
            }
            if let blockType = sceneModel.blockType {
                if UserScopeNoChangeFG.LYL.disableAllViewAnimation {
                    switch blockType {
                    case .dashboard:
                        return .fixedShow
                    case .linkedDocx:
                        return .fixedShow
                    case .table:
                        if let viewType = sceneModel.viewType {
                            switch viewType {
                            case .grid:
                                return .canSwitch
                            case .kanban:
                                return .fixedShow
                            case .gallery:
                                return .fixedShow
                            case .gantt:
                                return .fixedShow
                            case .form:
                                return .fixedShow
                            case .hierarchy:
                                return .canSwitch
                            case .calendar:
                                return .fixedShow
                            case .widgetView:
                                return .fixedShow
                            }
                        }
                    }
                } else {
                    switch blockType {
                    case .dashboard:
                        return .canSwitch
                    case .linkedDocx:
                        return .canSwitchFixBottom
                    case .table:
                        if let viewType = sceneModel.viewType {
                            switch viewType {
                            case .grid:
                                return .canSwitch
                            case .kanban:
                                return .canSwitchFixBottom
                            case .gallery:
                                return .canSwitch
                            case .gantt:
                                return .canSwitch
                            case .form:
                                // BTRecord resize 会重影，所以这里让其超出屏幕
                                return .canSwitch
                            case .hierarchy:
                                return .canSwitch
                            case .calendar:
                                return .canSwitchFixBottom
                            case .widgetView:
                                return .canSwitchFixBottom
                            }
                        }
                    }
                }
            }
            return .fixedShow
        }
    }
    
    var viewContainerType: ViewContainerType {
        get {
            guard let blockType = sceneModel.blockType else {
                return .noViewCatalogNoToolBar
            }
            switch blockType {
            case .dashboard:
                return .noViewCatalogNoToolBar
            case .linkedDocx:
                return .noViewCatalogNoToolBar
            case .table:
                guard let viewType = sceneModel.viewType else {
                    return .noViewCatalogNoToolBar
                }
                if viewType.shouldToolBar {
                    return .hasViewCatalogHasToolBar
                } else {
                    return .hasViewCatalogNoToolBar
                }
            }
        }
    }
    
//    var toolBarHidden: Bool {
//        if viewContainerType != .hasViewCatalogHasToolBar {
//            return true
//        }
//        if baseHeaderHidden {
//            return canSwitchToolBar
//        } else {
//            return false
//        }
//    }
    
    var canSwitchToolBar: Bool {
        if viewContainerType != .hasViewCatalogHasToolBar {
            return false
        }
        if let blockType = sceneModel.blockType,
           blockType == .table,
           let viewType = sceneModel.viewType {
            return viewType.canSwitchToolBar
        }
        return false
    }
    
    var webviewBottomOffset: CGFloat {
        let bottomOffsetForHeader: CGFloat
        if headerMode == .canSwitch {
            bottomOffsetForHeader = headerTitleHeight
        } else if headerMode == .fixedHidden {
            bottomOffsetForHeader = headerTitleHeight
        } else if headerMode == .canSwitchFixBottom {
            bottomOffsetForHeader = baseHeaderHidden ? headerTitleHeight : 0
        } else {
            bottomOffsetForHeader = 0
        }
        
        let bottomOffsetForToolBar = canSwitchToolBar ? BTContainer.Constaints.toolBarHeight : 0
        
        return bottomOffsetForHeader + bottomOffsetForToolBar
    }
    
    /// Web 全屏模式
    var fullScreenType: FullScreenType {
        get {
            if forceFullScreen {
                return .webFullScreen
            } else if webFailed {
                return .webFullScreenShowNaviBar
            } else if containerTimeout {
                return .webFullScreenShowNaviBar
            } else if indRecordShow {
                return .webFullScreen
            } else if recordNoHeader {
                return .webFullScreenShowNaviBar
            } else if sceneModel.dashboardFullScreen == true {
                return .webFullScreenShowStatusBar
            }
            return .none
        }
    }
    
    /// 是否应当显示顶部目录胶囊
    var shouldShowSideBarButton: Bool {
        get {
            if fullScreenType != .none {
                // 全屏模式
                return false
            }
            if containerState == .statePgae {
                // 正在显示错误页/权限页
                return false
            }
            if headerMode == .fixedHidden {
                return true
            } else if headerMode == .fixedShow {
                return false
            }
            return baseHeaderHidden
        }
    }
    
    // MARK: ----------方法----------
    /// 当修改某一个属性时，需要联动更新其他属性
    private mutating func updateProperties() {
        if headerMode == .fixedHidden {
            if !baseHeaderHidden {
                baseHeaderHidden = true
            }
        } else if headerMode == .fixedShow {
            if baseHeaderHidden {
                baseHeaderHidden = false
            }
        }
    }
    
    static func isDarkMode() -> Bool {
        if #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
            return true
        } else {
            return false
        }
    }
}

extension BTContainerStatus: CustomStringConvertible {
    public var description: String {
        "BTContainerStatus:{statusVersion:\(statusVersion),baseHeaderHidden:\(baseHeaderHidden),blockCatalogueHidden:\(blockCatalogueHidden),toolBarHidden:\(toolBarHidden),containerSize:\(containerSize),mainContainerSize:\(mainContainerSize),topContainerHeight:\(topContainerHeight),headerTitleHeight:\(headerTitleHeight),forceFullScreen:\(forceFullScreen),orientation:\(orientation),sceneModel:\(sceneModel.description),hostType:\(hostType),isRegularMode:\(isRegularMode),blockCatalogueWidth:\(blockCatalogueWidth),mainViewContainerEnable:\(mainViewContainerEnable),targetBlockAreaWidth:\(targetBlockAreaWidth),headerMode:\(headerMode),viewContainerType:\(viewContainerType),darkMode:\(darkMode),webFailed:\(webFailed),containerTimeout:\(containerTimeout)}"
    }
}

extension BTContainer {
    
    func updateStatus(status: BTContainerStatus, animated: Bool, noWait: Bool = false) {
        let oldStatusVersion = self.status.statusVersion
        let newStatusVersion = oldStatusVersion + 1
        self.status = status
        self.status.statusVersion = newStatusVersion
        DocsLogger.info("BTContainer.updateStatus(\(newStatusVersion)):\(self.status)")
        let currentTime = Date().timeIntervalSince1970
        if noWait || animated || currentTime - lastUpdateStatusTime > 0.25 {
            // 包含动画，或者等待时间累计超过 0.25 强制执行，直接执行
            updateStatus(animated: animated)
        } else {
            // 先等 0.05 看下能不能凑一波执行
            let targetStatusVersion = self.status.statusVersion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self = self else {
                    return
                }
                guard targetStatusVersion == self.status.statusVersion else {
                    return  // 已经被更新的状态覆盖了，这个就不执行了
                }
                self.updateStatus(animated: animated)
            }
        }
    }
    
    private func updateStatus(animated: Bool)  {
        self.lastUpdateStatusTime = Date().timeIntervalSince1970
        
        let beginTime = Date()
        DocsLogger.info("BTContainer.updateStatusBegin(\(self.status.statusVersion)):animated:\(animated)")
        let targets = self.plugins.values
        if animated {
            targets.forEach { value in
                // 动画开始时，不改状态
                value.updateStatus(old: value.status, new: self.status, stage: .animationBeginStage)
            }
            let options: UIView.AnimationOptions = UserScopeNoChangeFG.XM.allowUserInteractionInAnimationDisable ? [] : .allowUserInteraction
            UIView.animate(withDuration: BTContainer.Constaints.animationDuration, delay: 0.0, options: options) { [weak self] in
                guard let self = self else {
                    return
                }
                targets.forEach { value in
                    value.updateStatus(old: value.status, new: self.status, stage: .animationEndStage)
                }
            } completion: { [weak self] _ in
                guard let self = self else {
                    return
                }
                targets.forEach { value in
                    value.updateStatus(old: value.status, new: self.status, stage: .finalStage)
                }
                DocsLogger.info("BTContainer.updateStatusFinalStage(\(self.status.statusVersion)):costTime:\(Int(Date().timeIntervalSince(beginTime) * 1000))ms")
            }
        } else {
            // 没有动画直接一步到位
            targets.forEach { value in
                value.updateStatus(old: value.status, new: self.status, stage: .finalStage)
            }
            DocsLogger.info("BTContainer.updateStatusFinalStage(\(self.status.statusVersion)):costTime:\(Int(Date().timeIntervalSince(beginTime) * 1000))ms")
        }
        
    }
}

extension BTContainer {
    func setMainContainerSize(mainContainerSize: CGSize) {
        guard mainContainerSize != self.status.mainContainerSize else {
            return
        }
        DocsLogger.info("BTContainer.setMainContainerSize:\(mainContainerSize)")
        var status = self.status
        status.mainContainerSize = mainContainerSize
        updateStatus(status: status, animated: false)
    }
    
    func setBaseHeaderHidden(baseHeaderHidden: Bool, animated: Bool = true) {
        guard baseHeaderHidden != self.status.baseHeaderHidden else {
            return
        }
        DocsLogger.info("BTContainer.setBaseHeaderHidden:\(baseHeaderHidden),animated:\(animated)")
        var status = self.status
        status.baseHeaderHidden = baseHeaderHidden
        updateStatus(status: status, animated: animated)
    }
    
    func setBlockCatalogueHidden(blockCatalogueHidden: Bool, animated: Bool = true) {
        guard blockCatalogueHidden != self.status.blockCatalogueHidden else {
            return
        }
        DocsLogger.info("BTContainer.setBlockCatalogueHidden:\(blockCatalogueHidden),animated:\(animated)")
        browserViewController?.view.endEditing(true)
        
        var status = self.status
        status.blockCatalogueHidden = blockCatalogueHidden
        updateStatus(status: status, animated: animated)
    }
    
    func setToolBarHidden(toolBarHidden: Bool, animated: Bool = true) {
        guard toolBarHidden != self.status.toolBarHidden,
              self.status.sceneModel.showAiConfigForm != true else {
            return
        }
        DocsLogger.info("BTContainer.setToolBarHidden:\(toolBarHidden),animated:\(animated)")
        var status = self.status
        status.toolBarHidden = toolBarHidden
        updateStatus(status: status, animated: animated)
    }
    
    func setHeaderTitleHeight(headerTitleHeight: CGFloat) {
        guard headerTitleHeight != self.status.headerTitleHeight else {
            return
        }
        DocsLogger.info("BTContainer.setHeaderTitleHeight:\(headerTitleHeight)")
        var status = self.status
        status.headerTitleHeight = headerTitleHeight
        updateStatus(status: status, animated: false)
    }
    
    func setContainerSize(containerSize: CGSize) {
        guard containerSize != self.status.containerSize else {
            return
        }
        DocsLogger.info("BTContainer.setContainerSize:\(containerSize)")
        var status = self.status
        status.containerSize = containerSize
        updateStatus(status: status, animated: false)
    }
    
    func setTopContainerHeight(topContainerHeight: CGFloat) {
        guard topContainerHeight != self.status.topContainerHeight else {
            return
        }
        DocsLogger.info("BTContainer.setTopContainerHeight:\(topContainerHeight)")
        var status = self.status
        status.topContainerHeight = topContainerHeight
        updateStatus(status: status, animated: false, noWait: true)
    }
    
    func setSceneModel(sceneModel: ContainerSceneModel) {
        guard sceneModel != self.status.sceneModel else {
            return
        }
        DocsLogger.info("BTContainer.setSceneModel:\(sceneModel)")
        let lastSceneModel = self.status.sceneModel
        var status = self.status
        status.sceneModel = sceneModel
        if status.fullScreenType != .none, !status.blockCatalogueHidden {
            // 全屏时主动隐藏 blockCatalogue
            DocsLogger.info("BTContainer.setSceneModel:blockCatalogueHidden=true")
            status.blockCatalogueHidden = true
        }
        if status.sceneModel.dashboardFullScreen == true, status.hostType == .templatePreview {
            DocsLogger.info("BTContainer.setSceneModel:dashboardFullScreen=nil")
            status.sceneModel.dashboardFullScreen = nil // 模板中心不支持仪表盘全屏
        }
        if status.viewContainerType != .hasViewCatalogHasToolBar {
            // 切换视图时，不应当显示 Toolbar 的情况，应当主动隐藏
            DocsLogger.info("BTContainer.setSceneModel:toolBarHidden=true")
            status.toolBarHidden = true
        } else if sceneModel.viewType != lastSceneModel.viewType || sceneModel.blockType != lastSceneModel.blockType {
            // 切换视图时，强行重置 toolBarHidden 的状态
            status.toolBarHidden = status.viewContainerType != .hasViewCatalogHasToolBar
        }
        updateStatus(status: status, animated: false)
    }
    
    func setForceFullScreen(forceFullScreen: Bool) {
        guard forceFullScreen != self.status.forceFullScreen else {
            return
        }
        DocsLogger.info("BTContainer.setForceFullScreen:\(forceFullScreen)")
        var status = self.status
        status.forceFullScreen = forceFullScreen
        updateStatus(status: status, animated: false)
    }
    
    func setOrientation(orientation: UIInterfaceOrientation) {
        guard orientation != self.status.orientation else {
            return
        }
        DocsLogger.info("BTContainer.setOrientation:\(orientation)")
        var status = self.status
        status.orientation = orientation
        updateStatus(status: status, animated: false)
    }
    
    func setHostType(hostType: HostType) {
        guard hostType != self.status.hostType else {
            return
        }
        DocsLogger.info("BTContainer.setHostType:\(hostType)")
        var status = self.status
        status.hostType = hostType
        updateStatus(status: status, animated: false)
    }
    
    func remakeConstraints() {
        DocsLogger.info("BTContainer.remakeConstraints")
        plugins.forEach { (_, value: BTContainerPlugin) in
            value.remakeConstraints(status: value.status)
        }
    }
    
    func updateDarkMode() {
        let darkMode = BTContainerStatus.isDarkMode()
        DocsLogger.info("BTContainer.updateDarkMode:\(darkMode)")
        var status = self.status
        status.darkMode = darkMode
        updateStatus(status: status, animated: false)
    }
    
    func setWebFailed(webFailed: Bool) {
        guard webFailed != self.status.webFailed else {
            return
        }
        DocsLogger.info("BTContainer.setWebFailed:\(webFailed)")
        var status = self.status
        status.webFailed = webFailed
        updateStatus(status: status, animated: false)
    }
    
    func setContainerState(containerState: ContainerState) {
        guard containerState != self.status.containerState else {
            return
        }
        DocsLogger.info("BTContainer.setContainerState:\(containerState)")
        var status = self.status
        status.containerState = containerState
        if containerState == .statePgae, !status.blockCatalogueHidden {
            // 这种情况要强行退出目录展开，不然导航栏看不见了
            DocsLogger.info("BTContainer.setContainerState:blockCatalogueHidden=true")
            status.blockCatalogueHidden = true
        }
        updateStatus(status: status, animated: false)
    }
    
    func setContainerTimeout(containerTimeout: Bool) {
        guard containerTimeout != self.status.containerTimeout else {
            return
        }
        DocsLogger.info("BTContainer.setContainerTimeout:\(containerTimeout)")
        var status = self.status
        status.containerTimeout = containerTimeout
        updateStatus(status: status, animated: false)
    }
    
    func setRecordNoHeader(recordNoHeader: Bool) {
        guard recordNoHeader != self.status.recordNoHeader else {
            return
        }
        DocsLogger.info("BTContainer.setRecordNoHeader:\(recordNoHeader)")
        var status = self.status
        status.recordNoHeader = recordNoHeader
        updateStatus(status: status, animated: false)
    }
    
    func setIndRecordShow(indRecordShow: Bool) {
        guard indRecordShow != self.status.indRecordShow else {
            return
        }
        DocsLogger.info("BTContainer.setIndRecordShow:\(indRecordShow)")
        var status = self.status
        status.indRecordShow = indRecordShow
        updateStatus(status: status, animated: false)
    }
    
//    private func setLoadStatus(loadStatus: LoadStatus) {
//        var status = self.status
//        status.loadStatus = loadStatus
//        updateStatus(status: status, animated: false)
//    }
}

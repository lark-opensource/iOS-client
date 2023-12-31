//
//  SKEditorToolBarPulgin.swift
//  SKBrowser
//
//  Created by zoujie on 2021/3/26.
//  swiftlint:disable cyclomatic_complexity function_body_length file_length

import SKFoundation
import SKCommon
import SKUIKit
import RxSwift
import LarkWebViewContainer
import LarkContainer

// swiftlint:disable type_body_length
public final class SKEditorToolBarPulgin: JSServiceHandler {
    enum ToolType: Int {
        case DOC = 2
        case SHEET = 3
        case EQUATION = 4 //公式
        case MINDNOTE = 5
    }

    //普通菜单item的宽度
    private var itemWidth: CGFloat = 0
    //工具栏的宽度
    private var oldHostViewWidth: CGFloat = 0
    //是否是iPad工具栏
    private var isIPadToolbar = false
    public var logPrefix: String = ""
    private let config: SKBaseToolBarConfig
    var mainTBPanel: SKMainToolBarPanel?
    private var currentToolType: ToolType = .DOC
    var subTBPanels: [String: SKSubToolBarPanel] = [:]
    var subDisplayPanel: SKSubToolBarPanel? //覆盖二级菜单栏显示Panel
    //这个是toolBarManager,如果没有传就new 一个 docsToolBarManager就可以
    var tool: BrowserToolConfig?
    var workingMethod = DocsJSService.docToolBarJsName
    var isNewToolBarType: Bool = false
    //记录上一次工具栏展开的类型
    private var lastUnfoldType: UnfoldType = .nothing
    //记录上一次展开的标题
    private var lastUnfoldTitle: ToolBarItemInfo?
    //记录上一次是否展开了对齐
    private var lastIsUnfoldRetract: Bool?
    // 正在展示的那个二级菜单 ID
    private(set) var showingItemID: String?
    private var hasClickForeColorItem = false
    private var currentClickToolbarItem: ToolBarItemInfo?
    ///监听 keyboard 事件
    private var keyboardIsShow = true
    private let keyboard = Keyboard()
    private let disposeBag = DisposeBag()
    private let keyboardObserver = PublishSubject<ToolBarItemInfo?>()
    ///是否点击+号按钮
    public var didClickAddButton = false

    ///统一callback
    private var nativeCallback: APICallbackProtocol?
    lazy var restoreCallback: ((String) -> Void) = { [weak self] tag in
        guard let self = self else { return }
        self.changeSubPanel(with: tag)
    }

    public weak var pluginProtocol: SKBaseToolBarPluginProtocol?

    var jsMethod: String = ""
    private var toolBarInfos: [ToolBarItemInfo] = []
    //自适应宽高之后的工具栏items
    private var realToolBarInfos: [ToolBarItemInfo] = []
    private var subTBInfos: [ToolBarItemInfo] = []
    private var toolBarItems: [DocsBaseToolBarItem] = []
    private var jsItems: [[String: Any]] = [[:]]

    let highlightPanelPlugin = HighlightPanelPlugin()
    let insertBlockPlugin = InsertBlockPlugin()
    
    let userResolver: UserResolver
    
    public init(_ config: SKBaseToolBarConfig, userResolver: UserResolver) {
        self.config = config
        self.userResolver = userResolver
        highlightPanelPlugin.delegate = self
        insertBlockPlugin.delegate = self
        setKeyboardObserver()
    }

    deinit {
        keyboard.stop()
    }

    public var handleServices: [DocsJSService] {
        return [.docToolBarJsNameV2, .docToolBarJsName, .sheetToolBarJsName, .mindnoteToolBarJsName, .docToolBarForIpadJsName, .mindnoteToolBarJsNameV2]
            + highlightPanelPlugin.handleServices
            + insertBlockPlugin.handleServices
    }

    public func handle(params: [String: Any], serviceName: String) {}

    // MARK: JS API 调用工具栏入口在这
    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        if insertBlockPlugin.canHandle(serviceName) {
            insertBlockPlugin.handle(params: params, serviceName: serviceName, callback: callback)
            return
        }
        if highlightPanelPlugin.canHandle(serviceName) {
            highlightPanelPlugin.handle(params: params, serviceName: serviceName, callback: callback)
            return
        }
        workingMethod = DocsJSService(rawValue: serviceName)
        DocsLogger.debug("KeyboardPlugin: \(serviceName) params:\(params)")
        guard let items = params["items"] as? [[String: Any]] else {
                currentTool.remove(mode: .toolbar)
                removeAllToolBarView()
                let type = params["type"] as? Int
                if type != ToolType.EQUATION.rawValue {
                    let toolBar = currentTool.toolBar
                    toolBar.changeInputView(nil)
                    pluginProtocol?.didReceivedCloseToolBarInfo()
                } else {
                    pluginProtocol?.updateUiResponderTrigger(trigger: DocsKeyboardTrigger.blockEquation.rawValue)
                    pluginProtocol?.updateNavigationPluginToolBarHeight(height: 0)
                    DocsLogger.info("前端调用了只展示键盘不展示工具栏")
                }
            return
        }
        jsMethod = params["callback"] as? String ?? ""
        nativeCallback = callback
        jsItems = items
        showingItemID = params["showingItemId"] as? String
        if showingItemID?.isEmpty ?? false {
            subDisplayPanel = nil
        }
        toolBarInfos.removeAll()
        for info in jsItems {
            guard let sId = info["id"] as? String else { continue }
            let itemModel = ToolBarItemInfo(identifier: sId, json: info, jsMethod: jsMethod)
            itemModel.childrenIsShow = (sId == showingItemID)
            toolBarInfos.append(itemModel)
        }
        let tool = currentTool
        let toolBar = currentTool.toolBar
        isIPadToolbar = (workingMethod == .docToolBarForIpadJsName)
        toolBar.restoreCallback = restoreCallback
        DocsLogger.info("DocsToolbar did revice items", extraInfo: ["count": toolBarInfos.count], component: LogComponents.toolbar)

        switch workingMethod {
        case .docToolBarJsNameV2, .docToolBarForIpadJsName, .mindnoteToolBarJsNameV2:
            isNewToolBarType = true
            //V3.30 新的工具栏接口，default是之前的逻辑
            guard let type = params["type"] as? Int else {
                DocsLogger.info("biz.navigation.setDocToolbarV2 没有返回type值", component: LogComponents.toolbar)
                return
            }
            if toolBarInfos.count > 0 {
                //需要转成旧的类型，适配旧逻辑
                if type == ToolType.SHEET.rawValue {
                    currentToolType = .SHEET
                    workingMethod = DocsJSService.sheetToolBar
                } else if type == ToolType.DOC.rawValue {
                    currentToolType = .DOC
                    workingMethod = DocsJSService.docToolBarJsName
                }
                updateSubTBView(toolBarInfos)
                //docs工具栏iPad宽度自适应 前端FG控制
                relayoutAttachToolBar()
                updateDisplaySubTBView()
                toolBar.setEditMode(to: editModeV2(type), animated: false)
                if editModeV2(type) != .sheetInput { toolBar.resetSheetStatus() }
                if displayToolBar { tool.set(DocsToolbarManager.ToolConfig(toolBar), mode: .toolbar) }
                if let view = mainTBPanel { pluginProtocol?.requestDisplayMainTBPanel(view) }
                //这个要改 first timer 怎么判断
                if let data = params["data"] as? [String: Any], let inputDict = data["input"] as? [String: Any] {
                    let value = inputDict["value"] as? String ?? ""
                    let info = DocsToolBar.SheetInputInfo(text: value)
                    pluginProtocol?.didReceivedOpenToolBarInfo(firstTimer: false, doubleClick: false)
                    pluginProtocol?.didReceivedInputText(text: true)
                } else if type == ToolType.SHEET.rawValue {
                    pluginProtocol?.didReceivedOpenToolBarInfo(firstTimer: false, doubleClick: true)
                    toolBar.beginSheetEdit(with: nil, animated: true)
                    pluginProtocol?.didReceivedInputText(text: false)
                } else {
                    pluginProtocol?.didReceivedOpenToolBarInfo(firstTimer: false, doubleClick: false)
                }
                toolBar.restoreEditStateIfNeeded()
            } else if canRemoveToolBar {
                tool.remove(mode: .toolbar)
                removeAllToolBarView()
                pluginProtocol?.didReceivedCloseToolBarInfo()
            } else {
                DocsLogger.info("BaseToolbar can't remove toolbar when item is empty.",
                                extraInfo: ["working_method": workingMethod, "toolbar_mode": tool.toolBar.mode],
                                component: LogComponents.toolbar)
            }
        default:
            // default是V3.30之前的逻辑
            isNewToolBarType = false
            if toolBarInfos.count > 0 {
                updateMainTBView(toolBarInfos)
                updateSubTBView(toolBarInfos)
                toolBar.setEditMode(to: editMode, animated: false)
                if editMode != .sheetInput { toolBar.resetSheetStatus() }
                if displayToolBar { tool.set(DocsToolbarManager.ToolConfig(toolBar), mode: .toolbar) }
                if let view = mainTBPanel { pluginProtocol?.requestDisplayMainTBPanel(view) }
                //这个要改 first timer 怎么判断
                pluginProtocol?.didReceivedOpenToolBarInfo(firstTimer: false, doubleClick: (params["input"] == nil))
                if let inputDict = params["input"] as? [String: Any] {
                    let value = inputDict["value"] as? String ?? ""
                    let info = DocsToolBar.SheetInputInfo(text: value)
                    pluginProtocol?.didReceivedInputText(text: true)
                } else if workingMethod == DocsJSService.sheetToolBarJsName {
                    toolBar.beginSheetEdit(with: nil, animated: true)
                    pluginProtocol?.didReceivedInputText(text: false)
                } else {
                    pluginProtocol?.didReceivedOpenToolBarInfo(firstTimer: false, doubleClick: false)
                }
                toolBar.restoreEditStateIfNeeded()
            } else if canRemoveToolBar {
                tool.remove(mode: .toolbar)
                removeAllToolBarView()
                pluginProtocol?.didReceivedCloseToolBarInfo()
            } else {
                DocsLogger.info("BaseToolbar can't remove toolbar when item is empty.",
                                extraInfo: ["working_method": workingMethod, "toolbar_mode": tool.toolBar.mode],
                                component: LogComponents.toolbar)
            }
        }
    }

    private func setKeyboardObserver() {
        keyboard.on(event: .didShow) { [weak self] options in
            let height = options.endFrame.height
            //过滤掉一些奇怪的高度
            guard height > 180 else { return }
            self?.keyboardIsShow = true
        }

        keyboard.on(event: .willHide) { [weak self] _ in
            self?.keyboardIsShow = false
        }

        keyboard.on(event: .didHide) { [weak self] _ in
            if self?.hasClickForeColorItem ?? false {
                self?.keyboardObserver.onNext(self?.currentClickToolbarItem)
            }
            self?.keyboardIsShow = false
            self?.hasClickForeColorItem = false
        }
        keyboard.start()
    }

    ///iPad工具栏自适应item宽度调整
    func setToolbarWidthForIPad() {
        DocsMainToolBarV2.Const.itemWidth = 48
        DocsMainToolBarV2.Const.separateWidth = 17
        DocsMainToolBarV2.Const.contentInsetPadding = 8
    }

    ///iPad工具栏自适应
    func relayoutAttachToolBar() {
        if !isIPadToolbar {
            updateMainTBViewV2(toolBarInfos)
            return
        }

        //13.0以下的版本不支持Pencilkit
        if #available(iOS 13.0, *) {
        } else {
            toolBarInfos = toolBarInfos.filter { (item) -> Bool in
                return item.identifier != BarButtonIdentifier.pencilkit.rawValue
            }
        }

        setToolbarWidthForIPad()
        itemWidth = DocsMainToolBarV2.Const.itemWidth
        let currentWidth = config.hostView?.bounds.width ?? 0
        DocsLogger.info("toolBar hostView currentWidth:\(currentWidth) oldHostViewWidth:\(oldHostViewWidth)")

        realToolBarInfos.removeAll()
        realToolBarInfos.append(contentsOf: toolBarInfos)

        switch currentToolType {
        case .DOC:
            relayoutDocAttachToolBar(width: currentWidth)
        case .SHEET:
            relayoutSheetAttachToolBar(width: currentWidth)
        case .EQUATION, .MINDNOTE:
            break
        }

        updateMainTBViewV2(realToolBarInfos)
    }

    func relayoutDocAttachToolBar(width: CGFloat) {
        //docs工具栏
        var type = UnfoldType.nothing
        type.foldType(width: width, type: .DOC, items: realToolBarInfos)

        //在工具栏hostview宽度不变的情况下保持上一次的展开状态
        if oldHostViewWidth == width {
            type = lastUnfoldType
        } else {
            lastUnfoldType = type
            lastUnfoldTitle = nil
            lastIsUnfoldRetract = nil
            oldHostViewWidth = width
        }

        let unfoldRetractBlock = {
            if self.lastIsUnfoldRetract == nil {
                self.lastIsUnfoldRetract = self.canUnfoldRetract()
            }

            if self.lastIsUnfoldRetract ?? false {
                self.unfoldRetract()
            }
        }

        switch type {
        case .nothing:
            unfoldRetractBlock()
        case .textTransform:
            //展开文本样式
            mergeAttachedItemsIntoMainToolbar(for: BarButtonIdentifier.textTransform.rawValue)
            //展开缩进
            unfoldRetractBlock()
        case .blockTransform:
            //展开文本样式
            mergeAttachedItemsIntoMainToolbar(for: BarButtonIdentifier.textTransform.rawValue)
            //展开部分Block格式
            //将H4-H9放在Hn的子目录下
            mergeAttachedItemsIntoMainToolbar(for: BarButtonIdentifier.blockTransform.rawValue)
            unfoldAllTitleToolBar()
            //展开缩进
            unfoldRetractBlock()
        case .alignTransform:
            //展开文本样式
            mergeAttachedItemsIntoMainToolbar(for: BarButtonIdentifier.textTransform.rawValue)
            //展开Block格式
            mergeAttachedItemsIntoMainToolbar(for: BarButtonIdentifier.blockTransform.rawValue)
            //展开对齐
            mergeAttachedItemsIntoMainToolbar(for: BarButtonIdentifier.alignTransform.rawValue)
            //将H4-H9放在Hn的子目录下
            //逐个展开H4-H9
            unfoldTitleToolBar()
        default:
            break
        }
    }

    func relayoutSheetAttachToolBar(width: CGFloat) {
        //sheet@doc 工具栏
        var type = UnfoldType.nothing
        type.foldType(width: width, type: .SHEET, items: realToolBarInfos)
        switch type {
        case .nothing:
            break
        case .textTransform:
            //展开文本样式
            mergeAttachedItemsIntoMainToolbar(for: BarButtonIdentifier.textTransform.rawValue)
        case .all:
            //展开文本样式
            mergeAttachedItemsIntoMainToolbar(for: BarButtonIdentifier.textTransform.rawValue)
            //展开对齐
            mergeAttachedItemsIntoMainToolbar(for: BarButtonIdentifier.alignTransform.rawValue)
        default:
            break
        }
    }

    ///菜单view的宽度不足以展开对齐和缩进时，判断是否能展开对齐
    func canUnfoldRetract() -> Bool {
        guard let bounds = config.hostView?.bounds else { return false }
        //若工具栏的hostview宽度未发生变化，则保持上次对齐的展开状态
        //如果上次对齐是展开的，则不需要判断宽度是否够，直接展开就行
        let baseWidth: CGFloat = getMainToolBarWidth() + itemWidth + DocsMainToolBarV2.Const.separateWidth //加上最右边常驻的键盘收起按钮 和 分割线
        guard bounds.width - baseWidth > 0 else { return false }
        let diff = bounds.width - baseWidth

        let count = Int(floor(diff / itemWidth))//还可以放下菜单的个数

        guard count >= 2 else { return false }
        return true
    }

    ///展开对齐
    func unfoldRetract() {
        var alignTransformIndex = 0
        var alignTransform: ToolBarItemInfo?
        for (i, toolBarInfo) in realToolBarInfos.enumerated() where toolBarInfo.identifier == BarButtonIdentifier.alignTransform.rawValue {
            alignTransformIndex = i
            alignTransform = toolBarInfo
            break
        }

        guard let toolBar = alignTransform, let childs = toolBar.children, childs.count > 2 else { return }

        let subChilds = childs.filter { (toolBarInfo) -> Bool in
            return toolBarInfo.identifier != BarButtonIdentifier.indentLeft.rawValue &&
                toolBarInfo.identifier != BarButtonIdentifier.indentRight.rawValue
        }

        let separator = ToolBarItemInfo(identifier: BarButtonIdentifier.separator.rawValue)
        separator.parentIdentifier = alignTransform?.identifier
        let retract = childs[0...1]
        let newAlignTransform = ToolBarItemInfo(identifier: BarButtonIdentifier.alignTransform.rawValue)
        newAlignTransform.isEnable = toolBar.isEnable
        newAlignTransform.jsMethod = jsMethod
        newAlignTransform.children = subChilds
        newAlignTransform.childrenOrientationType = .horizontal
        newAlignTransform.childrenIsShow = toolBar.childrenIsShow

        realToolBarInfos.remove(at: alignTransformIndex)
        realToolBarInfos.insert(newAlignTransform, at: alignTransformIndex)
        realToolBarInfos.insert(contentsOf: retract, at: alignTransformIndex)
        realToolBarInfos.insert(separator, at: alignTransformIndex)
    }

    ///标题菜单H4~H9收到Hn的子菜单中
    func unfoldAllTitleToolBar() {
        var h4Index = 0
        var lastTitleIndex = 0

        for (i, toolBarInfo) in realToolBarInfos.enumerated() where toolBarInfo.identifier == BarButtonIdentifier.h4.rawValue {
            h4Index = i
            break
        }

        guard h4Index > 0 else { return }
        for (i, toolBarInfo) in realToolBarInfos.enumerated() where toolBarInfo.identifier == BarButtonIdentifier.h9.rawValue {
            lastTitleIndex = i
            break
        }

        if lastTitleIndex > 0 && h4Index < lastTitleIndex {
            //将放不下的H菜单收到Hn的子菜单中
            var childTitle: [ToolBarItemInfo] = []
            let hnItemInfo = ToolBarItemInfo(identifier: "hn")
            hnItemInfo.jsMethod = jsMethod
            hnItemInfo.parentIdentifier = BarButtonIdentifier.blockTransform.rawValue
            hnItemInfo.childrenOrientationType = .horizontal
            childTitle.append(contentsOf: realToolBarInfos[h4Index...lastTitleIndex])
            realToolBarInfos.removeSubrange(h4Index...lastTitleIndex)
            realToolBarInfos.insert(hnItemInfo, at: h4Index)
            realToolBarInfos[h4Index].children = childTitle
        }
    }

    func unfoldTitleToolBar() {
        //菜单全部展开后
        //根据菜单view的宽度收起部分标题菜单到hn中
        guard let bounds = config.hostView?.bounds else { return }
        let baseWidth: CGFloat = getMainToolBarWidth() + itemWidth + DocsMainToolBarV2.Const.separateWidth //加上最右边常驻的键盘收起按钮 和 分割线
        guard bounds.width - baseWidth < 0 else { return }
        let diff = baseWidth - bounds.width

        let count = Int(ceil(diff / itemWidth))//需要放到Hn子菜单中的个数

        DocsLogger.info("iPad toolBar bounds width: \(bounds.width) toolbarWidth: \(baseWidth) count: \(count)")
        var childTitle: [ToolBarItemInfo] = []
        var lastTitleIndex = 0
        var h4Index = 0

        for (i, toolBarInfo) in realToolBarInfos.enumerated() where toolBarInfo.identifier == BarButtonIdentifier.h4.rawValue {
            h4Index = i
            break
        }

        guard h4Index > 0 else { return }
        for (i, toolBarInfo) in realToolBarInfos.enumerated() where toolBarInfo.identifier == BarButtonIdentifier.h9.rawValue {
            lastTitleIndex = i
            break
        }

        var foldIndexs = lastTitleIndex - count

        if let lastTitle = lastUnfoldTitle {
            for (i, toolBarInfo) in realToolBarInfos.enumerated() where toolBarInfo.identifier == lastTitle.identifier {
                foldIndexs = i
                break
            }
        } else {
            lastUnfoldTitle = realToolBarInfos[foldIndexs]
        }

        if count > 0 && h4Index <= foldIndexs {
            //将放不下的H菜单收到Hn的子菜单中
            let hnItemInfo = ToolBarItemInfo(identifier: "hn")
            hnItemInfo.jsMethod = jsMethod
            hnItemInfo.parentIdentifier = BarButtonIdentifier.blockTransform.rawValue
            hnItemInfo.childrenOrientationType = .horizontal
            childTitle.append(contentsOf: realToolBarInfos[foldIndexs...lastTitleIndex])
            realToolBarInfos.removeSubrange(foldIndexs...lastTitleIndex)
            realToolBarInfos.insert(hnItemInfo, at: foldIndexs)
            realToolBarInfos[foldIndexs].children = childTitle
        }
    }

    ///根据当前的菜单项获取菜单的宽度
    func getMainToolBarWidth() -> CGFloat {
        var totalWidth: CGFloat = DocsMainToolBarV2.Const.contentInsetPadding
        realToolBarInfos.forEach { (toobarInfo) in
            switch toobarInfo.identifier {
            case BarButtonIdentifier.highlight.rawValue:
                totalWidth += DocsMainToolBarV2.Const.highlightCellWidth
            case BarButtonIdentifier.separator.rawValue:
                totalWidth += DocsMainToolBarV2.Const.separateWidth
            default:
                totalWidth += itemWidth
            }
        }
        return totalWidth
    }

    ///展开indentifier的二级菜单
    func mergeAttachedItemsIntoMainToolbar(for indentifier: String) {
        var attachItems: [ToolBarItemInfo]?
        var parentItem: ToolBarItemInfo?
        var index = 0

        if indentifier == BarButtonIdentifier.blockTransform.rawValue {
            //移除工具栏尾部的checkbox和remiender，因为blockTransform的子菜单里面包括checkbox和remiender
            realToolBarInfos = realToolBarInfos.filter { (toolBarInfo) -> Bool in
                return toolBarInfo.identifier != BarButtonIdentifier.checkbox.rawValue &&
                    toolBarInfo.identifier != BarButtonIdentifier.reminder.rawValue &&
                    toolBarInfo.identifier != BarButtonIdentifier.checkList.rawValue
            }
        }
        for (i, toolBarInfo) in realToolBarInfos.enumerated() where toolBarInfo.identifier == indentifier {
            attachItems = toolBarInfo.children?.filter({ (child) -> Bool in
                return child.identifier != BarButtonIdentifier.separator.rawValue
            })
            parentItem = toolBarInfo
            index = i
            break
        }
        guard var attItems = attachItems, index > 0, index < realToolBarInfos.count else { return }
        let separator = ToolBarItemInfo(identifier: BarButtonIdentifier.separator.rawValue)
        separator.parentIdentifier = parentItem?.identifier

        if indentifier == BarButtonIdentifier.blockTransform.rawValue {
            attItems.append(separator)
        }

        realToolBarInfos.remove(at: index)
        realToolBarInfos.insert(contentsOf: attItems, at: index)

        if indentifier == BarButtonIdentifier.alignTransform.rawValue {
            realToolBarInfos.insert(separator, at: index)
        }
    }

    public func removeAllToolBarView() {
        mainTBPanel = nil
        subTBPanels.removeAll()
        subDisplayPanel = nil
    }

    private func updateMainTBView(_ status: [ToolBarItemInfo]) {
        tool?.toolBar.changeSubPanelAfterKeyboardDidShow = false
        if let view = mainTBPanel {
            view.refreshStatus(status: status, service: workingMethod)
            return
        } else {
            mainTBPanel = config.uiCreater?.updateMainToolBarPanel(status, service: workingMethod)
            mainTBPanel?.delegate = self
            mainTBPanel?.refreshStatus(status: status, service: workingMethod)
        }
    }

    private func updateMainTBViewV2(_ status: [ToolBarItemInfo]) {
        if let view = mainTBPanel {
            view.refreshStatus(status: status, service: workingMethod)
            return
        } else {
            mainTBPanel = config.uiCreater?.updateMainToolBarPanelV2(status, service: workingMethod, isIPadToolbar: isIPadToolbar)
            mainTBPanel?.delegate = self
            tool?.toolBar.changeSubPanelAfterKeyboardDidShow = true
            mainTBPanel?.refreshStatus(status: status, service: workingMethod)
        }
    }

    private func updateDisplaySubTBView() {
        guard let displayView = subDisplayPanel, displayView.superview != nil, let displayHeight = displayView.getCurrentDisplayHeight() else {
            return
        }
        tool?.toolBar.updateToolBarHeight(displayHeight)
    }

    private func updateSubTBView(_ status: [ToolBarItemInfo]) {
        for item in status {
            if let view = subTBPanels[item.identifier],
                let children = item.children {
                view.updateStatus(status: DocsSubToolBar.statusTransfer(status: children))
            } else if let newView = config.uiCreater?.updateSubToolBarPanel(item.children, identifier: item.identifier, curWindow: config.hostView?.window) {
                newView.panelDelegate = self
                if item.identifier == BarButtonIdentifier.attr.rawValue || item.identifier == BarButtonIdentifier.textTransform.rawValue {
                    subTBPanels[BarButtonIdentifier.attr.rawValue] = newView
                    subTBPanels[BarButtonIdentifier.textTransform.rawValue] = newView
                } else {
                    subTBPanels[item.identifier] = newView
                }
            }
            if item.children?.contains(where: { $0.identifier == BarButtonIdentifier.highlight.rawValue }) ?? false {
                if let view = subTBPanels.first(where: { return $1 is DocsAttributionView })?.value {
                    subTBPanels[BarButtonIdentifier.highlight.rawValue] = view
                }
            }
        }
    }

    private func _getSubTBView(_ identifier: String) -> SKSubToolBarPanel? {
        if let view = subTBPanels[identifier] {
            return view
        } else if let view = config.uiCreater?.updateSubToolBarPanel([], identifier: identifier, curWindow: config.hostView?.window) {
            view.panelDelegate = self
            if identifier == BarButtonIdentifier.attr.rawValue || identifier == BarButtonIdentifier.textTransform.rawValue {
                subTBPanels[BarButtonIdentifier.attr.rawValue] = view
                subTBPanels[BarButtonIdentifier.textTransform.rawValue] = view
            } else {
                subTBPanels[identifier] = view
            }
            return view
        }
        return nil
    }

    private var editMode: DocsToolBar.EditMode {
        //3.30以前是通过两个不同的接口来区分docs工具栏&sheet@Docs工具栏
        //这个接口仅仅在旧版使用，V2不使用这个来进行判断
        switch workingMethod {
        case .sheetToolBarJsName:
            return .sheetInput
        default:
            return .normal
        }
    }

    private func editModeV2(_ type: Int) -> DocsToolBar.EditMode {
        //3.30后使用这个接口来区分是什么模式：docs工具栏&sheet@Docs工具栏
        if type == ToolType.SHEET.rawValue {
            return .sheetInput
        } else {
            return .normal
        }
    }

    private var canRemoveToolBar: Bool {
        switch workingMethod {
        case .sheetToolBarJsName:
            return tool?.toolBar.mode == .sheetInput
        case .docToolBarJsName, .mindnoteToolBarJsName, .mindnoteToolBarJsNameV2:
            return tool?.toolBar.mode == .normal
        default:
            return false
        }
    }

    private var displayToolBar: Bool {
        switch workingMethod {
        case .docToolBarJsName:
            return currentTool.currentMode != .atSelection
        case .mindnoteToolBarJsName, .mindnoteToolBarJsNameV2:
            return currentTool.currentMode != .atComment
        default:
            return true
        }
    }

    private var currentTool: BrowserToolConfig {
        if let realTool = tool {
            return realTool
        } else {
            let newTool = DocsToolbarManager(userResolver: self.userResolver)
            newTool.embed(DocsToolbarManager.ToolConfig(newTool.toolBar))
            tool = newTool
            return newTool
        }
    }

    private func openWhiteBoard() {}
}

extension SKEditorToolBarPulgin: SKAttachedTBPanelDelegate {

    public func didClickedItem(_ item: ToolBarItemInfo, panel: SKMainToolBarPanel, emptyClick: Bool) {
        didClickAddButton = (item.identifier == BarButtonIdentifier.addNewBlock.rawValue)
        if item.identifier == BarButtonIdentifier.highlight.rawValue {
            if let jsonValue = item.valueJSON,
               let openPanel = jsonValue["openPanel"] as? Bool, openPanel {
                guard let colorPickView = attributionView?.colorPickerPanelV2,
                      var colorPickFrame = panel.getCellFrame(byToolBarItemID: BarButtonIdentifier.highlight.rawValue) else { return }
                // popover页面的箭头需要指到小三角
                let leftPadding = DocsToolBar.Const.highlightColorWidth
                colorPickFrame.origin.x += leftPadding
                colorPickFrame.size.width -= leftPadding
                //收起二级工具栏
                (panel as? DocsMainToolBarV2)?.hideAttachedToolBar(true, forceRemove: false)
                let vc = InsertColorPickerViewController(colorPickPanel: colorPickView)
                vc.delegate = self
                pluginProtocol?.requestPresentViewController(vc, sourceView: panel, sourceRect: colorPickFrame)
                attributionView?.setColorPickerUpV2()
            } else if let attView = attributionView {
                select(item: item, update: item.jsonString, view: attView)
            }
            return
        }

        if item.identifier == BarButtonIdentifier.pencilkit.rawValue {
            openWhiteBoard()
        }

        let selectedStr = emptyClick ? "true" : "false"
        let params: [String: Any] = ["id": item.identifier,
                                     "level": 1,
                                     "value": selectedStr]
        nativeCallJS(item: item, params: params)
        if let subPanel = subTBPanels[item.identifier], item.childrenIsShow == false {
            if item.identifier == BarButtonIdentifier.insertImage.rawValue && item.adminLimit {
                return
            }
            pluginProtocol?.requestChangeSubTBPanel(subPanel, info: item)
        }
        didClickAddButton = false
    }

    public func didClickedItem(_ item: ToolBarItemInfo, panel: SKMainToolBarPanel, value: Any?) {
        if item.identifier == BarButtonIdentifier.fontSize.rawValue {
            var params: [String: Any] = ["id": item.identifier,
                                         "level": 1]
            if let v = value { params["value"] = v }
            nativeCallJS(item: item, params: params)
            return
        }

        if item.identifier == BarButtonIdentifier.foreColor.rawValue {
            hasClickForeColorItem = true
            currentClickToolbarItem = item
            displayFontColorPickerView(item: item, value: value, level: 1)
        }
    }

    public func didClickedItem(_ item: ToolBarItemInfo, panel: SKMainToolBarPanel, emptyClick: Bool, isFromRefresh: Bool) {
        if let subPanel = subTBPanels[item.identifier] {
            pluginProtocol?.requestChangeSubTBPanel(subPanel, info: item)
        }
    }

    public func didClickedItem(_ item: ToolBarItemInfo, panel: DocsAttachedToolBar, value: Any? = nil) {

        if item.identifier == BarButtonIdentifier.backColor.rawValue
            || item.identifier == BarButtonIdentifier.foreColor.rawValue
            || item.identifier == BarButtonIdentifier.oldHighlight.rawValue {
            displayFontColorPickerView(item: item, value: value, level: 2)
        } else if item.identifier == BarButtonIdentifier.borderLine.rawValue {
            var params: [String: Any] = ["id": item.identifier,
                                         "level": 2]
            if let v = value { params["value"] = v }
            nativeCallJS(item: item, params: params)
            let panel = BorderOperationView(info: item)
            panel.panelDelegate = self
            pluginProtocol?.requestDisplaySubTBPanel(panel, info: item)
            subDisplayPanel = panel
        } else if item.identifier == BarButtonIdentifier.highlight.rawValue {
            guard let subPanel = subTBPanels[item.identifier] else { return }
            //点击颜色选择面板时需要先把二级工具栏隐藏起来
            if let valueJSON = item.valueJSON, let openPanel = valueJSON["openPanel"] as? Bool, openPanel {
                //iPad 工具栏自适应 FG控制
                if isIPadToolbar {
                    //在键盘上方展示
                    guard let colorPickerPanelV2 = attributionView?.colorPickerPanelV2 else { return }
                    let panel = ColorPickerView(colorPickerPanelV2: colorPickerPanelV2, userResolver: self.userResolver, width: mainTBPanel?.bounds.width ?? 0)
                    pluginProtocol?.requestDisplaySubTBPanel(panel, info: item)
                    attributionView?.setColorPickerUpV2()
                    subDisplayPanel = panel
                } else {
                    //替换键盘view
                    (mainTBPanel as? DocsMainToolBarV2)?.hideAttachedToolBar(true, forceRemove: false)
                    pluginProtocol?.requestChangeSubTBPanel(subPanel, info: item)
                }
            } else {
                if let attView = attributionView {
                    select(item: item, update: item.jsonString, view: attView)
                }
            }
        } else {
            var params: [String: Any] = ["id": item.identifier,
                                         "level": 2]
            if let v = value { params["value"] = v }
            nativeCallJS(item: item, params: params)
        }
    }

    private func displayFontColorPickerView(item: ToolBarItemInfo, value: Any? = nil, level: Int) {
        var params: [String: Any] = ["id": item.identifier,
                                     "level": level]
        if let v = value { params["value"] = v }
        nativeCallJS(item: item, params: params)
        let panel = FontColorPickerView(info: item)
        panel.panelDelegate = self
        if !keyboardIsShow {
            pluginProtocol?.requestDisplaySubTBPanel(panel, info: item)
            subDisplayPanel = panel
            hasClickForeColorItem = false
        }

        if !keyboardObserver.hasObservers {
            keyboardObserver.subscribe(onNext: { [weak self] (toolbarItem) in
                guard let toolbar = toolbarItem else { return }
                let panel = FontColorPickerView(info: toolbar)
                panel.panelDelegate = self
                self?.pluginProtocol?.requestDisplaySubTBPanel(panel, info: toolbar)
                self?.subDisplayPanel = panel
            }).disposed(by: disposeBag)
        }

        if let sheetManagerView = subTBPanels[BarButtonIdentifier.sheetCellAtt.rawValue] as? SheetCellManagerView, item.identifier == BarButtonIdentifier.backColor.rawValue {
            sheetManagerView.currentBackcolorPanel = panel
        }
    }

    private func changeSubPanel(with tag: String) {
        var identifier: String?
        switch tag {
        case DocsAssetToolBarItem.restoreTag:
            identifier = BarButtonIdentifier.insertImage.rawValue
        default:
            break
        }
        if let identifier = identifier, let subPanel = subTBPanels[identifier],
            let item = toolBarInfos.first(where: { return $0.identifier == BarButtonIdentifier.insertImage.rawValue }) {
            pluginProtocol?.requestChangeSubTBPanel(subPanel, info: item)
        }
    }

    private func nativeCallJS(item: ToolBarItemInfo, params: [String: Any]) {
        if jsMethod.isEmpty {
            nativeCallback?.callbackSuccess(param: params, extra: ["bizDomain": "ccm"])
        } else {
            pluginProtocol?.callFunction(DocsJSCallBack(item.jsMethod), params: params, completion: nil)
        }
    }

    public func hideHighlightView() {
        pluginProtocol?.requestDismissViewController(completion: nil)
    }
}

extension SKEditorToolBarPulgin: SKSubTBPanelDelegate {
    public func select(item: ToolBarItemInfo, updateJson value: [String: Any]?, view: SKSubToolBarPanel) {
        if let sValue = value {
            let params: [String: Any] = ["id": item.identifier, "value": sValue]
            nativeCallJS(item: item, params: params)
        } else {
            let params = ["id": item.identifier]
            nativeCallJS(item: item, params: params)
        }
    }

    public func select(item: ToolBarItemInfo, update value: Any?, view: SKSubToolBarPanel) {
        if let sValue = value {
            let params = ["id": item.identifier,
                          "value": sValue
            ]
            nativeCallJS(item: item, params: params)
        } else {
            let params = ["id": item.identifier]
            nativeCallJS(item: item, params: params)
        }
    }

    public func requestShowKeyboard() {
        pluginProtocol?.requestShowKeyboard()
    }
}

extension SKEditorToolBarPulgin: HighlightPanelPluginDelegate {
    var attributionView: DocsAttributionView? {
        NotificationCenter.default.post(name: Notification.Name.NavigationHideHighlightPanel, object: nil)
        return self._getSubTBView(BarButtonIdentifier.attr.rawValue) as? DocsAttributionView
    }
    
    func callback(callback: DocsJSCallBack, params: [String: Any], nativeCallback: APICallbackProtocol?) {
        if callback.rawValue.isEmpty {
            nativeCallback?.callbackSuccess(param: params, extra: ["bizDomain": "ccm"])
            return
        }
        pluginProtocol?.callFunction(callback, params: params, completion: nil)
    }
}

extension SKEditorToolBarPulgin: InsertBlockPluginDelegate {

    var viewDistanceToWindowBottom: CGFloat {
        guard let hostView = config.hostView, let window = hostView.window else { return 0 }
        return window.bounds.maxY - hostView.convert(hostView.bounds, to: nil).maxY
    }

    func presentInsertBlockViewController(_ vc: UIViewController) {
        let addBlockFrame = mainTBPanel?.getCellFrame(byToolBarItemID: BarButtonIdentifier.addNewBlock.rawValue)
        pluginProtocol?.requestPresentViewController(vc, sourceView: mainTBPanel, sourceRect: addBlockFrame)
    }

    func dismissInsertBlockViewController(completion: (() -> Void)? = nil) {
        pluginProtocol?.requestDismissViewController(completion: completion)
    }

    func setAtFinderServiceDelayHandleOnce() {
        tool?.toolBar.atFinderServiceDelayHandleInterval = DispatchQueueConst.MilliSeconds_250
    }

    func resignFirstResponder() {
        pluginProtocol?.resignFirstResponder()
    }

    func noticeWebview(param: [String: Any], callback: DocsJSCallBack, nativeCallback: APICallbackProtocol?) {
        let id = param["id"] as? String
        if id == BarButtonIdentifier.pencilkit.rawValue {
            openWhiteBoard()
        }

        if callback.rawValue.isEmpty {
            nativeCallback?.callbackSuccess(param: param, extra: ["bizDomain": "ccm"])
            return
        }

        pluginProtocol?.callFunction(callback, params: param, completion: { (_, error) in
            if let error = error {
                DocsLogger.error("Inserting block failed with error: ", error: error, component: LogComponents.toolbar)
            }
        })
    }

    func setShouldInterceptEvents(to enable: Bool) {}
}
extension SKEditorToolBarPulgin {
    //展开工具栏对应菜单所需宽度
    enum NeededWidthToUnfoldToolbar: Int {
        case docUnfoldTextTransform //doc工具栏展开文本样式所需最小宽度
        case docUnfoldBlockTransform //doc工具栏展开block样式所需最小宽度
        case docUnfoldAlignTransform //doc工具栏展开对齐所需最小宽度
        case sheetUnfoldTextTransform //sheet@doc工具栏展开文本样式所需最小宽度
        case sheetUnfoldAll //sheet@doc工具栏展开全部所需最小宽度

        //计算attachedBarId二级菜单项个数
        //不包括分割线、高亮色菜单、字体大小调节菜单
        func getAttachToolBarItemsCount(_ toolBarInfos: [ToolBarItemInfo], attachedBarId: String) -> CGFloat {
            var count: CGFloat = 0
            var attachedItem: ToolBarItemInfo?
            toolBarInfos.forEach { (item) in
                if item.identifier == attachedBarId {
                    attachedItem = item
                    return
                }
            }

            guard let item = attachedItem, let children = item.children else { return count }
            //展开二级菜单的一级菜单本身需要删除掉
            count -= 1

            children.forEach({ (item) in
                //checkbox和reminder在一级菜单中已包含，不需要计算个数
                if item.identifier != BarButtonIdentifier.separator.rawValue &&
                    item.identifier != BarButtonIdentifier.highlight.rawValue &&
                    item.identifier != BarButtonIdentifier.fontSize.rawValue &&
                    item.identifier != BarButtonIdentifier.checkbox.rawValue &&
                    item.identifier != BarButtonIdentifier.checkList.rawValue &&
                    item.identifier != BarButtonIdentifier.reminder.rawValue {
                    count += 1
                }
            })

            //仅新版iPad适配的工具栏前端会将h1～h9都传过来
            if attachedBarId == BarButtonIdentifier.blockTransform.rawValue {
                //h4~h9收到hn
                count -= 5
            }

            return count
        }

        public func neededWidth(items: [ToolBarItemInfo]) -> CGFloat {
            let mainToolBarItemsCount: CGFloat = CGFloat(items.count - 2) //减掉两条分割线

            let textTransformCount = getAttachToolBarItemsCount(items, attachedBarId: BarButtonIdentifier.textTransform.rawValue)
            let blockTransformCount = getAttachToolBarItemsCount(items, attachedBarId: BarButtonIdentifier.blockTransform.rawValue)
            let alignTransformCount = getAttachToolBarItemsCount(items, attachedBarId: BarButtonIdentifier.alignTransform.rawValue)

            //需要加上右侧的键盘item
            switch self {
            case .docUnfoldTextTransform:
                let commonItemsCount = textTransformCount + mainToolBarItemsCount
                return (commonItemsCount + 1) * DocsMainToolBarV2.Const.itemWidth +
                    DocsMainToolBarV2.Const.highlightCellWidth +
                    2 * DocsMainToolBarV2.Const.separateWidth +
                    DocsMainToolBarV2.Const.contentInsetPadding
            case .docUnfoldBlockTransform:
                let commonItemsCount = textTransformCount + blockTransformCount + mainToolBarItemsCount
                return (commonItemsCount + 1) * DocsMainToolBarV2.Const.itemWidth +
                    DocsMainToolBarV2.Const.highlightCellWidth +
                    3 * DocsMainToolBarV2.Const.separateWidth +
                    DocsMainToolBarV2.Const.contentInsetPadding
            case .docUnfoldAlignTransform:
                let commonItemsCount = textTransformCount + blockTransformCount + alignTransformCount + mainToolBarItemsCount
                return (commonItemsCount + 1) * DocsMainToolBarV2.Const.itemWidth +
                    DocsMainToolBarV2.Const.highlightCellWidth +
                    4 * DocsMainToolBarV2.Const.separateWidth +
                    DocsMainToolBarV2.Const.contentInsetPadding
            case .sheetUnfoldTextTransform:
                let commonItemsCount = textTransformCount + mainToolBarItemsCount
                return (commonItemsCount + 1) * DocsMainToolBarV2.Const.itemWidth +
                    DocsMainToolBarV2.Const.fontSizeCellWidth +
                    4 * DocsMainToolBarV2.Const.separateWidth +
                    DocsMainToolBarV2.Const.contentInsetPadding
            case .sheetUnfoldAll:
                let commonItemsCount = textTransformCount + alignTransformCount + mainToolBarItemsCount
                return (commonItemsCount + 1) * DocsMainToolBarV2.Const.itemWidth +
                    DocsMainToolBarV2.Const.fontSizeCellWidth +
                    4 * DocsMainToolBarV2.Const.separateWidth +
                    DocsMainToolBarV2.Const.contentInsetPadding
            }
        }
    }

    enum UnfoldType: Int {
        case nothing //不展开
        case textTransform //展开文本样式
        case blockTransform //展开部分Block样式
        case alignTransform //展开对齐
        case all //全部展开

        mutating func foldType(width: CGFloat, type: ToolType, items: [ToolBarItemInfo]) {
            switch type {
            case .DOC:
                switch width {
                case _ where width >= NeededWidthToUnfoldToolbar.docUnfoldTextTransform.neededWidth(items: items) &&
                        width < NeededWidthToUnfoldToolbar.docUnfoldBlockTransform.neededWidth(items: items):
                    DocsLogger.info("iPad tool bar collectionview docUnfoldBlockTransform:\(NeededWidthToUnfoldToolbar.docUnfoldBlockTransform.neededWidth(items: items))")
                    self = .textTransform
                case _ where width >= NeededWidthToUnfoldToolbar.docUnfoldBlockTransform.neededWidth(items: items) &&
                        width < NeededWidthToUnfoldToolbar.docUnfoldAlignTransform.neededWidth(items: items):
                    self = .blockTransform
                case _ where width >= NeededWidthToUnfoldToolbar.docUnfoldAlignTransform.neededWidth(items: items):
                    self = .alignTransform
                default:
                    break
                }
            case .SHEET:
                switch width {
                case _ where width >= NeededWidthToUnfoldToolbar.sheetUnfoldTextTransform.neededWidth(items: items) &&
                        width < NeededWidthToUnfoldToolbar.sheetUnfoldAll.neededWidth(items: items):
                    self = .textTransform
                case _ where width >= NeededWidthToUnfoldToolbar.sheetUnfoldAll.neededWidth(items: items):
                    self = .all
                default:
                    break
                }
            default:
                return
            }
        }
    }
}

extension SKEditorToolBarPulgin: InsertColorPickerDelegate {
    public func didSelectBlock(id: String) {
        pluginProtocol?.requestDismissViewController(completion: nil)
        if id.hasPrefix("mention") { // 如果点击了 at 人、at 群或 at 文件
            setAtFinderServiceDelayHandleOnce()
        }
        //需要旋转倒三角
        guard let mainTBV2 = mainTBPanel as? DocsMainToolBarV2 else { return }
        mainTBV2.docsMainToolBarV2Delegate?.rotationHighlightColorSelectView()
    }

    public func noticeWebScrollUpHeight(height: CGFloat) {
        //调用前端回调
        let params = [
            "isOpenKeyboard": 1,
            "innerHeight": height,
            "keyboardType": "editor"
            ] as [String: Any]

        noticeWebview(param: params, callback: DocsJSCallBack(rawValue: DocsJSService.onKeyboardChanged.rawValue), nativeCallback: nil)
    }
}

//  Created by nine on 2018/3/9.

import Foundation
import SKCommon
import SKUIKit
import SKFoundation
import RxSwift
import LarkTraitCollection
import UniverseDesignColor
import LarkAlertController
import SpaceInterface

public final class UtilAtFinderService: BaseJSService, ToolPlugin {
    weak var tool: BrowserToolConfig?
    private var _atlistManager: SeperateAtlistManager?
    private var atlistManager: SeperateAtlistManager? {
        spaceAssert(Thread.isMainThread)
        if _atlistManager == nil {
            _atlistManager = atlistManger(type: currentAtType)
            _atlistManager?.cancelAction = { [weak self] in
                self?.dismissAtListView()
            }
        }
        return _atlistManager
    }
    private let keyboard = Keyboard()
    private var currentKeyboardHeight: CGFloat = 0
    private var currentAtType: AtViewType    //当前使用AtType
    private let hostAtType: AtViewType //文档AtType
    private var requestType: Set<AtDataSource.RequestType> = AtDataSource.RequestType.userTypeSet
    private let disposeBag = DisposeBag()
    private weak var atListContainerViewController: AtListContainerViewController?
    // 前端光标位置虚拟view
    private lazy var fakeCursorView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, tool: BrowserToolConfig) {
        self.tool = tool
        if EnvConfig.ShouldHideChat.value {
            self.hostAtType = .larkDocs
        } else {
            self.hostAtType = model.hostBrowserInfo.docsInfo?.inherentType == .mindnote ? .mindnote : .docs
        }
        self.currentAtType = self.hostAtType
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)

        keyboard.on(events: [.didChangeFrame]) { [weak self] (options) in
            self?.onKeyboardChange(options: options)
        }
        
        keyboard.on(events: [.willHide]) { [weak self] (options) in
            let isPad = SKDisplay.pad
            let condition1 = options.endFrame.origin.y - options.beginFrame.origin.y < 3.5 // 竖直方向变化很小,调试时发现是2.5
            let condition2 = self?._atlistManager != nil && (options.endFrame.height < options.beginFrame.height)
            let noNeedDismissPopover = isPad && (condition1 || condition2) // 这些情况需要过滤掉，不触发dismiss
            DocsLogger.info("UtilAtFinderService call atFinderNoResult, willHide, options:\(options), atListContainerVC:\(self?.atListContainerViewController), _atlistManager:\(self?._atlistManager)")
            if options.displayType == .floating || noNeedDismissPopover {
                DocsLogger.info("UtilAtFinderService handle willHide, options:\(options), isPad:\(isPad)")
                return
            }
            if self?.atListContainerViewController == nil, self?._atlistManager != nil {
                self?._atlistManager?.downAnimate()
                self?.restoreOrRemoveToolMode()
                DocsLogger.info("UtilAtFinderService call atFinderNoResult")
                self?.model?.jsEngine.callFunction(DocsJSCallBack.atFinderNoResult, params: nil, completion: nil)
            } else {
                self?.hideAtListContainerViewController()
            }
        }
        keyboard.start()
    }

    deinit {
        keyboard.stop()
        tool?.unembed(DocsToolbarManager.ToolConfig(_atlistManager?.atTypeSelectView, direction: .rightToLeft, verticalView: _atlistManager?.listContainerView))
    }

    private func atlistManger(type: AtViewType) -> SeperateAtlistManager? {
        guard let model = self.model else { return nil }
        guard model.requestAgent.currentUrl?.host != nil,
            let fileType = model.browserInfo.docsInfo?.type,
            let token = model.browserInfo.token else { spaceAssertionFailure(); return nil }
        let chatID = model.browserInfo.chatId

        let atConfig = AtDataSource.Config(chatID: chatID, sourceFileType: fileType, location: type, token: token)
        let dataSource = AtDataSource(config: atConfig)
        return SeperateAtlistManager(dataSource, type: type, requestType: requestType, width: self.ui?.editorView.frame.size.width ?? 0)
    }
}

extension UtilAtFinderService: BrowserViewLifeCycleEvent {
    public func browserWillClear() {
        _atlistManager = nil
    }

    public func browserDidUpdateDocsInfo() {
        guard let docsInfo = model?.browserInfo.docsInfo else {
            DocsLogger.info("doc info is nil")
            return
        }
        _atlistManager?.updateAtDataSourceByDocInfo(docsInfo)
    }

    public func browserDidChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation) {
        if SKDisplay.pad, _atlistManager != nil {
            dismissAtListView()
        }
        if atListContainerViewController != nil {
            hideAtListContainerViewController()
        }
    }
}

extension UtilAtFinderService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilAtFinder, .utilGetIPadViewMode, .utilAtFinderReceiveTabAction]
    }

    public func handle(params: [String: Any], serviceName: String) {
        
        DocsLogger.info("UtilAtFinderService handle \(serviceName) params: \(params.jsonString?.encryptToShort)")
        
        switch serviceName {
        case DocsJSService.utilGetIPadViewMode.rawValue:
            handleGetIPadViewModeService(params: params, serviceName: serviceName)
        case DocsJSService.utilAtFinder.rawValue:
            handleAtFinderService(params: params, serviceName: serviceName)
        case DocsJSService.utilAtFinderReceiveTabAction.rawValue:
            handleReceiveMagicKeyboardTabAction(params: params)
        default:
            spaceAssertionFailure("event \(serviceName) not handled")
        }
    }
    
    private func handleGetIPadViewModeService(params: [String: Any], serviceName: String) {
        if let callback = params["callback"] as? String, let ui = ui {
            notifyFrontendTraitCollectionDidChange(callback: callback)
            RootTraitCollection.observer
                .observeRootTraitCollectionDidChange(for: ui.editorView)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: {[weak self] change in
                    guard change.new != change.old, let self = self else {
                        return
                    }
                    self.notifyFrontendTraitCollectionDidChange(callback: callback)
                }).disposed(by: disposeBag)
        }
    }
    
    private func notifyFrontendTraitCollectionDidChange(callback: String) {
        if let dbvc = self.registeredVC as? BrowserViewController {
            let viewMode = dbvc.isMyWindowRegularSizeInPad ? 0 : 1
            model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["viewMode": viewMode], completion: nil)
            DocsLogger.info("notify frontend viewMode: \(viewMode)", component: LogComponents.toolbar)
        }
    }
    
    private func handleAtFinderService(params: [String: Any], serviceName: String) {
        let delayInterval: DispatchTimeInterval = tool?.toolBar.atFinderServiceDelayHandleInterval ?? .milliseconds(0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delayInterval) {
            if self.needPopover(params: params) {
                self.handleCoreWithPopover(params: params)
            } else {
                self.handleCore(params: params, serviceName: serviceName)
            }
            self.tool?.toolBar.atFinderServiceDelayHandleInterval = .milliseconds(0)
        }
        expose(params: params)
    }
    
    /// 判断是否需要popover
    private func needPopover(params: [String: Any]) -> Bool {
        // 非doc, 不支持popover样式
        guard let type = self.hostDocsInfo?.inherentType,
              (type == .doc || type == .docX) else {
            return false
        }
        // 非iPad R视图，不支持popover样式
        guard let dbvc = self.registeredVC as? BrowserViewController, dbvc.isMyWindowRegularSizeInPad else {
            return false
        }
        return true
    }
    
    private func handleCore(params: [String: Any], serviceName: String) {
        guard let showValue = params["show"] as? Int, let filter = params["type"] as? String else {
            DocsLogger.info("wrong js params \(params)", component: LogComponents.toolbar)
            return
        }
        let show = showValue == 1
        DocsLogger.debug("js params \(params)", component: LogComponents.toolbar)
        let content = params["content"] as? String ?? ""
        guard let tool = tool else { return }
        
        if show {
            //修改mention类型
            if UserScopeNoChangeFG.LJY.enableSyncBlock {
                var newAtType = self.currentAtType
                if let from = params["from"] as? String, let extViewType = ExtAtViewType(rawValue: from)?.viewType {
                    newAtType = extViewType
                } else {
                    newAtType = self.hostAtType
                }
                if newAtType != self.currentAtType {
                    self._atlistManager?.downAnimate()
                    self.restoreOrRemoveToolMode()
                    _atlistManager = nil //mention类型变了，需要重置
                    DocsLogger.info("mention atType change \(self.currentAtType.rawValue) to \(newAtType.rawValue)")
                    self.currentAtType = newAtType
                }
            }
        }
        
        tool.embed(DocsToolbarManager.ToolConfig(atlistManager?.atTypeSelectView, direction: .rightToLeft, verticalView: atlistManager?.listContainerView))

        if show {
            var source = AtTracker.Source.unknown
            var zone = AtTracker.Zone.unknown
            var type = DocsType.unknownDefaultType
            
            if tool.currentMode != .atSelection {
                let newScrollViewHeight = scrollViewHeight
                DocsLogger.debug("calculated scroll view height: \(newScrollViewHeight)", component: LogComponents.toolbar)
                atlistManager?.scrollViewHeight = newScrollViewHeight
                atlistManager?.setupAtSelectTypeView()
                let toolConfig = DocsToolbarManager.ToolConfig(atlistManager?.atTypeSelectView, direction: .rightToLeft, verticalView: atlistManager?.listContainerView)
                tool.set(toolConfig, mode: .atSelection)
                tool.toolBar.showKeyboard()
                
                atlistManager?.configScrollViewLayout(contentWidth: self.ui?.editorView.frame.width)
                if let mention = params["mention"] as? [String: Any] {
                    source = AtTracker.Source(rawValue: mention["source"] as? String ?? "") ?? .unknown
                    zone = AtTracker.Zone(rawValue: mention["zone"] as? String ?? "") ?? .unknown
                    if let value = mention["file_type"] as? Int {
                        type = DocsType(rawValue: value)
                    } else {
                        type = .unknownDefaultType
                    }
                    reportOpenAt(fileType: type, zone: zone, source: source)
                }
            }
            var atCheckboxData: AtCheckboxData?
            if let checkBoxData = params["checkboxData"] as? [String: Any],
               let checkboxTypeValue = checkBoxData["checkBoxType"] as? Int,
               let checkboxType = AtCheckboxData.CheckboxType(rawValue: checkboxTypeValue),
               let text = checkBoxData["text"] as? String {
                let isSelected = checkBoxData["isSelected"] as? Bool ?? false
                atCheckboxData = AtCheckboxData(checkBoxType: checkboxType, text: text, isSelected: isSelected)
            }
            
            atlistManager?.configCheckboxData(atCheckboxData)
            
            // update and config
            _atlistManager?.refresh(with: content, filter: getRequestTypeSetFrom(filter))
            if let initialPage = params["mentionPanel"] as? String {
                requestType = AtDataSource.RequestType.decode(from: initialPage)
                _atlistManager?.atTypeSelectView.updateRequestType(to: requestType)
                _atlistManager?.updateScrollViewRequestType(to: requestType)
            }
            if let callback = params["callback"] as? String {
                _atlistManager?.selectAction = { [weak self] at, info, _ in
                    guard let `self` = self else { return }
                    DocsLogger.info("\(serviceName) callback", component: LogComponents.toolbar)
                    self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: info, completion: { (_, error) in
                        error.map({
                            DocsLogger.info("js error, error is \($0)")
                        })
                    })

                    if let atInfo = at {
                        self.doStaticsForAtConfirm(fileType: type, atInfo: atInfo, zone: zone, source: source)
                    }
                    self.dismissAtListView()
                }
            }
        } else {
            if tool.currentMode == .atSelection {
                self.dismissAtListView()
            }
        }
    }
    
    private func handleCoreWithPopover(params: [String: Any]) {
        guard let showValue = params["show"] as? Int else {
            DocsLogger.info("wrong js params \(params)", component: LogComponents.toolbar)
            return
        }
        let show = showValue == 1
        guard let dbvc = self.registeredVC as? BrowserViewController else {
            return
        }
        let content = params["content"] as? String ?? ""
        if show {
            if UserScopeNoChangeFG.LJY.enableSyncBlock {
                if let from = params["from"] as? String, let extViewType = ExtAtViewType(rawValue: from)?.viewType {
                    self.currentAtType = extViewType
                } else {
                    self.currentAtType = self.hostAtType
                }
            }
            
            if let initialPage = params["mentionPanel"] as? String {
                requestType = AtDataSource.RequestType.decode(from: initialPage)
            }
            if let position = params["position"] as? [String: Any],
                  let x = position["x"] as? CGFloat,
                  let y = position["y"] as? CGFloat,
                  let height = position["height"] as? CGFloat {
                //将前端传过来的坐标转换为屏幕坐标
                let point = ui?.editorView.convert(CGPoint(x: x, y: y), to: ui?.editorView) ?? CGPoint(x: x, y: y)
                
                var atCheckboxData: AtCheckboxData?
                if let checkBoxData = params["checkboxData"] as? [String: Any],
                   let checkboxTypeValue = checkBoxData["checkBoxType"] as? Int,
                   let checkboxType = AtCheckboxData.CheckboxType(rawValue: checkboxTypeValue),
                   let text = checkBoxData["text"] as? String {
                    let isSelected = checkBoxData["isSelected"] as? Bool ?? false
                    atCheckboxData = AtCheckboxData(checkBoxType: checkboxType, text: text, isSelected: isSelected)
                }
                showAtListContainerVC(point: point, height: height, cursorParentView: ui?.editorView, checkboxData: atCheckboxData)
            }
            refreshAtListView(content)
            
            if let initialPage = params["mentionPanel"] as? String {
                requestType = AtDataSource.RequestType.decode(from: initialPage)
                atListContainerViewController?.updateContentOffset(requestType: requestType)
            }
            var source = AtTracker.Source.unknown
            var zone = AtTracker.Zone.unknown
            var type = DocsType.unknownDefaultType
            if let mention = params["mention"] as? [String: Any] {
                source = AtTracker.Source(rawValue: mention["source"] as? String ?? "") ?? .unknown
                zone = AtTracker.Zone(rawValue: mention["zone"] as? String ?? "") ?? .unknown
                if let value = mention["file_type"] as? Int {
                    type = DocsType(rawValue: value)
                } else {
                    type = .unknownDefaultType
                }
                reportOpenAt(fileType: type, zone: zone, source: source)
            }
            
            if let callback = params["callback"] as? String {
                atListContainerViewController?.atListView.selectAction = { [weak self] at, info, _ in
                    guard let `self` = self else { return }
                    self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: info, completion: { (_, error) in
                        error.map({
                            DocsLogger.info("js error, error is \($0)")
                        })
                    })
                    if let atInfo = at {
                        self.doStaticsForAtConfirm(fileType: type, atInfo: atInfo, zone: zone, source: source)
                    }
                    self.hideAtListContainerViewController()
                }
            }
        } else {
            let needCallNoResult = !(SKDisplay.pad) // ipad这里不调用多余的atFinderNoResult隐藏操作
            self.hideAtListContainerViewController()
        }
    }
    
    private func getRequestTypeSetFrom(_ requestStr: String) -> Set<AtDataSource.RequestType> {
        let strArray = requestStr.components(separatedBy: ",")
        let requestTypeArray: [AtDataSource.RequestType] = strArray.compactMap({
            if let intValue = Int($0) {
                return AtDataSource.RequestType(rawValue: intValue)
            }
            return nil
        })
        return Set(requestTypeArray)
    }

    private func handleReceiveMagicKeyboardTabAction(params: [String: Any]) {
        guard let vc = atListContainerViewController else {
            return
        }
        vc.didReceiveMagicKeyboardTabAction()
    }
}
/// @面板 for iPad
extension UtilAtFinderService {
    private func setupAtListContainerViewController() -> AtListContainerViewController? {
        guard let model = self.model else {
            return nil
        }
        guard model.requestAgent.currentUrl?.host != nil,
              let fileType = model.browserInfo.docsInfo?.type,
              let token = model.browserInfo.token else {
            return nil
        }
        let chatID = model.browserInfo.chatId
        let atConfig = AtDataSource.Config(chatID: chatID, sourceFileType: fileType, location: currentAtType, token: token)
        let dataSource = AtDataSource(config: atConfig)
        let type = currentAtType
        let atRequestType = requestType
        let vc = AtListContainerViewController(dataSource, type: type, requestType: atRequestType)
        return vc
    }
    
    // 展示@列表
    private func showAtListContainerVC(point: CGPoint, height: CGFloat, cursorParentView: UIView?, checkboxData: AtCheckboxData?) {
        
        let vc: AtListContainerViewController
        if let atListContainerVC = atListContainerViewController {
            vc = atListContainerVC
        } else if let newListContainerVC = setupAtListContainerViewController() {
            vc = newListContainerVC
        } else {
            DocsLogger.error("setupAtListContainerViewController error", component: LogComponents.toolbar)
            return
        }
        vc.configCheckboxData(checkboxData)
        if vc.presentingViewController != nil {
            DocsLogger.info("AtListContainerViewController is presenting")
            return
        }
        guard let cursorContainer = cursorParentView else { return }
        if fakeCursorView.superview == nil {
            cursorContainer.addSubview(fakeCursorView)
        }
        
        DocsLogger.info("show atListContainerViewController")
        fakeCursorView.frame = CGRect(x: point.x + height * 0.8, y: point.y, width: 1, height: height + 6)
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.backgroundColor = UDColor.bgFloat
        vc.popoverPresentationController?.sourceView = fakeCursorView
        vc.popoverPresentationController?.sourceRect = fakeCursorView.bounds
        vc.popoverPresentationController?.popoverLayoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 50, right: 16)
        vc.popoverPresentationController?.permittedArrowDirections = [.up, .down, .left, .right]
        
        vc.disappearCallBack = { [weak self] in
            self?.fakeCursorView.removeFromSuperview()
            self?.ui?.displayConfig.isPopoverAtFinderScene = false
        }
        let obj = ObjectIdentifier(vc)
        vc.dismissCallBack = {[weak self] in
            DocsLogger.info("UtilAtFinderService call atFinderNoResult, popover:\(obj) dismissCallBack")
            self?.model?.jsEngine.callFunction(DocsJSCallBack.atFinderNoResult, params: nil, completion: nil)
        }
        navigator?.presentViewController(vc, animated: true, completion: nil)
        self.atListContainerViewController = vc
        self.ui?.displayConfig.isPopoverAtFinderScene = true
    }
    // 隐藏@列表
    private func hideAtListContainerViewController() {
        atListContainerViewController?.dismiss(animated: true, completion: nil)
        AtTracker.commonParams = [:]
    }
    
    // 刷新列表
    private func refreshAtListView(_ keyword: String?) {
        atListContainerViewController?.atListView.refresh(with: keyword ?? "", filter: AtDataSource.RequestType.atViewFilter, animated: false)
    }
}
extension UtilAtFinderService {
    func dismissAtListView() {
        _atlistManager?.downAnimate()
        restoreOrRemoveToolMode()
        tool?.toolBar.reloadItems()
        tool?.toolBar.reloadPanel()
        DocsLogger.info("UtilAtFinderService call atFinderNoResult, dismissAtListView")
        self.model?.jsEngine.callFunction(DocsJSCallBack.atFinderNoResult, params: nil, completion: nil)
        AtTracker.commonParams = [:]
    }
    /// 如果当前工具栏有旧的模式，则退到之前的模式，如果没，则移除。
    func restoreOrRemoveToolMode() {
        guard let _tool = tool else { return }
        if _tool.lastestMode != .none && _tool.lastestMode != .atSelection {
            _tool.restore(mode: .atSelection)
        } else {
            _tool.remove(mode: .atSelection)
        }
    }
}
// MARK: - 键盘事件
extension UtilAtFinderService {
    private var scrollViewHeight: CGFloat {
        guard let dbvc = registeredVC as? BrowserViewController else {
            DocsLogger.error("当前不在 docs browser 里面，不能看 at", component: LogComponents.toolbar)
            return 0
        }
        let maxHeight = dbvc.view.bounds.height + dbvc.browserViewDistanceToWindowBottom
        let leftoutHeight = 129 - SeperateAtlistManager.shadowHeight
        var viewHeight = maxHeight - currentKeyboardHeight - dbvc.statusBar.bounds.height - leftoutHeight
        if SKDisplay.pad { viewHeight -= dbvc.navigationBar.bounds.height }
        return viewHeight
    }

    private func onKeyboardChange(options: Keyboard.KeyboardOptions) {
        currentKeyboardHeight = options.endFrame.size.height
        let newHeight = scrollViewHeight
        DocsLogger.info("keyboard height changed to \(currentKeyboardHeight), reset scrollview height: \(newHeight)", component: LogComponents.toolbar)
        _atlistManager?.updateScrollViewLayout(height: newHeight)
    }
}
/// 埋点
extension UtilAtFinderService {
    private func reportOpenAt(fileType: DocsType, zone: AtTracker.Zone, source: AtTracker.Source) {
        guard let objToken = model?.browserInfo.docsInfo?.objToken,
            let type = model?.browserInfo.docsInfo?.type else { return }
        let fileId = DocsTracker.encrypt(id: objToken)
        let context = AtTracker.Context(module: type,
                                        fileType: fileType,
                                        fileId: fileId,
                                        zone: zone,
                                        source: source)
        AtTracker.logOpen(with: context)
    }
    private func doStaticsForAtConfirm(fileType: DocsType, atInfo: AtInfo, zone: AtTracker.Zone, source: AtTracker.Source) {
        let mentionType = atInfo.type.strForMentionType
        let subType = atInfo.type.strForMentionSubType
        guard let objToken = model?.browserInfo.docsInfo?.objToken,
            let type = model?.browserInfo.docsInfo?.type else { return }
        let fileId = DocsTracker.encrypt(id: objToken)
        let context = AtTracker.Context(mentionType: mentionType,
                                        mentionSubType: subType,
                                        module: type,
                                        fileType: fileType,
                                        fileId: fileId,
                                        zone: zone,
                                        source: source)
        AtTracker.logConfirm(with: context)
        var mentionId = atInfo.id ?? ""
        if atInfo.type != .user {
            mentionId = atInfo.token
        }
        AtTracker.mentionReport(type: atInfo.type.strForMentionType, mentionId: mentionId, isSendNotice: false, domain: .text, docsInfo: model?.browserInfo.docsInfo)
    }
    private func expose(params: [String: Any]) {
       var bizCommonParams: [String: Any] = [:]
       if let biz = params["bizCommonParams"] as? [String: Any] {
           bizCommonParams = biz
       }
       AtTracker.commonParams = bizCommonParams
       AtTracker.expose(parameter: bizCommonParams, docsInfo: model?.browserInfo.docsInfo)
       SheetTracker.report(event: .insertMention, docsInfo: model?.browserInfo.docsInfo)
    }
}

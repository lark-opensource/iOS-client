//
//  SheetToolManagerService.swift
//  SpaceKit
//
//  Created by Webster on 2019/7/10.
//

import Foundation
import EENavigator
import RxSwift
import SKCommon
import SKBrowser
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignToast

struct SheetToolkitTapItem {
    var tapId = ""
    var title = ""
    var enable = false
    var items: [(String, ToolBarItemInfo)] = []

    func info(for sid: String) -> ToolBarItemInfo? {
        return items.first(where: { (id, _) -> Bool in
            id == sid
        })?.1
    }
}

enum SheetRangeType: String {
    case cell = "cell"
    case row = "row"
    case col = "column"
}

class SheetToolManagerService: BaseJSService {
    var fabJsMethod = "" //fab点击对前端的回调
    var toolJsMethod = "" //工具箱点击前端回调
    var filterJsMethod = "" //筛选对应的前端回调
    var toolkitRedirectURL = "" //前端toolkit资源定位路径
    var mustDisplayToolkit = false
    var rangeType: SheetRangeType?
    let disposeBag = DisposeBag()

    var toolkitInfos = [SheetToolkitTapItem]()
    var filterInfos: [SheetFilterType: SheetFilterInfo] = [:]
    var navVC: UINavigationController?
    
    func findToolBarItemInfo(identifier: String) -> ToolBarItemInfo? {
        for sheetToolkitTapItem in toolkitInfos {
            if let item = sheetToolkitTapItem.info(for: identifier) {
                return item
            }
        }
        return nil
    }
    
    lazy var fabContainer: FABContainer = {
        let view = FABContainer()
        view.delegate = self
        view.backgroundColor = .clear
        if let sbvc = registeredVC as? SheetBrowserViewController {
            sbvc.fabContainer = view
        }
        return view
    }()

    lazy var manager: SheetToolkitManager = {
        let manager = SheetToolkitManager(navigator: self.navigator)
        manager.delegate = self
        manager.dataSource = self
        manager.docsInfo = self.model?.browserInfo.docsInfo
        if let sbvc = registeredVC as? SheetBrowserViewController {
            sbvc.toolkitManager = manager
        }
        return manager
    }()

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(dismissPanelBeforeShowComment), name: Notification.Name.DismissPanelBeforeShowComment, object: nil)
    }
    
    @objc
    func dismissPanelBeforeShowComment(noti: Notification) {
        guard let identifier = noti.object as? String, identifier == self.editorIdentity else {
            return
        }
        manager.hideToolkitView(immediately: true)
    }
}

extension SheetToolManagerService: BrowserViewLifeCycleEvent {
    func browserWillTransition(from: CGSize, to: CGSize) {
        manager.removeToolkitView(trigger: DocsKeyboardTrigger.sheetOperation.rawValue)
        SheetTracker.report(event: .closeToolbox(action: 1), docsInfo: self.model?.browserInfo.docsInfo)
    }

    func browserDidTransition(from: CGSize, to: CGSize) { }

    func browserDidHideLoading() {

    }
    
    func browserDidSplitModeChange() {
        manager.removeToolkitView(trigger: DocsKeyboardTrigger.sheetOperation.rawValue)
        SheetTracker.report(event: .closeToolbox(action: 1), docsInfo: self.model?.browserInfo.docsInfo)
    }
}

extension SheetToolManagerService: DocsJSServiceHandler {

    var handleServices: [DocsJSService] {
        // 返回最全的jsb数组, handle时按需处理, 以免产生未注册的问题
        return [.sheetOperationPanel, .sheetFABButtons, .sheetFilter, .simulateOpenSheetToolkit, .sheetClearBorderLinePanel]
    }

    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("SheetToolService:\(serviceName), params:\(params.count)")
        switch serviceName {
        case DocsJSService.sheetFABButtons.rawValue:
            handleFABButton(params)
        case DocsJSService.sheetOperationPanel.rawValue:
            handlePanelInfo(params)
        case DocsJSService.sheetFilter.rawValue:
            handleFilterInfo(params)
        case DocsJSService.simulateOpenSheetToolkit.rawValue:
            model?.jsEngine.callFunction(DocsJSCallBack(fabJsMethod), params: params, completion: nil)
        case DocsJSService.sheetClearBorderLinePanel.rawValue:
            clearBorderPanel()
        default:
            ()
        }
    }
}

private extension SheetToolManagerService {
    private func handleFABButton(_ params: [String: Any]) {
        DocsLogger.info("handleFABButton params: \(params.count)")
        guard let fabParams = FABParams.deserialize(from: params), !fabParams.data.isEmpty,
              let bvc = registeredVC as? BrowserViewController, let browserView = bvc.editor else {
            DocsLogger.info("sheet setFabButtons removeFromSuperview")
            fabContainer.updateButtons([])
            fabContainer.removeFromSuperview()
            return
        }
        DocsLogger.info("handleFABButton fabParams: \(fabParams)")
        fabJsMethod = fabParams.callback
        let fabContainerExistence = attachFABContainer(fabParams.data)

        if !fabContainerExistence {
            browserView.fabContainer = nil
            return
        } else {
            browserView.fabContainer = fabContainer
        }

        //如果快速操作面板的按钮消失，也是要关闭fab
        if !fabParams.data.map(\.id).contains(.toolkit) {
            manager.removeToolkitView(trigger: DocsKeyboardTrigger.sheetOperation.rawValue)
        }

        updateFAB(fabParams.data)
    }

    private func updateFAB(_ buttonInfos: [FABData]) {
        fabContainer.updateButtons(buttonInfos)
        fabContainer.snp.remakeConstraints { (make) in
            make.right.equalToSuperview()
            if let superview = fabContainer.superview {
                make.bottom.equalToSuperview().offset(-(superview.safeAreaInsets.bottom + 14))
            } else {
                make.bottom.equalToSuperview().offset(-14)
            }
        }

    }

    private func attachFABContainer(_ data: [FABData]) -> Bool {
        guard let hostView = ui?.editorView else {
            return false
        }

        if data.count > 0 {
            fabContainer.removeFromSuperview()
            fabContainer.snp.removeConstraints()

            hostView.addSubview(fabContainer)
            fabContainer.snp.makeConstraints { (make) in
                make.right.equalToSuperview()
                var bottomSafeAreaHeight: CGFloat = 0
                if let superview = fabContainer.superview {
                    bottomSafeAreaHeight = superview.safeAreaInsets.bottom
                }
                make.bottom.equalToSuperview().offset(-bottomSafeAreaHeight)
            }
            manager.fabButtonPanel = fabContainer
            return true
        } else {
            manager.fabButtonPanel = nil
            fabContainer.removeFromSuperview()
            return false
        }
        return true
    }
}

extension SheetToolManagerService: FABContainerDelegate {
    func didClickFABButton(_ button: FABIdentifier, view: FABContainer) {
        switch button {
        case .search:
            manager.removeAllView(trigger: DocsKeyboardTrigger.sheetEditor.rawValue)
            model?.jsEngine.simulateJSMessage(DocsJSService.simulateOpenSearch.rawValue, params: [String: Any]())
        default:
            ()
        }
        callJsEngine(identifier: button.rawValue, value: nil, jsMethod: fabJsMethod)
    }
}

extension SheetToolManagerService: SheetToolkitManagerDelegate {

    func toolkitRequestNavigation(identifier: String, value: Any?, viewType: ToolkitViewType, manager: SheetToolkitManager, itemIsEnable: Bool) {
        if itemIsEnable {
            switch identifier {
            case BarButtonIdentifier.search.rawValue:
                manager.removeAllView(trigger: DocsKeyboardTrigger.sheetEditor.rawValue)
                model?.jsEngine.simulateJSMessage(DocsJSService.simulateOpenSearch.rawValue, params: [String: Any]())
            case BarButtonIdentifier.freeze.rawValue:
                manager.toolkitContainerPush(BadgedItemIdentifier.freeze.rawValue)
            case BarButtonIdentifier.cellFilter.rawValue:
                manager.toolkitContainerPush(BadgedItemIdentifier.filter.rawValue)
            case BarButtonIdentifier.cellFilterByValue.rawValue:
                manager.toolkitContainerPush(BadgedItemIdentifier.filterValue.rawValue)
            case BarButtonIdentifier.cellFilterByCondition.rawValue:
                manager.toolkitContainerPush(BadgedItemIdentifier.filterCondition.rawValue)
            case BarButtonIdentifier.cellFilterByColor.rawValue:
                manager.toolkitContainerPush(BadgedItemIdentifier.filterColor.rawValue)
            case BarButtonIdentifier.uploadImage.rawValue:
                if let item = findToolBarItemInfo(identifier: identifier), !item.adminLimit {
                    manager.toolkitContainerPush(BadgedItemIdentifier.uploadImage.rawValue)
                }
            case BarButtonIdentifier.exportImage.rawValue:
                if CacheService.isDiskCryptoEnable() {
                    //KACrypto
                    DocsLogger.error("[KACrypto] 开启KA加密不能一键生图")
                    guard let window = navigator?.currentBrowserVC?.view.window else {
                        return
                    }
                    UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_ShareSecuritySettingKAToast,
                                           on: window)
                    return
                }
            default:
                ()
            }
        }
        callJsEngine(identifier: identifier, value: value, jsMethod: toolJsMethod)
    }

    func toolkitRequestSwitchPanel(_ panelId: String, value: String?, manager: SheetToolkitManager) {
        callJsEngine(identifier: panelId, value: value, jsMethod: toolJsMethod)
    }

    func didChangePanelHeight(_ info: SimulateKeyboardInfo, manager: SheetToolkitManager) {
        let params: [String: Any] = [SimulateKeyboardInfo.key: info]
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
    }

    func didPressAccessoryKeyboard(_ button: FloatButton?, manager: SheetToolkitManager) {
        logFabToolkitSwitchToKeyboard()
        callJsEngine(identifier: FABIdentifier.keyboard.rawValue, value: nil, jsMethod: fabJsMethod)
    }

    func filterRequestJsUpdateValue(_ identifier: String, value: String?, filterInfo: SheetFilterInfo, manager: SheetToolkitManager) {

        let params: [String: Any] = ["id": identifier,
                                     "value": value ?? "",
                                     "sheetId": filterInfo.sheetId,
                                     "currentCol": filterInfo.colIndex]
        model?.jsEngine.callFunction(DocsJSCallBack(filterJsMethod), params: params, completion: nil)
    }

    func filterRequestJsUpdateRange(_ identifier: String, range: [Any]?, filterInfo: SheetFilterInfo, manager: SheetToolkitManager, bySearch: Bool?) {

        var params: [String: Any] = ["id": identifier,
                                     "value": range ?? [String](),
                                     "sheetId": filterInfo.sheetId,
                                     "currentCol": filterInfo.colIndex]
        if let search = bySearch {
            params["isSearch"] = search
        }
        model?.jsEngine.callFunction(DocsJSCallBack(filterJsMethod), params: params, completion: nil)
    }

    func filterByValueDidPressPanelSearchButton(fromToolkit: Bool, manager: SheetToolkitManager) {
        logPressFilterSearchButton(fromToolkit: fromToolkit)
    }

    func filterByValueDidPressKeyboardSearchButton(fromToolkit: Bool, manager: SheetToolkitManager) {
        logStartFilterSearch(fromToolkit: fromToolkit)
    }

    func adjustPanelModel(_ model: SheetToolkitFloatModel, fromToolkit: Bool, manager: SheetToolkitManager) {
        logAdjustSheetToolkitFloatModel(floatModel: model, fromToolkit: fromToolkit)
    }
}

extension SheetToolManagerService: SheetToolkitManagerDataSource {
    var statusBarHeight: CGFloat {
        guard let dbvc = registeredVC as? BrowserViewController else { return 0 }
        return dbvc.statusBar.bounds.height
    }

    var topContainerHeight: CGFloat {
        guard let dbvc = registeredVC as? BrowserViewController else { return 0 }
        return dbvc.topContainer.bounds.height
    }

    func supportJSEngine(_ manager: SheetToolkitManager) -> BrowserJSEngine? {
        return model?.jsEngine
    }

    var primaryBrowserViewDistanceToWindowBottom: CGFloat {
        guard let dbvc = registeredVC as? BrowserViewController else { return 0 }
        return dbvc.browserViewDistanceToWindowBottom
    }
}

extension SheetToolManagerService {

    private func callJsEngine(identifier: String, value: Any?, jsMethod: String) {
        let params: [String: Any]
        if let sValue = value {
            params = ["id": identifier, "value": sValue]
        } else {
            params = ["id": identifier]
        }
        model?.jsEngine.callFunction(DocsJSCallBack(jsMethod), params: params, completion: nil)
    }
}

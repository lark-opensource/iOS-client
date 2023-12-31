//
//  BTContainerJSService.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/9.
//

import SKFoundation
import SKCommon
import SKUIKit
import HandyJSON
import SKInfra

struct ViewToolBarData: SKFastDecodable {
    var stat: SimpleItem?
    var toolMenu: [SimpleItem] = []
    var callback: String?

    static func deserialized(with dictionary: [String : Any]) -> ViewToolBarData {
        var model = ViewToolBarData()
        model.stat <~ (dictionary, "stat")
        model.toolMenu <~ (dictionary, "toolMenu")
        model.callback <~ (dictionary, "callback")
        return model
    }
}

struct BTViewContainerModel: HandyJSON, Equatable {
    var currentViewId: String?
    var viewList: [SimpleItem]?
    var callback: String?
    var moreAction: String?
    var currentViewType: ViewType = .grid
    var tableId: String = ""
    var baseId: String = ""
}

final class BTContainerJSService: BaseJSService {
    
    var container: BTContainer? {
        get {
            return (registeredVC as? BitableBrowserViewController)?.container
        }
    }
    
    private var baseInSheetCatalogueView: BaseInSheetCatalogueView?

    private var currentSceneModel: ContainerSceneModel?
    private var currentViewContainerData: BTViewContainerModel?
    private var currentToolbarData: ViewToolBarData?
    
    private var needUpdateSheetCatalogue: Bool = false
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(statusBarOrientationDidChange(_:)),
            name: UIApplication.didChangeStatusBarOrientationNotification,
            object: nil
        )
    }

    @objc
    private func statusBarOrientationDidChange(_ notification: Notification) {
        guard let currentToolbarData = currentToolbarData else {
            DocsLogger.btInfo("[BTViewContainerService] currentToolbarData is nil when statusBarOrientationDidChange")
            return
        }
        handleSetToolBar(data: currentToolbarData)
    }
}

extension BTContainerJSService: DocsJSServiceHandler {
    
    var handleServices: [DocsJSService] {
        return [
            .updateScene,
            .setViewContainer,
            .setTooBar,
            .setHeaderContainer,
            .onWebContentChange
        ]
    }
    
    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.btInfo("BTContainerJSService handle \(serviceName)")
        switch DocsJSService(serviceName) {
        case .updateScene:
            handleUpdateScene(params: params)
            break
        case DocsJSService.setViewContainer:
            handleSetViewContainer(params)
            break
        case DocsJSService.setTooBar:
            handleSetToolBar(params)
            break
        case .setHeaderContainer:
            handleSetHeaderContainer(params)
            break
        case .onWebContentChange:
            handleOnWebContentChange(params)
            break
        default:
            DocsLogger.btError("unsurpported \(serviceName)")
        }
    }
    
    private func handleSetViewContainer(_ params: [String: Any]) {
        guard let viewContainerData = BTViewContainerModel.deserialize(from: params) else {
            DocsLogger.btError("[BTViewContainerService] params deserialize fail")
            return
        }
        currentViewContainerData = viewContainerData
        if let container = container {
            container.updateViewContainerModel(viewContainerModel: viewContainerData)
            return
        }
        setNeedUpdateSheetCatalogue()
    }

    private func handleUpdateScene(params: [String: Any]) {
        let sceneModel = ContainerSceneModel.convert(from: params)
        if sceneModel == self.currentSceneModel {
            DocsLogger.info("sceneModel no update")
            return
        }
        self.currentSceneModel = sceneModel
        if let container = container {
            container.updateContainerSceneModel(containerSceneModel: sceneModel)
            // 视图切换隐藏native view
            if UserScopeNoChangeFG.XM.nativeCardViewEnable {
                if sceneModel.nativeViewType != nil {
                    DocsLogger.btInfo("handleUpdateScene show nativeRenderView")
                    container.nativeRendrePlugin.showNativeRenderView()
                } else {
                    DocsLogger.btInfo("handleUpdateScene hide nativeRenderView")
                    container.nativeRendrePlugin.hideNativeRenderView()
                }
            }
            return
        }
        setNeedUpdateSheetCatalogue()
    }
    
    private func handleSetToolBar(_ paramas: [String: Any]) {
        let shortEnrypt = paramas.jsonString?.encryptToShort ?? ""
        DocsLogger.info("[BTJSService] ViewToolBar handle paramas \(shortEnrypt)")
        let data = ViewToolBarData.deserialized(with: paramas)
        if currentToolbarData == nil {
            toolBarTrack(.view)
        }
        currentToolbarData = data
        handleSetToolBar(data: data)
    }

    private func handleSetToolBar(data: ViewToolBarData) {
        guard let callback = data.callback else {
            DocsLogger.btError("[BTJSService] ViewToolBar empty callback")
            return
        }
        if let container = container {
            let toolBar = container.toolBarPlugin.viewToolBar
            updateToolBar(toolBar)
            return
        }
        setNeedUpdateSheetCatalogue()
    }
    
    private func updateToolBar(_ toolBar: ViewToolBar) {
        guard let data = self.currentToolbarData,
              let callback = data.callback
        else {
            DocsLogger.btError("[BTJSService] ViewToolBar empty currentToolbarData or callback")
            return
        }
        toolBar.setData(data)
        toolBar.statActionClick = { [weak self] in
            guard let self = self else { return }
            if let id = data.stat?.id,
               let action = data.stat?.clickAction {
                self.model?.jsEngine.callFunction(DocsJSCallBack(callback),
                                                  params: ["id": id, "action": action],
                                                  completion: nil)
            } else {
                DocsLogger.error("[BTJSService] ViewToolBar click stat without action id")
            }
        }
        let plainAction: (Int) -> Void = { [weak self] index in
            let menu = data.toolMenu.safe(index: index)
            if let id = menu?.id,
               let action = menu?.clickAction {
                self?.model?.jsEngine.callFunction(DocsJSCallBack(callback),
                                                   params: ["id": id, "action": action],
                                                   completion: nil)
                var dest: String = "unknow"
                switch id {
                case "ViewFilter":
                    dest = "Filter"
                case "ViewSort":
                    dest = "Sort"
                case "ViewLayout":
                    dest = "Layout"
                default:
                    dest = "unknow"
                }
                let item = BTBottomToolBarItemModel(id: dest)
                self?.toolBarTrack(.click(item: item))
            } else {
                DocsLogger.btError("[BTJSService] ViewToolBar cant find action id \(menu)")
            }
        }
        toolBar.firstClick = {
            plainAction(0)
        }

        toolBar.secondClick = {
            plainAction(1)
        }

        toolBar.thirdClick = {
            plainAction(2)
        }
    }
    
    private var shouldShowSheetCatalogue: Bool {
        get {
            guard isSheet else {
                return false
            }
            guard let currentSceneModel = self.currentSceneModel else {
                return false
            }
            guard currentSceneModel.embeddedInSheet == true && currentSceneModel.viewType != nil else {
                return false
            }
            guard let currentViewContainerData = self.currentViewContainerData else {
                return false
            }
            return currentViewContainerData.viewList?.count ?? 0 > 0
        }
    }
    
    /// 做一下聚合限频
    private func setNeedUpdateSheetCatalogue() {
        needUpdateSheetCatalogue = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else {
                return
            }
            guard self.needUpdateSheetCatalogue else {
                return
            }
            self.updateSheetCatalogueIfNeeded()
        }
    }

    private func updateSheetCatalogueIfNeeded() {
        self.needUpdateSheetCatalogue = false
        guard isSheet else {
            return
        }
        guard let displayConfig = ui?.displayConfig else {
            DocsLogger.info("invalid displayConfig")
            return
        }
        if !shouldShowSheetCatalogue {
            DocsLogger.info("hide SheetCatalogue")
            displayConfig.setCatalogueBanner(catalogueBannerData: nil, callback: nil)
            displayConfig.setCatalogueBanner(visible: false)
            return
        }
        
        guard let viewContainerData = currentViewContainerData else {
            return
        }
        DocsLogger.info("show SheetCatalogue")
        let showToolbar = (currentToolbarData?.stat != nil ||
                           currentToolbarData?.toolMenu.count ?? 0 > 0) &&
                           viewContainerData.currentViewType.shouldToolBar
        
        
        var catalogueBannerData = SKCatalogueBannerData()
        let baseInSheetCatalogueView: BaseInSheetCatalogueView = self.baseInSheetCatalogueView ?? BaseInSheetCatalogueView()
        baseInSheetCatalogueView.viewToolBar.isHidden = !showToolbar
        baseInSheetCatalogueView.updateLayerColor()
        self.baseInSheetCatalogueView = baseInSheetCatalogueView
        catalogueBannerData.customView = baseInSheetCatalogueView
        catalogueBannerData.preferedHeight = showToolbar ? 96 : 60
        displayConfig.setCatalogueBanner(catalogueBannerData: catalogueBannerData) { [weak self] _ in
            guard let self = self else {
                DocsLogger.warning("self released")
                return
            }
            guard let callback = viewContainerData.callback else {
                DocsLogger.warning("callback is nil")
                return
            }
            guard let model = self.model else {
                DocsLogger.warning("self.model is nil")
                return
            }
            model.jsEngine.callFunction(
                DocsJSCallBack(callback),
                params: ["id": "catalog"],
                completion: nil
            )
        }
        
        baseInSheetCatalogueView.updateCurrentViewData(currentViewData: viewContainerData)
        baseInSheetCatalogueView.moreClick = { [weak self] in
            guard let self = self else { return }
            guard let callback = viewContainerData.callback else {
                DocsLogger.btError("[ViewCataloguePlugin] callback is nil")
                return
            }
            guard let moreAction = viewContainerData.moreAction else {
                DocsLogger.btError("[ViewCataloguePlugin] moreAction is nil")
                return
            }
            self.callFunction(DocsJSCallBack(callback),
                                   params: ["action": moreAction],
                                   completion: nil)
        }
        baseInSheetCatalogueView.viewCatalogSelect = { [weak self, weak baseInSheetCatalogueView] index in
            guard let self = self, let baseInSheetCatalogueView = baseInSheetCatalogueView else {
                DocsLogger.btError("[ViewCataloguePlugin] self & baseInSheetCatalogueView is nil")
                return
            }
            guard index >= 0, index < viewContainerData.viewList?.count ?? 0 else {
                DocsLogger.btError("[ViewCataloguePlugin] index is invalid")
                return
            }
            guard let currentViewId = viewContainerData.viewList?.safe(index: index)?.id else {
                DocsLogger.btError("[ViewCataloguePlugin] get  currentViewId fail")
                return
            }
            if let callback = viewContainerData.callback,
               let model = viewContainerData.viewList?.safe(index: index),
               let id = model.id,
               let clickAction = model.clickAction {
                self.callFunction(DocsJSCallBack(callback),
                                  params: ["id": id,
                                           "action": clickAction
                                          ],
                                  completion: nil)
            } else {
                DocsLogger.btError("[ViewCataloguePlugin] click empty callback or can not find model")
            }
            
            if UserScopeNoChangeFG.YY.bitableRedesignFormViewFixDisable || viewContainerData.currentViewType != .form {
                var viewContainerData = viewContainerData
                viewContainerData.currentViewId = currentViewId
                baseInSheetCatalogueView.updateCurrentViewData(currentViewData: viewContainerData)
            }
        }
        displayConfig.setCatalogueBanner(visible: true)
        updateToolBar(baseInSheetCatalogueView.viewToolBar)
    }

    private var isSheet: Bool {
        get {
            return model?.hostBrowserInfo.docsInfo?.isSheet == true
        }
    }
    
    private func handleSetHeaderContainer(_ paramas: [String: Any]) {
        guard let container = container else {
            DocsLogger.btError("[BTJSService] cant find container")
            return
        }
        let data = BaseHeaderModel.deserialized(with: paramas)
        container.updateHeaderModel(headerModel: data)
    }
    
    private func handleOnWebContentChange(_ params: [String: Any]) {
        guard let isTop = params["isTop"] as? Bool else {
            return
        }
        container?.gesturePlugin?.scrolledToTop(isTop)
    }
}

extension BTContainerJSService: ViewCatalogueService {
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        model?.jsEngine.callFunction(function, params: params, completion: completion)
    }
    
    func shouldPopoverDisplay() -> Bool {
        guard SKDisplay.pad else {
            return false
        }
        guard let ui = ui else {
            DocsLogger.warning("ui is nil")
            return false
        }
        return ui.hostView.isMyWindowRegularSize()
    }
}

extension BTContainerJSService: BaseContextService {
    
}


extension BTContainerJSService {
    
    enum ToolBarEventType {
        case view
        case click(item: BTBottomToolBarItemModel)
        case tipsView(reason: String, type: String)
    }
    
    private struct BaseData: BTEventBaseDataType {
        var baseId: String
        var tableId: String
        var viewId: String
    }
    
    private func baseData() -> BaseData? {
        if let tableId = currentViewContainerData?.tableId,
           let baseId = currentViewContainerData?.baseId,
           let viewId = currentViewContainerData?.currentViewId {
            return BaseData(baseId: baseId, tableId: tableId, viewId: viewId)
        }
        return nil
    }
    // nolint: duplicated_code
    func toolBarTrack(_ evenType: ToolBarEventType) {
        guard let baseData = baseData() else { return }
        var commonParams = BTEventParamsGenerator.createCommonParams(by: model?.hostBrowserInfo.docsInfo,
                                                          baseData: baseData)
        if let type = BTGlobalTableInfo.currentViewInfoForBase(baseData.baseId)?.gridViewLayoutType {
            commonParams[BTTableLayoutSettings.ViewType.trackKey] = type.trackValue
            if UserScopeNoChangeFG.XM.nativeCardViewEnable {
                commonParams.merge(other: CardViewConstant.commonParams)
            }
        } else {
            commonParams[BTTableLayoutSettings.ViewType.trackKey] = BTTableLayoutSettings.ViewType.classic.trackValue
        }
        switch evenType {
        case .view:
            DocsTracker.newLog(enumEvent: .bitableFilterSortBoardView, parameters: commonParams)
        case .click(let item):
            commonParams.updateValue(item.id.lowercased(), forKey: "click")
            commonParams.updateValue(item.trackTarget, forKey: "target")
            commonParams.updateValue(DocsTracker.toString(value: item.hasInvalidCondition), forKey: "is_premium_limited")
            DocsTracker.newLog(enumEvent: .bitableFilterSortBoardClick, parameters: commonParams)
        case let .tipsView(reason, type):
            commonParams.updateValue(reason, forKey: "reason")
            commonParams.updateValue(type, forKey: "limit_type")
            DocsTracker.newLog(enumEvent: .bitableToolbarLimitedTips, parameters: commonParams)
        }
    }
}

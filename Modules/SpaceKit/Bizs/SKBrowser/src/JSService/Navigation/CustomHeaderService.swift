//
//  CustomHeaderService.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/11/5.
//

import Foundation
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignLoading
import UniverseDesignIcon

class CustomHeaderService: BaseJSService {
    
    private weak var cacheView: SKCatalogueBannerView?
    // 存多个带 Key 的 Header 信息
    private var customHeaderData: [String: CustomTopContainerData] = [:]
    // 当前展示的 Header 信息
    private var currentCustomTopContainerData: CustomTopContainerData?
    // 最后一个展示带 Key 的Header 信息的 Key
    private var lastCurrentKey: String?

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension CustomHeaderService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.setCustomHeader]
    }
    
    func handle(params: [String: Any], serviceName: String) {
        guard let displayConfig = ui?.customTCDisplayConfig else {
            DocsLogger.info("当前 CustomTopContainerDisplayConfig 不存在")
            return
        }
        guard let browserVC = navigator?.currentBrowserVC as? BrowserViewController else {
            return
        }
        var customTCData: CustomTopContainerData?
        if UserScopeNoChangeFG.TYP.translateMS {
            // 解析失败什么也不处理
            if !params.isEmpty {
                customTCData = params.mapModel()
                guard customTCData != nil else {
                    DocsLogger.error("params mapModel error")
                    return
                }
            }
            /*
             这里的处理主要通过两个方面：
             1. isDataEmpty 为true认为前端想要隐藏customHeader，那么有四种情况
             - 前端数据不带key，当前展示View也不带key
                - 1. 如果栈中没数据直接隐藏当前header
                - 2. 如果栈中有数据，拿栈中数据出来展示
             - 前端数据不带key，当前展示View带key，直接return
             - 前端数据带key，当前展示View带key，删除栈中前端数据Key的值，如果前端key与展示View key相等，则隐藏当前view
             - 前端数据带key，当前展示View不带key，删除栈中前端数据Key的值，然后什么也不做return
             2. isDataEmpty 为false认为前端想要展示customHeader
             - 展示的逻辑比较简单，如果带key把数据入栈，如果不带key不入栈，然后都展示对应数据的customHeader
             */
            
            // 处理isDataEmpty 为true认为前端想要隐藏customHeader
            // - 前端数据不带key，当前展示View也不带key
            //  - 1. 如果栈中没数据直接隐藏当前header
            if customTCData == nil && customHeaderData.isEmpty {
                DocsLogger.info("CustomHeaderService: hide")
                if let view = ui?.customTCDisplayConfig?.getCustomCenterView(), view.isKind(of: RestoreHistoryView.self) {
                    self.ui?.displayConfig.isHistoryPanelShow = false
                }
                displayConfig.setCustomTopContainer(isShow: false)
                currentCustomTopContainerData = nil
                return
            }
            // 1. 处理isDataEmpty 为true认为前端想要隐藏customHeader
            // - 前端数据不带key，当前展示View也不带key
            //  - 1. 如果栈中有数据，拿栈中数据出来展示
            // 2. 前端数据不带key，当前展示View带key，直接return
            if isDataEmpty(customTCData), isKeyEmpty(customTCData) {
                if let currentCustomTopContainerData = currentCustomTopContainerData, currentCustomTopContainerData.key != nil {
                    return
                } else {
                    guard !customHeaderData.isEmpty else { return }
                    guard let lastCurrentKey = lastCurrentKey else { return }
                    customTCData = customHeaderData[lastCurrentKey]
                }
            }
            
            //1. 前端数据带key，当前展示View带key，删除栈中前端数据Key的值，如果前端key与展示Viewkey相等，则隐藏当前view
            // 2. 前端数据带key，当前展示View不带key，删除栈中前端数据Key的值，然后什么也不做return
            if isDataEmpty(customTCData) && !isKeyEmpty(customTCData) {
                guard let key = customTCData?.key else { return }
                customHeaderData.removeValue(forKey: key)
                if let currentTopContainerData = currentCustomTopContainerData, let currentKey = currentTopContainerData.key , currentKey == customTCData?.key {
                    DocsLogger.info("CustomHeaderService: hide")
                    if let view = ui?.customTCDisplayConfig?.getCustomCenterView(), view.isKind(of: RestoreHistoryView.self) {
                        self.ui?.displayConfig.isHistoryPanelShow = false
                    }
                    displayConfig.setCustomTopContainer(isShow: false)
                    currentCustomTopContainerData = nil
                    return
                } else {
                    return
                }
            }
            
            // isDataEmpty 为false认为前端想要展示customHeader
            // 有key需要把数据入栈，如果栈中有key对应的数据则更新栈
            if !isKeyEmpty(customTCData) && !isDataEmpty(customTCData){
                guard let key = customTCData?.key else { return }
                if customHeaderData.contains(where: { $0.key == key }) {
                    customHeaderData[key] = customTCData
                } else {
                    customHeaderData[key] = customTCData
                }
            }
            
        } else {
            // 原逻辑
            guard !params.isEmpty else {
                DocsLogger.info("CustomHeaderService: hide")
                if let view = ui?.customTCDisplayConfig?.getCustomCenterView(), view.isKind(of: RestoreHistoryView.self) {
                    self.ui?.displayConfig.isHistoryPanelShow = false
                }
                displayConfig.setCustomTopContainer(isShow: false)
                return
            }
            guard let customData: CustomTopContainerData = params.mapModel() else {
                DocsLogger.error("decode customTopContainerData failed=\(params)")
                return
            }
            customTCData = customData
        }
        guard let customTCData = customTCData else { return }
        // 保存展示的数据
        currentCustomTopContainerData = customTCData
        if let key = customTCData.key {
            lastCurrentKey = key
        }
        DocsLogger.info("CustomHeaderService: try show: \(params)")
        displayConfig.setCustomTopContainer(isShow: true)
        if !UserScopeNoChangeFG.ZJ.btCustomTopContainerPopgestureFixDisable {
            displayConfig.setPreNaviPopGestureDelegate(naviPopGestureDelegate: browserVC.naviPopGestureDelegate)
        }
        configureHeader(customTCData)

        if browserVC.spaceFollowAPIDelegate?.followRole == .follower {
            browserVC.customTCMangerForceTopContainer(state: .fixedHiding)
            displayConfig.setCustomTopContainerHidden(true)
        } else if let hideCustomHeaderInLandscape = customTCData.hideCustomHeaderInLandscape, UIApplication.shared.statusBarOrientation.isLandscape {
            // 如果前端有显式设置hideCustomHeaderInLandscape，则优先使用
            displayConfig.setCustomTopContainerHidden(hideCustomHeaderInLandscape)
        } else if hostDocsInfo?.isSheet == true,
                  UIApplication.shared.statusBarOrientation.isLandscape,
                  SKDisplay.phone {
            displayConfig.setCustomTopContainerHidden(true)
        } else {
            displayConfig.setCustomTopContainerHidden(false)
        }
    }

    private func configureHeader(_  customTCData: CustomTopContainerData) {
        DocsLogger.info("begin to configure custom topContainer")
        handleExtraPartWithCustomData(customTCData)
        handleTitlePartWithCustomData(customTCData.titleConfig, bitableCatalog: customTCData.bitableCatalog, callback: customTCData.callback)
        handleSidesWithCustomData(customTCData.sidesMenuConfig, callback: customTCData.callback)
        handleHistoryPartWithCustomData(customTCData)
    }
    
    private func isDataEmpty(_ data: CustomTopContainerData?) -> Bool {
        guard let data = data else { return true }
        return (data.shouldShowDivider == nil && data.titleConfig == nil && data.themeColor == nil && data.sidesMenuConfig == nil)
    }
    
    private func isKeyEmpty(_ data: CustomTopContainerData?) -> Bool {
        guard let data = data else { return true }
        return (data.key == nil)
    }
}

// MARK: configuration title part
extension CustomHeaderService {
    private func handleTitlePartWithCustomData(_ data: TitleConfig?, bitableCatalog: SKBitableCatalogData?, callback: String?) {
        guard let data = data else { return }
        var titleInfo = NavigationTitleInfo(title: data.title)
        titleInfo.displayType = data.isLoading ? .customized : .title
        if data.isLoading {
            let indicatorConfig: UDSpinIndicatorConfig = UDSpinIndicatorConfig(size: 20, color: UIColor.ud.colorfulBlue)

            let indicatorSpin = UDLoading.spin(config: UDSpinConfig(indicatorConfig: indicatorConfig, textLabelConfig: nil))
            indicatorSpin.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
            titleInfo.customView = indicatorSpin
            var layoutAttributes = ui?.customTCDisplayConfig?.layoutAttributes
            layoutAttributes?.titleTextColor = UIColor.ud.colorfulBlue
            ui?.customTCDisplayConfig?.layoutAttributes = layoutAttributes
        } else if let bitableCatalogData = bitableCatalog {
            DocsLogger.info("setbitableCatalog.tableId:\(bitableCatalogData.tableId),viewId:\(bitableCatalogData.viewId)")
            let view: SKCatalogueBannerView
            if let cacheView = cacheView {
                if cacheView.superview != nil {
                    cacheView.removeFromSuperview()
                }
                view = cacheView
            } else {
                view = SKCatalogueBannerView()
                cacheView = view
            }
            view.leftPaddingWidth = 6
            view.customFont = UIFont.systemFont(ofSize: 16, weight: .medium)
            
            var catalogueData = SKCatalogueBannerData()
            catalogueData.secondLevelLabelText = bitableCatalogData.viewName
            catalogueData.secondLevelIcon = bitableCatalogData.viewTypeImage
            catalogueData.secondLevelIconUrl = bitableCatalogData.iconUrl
            
            view.setCatalogueBanner(catalogueBannerData: catalogueData) { [weak self] _ in
                DocsLogger.info("CatalogueBanner callback.tableId:\(bitableCatalogData.tableId),viewId:\(bitableCatalogData.viewId)")
                guard let self = self else {
                    DocsLogger.warning("self released")
                    return
                }
                guard let callback = callback else {
                    DocsLogger.info("callback is nil")
                    return
                }
                guard let jsEngine = self.model?.jsEngine else {
                    DocsLogger.warning("model or jsEngine is nil")
                    return
                }
                jsEngine.callFunction(DocsJSCallBack(callback), params: ["id": "catalog"], completion: nil)
            }
            titleInfo.title = nil
            titleInfo.customView = view
            titleInfo.displayType = .fullCustomized
        } else if data.titleIcon != nil {
            // 翻译状态下 customHeader 中间的 View 是自定义,可配置相应的数据进行展示
            let view = SKCenterViewButton()
            var centerViewData = SKCenterViewData()
            
            centerViewData.title = data.title
            centerViewData.clickable = data.clickable
            centerViewData.id = data.id
            centerViewData.titleIcon = data.titleIcon
            centerViewData.showFoldBtn = data.showFoldBtn
            
            view.setSelectLanBtn(centerViewData) { [weak self] data in
                DocsLogger.info("CatalogueBanner callback.tableId:\(data.id)")
                guard let self = self else {
                    DocsLogger.warning("self released")
                    return
                }
                guard let callback = callback else {
                    DocsLogger.info("callback is nil")
                    return
                }
                guard let jsEngine = self.model?.jsEngine else {
                    DocsLogger.warning("model or jsEngine is nil")
                    return
                }
                jsEngine.callFunction(DocsJSCallBack(callback), params: ["id": data.id], completion: nil)
            }
            titleInfo.title = nil
            titleInfo.customView = view
            titleInfo.displayType = .fullCustomized
        }
        DocsLogger.info("setCustomTCTitleInfo:\(titleInfo.displayType.rawValue)")
        ui?.customTCDisplayConfig?.setCustomTCTitleInfo(titleInfo)
        let titleHorizontalAlignment: UIControl.ContentHorizontalAlignment = (data.position == "center") ? .center : .leading
        ui?.customTCDisplayConfig?.setCustomTCTitleHorizontalAlignment(titleHorizontalAlignment)
    }
    
    func handleHideCustomHeader(customTCData: CustomTopContainerData?, customTCDisplayConfig: CustomTopContainerDisplayConfig) {
        
    }
}

// MARK: configuration both sides barButton
extension CustomHeaderService {
    private func handleSidesWithCustomData(_ data: SidesMenuConfig?, callback: String?) {
        //左右Button没有数据时需要刷新去掉原有数据
        guard let data = data, let callback = callback else { return }
        if let leftMenuConfigs = data.leftMenuConfigs, leftMenuConfigs.count > 0 {
            ui?.customTCDisplayConfig?.leftBarButtonItems = barButtonItems(target: self, menuConfigs: leftMenuConfigs, callback: callback)
        } else {
            ui?.customTCDisplayConfig?.leftBarButtonItems = []
        }
        if let rightMenuConfigs = data.rightMenuConfigs, rightMenuConfigs.count > 0 {
            ui?.customTCDisplayConfig?.rightBarButtonItems = barButtonItems(target: self, menuConfigs: rightMenuConfigs.reversed(), callback: callback)
        } else {
            ui?.customTCDisplayConfig?.rightBarButtonItems = []
        }
    }

    private func barButtonItems(target: AnyObject, menuConfigs: [MenuConfig], callback: String) -> [SKBarButtonItem] {
        let targetClasses: [AnyClass] = [type(of: self)]
        let editorIdentity = model?.jsEngine.editorIdentity ?? "webidUnknown"
        var items = [SKBarButtonItem]()
        DocsLogger.info("start build custom barButtonItems for \(editorIdentity), target \(menuConfigs.count)")
        for config in menuConfigs {
            let id = config.id
            let extraid = config.extraId
            let aSelector = selector(uid: "docs_js_barbutton_command_\(ObjectIdentifier(target))_" + id, classes: targetClasses) { [weak self] in
                if let extraStr = extraid, self?._skNaviBarButtonExtraID(for: extraStr) == .historyExit {
                    self?.ui?.displayConfig.isHistoryPanelShow = false
                    let browserVC = self?.navigator?.currentBrowserVC as? BaseViewController
                    browserVC?.refreshLeftBarButtons()
                }
                self?.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["id": id], completion: nil)
            }
            if let text = config.text {
                let item = SKBarButtonItem(title: text, style: .plain, target: target, action: aSelector)
                item.id = getNaviBarID(for: id)
                item.isEnabled = config.enable ?? true
                if let customColorMapping = translateColorMapping(config.customColor?.map { UIColor.docs.rgb($0) }) {
                    item.foregroundColorMapping = customColorMapping
                } else {
                    item.foregroundColorMapping = SKBarButton.primaryColorMapping
                }
                items.append(item)
                DocsLogger.info("build custom barButtonItem for \(id), got text")
            } else if let iconID = getIconID(for: id) {
                let item = SKBarButtonItem(image: UDIcon.getIconByKey(iconID), style: .plain, target: target, action: aSelector)
                item.id = getNaviBarID(for: id)
                item.isEnabled = config.enable ?? true
                if let customColorMapping = translateColorMapping(config.customColor?.map { UIColor.docs.rgb($0) }) {
                    item.foregroundColorMapping = customColorMapping
                } else {
                    item.foregroundColorMapping = SKBarButton.defaultIconColorMapping
                }
                items.append(item)
                DocsLogger.info("build custom barButtonItem for \(id), got image")
            }
        }
        return items
    }
}

// MARK: configuration extra part
extension CustomHeaderService {
    private func handleExtraPartWithCustomData(_ data: CustomTopContainerData) {
        // set detail color
        if let themeColor = data.themeColor {
            ui?.customTCDisplayConfig?.setCustomTCThemeColor(themeColor)
        }
        // set divider
        if let shouldShowDivider = data.shouldShowDivider {
            ui?.customTCDisplayConfig?.shouldShowDivider(shouldShowDivider)
        }
        if let callback = data.callback {
            // set interactive pop gesture action
            ui?.customTCDisplayConfig?.setCustomTCInteractivePopGestureAction { [weak self] in
                self?.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["id": "exit"], completion: nil)
            }
        }
        ui?.customTCDisplayConfig?.hideCustomHeaderInLandscape = data.hideCustomHeaderInLandscape
    }
}

// MARK: configuration history part
extension CustomHeaderService {
    private func handleHistoryPartWithCustomData(_ data: CustomTopContainerData) {
        if let historySceneLogic = data.historySceneLogic, historySceneLogic.shouldShow {
            let historyTopCRightView = HistoryTopCRightView(frame: .zero)
            ui?.customTCDisplayConfig?.setCustomRightView(historyTopCRightView)
            let restoreHistoryView = RestoreHistoryView(frame: .zero, restoreEnable: historySceneLogic.restoreEnable, title: historySceneLogic.text) { [weak self] in
                let callBackId: String = historySceneLogic.id ?? "DOCX_RESTORE_HISTORY"
                if let callback = data.callback {
                    self?.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["id": callBackId], completion: nil)
                }
            }
            ui?.customTCDisplayConfig?.setCustomCenterView(restoreHistoryView)
        } else {
            ui?.customTCDisplayConfig?.setCustomRightView(nil)
            ui?.customTCDisplayConfig?.setCustomCenterView(nil)
        }
    }
}

// MARK: Mapping
extension CustomHeaderService {

    private func getIconID(for id: String) -> UDIconType? {
        return _iconNameMapping[id.lowercased()]
    }
    
    private func getNaviBarID(for id: String) -> SKNavigationBar.ButtonIdentifier {
        return _skNaviBarButtonID(for: id.lowercased())
    }

    // Get the icon Name from the icon id map
    private var _iconNameMapping: [String: UDIconType] {
        return [
            "appeal_exit": .leftOutlined,
            "doc_embedded_mindnote_exit": .leftOutlined,
            "smartable_fullscreen_exit": .windowMiniOutlined,
            "smartable_fullscreen_undo": .undoOutlined,
            "smartable_fullscreen_redo": .redoOutlined,
            "smartable_fullscreen_more": .moreOutlined,
            "comment": .addCommentOutlined,
            "search": .findAndReplaceOutlined,
            "close": .closeOutlined
        ]
    }

    private func _skNaviBarButtonID(for str: String) -> SKNavigationBar.ButtonIdentifier {
        return [
            "appeal_exit": .appealExit,
            "doc_embedded_mindnote_exit": .back,
            "smartable_fullscreen_exit": .fullScreenMode,
            "smartable_fullscreen_undo": .undo,
            "smartable_fullscreen_redo": .redo,
            "smartable_fullscreen_more": .more,
            "comment": .comment,
            "search": .findAndReplace,
            "close": .close
        ][str] ?? .unknown(str)
    }
    
    private func _skNaviBarButtonExtraID(for str: String) -> SKNavigationBar.ButtonExtraIdentifier {
        return ["docx_embedded_history_exit": .historyExit][str] ?? .unknown(str)
    }

    private func translateColorMapping(_ colors: [UIColor]?) -> [UIControl.State: UIColor]? {
        guard let colors = colors, colors.count == 4 else {
            DocsLogger.info("前端没有传正确的 bar button item 的 customColor 过来")
            return nil
        }
        return [
            .normal: colors[0],
            .highlighted: colors[1],
            .disabled: colors[2],
            .selected: colors[3],
            [.selected, .highlighted]: colors[1]
        ]
    }
}

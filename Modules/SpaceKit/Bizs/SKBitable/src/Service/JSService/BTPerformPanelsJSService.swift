//
//  BTPerformPanelsJSService.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/21.
//


// 筛选和排序技术方法：https://bytedance.feishu.cn/wiki/wikcnHjEgZPoi19OtXeQbr3XYRb

import SKFoundation
import SKCommon
import SKBrowser
import SwiftyJSON

// 筛选、排序、视图组合面板的tab
enum FilterSortViewSettingTab: String {
  case filter = "filter"
  case sort = "sort"
  case viewSetting = "view_setting"
}

enum CompositeType {
    case onlyFilter // 仅仅显示筛选
    case filterAndSort // 显示筛选和排序
    case all // 显示所有（筛选、排序、视图配置）
}

/// 前端通知客户端的动作
enum PerformPanelsAction: String {
    case ShowFilterPanel
    case CloseFilterPanel
    case ShowSortPanel
    case CloseSortPanel
    case TableModelChanged // 表数据变更
    case FilterInfoChanged // 筛选
    case SortInfoChanged //排序
    case ShowLayoutPanel // 显示布局面板
    case CloseLayoutPanel // 关闭布局面板
    case LayoutInfoChanged // 布局配置变更（协同）
    case ShowComposite // 显示聚合后的设置面板
    case CloseComposite // 关闭聚合后的设置面板
    case UpdateTitleButton // 临时配置按钮信息
}

extension BTJSService {
    func handlePreformPanelsAction(_ params: [String: Any]) {
        guard let jsService = self.model?.jsEngine,
              let hostVC = self.registeredVC else {
            return
        }
        
        let paramsJSON = JSON(params)
        guard let baseId = paramsJSON["baseId"].string,
              let tableId = paramsJSON["tableId"].string,
              let viewId = paramsJSON["viewId"].string,
              let actionValue = paramsJSON["action"].string,
              let callback = paramsJSON["callback"].string else {
            DocsLogger.btError("handlePreformPanelsAction params wrong \(params)")
            return
        }
        guard let action = PerformPanelsAction(rawValue: actionValue) else {
            DocsLogger.btError("handlePreformPanelsAction action value wrong \(actionValue)")
            return
        }
        let baseData = BTBaseData(baseId: baseId,
                                  tableId: tableId,
                                  viewId: viewId)
        let permissionObj = BasePermissionObj.parse(params)
        switch action {
        case .ShowFilterPanel:
            let baseContext = BaseContextImpl(baseToken: baseId,
                                              service: self,
                                              permissionObj: permissionObj,
                                              from: "showFilterPanel")
            filterPanelManager = BTFilterPanelManager(baseData: baseData,
                                                      jsService: jsService,
                                                      baseContext: baseContext,
                                                      dataService: self,
                                                      callback: callback)
            filterPanelManager?.hostDocsInfo = model?.hostBrowserInfo.docsInfo
            filterPanelManager?.showFilterPanelIfCan(from: hostVC)
        case .FilterInfoChanged:
            viewActionManager?.updateActionPanel(with: .filter)
        case .CloseFilterPanel:
            filterPanelManager?.closeFilterPanel()
            filterPanelManager = nil
        case .ShowSortPanel:
            let baseContext = BaseContextImpl(baseToken: baseId,
                                              service: self,
                                              permissionObj: permissionObj,
                                              from: "showSortPanel")
            sortPanelManager = BTSortPanelManager(baseData: baseData,
                                                  jsService: jsService,
                                                  baseContext: baseContext,
                                                  callback: callback)
            sortPanelManager?.hostDocsInfo = model?.hostBrowserInfo.docsInfo
            sortPanelManager?.showSortPanelIfCan(from: hostVC)
        case .SortInfoChanged:
            viewActionManager?.updateActionPanel(with: .sort)
        case .CloseSortPanel:
            sortPanelManager?.closeSortPanel()
            sortPanelManager = nil
        case .TableModelChanged:
            viewActionManager?.updateActionPanel(with: .filter)
            viewActionManager?.updateActionPanel(with: .sort)
        case .ShowLayoutPanel:
            handleTableLayoutSettingsShow(params)
        case .CloseLayoutPanel:
            handleTableLayoutSettingsClose(params)
        case .LayoutInfoChanged:
            viewActionManager?.updateActionPanel(with: .viewSetting, params: params)
        case .ShowComposite:
            let current = params["currTab"] as? String ?? ""
            let currentTab = FilterSortViewSettingTab(rawValue: current) ?? .filter
            let tabs = params["tabs"] as? [String] ?? []
            var compositeType = CompositeType.filterAndSort
            switch tabs.count {
            case 1:
                compositeType = .onlyFilter
            case 2:
                compositeType = .filterAndSort
            case 3:
                compositeType = .all
            default:
                compositeType = .filterAndSort
                DocsLogger.btError("handlePreformPanelsAction action invalid tabs \(tabs), will use default filterAndSort")
            }
            let baseContext = BaseContextImpl(baseToken: baseId,
                                              service: self,
                                              permissionObj: permissionObj,
                                              from: "showFilterSortViewSetting")
            showActionPanenl(with: currentTab,
                             compositeType: compositeType,
                             baseData: baseData,
                             permissionObj: permissionObj,
                             baseContext: baseContext,
                             jsService: jsService,
                             callback: callback,
                             hostVC: hostVC,
                             params: params)
        case .CloseComposite:
            viewActionManager?.closeActionPanel()
            viewActionManager = nil
        case .UpdateTitleButton:
            if let button = params["button"] as? [String: Any],
               let model = try? CodableUtility.decode(BTViewActionSyncButtonModel.self, withJSONObject: button) {
                viewActionManager?.updateSyncButton(model: model) { [weak self] in
                    guard let uiModel = self?.model else {
                        DocsLogger.error("[handlePreformPanelsAction] UpdateTitleButton model config is nil")
                        return
                    }
                    uiModel.jsEngine.callFunction(DocsJSCallBack(callback),
                                                      params: ["action": model.btnAction],
                                                      completion: nil)
                }
            } else {
                DocsLogger.btError("[handlePreformPanelsAction] UpdateTitleButton button data is invalid")
            }
        }
    }
    
    private func showActionPanenl(with current: FilterSortViewSettingTab,
                                  compositeType: CompositeType,
                                  baseData: BTBaseData,
                                  permissionObj: BasePermissionObj?,
                                  baseContext: BaseContext,
                                  jsService: BrowserJSEngine,
                                  callback: String,
                                  hostVC: UIViewController,
                                  params: [String: Any]) {
        viewActionManager = BTViewActionManager(with: compositeType,
                                                baseData: baseData,
                                                jsService: jsService,
                                                baseContext: baseContext,
                                                dataService: self,
                                                params: params,
                                                callback: callback)
        viewActionManager?.showActionPanel(with: current, hostVC: hostVC)
        viewActionManager?.viewActionController?.delegate = self
    }
}

extension BTJSService: BTViewActionControllerDelegate {
    func sortView() {
        let mdoel = BTBottomToolBarItemModel(id: "Sort")
        bottomToolBarTrack(.click(item: mdoel), baseData: viewActionManager?.baseData)
    }
    
    func filterView() {
        let mdoel = BTBottomToolBarItemModel(id: "Filter")
        bottomToolBarTrack(.click(item: mdoel), baseData: viewActionManager?.baseData)
    }
    
    func layoutView() {
        let mdoel = BTBottomToolBarItemModel(id: "Layout")
        bottomToolBarTrack(.click(item: mdoel), baseData: viewActionManager?.baseData)
    }
}

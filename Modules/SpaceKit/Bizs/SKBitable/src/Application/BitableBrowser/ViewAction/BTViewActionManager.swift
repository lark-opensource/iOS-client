//
//  BTViewActionManager.swift
//  SKBitable
//
//  Created by X-MAN on 2023/8/28.
//

import Foundation
import SKCommon
import SKFoundation
import UniverseDesignToast
import SKResource

final class BTViewActionManager {
    
    private(set) var viewActionController: BTViewActionController?
    private var context: BaseContext
    private var filterManager: BTFilterPanelManager
    private var sortManager: BTSortPanelManager?
    private var layoutManager: BTTableLayoutManager?
    private var compositeType: CompositeType = .filterAndSort
    private(set) var baseData: BTBaseData?
    
    init(with compositeType: CompositeType,
         baseData: BTBaseData,
         jsService: SKExecJSFuncService,
         baseContext: BaseContext,
         dataService: BTDataService?,
         params: [String: Any],
         callback: String) {
        self.compositeType = compositeType
        self.filterManager = BTFilterPanelManager(baseData: baseData,
                                                  jsService: jsService,
                                                  baseContext: baseContext,
                                                  dataService: dataService,
                                                  callback: callback)
        switch compositeType {
            case .all:
            self.sortManager = BTSortPanelManager(baseData: baseData,
                                                  jsService: jsService,
                                                  baseContext: baseContext,
                                                  callback: callback)
            if let settingsDict = params["payload"] as? [String: Any] {
                // 如果有payload，那么表示是 卡片视图 layout
                do {
                    let context = try CodableUtility.decode(BTTableLayoutSettingContext.self, withJSONObject: params)
                    let settings = try CodableUtility.decode(BTTableLayoutSettings.self, withJSONObject: settingsDict)
                    layoutManager = BTTableLayoutManager(context: context,
                                                         settings: settings,
                                                         service: dataService as? BTJSService)
                } catch {
                    DocsLogger.btError("[BTViewActionManager] viewSetting param decode failed with error: \(error)")
                    self.compositeType = .filterAndSort
                }
            } else {
                DocsLogger.warning("[BTViewActionManager] viewSetting payload is missing, does not display layoutTab")
                self.compositeType = .filterAndSort
            }
        case .onlyFilter:
            break
        case .filterAndSort:
            self.sortManager = BTSortPanelManager(baseData: baseData,
                                                  jsService: jsService,
                                                  baseContext: baseContext,
                                                  callback: callback)
        }
        
        self.context = baseContext
        self.sortManager?.sortApplyClick = { [weak self] in
            if let view = self?.viewActionController?.view {
                let text = BundleI18n.SKResource.Bitable_Mobile_Applied_Toast
                UDToast.showTips(with: text, on: view)
            }
        }
        self.filterManager.hostDocsInfo = context.hostDocsInfo
        self.baseData = baseData
    }
    
    func showActionPanel(with current: FilterSortViewSettingTab, hostVC: UIViewController) {
        if let vc = viewActionController {
            vc.updateRegular(BTNavigator.isReularSize(hostVC))
            BTNavigator.presentDraggableVCEmbedInNav(vc, from: hostVC)
        } else {
            let filterController = filterManager.getFilterController()
            let sortController = sortManager?.getSortController()
            let layoutController = layoutManager?.getSettingController()
            var index = 0
            switch current {
            case .filter:
                index = 0
            case .sort:
                index = 1
            case .viewSetting:
                index = layoutController != nil ? 2 : 0
            }
            let vc = BTViewActionController(with: self.compositeType,
                                            filterController: filterController,
                                            sortController: sortController,
                                            layoutController: layoutController,
                                            selectedIndex: index)
            vc.updateRegular(BTNavigator.isReularSize(hostVC))
            self.viewActionController = vc
            BTNavigator.presentDraggableVCEmbedInNav(vc, from: hostVC)
        }
    }
    
    func updateActionPanel(with type: FilterSortViewSettingTab, params: [String: Any] = [:]) {
        // controller 不在屏幕上的时候不更新，出现的时候总会去拿数据的
        if self.viewActionController?.view.window == nil { return }
        switch type {
        case .filter:
            filterManager.updateFilterPanelIfNeedV2()
        case .sort:
            sortManager?.updateSortPanelIfNeedV2()
        case .viewSetting:
            handleTableLayoutSettingsUpdate(params)
        }
    }
    
    func updateSyncButton(model: BTViewActionSyncButtonModel, syncClick: (() -> Void)?) {
        viewActionController?.updateSync(with: model)
        viewActionController?.syncClick = {
            syncClick?()
        }
    }
    
    func closeActionPanel() {
        viewActionController?.dismiss(animated: true)
    }
    
    private func handleTableLayoutSettingsUpdate(_ params: [String: Any]) {
        guard let settingsDict = params["payload"] as? [String: Any] else {
            DocsLogger.btError("[BTViewActionManager] update Layout payload is missing!")
            return
        }
        let mgr = layoutManager
        do {
            let context = try CodableUtility.decode(BTTableLayoutSettingContext.self, withJSONObject: params)
            guard mgr?.context.isSameViewContext(with: context) ?? false else {
                DocsLogger.btError("[BTViewActionManager] update Layout settings context not match")
                return
            }

            let settings = try CodableUtility.decode(BTTableLayoutSettings.self, withJSONObject: settingsDict)
            mgr?.updateSettingsV2(settings)
        } catch {
            DocsLogger.btError("[BTViewActionManager] update Layout param decode failed")
        }
    }
    
}

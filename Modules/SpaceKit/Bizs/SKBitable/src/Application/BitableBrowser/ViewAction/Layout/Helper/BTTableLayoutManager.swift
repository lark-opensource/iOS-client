//
//  BTTableLayoutManager.swift
//  SKBitable
//
//  Created by zhysan on 2023/1/30.
//

import SKFoundation
import SKUIKit
import LarkNavigator
import LarkUIKit
import EENavigator
import SKCommon

private enum BTTableLayoutManagerError: Error {
    case unknown(_ msg: String)
}

let BTTableLayoutLogTag = "==BTVL=="

final class BTTableLayoutManager {
    // MARK: - public
    
    private(set) var context: BTTableLayoutSettingContext
    
    /// 初始化时候的 settings
    private(set) var initialSettings: BTTableLayoutSettings
    
    /// 根据面板配置实时变化生成的 settings
    private(set) var settings: BTTableLayoutSettings
    
    private(set) weak var service: BTJSService?
    
    func getSettingController() -> BTTableLayoutSettingViewControllerV2 {
        if let vc = self.settingsVCV2 {
            return vc
        } else {
            let vc = BTTableLayoutSettingViewControllerV2(settings: self.settings, fields: [], delegate: self)
            self.settingsVCV2 = vc
            vc.delegate = self
            return vc
        }
    }
    
    func getTableLayoutSetting(completion: @escaping (BTTableLayoutSettings) -> Void) {
        service?.asyncJsRequest(biz: .toolBar,
                                funcName: .asyncJsRequest,
                                baseId: context.baseId,
                                tableId: context.tableId,
                                params: ["router": BTAsyncRequestRouter.getTableLayoutSetting.rawValue],
                                overTimeInterval: 5.0,
                                responseHandler: { result in
                                    switch result {
                                    case let .success(response):
                                        if response.result == 0,
                                           let setting = try? CodableUtility.decode(BTTableLayoutSettings.self, withJSONObject: response.data) {
                                            self.settings = setting
                                        } else {
                                            DocsLogger.btInfo("GetTableLayoutSetting result: error")
                                        }
                                        completion(self.settings)
                                    case let .failure(error):
                                        DocsLogger.btInfo("GetTableLayoutSetting result: \(error)")
                                        completion(self.settings)
                                    }
                                },
                                resultHandler: { result in
                                    DocsLogger.btInfo("GetTableLayoutSetting result: \(result)")
                                })
    }
    
    func showSettingsPanel() {
        DocsLogger.info("showSettingsPanel invoke", component: BTTableLayoutLogTag)
        guard let from = service?.registeredVC else {
            DocsLogger.error("register vc is nil", component: BTTableLayoutLogTag)
            return
        }
        
        getFieldList { [weak self] result in
            guard let self = self else {
                DocsLogger.error("nil self", component: BTTableLayoutLogTag)
                return
            }
            switch result {
            case .success(let data):
                DocsLogger.info("showSettingsPanel success", component: BTTableLayoutLogTag)
                let vc = BTTableLayoutSettingViewController(settings: self.settings, fields: data, delegate: self)
                vc.dismissBlock = { [weak self] in self?.handleSettingsVCDismiss() }
                BTNavigator.presentDraggableVCEmbedInNav(vc, from: from)
                
                self.settingsVC = vc
                self.trackSettingsPanelShow()
            case .failure(let error):
                DocsLogger.error("showSettingsPanel failed", error: error, component: BTTableLayoutLogTag)
            }
        }
    }
    
    func closeSettingsPanel() {
        DocsLogger.info("closeSettingsPanel invoke", component: BTTableLayoutLogTag)
        settingsVC?.dismiss(animated: true)
    }
    
    func updateSettings(_ settings: BTTableLayoutSettings) {
        self.settings = settings
        guard let vc = settingsVC else {
            DocsLogger.warning("update layout settings failed, settings vc is not displayed!", component: BTTableLayoutLogTag)
            return
        }
        getFieldList { [weak self] result in
            guard let self = self else {
                DocsLogger.error("nil self", component: BTTableLayoutLogTag)
                return
            }
            switch result {
            case .success(let data):
                DocsLogger.info("update layout settings success", component: BTTableLayoutLogTag)
                vc.updateSettings(self.settings, fields: data)
            case .failure(let error):
                DocsLogger.error("update grid layout settigs failed", error: error, component: BTTableLayoutLogTag)
            }
        }
    }
    
    func updateSettingsV2(_ settings: BTTableLayoutSettings) {
        self.settings = settings
        guard let vc = settingsVCV2 else {
            DocsLogger.warning("update layout settings failed, settings vc is not displayed!", component: BTTableLayoutLogTag)
            return
        }
        getFieldList { [weak self] result in
            guard let self = self else {
                DocsLogger.error("nil self", component: BTTableLayoutLogTag)
                return
            }
            switch result {
            case .success(let data):
                DocsLogger.info("update layout settings success", component: BTTableLayoutLogTag)
                vc.updateSettings(self.settings, fields: data)
            case .failure(let error):
                DocsLogger.error("update grid layout settigs failed", error: error, component: BTTableLayoutLogTag)
            }
        }
    }
    
    // MARK: - life cycle
    init(context: BTTableLayoutSettingContext, settings: BTTableLayoutSettings, service: BTJSService?) {
        self.context = context
        self.settings = settings
        self.initialSettings = settings
        self.service = service
    }
    
    // MARK: - private
    
    private var settingsVC: BTTableLayoutSettingViewController?
    private var settingsVCV2: BTTableLayoutSettingViewControllerV2?

    
    private func getFieldList(_ completion: ((Result<[BTFieldOperatorModel], Error>) -> Void)?) {
        guard let service = service else {
            DispatchQueue.main.async {
                completion?(.failure(BTTableLayoutManagerError.unknown("nil service")))
            }
            return
        }
        let args = BTGetBitableCommonDataArgs(type: .getFieldList, tableID: context.tableId, viewID: context.viewId)
        service.getBitableCommonData(args: args) { (result, error) in
            guard error == nil, let dataAry = result as? [[String: Any]] else {
                var err = error ?? BTTableLayoutManagerError.unknown("get field list failed")
                DispatchQueue.main.async {
                    completion?(.failure(err))
                }
                return
            }
            guard let fields = [BTFieldOperatorModel].deserialize(from: dataAry)?.compactMap({ $0 }) else {
                DispatchQueue.main.async {
                    completion?(.failure(BTTableLayoutManagerError.unknown("model deserialize failed")))
                }
                return
            }
            DispatchQueue.main.async {
                completion?(.success(fields))
            }
        }
    }
    
    private func handleSettingsVCDismiss() {
        guard let vc = settingsVC else { return }
        trackSettingsPanelClose(cardSettings: vc.vm.cardSettings)
        settingsVC = nil
    }
    
    private func handleSettingsVCDismissV2() {
        guard let vc = settingsVCV2 else { return }
        trackSettingsPanelClose(cardSettings: vc.vm.cardSettings)
    }
}

extension BTTableLayoutManager: BTTableLayoutSettingViewControllerDelegate {
    func openCoverChooseVC(data: [BTFieldCommonData]) {
        trackSettingsCoverPanelShow(attachmentFieldNumber: data.count)
    }
    
    func settingsDidChange(_ vc: BTTableLayoutSettingViewController) {
        guard vc == settingsVC else {
            spaceAssertionFailure("vc not match")
            return
        }
        guard let jsRuntime = service?.model?.jsEngine else {
            DocsLogger.error("js runtime is nil", component: BTTableLayoutLogTag)
            return
        }
        do {
            let setting = vc.vm.getCurrentLayoutSettings()
            let stData = try JSONEncoder().encode(setting)
            let stJsonObj = try JSONSerialization.jsonObject(with: stData)
            let params: [String: Any] = [
                "action": "SetLayout",
                "payload": stJsonObj
            ]
            DocsLogger.info("settings change notify invoke, param: \(params)", component: BTTableLayoutLogTag)
            settings = setting
            jsRuntime.callFunction(
                DocsJSCallBack(context.callback),
                params: params,
                completion: nil
            )
        } catch {
            DocsLogger.error("settings update encode failed", error: error, component: BTTableLayoutLogTag)
        }
    }
}

extension BTTableLayoutManager: BTTableLayoutSettingViewControllerDelegateV2 {
    func settingsDidChange(_ vc: BTTableLayoutSettingViewControllerV2) {
        guard vc == settingsVCV2 else {
            spaceAssertionFailure("vc not match")
            return
        }
        guard let jsRuntime = service?.model?.jsEngine else {
            DocsLogger.error("js runtime is nil", component: BTTableLayoutLogTag)
            return
        }
        do {
            let setting = vc.vm.getCurrentLayoutSettings()
            let stData = try JSONEncoder().encode(setting)
            let stJsonObj = try JSONSerialization.jsonObject(with: stData)
            let params: [String: Any] = [
                "action": "SetLayout",
                "payload": stJsonObj
            ]
            DocsLogger.info("settings change notify invoke, param: \(params)", component: BTTableLayoutLogTag)
            settings = setting
            jsRuntime.callFunction(
                DocsJSCallBack(context.callback),
                params: params,
                completion: nil
            )
        } catch {
            DocsLogger.error("settings update encode failed", error: error, component: BTTableLayoutLogTag)
        }
    }
    
    func openCoverChooseVCV2(data: [BTFieldCommonData]) {
        trackSettingsCoverPanelShow(attachmentFieldNumber: data.count)
    }
    func settingControllerWillShow(_ vc: BTTableLayoutSettingViewControllerV2) {
        trackSettingsPanelShow()
        self.getFieldList { [weak self] result in
            guard let self = self else {
                DocsLogger.error("nil self", component: BTTableLayoutLogTag)
                return
            }
            switch result {
            case let .success(data):
                DocsLogger.info("showSettingsPanel success", component: BTTableLayoutLogTag)
                self.settingsVCV2?.updateSettings(self.settings, fields: data)
                self.settingsVCV2?.dismissBlock = { [weak self] in self?.handleSettingsVCDismissV2() }
            case let .failure(error):
                DocsLogger.error("showSettingsPanel failed", error: error, component: BTTableLayoutLogTag)
            }
        }
    }
        
}

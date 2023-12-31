//
//  BTJSService+GridLayout.swift
//  SKBitable
//
//  Created by zhysan on 2023/1/31.
//

import SKFoundation

extension BTJSService {
    
    func handleTableLayoutSettingsShow(_ params: [String: Any]) {
        guard let settingsDict = params["payload"] as? [String: Any] else {
            DocsLogger.error("payload is missing!", component: BTTableLayoutLogTag)
            return
        }
        do {
            let context = try CodableUtility.decode(BTTableLayoutSettingContext.self, withJSONObject: params)

            let settings = try CodableUtility.decode(BTTableLayoutSettings.self, withJSONObject: settingsDict)
            
            tableLayoutManager = BTTableLayoutManager(context: context, settings: settings, service: self)
            tableLayoutManager?.showSettingsPanel()
        } catch {
            DocsLogger.error("param decode failed", error: error)
        }
    }
    
    func handleTableLayoutSettingsClose(_ params: [String: Any]) {
        tableLayoutManager?.closeSettingsPanel()
        tableLayoutManager = nil
    }
    
    func handleTableLayoutSettingsUpdate(_ params: [String: Any]) {
        guard let settingsDict = params["payload"] as? [String: Any] else {
            DocsLogger.error("payload is missing!")
            return
        }
        guard let mgr = tableLayoutManager else {
            DocsLogger.info("grid layout settings pannel is not displayed!")
            return
        }
        do {
            let context = try CodableUtility.decode(BTTableLayoutSettingContext.self, withJSONObject: params)
            guard mgr.context.isSameViewContext(with: context) else {
                DocsLogger.info("settings context not match")
                return
            }

            let settings = try CodableUtility.decode(BTTableLayoutSettings.self, withJSONObject: settingsDict)
            
            mgr.updateSettings(settings)
        } catch {
            DocsLogger.error("param decode failed", error: error)
        }
    }
}

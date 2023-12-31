//
//  PreloadReadyService.swift
//  SpaceKit
//
//  Created by Gill on 2020/2/16.
//

import Foundation
import SKCommon
import SKFoundation
import SKInfra

class PreloadReadyService: BaseJSService { }

extension PreloadReadyService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.notifyPreloadReady]
    }
    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("[ssr][Preload JSModule](\(self.editorIdentity)) Preload Ready", component: LogComponents.fileOpen)
        let types = getPreloadTypes()
        var costTime = 0.0
        if UserScopeNoChangeFG.LJY.enableRenderSSRWhenPreloadHtmlReady {
            if let sessionId = model?.browserInfo.openSessionID,
               let recordInfo = OpenFileRecord.openFilePerformanceDict[sessionId],
               let startOpenTime = recordInfo.startOpenTime {
                costTime = (Date().timeIntervalSince1970 - startOpenTime) * 1000
                OpenFileRecord.updateFileinfo(["wait_preload_html_time": costTime], for: sessionId)
            }
            model?.requestAgent.notifyPreloadHtmlReady(preloadTypes: types)
        }
        
        DocsLogger.info("[Preload JSModule](\(self.editorIdentity)) Preload info: \(types), cost:\(costTime)", component: LogComponents.fileOpen)
        PreloadStatistics.shared.updatePreloadTypes(self.editorIdentity, types: types)
        model?.jsEngine.callFunction(DocsJSCallBack.preloadJsModule,
                                     params: ["type": types],
                                     completion: nil)
        report(types)
    }
    
    private func getPreloadTypes() -> [String] {
        var types: [String] = []
        if let sequeceConfig = SettingConfig.preloadJsmoduleSequeceConfig, !sequeceConfig.isEmpty {
            types = sequeceConfig
        } else if let info = SettingConfig.preloadJsmoduleConfig {
            types = info.compactMap { (key, value) -> String? in
                if value {
                    return key
                } else {
                    return nil
                }
            }
        }
        
        if DocsUserBehaviorManager.isEnable() {
            let shouldPreloadTypes = DocsUserBehaviorManager.shared.getPreloadTypes()
            if let shouldPreloadTypes = shouldPreloadTypes {
                if !shouldPreloadTypes.isEmpty {
                    types = shouldPreloadTypes
                } else if !types.isEmpty {
                    types = [types[0]] //至少预加载一个，否则Web会加载所有
                }
            }
        }
        return types
    }
    
    private func report(_ types: [String]) {
        let params: [String: Any] = ["preload_sequence": types.joined(separator: ","),
                                         "preload_sequence_size": types.count]
        DocsTracker.log(enumEvent: .preLoadTemplate, parameters: params)
        
        if DocsUserBehaviorManager.shared.hasInterruptPreload(types: types) {
            let interruptParams: [String: Any] = ["interrupt_type": "template"]
            DocsTracker.log(enumEvent: .performanceDocForecast, parameters: interruptParams)
        }
    }
}

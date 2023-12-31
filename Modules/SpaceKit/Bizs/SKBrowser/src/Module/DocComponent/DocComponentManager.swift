//
//  DocComponentManager.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/5/31.
//  


import SKFoundation
import SKCommon
import SKInfra

public struct DocComponentSetting {
    public let appId: String
    public let setting: [String: Any]
}

public final class DocComponentManager {
    public static func getSceneConfig(for url: URL) -> DocComponentSetting? {
        let sceneId = url.docs.queryParams?["scene_id"] ?? url.docs.queryParams?["doc_app_id"]
        guard let sceneId = sceneId, !sceneId.isEmpty else {
            return nil
        }
        guard let allConfig = SettingConfig.docComponentConfig else {
            DocsLogger.error("docComponentConfig is empty", component: LogComponents.docComponent)
            return nil
        }
        guard let sceneConfig = allConfig["doc_component_config_\(sceneId)"] as? [String: Any] else {
            DocsLogger.error("\(sceneId) sceneConfig is empty", component: LogComponents.docComponent)
            return nil
        }
        let setting = DocComponentSetting(appId: sceneId, setting: sceneConfig)
        return setting
    }
}

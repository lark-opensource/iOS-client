//
//  CCMUserSettingsNetworkAPI.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/12/7.
//

import Foundation
import RxSwift
import SKFoundation
import SKInfra
import SwiftyJSON
import SpaceInterface

enum CCMUserSettingsNetworkAPI {

    static func getUserProperties() -> Single<CCMUserProperties> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getUserProperties, params: nil)
            .set(method: .GET)
        return request.rxStart().map { json in
            guard let json else {
                throw DocsNetworkError.invalidData
            }
            let data = try json["data"].rawData()
            let decoder = JSONDecoder()
            do {
                let properties = try decoder.decode(CCMUserProperties.self, from: data)
                return properties
            } catch {
                DocsLogger.error("user properties parse failed", error: error)
                spaceAssertionFailure("properties parse failed")
                throw error
            }
        }
    }

    static func updateUserProperties(patch: CCMUserProperties.Patch) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.setUserProperties, params: patch.paramsRepresentation)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart().asCompletable()
    }

    typealias Scene = CCMCommonSettingsScene

    static func getCommonSetting(scenes: Set<Scene>, meta: SpaceMeta?) -> Single<[Scene: Scene.Value]> {
        var querys = scenes.map { scene in
            "scene=\(scene.rawValue)"
        }
        if let meta {
            querys.append("token=\(meta.objToken)")
            querys.append("obj_type=\(meta.objType.rawValue)")
        }
        let path = OpenAPI.APIPath.getCommonSetting + "?\(querys.joined(separator: "&"))"
        let request = DocsRequest<JSON>(path: path,
                                        params: nil)
            .set(method: .GET)
        return request.rxStart().map { json in
            guard let data = json?["data"] else {
                throw DocsNetworkError.invalidData
            }
            var result: [Scene: Scene.Value] = [:]
            scenes.forEach { scene in
                let sceneData = data[scene.rawValue]
                result[scene] = scene.valueParser(sceneData)
            }
            return result
        }
    }

    static func updateCommonSetting(settings: [Scene: Any], meta: SpaceMeta?) -> Single<[Scene: Bool]> {
        let targetSettings = settings.map { k, v in
            return [
                "scene": k.rawValue,
                "setting_value": v
            ] as [String : Any]
        }
        var params: [String : Any] = ["settings": targetSettings]
        if let meta {
            params["token"] = meta.objToken
            params["obj_type"] = meta.objType.rawValue
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.updateCommonSetting, params: params)
            .set(encodeType: .jsonEncodeDefault)
            .set(method: .POST)
        return request.rxStart().map { json in
            guard let data = json?["data"] else {
                throw DocsNetworkError.invalidData
            }
            let failScene = data["fail_scene"].arrayValue.compactMap({ Scene(rawValue: $0.stringValue) })
            var result: [Scene: Bool] = [:]
            settings.forEach { k, _ in
                result[k] = !failScene.contains(k)
            }
            return result
        }
    }
}

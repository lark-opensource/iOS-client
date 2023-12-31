//
//  CCMUserSettings.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/12/7.
//

import Foundation
import LarkCache
import LarkContainer
import SKFoundation
import RxSwift
import RxRelay
import SpaceInterface

public class CCMUserSettings {
    private static let userPropertiesKey = "CCMUserPropertiesKey"
    private static func commonSettingKey(for scene: CCMCommonSettingsScene) -> String {
        "CCMCommonSettingKey_\(scene.rawValue)"
    }

    private let configCache: Cache
    private let userPropertiesRelay = BehaviorRelay<CCMUserProperties?>(value: nil)
    public var userProperties: CCMUserProperties? { userPropertiesRelay.value }
    public var userPropertiesUpdated: Observable<CCMUserProperties> { userPropertiesRelay.compactMap { $0 } }

    init(userResolver: UserResolver) {
        let userID: String
        if let currentUserID = userResolver.docs.user?.info?.userID {
            userID = currentUserID
        } else {
            spaceAssertionFailure("init UserSettings failed to get userID")
            userID = "unknown"
        }
        configCache = CacheService.configCache(for: userID)

        restorePropertiesFromCache()
    }
}

// MARK: - UserProperties
extension CCMUserSettings {

    private func restorePropertiesFromCache() {
        guard let data: Data = configCache.object(forKey: Self.userPropertiesKey) else { return }
        do {
            let decoder = JSONDecoder()
            let properties = try decoder.decode(CCMUserProperties.self, from: data)
            userPropertiesRelay.accept(properties)
        } catch {
            DocsLogger.error("failed to restore user properties from cache", error: error)
            spaceAssertionFailure()
        }
    }

    public func fetchUserProperties() -> Single<CCMUserProperties> {
        CCMUserSettingsNetworkAPI.getUserProperties().do(onSuccess: { [weak self] properties in
            self?.save(userProperties: properties)
        })
    }

    public func updateUserProperties(with patch: CCMUserProperties.Patch) -> Completable {
        CCMUserSettingsNetworkAPI.updateUserProperties(patch: patch).do(onCompleted: { [weak self] in
            self?.onUserPropertiesUpdateComplete(with: patch)
        })
    }

    private func onUserPropertiesUpdateComplete(with patch: CCMUserProperties.Patch) {
        guard var userProperties else { return }
        userProperties.apply(patch: patch)
        save(userProperties: userProperties)
    }

    private func save(userProperties: CCMUserProperties) {
        userPropertiesRelay.accept(userProperties)
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(userProperties)
            configCache.set(object: data, forKey: Self.userPropertiesKey)
        } catch {
            DocsLogger.error("failed to save user properties to cache", error: error)
            spaceAssertionFailure()
        }
    }
}

// MARK: - CommonSetting
extension CCMUserSettings {

    public typealias Scene = CCMCommonSettingsScene
    // 从缓存读 scene 配置
    public subscript(scene: CCMCommonSettingsScene) -> CCMCommonSettingsValue? {
        let cacheKey = Self.commonSettingKey(for: scene)
        guard let data: Data = configCache.object(forKey: cacheKey) else { return nil }
        do {
            let decoder = JSONDecoder()
            let value = try decoder.decode(CCMCommonSettingsValue.self, from: data)
            return value
        } catch {
            DocsLogger.error("failed to restore common setting from cache",
                             extraInfo: ["scene": scene],
                             error: error)
            spaceAssertionFailure()
            return nil
        }
    }

    public func fetchCommonSettings(scenes: Set<Scene>, meta: SpaceMeta?) -> Single<[Scene: Scene.Value]> {
        CCMUserSettingsNetworkAPI.getCommonSetting(scenes: scenes, meta: meta)
            .do(onSuccess: { [weak self] result in
                self?.save(commonSettings: result)
            })
    }

    public func updateCommonSettings(with patch: [Scene: Scene.Value], meta: SpaceMeta?) -> Single<[Scene: Bool]> {
        let params = patch.compactMapValues(\.updateParameterRepresentation)
        return CCMUserSettingsNetworkAPI.updateCommonSetting(settings: params,
                                                             meta: meta)
        .do(onSuccess: { [weak self] result in
            guard let self else { return }
            let updatedPatch = patch.filter { result[$0.key] ?? false }
            // 这里只保存后端确认更新成功的设置项
            self.save(commonSettings: updatedPatch)
        })
    }

    private func save(commonSettings: [Scene: Scene.Value]) {
        let encoder = JSONEncoder()
        commonSettings.forEach { (scene, value) in
            do {
                let data = try encoder.encode(value)
                configCache.set(object: data, forKey: Self.commonSettingKey(for: scene))
            } catch {
                DocsLogger.error("failed to save commonSetting to cache",
                                 extraInfo: ["scene": scene],
                                 error: error)
                spaceAssertionFailure()
            }
        }
    }
}

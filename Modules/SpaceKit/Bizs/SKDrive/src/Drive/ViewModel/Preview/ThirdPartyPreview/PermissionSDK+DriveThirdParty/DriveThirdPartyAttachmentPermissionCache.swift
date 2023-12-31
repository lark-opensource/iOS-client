//
//  DriveThirdPartyAttachmentPermissionCache.swift
//  SKDrive
//
//  Created by peilongfei on 2023/10/16.
//  


import Foundation
import LarkCache
import LarkStorage
import SKFoundation
import SpaceInterface

class DriveThirdPartyAttachmentPermissionCache {

    private let modelKeySubfix = "_drive_permission_model"
    private let cache: LarkCache.Cache

    init(userID: String) {
        let domain = Domain.biz.ccm.child("ccm_drive_permission")
        let cachePath: IsoPath = .in(space: .user(id: userID), domain: domain).build(.document)
        self.cache = CacheManager.shared.cache(
               rootPath: cachePath,
               cleanIdentifier: "Library/DocsSDK/ccm_drive_permission"
        )
        let countLimit: UInt = 200
        cache.memoryCache?.countLimit = countLimit
        cache.diskCache?.countLimit = countLimit
    }

    func set(userPermission: DriveThirdPartyAttachmentPermission, token: String) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(userPermission)
            let key = token + modelKeySubfix
            cache.set(object: data, forKey: key)
        } catch {
            spaceAssertionFailure("failed to save user permission in cache, error: \(error)")
        }
    }

    func userPermission(for token: String) -> DriveThirdPartyAttachmentPermission? {
        let decoder = JSONDecoder()
        let key = token + modelKeySubfix
        guard let data: Data = cache.object(forKey: key) else { return nil }
        do {
            let model = try decoder.decode(DriveThirdPartyAttachmentPermission.self, from: data)
            return model
        } catch {
            spaceAssertionFailure("failed to load user permission from cache, error: \(error)")
            return nil
        }
    }
}

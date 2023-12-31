// 
// Created by duanxiaochen.7 on 2020/6/7.
// Affiliated with SpaceKit.
// 
// Description:

import Foundation
import SwiftyJSON
import HandyJSON
import ThreadSafeDataStructure
import SKFoundation

public extension PermissionManager {

    class PublicPermissionStore {
        /// Public permission metas of files (docs and sheets specifically). Keys are composed by `objToken_userID` in light of switching tenant.
        private var _publicPermissionMetas: SafeDictionary<String, PublicPermissionMeta> = [:] + .semaphore

        /// Returns the public permission meta for the designated augmented token.
        func publicPermissionMeta(for augToken: String) -> PublicPermissionMeta? {
            spaceAssert(augToken.contains("_"), "You have to augment the objToken with the user's UserID to prevent data leakage between tenants!")
            return _publicPermissionMetas[augToken]
        }

        /// Set the public permission meta for the designated augmented token.
        func setPublicPermissionMeta(for augToken: String, to meta: PublicPermissionMeta) {
            spaceAssert(augToken.contains("_"), "You have to augment the objToken with the user's UserID to prevent data leakage between tenants!")
            _publicPermissionMetas[augToken] = meta
        }
        /// Clear stores when exiting a docs/sheets
        func clear() {
            _publicPermissionMetas.removeAll()
        }
    }

    /// Use this methods to update public permission metas instead of using directly `self.publicPermissions[token] = mask`.
    /// - Parameter permissions: `[token: mask]` or `["\(token)_\(uid)": mask]`
    func updatePublicPermissionMetas(_ metas: [String: PublicPermissionMeta]) {
        metas.forEach { token, meta in
            publicPermissionStore.setPublicPermissionMeta(for: augmentedToken(of: token), to: meta)
        }
    }

    /// Find in local store the public permission meta for a designated file
    /// - Parameters:
    ///   - token: file's `objToken`
    ///   - type: file's `DocsType` rawValue
    func getPublicPermissionMeta(token: String) -> PublicPermissionMeta? {
        return publicPermissionStore.publicPermissionMeta(for: augmentedToken(of: token))
    }
}

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
import SKInfra


extension PermissionManager {

    class UserPermissionStore {
        /// A user (not necessarily the current user)'s permission for files (docs and sheets specifically). Keys are composed by `objToken_userID` in light of switching tenant.
        private var _userPermissions: SafeDictionary<String, UserPermissionAbility> = [:] + .semaphore

        /// Returns the user's permission for the designated augmented token.
        func userPermission(for augToken: String) -> UserPermissionAbility? {
            spaceAssert(augToken.contains("_"), "You have to augment the objToken with the user's UserID to prevent data leakage between tenants!")
            return _userPermissions[augToken]
        }

        /// Set the user permission for the designated augmented token.
        func setUserPermission(for augToken: String, to mask: UserPermissionAbility) {
            spaceAssert(augToken.contains("_"), "You have to augment the objToken with the user's UserID to prevent data leakage between tenants!")
            _userPermissions[augToken] = mask
        }

        /// Clear stores when exiting a docs/sheets
        func clear() {
            _userPermissions.removeAll()
        }
    }

    /// Whether the current or designated user is editable for the given file.
    ///
    /// PermissionManager will look up the UserPermissionMask in its local store.
    /// If there's no user permission record in store, PermissionManager will fetch the user permission for you
    /// and return (false, .fetching). You can also pass in a block handling the fetch result.
    ///
    /// - Parameters:
    ///   - token: file's objToken
    ///   - type: file's type value (docs == 2, sheets == 3)
    ///   - userID: The designated userID, optional, if `nil` then PermissionManager will look for current user's editability
    ///   - afterFetching: A block sent to main thread handling the fetch result, optional. Argument: `isEditable`
    /// - Returns: A tuple as (isEditable, requestStatus).
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    public func isUserEditable(for token: String,
                        type: Int,
                        userID: String? = nil,
                        afterFetching: ((Bool) -> Void)? = nil) -> (editable: Bool, status: RequestStatus) {
        let augToken = augmentedToken(of: token, userID: userID)

        guard let permission = userPermissionStore.userPermission(for: augToken) else {
            fetchUserPermissions(token: token, type: type) { (info, error) in
                guard error == nil, info?.code == nil, let mask = info?.mask else { return }
                afterFetching?(mask.canEdit())
            }
            return (false, .fetching)
        }
        return (permission.canEdit(), .fetched)
    }

    /// Use this method to update user permissions instead of using directly `self.userPermissions[token] = mask`.
    /// - Parameter permissions: `[token: mask]` for current user's permission or `["\(token)_\(uid)": mask]` for other users' permission
    public func updateUserPermissions(_ permissions: [String: UserPermissionAbility]) {
        permissions.forEach { token, mask in
            userPermissionStore.setUserPermission(for: augmentedToken(of: token), to: mask)
        }
    }

    /// Find in local store the current user's permission for a designated file
    /// - Parameters:
    ///   - token: file's `objToken`
    ///   - type: file's `DocsType.rawValue`
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    public func getUserPermissions(for token: String) -> UserPermissionAbility? {
        return userPermissionStore.userPermission(for: augmentedToken(of: token))
    }

    /// Fetch from server the current user's permission for the designated files (10 files maximum)
    ///
    /// This method is **NOT** guaranteed to successfully fetch multiple files' user permission if you call it multiple times **within a second**.
    /// Use `registerUserPermissionsRequest(for:in)` to schedule requests in even spacing so as to minimize failures.
    ///
    /// - Parameters:
    ///   - files: files' `objToken` and `DocsType.rawValue`
    ///   - complete: The completion block sent to main thread handling the fetch result, optional.
    ///   Argument: (DocsNetworkError?, permission-updated objTokens excluding deleted files)
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    func fetchUserPermissions(files: [FileObj], complete: ((Error?, [String]) -> Void)? = nil) {

        guard User.current.info?.userID != nil else {
            spaceAssertionFailure("no userid in permission request")
            DispatchQueue.main.async { complete?(DocsNetworkError.loginRequired, []) }
            return
        }

        guard files.count > 0, files.count <= 10 else {
            spaceAssertionFailure("batch size should be 1...10")
            DispatchQueue.main.async { complete?(DocsNetworkError.invalidParams, []) }
            return
        }

        let params: [String: Any] = ["objs": files.toJSON()]

        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionObjects, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        request.makeSelfReferenced()

        request.start(callbackQueue: callbackQueue, result: { (json, error) in
            guard error == nil else {
                DispatchQueue.main.async { complete?(error, []) }
                return
            }
            guard let json = json, json["code"].int != nil, json["msg"].string != nil, let data = json["data"].dictionaryObject else {
                DispatchQueue.main.async { complete?(DocsNetworkError.invalidData, []) }
                return
            }
            guard let permsV2 = data["permissions_v2"] as? [String: Int] else {
                DispatchQueue.main.async { complete?(DocsNetworkError(json["code"].intValue, extraStr: json["msg"].stringValue), []) }
                return
            }
            var changedPermDict: [String: UserPermissionAbility] = [:]
            var changedPermTokens: [String] = []
            permsV2.forEach { [weak self] (token, permV2RawValue) in
                guard let self else { return }
                let augToken = self.augmentedToken(of: token)
                let permission = UserPermissionMask.create(withValue: permV2RawValue)

                if let cachePermission = self.userPermissionStore.userPermission(for: augToken), cachePermission.equalTo(anOther: permission) {

                } else {
                    changedPermTokens.append(token) // changedPermTokens 会传到外面，所以 token 不要附加 userID 尾缀
                    changedPermDict[token] = permission
                }
            }
            self.updateUserPermissions(changedPermDict)
            DispatchQueue.main.async { complete?(nil, changedPermTokens) }
        })
    }
}

//
// Created by duanxiaochen.7 on 2020/5/15.
// Affiliated with SpaceKit.
//
// Description: Permission manager for collborators, user permissions, public permissions and share folder permissions.
// FG key: spacekit.mobile.use_permission_manager，version >= 3.25

import Foundation
import SwiftyJSON
import HandyJSON
import RxSwift
import ThreadSafeDataStructure
import SKFoundation
import SKResource
import SKInfra

public struct FileObj: HandyJSON, Hashable {
    public var token: String = ""
    public var type: Int = 0

    public init() {
    }

    public init(token: String = "", type: Int = 0) {
        self.token = token
        self.type = type
    }
}

public struct MultipleFilesResponseModel: HandyJSON, Hashable {
    public var files: [FileObj] = []
    public var code: Int = 0
    public var message: String = "Success"

    public init() {
    }

    public init(files: [FileObj] = [], code: Int = 0, message: String = "Success") {
        self.files = files
        self.code = code
        self.message = message
    }
}

public enum CollaboratorsError: Error {
    case networkError
    case parseError
}

typealias CollaboratorsSearchResults = ([Collaborator]?, Bool)

public final class PermissionManager {
    public enum RequestStatus {
        case fetched
        case fetching
    }

    enum FetchUserPermissionsGroupID {
        case commentTableView
        case feedTableView
        case frontendSubscription
    }

    /// The queue where all the requests' callback (JSON parsing, store writing) take place
    let callbackQueue = DispatchQueue(label: "lark.space.permission_manager")

    /// Stores user permissions and related requests. Data for docs/sheets are cleared after exiting the docs/sheets.
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    let userPermissionStore = UserPermissionStore()

    /// Stores public permissions and related requests. Data for docs/sheets are cleared after exiting the docs/sheets.
    let publicPermissionStore = PublicPermissionStore()

    /// Stores collaborators and related requests
    public let collaboratorStore = CollaboratorStore()

    public init() {}

    /// Append `_\(UserID)` to a token.
    /// - Parameters:
    ///   - token: A file's `objToken` or a new share folder's `spaceID`
    ///   - userID: Another user's `userID`, optional, default `nil` means using current `userID`.
    /// - Returns: An `userID` augmented token in a form of `"\(token)_\(userID)"`
    public func augmentedToken(of token: String, userID: String? = nil) -> String {
        guard let currentUserID = User.current.info?.userID else {
            spaceAssertionFailure("no user are logged in before sending permission request")
            return token
        }
        let uid = userID ?? currentUserID
        if token.contains("_") {
            return token
        } else {
            return "\(token)_\(uid)"
        }
    }
}

public struct DeleteCollaboratorsRequest {
    public let type: Int
    public let token: String
    public let ownerID: String
    public let ownerType: Int
    public let collaboratorSource: CollaboratorSource
}

// MARK: - Static Requests

// FIXME: These methods should not be static.
extension PermissionManager {
    // 删除协作者
    public static func getDeleteCollaboratorsRequest(context: DeleteCollaboratorsRequest,
                                                     complete: @escaping (Result<Void, Error>, JSON?) -> Void) -> DocsRequest<JSON> {
        let parameters: [String: Any] = ["token": context.token,
                                         "type": context.type,
                                         "owner_id": context.ownerID,
                                         "owner_type": context.ownerType,
                                         "perm_type": context.collaboratorSource.rawValue]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionCollaboratorsDelete, params: parameters)
            .set(method: .POST)
            .set(encodeType: .urlEncodeInBody)
            .set(needVerifyData: false)
            .start(result: { (json, error) in
                if let error = error {
                    DispatchQueue.main.async {
                        complete(.failure(error), json)
                    }
                    return
                }
                guard let code = json?["code"].int else {
                    DocsLogger.error("deleteCollaboratorsRequest failed, json: \(String(describing: json))")
                    DispatchQueue.main.async {
                        complete(.failure(CollaboratorsError.parseError), json)
                    }
                    return
                }
                guard code == 0 else {
                    DispatchQueue.main.async {
                        complete(.failure(CollaboratorsError.networkError), json)
                    }
                    return
                }
                DispatchQueue.main.async {
                    complete(.success(()), json)
                }
        })
    }
}

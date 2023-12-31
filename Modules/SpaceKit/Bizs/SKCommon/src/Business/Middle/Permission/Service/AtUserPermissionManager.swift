//
//  AtUserPermissionManager.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/10/25.
// swiftlint:disable line_length

import SKFoundation
import SwiftyJSON
import SpaceInterface
import SKInfra

public final class AtPermissionManager {
    public static let shared: AtPermissionManager = AtPermissionManager()
    var atUserArray: [AtUserDocsKey: AtUserPermission] = [:]
}

public struct InviteUserRequestContext {
    public let userId: String
    public let token: String
    public let type: DocsType
    public let sendLark: Bool
    public let refreshPermision: Bool
    
    public init(userId: String, token: String, type: DocsType, sendLark: Bool, refreshPermision: Bool) {
        self.userId = userId
        self.token = token
        self.type = type
        self.sendLark = sendLark
        self.refreshPermision = refreshPermision
    }
    
}

extension AtPermissionManager {

    public func hasPermission(_ uid: String, docsKey: AtUserDocsKey) -> Bool? {
        guard let atUserPermisson = atUserArray[docsKey] else {
            return nil
        }
        return atUserPermisson.hasPermissionForUser(uid: uid)
    }

    public func fetchAtUserPermission(ids: [String], docsKey: AtUserDocsKey, handler: AnyObject, block: @escaping AtUserPermissionCallBack) {
        var userPermission: AtUserPermission? = atUserArray[docsKey]
        if userPermission == nil {
            userPermission = AtUserPermission(sKDocsKey: docsKey)
            atUserArray.updateValue(userPermission!, forKey: docsKey)
        }
        userPermission?.fetchAtUserPermission(ids: ids, handler: handler, block: block)
    }
}

extension AtPermissionManager {

    public func canInvite(for token: String) -> Bool {
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
        return permissionManager.getUserPermissions(for: token)?.canShare() ?? false
    }

    public func inviteUserRequest(context: InviteUserRequestContext, complete: @escaping (String?) -> Void) {
        let collaborator = Collaborator(rawValue: CollaboratorType.user.rawValue, userID: context.userId, name: "", avatarURL: "", avatarImage: nil, userPermissions: UserPermissionMask.read, groupDescription: nil)
        let requestContext = CollaboratorsRequest(type: context.type.rawValue, token: context.token, candidates: Set([collaborator]), notify: context.sendLark, larkIMText: nil, collaboratorSource: .defaultType)
        let request = PermissionManager.inviteCollaboratorsRequest(context: requestContext, notifyType: .bot) { [weak self] (result: JSON?, error: Error?) in
                let error = error as NSError?
                let statusCode = error?.code ?? 0
                guard let self = self else { return }
                guard let json = result else {
                    DocsLogger.error("return not json")
                    return
                }
                let code = json["code"].intValue

                guard code == 0, statusCode == 0 else {
                    DocsLogger.error("return error code = \(code), statusCode=\(statusCode)")

                    let errMsg = CollaboratorBlockStatusManager(requestType: .inviteCollaboratorsForBiz, fromView: nil, statistics: nil).getInviteCollaboratorsForBizFailedMessage(json)
                    complete(errMsg)
                    return
                }
                if context.refreshPermision {
                    let docsKey = AtUserDocsKey(token: context.token, type: context.type)
                    AtPermissionManager.shared.fetchAtUserPermission(ids: [context.userId], docsKey: docsKey, handler: self) { _ in
                        DocsLogger.info("重新拉取权限回来")
                        complete(nil)
                    }
                } else {
                    complete(nil)
                }
        }
        request.makeSelfReferenced()
    }
    
    public func inviteUserRequest(atInfo: AtInfo, docsKey: AtUserDocsKey, sendLark: Bool, complete: @escaping (String?) -> Void) {
        let context = InviteUserRequestContext(userId: atInfo.token, token: docsKey.token, type: docsKey.type, sendLark: sendLark, refreshPermision: true)
        self.inviteUserRequest(context: context, complete: complete)
    }
}

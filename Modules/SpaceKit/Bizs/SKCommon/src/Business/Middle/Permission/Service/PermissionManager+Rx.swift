//
//  PermissionManager+Rx.swift
//  SKCommon
//
//  Created by peilongfei on 2023/2/9.
//  


import Foundation
import RxSwift

public enum PermissionError: LocalizedError {
    case general(String)
    
    public var errorDescription: String? {
        switch self {
        case let .general(errMeg):
            return errMeg
        }
        return nil
    }
}

extension PermissionManager {

    // 查询文档附件权限时，需要同时把父文档的 parentToken 和 parentType 传进来
    public func fetchUserPermission(token: String, type: Int, parent: (String, Int)? = nil) -> Single<UserPermissionAbility> {
        return .create { [weak self] observer in
            self?.requestDocumentActionsState(token: token, type: type, actions: [], parent: parent) { info, error in
                if let error = error {
                    observer(.error(error))
                    return
                }
                if let userPermission = info?.mask {
                    observer(.success(userPermission))
                    return
                }
                observer(.error(PermissionError.general("userPermission is nil")))
            }
            return Disposables.create()
        }
    }

    public func fetchPublicPermission(token: String, type: Int) -> Single<PublicPermissionMeta> {
        return .create { [weak self] observer in
            self?.fetchPublicPermissions(token: token, type: type, complete: { publicPermission, error in
                if let error = error {
                    observer(.error(error))
                    return
                }
                if let publicPermission = publicPermission {
                    observer(.success(publicPermission))
                    return
                }
                observer(.error(PermissionError.general("publicPermission is nil")))
            })
            return Disposables.create()
        }
    }
}

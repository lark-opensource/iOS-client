//
//  BasePermissionObj.swift
//  SKBitable
//
//  Created by yinyuan on 2023/8/2.
//

import Foundation
import SpaceInterface
import SKFoundation

/// Base 权限点位对象，当你需要与权限点位中台进行对接时，需要使用这个对象
/// 注意：base@docx 中，inline base 使用的是宿主的信息，而关联base使用的是自己的信息，因此 permissionObj.objToken 不一定等于 baseToken
public struct BasePermissionObj {
    let objToken: String
    let objType: DocsType
    
    static func parse(_ params: [String : Any]) -> BasePermissionObj? {
        guard UserScopeNoChangeFG.YY.bitableReferPermission else {
            return nil
        }
        guard let srcObjToken: String = params["srcObjToken"] as? String,
              let srcObjTypeInt: Int = params["srcObjType"] as? Int else {
            return nil
        }
        let srcObjType = DocsType(rawValue: srcObjTypeInt)
        return BasePermissionObj(objToken: srcObjToken, objType: srcObjType)
    }
}

extension BasePermissionObj: CustomStringConvertible {
    public var description: String {
        "BasePermissionObj:{objToken:\(objToken.encryptToShort),objType:\(objType.rawValue)}"
    }
}

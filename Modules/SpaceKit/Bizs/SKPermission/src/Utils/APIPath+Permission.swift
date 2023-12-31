//
//  APIPath+Permission.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation
// TODO: APIPath+Permission 文件迁移

enum OpenAPI {
    enum APIPath {
        /// 获取文档用户权限
        static let getDocumentUserPermission = "/api/suite/permission/document/actions/state/"

        /// 获取 Space 2.0 文件夹用户权限
        public static let getFolderUserPermission = "/api/suite/permission/space/collaborator/perm/"

        /// 获取 Space 1.0 文件夹用户权限
        public static let getLegacyFolderUserPermission = "/api/suite/permission/share_space/member/perm/"

        /// dlp policy
        public static let dlpPolicystatus = "/lark/scs/compliance/intercept/ccm/policystatus"
        /// dlp check result
        public static let dlpResult = "/lark/scs/compliance/intercept/ccm/result"
    }
}

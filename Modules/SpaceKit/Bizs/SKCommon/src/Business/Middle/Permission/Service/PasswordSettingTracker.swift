//
//  PasswordSettingTracker.swift
//  SpaceKit
//
//  Created by liweiye on 2020/6/3.
//

import Foundation
import SKFoundation

enum PasswordSettingTrackerAction: String {
    case addPassword = "add_password"
    case changePassword = "change_password"
    case copy = "copy"
}

// 需求文档: https://bytedance.feishu.cn/docs/doccnJ6xvEqSBk7NOVpEZQaqOjf
class PasswordSettingTracker {
    struct FileModel {
        var objToken: String
        var type: ShareDocsType
        var fileType: String
        public init(objToken: String,
                    type: ShareDocsType,
                    ownerID: String,
                    fileType: String) {
            self.objToken = objToken
            self.type = type
            self.fileType = fileType
        }
    }
    private var fileModel: FileModel
    private let source: ShareSource

    init(fileModel: FileModel, source: ShareSource) {
        self.fileModel = fileModel
        self.source = source
    }

    func report(action: PasswordSettingTrackerAction) {
        var params: [String: Any] = [String: Any]()
        params["action"] = action.rawValue
        params["file_id"] = DocsTracker.encrypt(id: fileModel.objToken)
        params["file_type"] = fileModel.type.name
        params["sub_file_type"] = fileModel.fileType
        var module = ""
        if source == .list {
            module = FileListStatistics.module?.rawValue ?? "space"
        } else {
            module = fileModel.type.name
        }
        params["module"] = module
        DocsTracker.log(enumEvent: .clientLockSetting, parameters: params)
    }
}

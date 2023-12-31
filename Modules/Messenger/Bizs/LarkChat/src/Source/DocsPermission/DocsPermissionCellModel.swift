//
//  DocsPermissionCellModel.swift
//  Lark-Rust
//
//  Created by qihongye on 2018/2/28.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RustPB
import LarkMessageCore
import LarkRichTextCore

public final class DocsPermissionCellModel: DocPermissionCellProps {

    public var docUrl: String {
        return doc.url
    }

    var doc: RustPB.Basic_V1_Doc
    var permission: RustPB.Basic_V1_DocPermission.Permission

    public var messageIds: [String]

    public var icon: UIImage? {
        return LarkRichTextCoreUtils.docIcon(docType: doc.type, fileName: doc.name)
    }

    public var title: String {
        return doc.name
    }

    public var ownerName: String {
        return doc.ownerName
    }

    public var allowEdit: Bool

    public var permissionStates: [DocPermissionState]

    public var selectedPermisionStateIndex: Int32 = 0

    public var selected: Bool

    public init(
        messageIds: [String],
        doc: RustPB.Basic_V1_Doc,
        permission: RustPB.Basic_V1_DocPermission.Permission,
        selected: Bool = false
    ) {
        self.messageIds = messageIds
        self.doc = doc

        self.permission = permission

        var readPermission = RustPB.Basic_V1_DocPermission.Permission()
        readPermission.code = Int32(UpdateDocPermissionRequest.Permission.read.rawValue)

        var editPermission = RustPB.Basic_V1_DocPermission.Permission()
        editPermission.code = Int32(UpdateDocPermissionRequest.Permission.edit.rawValue)

        if permission.code == Int32(UpdateDocPermissionRequest.Permission.read.rawValue) {
            self.allowEdit = false
        } else {
            self.allowEdit = true
        }

        self.permissionStates = [readPermission, editPermission]

        self.selected = selected
    }
}

typealias UpdateDocPermissionRequest = RustPB.Space_Doc_V1_UpdateDocPermissionRequest
typealias CreateChatRequest = RustPB.Im_V1_CreateChatRequest

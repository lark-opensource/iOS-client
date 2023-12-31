//
//  DocsPermisionVCModel.swift
//  Lark-Rust
//
//  Created by qihongye on 2018/2/28.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation

public final class DocsPermissionVCModel: DocsPermissionVCProps {
    public var permissions: [DocPermissionCellProps]

    public init(docPermissions: [DocPermissionCellProps]) {
        self.permissions = docPermissions
    }

    public func authDocs(_ docs: [String: DocPermissionCellProps]) {

    }
}

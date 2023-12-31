//
//  PickerUserGroupMeta.swift
//  LarkModel
//
//  Created by Yuri on 2023/5/29.
//

import Foundation
import RustPB

//extension RustPB.Search_V2_UserGroupMeta: Codable {}

public struct PickerUserGroupMeta {
    public var id: String
    public var meta: RustPB.Search_V2_UserGroupMeta?

    public init(id: String, meta: RustPB.Search_V2_UserGroupMeta? = nil) {
        self.id = id
        self.meta = meta
    }

}

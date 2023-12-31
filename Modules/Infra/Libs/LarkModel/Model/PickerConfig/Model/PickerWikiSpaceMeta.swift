//
//  PickerWikiSpaceMeta.swift
//  LarkModel
//
//  Created by Yuri on 2023/6/5.
//

import Foundation
import RustPB

public struct PickerWikiSpaceMeta: PickerItemMetaType {
    public var id: String
    public var title: String?
    public var desc: String?
    public var meta: RustPB.Search_V2_WikiSpaceMeta?

    public init(title: String? = nil,
                desc: String? = nil,
                meta: RustPB.Search_V2_WikiSpaceMeta? = nil) {
        self.id = meta?.spaceID ?? ""
        self.title = title
        self.desc = desc
        self.meta = meta
    }
}

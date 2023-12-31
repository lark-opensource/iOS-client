//
//  PickerDocMeta.swift
//  LarkModel
//
//  Created by Yuri on 2023/5/19.
//

import Foundation
import RustPB

public struct PickerDocMeta: PickerItemMetaType {
    public var id: String
    public var title: String?
    public var desc: String?
    public var iconInfo: String?
    public var meta: RustPB.Search_V2_DocMeta?

    public init(title: String? = nil,
                desc: String? = nil,
                meta: RustPB.Search_V2_DocMeta? = nil) {
        self.id = meta?.id ?? ""
        self.title = title
        self.desc = desc
        self.meta = meta

    }
}

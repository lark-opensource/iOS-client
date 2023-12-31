//
//  PickerMailUserMeta.swift
//  LarkModel
//
//  Created by ByteDance on 2023/10/5.
//

import Foundation
import RustPB

// 开放搜索的Meta结构
public struct PickerMailUserMeta: PickerItemMetaType {
    public var id: String
    public var title: String?
    public var summary: String?
    public var mailAddress: String?
    public var imageURL: String?
    public var meta: RustPB.Search_V2_SlashCommandMeta?

    public init(id: String,
                title: String? = nil,
                summary: String? = nil,
                mailAddress: String? = nil,
                imageURL: String? = nil,
                meta: RustPB.Search_V2_SlashCommandMeta? = nil) {
        self.id = id
        self.title = title
        self.summary = summary
        self.mailAddress = mailAddress
        self.imageURL = imageURL
        self.meta = meta
    }
}

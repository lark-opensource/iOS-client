//
//  DocPreview.swift
//  LarkMine
//
//  Created by Hayden Wang on 2021/7/7.
//

import Foundation

struct DocPreview {
    var title: String
    var message: String
    var highlight: String
    var list1: String
    var list2: String
}

extension DocPreview {

    static func getExample() -> DocPreview {
        return DocPreview(
            title: BundleI18n.LarkMine.Lark_NewSettings_PreviewTextSizeDocs,
            message: BundleI18n.LarkMine.Lark_NewSettings_TextSizeAdjustForDocs,
            highlight: BundleI18n.LarkMine.Lark_NewSettings_TextSizePreviewDocsFeedback(),
            list1: BundleI18n.LarkMine.Lark_NewSettings_TextSizePreviewDocs1,
            list2: BundleI18n.LarkMine.Lark_NewSettings_TextSizePreviewDocs2
        )
    }
}

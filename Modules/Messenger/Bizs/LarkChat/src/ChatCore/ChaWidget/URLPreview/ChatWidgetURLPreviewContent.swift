//
//  ChatWidgetURLPreviewContent.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/1/10.
//

import Foundation
import RustPB
import LarkOpenChat
import TangramService
import LarkModel

struct ChatWidgetURLPreviewContent: ChatWidgetContent {
    let hangPoint: RustPB.Basic_V1_PreviewHangPoint
    var urlPreviewEntity: URLPreviewEntity?

    func copy() -> Self {
        let previewContent = ChatWidgetURLPreviewContent(hangPoint: self.hangPoint, urlPreviewEntity: self.urlPreviewEntity)
        return previewContent
    }
}

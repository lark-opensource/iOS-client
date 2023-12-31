//
//  WhiteboardPage.swift
//  ByteViewNetwork
//
//  Created by Prontera on 2022/3/20.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

typealias PBWhiteboardPage = Videoconference_V1_WhiteboardPage
public struct WhiteboardPage: Equatable {
    /// 页唯一 id
    public let pageID: Int64

    /// 页码
    public let pageNum: Int32

    /// 该页是否正在被共享
    public let isSharing: Bool

    public init(pageID: Int64, pageNum: Int32, isSharing: Bool) {
        self.pageID = pageID
        self.pageNum = pageNum
        self.isSharing = isSharing
    }
}

extension WhiteboardPage {
    var pbType: PBWhiteboardPage {
        var page = PBWhiteboardPage()
        page.pageID = pageID
        page.pageNum = pageNum
        page.isSharing = isSharing
        return page
    }
}

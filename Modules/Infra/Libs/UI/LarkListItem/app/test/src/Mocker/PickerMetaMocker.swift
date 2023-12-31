//
//  DocMetaMocker.swift
//  LarkListItemDemo
//
//  Created by Yuri on 2023/5/29.
//

import Foundation
import RustPB
import LarkModel

class ChatterMetaMocker {
    static func mockChatter() -> PickerChatterMeta {
        var meta = PickerChatterMeta(
            id: "6833188035178283010",
            name: "mumu",
            localizedRealName: "mumu",
            avatarKey: "15094e27-7366-46df-bee8-c535b8bf745g",
            description: "Unit test",
            email: "mumu.xu@bytedance.com",
            attributedName: "<h>mumu</h>"
        )
        meta.status = []
        return meta
    }
}

class DocMetaMocker {
    static func mockDoc() -> PickerDocMeta {
        var doc = RustPB.Search_V2_DocMeta()
        doc.type = .bitable
        doc.id = "bascntljWNdd76NydY7ZO0PBAtc"
        doc.updateTime = 1684402940
        doc.url = "https://bytedance.feishu.cn/base/bascntljWNdd76NydY7ZO0PBAtc"
        doc.ownerName = "谢许峰"
        doc.ownerID = "6807206318940618753"
        doc.messageID = ""
        doc.position = 0
        doc.isCrossTenant = false
        doc.createTime = 1671159907
        doc.lastOpenTime = 1684406738
        doc.editUserID = "6807206318940618753"
        doc.editUserName = "谢许峰"
        doc.chatID = ""
        doc.threadID = ""
        doc.threadPosition = 0
        doc.threadChatPosition = 0
        var icon = Basic_V1_Icon()
        icon.type = .unknown
        icon.value = ""
        doc.icon = icon
        doc.isShareFolder = false
        let meta = PickerDocMeta(meta: doc)
        return meta
    }
}

class WikiMetaMocker {
    static func mockWiki() -> PickerWikiMeta {
        var doc = RustPB.Search_V2_WikiMeta()
        doc.type = .docx
        doc.id = "doxcnq9pWpkfkWc7uBEI4vISX6g"
        doc.updateTime = 1677837573
        doc.url = "https://bytedance.feishu.cn/wiki/wikcnGJwvu8GnwtzvH3ePCQwEcg"
        doc.ownerName = "谢许峰"
        doc.ownerID = "6807206318940618753"
        doc.messageID = ""
        doc.position = 0
        doc.isCrossTenant = false
        doc.createTime = 1657543680
        doc.lastOpenTime = 1685513890
        doc.editUserID = "6807206318940618753"
        doc.editUserName = "谢许峰"
        doc.spaceID = 7045980712687697921
        doc.spaceName = "Lark Office"
        doc.token = "wikcnGJwvu8GnwtzvH3ePCQwEcg"
        var icon = Basic_V1_Icon()
        icon.type = .unknown
        icon.value = ""
        let meta = PickerWikiMeta(meta: doc)
        return meta
    }
}

class WikiSpaceMocker {
    static func mockWikiSpace() -> PickerWikiSpaceMeta {
        var wikiSpace = RustPB.Search_V2_WikiSpaceMeta()
        wikiSpace.spaceID = "7043001552528785411"
        wikiSpace.spaceName = "TCC"
        wikiSpace.description_p = "配置管理解决方案"
        wikiSpace.isStar = false
        wikiSpace.wikiSpaceType = .team
        wikiSpace.wikiScope = .public
        wikiSpace.rootToken = "wikcnFVwn8fCxaEDlR7CQyPCLfF"
        wikiSpace.coverColorValue = "FFFFFF"
        wikiSpace.coverIsGraphDark = false
        wikiSpace.coverKey = "boxcnI2TnBY0KexcUv83T6Dkdqg_false"
        wikiSpace.coverOrigin = "https://s1-imfile.feishucdn.com/static-resource/v1/v2_d270bcab-c014-43d9-ac9b-3ef150e8199g~?image_size=noop&cut_type=&quality=&format=image&sticker_format=.webp"
        wikiSpace.coverThumbnail = ""
        let meta = PickerWikiSpaceMeta(meta: wikiSpace)
        return meta
    }
}

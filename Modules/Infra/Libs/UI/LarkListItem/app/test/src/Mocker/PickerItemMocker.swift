//
//  PickerItemMocker.swift
//  LarkListItemDemo
//
//  Created by Yuri on 2023/6/5.
//

import Foundation
import LarkModel
import RustPB

class PickerItemMocker {
    static func mockChatter(meta: PickerChatterMeta) -> PickerItem {
        var item = PickerItem(meta: .chatter(meta))
        var renderData = PickerItem.RenderData()
        renderData.title = "MuMu"
        renderData.summary = "Lark Office Engineering-Performance"
        renderData.renderData = "{\"components\":{\"tenant_name\":\"\",\"department_name\":\"Lark Office Engineering-Performance\",\"custom_display\":\"\",\"explanation_descriptions\":\"\"},\"template\":\"search_chatter_card\"}"
        renderData.extrasHighlighted = ""
        item.renderData = renderData
        return item
    }

    static func mockDoc(doc: PickerDocMeta = DocMetaMocker.mockDoc()) -> PickerItem {
        var item = PickerItem(meta: .doc(doc))
        var segment1 = Search_V2_ExtraInfoBlockSegment()
        segment1.textHighlighted = "所有者：谢许峰"
        segment1.isOmissible = false
        segment1.type = .text
        var segment2 = Search_V2_ExtraInfoBlockSegment()
        segment2.textHighlighted = "最后更新于 "
        segment2.isOmissible = false
        segment2.type = .text
        var segment3 = Search_V2_ExtraInfoBlockSegment()
        segment3.textHighlighted = "1684910632"
        segment3.isOmissible = false
        segment3.type = .timestamp
        var block1 = RustPB.Search_V2_ExtraInfoBlock()
        block1.blockSegments = [segment1]
        var block2 = RustPB.Search_V2_ExtraInfoBlock()
        block2.blockSegments = [ segment2, segment3]
        var renderData = PickerItem.RenderData()
        renderData.extraInfoSeparator = " · "
        renderData.extraInfos = [block1, block2]
        renderData.titleHighlighted = NSAttributedString(string: "TaskBoard")
        renderData.summaryHighlighted = NSAttributedString(string: "")
        item.renderData = renderData
        return item
    }

    static func mockWiki(wiki: PickerWikiMeta = WikiMetaMocker.mockWiki()) -> PickerItem {
        var item = PickerItem(meta: .wiki(wiki))
        var segment1 = Search_V2_ExtraInfoBlockSegment()
        segment1.textHighlighted = "Lark Office"
        segment1.isOmissible = false
        segment1.type = .text
        var block1 = RustPB.Search_V2_ExtraInfoBlock()
        block1.blockSegments = [segment1]
        block1.segmentSeparator = ">"
        var icon = Search_V2_ExtraInfoBlockIcon()
        icon.iconKey = "wiki"
        block1.blockIcon = icon

        var segment2 = Search_V2_ExtraInfoBlockSegment()
        segment2.textHighlighted = "最后更新于 "
        segment2.isOmissible = false
        segment2.type = .text
        var segment3 = Search_V2_ExtraInfoBlockSegment()
        segment3.textHighlighted = "1677837573"
        segment3.isOmissible = false
        segment3.type = .timestamp
        var block2 = RustPB.Search_V2_ExtraInfoBlock()
        block2.blockSegments = [segment2, segment3]
        var renderData = PickerItem.RenderData()
        renderData.extraInfoSeparator = " · "
        renderData.extraInfos = [block1, block2]
        renderData.titleHighlighted = NSAttributedString(string: "Lark iOS Core模块技术目录")
        renderData.summaryHighlighted = NSAttributedString(string: "")
        item.renderData = renderData
        return item
    }

    static func mockWikiSpace(space: PickerWikiSpaceMeta = WikiSpaceMocker.mockWikiSpace()) -> PickerItem {
        var item = PickerItem(meta: .wikiSpace(space))
        var renderData = PickerItem.RenderData()
        renderData.titleHighlighted = NSAttributedString(string: "TCC")
        renderData.summaryHighlighted = NSAttributedString(string: "配置管理解决方案")
        item.renderData = renderData
        return item
    }
}

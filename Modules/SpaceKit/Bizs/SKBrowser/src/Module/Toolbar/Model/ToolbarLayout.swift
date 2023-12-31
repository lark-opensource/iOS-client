//
// Created by duanxiaochen.7 on 2020/11/24.
// Affiliated with SKBrowser.
//
// Description:

import Foundation
import HandyJSON

public typealias ToolBarLineType = [String: [[BarButtonIdentifier]]]

enum TextAttributionLayoutType: String, CaseIterable {
    case singleLine = "SingleLineKey"
    case scrollableLine = "ScrollableLineKey"
}

/// the layout of attributon panel
public final class ToolBarLayoutMapping {
    static let kSingleLine: String = TextAttributionLayoutType.singleLine.rawValue
    static let kScrollableLine: String = TextAttributionLayoutType.scrollableLine.rawValue

    /// docs text attribution layout
    ///
    /// - Returns: layout
    class func docsAttributeItems(_ dict: [BarButtonIdentifier: ToolBarItemInfo]) -> [ToolBarLineType] {
        let subBius: [BarButtonIdentifier] = [.bold, .italic, .underline, .strikethrough]
        let subH: [BarButtonIdentifier] = resolveTypeH(dict)
        let subList: [BarButtonIdentifier] = [.checkbox, .unorderedlist, .orderedlist]
        let subCode: [BarButtonIdentifier] = [.inlinecode, .codelist]
        let subQuote: [BarButtonIdentifier] = [.blockquote]
        let subAlign: [BarButtonIdentifier] = [.alignleft, .aligncenter, .alignright]
        let subSeparator: [BarButtonIdentifier] = [.insertSeparator]

        let lineType1 = [kScrollableLine: [subH]]
        let lineType2 = [kSingleLine: [subBius]]
        let lineType3 = [kSingleLine: [subList, subCode]]
        let lineType4 = [kSingleLine: [subQuote, subAlign, subSeparator]]

        return [lineType1, lineType2, lineType3, lineType4]
    }

    /// sheet text attributon layout
    ///
    /// - Returns: layout
    class func sheetAttributeItems() -> [ToolBarLineType] {
        let subBius: [BarButtonIdentifier] = [.bold, .italic, .underline, .strikethrough]
        let subAlign: [BarButtonIdentifier] = [.horizontalLeft, .horizontalCenter, .horizontalRight]
        let subVertical: [BarButtonIdentifier] = [.verticalTop, .verticalCenter, .verticalBottom]

        let lineType1 = [kSingleLine: [subBius]]
        let lineType2 = [kSingleLine: [subAlign]]
        let lineType3 = [kSingleLine: [subVertical]]

        return [lineType1, lineType2, lineType3]
    }

    /// sheet cell manager panel layout
    ///
    /// - Returns: layout
    class func sheetCellManagerItems() -> [ToolBarLineType] {
        let subMerge: [BarButtonIdentifier] = [.cellMerge]
        let subLinebreak: [BarButtonIdentifier] = [.autoWrap, .overflow, .clip]

        let lineType1 = [kSingleLine: [subMerge]]
        let lineType2 = [kSingleLine: [subLinebreak]]

        return [lineType1, lineType2]
    }

    public class func sheetRedesignAttribute() -> [ToolBarLineType] {
        let subBius: [BarButtonIdentifier] = [.bold, .italic, .underline, .strikethrough]
        let subCell: [BarButtonIdentifier] = [.cellMerge]
        let lineType1 = [kSingleLine: [subBius]]
        let lineType2 = [kSingleLine: [subCell]]
        return [lineType1, lineType2]
    }

    public class func sheetRedesignAlign() -> [ToolBarLineType] {
        let subAlign: [BarButtonIdentifier] = [.horizontalLeft, .horizontalCenter, .horizontalRight]
        let subVertical: [BarButtonIdentifier] = [.verticalTop, .verticalCenter, .verticalBottom]
        let subLinebreak: [BarButtonIdentifier] = [.autoWrap, .overflow, .clip]

        let lineType1 = [kSingleLine: [subAlign]]
        let lineType2 = [kSingleLine: [subVertical]]
        let lineType3 = [kSingleLine: [subLinebreak]]

        return [lineType1, lineType2, lineType3]
    }

    public class func sheetRedesignFreeze() -> [ToolBarLineType] {
        let subItems: [BarButtonIdentifier] = [.tmpToggleFreeze]
        let lineType1 = [kSingleLine: [subItems]]
        return [lineType1]
    }

    class func mindnoteAttributeItems() -> [ToolBarLineType] {
        let subBius: [BarButtonIdentifier] = [.bold, .italic, .underline]
        let subH: [BarButtonIdentifier] = [.h1, .h2, .h3]
        let lineType1 = [kSingleLine: [subBius]]
        let lineType2 = [kSingleLine: [subH]]
        return [lineType1, lineType2]
    }
}

extension ToolBarLayoutMapping {
    @inline(__always)
    private class func resolveTypeH(_ dict: [BarButtonIdentifier: ToolBarItemInfo]) -> [BarButtonIdentifier] {
        let kTypeSetH: [BarButtonIdentifier] = [.h1, .h2, .h3, .h4, .h5, .h6, .h7, .h8, .h9]
        return kTypeSetH.filter { return dict.keys.contains($0) }
    }
}

//
//  ToolBarItem.swift
//  SpaceKit
//
//  Created by Webster on 2019/1/6.
//

import Foundation
import SwiftyJSON
import HandyJSON
import SKResource
import SKUIKit
import UniverseDesignIcon
import RxDataSources
import SKFoundation
import UniverseDesignColor

/// the display info for each tool bar item
/// 对外的工具栏接口有用到这个类：重大接口变更一定要在lark里面测试能不能编译通过
//swiftlint:disable function_body_length
public final class ToolBarItemInfo: Hashable, IdentifiableType, GroupableItem, SKOperationItem {

    public typealias Identity = String

    public var identity: String {
        return identifier + (parentIdentifier ?? subIdentifier)
    }

    public var identifier: String
    
    // 父菜单
    public var parentIdentifier: String?

    public var groupId: String {
        return parentIdentifier ?? identifier
    }
    
    public var subIdentifier: String = ""
    
    public var titleFont: UIFont?
    
    public var titleAlignment: NSTextAlignment?
    
    public var imageNoTint: Bool {
        let noTintIds: [BarButtonIdentifier] = [.myAiDataInsight, .ai]
        return noTintIds.contains { $0.rawValue == self.identifier }
    }
    
    public var imageSize: CGSize?
    
    public var background: (normal: UIColor, highlighted: UIColor)?
    
    public var clickHandler: (() -> Void)?
    
    public var title: String?
    
    public var image: UIImage?
    
    public var jsonString: String?
    // 对应 value 字段
    public var value: String?
    // 对应 value 字段
    public var valueJSON: [String: Any]?
    // 对应 list 字段
    public var valueList: [String]?

    public var minValue: Int?
    
    public var maxValue: Int?
    
    public var isSelected: Bool = false
    
    public var isEnable: Bool = true
    
    public var jsMethod: String = ""
    
    // admin限制，true置灰弹toast
    public var adminLimit: Bool = false
    
    public var children: [ToolBarItemInfo]?
    
    public var childrenIsShow: Bool = false
    
    public var childrenOrientationType: ToolbarOrientation?
    
    public var childrenRealCount: Int = 0
    
    // sheet 颜色面板解析 对应list
    public var colorList: [ColorItemNew]?
    
    // sheet 边框数据
    public var borderInfo: BorderInfo?

    public var hasSubItem: Bool {
        (children?.count ?? 0) > 0
    }

    public var insertList: [SKOperationItem]?

    public var shouldShowRedPoint: Bool {
        if self.identifier == BarButtonIdentifier.uploadImage.rawValue {
            return self.adminLimit && self.isEnable
        } else {
            return self.isEnable
        }
    }

    public var shouldShowWarningIcon: Bool = false
    
    public var shouldShowRedBadge: Bool = false

    public var customView: UIView?

    public var customViewHeight: CGFloat?

    public var disableReason: OperationItemDisableReason = .other

    public var customViewLayoutCompleted: () -> Void = {}

    /// Description
    ///
    /// - Parameters:
    ///   - identifier: identifier description
    ///   - json: json description
    public init(identifier: String, json: [String: Any], jsMethod: String = "") {
        self.jsMethod = jsMethod
        self.identifier = identifier
        self.isSelected = json["selected"] as? Bool ?? false
        self.isEnable = json["enable"] as? Bool ?? true
        self.adminLimit = json["adminLimit"] as? Bool ?? false
        self.value = loadValue(json)
        self.valueList = json["list"] as? [String]
        self.minValue = json["min"] as? Int
        self.maxValue = json["max"] as? Int
        self.image = ToolBarItemInfo.loadImage(by: identifier)
        self.title = ToolBarItemInfo.loadTitle(by: identifier, selected: self.isSelected, wantedTitle: (json["title"] as? String))
        
        if let list = json["list"] as? [[String: Any]] {
            colorList = [ColorItemNew]()
            for item in list {
                if let colorItem = ColorItemNew.deserialize(from: item) {
                    colorList?.append(colorItem)
                }
            }
        }
        
        if let list = json["list"] as? [String: Any] {
            borderInfo = BorderInfo.deserialize(from: list)
        }
        
        /// SetDocToolBar 和 V2 接口的 Children 结构不一样
        if let childrenInfos = json["children"] as? [[String: Any]] { // V1
            children = [ToolBarItemInfo]()
            for childDict in childrenInfos {
                if let newId = childDict["id"] as? String {
                    let childItem = ToolBarItemInfo(identifier: newId, json: childDict, jsMethod: jsMethod)
                    childItem.parentIdentifier = self.identifier
                    self.children?.append(childItem)
                }
            }
        } else if let childrenInfo = json["children"] as? [String: Any] { // V2
            if let typeInt = childrenInfo["orientationType"] as? Int {
                childrenOrientationType = ToolbarOrientation(rawValue: typeInt)
            } else {
                childrenOrientationType = .horizontal
            }
            if let items = childrenInfo["items"] as? [[String: Any]] {
                self.children = items.compactMap {
                    if let id = $0["id"] as? String {
                        let childItem = ToolBarItemInfo(identifier: id, json: $0, jsMethod: jsMethod)
                        childItem.parentIdentifier = self.identifier
                        childItem.isEnable = self.isEnable && childItem.isEnable
                        return childItem
                    } else {
                        return nil
                    }
                }
            }
        }

        if let jValue = json["value"] as? String,
            let jsonValue = JSON(parseJSON: jValue).dictionaryObject {
            self.jsonString = jValue
            self.valueJSON = jsonValue
        }
    }

    /// Initializes identifier and image only.
    ///
    /// - Parameter identifier: identifier description
    public init(identifier: String) {
        self.identifier = identifier
        self.image = ToolBarItemInfo.loadImage(by: identifier)
    }

    private func loadValue(_ json: [String: Any]) -> String? {
        if let value = json["value"] as? String { return value }
        if let intValue = json["value"] as? Int { return String(intValue) }
        return nil
    }

    /// load icon image by current button's identifier
    ///
    /// - Parameter identifier: button identifier
    /// - Returns: icon image
    public class func loadImage(by identifier: String) -> UIImage? {
        guard let type = BarButtonIdentifier(rawValue: identifier) else {
            return nil
        }
        // FIXME: 待删除源文件
        let imageMapping: [BarButtonIdentifier: UDIconType] = [
            .bold: .boldOutlined, // "icon_tool_bold_nor",
            .italic: .italicOutlined, // "icon_tool_italic_nor",
            .underline: .underlineOutlined, // "icon_tool_underline_nor",
            .strikethrough: .horizontalLineOutlined, // "icon_tool_horizontalline_nor",
            .highlight: .fontcolorOutlined, // icon_tool_highlight_nor
            .plainText: .text2Outlined, // "icon_plaintext_nor",
            .h1: .h1Outlined, // "icon_tool_H1_nor",
            .h2: .h2Outlined, // "icon_tool_H2_nor",
            .h3: .h3Outlined, // "icon_tool_H3_nor",
            .h4: .h4Outlined, // "icon_tool_H4_nor",
            .h5: .h5Outlined, // "icon_tool_H5_nor",
            .h6: .h6Outlined, // "icon_tool_H6_nor",
            .h7: .h7Outlined, // "icon_tool_H7_nor",
            .h8: .h8Outlined, // "icon_tool_H8_nor",
            .h9: .h9Outlined, // "icon_tool_H9_nor",
            .hn: .hnOutlined, // "icon_tool_Hn_nor",
            .copy: .copyOutlined, // "icon_tool_copy_nor",
            .paste: .pasteOutlined, // "icon_tool_paste_nor",
            .cut: .screenshotsOutlined, // "icon_tool_capture_nor",
            .clear: .deleteTrashOutlined, // "icon_global_delete_nor",
            .checkbox: .todoOutlined, // "icon_global_mindnotetodo_nor",
            .pencilkit: .pencilkitOutlined, // "icon_tool_pencilkit_nor",
            .orderedlist: .orderListOutlined, // "icon_tool_ordelist_nor",
            .unorderedlist: .disorderListOutlined, // "icon_tool_disordelist_nor",
            .inlinecode: .codeOutlined, // "icon_global_code_nor",
            .codelist: .codeblockOutlined, // "icon_tool_codeblock_nor",
            .blockquote: .referenceOutlined, // "icon_tool_reference_nor",
            .alignleft: .leftAlignmentOutlined, // "icon_tool_leftalignment_nor",
            .alignTransform: .typographyOutlined, // icon_tool_typography_nor
            .aligncenter: .centerAlignmentOutlined, // "icon_tool_centeralignment_nor",
            .alignright: .rightAlignmentOutlined, // "icon_tool_rightalignment_nor",
            .horizontalLeft: .leftAlignmentOutlined, // "icon_tool_leftalignment_nor",
            .horizontalCenter: .centerAlignmentOutlined, // "icon_tool_centeralignment_nor",
            .horizontalRight: .rightAlignmentOutlined, // "icon_tool_rightalignment_nor",
            .verticalTop: .topAlignOutlined, // "icon_tool_topalign_nor",
            .verticalBottom: .bottomAlignOutlined, // "icon_tool_buttonalign_nor",
            .verticalCenter: .verticalAlignOutlined, // "icon_tool_verticalalign_nor",
            .reminder: .calendarOutlined, // "icon_tool_insertcalendar_nor",
            .addReminder: .alarmClockOutlined, // "icon_tool_alarmclock_nor",
            .addNewBlock: .addnewOutlined, // "icon_global_more_add",
            .insertImage: .imageOutlined, // "icon_global_image_nor",
            .insertSeparator: .dividerOutlined, // "icon_tool_divider_nor",
            .mentionUser: .memberOutlined, // "icon_global_mentionpeople_nor",
            .mentionChat: .groupCardOutlined, // "icon_tool_groupcard_nor",
            .mentionFile: .spaceOutlined, // "icon_larkspace_outlined",
            .insertFile: .attachmentOutlined, // "icon_global_select_file_nor",
            .equation: .latexOutlined, // icon_global_latex_nor
            .calloutBlock: .calloutOutlined, // "icon_global_callout_nor",
            .insertTable: .dataSheetOutlined, // "icon_global_insert_table_nor",
            .insertCalendar: .calendarLineOutlined, // "icon_tool_insert_calendar_nor",
            .insertReminder: .alarmClockOutlined, // "icon_tool_insertreminder_nor"
            .insertTask: .tabTodoOutlined,
            .checkList: .todoOutlined,
            .transTask: .changeTodoOutlined,
            .search: .findAndReplaceOutlined, //icon_tool_findandreplace_nor
            .rename: .renameOutlined, // icon_global_rename_nor
            .uploadImage: .imageOutlined, // icon_operation_image_outlined
            .freeze: .freezeColumnAndRowOutlined, // fab_freeze
            .createSheet: .sheetOutlined, // icon_global_spreadsheet_nor
            .cellFilter: .listFilterOutlined, // icon_tool_filter_nor
            .insertComment: .addCommentOutlined, // icon_operation_comment_outlined
            .addRowUp: .insertRowUpOutlined, // icon_tool_insertionarrowtop_new_nor
            .addRowDown: .insertRowDownOutlined, // icon_tool_insertionarrowdown_new_nor
            .deleteRow: .deleteTrashOutlined, // icon_global_delete_nor
            .addColLeft: .insertColumnLeftOutlined, // icon_tool_insertionarrowleft_new_nor
            .addColRight: .insertColumnRightOutlined, // icon_tool_insertionarrowright_new_nor
            .deleteCol: .deleteTrashOutlined, // icon_global_delete_nor
            .exportImage: .longFigureOutlined, // icon_global_Long_figure_nor
            .insertSheet: .sheetTableOutlined,
            .insertBitable: .sheetBitableOutlined,
            .insertMindnote: .mindmapOutlined,
            .insertAgenda: .fileLinkNotesOutlined,
            .myAiDataInsight: .myaiColorful,
            .folderBlock: .wikiSubpageOutlined
        ]

        let firstLevelMapping: [BarButtonIdentifier: UDIconType] = [
            .blockTransform: .text2Outlined, // "icon_tool_textformat_nor",
            .textTransform: .textstyleOutlined, // icon_tool_textstyle_nor
            .attr: .styleOutlined, // "icon_global_style_nor",
            .at: .atOutlined, // "icon_global_at_nor",
            .comment: .addCommentOutlined, // "icon_global_doccomment_nor",
            .undo: .undoOutlined, // "icon_global_undo_nor",
            .redo: .redoOutlined, // "icon_global_redo_nor",
            .delete: .deleteTrashOutlined, // "icon_global_delete_nor",
            //.rename: .annotateOutlined, // "icon_global_rename_nor",
            //.createSheet: .sheetTableOutlined, // icon_global_spreadsheet_nor
            .createBitable: .fileBitableOutlined, // icon_global_bitable_nor
            .createGrid: .bitablegridOutlined, // icon_bitable_grid_outlined
            .createKanban: .bitablekanbanOutlined, // icon_bitable_kanban_outlined
            .indentLeft: .reduceIndentationOutlined, // "icon_global_reduceindentation_nor",
            .indentRight: .increaseIndentationOutlined, // "icon_global_increaseindentation_nor",
            .sheetTxtAtt: .styleOutlined, // "icon_global_style_nor",
            .sheetCellAtt: .sheetTableOutlined, // icon_global_table_nor
            .sheetCloseToolbar: .listCheckOutlined, // "icon_tool_done_nor",
            .mnTextAtt: .textstyleOutlined, // "icon_global_style_nor",
            .mnTextFormat: .text2Outlined, // "icon_tool_textformat_nor",
            .mnTextStyle: .textstyleOutlined, // icon_tool_textstyle_nor
            .mnIndent: .increaseIndentationOutlined, // "icon_global_increaseindentation_nor",
            .mnOutdent: .reduceIndentationOutlined, // "icon_global_reduceindentation_nor",
            .mnNote: .editDiscriptionOutlined, // "icon_tool_copyandpasteitem_nor",
            .mnFinish: .todoOutlined, // "icon_global_mindnotetodo_nor",
            .cellMerge: .mergecellsOutlined, // "icon_global_mergecells_nor",
            .clip: .clipOutlined, // "icon_tool_clip_nor",
            .autoWrap: .wrapOutlined, // "icon_tool_wrap_nor",
            .overflow: .wrappingOutlined, // "icon_tool_wrapping_nor",
            .backColor: .styleFillcolorOutlined, // "icon_tool_fill_color_nor",
            .foreColor: .styleFontcolorOutlined, // icon_tool_fontcolor_nor
            .borderLine: .bordersOutlined, // "icon_borders_outlined"
            .hyperLink: .linkCopyOutlined,
            .ai: .myaiColorful
        ]
        
        let resImageMapping: [BarButtonIdentifier?: UIImage] = [
            .okr: BundleResources.SKResource.Common.Tool.icon_tool_okr,
            .syncedSource: BundleResources.SKResource.Common.Tool.icon_link_record_outlined
        ]
        if let image = resImageMapping[type] {
            return image
        } else if let id = imageMapping[type] ?? firstLevelMapping[type] {
            
            return UDIcon.getIconByKey(id)
        } else {
            return nil
        }
    }

    class func loadTitle(by identifier: String, selected: Bool, wantedTitle: String?) -> String? {
        guard let type = BarButtonIdentifier(rawValue: identifier) else {
            return nil
        }
        if wantedTitle != nil { return wantedTitle }
        let cellTitle = selected ?  BundleI18n.SKResource.Doc_Doc_ToolbarCellSplit : BundleI18n.SKResource.Doc_Doc_ToolbarCellMerge
        let titleMapping: [BarButtonIdentifier: String] = [
            .cellMerge: cellTitle,
            .autoWrap: BundleI18n.SKResource.Doc_Doc_ToolbarCellAutoWrap,
            .overflow: BundleI18n.SKResource.Doc_Doc_ToolbarCellOverflow,
            .clip: BundleI18n.SKResource.Doc_Doc_ToolbarCellClip,
            .backColor: BundleI18n.SKResource.Doc_Doc_ToolbarCellBgColor,
            .borderLine: BundleI18n.SKResource.Doc_Doc_ToolbarCellBorderLine
        ]
        return titleMapping[type]
    }
    
    public func getSelectIndexInfo() -> IndexPath {
        let indexPath = IndexPath(row: -1, section: -1)
        guard let list = colorList else {
            return indexPath
        }
        let colorVal = (value ?? "#000000").lowercased()
        for (section, item) in list.enumerated() {
            for (row, color) in item.colorList.enumerated() {
                if colorVal == color.lowercased() {
                    return IndexPath(row: row, section: section)
                }
            }
        }
        return indexPath
    }

    public func updateJsonString(value: [String: Any]) {
        let jsonObj = JSON(value)
        if let rawString = jsonObj.rawString(.utf8, options: []) {
            self.jsonString = rawString
        }
    }
    
    public func isInsertList() -> Bool {
        return insertList != nil
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(parentIdentifier)
        hasher.combine(isSelected)
        hasher.combine(isEnable)
        hasher.combine(value)
        hasher.combine(valueList)
        hasher.combine(minValue)
        hasher.combine(maxValue)
        hasher.combine(title)
        hasher.combine(childrenIsShow)
    }

    public static func == (lhs: ToolBarItemInfo, rhs: ToolBarItemInfo) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

}

public final class ColorItemNew: HandyJSON {
    public var topicColor: String = ""
    public var defaultColor: String = ""
    public var colorList: [String] = []
    public var defaultIndex: Int {
        return colorList.firstIndex(of: defaultColor) ?? 0
    }

    required public init() {

    }
}

public final class BorderItemDefaultValue: HandyJSON {
    public var border: String = ""
    public var color: String = ""
    required public init() {

    }
}

public final class BorderInfo: HandyJSON {
    public var defaultValue: BorderItemDefaultValue?
    public var border: [String]?
    public var color: [ColorItemNew]?
    required public init() {

    }
}

public struct ToolBarItemContainer: AnimatableSectionModelType {
    public typealias Item = ToolBarItemInfo
    public var identity: String { identifier }

    public let identifier: String
    private(set) public var items: [Item]

    public init(identifier: String,
         items: [ToolBarItemInfo]) {
        self.identifier = identifier
        self.items = items
    }

    public init(original: ToolBarItemContainer,
         items: [ToolBarItemInfo]) {
        self = original
        self.items = items
    }
}

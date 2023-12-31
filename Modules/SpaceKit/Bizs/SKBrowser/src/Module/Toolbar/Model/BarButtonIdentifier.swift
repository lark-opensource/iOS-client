//
// Created by duanxiaochen.7 on 2020/11/24.
// Affiliated with SKCommon.
//
// Description:

import Foundation
import HandyJSON

/// button identifier belong to front end
///
public enum BarButtonIdentifier: String, HandyJSONEnum {

    // MARK: doc、sheet、mindnote 共有
    case at = "mention"
    case checkbox = "checkbox"
    case checkList
    case transTask
    case search = "search"
    case delete = "delete"
    case rename = "rename"
    case bold = "bold"
    case italic = "italic"
    case underline = "underline"
    case strikethrough = "strikethrough"
    case insertImage = "insertImage"
    case copy = "copy"


    // doc mindnote 通用
    case h1 = "h1"
    case h2 = "h2"
    case h3 = "h3"
    case insertSeparator = "insertSeparator"
    case comment = "comment"
    case reminder = "reminder"       // docs 工具栏的 reminder，📅
    case keyboard = "keyboard" // 收起键盘按钮
    case highlight = "highlight"
    case oldHighlight = "oldHighlight"


    // MARK: doc 独有
    case paste = "paste"
    case cut = "cut"
    case clear = "clear"
    case pencilkit = "pencilKit"
    case separator = "separator" // 分割线
    // 标题
    case plainText = "plainText"
    case h4 = "h4"
    case h5 = "h5"
    case h6 = "h6"
    case h7 = "h7"
    case h8 = "h8"
    case h9 = "h9"
    case hn = "hn"
    // 文本样式
    case orderedlist = "orderedList"
    case unorderedlist = "unorderedList"
    case indentLeft  = "indentLeft"
    case indentRight  = "indentRight"
    case inlinecode = "inlineCode"
    case codelist = "codeList"
    case blockquote = "blockQuote"
    case attr = "attribution"
    case equation = "equation"
    case calloutBlock = "calloutBlock"
    case addNewBlock = "addNewBlock"
    case mentionUser = "mentionUser"
    case mentionChat = "mentionChat"
    case mentionFile = "mentionFile"
    case insertFile = "insertFile"
    case insertTable = "insertTable"
    case insertCalendar = "insertCalendar"
    case insertReminder = "insertReminder"
    case blockTransform = "blockTransform"
    case textTransform = "textTransform"
    case alignTransform = "alignTransform"
    case alignleft = "alignLeft"
    case aligncenter = "alignCenter"
    case alignright = "alignRight"
    case sheetTxtAtt = "textAttribute"
    case sheetCellAtt = "cellAttribute"
    case sheetCloseToolbar = "closeToolbar"
    case insertTask = "insertTask"
    case insertSheet = "insertSheet"
    case insertBitable = "insertBitable"
    case insertMindnote = "insertMindnote"

    // MARK: docx 独有
    case normalText = "normalText"
    case moveUpBlock = "moveUpBlock"
    case moveDownBlock = "moveDownBlock"
    case selectAllBlock = "selectAllBlock"
    case commentAction = "commentAction"
    case textHighLight = "textHighLight"
    case hyperLink = "hyperLink"
    case insertAgenda = "insertAgenda"
    case insertTaskList = "insertTaskList"
    
    // MARK: sheet 独有
    // 新建工作表
    case createSheet = "create_sheet"
    case createGrid = "create_grid"
    case createKanban = "create_kanban"
    case createBitable = "create_bitable"

    // 工具栏
    case systemText = "text" // sheet ABC 键盘
    case customNumber = "number" // sheet 数字键盘
    case customDate = "date" // sheet 日期键盘
    case editInCard = "editRowInCard" // sheet 按行填写
    
    // 插入面板
    case uploadImage = "uploadImage"
    case addReminder = "addReminder" // sheets 工具箱的 reminder，⏰
    case insertComment = "insertComment"
    case syncedSource = "syncedSource" //同步块

    // 操作面板
    case addRowColumn = "addRowColumn" // 下面四个的 groupID
    case addRowUp = "addRowUp"
    case addRowDown = "addRowDown"
    case addColLeft = "addColLeft"
    case addColRight = "addColRight"

    case operateRowColumn = "operateRowColumn" // 下面的 groupID
    case deleteRow = "deleteRow"
    case deleteCol = "deleteCol"
    case cellMerge = "merge"
    
    case myAiDataInsight = "myAiDataInsight" //MyAI独自成组
    
    case cellFilter = "filter"
    case freeze = "freezeSheet"

    // 下面的用 "filter" 做 groupID
    case cellFilterByValue = "filterValue"
    case cellFilterByColor = "filterColor"
    case cellFilterByCondition = "filterCondition"
    case filterByCell = "filterByCell"
    case cancelFilterByCell = "cancelFilterByCell"
    case cellFilterClear = "filterClear" // 取消筛选按钮
    
    // 下面的用 "freezeSheet" 做 groupID
    case freezeRow = "freezeToRow"
    case freezeCol = "freezeToCol"
    case tmpToggleFreeze = "tmpToggleFrozenArea"
    
    case exportImage = "shareImage" // 一键生图独自成组
    
    // 样式面板
    case bius = "bius"
    
    case textAlignment = "textAlignment" // 下面的 groupID
    case horizontalLeft =  "horizontalLeft"
    case horizontalCenter = "horizontalCenter"
    case horizontalRight = "horizontalRight"
    case verticalTop = "verticalTop"
    case verticalCenter = "verticalCenter"
    case verticalBottom = "verticalBottom"
    
    case lineBreakMode = "linkBreakMode" // 下面的 groupID
    case overflow = "overflow"
    case autoWrap = "autoWrap"
    case clip = "clip"
    
    case cellAttributes = "cellAttributes" // 下面的 groupID
    case borderLine = "borderLine"
    case foreColor = "foreColor"
    case backColor = "backColor"
    case fontSize = "fontSize"

    
    // MARK: mindnote 独有
    case undo = "undo"
    case redo = "redo"
    case mnTextAtt = "mnAttribute"
    case mnTextFormat = "mnTextFormat"
    case mnTextStyle = "mnTextStyle"
    case mnHighlight1 = "mnHighlight_1"
    case mnHighlight2 = "mnHighlight_2"
    case mnHighlight3 = "mnHighlight_3"
    case mnHighlight4 = "mnHighlight_4"
    case mnHighlight5 = "mnHighlight_5"
    case mnHighlight6 = "mnHighlight_6"
    case mnHighlight7 = "mnHighlight_7"
    case mnFinish  = "finish"
    case mnNote    = "note"
    case mnIndent  = "indent"
    case mnOutdent = "outdent"
    
    // MARK: 小程序 独有
    case okr  = "insertOkrBlock"
    
    // MARK: AI入口
    case ai = "inlineAI"
    // MARK: 文件夹block
    case folderBlock = "insertFolderManager"
}

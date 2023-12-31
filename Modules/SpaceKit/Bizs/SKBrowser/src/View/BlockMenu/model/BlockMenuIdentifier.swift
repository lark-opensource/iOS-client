//
//  BlockMenuIdIdentify.swift
//  SKDoc
//
//  Created by zoujie on 2021/1/20.
//  

import SKFoundation

public enum BlockMenuPanelId: String {
    case blockMenuPanel //一级block菜单
    case toolBarMenuPanel //二级block编辑菜单
    case highlightPanel //高亮色面板
    case reactionPanel //reaction面板
    case visionMenuPanel //二级视图菜单
    case alignMenuPanel //二级对齐菜单
    case fileMorePanel //fileBlock二级菜单
}

///旧版Block菜单ID
public enum BlockMenuIdentifier: String {
    case cut           = "CUT"
    case copy          = "COPY"
    case comment       = "COMMENT"
    case delete        = "DELETE"
    case copyLink      = "COPY_LINK"
    case debugCreator  = "DEBUG_CREATOR"
    case debugBlock    = "DEBUG_BLOCK"
    case refreshBlock  = "REFRESH_BLOCK"
    case contentReaction = "CONTENT_REACTION" // 正文表情回应
}

///新版Block菜单ID
public enum BlockMenuV2Identifier: String {

    case style
    case cut
    case copy
    case comment
    case delete
    case copyLink
    case align
    case editPencilKit
    case focusTask
    case checkDetails
    case cancelRealtimeReference
    case cancelSyncTask
    case more
    case contentReaction // 正文表情回应
    case inlineAI
    case translate


    // 标题
    case plainText
    case h1
    case h2
    case h3
    case h4
    case h5
    case h6
    case h7
    case h8
    case h9
    case hn

//    case view
//    case cardView
//    case textView
//    case preView

    case separator

    // 文本样式
    case blockquote
    case codelist
    case inlinecode

    case checkbox
    case checkList
    case insertorderedlist
    case insertunorderedlist
    case insertcodeblock

    case bold
    case italic
    case underline
    case strikethrough
    case highlight
    case blockbackground

    // ===排版样式===
    // 缩进
    case indentright
    case indentleft
    
    // blockedit菜单对齐
    case alignleft
    case aligncenter
    case alignright

    // block菜单对齐
    case blockalignleft
    case blockaligncenter
    case blockalignright

    // group
    case indentTransform // 缩进
    case textTransform // 文本样式
    case alignTransform // 对齐样式
    case textBlockTransform //标题组
    
    //fileBlock
    case fileDownload //文件下载
    case fileOpenWith //其他应用打开
    case fileSaveToDrive //保存到云盘
    
    //image
    case caption //图片备注
    
    case syncedSource //同步块
    case forward //转发
    case newLineBelow //插入空行
    case addTime
    case editTime
    case startTime
    case pauseTime
}

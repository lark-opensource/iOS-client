// longweiwei

import Foundation

protocol MailJSServiceHandler: EditorJSServiceHandler {
}

// JSService 文档 https://wiki.bytedance.net/pages/viewpage.action?pageId=145996596
struct EditorJSService: Hashable, RawRepresentable {
    var rawValue: String
    init(_ str: String) {
        self.rawValue = str
    }

    init(rawValue: String) {
        self.init(rawValue)
    }

    static func == (lhs: EditorJSService, rhs: EditorJSService) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
    // lark.biz.sync.
    static let getHtml = EditorJSService("biz.core.getHtml")
    static let getText = EditorJSService("window.getText")

    /// util etc
    static let utilFailEvent = EditorJSService("biz.util.failEvent")
    static let utilProfile = EditorJSService("biz.util.showProfile")
    static let utilSyncComplete = EditorJSService("biz.util.syncComplete")
    static let utilShowMessage = EditorJSService("biz.util.showMessage")
    static let utilAtShowTips = EditorJSService("biz.util.showTips")
    static let utilAtHideTips = EditorJSService("biz.util.hideTips")
    static let utilTitleSetOfflineName = EditorJSService("biz.util.setOfflineName")
    static let utilFilePreview = EditorJSService("biz.util.fileClick")
    static let utilShowLoading = EditorJSService("biz.util.showLoading")
    static let utilHideLoadingOverTime = EditorJSService("biz.util.hideLoadingOvertime")
    static let utilAtFinder = EditorJSService("biz.util.atfinder")
    static let utilShowMenu = EditorJSService("biz.util.showBottomMenu")

    // navigation
    static let navToolBar = EditorJSService("biz.navigation.setToolBar")
    static let docToolBar = EditorJSService("biz.navigation.setDocToolbar")
    static let navTitle = EditorJSService("biz.navigation.setTitle")
    static let navMenu = EditorJSService("biz.navigation.setMenu")
    static let onSelectionChanged = EditorJSService("biz.selection.onSelectionChanged")
    static let navRequestCustomContextMenu = EditorJSService("window.lark.biz.navigation.requestCustomContextMenu()")
    static let navShowCustomContextMenu = EditorJSService("biz.navigation.showCustomContextMenu")
    static let navSetCustomMenu = EditorJSService("biz.navigation.setCustomContextMenu")
    static let navCloseCustomMenu = EditorJSService("biz.navigation.closeCustomContextMenu")

    // 手势
    static let selectionLongPress = EditorJSService("javascript:window.lark.biz.selection.longPressSelect('%.2f','%.2f')")
    static let selectionStart = EditorJSService("window.lark.biz.selection.dragSelectionStart('%.2f','%.2f')")
    static let selectionChange = EditorJSService("window.lark.biz.selection.dragSelectionEnd('%.2f','%.2f')")
    static let selectionFinish = EditorJSService("window.lark.biz.selection.dragFinish()")

    // handle click
    static let navClickSelect = EditorJSService("biz.navigation.handleSelectMenuClick")
    static let navClickSelectAll = EditorJSService("biz.navigation.handleSelectAllMenuClick")
    static let navClickCut = EditorJSService("biz.navigation.handleCutMenuClick")
    static let navClickCopy = EditorJSService("biz.navigation.handleCopyMenuClick")
    static let navClickPaste = EditorJSService("biz.navigation.handlePasteMenuClick")

    // 剪贴板
    static let clipboardSetContent = EditorJSService("biz.clipboard.setContent")
    static let clipboardGetContent = EditorJSService("biz.clipboard.getContent")

    // notify
    static let notifyHeight = EditorJSService("biz.notify.sendChangedHeight")

    // comment
//    static let commentShowCards           = EditorJSService("biz.comment.showCards")
//    static let commentShowInput           = EditorJSService("biz.comment.showInput")
//    static let commentHideInput           = EditorJSService("biz.comment.hideInput")
//    static let commentFeedShowMsg         = EditorJSService("biz.feed.showMessages")
//    static let commentUpdateResolveStatus = EditorJSService("biz.comment.updateResolveStatusResult")

    // report
    static let reportReportEvent = EditorJSService("biz.statistics.reportEvent")
    static let reportSendEvent = EditorJSService("biz.statistics.sendEvent")

    // sheet
//    static let sheetCloseEditor = EditorJSService("biz.sheet.closeEditor")
//    static let sheetOpenEditor  = EditorJSService("biz.sheet.openEditor")

    // long pic
//    static let screenShot      = EditorJSService("biz.doc.screenshot")
//    static let screenShotReady = EditorJSService("biz.doc.screenshotReady")
//    static let screenShotStart = EditorJSService("biz.doc.screenshotStart")

    /// keyboard
    /// 图片
    static let pickImage = EditorJSService("biz.util.selectImage")
    static let uploadImage = EditorJSService("biz.util.uploadImage")

    static let utilShowPartialLoading = EditorJSService("biz.util.showPartialLoading")
    static let utilHidePartialLoading = EditorJSService("biz.util.hidePartialLoading")
    static let utilShowContextMenu = EditorJSService("biz.util.showContextMenu")
    static let utilOpenLikeList = EditorJSService("biz.util.openlikesList")

    /// 开始编辑
    static let utilBeginEdit = EditorJSService("biz.doc.beginEdit")

    /// 设置键盘触发信息
    static let setKeyboardInfo = EditorJSService("biz.util.setKeyboardInfo")

    /// 隐藏/显示 title bar
    static let toggleTitleBar = EditorJSService("biz.util.toggleTitlebar")

    /// 保存图片
    static let save2Image = EditorJSService("biz.util.save2Image")

    // 图片查看器中的评论
//    static let setOuterDocData = EditorJSService("biz.comment.showOuterDocCards")
    // 图片查看器中的删除
//    static let utilDeleteImg = EditorJSService("biz.util.deleteImgCallback")

//    static let shareService = EditorJSService("biz.util.share")
//    static let moreEvent    = EditorJSService("biz.util.more")
    // History
    static let historyEvent = EditorJSService("biz.history.show")
    // Search
//    static let search             = EditorJSService("biz.content.search")
//    static let switchSearchResult = EditorJSService("biz.content.switchSearchResult")
//    static let clearSearchResult  = EditorJSService("biz.content.clearSearchResult")
//    static let updateSearchResult = EditorJSService("biz.content.updateSearchResult")

    static let fetchReadingData = EditorJSService("window.lark.biz.content.requestFileInfo()")
    static let receiveReadingData = EditorJSService("biz.content.setFileInfo")
    static let createDocument = EditorJSService("biz.util.create")

    //    //RN
    //    static let rnSendMsg   = EditorJSService("biz.rn.sendMessage")
    //    static let rnHandleMsg = EditorJSService("biz.rn.handleMessage")
    //    static let rnReload = EditorJSService("biz.rn.reload")

    // Sheet ContentInset适配
    static let setPadding = EditorJSService("window.lark.biz.viewport.setPadding")
    static let getPadding = EditorJSService("window.lark.biz.viewport.getPadding")
    static let saveScrollPos = EditorJSService("biz.util.saveScrollPos")
    static let reminderSetting = EditorJSService("biz.reminder.showSettingsPage")
    static let navSetName = EditorJSService("biz.navigation.setName")

    // 目录
    static let catalogDisplay = EditorJSService("biz.navigation.setDocumentStructure")
    static let catalogJump = EditorJSService("window.lark.biz.navigation.jump()")
}

/// 给 JS 的回调函数
struct EditorlJSCallBack: Hashable, RawRepresentable {
    var rawValue: String
    init(_ str: String) {
        self.rawValue = str
    }

    init(rawValue: String) {
        self.init(rawValue)
    }

    static func == (lhs: EditorlJSCallBack, rhs: EditorlJSCallBack) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    static let hideComment = EditorlJSCallBack("lark.biz.comment.onPanelHide()") // 评论卡片收起来了
    static let atFinderNoResult = EditorlJSCallBack("lark.biz.util.atfinderSearchNoResult()") // 文档中@人，找不到推荐的人
    static let jumpFragment = EditorlJSCallBack("window.lark.biz.navigation.jump('%@')") // 文档中@人，找不到推荐的人
    static let renderCachedHtml = EditorlJSCallBack("window.renderCacheHTML(%@)") // 给缓存的html到前端
}

//
//  DocsJSService.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2019/9/12.
//  https://wiki.bytedance.net/pages/viewpage.action?pageId=145996596
//  swiftlint:disable operator_usage_whitespace file_length

import Foundation

public struct DocsJSService: Hashable, RawRepresentable {
    public var rawValue: String
    public init(_ str: String) {
        self.rawValue = str
    }

    public init(rawValue: String) {
        self.init(rawValue)
    }

    public static func == (lhs: DocsJSService, rhs: DocsJSService) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

// MARK: - util
extension DocsJSService {
    public static let utilFetch                      = DocsJSService("biz.util.fetch")
    public static let utilFetchSSR                   = DocsJSService("biz.util.fetchSSR")
    public static let utilLogger                     = DocsJSService("biz.util.logger")
    public static let utilBatchLogger                = DocsJSService("biz.util.batchLogger") // 前端日志聚合
    public static let utilAlert                      = DocsJSService("biz.util.showAlert")
    public static let utilImpactEffect               = DocsJSService("biz.util.triggerShake")
    public static let utilShowToast                  = DocsJSService("biz.util.showToast")
    public static let utilHideToast                  = DocsJSService("biz.util.hideToast")
    public static let utilShowActionSheet            = DocsJSService("biz.util.showActionSheet")
    public static let utilHideLoading                = DocsJSService("biz.util.hideLoading")
    public static let utilKeyboard                   = DocsJSService("biz.util.showKeyboard")
    public static let utilUpdateDocInfo              = DocsJSService("biz.util.updateDocInfo")
    public static let utilFailEvent                  = DocsJSService("biz.util.failEvent")
    public static let utilProfile                    = DocsJSService("biz.util.showProfile")
    public static let utilSyncComplete               = DocsJSService("biz.util.syncComplete")
    public static let utilShowMessage                = DocsJSService("biz.util.showMessage")
    public static let utilHiddenMessage              = DocsJSService("biz.util.hideMessage")
    public static let utilAtShowTips                 = DocsJSService("biz.util.showTips")
    public static let utilAtHideTips                 = DocsJSService("biz.util.hideTips")
    public static let utilTitleSetOfflineName        = DocsJSService("biz.util.setOfflineName")
    public static let utilFilePreview                = DocsJSService("biz.util.fileClick")
    public static let utilAttachFilePreview          = DocsJSService("biz.util.attachFileClick")
    public static let utilShowLoading                = DocsJSService("biz.util.showLoading")
    public static let utilHideLoadingOverTime        = DocsJSService("biz.util.hideLoadingOvertime")
    public static let utilAtFinder                   = DocsJSService("biz.util.atfinder")
    public static let utilAtFinderReceiveTabAction   = DocsJSService("biz.util.atFinderReceiveTabAction")
    public static let utilGetIPadViewMode            = DocsJSService("biz.util.getIPadViewMode")
    public static let utilShowMenu                   = DocsJSService("biz.util.showBottomMenu")
    public static let utilShowPartialLoading         = DocsJSService("biz.util.showPartialLoading")
    public static let utilHidePartialLoading         = DocsJSService("biz.util.hidePartialLoading")
    public static let utilShowContextMenu            = DocsJSService("biz.util.showContextMenu")
    public static let utilOpenLikeList               = DocsJSService("biz.util.openlikesList")
    public static let utilPerformAction              = DocsJSService("biz.util.performAction")
    public static let utilGetSSRScrollPosition       = DocsJSService("biz.util.getSSRScrollPos")
    public static let showTranslationLoding          = DocsJSService("biz.util.showSmallLoading")
    public static let hideTranslationLoding          = DocsJSService("biz.util.hideSmallLoading")
    public static let translateWebViewEnableScroll   = DocsJSService("biz.util.setEnableScroll")
    public static let shareService                   = DocsJSService("biz.util.share")
    public static let exportLoading                  = DocsJSService("biz.util.loading")
    public static let showQuotaDialog                = DocsJSService("biz.util.showFullQuoteDialog")
    public static let keyDownRecord                  = DocsJSService("biz.util.inputTimeRecord")

    public static let secretSetting                  = DocsJSService("biz.util.secret")
    public static let moreEvent                      = DocsJSService("biz.util.more")
    public static let createDocument                 = DocsJSService("biz.util.create")
    public static let saveScrollPos                  = DocsJSService("biz.util.saveScrollPos")
    public static let showOperationPanel             = DocsJSService("biz.util.showOperationPanel")
    public static let showBottomPopup                = DocsJSService("biz.util.showBottomPopup")
    public static let offlineCreateDocs              = DocsJSService("biz.util.getOfflineCreatedDoc")
    public static let setStatus                      = DocsJSService("biz.util.setStatus")
    public static let onKeyboardChanged              = DocsJSService("biz.util.onKeyboardChanged")
    /// image
    public static let utilOpenImage                  = DocsJSService("biz.util.openImg")
    public static let pickImage                      = DocsJSService("biz.util.selectImage")
    public static let selectMedia                    = DocsJSService("biz.util.selectMedia")
    public static let selectFile                     = DocsJSService("biz.util.selectFile")
    public static let pickH5Image                    = DocsJSService("biz.util.selectH5Image")
    public static let getLocalImage                  = DocsJSService("biz.util.getLocalImageSource")
    public static let uploadImage                    = DocsJSService("biz.util.uploadImage")
    public static let uploadFile                     = DocsJSService("biz.util.uploadFile")
    public static let cancelUploadFile               = DocsJSService("biz.util.cancelUploadFile")
    public static let closeImageViewer               = DocsJSService("biz.util.closeImgViewer")
    public static let pickDiagramData                = DocsJSService("biz.util.sendDiagramBase64Data")
    /// cache
    public static let utilSetData                    = DocsJSService("biz.util.setData")
    public static let utilGetData                    = DocsJSService("biz.util.getData")
    public static let collectData                    = DocsJSService("biz.util.collectData")
    /// 通用小型数据接口
    public static let setKeyValue                    = DocsJSService("biz.util.setPreference")
    public static let getKeyValue                    = DocsJSService("biz.util.getPreference")
    ////  展示权限设置面板
    public static let permissionPanel                = DocsJSService("biz.permission.openSettingPanel")
    /// 引导
    public static let userGuide                      = DocsJSService("biz.util.showUserGuide")
    /// 用户权限
    public static let userDocPermission              = DocsJSService("biz.util.notifyPermissionChange")
    /// 设置键盘触发信息
    public static let setKeyboardInfo                = DocsJSService("biz.util.setKeyboardInfo")
    public static let keyboardHeight                 = DocsJSService("biz.util.keyboardHeight")
    /// 隐藏/显示 title bar
    public static let toggleTitleBar                 = DocsJSService("biz.util.toggleTitlebar")
    /// 前端获取title bar 遮挡webview的高度
    public static let getWebViewCoverHeight          = DocsJSService("biz.util.getWebViewCoverHeight")
    /// 开启/关闭 左滑退出
    public static let toggleSwipeGesture             = DocsJSService("biz.util.toggleSwipeGesture")
    /// 保存图片
    public static let save2Image                     = DocsJSService("biz.util.save2Image")
    /// 退出 VC Follow 附件预览
    public static let exitFile                       = DocsJSService("biz.util.exitFile")
    /// 退出 VC Follow 附件预览 New
    public static let exitAttachFile                 = DocsJSService("biz.util.exitAttachFile")
    /// 图片查看器中的删除
    public static let utilDeleteImg                  = DocsJSService("biz.util.deleteImgCallback")
    /// 前端通知初始化完毕，等待iOS告知其可以弹起键盘
    public static let notifySetFocusableReady        = DocsJSService("biz.util.notifySetFocusableReady")
    /// 标题栏是否常驻
    public static let navBarFixedShowing             = DocsJSService("biz.util.fixedTitleBar")
    /// sheet 导出
    public static let sheetShowSnapshotAlert         = DocsJSService("biz.util.showImageAlert")
    public static let sheetShowShareOpreationList    = DocsJSService("biz.util.showShareOpreationList")
    public static let sheetHideShareOpreationList    = DocsJSService("biz.util.hideShareOpreationList")
    /// 记录位置
    public static let getPositionKeeperStatus        = DocsJSService("biz.util.getPositionKeeperStatus")
    /// native 从后台获取的DomainConfig，如果FE没有，他们会找我们要一遍，如果我们本地没有会请求后台去拉
    public static let utilFetchDomainConfig          = DocsJSService("biz.util.fetchDomainConfig")
    /// 获取主端配置传递给前端
    public static let getAppSetting                  = DocsJSService("biz.util.getAppSetting")
    /// Obtain CodeBlockLanguages
    public static let codeBlockLanguages             = DocsJSService("biz.util.selectCodeBlockLanguage")
    /// 通知ipad新版评论状态
    public static let simulateCommentStateChange     = DocsJSService("biz.comment.simulateCommentStateChange")
    /// 获取iPad browserVC宽高信息
    public static let getIpadLayoutInfo              = DocsJSService("biz.util.getIpadLayoutInfo")
    ///通用的显示more面板（目前群公告和一事一档都在用）
    public static let showMoreDialog                 = DocsJSService("biz.navigation.showMoreDialog")
    ///群公告发布
    public static let announcementPublish            = DocsJSService("biz.announcement.publish")
    ///群公告弹出操作选择框
    public static let announcementPublishAlert       = DocsJSService("biz.announcement.publishAlert")
    ///群公告内唤起模版中心
    public static let setTemplate                    = DocsJSService("biz.announcement.setTemplate")
    ///群公告页面显示变化通知前端
    public static let templateHidden                 = DocsJSService("biz.announcement.onTemplateHidden")
    public static let exitDocument                   = DocsJSService("biz.util.exitDocument")
    /// 前端控制退出当前文档页面
    public static let backPrePage                    = DocsJSService("biz.util.backPrePage")
    
    public static let searchAssignee                 = DocsJSService("biz.util.searchAssignee")
    public static let showTaskAssignee               = DocsJSService("biz.util.showTaskAssignee")
    public static let showCreateTask                = DocsJSService("biz.util.showCreateTask")
    
    /// 密级引导了解详情
    public static let secretLevelNewbieLearnMore     = DocsJSService("biz.util.secretLevelNewbieLearnMore")
    /// 获取文档mg域名相关
    public static let getMgDomainConfig              = DocsJSService("biz.util.getMgDomainConfig")
    /// 用户前置信息，用户列表
    public static let utilShowUserList               = DocsJSService("biz.docInfo.showList")
    /// 获取当前用户信息
    public static let getCurrentUserInfo             = DocsJSService("biz.util.getCurrentUserInfo")
    /// 显示Time Picker
    public static let showTimePicker                 = DocsJSService("biz.util.showTimePicker")
    /// 前端检查当前文档同步状态（文档打开完成调用）
    public static let utilCheckSyncState             = DocsJSService("biz.util.checkSyncState")
    ///  reload
    public static let reload                         = DocsJSService("biz.util.reload")
    
}

// MARK: - navigation
extension DocsJSService {
    public static let navSetName                     = DocsJSService("biz.navigation.setName")
    public static let navTitle                       = DocsJSService("biz.navigation.setTitle")
    public static let sheetShowTitle                 = DocsJSService("biz.navigation.showTitle")
    public static let sheetHideTitle                 = DocsJSService("biz.navigation.hideTitle")
    public static let navMenu                        = DocsJSService("biz.navigation.setMenu")
    public static let navShowCustomContextMenu       = DocsJSService("biz.navigation.showCustomContextMenu")
    public static let navSetCustomMenu               = DocsJSService("biz.navigation.setCustomContextMenu")
    public static let navCloseCustomMenu             = DocsJSService("biz.navigation.closeCustomContextMenu")
    public static let navShowShortcutMenu            = DocsJSService("biz.navigation.showShortcutMenu")
    public static let navCloseShortcutMenu           = DocsJSService("biz.navigation.closeShortcutMenu")
    ///native通知前端关闭Block菜单
    public static let closeBlockMenuPanel            = DocsJSService("biz.navigation.closeBlockMenuPanel")
    ///前端设置Block菜单项
    public static let setBlockMenuPanelItems         = DocsJSService("biz.navigation.setBlockMenuPanelItems")
    /// handle click
    public static let navClickSelect                 = DocsJSService("biz.navigation.handleSelectMenuClick")
    public static let navClickSelectAll              = DocsJSService("biz.navigation.handleSelectAllMenuClick")
    public static let navClickCut                    = DocsJSService("biz.navigation.handleCutMenuClick")
    public static let navClickCopy                   = DocsJSService("biz.navigation.handleCopyMenuClick")
    public static let navClickPaste                  = DocsJSService("biz.navigation.handlePasteMenuClick")
    public static let navClickTranslate              = DocsJSService("biz.selection.triggerTranslate")

    // toolbar
    public static let navToolBar                     = DocsJSService("biz.navigation.setToolBar")
    public static let docToolBar                     = DocsJSService("biz.navigation.setDocToolbar")
    public static let sheetToolBar                   = DocsJSService("biz.navigation.setSheetToolbar")
    public static let mindnoteToolBar                = DocsJSService("biz.navigation.setMindnoteToolbar")
    // 目录
    public static let catalogDisplay                 = DocsJSService("biz.navigation.setDocumentStructure")
    public static let ipadCatalogDisplay             = DocsJSService("biz.navigation.ipadCatalogDisplay")
    public static let iPadCatalogButtonState         = DocsJSService("biz.navigation.setIPadCatalogState")
    public static let setActiveCatalogItem           = DocsJSService("biz.catalog.setActiveCatalogueItem")
    public static let setCatalogVisible              = DocsJSService("biz.catalog.setVisible") // iPad前端控制目录是否显示
    public static let getIPadInitialStatus           = DocsJSService("biz.util.getIPadInitialStatus")
    /// sheet 退出导出
    public static let sheetExitPreview               = DocsJSService("biz.navigation.exit")
    /// 设置header， 一般使用于 Block 全屏
    public static let setCustomHeader                = DocsJSService("biz.navigation.setCustomHeader")
    /// 自定义 icon
    public static let selectIcon                     = DocsJSService("biz.navigation.selectIcon")
    ///pencilkit
    public static let changePencilKit                = DocsJSService("biz.util.changePencilKit")
    public static let alertDeletePencilKit           = DocsJSService("biz.util.alertDeletePencilKit")
    public static let alertUpdatePencilKit           = DocsJSService("biz.util.alertUpdatePencilKit")
    public static let uploadCanvas                   = DocsJSService("biz.util.uploadCanvas")
}

// MARK: - device
extension DocsJSService {
    public static let orientationControl             = DocsJSService("biz.control.functions")
    public static let getInfo                        = DocsJSService("biz.device.getInfo")
}

// MARK: - sheet
extension DocsJSService {
    public static let sheetCloseEditor               = DocsJSService("biz.sheet.closeEditor")
    public static let sheetOpenEditor                = DocsJSService("biz.sheet.openEditor")
    public static let sheetOperationPanel            = DocsJSService("biz.sheet.operationPanel")
    public static let sheetClearBorderLinePanel      = DocsJSService("biz.sheet.clearBorderLinePanel")
    public static let sheetFABButtons                = DocsJSService("biz.sheet.setFabButtons")
    public static let sheetToolkit                   = DocsJSService("biz.sheet.setSheetToolkit")
    public static let sheetFilter                    = DocsJSService("biz.sheet.setFilter")
    public static let sheetShowInput                 = DocsJSService("biz.sheet.showInput")
    public static let sheetSetTabs                   = DocsJSService("biz.sheet.setSheetTabs")
    public static let sheetTabOperation              = DocsJSService("biz.sheet.setSheetModal")
    public static let sheetShowReminder              = DocsJSService("biz.sheet.showReminderPanel")
    public static let sheetCardModeNavBar            = DocsJSService("biz.sheet.setCardModeNavBar")
    public static let sheetShowLoading               = DocsJSService("biz.sheet.showLoading")
    public static let sheetHideLoading               = DocsJSService("biz.sheet.hideLoading")
    public static let sheetPrepareWriteImage         = DocsJSService("biz.sheet.ShareImageDataMeta")
    public static let sheetReceiveImageData          = DocsJSService("biz.sheet.ShareImageData")
    public static let sheetShowDropdown              = DocsJSService("biz.sheet.showDropdown")
    public static let sheetHideDropdown              = DocsJSService("biz.sheet.hideDropdown")
    public static let sheetShowAttachmentList        = DocsJSService("biz.sheet.showAttachmentList")
    public static let notifySnapshotAction           = DocsJSService("biz.sheet.onScreenShot")
    public static let sheetGetSharePanelHeight       = DocsJSService("biz.sheet.shareOpreationViewMessage")
    public static let sheetStopTransferImage         = DocsJSService("biz.sheet.stopTransferImage")
    public static let sheetExportShare               = DocsJSService("biz.sheet.exportShare")
    public static let sheetShowCellContent           = DocsJSService("biz.sheet.showCellContent")
    public static let sheetGetWatermarkInfo          = DocsJSService("biz.sheet.getWatermarkInfo")
}

// MARK: - slide
extension DocsJSService {
    public static let slideExportSelect              = DocsJSService("biz.slide.slideExportSelect")
    public static let slideExportResponse            = DocsJSService("biz.slide.exportResponse")
    public static let slideScrollBarMove             = DocsJSService("biz.slide.onScrollBarMove")
    public static let slideDownloadFont              = DocsJSService("biz.slide.downloadFont")
    public static let slideEntryPaly                 = DocsJSService("biz.slide.entryShow")
    public static let slideExitPaly                  = DocsJSService("biz.slide.exitShow")
    public static let clickToggleTitleBar            = DocsJSService("biz.slide.clickToggleTitleBar")
}

// MARK: - content
extension DocsJSService {
    public static let search                         = DocsJSService("biz.content.search")
    public static let sheetOpenSearch                = DocsJSService("biz.content.enterSearch")
    public static let switchSearchResult             = DocsJSService("biz.content.switchSearchResult")
    public static let clearSearchResult              = DocsJSService("biz.content.clearSearchResult")
    public static let updateSearchResult             = DocsJSService("biz.content.updateSearchResult")
    public static let exitSearchResult               = DocsJSService("biz.content.exitSearch")
    public static let receiveWordCount          = DocsJSService("biz.content.setFileInfo")
}

// MARK: - translate
extension DocsJSService {
    public static let setUpTranslation               = DocsJSService("biz.translate.setupTranslation")
    public static let rightBottomFeature             = DocsJSService("biz.translate.setRightBottomMenus") //旧逻辑，3.29版本后废弃，
    public static let setLangMenus                   = DocsJSService("biz.translate.setLangMenus")
    public static let translationContent             = DocsJSService("biz.translate.showOriginalLanguage")
    public static let translateBottomBtnVisible      = DocsJSService("biz.translate.setTranslateLanguageSwitchVisible")
    public static let translateChooseLanguage        = DocsJSService("biz.translate.chooseLanguage")
    public static let getTranslationConfig           = DocsJSService("biz.translate.setConfig")
    // 前端更新 More 面板默认翻译语言
    public static let setTranslationItem             = DocsJSService("biz.translate.setTranslateItem")
    // Native 将翻译配置更新协同推送给前端
    public static let translateSettingChange         = DocsJSService("biz.translate.settingChange")
}

// MARK: - comment
extension DocsJSService {
    public static let commentShowCards               = DocsJSService("biz.comment.showCards")
    public static let commentShowInput               = DocsJSService("biz.comment.showInput")
    public static let commentHideInput               = DocsJSService("biz.comment.hideInput")
    public static let commentResultNotify            = DocsJSService("biz.comment.notifyRequestResult")
    public static let commentUpdateResolveStatus     = DocsJSService("biz.comment.updateResolveStatusResult")
    public static let commentCloseCards              = DocsJSService("biz.comment.closePanel")
    public static let commentSwitchCard              = DocsJSService("biz.comment.activeCards")
    public static let scrollComment              = DocsJSService("biz.comment.scrollComment")
    /// 隐藏评论的表情菜单。
    public static let commentHideReaction        = DocsJSService("biz.comment.commentHideReaction")
    /// 图片查看器中的评论
    public static let setOuterDocData                = DocsJSService("biz.comment.showOuterDocCards")
    public static let commentRequestNative           = DocsJSService("biz.comment.requestNative")
    public static let addCommentEventListener        = DocsJSService("biz.comment.addEventListener")
    /// 打开评论图片图片接口
    public static let openImageForComment            = DocsJSService("biz.comment.openImageForComment")
    public static let simulateCloseCommentImage      = DocsJSService("biz.comment.simulateCloseCommentImage")
    
    /// 为了MS 下解决评论与其他组件的冲突，使用这种方式来进行处理
    /// suppend 是其他地方将评论视图 dismiss 需要下次某个时间段再打开。
    /// resume 是如果暂时关闭期间没有没清除的消息的话就进行重新打开。
    public static let simulateSuppendComment      = DocsJSService("biz.comment.simulateSuppendComment")
    public static let simulateResumeComment       = DocsJSService("biz.comment.simulateResumeComment")
    
    public static let simulateForceCommentPortraint      = DocsJSService("biz.comment.forcePortraint")

    /// 前端获取当前评论UI的显示样式, 返回参数 style: "card"  // card:卡片样式,  embed： 内嵌评论样式
    /// 获取参数中的callback，发生变换时主动通知前端
    public static let switchStyle                    = DocsJSService("biz.comment.switchStyle")
    public static let activateImageChange            = DocsJSService("biz.comment.activateImageChange")
    public static let cancelComment                  = DocsJSService("biz.comment.cancel")
    public static let commentPanelHeightUpdate       = DocsJSService("biz.comment.panelHeightUpdate")
    public static let switchCard                     = DocsJSService("biz.comment.switchCard")
    public static let commonEventListener            = DocsJSService("biz.comment.commonEventListener")

    /// 小程序打开新页面通知
    public static let commentSetEntity               = DocsJSService("biz.comment.setEntity")
    public static let commentRemoveEntity            = DocsJSService("biz.comment.removeEntity")
    /// 前端发送数据 透传到RN
    public static let commentPostMessage             = DocsJSService("biz.comment.postMessage")
    /// RN返回数据后通过lark bridge通知前端
    public static let commentOnMessage               = DocsJSService("biz.comment.onMessage")
    
    /// Docs业务中返回用户id，小程序中返回openId
    public static let updateCurrentUser               = DocsJSService("biz.comment.currentUser")

    public static let commentReportToTea             = DocsJSService("biz.statistics.reportEvent")
    
    public static let commentShowToast               = DocsJSService("biz.comment.showToast")
    
    public static let commentConferenceInfo          = DocsJSService("biz.comment.vcfollow.conferenceInfo")
    
    public static let setCopyUrlTemplate          = DocsJSService("biz.comment.setCopyUrlTemplate")
}

// MARK: - notify
extension DocsJSService {
    public static let notifyReady                    = DocsJSService("biz.notify.ready")
    public static let notifyEvent                    = DocsJSService("biz.notify.event")
    public static let notifyHeight                   = DocsJSService("biz.notify.sendChangedHeight")
    public static let syncDocInfo                    = DocsJSService("biz.notify.syncDocInfo")
    public static let notifyPreloadReady             = DocsJSService("biz.notify.preloadReady")
    public static let notifyClearDone                = DocsJSService("biz.notify.clearDone")
}

// MARK: - doc
extension DocsJSService {
    /// long pic
    public static let screenShot                     = DocsJSService("biz.doc.screenshot")
    public static let screenShotReady                = DocsJSService("biz.doc.screenshotReady")
    public static let screenShotStart                = DocsJSService("biz.doc.screenshotStart")
    /// 前端告诉我们，开始编辑了
    public static let utilBeginEdit                  = DocsJSService("biz.doc.beginEdit")
}

// MARK: - simulate: native 主动跨 service 调用
extension DocsJSService {
    public static let simulateOpenSearch             = DocsJSService("biz.simulate.showLookup")
    public static let simulateKeyboardChange         = DocsJSService("biz.simulate.keyboardHeightChange")
    public static let simulateOpenSheetToolkit       = DocsJSService("biz.simulate.openSheetToolkit")
    public static let simulateFinishPickingImage     = DocsJSService("simulate.image.finishPickingImages")
    public static let simulateCanSetFocusable        = DocsJSService("biz.simulate.setFocusable")
    public static let simulateFinishPickFile         = DocsJSService("biz.simulate.simulatePickFile")
    public static let simulatePickVideo              = DocsJSService("biz.simulate.simulatePickVideo")
    public static let simulateCommentInputViewHeight = DocsJSService("biz.simulate.commentInputViewHeight")
    public static let simulateCommentEntrance        = DocsJSService("biz.simulate.save.commentEntrance")
    public static let simulateClearCommentEntrance        = DocsJSService("biz.simulate.clear.commentEntrance")
}

// MARK: - mindnote
extension DocsJSService {
    public static var mindnoteEditStatus             = DocsJSService("biz.mindnote.updateEditStatus")
    public static let mindnoteShowThemeCard          = DocsJSService("biz.mindnote.showThemeCard")
    public static let mindnoteSetView                = DocsJSService("biz.mindnote.setView")
}

// MARK: - feed
extension DocsJSService {
    public static let fetchMessage                   = DocsJSService("biz.feed.requestNative")
    public static let addFeedEventListener           = DocsJSService("biz.feed.addEventListener")
    public static let feedShowMessage                = DocsJSService("biz.feed.showMessages")
    public static let feedCloseMessage               = DocsJSService("biz.feed.closeMessages")
    public static let commentGetMessageStatus        = DocsJSService("biz.feed.getMessageStatus")
    public static let commentNotifyMessageChange     = DocsJSService("biz.feed.notifyMessageChange")
    public static let feedClosePanel                 = DocsJSService("biz.feed.closePanel")
    public static let readMessages                   = DocsJSService("biz.feed.readMessages")
}

// MARK: - reaction
extension DocsJSService {
    public static let reactionShowDetail             = DocsJSService("biz.reaction.showDetail")
    public static let reactionUpdateDetail           = DocsJSService("biz.reaction.updateDetail")
    public static let reactionUpdateRecent           = DocsJSService("biz.reaction.updateRecent")
    public static let reactionClose                  = DocsJSService("biz.reaction.close")
    /// 返回全文/正文reaction详细信息
    public static let setReactionDetail              = DocsJSService("biz.comment.setReactionDetail")
    /// 拉起正文表情面板
    public static let showContentReactionPanel       = DocsJSService("biz.reaction.showContentReactionPanel")
    /// 关闭正文表情面板
    public static let closeContentReactionPanel      = DocsJSService("biz.reaction.closeContentReactionPanel")
    
    public static let sendCommonLinkToIM            = DocsJSService("biz.common.sendToIm")
}

// MARK: - rn
extension DocsJSService {
    public static let rnSendMsg                      = DocsJSService("biz.rn.sendMessage")
    public static let rnHandleMsg                    = DocsJSService("biz.rn.handleMessage")
    public static let rnReload                       = DocsJSService("biz.rn.reload")
}

// MARK: - clipboard
extension DocsJSService {
    public static let clipboardSetContent            = DocsJSService("biz.clipboard.setContent")
    public static let clipboardSetText               = DocsJSService("biz.clipboard.setText")
    public static let clipboardGetContent            = DocsJSService("biz.clipboard.getContent")
    public static let clipboardGetText               = DocsJSService("biz.clipboard.getText")
    public static let clipboardSetEncryptId          = DocsJSService("biz.clipboard.setEncryptId")
    
}

// MARK: - viewport
extension DocsJSService {
    /// Sheet ContentInset 适配
    public static let setPadding                     = DocsJSService("window.lark.biz.viewport.setPadding")
    public static let getPadding                     = DocsJSService("window.lark.biz.viewport.getPadding")
}

// MARK: - statistics
extension DocsJSService {
    public static let reportReportEvent              = DocsJSService("biz.statistics.reportEvent")
    public static let reportSendEvent                = DocsJSService("biz.statistics.sendEvent")
    public static let baseReport                     = DocsJSService("biz.bitable.report")
}

// MARK: - wiki
extension DocsJSService {
    public static let utilWikiFetchToken             = DocsJSService("biz.wiki.setWikiInfo")
    public static let utilWikiTreeEnable             = DocsJSService("biz.wiki.setWikiTreeEnable")

    public static let wikiRegisterPush               = DocsJSService("biz.wiki.registerPush")
}

// MARK: - history
extension DocsJSService {
    public static let historyEvent                   = DocsJSService("biz.history.show")
}

// MARK: - selection
extension DocsJSService {
    public static let onSelectionChanged             = DocsJSService("biz.selection.onSelectionChanged")
}

// MARK: - preload
extension DocsJSService {
    /// preload html cache
    public static let preLoadHtmlFinish              = DocsJSService("biz.preload.cacheHTMLDone")
}

// MARK: - orientation
extension DocsJSService {
    public static let getOrientation                 = DocsJSService("biz.orientation.getStatus")
}

// MARK: - reminder
extension DocsJSService {
    public static let reminderSetting                = DocsJSService("biz.reminder.showSettingsPage")
}

// MARK: - vcFollow
extension DocsJSService {
    public static let vcFollowOn                     = DocsJSService("biz.vcSdk.onFollow")
    public static let followReady                    = DocsJSService("biz.vcSdk.followReady")
    /// VC Follow RN接口迁移
    public static let sendToNative                   = DocsJSService("biz.vcfollow.sendToNative")
    
    public static let simulateOnRoleChange           = DocsJSService("biz.simulate.onRoleChange")
    
}

// MARK: - Mina
extension DocsJSService {
    // 走 mina 配置平台
    public static let minaConfigChange               = DocsJSService("biz.user.onMinaConfigChange")
}

// MARK: - Bitable
extension DocsJSService {
    // 前端更新一些信息到客户端（用于埋点等）
    public static let updateTableInfo                = DocsJSService("biz.bitable.updateTableInfo")
    
    public static let jiraActionSheet                = DocsJSService("biz.bitable.launchActionSheet")
    public static let updateViewMeta                 = DocsJSService("biz.bitable.updateViewMeta")
    public static let performCardAction              = DocsJSService("biz.bitable.performCardsAction")
    public static let performPanelsAction            = DocsJSService("biz.bitable.performPanelsAction")
    public static let bitableTip                     = DocsJSService("biz.bitable.showTips")
    public static let bitableHideTip                 = DocsJSService("biz.bitable.hideTips")
    public static let bitablePanel                   = DocsJSService("biz.bitable.showPanel")
    public static let bitableFAB                     = DocsJSService("biz.bitable.setFabButtons")
    public static let managerPanel                   = DocsJSService("biz.bitable.managerPanel")
    
    // AI 字段使用的服务
    public static let showAiOnBoarding               = DocsJSService("biz.bitable.showAIOnBoarding")
    public static let setEditPanelVisibility         = DocsJSService("biz.bitable.setEditPanelVisibility")
    
    //设置目录
    public static let setCatalog                     = DocsJSService("biz.bitable.setCatalog")
    public static let formShare                      = DocsJSService("biz.bitable.form.share")
    public static let bitableShare                   = DocsJSService("biz.bitable.share")
    // 查询是否有未完成上传的附件
    public static let getPendingEdit                 = DocsJSService("biz.bitable.getPendingEdit")
    // 通知native开始上传附件 表单&高级权限记录
    public static let startUploadAttachments         = DocsJSService("biz.bitable.startUploadAttachments")
    public static let openFieldEditPanel             = DocsJSService("biz.bitable.openFieldEditPanel")
    
    // bitable 统计浮层面板打开
    public static let openStatPanel                 = DocsJSService("biz.bitable.openStatPanel")
    //bitable分组统计分页请求数据返回
    public static let sendGroupData                  = DocsJSService("biz.bitable.sendGroupData")
    //异步请求数据结果回调
    public static let asyncJsResponse                = DocsJSService("biz.bitable.asyncJsResponse")
    // bitable 高级权限开启/关闭的操作结果回调
    public static let upgradeBaseCompleted           = DocsJSService("biz.bitable.upgradeBaseCompleted")
    //打开底部工具栏
    public static let setBottomToolbar               = DocsJSService("biz.bitable.setBottomToolbar")
    //画册面板附件预览
    public static let openCoverFiles                 = DocsJSService("biz.bitable.openCoverFiles")
    //bitable异步事件通知接口
    public static let btEmitEvent                    = DocsJSService("biz.bitable.emitEvent")
    public static let performNotifyAction            = DocsJSService("biz.bitable.performNotifyAction")
    // 打开高级权限面板
    public static let showProModal                   = DocsJSService("biz.util.showProModal")
    // SSC升级通知Native
    public static let sscUpgradeNotify                   = DocsJSService("biz.bitable.sscUpgradeNotify")
    // 计费使用二级面板所需要的 API
    public static let contactService                 = DocsJSService("biz.bitable.contactService")
    public static let goToProfile                    = DocsJSService("biz.bitable.goToProfile")
    public static let openWebPage                    = DocsJSService("biz.bitable.openWebPage")
    /// 搜索文档（调用大搜接口）
    public static let searchDocument                 = DocsJSService("biz.util.searchDocument")
    // 创建副本前置检查
    public static let checkBitableClone              = DocsJSService("biz.bitable.checkBitableClone")
    // bitable Data Define UI Service
    public static let dduiService                    = DocsJSService("biz.bitable.ddui")
    // LinkedDocx
    public static let showLinkedDocx                 = DocsJSService("biz.bitable.showLinkedDocx")
    public static let hideLinkedDocx                 = DocsJSService("biz.bitable.hideLinkedDocx")
    // 展示/隐藏 header
    public static let showHeader                     = DocsJSService("biz.bitable.showHeader")
    /// 导航栏上点击more唤起Action Menu
    public static let baseMore                       = DocsJSService("biz.bitable.baseMore")
    /// 设置工具栏数据
    public static let setTooBar                      = DocsJSService("biz.bitable.setToolbarContainer")
    /// base框架改版，新目录接口
    public static let setBlockCatalogContainer       = DocsJSService("biz.bitable.setBlockCatalogContainer")
    public static let setHeaderContainer             = DocsJSService("biz.bitable.setHeaderContainer")
    /// 设置视图目录
    public static let setViewContainer               = DocsJSService("biz.bitable.setViewContainer")
    /// 展示视图面板
    public static let showViewPanel                  = DocsJSService("biz.bitable.showViewPanel")
    ///
    public static let updateScene                    = DocsJSService("biz.bitable.updateScene")
    /// 聚合面板
    public static let viewSetting                    = DocsJSService("biz.bitable.viewSetting")
    
    /// native卡片视图
    public static let setCardViewData                = DocsJSService("biz.bitable.setCardViewData")
    /// Web 内容滚动到顶事件
    public static let onWebContentChange             = DocsJSService("biz.bitable.onWebContentChange")
    /// 获取快捷新建记录的数据
    public static let getAddRecordContent            = DocsJSService("biz.bitable.getAddRecordContent")
    /// 获取记录分享的数据
    public static let getRecordContent               = DocsJSService("biz.bitable.getRecordContent")
    /// 发送人员/文本at字段 mention 通知
    public static let sendMention                    = DocsJSService("biz.bitable.sendMention")
}

extension DocsJSService {
    /// FormsAPI
    public static let bitableChooseAttachment = DocsJSService("biz.bitable.chooseAttachment")
    public static let bitableCheckAttachmentValid = DocsJSService("biz.bitable.checkAttachmentValid")
    public static let bitablePreviewAttachment = DocsJSService("biz.bitable.previewAttachment")
    public static let bitableDeleteAttachment = DocsJSService("biz.bitable.deleteAttachment")
    public static let bitableUploadAttachment = DocsJSService("biz.bitable.baseUploadAttachment")
    public static let bitableGetLocation = DocsJSService("biz.bitable.getLocation")
    public static let bitableReverseGeocodeLocation = DocsJSService("biz.bitable.reverseGeocodeLocation")
    public static let bitableChooseLocation = DocsJSService("biz.bitable.chooseLocation")
    public static let bitableOpenLocation = DocsJSService("biz.bitable.openLocation")
    public static let bitableScanCode = DocsJSService("biz.bitable.scanCode")
    public static let openFullScreen = DocsJSService("biz.util.openFullScreen")
    public static let closeFullScreen = DocsJSService("biz.util.closeFullScreen")
    public static let formConfiguration = DocsJSService("biz.bitable.formConfiguration")
    public static let safeArea = DocsJSService("biz.bitable.safeArea")
    public static let formsShare = DocsJSService("biz.forms.share")
    public static let formsUnmount = DocsJSService("biz.forms.formsUnmount")
    public static let chooseContact = DocsJSService("biz.forms.chooseContact")
}

// MARK: - Feature Gating
extension DocsJSService {
    // 走 Lark FG 平台
    public static let fgConfigChange                 = DocsJSService("biz.user.onFGConfigChange")
}

// MARK: - Onboarding
extension DocsJSService {
    public static let getOnboardingStatuses          = DocsJSService("biz.onboarding.getStatuses")
    public static let setOnboardingFinished          = DocsJSService("biz.onboarding.setFinished")
}

// MARK: - 封面
extension DocsJSService {
    public static let showSelectCoverPanel           = DocsJSService("biz.title.selectCover")
}

// MARK: Read/Edit Mode
extension DocsJSService {

    /// EditButton -> setVisible
    public static let editButtonSetVisible          = DocsJSService("biz.editButton.setVisible")
    /// 用户点击屏幕回调，此时应该根据当前状态切换至另一显示模式
    public static let togglgEditMode                = DocsJSService("biz.edit.togglgEditMode")
    /// 显示隐藏完成按钮
    public static let completeButtonSetVisible      = DocsJSService("biz.completeButton.setVisible")
}

// MARK: - Permission
extension DocsJSService {
    /// 前端向客户端注册/注销监听用户对文档的权限，会调用多次
    public static let subscribeUserPermission    = DocsJSService("biz.permission.requestNative")
    /// 前端向客户端提供权限变更时的 callback，只调一次
    public static let addPermissionEventListener = DocsJSService("biz.permission.addEventListener")
    /// 前端向客户端通知预览行为受 TNS 阻断
    public static let notifyBlockByTNS           = DocsJSService("biz.permission.blockByTNS")
}

// MARK: - Appeal
extension DocsJSService {
    //前端传递url,通过webview打开一个新的页面，目前用于申诉页面
    public static let utilShowPage                   = DocsJSService("biz.appeal.showPage")

    // native通知前端DarkMode状态变更，初始化时调用一次
    public static let utilThemeChanged               = DocsJSService("biz.util.theme")
    // SpaceHomeViewController 和 BrowserViewController 的 DarkMode 状态变化的时候，主动通知到前端 Service
    public static let simulateUserInterfaceChanged   = DocsJSService("biz.util.simulateUserInterfaceChanged")
}

// MARK: - DocX
extension DocsJSService {
    //显示Oops弹框
    public static let showOopsDialog                = DocsJSService("biz.util.showOops")
    //关闭Oops弹框
    public static let hideOopsDialog                = DocsJSService("biz.util.hideOops")
    //跳转联系客服
    public static let contactUs                     = DocsJSService("biz.util.contactUs")
    //新建DocX文档
    public static let createDocX                    = DocsJSService("biz.util.createNewPage")
    //DocX编辑阅读态切换
    public static let editStatus                    = DocsJSService("biz.docx.updateEditStatus")
    //关联文档基础信息同步
    public static let blockInfo                     = DocsJSService("biz.util.setBlockInfo")
    //显示同步块引用位置
    public static let showSyncedBlockReferences     = DocsJSService("biz.util.showSyncedBlockReferences")
}

// MARK: - analytic
extension DocsJSService {
    /// 评论&mention 埋点公共参数
    public static let setCommonParams                   = DocsJSService("biz.analytic.setCommonParams")

}

// MARK: - EnterpriseTopic
extension DocsJSService {
    /// EnterpriseTopic
    public static let showEnterpriseTopic = DocsJSService("biz.util.showEnterpriseTopic")
    public static let dismissEnterpriseTopic = DocsJSService("biz.util.dismissEnterpriseTopic")
}

// MARK: - keyboard
extension DocsJSService {
    public static let keyBoardGetType = DocsJSService("biz.keyboard.getType")
}

// MAKR: - HyperLink

extension DocsJSService {
    public static let openEditHyperLinkAlter = DocsJSService("biz.util.addOrEditHyperLink")
}

// MARK: - vote
extension DocsJSService {
    public static let openVoteMembers = DocsJSService("biz.util.openVoteMembers")
    public static let showVoteSelectExpirationDatePanel = DocsJSService("biz.docx.showVoteSelectExpirationDatePanel")
}

// MARK: - InlineAI
extension DocsJSService {
    public static let showInlineAIPanel = DocsJSService("biz.inlineAI.show")
    public static let inlineAIMessage = DocsJSService("biz.inlineAI.message")
    public static let inlineAIInfoList = DocsJSService("biz.inlineAI.infoList")
    public static let simulateHideAIPanel = DocsJSService("biz.inlineAI.simulateHideAIPanel")
    public static let inlineAIFeedback = DocsJSService("biz.inlineAI.feedback")
}

// MARK: - DocComponent
extension DocsJSService {
    public static let invokeNativeForDC = DocsJSService("biz.doccomponent.invokeNative")
}

// MARK: - CommonList
extension DocsJSService {
    public static let commonList = DocsJSService("biz.util.commonList")
}

// MARK: - FolderBlock
extension DocsJSService {
    public static let showSelectionPanel = DocsJSService("biz.util.showSelectionPanel")
    public static let showCreationPanel = DocsJSService("biz.util.showCreationPanel")
    public static let selectFileBlockMedia = DocsJSService("biz.util.selectFileBlockMedia")
    public static let folderBlockMore = DocsJSService("biz.wiki.folderBlockMore")
    public static let getThumbnail = DocsJSService("biz.wiki.getThumbnail")
}

// MARK: - AssociateApp
extension DocsJSService {
    ///关联关系数据获取，接口把关联关系数据给到native
    public static let associateAppUrlInfo = DocsJSService("biz.associateapp.urlInfos")
    ///文档内查看关联的应用
    public static let associateAppShowUrlListPanel = DocsJSService("biz.associateapp.showUrlListPanel")
    ///解除关联的二次弹出
    public static let associateAppShowDisassociateMoreDialog = DocsJSService("biz.associateapp.showDisassociateMoreDialog")
}

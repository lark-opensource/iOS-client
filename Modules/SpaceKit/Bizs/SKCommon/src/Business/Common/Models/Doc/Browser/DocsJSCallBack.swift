//
//  DocsJSCallBack.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2019/9/12.
//  给 JS 的回调函数

import Foundation

public struct DocsJSCallBack: Hashable, RawRepresentable {
    public var rawValue: String
    public init(_ str: String) {
        self.rawValue = str
    }

    public init(rawValue: String) {
        self.init(rawValue)
    }

    public static func == (lhs: DocsJSCallBack, rhs: DocsJSCallBack) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static let atFinderNoResult = DocsJSCallBack("lark.biz.util.atfinderSearchNoResult") // 文档中@人，找不到推荐的人
    public static let catalogSwitchHeading = DocsJSCallBack("lark.biz.headings.switchHeading") //
    public static let navigationJump = DocsJSCallBack("window.lark.biz.navigation.jump")
    public static let renderCachedHtml = DocsJSCallBack("window.renderCacheHTML") // 给缓存的html到前端

    public static let webviewVisibilityChange = DocsJSCallBack("window.lark.biz.util.updateWebviewVisibility")//告诉前端WebviewVisibility改变了

    public static let notifyGuideFinish = DocsJSCallBack("lark.biz.util.finishUserGuide") // 告诉前端完成引导

    public static let appealClick = DocsJSCallBack("lark.biz.appeal.click") //点击申诉

    public static let preLoadHtml = DocsJSCallBack("window.lark.biz.preload.cacheHTML")//告诉前端clientVars,直出html

    public static let publishComment = DocsJSCallBack("lark.biz.comment.publish") // 发送评论
    public static let editComment = DocsJSCallBack("lark.biz.comment.edit")       // 编辑评论
    public static let cancelComment = DocsJSCallBack("lark.biz.comment.cancel")   // 取消评论
    public static let deleteComment = DocsJSCallBack("lark.biz.comment.delete")   // 删除评论
    public static let reaction = DocsJSCallBack("lark.biz.reaction.addReaction") // 增加/减少 Reaction
    public static let getReactionDetail = DocsJSCallBack("lark.biz.reaction.getDetail") // 获取 Reaction 详情
    public static let setDetailPanelStatus = DocsJSCallBack("lark.biz.reaction.setDetailPanelStatus") // 通知前端Reaction详情面板打开状态
    public static let translateComment = DocsJSCallBack("lark.biz.comment.translate") // 手动翻译评论
    public static let switchCard = DocsJSCallBack("lark.biz.comment.switchCard") // 切换评论
    public static let activeComment = DocsJSCallBack("lark.biz.comment.activate")

    public static let reactionGetDetail = DocsJSCallBack("lark.biz.reaction.getDetail")
    public static let setPanelHeight = DocsJSCallBack("lark.biz.util.setPanelHeight")
    public static let updateResolveStatus = DocsJSCallBack("lark.biz.comment.updateResolveStatus")
    public static let deleteImg = DocsJSCallBack("window.native.assetBrowser.deleteImg")

    public static let translateClickAction = DocsJSCallBack("window.lark.biz.translate.translate") //AI翻译
    public static let translateSettingChange = DocsJSCallBack("window.lark.biz.translate.settingChange")
    public static let shortCutMenuStatus = DocsJSCallBack("window.lark.biz.navigation.notifyShortcutMenuStatus") //通知前端block快捷菜单是否展示
    public static let reminderSetDate = DocsJSCallBack("lark.biz.reminder.setDate")
    public static let reminderCancel = DocsJSCallBack("lark.biz.reminder.cancel")
    public static let commentDelete = DocsJSCallBack("lark.biz.comment.delete")

    public static let hideMessages = DocsJSCallBack("lark.biz.feed.hideMessages")
    public static let scrollToMessage = DocsJSCallBack("lark.biz.feed.scrollToMessage")

    public static let fetchWordCount = DocsJSCallBack("window.lark.biz.content.requestFileInfo")
    public static let closeImg = DocsJSCallBack("lark.biz.util.closeImg")
    public static let notityNetStatus = DocsJSCallBack("window.native&&window.native.setNetworkState&&window.native.setNetworkState")
    public static let navRequestCustomContextMenu = DocsJSCallBack("window.lark.biz.navigation.requestCustomContextMenu")
    public static let onHeaderMenuItemLongPress = DocsJSCallBack("window.lark.biz.navigation.onHeaderMenuItemLongPress")
    public static let windowClear = DocsJSCallBack("window.clear")
    public static let windowReload = DocsJSCallBack("window.reload")
    public static let sheetOnUpdateEdit = DocsJSCallBack("window.lark.biz.sheet.onUpdateEdit")
    public static let sheetOnClickToolbarItem = DocsJSCallBack("window.lark.biz.sheet.onToolbarClick")
    public static let cancelFromImageSelector = DocsJSCallBack("window.lark.biz.util.cancelFromImageSelector")

    public static let onSwitchSheet = DocsJSCallBack("window.lark.biz.sheet.onSwitchSheet")
    public static let onScrollBarMove = DocsJSCallBack("window.lark.biz.slide.onScrollBarMove")
    public static let windowRender = DocsJSCallBack("window.render")
    public static let screenShot = DocsJSCallBack("window.native.screenshot")
    public static let slideExport = DocsJSCallBack("window.lark.biz.slide.exportStart")
    public static let slideContentSize = DocsJSCallBack("window.lark.biz.slide.contentSize")
    public static let slideExportGoBack = DocsJSCallBack("window.lark.biz.util.goBack")

    // 手势
    public static let selectionLongPress = DocsJSCallBack("window.lark.biz.selection.longPressSelect")
    public static let selectionstart = DocsJSCallBack("window.lark.biz.selection.dragSelectionStart")
    public static let selectionChange = DocsJSCallBack("window.lark.biz.selection.dragSelectionEnd")
    public static let selectionFinish = DocsJSCallBack("window.lark.biz.selection.dragFinish")

    public static let contextMenuDidHide = DocsJSCallBack("window.lark.biz.sheet.onContextMenuHidden") // 告诉前端 context menu 已经隐藏了，用在sheet
    public static let onContextMenuClose = DocsJSCallBack("window.lark.biz.util.onContextMenuClose") // 告诉前端 context menu 已经隐藏了，用在docx
    public static let switchToKeyboardFromDropdown = DocsJSCallBack("window.lark.biz.sheet.dropdown.onSwitchToKeyboard") // 告诉前端从下拉列表切换到了键盘
    public static let notifyH5ToHideDropdown = DocsJSCallBack("window.lark.biz.sheet.dropdown.onCancel") // 告诉前端点击其他区域收起了下拉列表
    public static let sheetFilterPageFetch = DocsJSCallBack("window.lark.biz.sheet.getFilterValues")
    public static let sheetClearBadges = DocsJSCallBack("window.lark.biz.sheet.clearBadges")
    public static let sheetClickShare = DocsJSCallBack("window.lark.biz.sheet.clickShare")
    public static let sheetClickExport = DocsJSCallBack("window.lark.biz.sheet.clickExport")
    public static let sheetNotifySnapshot = DocsJSCallBack("window.lark.biz.sheet.onScreenShot")
    public static let sheetTitleExit = DocsJSCallBack("window.lark.biz.navigation.exit")
    // 控制前端是否可以focus
    public static let setFocusable = DocsJSCallBack("window.lark.biz.util.setFocusable")
    
    /// 回到上次位置
    public static let backToLastPosition = DocsJSCallBack("window.lark.biz.positionKeeper.backToLastPosition")
    /// 清除位置
    public static let clearLastPosition = DocsJSCallBack("window.lark.biz.positionKeeper.clearLastPosition")
    /// 记住当前位置
    public static let keepCurrentPosition = DocsJSCallBack("window.lark.biz.positionKeeper.keepCurrentPosition")

    /// 退出附件预览
    public static let onFileExit = DocsJSCallBack("window.lark.biz.util.onFileExit")
    /// 退出附件预览 New
    public static let onAttachFileExit = DocsJSCallBack("window.lark.biz.util.onAttachFileExit")
    /// 退出 bitable 编辑
    public static let bitableEditClosePanel = DocsJSCallBack("window.lark.biz.bitable.closeEditPanel")
    /// Bitable 的表格结构信息
    public static let btGetTableMeta = DocsJSCallBack("window.lark.biz.bitable.getTableMeta")
    /// Bitable 表格内全部 recordID 列表
    public static let btGetTableRecordIDList = DocsJSCallBack("window.lark.biz.bitable.getTableRecordIds")
    /// Bitable 根据 recordID 数组拉取记录内容
    public static let btGetRecordsData = DocsJSCallBack("window.lark.biz.bitable.getRecordsData")
    /// Bitable 根据搜索关键字拉取记录内容
    public static let btSearchRecords = DocsJSCallBack("window.lark.biz.bitable.getTableRecordsBySearchKey")
    /// Bitable 获取视图类型
    public static let getViewType = DocsJSCallBack("window.lark.biz.bitable.getViewType")
    /// Bitable 分组统计浮层面板分页数据获取
    public static let obtainGroupData = DocsJSCallBack("window.lark.biz.bitable.obtainGroupData")
    /// bitable proAdd下的提示
    public static let setSubmitTopTipShow = DocsJSCallBack("window.lark.biz.bitable.setSubmitTopTipShow")
    /// bitable 获取是否需要拦截创建副本
    public static let checkBitableClone = DocsJSCallBack("window.lark.biz.bitable.checkBitableClone")

    /// 动态通知是否启用位置记忆的事件
    public static let setPositionKeeper = DocsJSCallBack("window.lark.biz.util.setPositionKeeper")
    /// 重命名后通知前端文档标题
    public static let setTitle = DocsJSCallBack("window.lark.biz.title.setTitle")
    /// 设置文档Icon
    public static let setIcon = DocsJSCallBack("window.lark.biz.title.setIcon")
    /// 告知前端需要加载哪些 JS 业务，降低内存占用
    public static let preloadJsModule = DocsJSCallBack("window.preloadJsModule")
    /// 用户点击进入编辑模式按钮
    public static let clickEdit = DocsJSCallBack("window.lark.biz.editButton.clickEdit")
    /// 点击完成按钮
    public static let clickCompleteButton = DocsJSCallBack("window.lark.biz.completeButton.click")
    /// 点击取消按钮
    public static let clickCancelButton = DocsJSCallBack("window.lark.biz.cancel.click")

    /// 获取SVG数据
    public static let requestDiagramSVGData = DocsJSCallBack("window.lark.biz.util.requestDiagramSVGData")

    /// 用户点击目录打开开关
    public static let requestShowCatalog = DocsJSCallBack("window.lark.biz.catalog.showCatalog")
    /// 用户点击正文模式切换（全宽，标准宽）
    public static let widescreenModeSwitch = DocsJSCallBack("window.lark.biz.catalog.widescreenModeSwitch")
    /// 点击全屏按钮
    public static let clickFullScreenButton = DocsJSCallBack("window.lark.biz.util.fullsceenMode")

    /// 局部评论图片查看器回调
    public static let activateImageChange = DocsJSCallBack("lark.biz.comment.activateImageChange")

    /// 封面
    public static let setCover = DocsJSCallBack("window.lark.biz.title.setCover")
    public static let autoSetRandomCover = DocsJSCallBack("window.lark.biz.title.randomCover")

    /// sheet 附件列表高度
    public static let reportSheetAttachmentListHeight = DocsJSCallBack("window.lark.biz.sheet.reportSheetAttachmentPanelStatus")
    
    ///native通知前端需要展示工具栏
    public static let setToolBar = DocsJSCallBack("window.lark.biz.toolBar.restoreEditor")
    
    ///native通知前端关闭Block菜单
    public static let closeBlockMenuPanel = DocsJSCallBack("lark.biz.navigation.closeBlockMenuPanel")

    ///native通知前端目录模式变更
    public static let catalogChangeDisplayMode = DocsJSCallBack("window.lark.biz.catalog.changeDisplayMode")

    ///native通知前端字体大小变化
    public static let baseFontSizeUpdated = DocsJSCallBack("window.lark.biz.util.updateBaseFontSize")

    /// native打开附件通知前端
    public static let notifyAttachFileOpen =
        DocsJSCallBack("window.lark.biz.util.notifyAttachFileOpen")

    /// bitable native VCFollow 状态通知前端
    public static let bitableVCFollowState = DocsJSCallBack("window.lark.biz.bitable.sendVCFollowState")

    /// native更新bitable数据通知前端
    public static let btExecuteBitableCommands = DocsJSCallBack("window.lark.biz.bitable.executeCommands")

    /// 提交保存检查确认逻辑
    public static let btCheckConfirm = DocsJSCallBack("window.lark.biz.bitable.checkConfirm")
    
    /// 通知前端打开 AI字段面板：
    public static let btShowAIConfigForm = DocsJSCallBack("window.lark.biz.bitable.showAIConfigForm")
    
    /// 通知前端关闭 AI字段面板：
    public static let btHideAIConfigForm = DocsJSCallBack("window.lark.biz.bitable.hideAIConfigForm")
    
    /// 询问前端当前 AI 字段是否可以切换
    public static let btCheckFieldTypeChange = DocsJSCallBack("window.lark.biz.bitable.checkFieldTypeChange")

    /// 获取bitable通用数据
    public static let btGetBitableCommonData = DocsJSCallBack("window.lark.biz.util.getBitableCommonData")

    /// 获取bitable权限批量接口
    public static let btGetPermissionData = DocsJSCallBack("window.lark.biz.bitable.getPermissionsData")

    /// 请求native所需的UI数据
    public static let btGetUIData = DocsJSCallBack("window.lark.biz.bitable.getUIData")

    /// bitable数据请求聚合接口
    public static let btQuery = DocsJSCallBack("window.lark.biz.bitable.query")
    
    /// 获取当前文档时区
    public static let btGetBaseTimeZone = DocsJSCallBack("window.lark.biz.bitable.getBaseTimeZone")

    ///卡片组件异步请求数据接口，数据返回接口：window.lark.biz.util.asyncJsResponse
    public static let asyncJsRequest = DocsJSCallBack("window.lark.biz.bitable.asyncJsRequest")
    
    ///晒选排序组件异步请求数据接口，数据返回接口：window.lark.biz.util.asyncJsResponse
    public static let asyncToolbarJsRequest = DocsJSCallBack("window.lark.biz.bitable.asyncToolbarJsRequest")
    
    /// 同步扩展字段 owner 信息
    public static let syncFieldExtendOwner = DocsJSCallBack("window.lark.biz.bitable.syncFieldExtendOwner")
    
    ///异步卡片分页请求数据接口
    public static let btGetCardList = DocsJSCallBack("window.lark.biz.bitable.getCardList")

    /// 获取视图Meta信息
    public static let getViewMeta = DocsJSCallBack("window.lark.biz.bitable.getViewMeta")
    
    public static let remindNotificationClick = DocsJSCallBack("window.lark.biz.forms.remindNotificationClick")

    ///异步关联卡片分页请求数据接口
    public static let btGetLinkCardList = DocsJSCallBack("window.lark.biz.bitable.getLinkCardList")
    
    ///开启 / 关闭bitable高级权限
    public static let btUpgradeBase = DocsJSCallBack("window.lark.biz.bitable.upgradeBase")
    
    ///webviewsize变化时通知前端
    public static let notifyWebViewSizeChange = DocsJSCallBack("window.lark.biz.util.updateWebViewSize")
    /// 高级权限升级面板中的状态
    public static let getProUpdateStatus = DocsJSCallBack("window.lark.biz.bitable.getProUpdateStatus")
    /// 高级权限升级后受影响的公式信息
    public static let getProUpdateEffectData = DocsJSCallBack("window.lark.biz.bitable.getProUpdateEffectData")
    /// 前端计算文档升级为后端计算文档
    public static let upgradeSSC = DocsJSCallBack("window.lark.biz.bitable.upgradeSSC")

    /// DocComponent通用invoke方法
    public static let invokeWebForDC = DocsJSCallBack("lark.biz.doccomponent.invokeWeb")
    public static let configChangeForDC = DocsJSCallBack("lark.biz.doccomponent.configChange")

    /// bitable卡片itemView数据请求
    public static let getItemViewData = DocsJSCallBack("window.lark.biz.bitable.getItemViewData")
    
    /// rn通知同步成功后回调给前端
    public static let docSyncSuccess = DocsJSCallBack("window.lark.biz.handleOfflineCreateSuccess")
    /// SyncBlock更多按钮点击
    public static let syncBlockMoreMenuClick = DocsJSCallBack("lark.biz.util.onSubMoreMenuClick")

    /// 通知前端 base header 的显示隐藏
    public static let showHeader = DocsJSCallBack("window.lark.biz.bitable.switchHeader")
    
    /// iframe加载错误通知
    public static let notifyFrameError = DocsJSCallBack("window.lark.biz.notifyFrameError")

    /// 获取 SDK 的耗时相关数据
    public static let getFileLoadPerformanceCost = DocsJSCallBack("window.lark.biz.bitable.getFileLoadPerformanceCost")
    
    /// 内存警告
    public static let memoryWarning = DocsJSCallBack("window.lark.biz.util.memoryWarning")
}

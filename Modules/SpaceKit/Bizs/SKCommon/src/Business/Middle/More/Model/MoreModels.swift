//
//  MoreModels.swift
//  SpaceKit
//
//  Created by Gill on 2019/11/29.
//

import SKFoundation
import SKResource
import LarkSuspendable
import UniverseDesignIcon
import UniverseDesignColor
import SpaceInterface
import SKInfra

/*
 3.10.0 开始，此枚举的值，仅仅在新UI样式的FG关闭时，才代表在UI上的顺序；
 如果新UI的FG打开，则枚举值不影响顺序，真正的顺序在MoreViewController+DataSource.swift中决定
 注意：添加枚举的时候，请按顺序保证优先级，默认显示将会按这个进行优先级排序
 规则文档：https://bytedance.feishu.cn/docs/doccnVioXY2XtZ1pdO1jJgOUp3d
 */
public enum MoreItemType: Equatable, Hashable, Any {
    case share
    case shareVersion   // 分享版本
    case addTo
    case star
    case unStar
    case subscribe
    case addToSuspend //添加至浮窗
    case cancelSuspend //取消浮窗
    case addShortCut
    case delete
    case deleteShortcut
    case searchReplace //查找
    case translate   //翻译
    case openInBrowser
    case readingData(DocsType)  //文档信息、文件信息、表格信息
    case docsIcon       // 文档Icon
    case catalog      //目录
    case widescreenModeSwitch     //正文模式切换
    case sensitivtyLabel    //文档密级
    case bitableAdvancedPermissions //多维表格高级权限
    case publicPermissionSetting //权限设置
    case openWithOtherApp
    case rename
    case renameVersion // 版本重命名
    case saveToLocal    //保存到本地
    case operationHistory //操作历史  用于file
    case historyRecord  //历史记录
    case customerService //客服
    case uploadLog // 上传日志
    case feedShortcut //置顶
    case unFeedShortcut //取消置顶
    case pin
    case unPin
    case setHidden // 隐藏共享文件夹
    case setDisplay // 显示共享文件夹
    case moveTo
    case importAsDocs(String?)   // 导入为在线文档
    case report         // 举报
    case manualOffline // 手动离线
    case cancelManualOffline //取消手动离线
    case copyFile //创建副本
    case exportDocument // 将docs/sheet 导出为Word/PDF/Excel/Png
    case applyEditPermission // 申请编辑权限
    case saveAsTemplate // 保存为我的模板
    case switchToTemplate // 切换为模板
    case pano // 标签
    case copyLink // 复制链接
    case removeFromList // 从列表中移除，如从最近列表、离线访问列表删除等，文案和删除不一样
    case removeFromWiki // 从wiki移除
    case subscribeComment // 订阅评论更新
    case documentActivity // 操作记录，所有文档类型都有
    case wikiClipTop // wiki 置顶
    case wikiUnClip // wiki 取消置顶
    case retention // 保留标签
    case timeZone //设置时区
    case openSourceDocs // 版本对应的打开源文档
    case deleteVersion  // 删除版本
    case savedVersionList // 已存版本信息
    case entityDeleted // shortcut本体被删除
    case workbenchNormal //未添加到工作台
    case workbenchAdded // 已添加到工作台
    case pinToQuickLaunch //添加至 QuickLaunchWindow主导航
    case unpinFromQuickLaunch //从 QuickLaunchWindow 移除
    case openInNewTab //在主导航中打开
    case reportOutdate // 反馈内容过期
    case docFreshness // 文档时效性
    case translated(String) // 新翻译按钮
    case unassociateDoc //解除关联文档
    case quickAccessFolder  // 快速访问文件夹
    case unQuickAccessFolder    // 取消快速访问文件夹
    

    public var imageAndTitle: (UIImage, String) {
        var image: UIImage
        var title: String
        switch self {
        case .star:
            title = BundleI18n.SKResource.Doc_Facade_AddToFavorites
            image = UDIcon.collectionOutlined
        case .unStar:
            title = BundleI18n.SKResource.Doc_Facade_Remove_From_Favorites
            image = UDIcon.collectFilled
        case .addToSuspend:
            title = LarkSuspendable.BundleI18n.LarkSuspendable.Lark_Core_FloatingWindow
            image = UDIcon.multitaskOutlined
        case .cancelSuspend:
            title = LarkSuspendable.BundleI18n.LarkSuspendable.Lark_Core_CancelFloating
            image = UDIcon.unmultitaskOutlined
        case .subscribe:
            title = BundleI18n.SKResource.Doc_Facade_Subscribe
            image = UDIcon.subscribeAddOutlined
        case .pin:
            if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
                title = BundleI18n.SKResource.LarkCCM_NewCM_AddToPins_Menu
                image = UDIcon.pinOutlined
            } else {
                title = BundleI18n.SKResource.LarkCCM_CM_More_AddPin_Mob
                image = UDIcon.buzzOutlined
            }
        case .unPin:
            if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
                title = BundleI18n.SKResource.LarkCCM_NewCM_RemoveFromPins_Menu
                image = UDIcon.unpinOutlined
            } else {
                title = BundleI18n.SKResource.Doc_List_Remove_Access
                image = UDIcon.cancelBuzzOutlined
            }
        case .quickAccessFolder:
            title = BundleI18n.SKResource.LarkCCM_CM_More_AddPin_Mob
            image = UDIcon.buzzOutlined
        case .unQuickAccessFolder:
            title = BundleI18n.SKResource.Doc_List_Remove_Access
            image = UDIcon.cancelBuzzOutlined
        case .setHidden:
            title = BundleI18n.SKResource.Doc_List_SetHidden
            image = UDIcon.visibleLockOutlined
        case .setDisplay:
            title = BundleI18n.SKResource.Doc_List_SetDisplay
            image = UDIcon.visibleOutlined
        case .addTo:
            title = BundleI18n.SKResource.Doc_Facade_AddTo
            image = UDIcon.toolAddblockOutlined
        case .addShortCut:
            title = BundleI18n.SKResource.LarkCCM_Workspace_Menu_AddShortcutTo
            image = UDIcon.newShortcutOutlined
        case .delete:
            title = BundleI18n.SKResource.Doc_Facade_Delete
            image = UDIcon.deleteTrashOutlined
        case .deleteVersion:
            title = BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_DeleteV_Button
            image = UDIcon.deleteTrashOutlined
        case .removeFromList:
            title = BundleI18n.SKResource.Doc_Facade_Remove
            image = UDIcon.noOutlined
        case .removeFromWiki:
            title = BundleI18n.SKResource.LarkCCM_Workspace_Menu_RemoveFromSpace_Mob
            image = UDIcon.noOutlined
        case .deleteShortcut:
            title = BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_DeleteShortcuts_Tooltip
            image = UDIcon.deleteTrashOutlined
        case .searchReplace:
            title = BundleI18n.SKResource.Doc_Facade_LookFor
            image = UDIcon.cardSearchOutlined
        case .translate:
            title = BundleI18n.SKResource.LarkCCM_Docs_TranslateInto_Menu_Mob
            image = UDIcon.translateOutlined
        case .historyRecord:
            title = BundleI18n.SKResource.LarkCCM_Docs_EditHistory_Menu_Mob
            image = UDIcon.historyOutlined
        case .operationHistory:
            title = BundleI18n.SKResource.Drive_Drive_HistoryRecordPageTitle
            image = UDIcon.historyOutlined
        case .renameVersion:
            title = BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_RenameV_Button
            image = UDIcon.ccmRenameOutlined
        case .rename:
            title = BundleI18n.SKResource.Doc_Facade_Rename
            image = UDIcon.ccmRenameOutlined
        case .saveToLocal:
            title = BundleI18n.SKResource.CreationMobile_ECM_SaveToLocal_option
            image = UDIcon.downloadOutlined
        case .sensitivtyLabel:
            title = BundleI18n.SKResource.LarkCCM_Docs_SecurityLevel_Menu_Mob
            image = UDIcon.safeSettingsOutlined
        case .bitableAdvancedPermissions:
            // ig-TODO: 更新高级权限 image
            title = BundleI18n.SKResource.Bitable_AdvancedPermission_Setting
            image = BundleResources.SKResource.Common.Global.icon_approval_outlined_nor
        case .publicPermissionSetting:
            title = BundleI18n.SKResource.Doc_More_PublicPermissionSetting
            image = UDIcon.settingOutlined
        case .widescreenModeSwitch:
            title = BundleI18n.SKResource.CreationMobile_Docs_More_fullwidth_button
            image = BundleResources.SKResource.Common.More.icon_more_fullwidth_nor
        case .customerService:
            title = BundleI18n.SKResource.LarkCCM_Docs_ContactSupport_Menu_Mob
            image = UDIcon.helpdeskOutlined
        case .openWithOtherApp:
            title = BundleI18n.SKResource.Drive_Drive_OpenWithOtherApps
            image = UDIcon.leaveroomOutlined
        case .openInBrowser:
            title = BundleI18n.SKResource.Doc_Facade_OpenInBrowser
            image = UDIcon.browserMacOutlined
        case .readingData(let type):
            title = readingDataTitle(type)
            image = UDIcon.infoOutlined
        case .docsIcon:
            title = BundleI18n.SKResource.Doc_Doc_IconSettings
            image = UDIcon.emojiOutlined
        case .uploadLog:
            title = BundleI18n.SKResource.Doc_Facade_UploadLog
            image = UDIcon.updateLogOutlined
        case .catalog:
            title = BundleI18n.SKResource.Doc_Doc_MoreStructure
            image = UDIcon.tableGroupOutlined
        case .feedShortcut:
            title = BundleI18n.SKResource.Doc_More_Shortcut
            image = UDIcon.setTopOutlined
        case .unFeedShortcut:
            title = BundleI18n.SKResource.Doc_More_CancelShortcut
            image = UDIcon.setTopCancelOutlined
        case .importAsDocs(let type):
            title = DriveConvertFileUtils.convertFileTitle(fileType: type)
            image = UDIcon.docReplaceOutlined
        case .copyFile:
            title = BundleI18n.SKResource.LarkCCM_Docs_MakeACopy_Menu_Mob
            image = UDIcon.copyOutlined
        case .report:
            title = BundleI18n.SKResource.LarkCCM_Security_Docs_Report_Button
            image = UDIcon.warnReportOutlined
        case .share:
            title = BundleI18n.SKResource.Doc_More_Share
            image = UDIcon.shareOutlined
        case .shareVersion:
            title = BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_ShareVersion_Button_Mob
            image = UDIcon.shareOutlined
        case .manualOffline:
            title = BundleI18n.SKResource.Doc_Facade_OfflineMakeAvailable
            image = UDIcon.offlineOutlined
        case .cancelManualOffline:
            title = BundleI18n.SKResource.Doc_Facade_OfflineRemove
            image = UDIcon.cancelOfflineOutlined
        case .exportDocument:
            title = BundleI18n.SKResource.LarkCCM_Docs_DownloadAs_Menu_Mob
            image = UDIcon.downloadOutlined
        case .applyEditPermission:
            title = BundleI18n.SKResource.Doc_Resource_ApplyEditPerm
            image = UDIcon.ccmEditOutlined
        case .saveAsTemplate:
            title = BundleI18n.SKResource.Doc_List_SaveAsTmpl
            image = UDIcon.templateOutlined
        case .switchToTemplate:
            title = BundleI18n.SKResource.LarkCCM_Docs_ConvertToTemplate_Menu_Mob
            image = UDIcon.templateOutlined
        case .pano:
            title = BundleI18n.SKResource.Doc_More_EditTag
            image = UDIcon.tagOutlined
        case .copyLink:
            title = BundleI18n.SKResource.Doc_Facade_CopyLink
            image = UDIcon.linkCopyOutlined
        case .moveTo:
            title = BundleI18n.SKResource.LarkCCM_Docs_MoveTo_Menu_Mob
            image = UDIcon.intoItemOutlined
        case .subscribeComment:
            title = BundleI18n.SKResource.LarkCCM_Docs_FollowComments_Menu_Mob
            image = BundleResources.SKResource.Common.More.icon_add_comment_outlined
        case .documentActivity:
            title = BundleI18n.SKResource.CreationMobile_Activity_Tab
            image = UDIcon.operationrecordOutlined
        case .wikiClipTop:
            title = BundleI18n.SKResource.CreationMobile_Wiki_ClipToTop_Option
            image = UDIcon.setTopOutlined
        case .wikiUnClip:
            title = BundleI18n.SKResource.CreationMobile_Wiki_Unclip_Option
            image = UDIcon.setTopCancelOutlined
        case .retention:
            title = BundleI18n.SKResource.CreationMobile_Docs_Retention_Settings
            image = UDIcon.operationrecordOutlined
        case .timeZone:
            title = BundleI18n.SKResource.Bitable_Timezone_DocumentTimezoneMobileVer
            image = UDIcon.timeZoneOutlined
        case .openSourceDocs:
            title = BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_View_Back2Ori_Button
            image = UDIcon.viewinchatOutlined
        case .savedVersionList:
            title = BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_View_SavedVs_Button
            image = UDIcon.operationrecordOutlined
        case .entityDeleted:
            title = BundleI18n.SKResource.LarkCCM_Workspace_Menu_OriginalDocumentDeleted_Tooltip
            image = UDIcon.infoOutlined
        case .workbenchNormal:
            title = BundleI18n.SKResource.Bitable_ShareToWorkplace_ShareToWorkplace_Dropdown
            image = UDIcon.findAppOutlined
        case .workbenchAdded:
            title = BundleI18n.SKResource.Bitable_ShareToWorkplace_AddedToWorkplace_Dropdown
            image = UDIcon.findAppColorful
        case .pinToQuickLaunch:
            title = BundleI18n.SKResource.Lark_Core_AddAPPtoNaviBar_Button
            image = UDIcon.moreLauncherOutlined
        case .unpinFromQuickLaunch:
            title = BundleI18n.SKResource.Lark_Core_RemoveAppFromNaviBar_Button
            image = UDIcon.moreLauncherNoOutlined
        case .openInNewTab:
            title = BundleI18n.SKResource.Lark_Web_OpenInNewTab_Button
            image = UDIcon.addTagOutlined
        case .reportOutdate:
            title = BundleI18n.SKResource.LarkCCM_CM_Verify_AskOwner_Menu //反馈内容过期
            image = UDIcon.feedbackOutlined
        case .docFreshness:
            title = BundleI18n.SKResource.LarkCCM_CM_Verify_Validity_Title //文档时效性
            image = UDIcon.verifyOutlined
        case .translated(let language):
            title = BundleI18n.SKResource.LarkCCM_Docs_MagicShare_Translate_Button(language)
            image = UDIcon.translateOutlined
        case .unassociateDoc:
            title = BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_Unlink_Tooltip //解除关联文档
            image = UDIcon.unboundGroupOutlined
        }
        return (image, title)
    }

    public var enableColor: UIColor {
        switch self {
        case .unStar:
            return UDColor.colorfulYellow
        case .workbenchAdded:
            return UIColor.clear
        default:
            return UDColor.iconN1
        }
    }

    public var disableColor: UIColor {
        return UDColor.iconDisabled
    }

    private func readingDataTitle(_ type: DocsType) -> String {
        BundleI18n.SKResource.LarkCCM_Docs_DocumentDetails_Menu_Mob
    }

    // 红点逻辑,需要展示标签的入口在这里添加
    public var newTagIdentifiler: String? {
        switch self {
        case .savedVersionList:
            guard UserScopeNoChangeFG.GXY.docsVersionOnBoarding else {
                return nil
            }
            return UserDefaultKeys.docsVersionValue
        case .reportOutdate:
            return UserDefaultKeys.reportOutdated
        case .docFreshness:
            return UserDefaultKeys.docsFreshness
        default:
            return nil
        }
    }

    /// 是否展示"新"的标签
    public var shouldShowNewTag: Bool {
        switch self {
        case .savedVersionList, .reportOutdate, .docFreshness:
            return true
        default:
            return false
        }
    }

    public static func itemTypeControlledByFrontend(id: String) -> MoreItemType? {
        switch id {
        case "export":
            return .exportDocument
        case "rename":
            return .rename
        case "make_copy":
            return .copyFile
        case "template":
            return .saveAsTemplate
        case "searchV2":
            return .searchReplace
        default:
            return nil
        }
    }

    /// switch类型的UI复用刷新会有bug，需要确保cell是独立的
    public var switchIdentifier: String {
        switch self {
        case .subscribe:
            return "subscribe"
        case .catalog:
            return "catalog"
        case .widescreenModeSwitch:
            return "widescreenModeSwitch"
        case .switchToTemplate:
            return "switchToTemplate"
        case .subscribeComment:
            return "subscribeComment"
        default:
            return ""
        }
    }
}

public enum State {
    case enable
    case disable
    case hidden

    public var isEnable: Bool {
        switch self {
        case .enable:
            return true
        default:
            return false
        }
    }
}

public enum SectionType: Int {
    case horizontal
    case vertical
}

public enum MoreStyle {
    case normal
    /// needLoading: switch上是否显示loading
    case mSwitch(isOn: Bool, needLoading: Bool)
    case rightLabel(title: String)
    case rightIndicator(icon: UIImage?, title: String)
    case mButton(title: String) //右侧是 一个Button，有自己的点击事件

    public var isSwitch: Bool {
        switch self {
        case .mSwitch:
            return true
        case .normal, .rightLabel, .rightIndicator, .mButton:
            return false
        }
    }
    
    public var isRightButton: Bool {
        switch self {
        case .mButton:
            return true
        case .normal, .rightLabel, .rightIndicator, .mSwitch:
            return false
        }
    }
}

public typealias ItemActionHandler = ((_ item: ItemsProtocol, _ isSwitch: Bool) -> Void)
// 这里的 controller 代表 MoreViewController，但在非 switch、不置灰的按钮点击场景，controller 会先 dismiss 再执行 handler，因此 controller 会是 nil，仅在错误处理流程才有意义
// MoreViewV2RightButtonCell.Style 用于兼容左右两个按钮各有一个点击事件的情况
public typealias ItemActionHandlerV2 = (ItemsProtocol, Bool, UIViewController?, MoreViewV2RightButtonCell.Style?) -> Void

public typealias ItemActionHandlerV3 = ((_ item: ItemsProtocol, _ isSwitch: Bool, _ style: MoreViewV2RightButtonCell.Style?) -> Void)

public  protocol ItemsProtocol {
    var state: State { get set }
    // enable 状态下是否需要阻止点击后关闭 more 面板
    var shouldPreventDismissal: Bool { get }
    var type: MoreItemType { get }
    var style: MoreStyle { get }
    var image: UIImage { get }
    var iconEnableColor: UIColor { get }
    var iconDisableColor: UIColor { get }
    var title: String { get }
    var needNewTag: Bool { get }
    var hasSubPage: Bool { get }
    var handler: ItemActionHandlerV2 { get }
    func removeNewTagMarkWith(_ docsType: DocsType)
}

public protocol MoreDataProtocol {
    var sectionType: SectionType { get }
    var items: [ItemsProtocol] { get }
}
extension MoreDataProtocol {
    public var count: Int { items.count }
}

public enum WidescreenMode: String {
    case fullwidth //全宽,默认选中
    case standardwidth //标准宽
}

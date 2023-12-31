//
//  MoreViewModel+Reporter.swift
//  SKCommon
//
//  Created by lizechuang on 2021/3/5.
//  swiftlint:disable file_length

import SKFoundation
import SpaceInterface
import SKInfra
import LarkContainer

extension MoreViewModel {

    // 文档内点击…出 more 面板的埋点
    func reportViewMoreEvent() {
        guard let module = docsInfo.type.module else { return }
        let bizParam = SpaceBizParameter(module: module,
                                         fileID: DocsTracker.encrypt(id: docsInfo.objToken),
                                         fileType: docsInfo.type,
                                         driveType: docsInfo.fileType ?? "")
        let isFollowUpdate = docsInfo.subscribed
       let cacheInstance = DocsContainer.shared.resolve(CommentSubScribeCacheInterface.self)
        let isFollowComment = cacheInstance?.getCommentSubScribe(encryptedToken: docsInfo.encryptedObjToken) ?? false
        var params: [String: String] = [
            "is_follow_update": String(isFollowUpdate),
            "is_follow_comment": String(isFollowComment)
        ]

        if let userPermission = dataProvider.userPermissions {
            let permissionJSON = userPermission.reportData
            if let jsonString = permissionJSON.toJSONString() {
                params["user_permission"] = jsonString
            }
            if let isOwner = permissionJSON["is_owner"] as? Bool {
                params["is_owner"] = isOwner ? "true" : "false"
            }
        }
        params.merge(other: bizParam.params)
        if let tracker = moreItemClickTracker {
            // 列表页侧滑More面板view上报
            if tracker.isBitableHome {
                DocsTracker.reportBitableHomeRightClickMenuView(tracker, docsInfo.subscribed, bizParms: bizParam)
            } else {
                DocsTracker.reportSpaceRightClickMenuView(tracker, docsInfo.subscribed, bizParms: bizParam)
            }
        } else {
            // 文档内点击More面板view上报
            if docsInfo.isVersion {
                if docsInfo.inherentType == .sheet {
                    DocsTracker.newLog(enumEvent: .sheetVersionMoreMenu, parameters: params)
                } else {
                    DocsTracker.newLog(enumEvent: .docsVersionMoreMenu, parameters: params)
                }
            } else {
                DocsTracker.newLog(enumEvent: .spaceDocsMoreMenuView, parameters: params)
            }
        }
    }

    func reportClickApplyEditPermission() {
        let params: [String: Any] = ["file_type": docsInfo.type.name,
                                      "file_id": docsInfo.encryptedObjToken,
                                      "module": docsInfo.fromModule ?? "",
                                      "file_is_cross_tenant": docsInfo.isSameTenantWithOwner ? "0" : "1",
                                      "permission": "edit",
                                      "source": "more"]
        DocsTracker.log(enumEvent: .clickApplyEditPermission, parameters: params)
    }

//    func reportSwitchWidescreenMode(_ mode: WidescreenMode) {
//        FileListStatistics.curFileObjToken = self.docsInfo.objToken
//        FileListStatistics.curFileType = self.docsInfo.type
//        addReportForClickItem(actionType: .widescreenModeSwitch,
//                              exParams: ["full_width_switch": mode == .fullwidth ? "0" : "1"])
//    }

    //swiftlint:disable cyclomatic_complexity function_body_length
    // 整体上报
    func addReportForClickItem(actionType: MoreItemType, exParams: [String: String]? = [:]) { // innerPage 的 右上角 ... 交互action取值
        FileListStatistics.curFileObjToken = self.docsInfo.objToken
        FileListStatistics.curFileType = self.docsInfo.type
        var action = ""
        switch actionType {
        case .star, .wikiClipTop:
            action = "add_favorites"
        case .unStar, .wikiUnClip:
            action = "remove_favorites"
        case .addToSuspend:
            action = "add_to_tasklist"
        case .cancelSuspend:
            action = "remove_form_tasklist"
        case .subscribe:
            action = "subscribe"
        case .addShortCut:
            action = "addShortCut"
        case .addTo:
            action = "addto"
        case .delete:
            action = "delete"
        case .deleteVersion:
            action = "delete_version"
        case .deleteShortcut:
            action = "delete_shortcut"
        case .searchReplace:
            action = "search_replace" // 建议
        case .historyRecord, .operationHistory:
            action = "history_record"  // 建议
        case .sensitivtyLabel:
            action = "sensitivtyLabel"
        case .bitableAdvancedPermissions:
            action = "bitableAdvancedPermissions"
        case .publicPermissionSetting:
            action = "public_permission_setting" // 建议
        case .customerService:
            action = "contact"
        case .readingData:
            action = "Doc_Doc_DocumentDetails" // 建议
        case .docsIcon:
            action = "client_icon_change"
        case .rename:
            action = "rename"  // 建议
        case .renameVersion:
            action = "rename_version"
        case .saveToLocal:
            action = "saveToLocal"
        case .openWithOtherApp:
            action = "open_with_other_app" // 建议
        case .uploadLog:
            action = "upload_log"
        case .catalog:
            action = "catalog"
        case .widescreenModeSwitch:
            action = "docs_iPad_click_fw_button"
        case .translate:
            action = "translate"
        case .feedShortcut, .unFeedShortcut:
            action = "feedShortcut"
        case .pin, .quickAccessFolder:
            action = "add_quickaccess"
        case .unPin, .unQuickAccessFolder:
            action = "remove_quickaccess"
        case .setHidden:
            action = "set_hidden"
        case .setDisplay:
            action = "set_display"
        case .importAsDocs:
            action = "import_as_docs"
        case .report:
            action = "report"
        case .copyFile:
            action = "make_a_copy" //副本
        case .manualOffline, .cancelManualOffline:
            action = "manualOffline"
        case .share:
            action = "share"
        case .shareVersion:
            action = "share_version"
        case .exportDocument:
            action = "exportDocument"
        case .applyEditPermission:
            action = "apply_edit_permission"
            reportClickApplyEditPermission()
        case .openInBrowser:
            action = "browser"
        case .saveAsTemplate, .switchToTemplate:
            action = "saveAsTemplate"
        case .pano:
            action = "pano"
        case .copyLink:
            action = "copyLink"
        case .moveTo:
            action = "moveTo"
        case .removeFromList, .removeFromWiki:
            action = "removeFromList"
        case .subscribeComment, .retention, .timeZone, .entityDeleted, .workbenchNormal, .workbenchAdded: return// 还不需要埋
        case .documentActivity:
            action = " operation_records"
        case .openSourceDocs:
            action = "open_sources_docs"
        case .savedVersionList:
            action = "version_list"
        case .pinToQuickLaunch:
            action = "pin_to_quicklaunch"
        case .unpinFromQuickLaunch:
            action = "unpin_from_quicklaunch"
        case .openInNewTab:
            action = "open_in_quicklaunch"
        case .docFreshness:
            action = "docFreshness"
        case .reportOutdate:
            action = "reportOutdate"
        case .translated:
            action = "translate"
        case .unassociateDoc:
            action = "unassociateDoc"
        }

        let encryptFileID = DocsTracker.encrypt(id: docsInfo.objToken)
        var params = ["source": "innerpage_more", "action": action, "subModule": ""]
        params = checkToAddParam(key: "module", value: docsInfo.fromModule, params: params)
        params = checkToAddParam(key: "file_type", value: docsInfo.type.name, params: params)
        params = checkToAddParam(key: "file_id", value: encryptFileID, params: params)
        if let exParams = exParams, !exParams.isEmpty {
            exParams.forEach { (key, value) in
                params[key] = value
            }
        }
        var newParams: [String: Any] = params
        newParams = FileListStatistics.addParamsInto(newParams)

        DocsTracker.log(enumEvent: .clientContentManagement, parameters: newParams)
    }

    /// more 面板点击事件上报(2021.5 新埋点)
    @discardableResult
    func newReportForClickItem(actionType: MoreItemType) -> [String: String] {
        guard let module = docsInfo.type.module else { return [:] }
        let bizParam = SpaceBizParameter(module: module,
                                         fileID: DocsTracker.encrypt(id: docsInfo.objToken),
                                         fileType: docsInfo.type,
                                         driveType: docsInfo.fileType ?? "")
        if let wikiInfo = docsInfo.wikiInfo {
            if wikiInfo.wikiNodeState.originIsExternal {
                bizParam.originInWiki = false
            } else {
                bizParam.originInWiki = true
            }
            if wikiInfo.wikiNodeState.isShortcut {
                if wikiInfo.wikiNodeState.originIsExternal {
                    bizParam.shortcutId = docsInfo.token
                } else {
                    bizParam.shortcutId = wikiInfo.wikiNodeState.shortcutWikiToken ?? docsInfo.token
                }
            }
        }
        var params = ["click": actionType.clickValue, "target": actionType.targetValue]

        switch actionType {
        case .subscribe:
            params["click"] = docsInfo.subscribed ? "follow_close" : "follow_open"
        case .subscribeComment:
            params["click"] = docsInfo.subscribedComment ? "follow_comment_close" : "follow_comment_open"
        case .copyFile:
            if docsInfo.isFromWiki {
                // wiki copy
                params["target"] = DocsTracker.EventType.wikiFileLocationSelectView.rawValue
            }
        case .addShortCut:
            if docsInfo.isFromWiki {
                // wiki shortcut
                params["target"] = DocsTracker.EventType.wikiFileLocationSelectView.rawValue
            }
        case .docFreshness:
            if let clickValue = docsInfo.freshInfo?.freshStatus.statisticValue {
                params["click"] = clickValue
            }
        case .translated:
                params["menu_level"] = "first"
        case .savedVersionList:
            if docsInfo.inherentType == .sheet {
                params["target"] = DocsTracker.EventType.sheetVersionPanel.rawValue
            }
        default:
            break
        }

        if let userPermission = dataProvider.userPermissions {
            let permissionJSON = userPermission.reportData
            if let jsonString = permissionJSON.toJSONString() {
                params["user_permission"] = jsonString
            }
            if let isOwner = permissionJSON["is_owner"] as? Bool {
                params["is_owner"] = isOwner ? "true" : "false"
            }
        }
        params.merge(other: bizParam.params)
        if case .file = docsInfo.type {
            params["file_type"] = "drive"
        }
        if case .translated = actionType {
            params["app_form"] = docsInfo.isInVideoConference ?? false ? "vc" : "none"
            params["lang"] = getTranslateLanguageKey()
            if let translationContext = docsInfo.translationContext {
                params["lang"] = translationContext.targetLanguage
                params["user_main_lang"] = translationContext.userMainLanguage
                params["original_language"] = translationContext.contentSourceLanguage
                params["user_default_lang"] = translationContext.defaultTargetLanguage
            }
        }
        let isVersion = docsInfo.isVersion
        if isVersion {
            if docsInfo.inherentType == .sheet {
                DocsTracker.newLog(event: DocsTracker.EventType.sheetVersionMoreMenuClick.rawValue, parameters: params)
            } else {
                DocsTracker.newLog(event: DocsTracker.EventType.docsVersionMoreMenuClick.rawValue, parameters: params)
            }
        } else {
            DocsTracker.newLog(event: DocsTracker.EventType.spaceDocsMoreMenuClick.rawValue, parameters: params)
        }

        if case .exportDocument = actionType {
            params["is_version"] = isVersion ? "true" : "false"
            DocsTracker.newLog(event: DocsTracker.EventType.spaceExportAsView.rawValue, parameters: params)
        }
        if case .translate = actionType {
            params["is_version"] = isVersion ? "true" : "false"
            DocsTracker.newLog(event: DocsTracker.EventType.spaceTranslateView.rawValue, parameters: params)
        }
        return params
    }

//    final public class func reportInnerpageMoreAction(fromModule: String?, fromSubmodule: String?, fileTypeName: String) {
//        guard let fileType = FileListStatistics.curFileType?.fileTypeForSta else { return }
//        let params: [String: Any] = ["file_type": fileType,
//                                     "modlue": fileType] // 产品说，传一样的值，6
//
//        DocsTracker.log(enumEvent: .clickInnerpageMore, parameters: params)
//    }

    private func checkToAddParam(key: String, value: String?, params: [String: String]) -> [String: String] {
        var newParams = params
        if let value = value, !value.isEmpty {
            newParams[key] = value
        }
        return newParams
    }
    
    func getTranslateLanguageKey() -> String {
        guard let translateService = try? Container.shared.resolve(assert: CCMTranslateService.self) else { return ""}
        return translateService.targetLanguageKey ?? ""
    }

    func listReportForClickItem(actionType: MoreItemType, clickTracker: ListMoreItemClickTracker) {
        guard let module = docsInfo.type.module else { return }
        let bizParam = SpaceBizParameter(module: module,
                                         fileID: DocsTracker.encrypt(id: docsInfo.objToken),
                                         fileType: docsInfo.type,
                                         originInWiki: clickTracker.originInWiki)
        switch actionType {
        case .share:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .share, bizParms: bizParam)
        case .addTo:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .addToFolder, bizParms: bizParam)
        case .star:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .favoritesItem(add: true, isShareFolder: clickTracker.isShareFolder), bizParms: bizParam)
        case .unStar:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .favoritesItem(add: false, isShareFolder: clickTracker.isShareFolder), bizParms: bizParam)
        case .subscribe:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .subscribe, bizParms: bizParam)
        case .addShortCut:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .addShortCut, bizParms: bizParam)
        case .delete:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .delete, bizParms: bizParam)
        case .openWithOtherApp:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .openInOtherApp(isShareFolder: clickTracker.isShareFolder), bizParms: bizParam)
        case .pin:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .quickAccessItem(add: true), bizParms: bizParam)
        case .unPin:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .quickAccessItem(add: false), bizParms: bizParam)
        case .moveTo:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .moveToFolder, bizParms: bizParam)
        case .manualOffline:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .offlineItem(on: true), bizParms: bizParam)
        case .cancelManualOffline:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .offlineItem(on: false), bizParms: bizParam)
        case .copyFile:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .createCopy, bizParms: bizParam)
        case .applyEditPermission:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .applyEditPermission, bizParms: bizParam)
        case .copyLink:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .copyLink(isFolder: clickTracker.type == .folder, isShareFolder: clickTracker.isShareFolder),
                                                       bizParms: bizParam)
        case .retention:
            DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .retention, bizParms: bizParam)
        case .removeFromList:
            if clickTracker.isBitableHome {
                DocsTracker.reportSpaceRightClickMenuClick(tracker: clickTracker, params: .removeFromRecent, bizParms: bizParam)
            }
        default:
            return
        }
    }
}

extension MoreItemType {
    var clickValue: String {
        switch self {
        case .star:
            return "add_to_favorites"
        case .unStar:
            return "remove_from_favorites"
        case .addToSuspend:
            return "add_to_tasklist"
        case .cancelSuspend:
            return "remove_form_tasklist"
        case .share:
            return "share"
        case .shareVersion:
            return "share_version"
        case .subscribe:
            return "subscribe"
        case .addTo:
            return "add_to_folder"
        case .addShortCut:
            return "create_shortcut"
        case .delete:
            return "delete"
        case .deleteVersion:
            return "delete_version"
        case .deleteShortcut:
            return "delete_shortcut"
        case .searchReplace:
            return "find_replace"
        case .translate:
            return "translate"
        case .openInBrowser:
            return "open_in_explorer"
        case .readingData:
            return "docs_details"
        case .docsIcon:
            return "icon"
        case .catalog:
            return "catalog"
        case .widescreenModeSwitch:
            return "docs_iPad_click_fw_button"
        case .sensitivtyLabel:
            return "sensitivtyLabel"
        case .bitableAdvancedPermissions:
            return "bitable_premium_permission_settings"
        case .publicPermissionSetting:
            return "permission_settings"
        case .openWithOtherApp:
            return "open_in_other_apps"
        case .rename:
            return "rename"
        case .renameVersion:
            return "rename_version"
        case .saveToLocal:
            return "save_to_local"
        case .operationHistory:
            return "operation_history"
        case .historyRecord:
            return "history_version"
        case .customerService:
            return "contact_us"
        case .uploadLog:
            return "log_upload"
        case .feedShortcut:
            return "top"
        case .unFeedShortcut:
            return "top_cancel"
        case .pin, .quickAccessFolder:
            return "add_to_quickaccess"
        case .unPin, .unQuickAccessFolder:
            return "remove_from_quickaccess"
        case .setHidden:
            return "set_hidden"
        case .setDisplay:
            return "set_display"
        case .importAsDocs:
            return "import_as"
        case .report:
            return "report_abuse"
        case .manualOffline:
            return "turn_on_offline"
        case .cancelManualOffline:
            return "turn_off_offline"
        case .copyFile:
            return "create_copy"
        case .exportDocument:
            return "export_as"
        case .applyEditPermission:
            return "permission_read_without_edit"
        case .saveAsTemplate, .switchToTemplate:
            return "save_as_template"
        case .pano:
            return "pano_tag"
        case .copyLink:
            return "copy_link"
        case .moveTo:
            return "moveTo"
        case .removeFromList, .removeFromWiki:
            return "removeFromList"
        case .subscribeComment:
            // 需要外部判断
            return ""
        case .documentActivity:
            return "operation_records"
        case .wikiClipTop:
            return "clip_wiki"
        case .wikiUnClip:
            return "unclip_wiki"
        case .retention:
            return "retention"
        case .timeZone:
            return "doc_time_zone"
        case .openSourceDocs:
            return "back_to_source_doc"
        case .savedVersionList:
            return "view_saved_version"
        case .entityDeleted:
            // 暂时不需要埋
            return ""
        case .workbenchNormal:
            return "add_to_workplace"
        case .workbenchAdded:
            return "remove_from_workplace"
        case .pinToQuickLaunch:
            return "pin_to_quicklaunch"
        case .unpinFromQuickLaunch:
            return "unpin_from_quicklaunch"
        case .openInNewTab:
            return "open_in_quicklaunch"
        case .docFreshness:
            return "docs_timeliness"
        case .reportOutdate:
            return "reminde_update"
        case .translated:
            return "translate"
        case .unassociateDoc:
            return "unassociateDoc"
        }
    }

    var targetValue: String {
        switch self {
        case .share:
            return "ccm_permission_share_view"
        case .star, .unStar, .pin, .unPin, .importAsDocs, .copyFile, .manualOffline, .cancelManualOffline, .feedShortcut, .unFeedShortcut:
            return "ccm_docs_page_view"
        case .addTo, .addShortCut:
            return "ccm_space_add_to_folder_view"
        case .delete:
            return "ccm_space_delete_view"
        case .readingData:
            return "ccm_space_docs_details_view"
        case .publicPermissionSetting:
            return "ccm_permission_set_view"
        case .rename:
            return "ccm_space_drive_rename_view"
        case .historyRecord:
            return "ccm_docs_history_page_view"
        case .applyEditPermission:
            return "ccm_permission_read_without_edit_view"
        case .openInBrowser:
            return "ccm_docs_page_view"
        case .pano:
            return "pano_tagview_page_view"
        case .saveAsTemplate:
            return "ccm_space_save_customize_template_view"
        case .searchReplace:
            return "ccm_doc_find_replace_panel_view"
        case .translate, .translated:
            return "ccm_space_translate_view"
        case .exportDocument:
            return "ccm_space_export_as_view"
        case .sensitivtyLabel:
            return "sensitivtyLabel"
        case .bitableAdvancedPermissions:
            return "ccm_bitable_premium_permission_setting_view"
        case .documentActivity:
            return "ccm_space_all_contents_view"
        case .retention:
            return "ccm_space_retention_setting_view"
        case .timeZone:
            return "ccm_bitable_time_zone_setting_view"
        case .savedVersionList:
            return "ccm_doc_saved_version_view"
        case .renameVersion:
            return "ccm_doc_rename_version_view"
        default:
            return "none"
        }
    }
}

public extension DocsType {
    /// 供埋点使用，返回埋点行为发生的模块，目前仅定义对 drive 和 wiki 场景返回值
    /// https://bytedance.feishu.cn/sheets/shtcn4yyjk8IwmHx2hRybOhFWxd
    public var module: PageModule? {
        switch self {
        case .mindnote:
            return .mindnote
        case .sheet:
            return .sheet
        case .bitable:
            return .bitable
        case .slides:
            return .slides
        case .doc:
            return .doc
        case .docX:
            return .docx
        case .file:
            return .drive
        case .wiki:
            return .wiki
        default:
            return nil
        }
    }
}

///文档list左滑点击“…”后出现的view上的点击
enum RightClickMenuClickParameter {
    case share
    case copyLink(isFolder: Bool, isShareFolder: Bool)
    case createCopy
    case addToFolder
    case addShortCut
    case moveToFolder
    case quickAccessItem(add: Bool)
    case favoritesItem(add: Bool, isShareFolder: Bool)
    case followItem(add: Bool)
    case more //ipad更多
    case offlineItem(on: Bool)
    case openInOtherApp(isShareFolder: Bool)
    case export(type: String)
    case delete
    case convertToOnline(type: String)
    case saveToLocal
    case subscribe
    case applyEditPermission
    case retention
    case removeFromRecent

    ///一级参数
    var clickValue: String {
        switch self {
        case .share: return "share"
        case .copyLink: return "copy_link"
        case .createCopy: return "create_copy"
        case .addToFolder: return "add_to_folder"
        case .addShortCut: return "create_shortcut"
        case .moveToFolder: return "move_to_folder"
        case let .quickAccessItem(add): return (add ? "add_to_quickaccess" : "remove_from_quickaccess")
        case let .favoritesItem(add, _): return (add ? "add_to_favorites" : "remove_from_favorites")
        case let .followItem(add): return (add ? "follow_open" : "follow_close")
        case .more: return "more"
        case let .offlineItem(on): return (on ? "turn_on_offline" : "turn_off_offline")
        case .openInOtherApp: return "open_in_other_apps"
        case .export: return "exports_as"
        case .delete: return "delete"
        case .convertToOnline: return "convert_to_online"
        case .saveToLocal: return "download"
        case .subscribe: return "subscribe"
        case .applyEditPermission: return "permission_read_without_edit"
        case .retention: return "retention"
        case .removeFromRecent: return "remove_from_recent"
        }
    }

    ///二级参数
    var targetValue: String {
        switch self {
        case .addToFolder, .moveToFolder, .addShortCut:
            return "ccm_space_add_to_folder_view"
        case .more:
            return "ccm_space_right_click_menu_more_view"
        case .convertToOnline:
            return "ccm_docs_page_view"
        case .delete:
            return "ccm_space_delete_view"
        case .share:
            return "ccm_permission_share_view"
        case .retention:
            return "ccm_space_retention_setting_view"
        default:
            return "none"
        }
    }
}

extension DocsTracker {

    ///文档list左滑点击“…”后出现的view
    static func reportSpaceRightClickMenuView(_ tracker: ListMoreItemClickTracker,
                                              _ isFollow: Bool,
                                              enumEvent: EventType = .spaceRightClickMenuView,
                                              bizParms: SpaceBizParameter,
                                              useNewLog: Bool = false) {
        var params = ["is_shared_folder": String(tracker.isShareFolder),
                      "is_follow": String(isFollow),
                      "original_location": tracker.originInWiki ? "wiki" : "space"]
        params.merge(other: bizParms.params)
        if useNewLog {
            DocsTracker.newLog(enumEvent: enumEvent,
                               parameters: params)
        } else {
            DocsTracker.log(enumEvent: enumEvent,
                            parameters: params)
        }
    }
    ///文档list左滑点击“…”后出现的view上的点击
    static func reportSpaceRightClickMenuClick(tracker: ListMoreItemClickTracker, params: RightClickMenuClickParameter, bizParms: SpaceBizParameter) {
        var dic: [String: Any] = ["click": params.clickValue, "target": params.targetValue.isEmpty ? "none" : params.targetValue]
        dic.merge(other: bizParms.params)
        switch params {
        case let .copyLink(isFolder: isFolder, isShareFolder: isShareFolder):
            dic["is_folder"] = String(isFolder)
            dic["is_shared_folder"] = String(isShareFolder)
        case let .favoritesItem(_, isShareFolder):
            dic["is_shared_folder"] = String(isShareFolder)
            dic["view_from"] = "more"
        case let .openInOtherApp(isShareFolder):
            dic["is_shared_folder"] = String(isShareFolder)
        case let .export(type):
            dic["export_as"] = type
        case let .convertToOnline(type):
            dic["convert_type"] = type
        default: break
        }
        var enumEvent: EventType = .spaceRightClickMenuClick
        if tracker.isBitableHome {
            enumEvent = .bitableHomeMoreMenuViewClick
            dic["current_sub_view"] = tracker.subModule?.rawValue
            DocsTracker.newLog(enumEvent: enumEvent, parameters: dic)
            return
        }
        DocsTracker.log(enumEvent: enumEvent, parameters: dic)
    }

    ///bitable Home页面文档list左滑点击“…”后出现的view
    static func reportBitableHomeRightClickMenuView(_ tracker: ListMoreItemClickTracker, _ isFollow: Bool, bizParms: SpaceBizParameter) {
        reportSpaceRightClickMenuView(tracker, isFollow, enumEvent: .bitableHomeMoreMeunView, bizParms: bizParms, useNewLog: true)
    }
}

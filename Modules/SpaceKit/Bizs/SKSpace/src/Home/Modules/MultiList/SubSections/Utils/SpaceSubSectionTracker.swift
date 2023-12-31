//
//  SpaceSubSectionTracker.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/25.
//

import Foundation
import SKCommon
import SKFoundation
import LKCommonsTracker
import Homeric
import SpaceInterface

private extension SpaceListDisplayMode {
    var statisticValue: String {
        switch self {
        case .grid:
            return "grid"
        case .list:
            return "list"
        }
    }
}

private extension SlideAction {
    static let key = "action"
    var statisticValue: String {
        switch self {
        case .readyToDelete:
            return "delete"
        case .delete, .deleteDisable:
            return "deleted"
        case .share, .shareDisable:
            return "share"
        case .move:
            return "moveto"
        case .rename:
            return "rename"
        case .copyURL:
            return "copy_link"
        case .cancel:
            return "cancel"
        case .addTo:
            return "addto"
        case .addShortCut:
            return "add_shortCut"
        case .trashDelete:
            return "remove_complete"
        case .trashRestore:
            return "restore"
        case .addToPin:
            return "add_quickaccess"
        case .removeFromPin:
            return "remove_quickaccess"
        case .star:
            return "add_favorites"
        case .unstar:
            return "remove_favorites"
        case .subscribe:
            return "subscribe"
        case .openWithOtherApp:
            return "open_with_other_app"
        default:
            return ""
        }
    }
}

public struct SpaceSubSectionTracker: SpaceTracker {
    enum ActionSource: String {
        static let key = "source"
        case slide = "left_slide"
        case gridMore = "grid_more"
    }

    var module: PageModule { bizParameter.module }
    var params: [String: String] { bizParameter.params }
    private(set) var bizParameter: SpaceBizParameter
    // 记录筛选和排序选项是因为 clientContentManagement 事件需要上报，所以在 tracker 内存一份状态
    var filterAction: String?
    var sortAction: String?

    // moreViewController 和 slideActionManager 的回调中没有记录 source，因此记在 tracker 内
    var source = ActionSource.slide

    var defaultParams: P {
        [
            PageModule.key: module.rawValue
        ]
    }

    public static func reportEnter(module: PageModule) {
        SpaceSubSectionTracker(bizParameter: SpaceBizParameter(module: module)).reportEnter(module: module.rawValue, subModule: module.subRawValue, srcModule: "home")
    }

    public static func reportEnter(module: PageModule, srcModule: PageModule?) {
        SpaceSubSectionTracker(bizParameter:
                                SpaceBizParameter(module: .home(.recent))).reportEnter(module: module.rawValue,
                                                                                       subModule: module.subRawValue,
                                                                                       srcModule: srcModule?.rawValue)
    }
    // 进入模块上报
    func reportEnter(module: String, subModule: String?, srcModule: String?) {
        var params: P = ["module": module]
        var moduleString = module
        if let sub = subModule {
            params["sub_module"] = sub
            moduleString = sub
        }
        if let src = srcModule {
            params["src_module"] = src
        }
        SKCreateTracker.moduleString = moduleString
        SKCreateTracker.srcModuleString = srcModule ?? SKCreateTracker.srcModuleString
        if moduleString == StatisticModule.recent.rawValue || moduleString == StatisticModule.quickaccess.rawValue {
            SKCreateTracker.subModuleString = moduleString
            SKCreateTracker.srcModuleString = StatisticModule.home.rawValue
        }
        Tracker.post(TeaEvent(Homeric.DOCS_ENTER_EXPLORER_MODULE, params: params))
    }

    func reportEnter(folderToken: String, isShareFolder: Bool, currentModule: String, currentFolderToken: String?, subModule: String?) {
        let targetModule = isShareFolder ? "shared_folder" : "folder"

        var params: [String: String] = [
            "src_module": currentModule,
            "module": targetModule
        ]

        if let currentFolderToken = currentFolderToken {
            let currentFolderID = DocsTracker.encrypt(id: currentFolderToken)
            params["src_folder_id"] = currentFolderID
        }
        Tracker.post(TeaEvent(Homeric.DOCS_ENTER_EXPLORER_MODULE, params: params))
    }
    
    func reportFileListView(subView: String) {
        DocsTracker.reportBitableHomePageEvent(enumEvent: .baseHomepageFilelistView, parameters:  [
            "current_sub_view": subView
        ], bizParams: bizParameter)
    }

    func reportChangeDisplayMode(newMode: SpaceListDisplayMode, subModule: HomePageSubModule? = nil) {
        var params = defaultParams
        params["view"] = newMode.statisticValue
        DocsTracker.log(enumEvent: .clickViewSwitch, parameters: params)

        switch module {
        case .favorites, .personal, .offline, .shared:
            DocsTracker.reportSpacePagePageClick(enumEvent: DocsTracker.clickEventType(for: module),
                                                 params: .viewSwitch(subView: nil),
                                                 bizParms: SpaceBizParameter(module: module))
        case let .home(sub):
            DocsTracker.reportSpacePagePageClick(enumEvent: DocsTracker.clickEventType(for: module),
                                                 params: .viewSwitch(subView: sub),
                                                 bizParms: SpaceBizParameter(module: module))
        case .baseHomePage:
            DocsTracker.reportSpacePagePageClick(enumEvent: .baseHomepageFilelistClick,
                                                 params: .viewSwitch(subView: subModule),
                                                 bizParms: SpaceBizParameter(module: module),
                                                 userNewLog: true)
        case .sharedFolderRoot, .personalFolderRoot:
            DocsTracker.reportSpaceFolderClick(params: .viewSwitch(isShareFolder: bizParameter.isFolder),
                                             bizParms: SpaceBizParameter(module: module))
        case .personalSubFolder, .sharedSubFolder:
            DocsTracker.reportSpaceFolderClick(params: .viewSwitch(isShareFolder: bizParameter.isFolder),
                                                 bizParms: bizParameter)

        default: break
        }
    }

    func reportClickFilterPanel() {
        // 这个事件还有个file_type参数，但是没有上报过，也不知道要上报啥，暂时留空
        DocsTracker.log(enumEvent: .clickFilterBoard, parameters: defaultParams)
    }

    mutating func reportFilterPanelUpdated(action: String, filterAction: String?, sortAction: String?) {
        self.filterAction = filterAction
        self.sortAction = sortAction
        var params = defaultParams
        params["source"] = "filter_board"
        params["action"] = action
        params["filter_action"] = filterAction ?? ""
        params["sort_action"] = sortAction ?? ""
        DocsTracker.log(enumEvent: .clientContentManagement, parameters: params)
    }

    func reportClickGridMore(entryType: DocsType) {
        let params: P = [
            PageModule.key: module.rawValue,
            "file_type": entryType.fileTypeForSta
        ]
        DocsTracker.log(enumEvent: .clickGridMore, parameters: params)
    }

    func reportClick(slideAction: SlideAction) {
        let params: P = [
            PageModule.key: module.rawValue,
            SlideAction.key: slideAction.statisticValue
            // 还有一个 subModule 参数，但是不知道要传什么值，暂时先不传
        ]
        DocsTracker.log(enumEvent: .clickLeftSlide, parameters: params)

        var subView: HomePageSubModule?
        if case let .home(sub) = module {
            subView = sub
        }
        var userNewLog = false
        if case .baseHomePage = module {
            userNewLog = true
        }
        switch slideAction {
        case .more:
            DocsTracker.reportSpacePagePageClick(enumEvent: DocsTracker.clickEventType(for: module, slideAction: slideAction),
                                                 params: .more(subView: subView, pageModule: module),
                                                 bizParms: bizParameter,
                                                 userNewLog: userNewLog)
        case .share:
            DocsTracker.reportSpacePagePageClick(enumEvent: DocsTracker.clickEventType(for: module, slideAction: slideAction),
                                                 params: .share,
                                                 bizParms: bizParameter,
                                                 userNewLog: userNewLog)
        case .readyToDelete:
            DocsTracker.reportSpacePagePageClick(enumEvent: DocsTracker.clickEventType(for: module, slideAction: slideAction),
                                                 params: .delete,
                                                 bizParms: bizParameter,
                                                 userNewLog: userNewLog)
        case .removeFromPin:
            DocsTracker.reportSpacePagePageClick(enumEvent: DocsTracker.clickEventType(for: module, slideAction: slideAction),
                                                 params: .removeQuickAccess,
                                                 bizParms: bizParameter,
                                                 userNewLog: userNewLog)
        case .addToPin:
            DocsTracker.reportSpacePagePageClick(enumEvent: DocsTracker.clickEventType(for: module, slideAction: slideAction),
                                                 params: .addQuickAccess,
                                                 bizParms: bizParameter,
                                                 userNewLog: userNewLog)
        case .star:
            DocsTracker.reportSpacePagePageClick(enumEvent: DocsTracker.clickEventType(for: module, slideAction: slideAction),
                                                 params: .addFavorites,
                                                 bizParms: bizParameter,
                                                 userNewLog: userNewLog)
        case .unstar:
            DocsTracker.reportSpacePagePageClick(enumEvent: DocsTracker.clickEventType(for: module, slideAction: slideAction),
                                                 params: .removeFavorites,
                                                 bizParms: bizParameter,
                                                 userNewLog: userNewLog)
        case .remove:
            if case .baseHomePage = module {
                DocsTracker.reportSpacePagePageClick(enumEvent: DocsTracker.clickEventType(for: module, slideAction: slideAction),
                                                     params: .delete,
                                                     bizParms: bizParameter,
                                                     userNewLog: true)
            }
        default:
            break
        }
    }

    func reportClientContentManagement(for entry: SpaceEntry, action: SlideAction) {
        var params: P = [
            PageModule.key: module.rawValue,
            ActionSource.key: source.rawValue,
            "action": action.statisticValue,
            "file_type": entry.type.fileTypeForSta,
            "file_id": DocsTracker.encrypt(id: entry.objToken)
        ]
        if let sortAction = sortAction {
            params["sort_action"] = sortAction
        }
        if let filterAction = filterAction {
            params["filter_action"] = filterAction
        }
        DocsTracker.log(enumEvent: .clientContentManagement, parameters: params)
    }

    func reportToggleStar(isStar: Bool, for entry: SpaceEntry) {
        let params: P = [
            PageModule.key: module.rawValue,
            "file_id": DocsTracker.encrypt(id: entry.objToken),
            "file_type": entry.type.fileTypeForSta
        ]
        if isStar {
            DocsTracker.log(enumEvent: .clickFileStar, parameters: params)
        } else {
            DocsTracker.log(enumEvent: .clickFileCancelStar, parameters: params)
        }
    }

    func reportTogglePin(isPin: Bool, for entry: SpaceEntry) {
        let params: P = [
            PageModule.key: module.rawValue,
            "file_id": DocsTracker.encrypt(id: entry.objToken),
            "file_type": entry.type.fileTypeForSta
        ]
        if isPin {
            DocsTracker.log(enumEvent: .clickFilePin, parameters: params)
        } else {
            DocsTracker.log(enumEvent: .clickFilePinCancel, parameters: params)
        }
    }

    func reportClick(entry: SpaceEntry, at index: Int, pageModule: PageModule? = nil, pageSubModule: HomePageSubModule? = nil) {
        let params: P = [
            PageModule.key: module.rawValue,
            "sequence_num": String(index),
            "folder_level": "0",
            "file_type": entry.type.fileTypeForSta,
//            "location": "" // 不知道什么含义，一直都没有传，先不管
            "file_id": DocsTracker.encrypt(id: entry.objToken),
            "group": entry.openDateIdentify()
        ]
        DocsTracker.log(enumEvent: .clickListItem, parameters: params)

        bizParameter.update(fileID: entry.objToken, fileType: entry.docsType, driveType: (entry as? FolderEntry)?.fileType)

        let isFolder = entry.type == .folder
        let isShareFolder = entry.isShareFolder

        var enumEvent = DocsTracker.clickEventType(for: module)
        var clickParams: SpacePageClickParameter = .listItem(isFolder: isFolder, isShareFolder: isShareFolder, isSubFolder: false, folderLevel: 0, pageModule: pageModule, pageSubModule: pageSubModule)
        switch module {
        case .sharedSubFolder, .personalSubFolder, .sharedFolderRoot, .personalFolderRoot:
            clickParams = .listItem(isFolder: isFolder, isShareFolder: isShareFolder, isSubFolder: true, folderLevel: 0, pageModule: pageModule, pageSubModule: pageSubModule)
        default: break
        }
        var userNewLog = false
        if case .baseHomePage = module {
            enumEvent = .baseHomepageFilelistClick
            userNewLog = true
        }

        DocsTracker.reportSpacePagePageClick(enumEvent: enumEvent, params: clickParams, bizParms: bizParameter, userNewLog: userNewLog)
    }
}

struct SpaceListCellTracker: SpaceTracker {
    private(set) var bizParameter: SpaceBizParameter
    var module: PageModule { bizParameter.module }
    var itemType: DocsType { bizParameter.fileType ?? .doc }

    var defaultParams: P {
        [
            PageModule.key: module.rawValue
        ]
    }

    // 以下三个事件的上报时机相同，参数也基本相同
    func reportLeftSlide() {
        DocsTracker.log(enumEvent: .leftSlide, parameters: defaultParams)
    }

    func reportShowListSlide() {
        var params = defaultParams
        params["file_type"] = itemType.fileTypeForSta
        DocsTracker.log(enumEvent: .showListSlide, parameters: params)
    }

    func reportShowLeftSlide() {
        DocsTracker.log(enumEvent: .showLeftSlide, parameters: defaultParams)
    }
}

//
//  FileListStatistics.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/8/18.
//  

import SKFoundation
import SpaceInterface
import LarkContainer

public enum PageModule {
    public static let key = "module"
    case home(_ subModule: HomePageSubModule)
    case personal(_ subModule: PersonalPageSubModule)
    case shared(_ subModule: SharedPageSubModule)
    case favorites
    case offline
    case todo
    case template
    case personalFolderRoot //个人文件夹（根目录）
    case sharedFolderRoot //共享文件夹（根目录）
    case personalSubFolder //个人文件夹（子文件夹）
    case sharedSubFolder //共享文件夹（子文件夹）
    case shareFolderV2Root  //新共享文件夹(根目录)
    case homeTree   // 新首页目录树
    case subordinateRecent
    case newDrive(_ subModule: NewDrivePageSubModule)  // 新云盘页面

    //非space内部
    case drive
    case doc
    case docx
    case sheet
    case wiki
    case mindnote
    case bitable
    case slides
    case wikiHome
    case wikiSpace
    case baseHomePage(context: BaseHomeContext)
    case search
    case email
    case calendar

    public var rawValue: String {
        switch self {
        case .home: return "home"
        case .personal: return "personal"
        case .shared: return "shared"
        case .favorites: return "favorites"
        case .offline:  return "offline"
        case .todo: return "todo"
        case .personalFolderRoot: return "personal_folder_root"
        case .sharedFolderRoot, .shareFolderV2Root: return "shared_folder_root"
        case .personalSubFolder: return "personal_subfolder"
        case .sharedSubFolder: return "shared_subfolder"
        case .template: return "template"
        case .drive: return "drive"
        case .doc: return "doc"
        case .docx: return "docx"
        case .sheet: return "sheet"
        case .wiki: return "wiki"
        case .mindnote: return "mindnote"
        case .bitable: return "bitable"
        case .slides: return "slides"
        case .wikiHome: return "wiki_home"
        case .wikiSpace: return "wiki_space"
        case .search: return "search"
        case .email: return "email"
        case .calendar: return "calendar"
        case let .baseHomePage(context):
            return context.moduleName
        case .homeTree: return "sidebar"
        case .subordinateRecent: return "subordinate_recent"
        case .newDrive: return "new_drive"
        }
    }

    public var subRawValue: String? {
        switch self {
        case let .home(sub):
            return sub.rawValue
        case let .personal(sub):
            return sub.rawValue
        case let .shared(sub):
            return sub.rawValue
        case let .newDrive(sub):
            return sub.rawValue
        default:
            return nil
        }
    }

    public static func typeFor(tabID subTabID: String) -> Self? {
        switch subTabID {
        case "recent":
            return .home(.recent)
        case "pin":
            return .home(.quickaccess)
        case "homeAssembleTree":
            return .home(.catalogue)
        case "personal":
            return .newDrive(.personal)
        case "share-folder":
            return .newDrive(.shared)
        default:
            return nil
        }
    }
}

extension PageModule {

    public func generateCCMOpenCreateSource(isBaseForm: Bool = false) -> CCMOpenCreateSource {
        switch self {
        case .home:
            return .home
        case .personal, .personalFolderRoot, .personalSubFolder, .newDrive:
            return .personal
        case .shared, .sharedFolderRoot, .sharedSubFolder, .shareFolderV2Root:
            return .shared
        case .template:
            return .templateCenter
        case .wikiHome, .wikiSpace:
            return .wiki
        case let .baseHomePage(context):
            if isBaseForm {
                return context.containerEnv == .larkTab ? .baseHomeLarkTabForm : .baseHomeWorkbenchForm
            } else {
                return context.openCreateSource
            }
        case .favorites, .offline, .todo:
            return .home
        /// 这里不用 default 是为了防止后面添加没有映射到对应的地方。
        case .drive, .doc, .docx, .sheet, .wiki, .mindnote, .bitable, .slides, .search, .email, .calendar, .homeTree, .subordinateRecent:
            return .unknow
        }
    }

    /// 服务端需要区分创建副本来自那个模块：45 代表 bitable 工作台列表触发的创建副本，其他模块默认为
    public var copySource: Int {
        switch self {
        case .baseHomePage: return 45
        default: return 7
        }
    }
}

public enum HomePageSubModule: String {
    case recent
    case quickaccess = "quick_access"
    case favorites = "favorites"
    case homeTree = "sidebar"
    case catalogue
}

public enum PersonalPageSubModule: String {
    case personalFolder = "personal_folder" //个人空间上半部分
    case belongtome  //归我所有
    case none   //无上下分栏
}

public enum SharedPageSubModule: String {
    case sharedFolder = "shared_folder" //共享空间上半部分
    case sharetome    //与我共享
}

public enum NewDrivePageSubModule: String {
    case personal  // 我的文件夹
    case shared  // 共享文件夹
}

//https://bytedance.feishu.cn/space/doc/doccnaUFCD5u3vQ8jVRgdyjCRAc#
public enum FileListStatistics {
    /// 一级页面模块名
    public enum Module: String {
        case unknown
        case quickaccess = "quickaccess"
        case home = "home"// 最近列表
        case recent = "recent"
        case personalFolder = "personal_folder"
        case personal = "personal"
        case sharedSpace = "sharetome"
        case sharedFolder = "shared_folder"
        case favorites = "favorites"
        case manualOffline = "offline"
        case folder = "folder"
        case search = "search"
        case moveToWiki = "move_to_wiki"
        case bitableHome = "bitable_landing"
        
        case baseHomeLarkTabRecent = "base_hp_larktab_recent"
        case baseHomeLarkTabEmptyBase = "base_hp_larktab_empty_base"
        case baseHomeLarkTabForm = "base_hp_larktab_form"
        case baseHomeLarkTabQuickAccess = "base_hp_larktab_quickaccess"
        case baseHomeLarkTabFavorites = "base_hp_larktab_favorites"
        case baseHomeLarkTabComment = "base_hp_larktab_comment"
        case baseHomeLarkTabMention = "base_hp_larktab_mention"
        
        case baseHomeWorkbenchRecent = "base_hp_workbench_recent"
        case baseHomeWorkbenchEmptyBase = "base_hp_workbench_empty_base"
        case baseHomeWorkbenchForm = "base_hp_workbench_form"
        case baseHomeWorkbenchQuickAccess = "base_hp_workbench_quickaccess"
        case baseHomeWorkbenchFavorites = "base_hp_workbench_favorites"
        case baseHomeWorkbenchComment = "base_hp_workbench_comment"
        case baseHomeWorkbenchMention = "base_hp_workbench_mention"

        /// home v4 larktab
        case baseHomeLarkTabRecentV4 = "base_hp_larktab_recent_hpmobile_v2"
        case baseHomeLarkTabQuickAccessV4 = "base_hp_larktab_quickaccess_hpmobile_v2"
        case baseHomeLarkTabFavoritesV4 = "base_hp_larktab_favorites_hpmobile_v2"
        case baseHomeLarkTabEmptyBaseV4 = "base_hp_larktab_empty_base_hpmobile_v2"
        case baseHomeLarkTabFeedV4 = "homepage_feed_larktab_hpmobile_v2"
        /// home v4 workbench
        case baseHomeWorkbenchRecentV4 = "base_hp_workbench_recent_hpmobile_v2"
        case baseHomeWorkbenchQuickAccessV4 = "base_hp_workbench_quickaccess_hpmobile_v2"
        case baseHomeWorkbenchFavoritesV4 = "base_hp_workbench_favorites_hpmobile_v2"
        case baseHomeWorkbenchEmptyBaseV4 = "base_hp_workbench_empty_base_hpmobile_v2"
        case baseHomeWorkbenchFeedV4 = "homepage_feed_workbench_hpmobile_v2"

        // Drive 的埋点 From
        public func converToDriveFrom() -> DrivePreviewFrom {
            switch self {
            case .quickaccess:      return .pin
            case .home:             return .recent
            case .recent:           return .recent
            case .personalFolder:   return .personalFolder
            case .personal:         return .personal
            case .sharedSpace:      return .sharedSpace
            case .sharedFolder:     return .sharedFolder
            case .favorites:        return .favorites
            case .manualOffline:    return .offline
            case .search:           return .search
            case .folder:           return .personalFolder
            case .unknown:          return .docsList
            case .moveToWiki:       return .unknown
            case .bitableHome:      return .unknown
            case .baseHomeLarkTabRecent:         return .unknown
            case .baseHomeLarkTabEmptyBase:      return .unknown
            case .baseHomeLarkTabForm:           return .unknown
            case .baseHomeLarkTabQuickAccess:    return .unknown
            case .baseHomeLarkTabFavorites:      return .unknown
            case .baseHomeLarkTabComment:        return .unknown
            case .baseHomeLarkTabMention:        return .unknown
            case .baseHomeWorkbenchRecent:         return .unknown
            case .baseHomeWorkbenchEmptyBase:      return .unknown
            case .baseHomeWorkbenchForm:           return .unknown
            case .baseHomeWorkbenchQuickAccess:    return .unknown
            case .baseHomeWorkbenchFavorites:      return .unknown
            case .baseHomeWorkbenchComment:        return .unknown
            case .baseHomeWorkbenchMention:        return .unknown
            case .baseHomeLarkTabRecentV4:         return .unknown
            case .baseHomeLarkTabQuickAccessV4:    return .unknown
            case .baseHomeLarkTabFavoritesV4:      return .unknown
            case .baseHomeLarkTabEmptyBaseV4:      return .unknown
            case .baseHomeLarkTabFeedV4:           return .unknown
            case .baseHomeWorkbenchRecentV4:       return .unknown
            case .baseHomeWorkbenchQuickAccessV4:  return .unknown
            case .baseHomeWorkbenchFavoritesV4:    return .unknown
            case .baseHomeWorkbenchEmptyBaseV4:    return .unknown
            case .baseHomeWorkbenchFeedV4:         return .unknown
            }
        }
        // Docs 详情页的 From
        public func converToDocsFrom() -> FromSource {
            switch self {
            case .quickaccess:      return .quickAccess
            case .home:             return .recent
            case .recent:           return .recent
            case .personalFolder:   return .personalFolder
            case .personal:         return .personal
            case .sharedSpace:      return .shareSpace
            case .folder:           return .personalFolder
            case .sharedFolder:     return .sharedFolder
            case .favorites:        return .favorites
            case .manualOffline:    return .other
            case .search:           return .search
            case .unknown:          return .other
            case .moveToWiki:       return .moveToWiki
            case .bitableHome:      return .bitableHome
            case .baseHomeLarkTabRecent:      return .baseHomeLarkTabRecent
            case .baseHomeLarkTabEmptyBase:   return .baseHomeLarkTabEmptyBase
            case .baseHomeLarkTabForm:        return .baseHomeLarkTabForm
            case .baseHomeLarkTabQuickAccess: return .baseHomeLarkTabQuickAccess
            case .baseHomeLarkTabFavorites:   return .baseHomeLarkTabFavorites
            case .baseHomeLarkTabComment:     return .baseHomeLarkTabComment
            case .baseHomeLarkTabMention:     return .baseHomeLarkTabMention
            case .baseHomeWorkbenchRecent:         return .baseHomeWorkbenchRecent
            case .baseHomeWorkbenchEmptyBase:      return .baseHomeWorkbenchEmptyBase
            case .baseHomeWorkbenchForm:           return .baseHomeWorkbenchForm
            case .baseHomeWorkbenchQuickAccess:    return .baseHomeWorkbenchQuickAccess
            case .baseHomeWorkbenchFavorites:      return .baseHomeWorkbenchFavorites
            case .baseHomeWorkbenchComment:        return .baseHomeWorkbenchComment
            case .baseHomeWorkbenchMention:        return .baseHomeWorkbenchMention
            case .baseHomeLarkTabRecentV4:         return .baseHomeLarkTabRecentV4
            case .baseHomeLarkTabQuickAccessV4:    return .baseHomeLarkTabQuickAccessV4
            case .baseHomeLarkTabFavoritesV4:      return .baseHomeLarkTabFavoritesV4
            case .baseHomeLarkTabEmptyBaseV4:      return .baseHomeLarkTabEmptyBaseV4
            case .baseHomeLarkTabFeedV4:           return .baseHomeLarkTabFeedV4
            case .baseHomeWorkbenchRecentV4:       return .baseHomeWorkbenchRecentV4
            case .baseHomeWorkbenchQuickAccessV4:  return .baseHomeWorkbenchQuickAccessV4
            case .baseHomeWorkbenchFavoritesV4:    return .baseHomeWorkbenchFavoritesV4
            case .baseHomeWorkbenchEmptyBaseV4:    return .baseHomeWorkbenchEmptyBaseV4
            case .baseHomeWorkbenchFeedV4:         return .baseHomeWorkbenchFeedV4
            }
        }

//        public func converToPageModule() -> PageModule {
//            switch self {
//            case .quickaccess:      return .home(.quickaccess)
//            case .home, .recent:    return .home(.recent)
//            case .personalFolder:   return .personalFolderRoot
//            case .personal:         return .personal(.belongtome)
//            case .sharedSpace:      return .shared(.sharetome)
//            case .folder:           return .personalSubFolder
//            case .sharedFolder:     return .sharedSubFolder
//            case .favorites:        return .favorites
//            case .manualOffline:    return .offline
//            case .search:           return .home(.recent)
//            case .unknown:          return .home(.recent)
//            case .moveToWiki:        return .home(.recent)
//            }
//        }

        public func converToCCMOpenType() -> CCMOpenType {
            switch self {
            case .quickaccess:      return .homePin
            case .home, .recent:    return .homeRecent
            case .folder:           return .personalFolder
            case .personalFolder:   return .personalFolder
            case .personal:         return .personalOwn
            case .sharedSpace:      return .sharedShareToMe
            case .sharedFolder:     return .sharedSharedFolder
            case .favorites:        return .favorites
            case .manualOffline:    return .offline
            case .search:           return .personalSearch
            case .unknown, .moveToWiki: return .unknow
            case .bitableHome:       return .bitableHome
            case .baseHomeLarkTabRecent:      return .baseHomeLarkTabRecent
            case .baseHomeLarkTabEmptyBase:   return .baseHomeLarkTabEmptyBase
            case .baseHomeLarkTabForm:        return .baseHomeLarkTabForm
            case .baseHomeLarkTabQuickAccess: return .baseHomeLarkTabQuickAccess
            case .baseHomeLarkTabFavorites:   return .baseHomeLarkTabFavorites
            case .baseHomeLarkTabComment:     return .baseHomeLarkTabComment
            case .baseHomeLarkTabMention:     return .baseHomeLarkTabMention
            case .baseHomeWorkbenchRecent:         return .baseHomeWorkbenchRecent
            case .baseHomeWorkbenchEmptyBase:      return .baseHomeWorkbenchEmptyBase
            case .baseHomeWorkbenchForm:           return .baseHomeWorkbenchForm
            case .baseHomeWorkbenchQuickAccess:    return .baseHomeWorkbenchQuickAccess
            case .baseHomeWorkbenchFavorites:      return .baseHomeWorkbenchFavorites
            case .baseHomeWorkbenchComment:        return .baseHomeWorkbenchComment
            case .baseHomeWorkbenchMention:        return .baseHomeWorkbenchMention
            case .baseHomeLarkTabRecentV4:         return .baseHomeLarkTabRecentV4
            case .baseHomeLarkTabQuickAccessV4:    return .baseHomeLarkTabQuickAccessV4
            case .baseHomeLarkTabFavoritesV4:      return .baseHomeLarkTabFavoritesV4
            case .baseHomeLarkTabEmptyBaseV4:      return .baseHomeLarkTabEmptyBaseV4
            case .baseHomeLarkTabFeedV4:           return .baseHomeLarkTabFeedV4
            case .baseHomeWorkbenchRecentV4:       return .baseHomeWorkbenchRecentV4
            case .baseHomeWorkbenchQuickAccessV4:  return .baseHomeWorkbenchQuickAccessV4
            case .baseHomeWorkbenchFavoritesV4:    return .baseHomeWorkbenchFavoritesV4
            case .baseHomeWorkbenchEmptyBaseV4:    return .baseHomeWorkbenchEmptyBaseV4
            case .baseHomeWorkbenchFeedV4:         return .baseHomeWorkbenchFeedV4
            }
        }
    }

   public  enum Source: String {
        case filterBoard = "filter_board"
        case innerpageMore = "innerpage_more"
        case leftSlide = "left_slide"
        case gridMore = "grid_more"
        case innerFolder = "inner_folder"
    }

    public enum Action: String {
        case done
        case reset
        case addto
        case delete
        case remove
        case addQuickAccess = "add_quickaccess"
        case removeQuickAccess = "remove_quickaccess"
        case addFavorites = "add_favorites"
        case documentDetail = "document_detail"
        case contact
        case uploadLog = "upload_log"
        case searchReplace = "search_replace"
        case historyRecord = "history_record"
        case openWithOtherApp = "open_with_other_app"
        case rename
        case readingData = "reading_data"
        case publicPermissionSetting = "public_permission_setting"
        case copyLink = "copy_link"
        case addManuOffline = "add_offline"
        case removeManuOffline = "remove_offline"
        case hiddenStatus = "hiddenStatus"

    }

    /// 当前操作的文档，在关键入口和操作点更新这个值，
    /// 仅仅用于统计埋点，不能用于做业务
    public static var curFileObjToken: FileListDefine.ObjToken?
    public static var curEnObjToken: String? {
        guard let objToken = curFileObjToken else { return "" }
        return DocsTracker.encrypt(id: objToken)
    }
    public static var curFileType: DocsType?

    public static var module: Module?
    public static var source: Source?

    public static func prepareStatisticsData(_ label: DataModelLabel) {
        switch label {
        case .recent:
            FileListStatistics.module = .home
        case .personal:
            FileListStatistics.module = .personal
        case .folderDetail:
            FileListStatistics.module = .personalFolder
        case .shareFolder:
            FileListStatistics.module = .sharedFolder
        case .shareFiles:
            FileListStatistics.module = .sharedSpace
        case .manuOffline:
            FileListStatistics.module = .manualOffline
        case .bitableLanding:
            FileListStatistics.module = .bitableHome
        default:()

        }
    }

    public static func reportClientContentManagement(action: Action, params: [String: Any]?) {
        var newParams = [String: Any]()
        if let paramsLo = params {
            newParams = paramsLo
        }
        newParams["action"] = action.rawValue
        newParams = addParamsInto(newParams)
        reportClientContentManagement(params: newParams)
    }
    public static func reportClientContentManagement(params: [String: Any]?) {
        DocsTracker.log(enumEvent: .clientContentManagement, parameters: params)
    }

    public static func addParamsInto(_ params: [String: Any]?) -> [String: Any] {
        var newParams = [String: Any]()
        if let paramsLo = params {
            newParams = paramsLo
        }
        if let source = source {
            newParams["source"] = source.rawValue
        }
        if let module = module {
            newParams["module"] = module.rawValue
        }
        return newParams
    }

    public static func reportClientContentManagement(statusName: String, action: String) {
        guard let fileType = FileListStatistics.curFileType?.fileTypeForSta, let fileID = FileListStatistics.curEnObjToken else { return }
        let params = ["source": "innerpage_more",
                      "module": fileType,
                      "status_name": statusName,
                      "action": action,
                      "file_type": fileType,
                      "file_id": fileID] as [String: Any]
        DocsTracker.log(enumEvent: .clientContentManagement, parameters: params)
    }

    public static func reportClickAddtoOperation(action: String, file: SpaceEntry?) {
        guard let fileType = FileListStatistics.curFileType?.fileTypeForSta,
            let fileID = FileListStatistics.curEnObjToken else {
                return
        }
        var params = ["source": "innerpage_more",
                      "module": "home",
                      "action": action,
                      "file_type": fileType,
                      "file_id": fileID] as [String: Any]
        if let source = source {
            params["source"] = source.rawValue
        }
        if let module = module {
            params["module"] = module.rawValue
        }
        DocsTracker.log(enumEvent: .clickAddtoOperation, parameters: params)
    }
}

private let fromModuleKey = "fromModule"
private let fromSubmoduleKey = "fromSubmodule"
extension SpaceEntry {
    // 仅用于埋点，来自哪个模块
    public var fromModule: String? {
        get { return storedExtensionProperty[fromModuleKey] as? String }
        set { updateStoredExtensionProperty(key: fromModuleKey, value: newValue as Any) }
    }

    // 仅用于埋点，来自哪个子模块
    public var fromSubmodule: String? {
        get { return storedExtensionProperty[fromSubmoduleKey] as? String }
        set { updateStoredExtensionProperty(key: fromSubmoduleKey, value: newValue as Any) }
    }
}

public struct BaseHomeContext {
    public enum BaseHomeVersion: String {
        case hp_v2
        case original
    }

    public enum ContainerEnv: String {
        case larkTab = "larktab_bitable"
        case workbench = "workbench"
    }
    
    public let userResolver: UserResolver
    public let containerEnv: ContainerEnv
    public let baseHpFrom: String?
    public let shouldShowRecommend: Bool
    public let version: BaseHomeVersion
    public var extraInfos: [String: String]?

    public init(userResolver: UserResolver,
                containerEnv: ContainerEnv,
                baseHpFrom: String?,
                shouldShowRecommend: Bool = false,
                version: BaseHomeVersion) {
        self.userResolver = userResolver
        self.containerEnv = containerEnv
        self.baseHpFrom = baseHpFrom
        self.shouldShowRecommend = shouldShowRecommend
        self.version = version
    }
}

extension BaseHomeContext {
    var openCreateSource: CCMOpenCreateSource {
        if version == .hp_v2 {
            return containerEnv == .larkTab ? .baseHomeLarkTabEmptyBaseV4 : .baseHomeWorkbenchEmptyBaseV4
        }
        return containerEnv == .larkTab ? .baseHomeLarkTabEmptyBase : .baseHomeWorkbenchEmptyBase
    }

    var moduleName: String {
        if version == .hp_v2 {
            return "base_home"
        }
        return "bitable_home"
    }
}

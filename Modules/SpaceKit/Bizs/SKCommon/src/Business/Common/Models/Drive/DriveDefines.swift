//
//  DriveDefines.swift
//  SKCommon
//
//  Created by lijuyou on 2020/6/5.
//
// swiftlint:disable file_length

import Foundation
import RxSwift
import RxRelay
import RustPB
import EENavigator
import SKResource
import SKFoundation
import LarkSecurityComplianceInterface
import SpaceInterface

// DriveMountTokens
public struct DriveConstants {
    public static let driveMountPoint = "explorer" // space上传的文件挂载点
    public static let wikiMountPoint = "wiki" // wiki上传文件的挂载点
    public static let workspaceMountPoint = "workspace" // space + wiki 上传文件的挂载点
}
//DrivePreloadService.Source
/// 预加载文件来源
///
/// - recent: 最近访问
/// - pin: 快速访问
/// - favorite: 收藏
public enum DrivePreloadSource {
    case recent
    case pin
    case favorite
    case manualOffline
    var priority: DriveDownloadPriority {
        switch self {
        case .manualOffline:
            return .manualOffline
        default:
            return .preload
        }
    }
}

/// 从哪里进入drive文件预览,用于数据上报
// TODO: @chenjiahao.gill 解决这里不合理的 public
public enum DrivePreviewFrom: String {
    case unknown = ""
    /// 来自列表页
    case docsList = "docs_list"
    case message = "message"
    /// 来自docs附件的预览
    case docsAttach = "docs_attach"
    /// 来自sheet单元格附件的预览
    case sheetAttach = "sheet_attach"
    /// 来自docs mention的预览
    case docsMention = "tab_link"
    /// 从历史版本
    case history = "history"
    /// 本地文件预览
    case localFile = "local_file"
    /// 当前只有mail的本地预览会上报到thirdparty
    case thirdParty = "thirdparty_attachment"
    /// 邮箱附件预览
    case mail = "mail"
    /// 日历附件预览
    case calendar = "calendar"
    /// docx附件预览
    case docx = "docx"
    /// bitable附件预览
    case bitableAttach = "bitable_attach"
    /// 来自lark feed
    case larkfeed = "docs_feed"
    /// 来自搜索
    case search = "lark_search"
    /// 来自链接（评论，消息）
    case link = "tab_at"
    /// 来自 VC Follow，取值参考 DocsVCFollowFactory.fromKey
    case vcFollow = "vcFollow"
    /// VC Follow 中的附件预览
    case docsAttachInFollow = "docs_attach_vcFollow"
    case sheetAttachInFollow = "sheet_attach_vcFollow"
    /// 来自 DriveSDK 从云空间打开
    case driveSDK = "drive_sdk"
    /// DriveSDK IM
    case im
    /// DriveSDK 密聊
    case secretIM = "secret_im"
    /// DriveSDK 小程序附件
    case miniApp = "mini_app"
    /// drive接入wiki
    case wiki = "wiki"
    /// 群Tab
    case groupTab = "chat_tabs_docPreview"

    ///开平
    case webBroswer = "webBroswer"

    case recent         = "tab_recent"          // 云空间
    case pin            = "tab_quickaccess"     // 快捷访问
    case favorites      = "tab_favorites"       // 收藏
    case offline        = "tab_offline"         // 离线
    case personal       = "tab_personal"        // 我的空间
    case sharedSpace    = "tab_sharetome"       // 共享空间
    case personalFolder = "tab_personal_folder" // 个人目录
    case sharedFolder   = "tab_shared_folder"   // 共享目录
    case taskList       = "tasklist"            // 多任务

    public var stasticsValue: String {
        switch self {
        case .docsList:
            return "docs_list"
        case .message:
            return "message"
        case .docsAttach:
            return "doc_embed"
        case .docsMention:
            return "doc_mention"
        case .history:
            return "history"
        case .localFile:
            return "local_file"
        case .thirdParty:
            return "thirdparty_attachment"
        case .unknown:
            return "unknown"
        case .larkfeed:
            return "docs_feed"
        case .search:
            return "lark_search"
        case .link:
            return "tab_at"
        default:
            return self.rawValue
        }
    }

    public var isAttachment: Bool {
        switch self {
        case .docx, .docsAttach, .docsAttachInFollow, .sheetAttach, .sheetAttachInFollow:
            return true
        default:
            return false
        }
    }

    public var shouldReportClientFileOpenEvent: Bool {
        switch self {
        // VC Follow 中、本地文件打开不上报 fileOpen 事件
        case .docsAttachInFollow, .sheetAttachInFollow, .vcFollow, .localFile:
            return false
        default:
            return true
        }
    }

    public var shouldShowNewScene: Bool {
        switch self {
        case .docsAttach, .docsAttachInFollow, .sheetAttach, .sheetAttachInFollow, .vcFollow, .mail, .calendar, .localFile, .unknown:
            return false
        default:
            return true
        }
    }

    /// 业务方所认为的使用 DriveSDK 能力入口
    public var isDriveSDK: Bool {
        switch self {
        case .docsAttach, .sheetAttach, .docsAttachInFollow, .sheetAttachInFollow, // ccm附件
             .mail, .calendar, .docx, .bitableAttach, // 第三方附件
             .im, // im附件
             .miniApp, .secretIM: // 本地附件
            return true
        default:
            return false
        }
    }

    public var driveSDKApp: DKSupportedApp? {
        switch self {
        case .docsAttach, .docsAttachInFollow:
            return .doc
        case .sheetAttach, .sheetAttachInFollow:
            return .sheet
        case .im:
            return .im
        case .mail:
            return .mail
        case .calendar:
            return .calendar
        case .docx:
            return .docx
        case .bitableAttach:
            return .bitable
        case .miniApp:
            return .miniApp
        case .secretIM:
            return .secretIM
        case .docsList, .docsMention, .history, .favorites,
             .larkfeed, .link, .localFile, .message, .offline,
             .personal, .personalFolder, .pin, .recent, .search,
             .sharedSpace, .sharedFolder, .taskList, .vcFollow, .unknown, .wiki, .groupTab:
            return nil
        case .driveSDK, .thirdParty:
            spaceAssertionFailure("this preview from will not support anymore")
            return nil
        case .webBroswer:
            return .webBroswer
        }
    }

    /// 预览页面是否可以进入浮窗
    public var isSuspendable: Bool {
        switch self {
        case .docsAttach, .sheetAttach, .docx, .history,
             .localFile, .thirdParty, .mail, .calendar, .bitableAttach,
             .vcFollow, .docsAttachInFollow, .sheetAttachInFollow, .im, .secretIM, .miniApp, .wiki, .groupTab, .driveSDK, .webBroswer:
            return false
        case .docsList, .message, .docsMention, .larkfeed,
             .search, .link, .recent, .pin, .favorites,
             .offline, .personal, .sharedSpace,
             .personalFolder, .sharedFolder, .taskList, .unknown:
            return true
        }
    }
    
    //条件访问控制 previewFrom转换成bizdomain
    public var transfromBizDomain: CCMSecurityPolicyService.BizDomain {
        switch self {
        case .im:
            return .im
        case .docsList, .docsAttach, .sheetAttach, .docx, .bitableAttach,
             .recent, .wiki, .pin, .personal, .sharedSpace, .favorites, .offline, .sharedFolder:
            return .ccm
        case .calendar:
            // TODO: 梳理清楚日历场景到底用哪种实体
            return .ccm
        default:
            return .customCCM(fileBizDomain: .unknown)
        }
    }
    
    // 针对下载点位，转换 DrivePreviewFrom,日历下载用calendar
    public var transfromBizDomainDownloadPoint: CCMSecurityPolicyService.BizDomain {
        switch self {
        case .im:
            return .im
        case .docsList, .docsAttach, .sheetAttach, .docx, .bitableAttach,
             .recent, .wiki, .pin, .personal, .sharedSpace, .favorites, .offline, .sharedFolder:
            return .ccm
        case .calendar:
            return .calendar
        default:
            return .customCCM(fileBizDomain: .unknown)
        }
    }

    public var permissionBizDomain: PermissionRequest.BizDomain {
        switch self {
        case .im:
            return .im
        case .docsList, .docsAttach, .sheetAttach, .docx, .bitableAttach,
                .recent, .wiki, .pin, .personal, .sharedSpace, .favorites, .offline, .sharedFolder, .driveSDK:
            return .ccm
        case .calendar:
            // TODO: 梳理清楚日历场景到底用哪种实体
            return .ccm
        case .miniApp, .webBroswer, .secretIM:
            return .customCCM(fileBizDomain: .unknown)
        default:
            return .ccm
        }
    }

    // 针对下载点位，转换 DrivePreviewFrom,日历下载用calendar
    public var permissionBizDomainForDownload: PermissionRequest.BizDomain {
        switch self {
        case .im:
            return .im
        case .docsList, .docsAttach, .sheetAttach, .docx, .bitableAttach,
             .recent, .wiki, .pin, .personal, .sharedSpace, .favorites, .offline, .sharedFolder, .driveSDK:
            return .ccm
        case .calendar:
            return .calendar
        case .miniApp, .webBroswer, .secretIM:
            return .customCCM(fileBizDomain: .unknown)
        default:
            return .ccm
        }
    }
}

/// DrivePreloadService.Config
/// Drive 预加载配置
public struct DrivePreloadConfig: Codable {

    public let recentLimit: Int
    public let pinLimit: Int
    public let favouriteLimit: Int
    public let sizeLimit: UInt64
    public let videoCacheSizeLimit: UInt64

    public subscript(source: DrivePreloadSource) -> Int {
        switch source {
        case .recent:
            return recentLimit
        case .pin:
            return pinLimit
        case .favorite:
            return favouriteLimit
        case .manualOffline:
            return Int.max
        }
    }
}

/// public for DataModel+List
public final class DriveListConfig {
    public var isNeedUploading = false
    public var progress: Double = 0.0
    public var remainder: Int = 0
    public var failed = false
    public var errorCount = 0
    public var totalCount = 0

    public func renew() {
        isNeedUploading = true
        progress = 0.0
        failed = false
    }

    public func update(progress: Double, total: Int?, reminder: Int?) {
        if let r = reminder { self.remainder = r }
        if let total = total { self.totalCount = total }
        self.progress = progress
        failed = false
    }
    public func finished() {
        isNeedUploading = false
        failed = false
    }
    public func updateForError(errCount: Int) {
        isNeedUploading = true
        failed = true
        errorCount = errCount
    }
    public init() { }
}

public enum ConvertFileError: Error {
    case fgClosed                       // FG关闭，不显示转在线文档的cell
    case importFailedRetry              // 导入失败，请重试
    case unsupportType                  // 不支持的文件格式
    case fileSizeOverLimit              // 文件大小超过限制
    case notApproved                    // 未通过审核
    case isDeleted                      // 文件被删除
    case notExist                       // 文件不存在
    case noReadablePermission           // 无阅读权限
    case noExportPermission             // 无导出权限

    public var errorMessage: String {
        switch self {
        case .fgClosed:
            return BundleI18n.SKResource.Drive_Drive_ImportFailedSupport
        case .importFailedRetry:
            return BundleI18n.SKResource.Drive_Drive_ImportNoPermisson
        case .unsupportType:
            return BundleI18n.SKResource.Doc_Facade_ImportFailedUnsupportType
        case .fileSizeOverLimit:
            return BundleI18n.SKResource.Doc_Facade_ImportFailedTooLarge
        case .notApproved:
            return BundleI18n.SKResource.Doc_Facade_ImportFailedNotApproved
        case .isDeleted:
            return BundleI18n.SKResource.Doc_Facade_ImportFailedDeleted
        case .notExist:
            return BundleI18n.SKResource.Doc_Facade_ImportFailedNotExist
        case .noReadablePermission:
            return BundleI18n.SKResource.Doc_Facade_ImportFailedNoReadPermission
        case .noExportPermission:
            return BundleI18n.SKResource.Doc_Facade_ImportFailedNoImportPermission
        }
    }
}

/// 操作的来源
public enum DriveStatisticActionSource: String {
    case unknow = ""
    /// 列表页主视图
    case spaceList = "left_slide"
    /// 列表页网格视图
    case spaceGrid = "grid_more"
    /// 文件预览页
    case fileDetail = "innerpage_more"
    /// 附件预览页
    case attachmentMore = "attachment_more"
    /// 本地文件
    case localFile = "local_file"
    /// More
    case headerbarMore = "headerbar_more"
    /// 窗口
    case window = "window"
    /// 音频播放器
    case audioPlay = "audio-play"
    /// 视频播放器
    case videoPlay = "video-play"
}

/// DriveSDK 支持的业务
extension DKSupportedApp {

    public var statisticModuleString: String? {
        switch self {
        case .im, .secretIM:
            return StatisticModule.im.rawValue
        case .miniApp:
            return StatisticModule.miniProgram.rawValue
        case .mail:
            return StatisticModule.email.rawValue
        case .calendar:
            return StatisticModule.calendar.rawValue
        case .doc:
            return StatisticModule.doc.rawValue
        case .sheet:
            return StatisticModule.sheet.rawValue
        case .docx:
            return StatisticModule.docx.rawValue
        case .bitable, .bitableLocal:
            return StatisticModule.bitable.rawValue
        case .webBroswer:
            return StatisticModule.webBroswer.rawValue
        case .space:
            return nil
        }
    }

    public var previewFrom: DrivePreviewFrom {
        switch self {
        case .im:
            return .im
        case .secretIM:
            return .secretIM
        case .miniApp:
            return .miniApp
        case .mail:
            return .mail
        case .calendar:
            return .calendar
        case .doc:
            return .docsAttach
        case .sheet:
            return .sheetAttach
        case .docx:
            return .docx
        case .bitable, .bitableLocal:
            return .bitableAttach
        case .space:
            spaceAssertionFailure("space dont get previewFrom app")
            return .docsList
        case .webBroswer:
            return .webBroswer
        }
    }
}

// MARK: - DriveStatusItem
public final class DriveStatusItem {
    public enum Status {
        case uploading
        case failed
    }
    public let status: Status
    public let progress: Double
    public let count: Int
    public let totalCount: Int
    public var uniqueID: String {
        if status == .uploading {
            return "upload-\(count)-\(progress)"
        } else {
            return "failed-\(count)-\(progress)"
        }
    }
    public init(count: Int, total: Int, progress: Double, status: Status) {
        self.progress = progress
        self.count = count
        self.totalCount = total
        self.status = status
    }
}

public enum DriveAppealAlertFrom: String {

    //不在本次埋点范围
    case unknown = ""
    //drive详情页more面板用其它应用打开
    case driveDetailOpenInOtherApp = "from_drive_more_api_download"
    //云空间drive文件列表侧滑保存到本地
    case driveDetailSideSlipDownload = "from_right_click_download"
    //drive详情页更多面板上点击保存到本地
    case driveDetailMoreDownload = "from_drive_more_download"
    //云文档详情页附件预览more面板保存到本地
    case driveAttachmentMoreDownload = "from_docs_attachment_preview_download"
    //云文档详情页附件保存到本地
    case driveAttachmentDownload = "from_docs_attachment_download"
}

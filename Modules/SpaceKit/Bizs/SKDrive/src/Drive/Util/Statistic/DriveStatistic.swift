//
//  DriveStatistic.swift
//  SpaceKit
//
//  Created by liweiye on 2019/3/13.
//

import Foundation
import SKCommon
import SKFoundation
import LarkDocsIcon

// swiftlint:disable file_length
// nolint: long parameters

enum DriveStatisticAction: String {
    // MARK: - 上传
    /// 上传文件
    case driveClickUploadFile = "drive_click_upload_file"
    /// 上传多媒体
    case driveClickUploadMultimedia = "drive_click_upload_multimedia"
    /// 上传文件的确认
    case driveClickUploadFileConfirm = "drive_click_upload_file_confirm"
    /// 上传多媒体的确认
    case driveClickUploadMultimediaConfirm = "drive_click_upload_multimedia_confirm"
    /// 上传结果
    case driveUploadResult = "drive_upload_result"
    /// 进入上传列表页
    case showUploadLayer = "show_upload_layer"
    /// 退出上传列表页
    case hideUploadLayer = "hide_upload_layer"
    /// 列表页重新上传
    case reUpload = "re_upload"
    /// 取消上传-批量取消
    case cancelUploadBatch = "cancel_upload_batch"
    /// 取消上传-单个取消
    case cancelUpload = "cancel_upload"
    /// 取消上传的确认
    case cancelUploadConfirm = "cancel_upload_confirm"
    /// 取消上传的取消
    case cancelUploadCancel = "cancel_upload_cancel"
    /// 点击上传按钮
    case clickUpoad = "click_upload"
    /// 点击确认上传按钮
    case confirmUpload = "confrim_upload"
    /// 上传结束
    case finishUpload = "finish_upload"
    // 结束下载
    case finishDownload = "finish_download"

    // MARK: - 更多
    /// 重命名
    case clickRename = "click_rename"
    /// 重命名的确认
    case clickRenameConfirm = "click_rename_confirm"
    /// 用其他应用打开
    case openInOtherApps = "open_in_other_apps"
    /// 取消加载
    case cancelOpenInOtherApps = "cancel_open_in_other_apps"
    /// 导入为在线文档
    case importToOnlineFile = "import"

    /// 文件信息页面
    case readingDataPage = "file_within_info_page"

    /// 保存到云空间
    case saveToDrive = "save_to_drive"

    // MARK: - 预览
    /// 视频
    case play = "play"
    case pause = "pause"

    /// 点赞
    case cancelPraise = "cancel_praise"
    case confirmPraise = "confirm_praise"
    case showPraisePage = "show_praise_page"

    /// 商业化
    case notifyAdmin = "notify_admin"
    case cancel = "cancel"

    /// 压缩文件
    case clickArchiveFolder = "click_folder"
    case clickArchiveFile = "click_file"

    // 第三方预览打开业务统计
    case openMentioned = "click_open_mentioned_obj"

    /// 安全链接数据上报:  https://bytedance.feishu.cn/docs/doccnDRVVFGvIgIqKB6Em0978Re
    case secLink = "secLink"
    
    // 文件浏览状态切换
    case clickDisplay = "clickDisplay"
 }

final class DriveStatistic: NSObject {

    /// 上报到后台时的字段常用键值
    enum ReportKey: String {
        case action = "action"
        case eventType = "event_type"
        case fileId = "file_id"
        case fileType = "file_type"
        case fileTenantId = "file_tenant_id"
        case fileIsCrossTenant = "file_is_cross_tenant"
        case inPage = "in_page"
        /// 文件所在的模块
        case module = "module"
        case mode = "mode"
        case networkStatus = "network_status"
        case productType = "product_type"
        case sessionId = "session_id"
        case sessionDuration = "session_duration"
        case source = "source"
        case subFileType = "sub_file_type"
        case subModule = "sub_module"
        case mentionFileType = "mention_file_type"
        /// docs附件进入: doc_embed, docs mention文件: doc_mention, 其他类型: 空
        case previewFrom = "preview_from"
        case appForm = "app_form"
        case triggerAction = "trigger_action"
        /// 文件所处位置的上一层级模块
        case srcModule = "src_module"
        /// 所在文件夹的文件夹 id，如不在文件夹里，不需要上报
        case srcObjId = "src_obj_id"
        case isDir = "is_dir"
        case isImport = "is_import"
        case isExport = "is_export"
        /// 文件打开是否横屏
        case isLandscape = "is_landscape"
        /// 内容的展示形态
        case displayType = "display_type"
    }

    private typealias StatisticParameters = [ReportKey: Any]

    /// 模块
    private static let module = "drive"
    /// 产品类型
    private static let productType = "drive"
    /// 文件类型
    private static let fileType = "file"
    /// 模式
    private static let mode = "drive_mode"
    /// 当前网络状态
    private static var networkStatus: String {
        if DocsNetStateMonitor.shared.isReachable {
            return "true"
        } else {
            return "false"
        }
    }
    /// 定时器
    private static var timer: Timer?

    /// 文件预览
    ///
    /// - Parameters:
    ///   - fileId: 文件Id，取值为加密后的文件token
    ///   - subFileType: 文件拓展名
    ///   - fileTenantId: 文件owner租户Id
    ///   - fileIsCrossTenant: 是否跨租户，true/false
    ///   - previewFrom: 预览事件来源
    ///   - addtionalParamters: 其他额外参数
    static func clientFileOpen(fileId: String, subFileType: DriveFileType,
                               fileTenantId: String,
                               fileIsCrossTenant: String,
                               previewFrom: String,
                               mode: String,
                               screenMode: String,
                               isDriveSDK: Bool,
                               additionalParameters: [String: String]? = nil,
                               statisticInfo: [String: String] = [:]) {
        let para: StatisticParameters = [
            .fileId: DocsTracker.encrypt(id: fileId),
            .fileType: fileType,
            .subFileType: subFileType.rawValue.lowercased(),
            .networkStatus: networkStatus,
            .fileTenantId: DocsTracker.encrypt(id: fileTenantId),
            .fileIsCrossTenant: fileIsCrossTenant,
            .productType: productType,
            .previewFrom: previewFrom,
            .mode: mode,
            .displayType: screenMode
        ]
        
        var statisticInfo = statisticInfo
        statisticInfo.merge(other: additionalParameters)
        
        let event: DocsTracker.EventType = isDriveSDK ? .driveSDKFileOpen : .clientFileOpen
        log(event: event, parameters: para, additionalParameters: statisticInfo)
    }
    
    /// 文件切换横竖屏
    static func clientFileLandscape(fileId: String, subFileType: DriveFileType,
                                    previewFrom: String, module: String,
                                    isLandscape: Bool) {
        let para: StatisticParameters = [
            .fileId: DocsTracker.encrypt(id: fileId),
            .fileType: fileType,
            .subFileType: subFileType.rawValue.lowercased(),
            .previewFrom: previewFrom,
            .module: module,
            .isLandscape: isLandscape ? 1 : 0
        ]
        log(event: .clientFileLandscape, parameters: para, additionalParameters: [:])
    }
    
    /// 文件详情页展示状态切换
    static func clientClickDisplay(fileId: String,
                                   subFileType: DriveFileType,
                                   screenMode: String,
                                   preViewFrom: String) {
        let para: StatisticParameters = [
            .fileId: DocsTracker.encrypt(id: fileId),
            .module: "drive",
            .fileType: "file",
            .subFileType: subFileType.rawValue.lowercased(),
            .displayType: screenMode,
            .previewFrom: preViewFrom
        ]
        log(event: .clientClickDisplay, parameters: para, additionalParameters: [:])
    }
    
    /// 文档管理
    static func clientContentManagement(action: DriveStatisticAction,
                                        fileId: String,
                                        additionalParameters: [String: String]? = nil) {
        let para: StatisticParameters = [
            .action: action.rawValue,
            .fileType: fileType,
            .fileId: DocsTracker.encrypt(id: fileId),
            .module: module,
            .subModule: "recent"
        ]
        log(event: .clientContentManagement,
            parameters: para,
            additionalParameters: additionalParameters)
    }

    /// 进入预览之后的操作
    static func toggleAttribute(fileId: String,
                                subFileType: String,
                                action: DriveStatisticAction,
                                source: DriveStatisticActionSource,
                                previewFrom: String = "",
                                additionalParameters: [String: String]? = nil,
                                statisticInfo: [String: String] = [:]) {
        let para: StatisticParameters = [
            .productType: productType,
            .eventType: "mouseclick",
            .fileId: DocsTracker.encrypt(id: fileId),
            .fileType: fileType,
            .subFileType: subFileType.lowercased(),
            .module: module,
            .action: action.rawValue,
            .source: source.rawValue,
            .previewFrom: previewFrom
        ]
        
        var statisticInfo = statisticInfo
        statisticInfo.merge(other: additionalParameters)
        
        log(event: .toggleAttribute,
            parameters: para,
            additionalParameters: statisticInfo)
    }

    /// 上传列表页中的操作
    static func clientFileUpload(fileId: String,
                                 subFileType: String,
                                 action: DriveStatisticAction,
                                 additionalParameters: [String: String]? = nil) {
        let para: StatisticParameters = [
            .productType: productType,
            .fileId: DocsTracker.encrypt(id: fileId),
            .fileType: fileType,
            .subFileType: subFileType.lowercased(),
            .module: module,
            .subModule: "upload_layer",
            .action: action.rawValue
        ]
        log(event: .clientFileUpload,
            parameters: para,
            additionalParameters: additionalParameters)
    }

    /// 点赞模块
    static func clientPraise(action: DriveStatisticAction,
                             fileType: String,
                             fileId: String,
                             module: String,
                             previewFrom: String,
                             additionalParameters: [String: String]? = nil) {
        let para: StatisticParameters = [
            .action: action.rawValue,
            .fileType: fileType,
            .fileId: DocsTracker.encrypt(id: fileId),
            .module: module,
            .previewFrom: previewFrom
        ]
        log(event: .clientPraise,
            parameters: para,
            additionalParameters: additionalParameters)
    }

    /// 历史版本
    static func clickEnterHistoryWithin(fileId: String,
                                        fileType: String,
                                        previewFrom: String,
                                        additionalParameters: [String: String]? = nil) {
        let para: StatisticParameters = [
            .fileType: fileType,
            .fileId: DocsTracker.encrypt(id: fileId),
            .previewFrom: previewFrom
        ]
        log(event: .clickEnterHistoryWithin,
            parameters: para,
            additionalParameters: additionalParameters)
    }

    /// larkfeed进入文件
    static func enterFileFromLark(additionalParameters: [String: String]? = nil) {
        let para: StatisticParameters = [
            .fileType: "file",
            .source: "docs_feed"
        ]
        log(event: .clickDocsTab,
            parameters: para,
            additionalParameters: additionalParameters)
    }

    /// 商业化
    static func clientCommerce(action: DriveStatisticAction,
                               additionalParameters: [String: String]? = nil) {
        let para: StatisticParameters = [
            .action: action.rawValue,
            .triggerAction: "import"
        ]
        log(event: .clientCommerce,
            parameters: para,
            additionalParameters: additionalParameters)
    }

    /// 压缩文件
    static func clickArchiveNode(fileId: String,
                                 nodeType: DriveArchiveNode.FileType,
                                 archiveFileType: DriveFileType,
                                 previewFrom: DrivePreviewFrom,
                                 additionalParameters: [String: String]? = nil) {
        let action: DriveStatisticAction
        switch nodeType {
        case .folder:
            action = .clickArchiveFolder
        case .regularFile:
            action = .clickArchiveFile
        }
        toggleAttribute(fileId: fileId,
                        subFileType: archiveFileType.rawValue,
                        action: action,
                        source: .window,
                        previewFrom: previewFrom.stasticsValue,
                        additionalParameters: additionalParameters)
    }
    
    static func extractArchive(isSuccess: Bool, archiveType: String, fileType: String, isEncrypted: Bool, errorMessage: String) {
        let params: [String: Any] = ["result": isSuccess ? 0 : -1,
                                    "archive_file_type": archiveType,
                                    "file_type": fileType,
                                    "is_encrypted": isEncrypted ? 1 : 0,
                                    "error_message": errorMessage]
        DocsTracker.newLog(event: DocsTracker.EventType.driveArchiveExtract.stringValue, parameters: params)
    }

    /// PPT进入演示模式
    static func enterPresentation(actionType: String, fileType: String, additionalParameters: [String: String]? = nil) {
        let params: StatisticParameters = [
            .fileType: fileType.lowercased(),
            .action: actionType
        ]
        log(event: .driveEnterPresentation,
            parameters: params,
            additionalParameters: additionalParameters)
    }

    // 第三方业务打开事件统计
//    static func clickOpenMentioned(fileId: String,
//                                   subFileType: String,
//                                   module: String,
//                                   additionalParameters: [String: String]? = nil) {
//        let params: StatisticParameters = [
//            .module: module,
//            .mentionFileType: subFileType.lowercased(),
//            .fileType: "file",
//            .fileId: DocsTracker.encrypt(id: fileId)
//        ]
//        log(event: .thirdpatyOpenMentioned,
//            parameters: params,
//            additionalParameters: additionalParameters)
//    }

    /// 耗时埋点记录开始
    ///
    /// - Parameters:
    ///   - fileId: 文件Id，取值为加密后的文件token
    ///   - subFileType: 文件拓展名
    static func startRecordTimeConsuming(fileId: String,
                                         subFileType: DriveFileType,
                                         additionalParameters: [String: String]? = nil) {
        let key = DocsTracker.EventType.launchDuration.rawValue
        // 保存埋点记录开始时的时间
        costTime[key] = getCurrentTime()
        // 保存需要上报的参数
        // session_id: 会话Id
        var para = [ReportKey.module.rawValue: module,
                    ReportKey.inPage.rawValue: "true",
                    ReportKey.fileId.rawValue: DocsTracker.encrypt(id: fileId),
                    ReportKey.fileType.rawValue: fileType,
                    ReportKey.subFileType.rawValue: subFileType.rawValue.lowercased(),
                    ReportKey.sessionId.rawValue: ""]
        para.merge(other: additionalParameters)
        uploadParameters[key] = para
    }

    /// 耗时埋点记录结束
    static func endRecordTimeConsuming() {
        let key = DocsTracker.EventType.launchDuration.rawValue
        guard let enterTime = self.costTime[key] else {
            DocsLogger.error("EnterTime is nil")
            return
        }
        // 预览总时间 = 退出预览的时间 - 进入预览的时间
        // 单位是 ms，省略小数部分
        let costTime = Int((getCurrentTime() - enterTime) * 1000)

        var allParames: [String: Any] = [ReportKey.sessionDuration.rawValue: costTime]
        guard let uploadParameter = self.uploadParameters[key] else {
            DocsLogger.error("UploadParameters are nil!")
            return
        }
        allParames.merge(other: uploadParameter)
        DocsTracker.log(enumEvent: .launchDuration, parameters: allParames)
        self.costTime[key] = nil
        self.uploadParameters[key] = nil
    }

    /// 定时器任务开启
    static func startTimedReporting(timeInterval: Double) {
        timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                     target: self, selector: #selector(DriveStatistic.launchDurationTask),
                                     userInfo: nil, repeats: true)
    }

    /// 定时器任务关闭
    static func endTimedReporting() {
        timer?.invalidate()
    }

    @objc
    static func launchDurationTask() {
        DriveStatistic.endRecordTimeConsuming()
    }

    private static func log(event: DocsTracker.EventType,
                            parameters: StatisticParameters,
                            additionalParameters: [String: String]?) {
        var rawParameters: [AnyHashable: Any] = [:]
        parameters.forEach { rawParameters[$0.0.rawValue] = $0.1 }
        rawParameters.merge(other: additionalParameters)
        DocsTracker.log(enumEvent: event, parameters: rawParameters)
    }
}

extension DriveStatistic {
    static func enterPreview(fileID: String,
                             fileType: DriveFileType,
                             fileTenantId: String,
                             previewFrom: String,
                             shouldReportClientFileOpen: Bool,
                             isDriveSDK: Bool,
                             mode: String,
                             screenMode: String,
                             additionalParameters: [String: String]? = nil,
                             statisticInfo: [String: String] = [:]) {
        if shouldReportClientFileOpen {
            clientFileOpen(fileId: fileID,
                           subFileType: fileType,
                           fileTenantId: fileTenantId,
                           fileIsCrossTenant: fileIsCrossTenant(fileTenant: fileTenantId),
                           previewFrom: previewFrom,
                           mode: mode,
                           screenMode: screenMode,
                           isDriveSDK: isDriveSDK,
                           additionalParameters: additionalParameters,
                           statisticInfo: statisticInfo)
        }
        
        // 耗时埋点记录开始
        startRecordTimeConsuming(fileId: fileID,
                                 subFileType: fileType,
                                 additionalParameters: additionalParameters)
        // 定时器开始，每60秒上报一次
        startTimedReporting(timeInterval: 60.0)
    }

    // 点击文件进入预览
//    static func enterPreview(fileInfo: DriveFileInfo?,
//                             fileTenantId: String,
//                             previewFrom: String,
//                             shouldReportClientFileOpen: Bool,
//                             isDriveSDK: Bool,
//                             mode: String,
//                             screenMode: String,
//                             additionalParameters: [String: String]? = nil,
//                             statisticInfo: [String: String] = [:]) {
//        guard let fileInfo = fileInfo else { return }
//        enterPreview(fileID: fileInfo.fileToken,
//                     fileType: fileInfo.fileType,
//                     fileTenantId: fileTenantId,
//                     previewFrom: previewFrom,
//                     shouldReportClientFileOpen: shouldReportClientFileOpen,
//                     isDriveSDK: isDriveSDK,
//                     mode: mode,
//                     screenMode: screenMode,
//                     additionalParameters: additionalParameters,
//                     statisticInfo: statisticInfo)
//    }

    /// 退出预览
    static func exitPreview() {
        // 统计预览时长
        endRecordTimeConsuming()
        // 停止定时器
        endTimedReporting()
    }
}

extension DriveStatistic {
    private static var costTime: Dictionary = [String: Double]()
    private static var uploadParameters = [String: [String: Any]]()

    private class func getCurrentTime() -> Double {
        return Date().timeIntervalSince1970
    }
    private static func fileIsCrossTenant(fileTenant: String) -> String {
        var isCrossTenant = ""
        if let curTenant = User.current.info?.tenantID,
            !curTenant.isEmpty,
            !fileTenant.isEmpty {
            isCrossTenant = (curTenant == fileTenant) ? "false" : "true"
        }
        return isCrossTenant
    }
}

// Drive upload & download
extension DriveStatistic {
    struct ModuleInfo {
        let module: String
        let srcModule: String
        let subModule: String
        let isExport: Bool
        let isDriveSDK: Bool
        let fileID: String
    }
    // 存储上传的key对应上传来源module
    static private var uploadKeyModuleMap = ThreadSafeDictionary<String, ModuleInfo>()
    // 存储下载的key对应下载来源module
    static private var downloadKeyModuleMap = ThreadSafeDictionary<String, ModuleInfo>()
    
    static func setKey(_ key: String, moduleInfo: ModuleInfo, isUpload: Bool) {
        if isUpload {
            uploadKeyModuleMap.updateValue(moduleInfo, forKey: key)
        } else {
            downloadKeyModuleMap.updateValue(moduleInfo, forKey: key)
        }
    }

    static func moduleInfo(for key: String, isUpload: Bool) -> ModuleInfo? {
        if isUpload {
            return uploadKeyModuleMap.value(ofKey: key)
        } else {
            return downloadKeyModuleMap.value(ofKey: key)
        }
    }
    
    // isDriveSDK: 产品视角的DriveSDK, 非
    static func reportUpload(action: DriveStatisticAction,
                             fileID: String,
                             fileSubType: String? = nil,
                             module: String,
                             subModule: String ,
                             srcModule: String,
                             isDriveSDK: Bool) {
        let params: StatisticParameters = [ReportKey.action: action.rawValue,
                      ReportKey.fileId: DocsTracker.encrypt(id: fileID),
                      ReportKey.fileType: fileType,
                      ReportKey.subFileType: fileSubType ?? "",
                      ReportKey.module: module,
                      ReportKey.subModule: subModule,
                      ReportKey.srcModule: srcModule,
                      ReportKey.productType: "drive",
                      ReportKey.isDir: 0,
                      ReportKey.isImport: 0]
        let event: DocsTracker.EventType = isDriveSDK ? .driveSDKFileUpload : .clientFileUpload
        DocsLogger.driveInfo("drive download and upload- \(event):\(params)")
        log(event: event, parameters: params, additionalParameters: nil)
    }
    
    static func reportDownload(action: DriveStatisticAction,
                               fileID: String,
                               fileSubType: String? = nil,
                               module: String,
                               subModule: String,
                               srcModule: String,
                               isExport: Bool,
                               isDriveSDK: Bool) {
        let export = isExport ? 1 : 0
        let params: StatisticParameters = [ReportKey.action: action.rawValue,
                      ReportKey.fileId: DocsTracker.encrypt(id: fileID),
                      ReportKey.fileType: fileType,
                      ReportKey.subFileType: fileSubType ?? "",
                      ReportKey.module: module,
                      ReportKey.subModule: subModule,
                      ReportKey.srcModule: srcModule,
                      ReportKey.isExport: export,
                      ReportKey.isDir: "0",
                      ReportKey.productType: "drive"]
        let event: DocsTracker.EventType = isDriveSDK ? .driveSDKFileDownload : .clientFileDownload
        DocsLogger.debug("drive download and upload- \(event):\(params)")
        log(event: event, parameters: params, additionalParameters: nil)
    }
}


// MARK: - 2021.5月新埋点方案
// https://bytedance.feishu.cn/sheets/shtcnqPPSGnCmMCzezvXbEXDJEg?sheet=5Y3XxU
extension DriveStatistic {
    
//    /// Drive 文件预览的更多菜单页面（ActionSheet 形式）点击事件
//    static func reportDriveMenuClickEvent(_ event: ClickEventType, fileId: String, fileType: DriveFileType) {
//        let params: [String: Any] = ["click": event.clickValue, "target": event.targetValue]
//        reportEvent(DocsTracker.EventType.driveFileMenuClick, fileId: fileId, fileType: fileType.rawValue, params: params)
//    }
    
    /// 上报点击类的事件
    static func reportClickEvent(_ event: DocsTrackerEventType, clickEventType: ClickEventType, fileId: String?, fileType: DriveFileType?, params: [String: Any] = [:]) {
        var params = params
        params["click"] = clickEventType.clickValue
        params["target"] = clickEventType.targetValue
        reportEvent(event, fileId: fileId, fileType: fileType?.rawValue, params: params)
    }
    
    static func reportEvent(_ event: DocsTrackerEventType, fileId: String?, fileType: String?, params: [String: Any] = [:]) {
        var bizParam: SpaceBizParameter
        if let fileId = fileId, let fileType = fileType {
            bizParam = SpaceBizParameter(module: .drive,
                                             fileID: fileId,
                                             fileType: .file,
                                             driveType: fileType)
        } else {
            bizParam = SpaceBizParameter(module: .drive)
        }
        
        var params = params
        params.merge(other: bizParam.params)
        DocsTracker.newLog(event: event.stringValue, parameters: params)
    }
    
//    static func reportUploadChoose(fileName: String, mountPoint: String, token: String?) {
//        /// 针对space和wiki场景外的上传事件的上报，此处通过 isSpaceOrWikiUpload 进行标记
//        guard let module = DocsTracker.getCurrentUploadMoudle(mountPoint: mountPoint, token: token), !DocsTracker.isSpaceOrWikiUpload else {
//            DocsTracker.isSpaceOrWikiUpload = false
//            return
//        }
//        
//        let ext = SKFilePath.getFileExtension(from: fileName)
//        let type = DriveFileType(fileExtension: ext)
//        let fileType: String
//        if type.isImage || type.isVideo {
//            fileType = "picture"
//        } else {
//            fileType = "file"
//        }
//        let biz = CreateNewClickParameter.bizParameter(for: "", module: module)
//        DocsTracker.reportSpaceFileChooseClick(params: .confirm(fileType: fileType), bizParms: biz, mountPoint: mountPoint)
//    }
    
    /// Drive 文件的更多面板（ActionSheet）的点击事件
    enum DriveFileMenuClickEvent: String, ClickEventType {
        case sendToChat = "send_to_chat"
        case openInOtherApp = "open_in_other_apps"
        /// 转为在线文档/表格
        case importAs = "import_as"
        /// 保存到云空间
        case saveToDrive = "save_to_drive"
        case saveToFile = "save_to_file"
        case saveImage = "save_image"
        case saveToLocal = "save_to_local"
        case cancel = "cancel"
        case applyPermission = "permission_read_without_edit"

        var clickValue: String { return self.rawValue }
        
        var targetValue: String {
            switch self {
            case .sendToChat:
                return "public_multi_select_share_view"
            case .importAs:
                return "ccm_docs_page_view"
            case .openInOtherApp, .saveToDrive, .saveToFile, .saveImage, .cancel, .saveToLocal, .applyPermission:
                return "none"
            }
        }
    }
    
    enum DrivePageClickEvent: String, ClickEventType {
        case like
        case input
        case comment
        
        var clickValue: String { return self.rawValue }
        
        var targetValue: String {
            switch self {
            case .like:
                return "none"
            case .comment, .input:
                return "ccm_comment_view"
            }
        }
    }
    
    enum DriveFileOpenClickEventType: String, ClickEventType {
        case more
        case mediaRotate = "media_rotate"
        case mediaFullScreen = "media_fullscreen"
        case mediaVolume = "media_volume"
        case mediaTime = "media_time"
        case pause
        case mediaQuanlity = "media_quanlity"
        case mediaPlay = "media_play"
        case slide
        case clickReturn = "click_return"
        
        var clickValue: String { return self.rawValue }
        
        var targetValue: String {
            switch self {
            case .more:
                return "ccm_drive_file_menu_view"
            case .mediaRotate, .mediaFullScreen, .mediaVolume, .mediaTime,
                 .pause, .mediaQuanlity, .mediaPlay, .slide, .clickReturn:
                return "none"
            }
        }
    }
    
    enum DriveFileUploadViewClickEventType: String, ClickEventType {
        case cancel
        case retry
        case confirm
        
        var clickValue: String { return self.rawValue }
        var targetValue: String { return "none" }
    }
    
    enum DriveAppealAlertClickEventType: String, ClickEventType {
        //发起申诉
        case launch_complain
        //我知道了
        case known
        
        var clickValue: String { return self.rawValue }
        var targetValue: String { return "none" }
    }
    
    enum DriveTopBarClickEventType: String, ClickEventType {
        case more
        case share
        case notification
        case show
        case showMyAIChat
        
        var clickValue: String { return self.rawValue }
        var targetValue: String {
            switch self {
            case .more:
                return "ccm_space_docs_more_menu_view"
            case .share:
                return "ccm_permission_share_view"
            case .notification:
                return "ccm_notification_panel_view"
            case .show:
                return "none"
            case .showMyAIChat: // TODO: - howie, 添加My AI埋点
                return "ccm_show_myai_panel"
            }
        }
    }

    /// Rust上传下载接口TeaParams扩展字段的Key值
    enum RustTeaParamKey {
        static let downloadFor = "download_for"
    }

    enum DownloadFor {
        static let videoCover = "video_cover"
        static let drivePreload = "drive_preload"
        static let driveImageThumbnail = "drive_image_thumbnail"
    }
}

protocol ClickEventType {
    var clickValue: String { get }
    var targetValue: String { get }
}

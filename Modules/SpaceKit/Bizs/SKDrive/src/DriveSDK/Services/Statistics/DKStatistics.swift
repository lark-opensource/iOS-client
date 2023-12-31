//
//  DKStatistics.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/7/10.
//

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface
import LarkDocsIcon
import SKInfra

protocol DKStatisticsService {
    func enterPreview()
    func exitPreview()
    func reportSaveToSpace()
    func toggleAttribute(action: DriveStatisticAction, source: DriveStatisticActionSource)
    func enterFileLandscape(_ isLandscape: Bool)
    func clientClickDisplay(screenMode: String)
    func reportExcelContentPageView(editMethod: FileEditMethod)
    func reportDrivePageView(isSupport: Bool, displayMode: DrivePreviewMode)
    func reportEvent(_ event: DocsTrackerEventType, params: [String: Any])
    func reportClickEvent(_ event: DocsTrackerEventType, clickEventType: ClickEventType, params: [String: Any])
    func updateFileType(_ fileType: DriveFileType)
    func reportFileOpen(fileId: String, fileType: DriveFileType, isSupport: Bool)
    var additionalParameters: [String: String] { get set }
    var commonTrackParams: [String: String] { get set }
    var previewFrom: DrivePreviewFrom { get }
}

extension DrivePreviewMode {
    var statisticValue: String {
        switch self {
        case .card:
            return "card"
        case .normal:
            return "preview"
        @unknown default:
            fatalError("unknow case")
        }
    }
}

class DKStatistics: DKStatisticsService {
    private let sdkAppIDKey = "sdkAppId"
    private let appID: String
    private let fileID: String
    private var fileType: DriveFileType
    let previewFrom: DrivePreviewFrom
    var statisticInfo: [String: String]?
    var additionalParameters: [String: String]
    var commonTrackParams: [String: String]
    private var isDriveSDK: Bool {
        return appID != DKSupportedApp.space.rawValue
    }
    private var isFromWiki: Bool {
        return previewFrom == .wiki
    }
    private var isLinkOpen: Bool {
        // 在IM,日历场景通过链接打开时，打开的是云空间文件，而非附件
        if previewFrom == .im || previewFrom == .secretIM || previewFrom == .calendar, !isAttachMent {
            return true
        }
        return previewFrom == .unknown ||
               previewFrom == .docsMention ||
               previewFrom == .link
    }
    public let mountPoint: String?
    // 判断当前打开的drive文件是附件还是云空间文件
    private let isAttachMent: Bool
    
    init(appID: String,
         fileID: String,
         fileType: DriveFileType,
         previewFrom: DrivePreviewFrom,
         mountPoint: String?,
         isInVCFollow: Bool,
         isAttachMent: Bool,
         statisticInfo: [String: String]?) {
        self.appID = appID
        self.fileID = fileID
        self.mountPoint = mountPoint
        self.fileType = fileType
        self.previewFrom = previewFrom
        self.additionalParameters = [sdkAppIDKey: appID]
        self.statisticInfo = statisticInfo
        self.commonTrackParams = ["file_id": DocsTracker.encrypt(id: fileID),
                                  "file_type": "file",
                                  "sub_file_type": fileType.rawValue,
                                  "app_form": isInVCFollow ? "vc" : "none",
                                  "module": "drive",
                                  "sub_module": "none"]
        self.isAttachMent = isAttachMent
    }
    
    func enterPreview() {
        // 添加上报埋点数据 module，文件来源
        additionalParameters[DriveStatistic.ReportKey.module.rawValue] = DKSupportedApp(rawValue: appID)?.statisticModuleString ?? ""
        additionalParameters.merge(other: statisticInfo)
        additionalParameters["user_brand"] = DomainConfig.envInfo.isFeishuBrand ? "feishu" : "lark"
        additionalParameters["is_block"] = "false"
        DriveStatistic.enterPreview(fileID: fileID,
                                    fileType: fileType,
                                    fileTenantId: "", // 目前拿不到，android端没有上报
                                    previewFrom: previewFrom.rawValue,
                                    shouldReportClientFileOpen: true,
                                    isDriveSDK: isDriveSDK,
                                    mode: "preview",
                                    screenMode: "default",
                                    additionalParameters: additionalParameters)
    }

    /// IM Excel文件打开上报
    func reportExcelContentPageView(editMethod: FileEditMethod) {
        var params = [String: Any]()
        params["open_type"] = editMethod.statisticValue
        DriveStatistic.reportEvent(DocsTracker.EventType.excelContentPageView, fileId: fileID, fileType: fileType.rawValue, params: params)
    }

    /// Drive 文件预览新埋点
    func reportDrivePageView(isSupport: Bool, displayMode: DrivePreviewMode) {
        var params = [String: Any]()
        params["preview_viable"] = isSupport ? 1 : 0
        params["display"] = displayMode.statisticValue
        DriveStatistic.reportEvent(DocsTracker.EventType.drivePageView, fileId: fileID, fileType: fileType.rawValue, params: params)
    }
    
    func reportFileOpen(fileId: String, fileType: DriveFileType, isSupport: Bool) {
        var params = [String: Any]()
        params["preview_viable"] = isSupport ? 1 : 0
        params["mount_point"] = self.mountPoint
        if isFromWiki {
            params["container_type"] = "wiki"
            params["container_id"] = "none"
        }
        if !isLinkOpen {
            DriveStatistic.reportEvent(DocsTracker.EventType.drivePageView, fileId: fileId, fileType: fileType.rawValue, params: params)
        } else {
            DriveStatistic.reportEvent(DocsTracker.EventType.docsPageView, fileId: fileId, fileType: fileType.rawValue, params: params)
        }
    }
    
    /// 上报点击事件
    func reportClickEvent(_ event: DocsTrackerEventType, clickEventType: ClickEventType, params: [String: Any]) {
        DriveStatistic.reportClickEvent(event, clickEventType: clickEventType, fileId: fileID, fileType: fileType, params: params)
    }
    
    /// 上报事件
    func reportEvent(_ event: DocsTrackerEventType, params: [String: Any]) {
        var params = params
        if event.stringValue == "ccm_drive_edit_click" { params["mount_point"] = self.mountPoint }
        DriveStatistic.reportEvent(event, fileId: fileID, fileType: fileType.rawValue, params: params)
    }
    
    /// 更新 FileType (以附件形式的预览，DKStatistics 初始化时，无法知道文件类型，需由外部更新)
    func updateFileType(_ fileType: DriveFileType) {
        self.fileType = fileType
        self.commonTrackParams["sub_file_type"] = fileType.rawValue
    }
    
    func enterFileLandscape(_ isLandscape: Bool) {
        let module = DKSupportedApp(rawValue: appID)?.statisticModuleString ?? ""
        DriveStatistic.clientFileLandscape(fileId: fileID,
                                           subFileType: fileType,
                                           previewFrom: previewFrom.rawValue,
                                           module: module,
                                           isLandscape: isLandscape)
        
    }
    
    func exitPreview() {
        DriveStatistic.exitPreview()
    }
    
    func toggleAttribute(action: DriveStatisticAction,
                         source: DriveStatisticActionSource) {
        // 添加上报埋点数据 module，文件来源
        additionalParameters[DriveStatistic.ReportKey.module.rawValue] = DKSupportedApp(rawValue: appID)?.statisticModuleString ?? ""
        additionalParameters.merge(other: statisticInfo)
        DriveStatistic.toggleAttribute(fileId: fileID,
                                       subFileType: fileType.rawValue,
                                       action: action,
                                       source: source,
                                       previewFrom: previewFrom.rawValue,
                                       additionalParameters: additionalParameters)
    }

    func reportSaveToSpace() {
        var params: [String: String] = [
            "source": "attachment_more",
            "sub_file_type": fileType.rawValue,
            "preview_from": previewFrom.rawValue
        ]
        additionalParameters.merge(other: statisticInfo)
        params.merge(other: additionalParameters)
        DriveStatistic.clientContentManagement(action: .saveToDrive, fileId: fileID, additionalParameters: params)
    }
    
    func clientClickDisplay(screenMode: String) {
        DriveStatistic.clientClickDisplay(fileId: fileID, subFileType: fileType, screenMode: screenMode, preViewFrom: previewFrom.rawValue)
    }
    
}

extension FileEditMethod {
    var statisticValue: String {
        switch self {
        case .wps:
            return "wps"
        case .sheet:
            return "sheet"
        case .none:
            return "error"
        }
    }
}

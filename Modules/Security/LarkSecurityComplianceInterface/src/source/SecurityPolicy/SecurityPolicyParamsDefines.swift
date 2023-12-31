//
//  SecurityPolicyParamsDefines.swift
//  LarkSecurityComplianceInterface
//
//  Created by ByteDance on 2022/11/15.
//
import Foundation

public enum FileBizDomain: String, Codable, CaseIterable {
    case unknown = "Unknown"
    case ccm = "CCM"
    case im = "IM"
    case mail = "Mail"
    case vc = "VC"
    case todo = "TODO"
    case calendar = "Calendar"
    case passport = "Passport"
    case imOthers = "IM_Others"
}

public enum EntityDomain: String, Codable, CaseIterable {
    case unknown = ""
    case ccm = "CCM"
    case im = "IM"
    case mail = "MAIL"
    case vc = "VC"
    case todo = "TODO"
    case calendar = "CALENDAR"
    case passport = "PASSPORT"
    case orm = "ORM"
}

public enum EntityOperate: String, Codable, CaseIterable {
    case unknown = "Unknown"
    case ccmCopy = "CCM_CONTENT_COPY"                      // CCM内容复制
    case ccmPrint = "CCM_PRINT"                            // CCM文档打印
    case ccmExport = "CCM_EXPORT"                          // CCM文档导出
    case ccmShare = "CCM_SHARE"                            // CCM文档对外分享
    case ccmAttachmentDownload = "CCM_ATTACHMENT_DOWNLOAD" // CCM文件内部附件下载
    case ccmAttachmentUpload = "CCM_ATTACHMENT_UPLOAD"     // CCM文件内部附件上传
    case ccmContentPreview = "CCM_CONTENT_PREVIEW"         // CCM文档内容预览
    case ccmCreateCopy = "CCM_CREATE_COPY" // CCM创建副本
    case ccmPhysicalDelete = "CCM_DELETE"  // CCM文档物理删除
    case ccmFileUpload = "CCM_FILE_UPLOAD"     // CCM文件(drive)上传操作
    case ccmFilePreView = "CCM_FILE_PREVIEW"   // CCM文件(drive)预览
    case ccmFileDownload = "CCM_FILE_DOWNLOAD" // CCM文件(drive)下载
    case ccmMoveRecycleBin = "CCM_MOVE_RECYCLE_BIN" // CCM用户删除，移动到用户回收站
    case ccmAuth = "CCM_AUTH"
    case ccmDeleteFromRecycleBin = "CCM_DELETE_FROM_RECYCLE_BIN" // CCM从用户回收站删除
    case imFileDownload = "IM_MSG_FILE_DOWNLOAD" // IM文件下载
    case imFileSave = "IM_MSG_FILE_SAVE"         // IM文件保存
    case imFileUpload = "IM_MSG_FILE_UPLOAD"     // IM文件上传
    case imFileShare = "IM_MSG_FILE_SHARE"       // IM文件分享
    case imFilePreview = "IM_MSG_FILE_PREVIEW"   // IM文件预览
    case imFileCopy = "IM_MSG_FILE_COPY"         // IM文件复制
    case imFileRead = "IM_MSG_FILE_READ"         // IM文件尝试读场景
    case openExternalAccess = "CCM_OPEN_EXTERNAL_ACCESS" // CCM对外分享
}

public enum EntityType: String, Codable, CaseIterable {
    case doc = "DOC"                             // doc
    case docx = "DOCX"                           // docx
    case sheet = "SHEET"                         // 电子表格
    case bitable = "BITABLE"                     // 多维表格
    case mindnote = "MINDNOTE"                   // mindnote
    case file = "FILE"                           // 文件
    case dashboard = "DASHBOARD"                 // Dashboard
    case bitableShareForm = "BITABLE_SHARE_FORM" // bitable分享表单
    case chart = "CHART"                         // 图表
    case catalog = "CATALOG"                     // Deprecated: 文件夹目录-该类型废弃
    case pivotTable = "PIVOT_TABLE"              // 透视表格
    case spaceCatalog = "SPACE_CATALOG"         // 云空间的文件夹
    case wikiSpace = "WIKI_SPACE"
    // EntityTypeImMsg IM相关实体类型
    case imMsg = "IM_MSG"          // IM消息实体
    case imMsgFile = "IM_MSG_FILE" // IM消息中文件实体
    case imMsgChat = "IM_MSG_CHAT" // IM群实体
    // EntityTypeMail 相关实体类型
    case mail = "MAIL" // 邮件实体
    // TODO业务线实体
    case todoTask = "TODO_TASK" // todo任务实体类型
    // EntityTypeVC
    case meetingMinutes = "MeetingMinutes" // 妙计文件
    case vcMeeting = "VC_Meeting"          // VC会议实体
    // CALENDAR
    case calendarEvent = "Calendar_Event" // 日程
    case calendar = "Calendar"            // 日历实体
    case slides = "SLIDES"    // Slides
}

public enum PointKey: String, Codable, CaseIterable {
    case ccmExport = "PC:CLIENT:ios:PointKey_CCM_EXPORT"
    case ccmFileDownload = "PC:CLIENT:ios:PointKey_CCM_FILE_DOWNLOAD"
    case ccmAttachmentDownload = "PC:CLIENT:ios:PointKey_CCM_ATTACHMENT_DOWNLOAD"
    case ccmCopy = "PC:CLIENT:ios:PointKey_CCM_CONTENT_COPY"
    case ccmContentPreview = "PC:CLIENT:ios:PointKey_CCM_CONTENT_PREVIEW"
    case ccmFilePreView = "PC:CLIENT:ios:PointKey_CCM_FILE_PREVIEW"
    case ccmFileUpload = "PC:CLIENT:ios:PointKey_CCM_FILE_UPLOAD"
    case ccmAttachmentUpload = "PC:CLIENT:ios:PointKey_CCM_FILE_ATTACHMENT_UPLOAD"
    case ccmCreateCopy = "PC:CLIENT:ios:PointKey_CCM_CREATE_COPY"
    case ccmMoveRecycleBin = "PC:CLIENT:ios:PointKey_CCM_MOVE_RECYCLE_BIN"
    case imFileDownload = "PC:CLIENT:ios:PointKey_IM_MSG_FILE_DOWNLOAD"
    case imFilePreview = "PC:CLIENT:ios:PointKey_IM_MSG_FILE_PREVIEW"
    case imFileRead = "PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ"
    case imFileCopy = "PC:CLIENT:ios:PointKey_IM_MSG_FILE_COPY"
    case ccmDeleteFromRecycleBin = "PC:CLIENT:ios:PointKey_CCM_DELETE_FROM_RECYCLE_BIN"
    case ccmOpenExternalAccess = "PC:CLIENT:ios:PointKey_CCM_OPEN_EXTERNAL_ACCESS"
    
    // 虚拟切点，安全内部使用，构建切点模型时不要使用
    case ccmExportObject = "PC:CLIENT:ios:PointKey_CCM_EXPORT_OBJECT"
    case ccmFileDownloadObject = "PC:CLIENT:ios:PointKey_CCM_FILE_DOWNLOAD_OBJECT"
    case ccmAttachmentDownloadObject = "PC:CLIENT:ios:PointKey_CCM_ATTACHMENT_DOWNLOAD_OBJECT"
    case ccmCopyObject = "PC:CLIENT:ios:PointKey_CCM_CONTENT_COPY_OBJECT"
    case ccmOpenExternalAccessObject = "PC:CLIENT:ios:PointKey_CCM_OPEN_EXTERNAL_ACCESS_OBJECT"
}

//
//  SecurityReviewManager.swift
//  SKCommon
//
//  Created by LiXiaolin on 2020/10/30.
//  https://bytedance.feishu.cn/docs/doccnz0SWK6uemDeEla7v7U2T4g#

import Foundation
import SKFoundation
import SKUIKit
import SKResource
import LarkSecurityAudit
import SpaceInterface
import SKInfra
import LarkDocsIcon

//public enum ModuleType: Int {
//   case moduleDocs
//   case moduleSheets
//   case moduleFiles
//   case moduleFolders
//}

public enum OperationType: Int {
   case operationsExport                           // 导出
   case operationsShareTo3rdApp                    // 分享到第三方应用
   case operationsOpenWith3rdApp                   // 使用其它应用打开
   case operationsCopy                             //复制
   case operationsDownload                          //下载
   case operationsClickDocPlugin                   //一事一档插件点击跳转文档
}

public enum RenderItemKey: String {
   case ccmDownloadType = "ccm_download_type" // 云文档内容下载类型（枚举值：文字text、图片image、视频video、文件file、链接url、其他other
   case relationDocId = "relation_doc_id"  // 一事一档打开的文档 ID
   case relationUrl = "relation_url"       // 一事一档关联的网页地址
}


public final class SecurityReviewManager {
    // DrvieSDK 单独处理，涉及到 IM、小程序附件预览
    public class func reportDriveSDKAction(appID: String,
                                           fileID: String,
                                           operation: OperationType,
                                           driveType: DriveFileType? = nil) {
        reportDriveSDKActionCore(appID: appID, fileID: fileID,
                                 operation: operation,
                                 driveType: driveType,
                                 objectType: .entityDriverSdkfileID)
    }
    
    public class func reportDriveSDKLocalAction(appID: String,
                                                fileID: String,
                                                operation: OperationType,
                                                driveType: DriveFileType? = nil,
                                                thirdPartyID: String?) {
        reportDriveSDKActionCore(appID: appID, fileID: fileID, operation: operation, driveType: driveType, objectType: .entityLocalFile, thirdPartyID: thirdPartyID)
    }
    
    private class func reportDriveSDKActionCore(appID: String, fileID: String,
                                                operation: OperationType,
                                                driveType: DriveFileType? = nil,
                                                objectType: SecurityEvent_EntityType,
                                                thirdPartyID: String? = nil) {
        guard let deviceID = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.deviceID) else {
            DocsLogger.info("SecurityReviewManager deviceId 拿不到")
            return
        }
        let securityAudit = SecurityAudit()

        var evt = Event()
        evt.module = .moduleImfile
        evt.env.did = deviceID
        if let ip = getInterfaceIPAddress() {
            evt.env.ip = ip
        }
        evt.operation = getoperationType(operation)
        evt.operator = OperatorEntity()
        evt.operator.type = .entityUserID
        evt.operator.value = User.current.info?.userID ?? ""

        let dict = ["app_id": appID, "app_file_id": fileID]
        var opType = SecurityEvent_ObjectEntity()
        opType.type = objectType
        opType.value = dict.toJSONString() ?? ""
        opType.detail.thirdPartyAppID = thirdPartyID ?? ""
        evt.objects = [opType]

        var itemList = [SecurityEvent_RenderItem]()
        if let driveType = driveType, operation == .operationsDownload {
            itemList = self.getDriveSecurityEventitem(driveType: driveType)
        }
        evt.extend.commonDrawer.itemList = itemList

        securityAudit.auditEvent(evt)
    }

    //通过admin提供的securityAudit进行上报，审计用户的一些导出行为
    public class func reportAction(_ type: DocsType,
                                   operation: OperationType,
                                   driveType: DriveFileType? = nil,
                                   token: String,
                                   appInfo: ShareAssistType?,
                                   wikiToken: String?,
                                   renderItems: [SecurityEvent_RenderItem]? = nil) {
        guard let deviceID = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.deviceID) else {
            DocsLogger.info("SecurityReviewManager deviceId 拿不到")
            return
        }
        let securityAudit = SecurityAudit()

        var evt = Event()
        evt.module = getModuleByDocsType(type)
        evt.env.did = deviceID
        if let ip = getInterfaceIPAddress() {
            evt.env.ip = ip
        }
        evt.operation = getoperationType(operation)
        evt.operator = OperatorEntity()
        evt.operator.type = .entityUserID
        evt.operator.value = User.current.info?.userID ?? ""
        evt.extend.appDetail = getInfoByShareAssistType(appInfo)
        var opType = SecurityEvent_ObjectEntity()
        opType.type = getEntityTypeByDocsType(type)
        opType.value = token

        if let wikiToken = wikiToken {
            opType.detail.containerType = .wiki
            opType.detail.containerID = wikiToken
        }
        evt.objects = [opType]

        if let renderItems = renderItems {
            evt.extend.commonDrawer.itemList = renderItems
        }

        securityAudit.auditEvent(evt)
    }

    // 通过DocsType映射获得SDK需要的SecurityEvent_ModuleType
    private class func getModuleByDocsType(_ type: DocsType) -> SecurityEvent_ModuleType {
        var module = SecurityEvent_ModuleType.moduleUnknown
        switch type {
        case .docX:
            module = .moduleDocx
        case .doc:
            module = .moduleDocs
        case .sheet:
            module = .moduleSheets
        case .file:
            module = .moduleFiles
        case .folder:
            module = .moduleFolders
        case .mindnote:
            module = .moduleMindNote
        default:
            module = .moduleUnknown
        }
        return module
    }

    // 通过DocsType映射获得SDK需要的SecurityEvent_ModuleType
    private class func getEntityTypeByDocsType(_ type: DocsType) -> SecurityEvent_EntityType {
        var entityType = SecurityEvent_EntityType.unknown
        switch type {
        case .docX:
            entityType = .entityDocxID
        case .doc:
            entityType = .entityDocID
        case .sheet:
            entityType = .entitySheetID
        case .file:
            entityType = .entityFileID
        case .folder:
            entityType = .entityFolderID
        case .mindnote:
            entityType = .entityMindNoteID
        default:
            entityType = .unknown
        }
        return entityType
    }

    // 通过OperationType映射获得SDK需要的SecurityEvent_OperationType
    private class func getoperationType(_ type: OperationType) -> SecurityEvent_OperationType {
        var operation = SecurityEvent_OperationType.unknown
        switch type {
        case .operationsOpenWith3rdApp:
            operation = .operationOpenWith3RdApp
        case .operationsExport:
            operation = .operationFrontExport
        case .operationsShareTo3rdApp:
            operation = .operationShareTo3RdApp
        case .operationsCopy:
            operation = .operationCopyContent
        case .operationsDownload:
            operation = .operationDownload
        case .operationsClickDocPlugin:
            operation = .operationSpaceDocClickDocPlugin
        }
        return operation
    }

    // 通过ShareAssistType映射获得SDK需要的AppInfo
    private class func getInfoByShareAssistType(_ type: ShareAssistType?) -> SecurityEvent_AppDetail {
        var info = SecurityEvent_AppDetail.unknown
        switch type {
        case .more:
            info = SecurityEvent_AppDetail.others
        case .wechat:
            info = SecurityEvent_AppDetail.weChat
        case .wechatMoment:
            info = SecurityEvent_AppDetail.weChatMoments
        case .weibo:
            info = SecurityEvent_AppDetail.weibo
        case .qq:
            info = SecurityEvent_AppDetail.qq
        default:
            info = SecurityEvent_AppDetail.unknown
        }
        return info
    }

    private enum AddressRequestType {
        case ipAddress
        case netmask
    }

    // From BDS ioccom.h
    // Macro to create ioctl request
    private static func _IOC (_ io: UInt32, _ group: UInt32, _ num: UInt32, _ len: UInt32) -> UInt32 {
        let rv = io | (( len & UInt32(IOCPARM_MASK)) << 16) | ((group << 8) | num)
        return rv
    }

    // Macro to create read/write IOrequest
    private static func _IOWR (_ group: Character, _ num: UInt32, _ size: UInt32) -> UInt32 {
        return _IOC(IOC_INOUT, UInt32(group.asciiValue!), num, size)
    }

    private static func _interfaceAddressForName (_ name: String, _ requestType: AddressRequestType) throws -> String {

        var ifr = ifreq()
        ifr.ifr_ifru.ifru_addr.sa_family = sa_family_t(AF_INET)

        // Copy the name into a zero padded 16 CChar buffer

        let ifNameSize = Int(IFNAMSIZ)
        var b = [CChar](repeating: 0, count: ifNameSize)
        strncpy(&b, name, ifNameSize)

        // Convert the buffer to a 16 CChar tuple - that's what ifreq needs
        ifr.ifr_name = (b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15])

        let ioRequest: UInt32 = {
            switch requestType {
            case .ipAddress: return _IOWR("i", 33, UInt32(MemoryLayout<ifreq>.size))    // Magic number SIOCGIFADDR - see sockio.h
            case .netmask: return _IOWR("i", 37, UInt32(MemoryLayout<ifreq>.size))      // Magic number SIOCGIFNETMASK
            }
        }()

        if ioctl(socket(AF_INET, SOCK_DGRAM, 0), UInt(ioRequest), &ifr) < 0 {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? POSIXErrorCode.EINVAL)
        }

        let sin = unsafeBitCast(ifr.ifr_ifru.ifru_addr, to: sockaddr_in.self)
        let rv = String(cString: inet_ntoa(sin.sin_addr))

        return rv
    }
    public static func getInterfaceIPAddress() -> String? {
        return try? getInterfaceIPAddress(interfaceName: "en0")
    }

    public static func getInterfaceIPAddress(interfaceName: String) throws -> String {
        return try _interfaceAddressForName(interfaceName, .ipAddress)
    }

//    public static func getInterfaceNetMask(interfaceName: String) throws -> String {
//        return try _interfaceAddressForName(interfaceName, .netmask)
//    }
}

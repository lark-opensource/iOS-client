//
//  Extension.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/12/12.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkSecurityAudit
import SwiftyJSON
import LarkPolicyEngine
import LarkSecurityComplianceInfra

extension AuthResult {
    var validateResultType: ValidateResultType {
        switch self {
        case .allow:
            return .allow
        case .deny:
            return .deny
        case .null:
            return .null
        case .error:
            return .error
        default:
            return .unknown
        }
    }
}

extension AuthResultErrorReason {
    var validateErrorReason: ValidateErrorReason {
        switch self {
        case .networkError:
            return .networkError
        case .requestTimeout:
            return .requestTimeout
        default:
            return .requestFailed
        }
    }
}

extension PolicyModel: Hashable {
    public static func == (lhs: LarkSecurityComplianceInterface.PolicyModel, rhs: LarkSecurityComplianceInterface.PolicyModel) -> Bool {
        return lhs.taskID == rhs.taskID
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(taskID)
    }
}

extension PolicyModel: CustomStringConvertible {
    public var description: String { taskID }
}

extension PolicyModel {
    var isScene: Bool {
        SecurityPolicyConstKey.scenePointKey.contains(pointKey)
    }

    var debugDescription: String {
        return "\(entity.entityOperate.rawValue).\(entity.entityType.rawValue)"
    }

    static func policyModel(taskID: String) -> PolicyModel? {
        guard let data = taskID.data(using: .utf8) else { return nil }
                let policyModel = try? JSONDecoder().decode(PolicyModel.self, from: data)
                return policyModel
    }
}

extension EntityOperate {
    var isScene: Bool {
        SecurityPolicyConstKey.sceneEntityOperate.contains(self)
    }
}

extension PolicyEntity {
    var rustActionModel: NoPermissionRustActionModel {
        var params: [String: JSON] = [:]
        var bizDomainJson = JSON(parseJSON: entityDomain.rawValue)
        bizDomainJson.stringValue = entityDomain.rawValue
        var operateJson = JSON(parseJSON: entityDomain.rawValue)
        operateJson.stringValue = entityOperate.rawValue
        params[Key.bizDomain.rawValue] = bizDomainJson
        params[Key.operate.rawValue] = operateJson
        let actionModel = NoPermissionRustActionModel.ActionModel(name: "FILE_BLOCK_COMMON",
                                                                  params: params)
        return NoPermissionRustActionModel(action: actionModel)
    }

    func temporaryIntegrateToDoc() {
        guard ccmCloudFileEntityType.contains(self.entityType) else { return }
        self.entityType = .doc
    }

    private var ccmCloudFileEntityType: [LarkSecurityComplianceInterface.EntityType] {
        return [
            .docx,
            .sheet,
            .bitable,
            .mindnote,
            .dashboard,
            .chart,
            .bitableShareForm,
            .pivotTable,
            .spaceCatalog,
            .wikiSpace,
            .slides
        ]
    }

}

extension Action {
    /// 策略引擎Action模型转化为访问控制链路中的ActionModel模型
    var rustActionModel: NoPermissionRustActionModel {
        let params: [String: JSON] = params.compactMapValues {
            guard let value = $0 as? String else { return nil }
            return JSON(rawValue: value)
        }
        let actionModel = NoPermissionRustActionModel.ActionModel(name: name,
                                                                  params: params)
        return NoPermissionRustActionModel(action: actionModel)
    }
}

extension NoPermissionRustActionModel {
    var rawActionModelString: String {
        let data: Data
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
             data = try encoder.encode(self)
        } catch {
            SCLogger.info("rawActionModelString decode failed, error:\(error)")
            return ""
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}

extension ResponseType {
    var validateResultMethod: ValidateResultMethod {
        switch self {
        case .fastPass:
            return .fastpass
        case .local:
            return .localStrategy
        case .remote:
            return .serverStrategy
        case .downgrade:
            return .downgrade
        }
    }
}

extension FileBizDomain {
    var trackName: String {
        switch self {
        case .ccm:
            return "ccm"
        case .im:
            return "im"
        case .calendar:
            return "calendar"
        default:
            return "unknown"
        }
    }
}

extension OperateCategory {
    var trackName: String {
        switch self {
        case .Lark_Conditions_FilePolicy_Dialog_NoUpload:
            return "upload"
        case .Lark_Conditions_FilePolicy_Dialog_NoDownload:
            return "download"
        case .Lark_Conditions_FilePolicy_Dialog_NoPrinting:
            return "print"
        case .Lark_Conditions_FilePolicy_Dialog_NoCopying:
            return "copy_content"
        case .Lark_Conditions_FilePolicy_Dialog_NoDuplicates:
            return "copy_file"
        case .Lark_Conditions_FilePolicy_Dialog_NoSharing:
            return "share"
        case .Lark_Conditions_FilePolicy_Dialog_NoPreview:
            return "view"
        case .Lark_Conditions_FilePolicy_Dialog_NoDeleting:
            return "delete"
        case .Lark_Conditions_FilePolicy_Dialog_NoOperate:
            return "unknown"
        }
    }
}

extension LarkPolicyEngine.Action {
    public var validateResource: ValidateSource {
        switch name {
        case "FILE_BLOCK_COMMON":
            return .fileStrategy
        case "DLP_CONTENT_DETECTING":
            return .dlpDetecting
        case "DLP_CONTENT_SENSITIVE":
            return .dlpSensitive
        case "TT_BLOCK":
            return .ttBlock
        default:
            return .unknown
        }
    }
}

extension PointKey {
    var isScene: Bool {
        switch self {
        case .imFileRead,
                .imFileDownload,
                .ccmCopyObject,
                .ccmExportObject,
                .ccmFileDownloadObject,
                .ccmAttachmentDownloadObject,
                .ccmOpenExternalAccessObject:
            return true
        case .ccmAttachmentDownload,
                .ccmExport,
                .ccmFileDownload,
                .ccmContentPreview,
                .ccmFilePreView,
                .ccmFileUpload,
                .ccmAttachmentUpload,
                .ccmCopy,
                .ccmCreateCopy,
                .ccmDeleteFromRecycleBin,
                .ccmMoveRecycleBin,
                .imFilePreview,
                .imFileCopy:
            return false
        default:
            return false
        }
    }
}

extension ValidateConfig: SCLoggerAdditionalDataConvertable {
    public var logData: [String: String] {
        ["cid": cid]
    }
}

extension PolicyModel: SCLoggerAdditionalDataConvertable {
    public var logData: [String: String] {
        ["entityOperate": "\(entity.entityOperate)",
         "entityType": "\(entity.entityType)",
         "pointKey": "\(pointKey)"]
    }
}

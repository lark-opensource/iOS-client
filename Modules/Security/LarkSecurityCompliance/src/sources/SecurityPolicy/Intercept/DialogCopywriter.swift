//
//  DialogCopywriter.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/10/14.
//

import Foundation
import LarkSecurityComplianceInterface

extension EntityOperate {
    var category: OperateCategory {
        switch self {
        case .ccmCopy:
            return .Lark_Conditions_FilePolicy_Dialog_NoCopying
        case .ccmPrint:
            return .Lark_Conditions_FilePolicy_Dialog_NoPrinting
        case .ccmExport:
            return .Lark_Conditions_FilePolicy_Dialog_NoDownload
        case .ccmShare:
            return .Lark_Conditions_FilePolicy_Dialog_NoSharing
        case .ccmAttachmentDownload:
            return .Lark_Conditions_FilePolicy_Dialog_NoDownload
        case .ccmAttachmentUpload:
            return .Lark_Conditions_FilePolicy_Dialog_NoUpload
        case .ccmContentPreview:
            return .Lark_Conditions_FilePolicy_Dialog_NoPreview
        case .ccmCreateCopy:
            return .Lark_Conditions_FilePolicy_Dialog_NoDuplicates
        case .ccmPhysicalDelete:
            return .Lark_Conditions_FilePolicy_Dialog_NoDeleting
        case .ccmFileUpload:
            return .Lark_Conditions_FilePolicy_Dialog_NoUpload
        case .ccmFilePreView:
            return .Lark_Conditions_FilePolicy_Dialog_NoPreview
        case .ccmFileDownload:
            return .Lark_Conditions_FilePolicy_Dialog_NoDownload
        case .ccmMoveRecycleBin:
            return .Lark_Conditions_FilePolicy_Dialog_NoDeleting
        case .ccmAuth:
            return .Lark_Conditions_FilePolicy_Dialog_NoSharing
        case .imFileDownload:
            return .Lark_Conditions_FilePolicy_Dialog_NoDownload
        case .imFileSave:
            return .Lark_Conditions_FilePolicy_Dialog_NoDownload
        case .imFileUpload:
            return .Lark_Conditions_FilePolicy_Dialog_NoUpload
        case .imFileShare:
            return .Lark_Conditions_FilePolicy_Dialog_NoSharing
        case .imFilePreview:
            return .Lark_Conditions_FilePolicy_Dialog_NoPreview
        case .imFileCopy:
            return .Lark_Conditions_FilePolicy_Dialog_NoCopying
        case .imFileRead:
            return .Lark_Conditions_FilePolicy_Dialog_NoSharing
        case .ccmDeleteFromRecycleBin:
            return .Lark_Conditions_FilePolicy_Dialog_NoDeleting
        default:
            return .Lark_Conditions_FilePolicy_Dialog_NoOperate
        }
    }
}

enum OperateCategory: Int {
    case Lark_Conditions_FilePolicy_Dialog_NoOperate = 0
    case Lark_Conditions_FilePolicy_Dialog_NoUpload = 1
    case Lark_Conditions_FilePolicy_Dialog_NoDownload = 2
    case Lark_Conditions_FilePolicy_Dialog_NoPrinting = 3
    case Lark_Conditions_FilePolicy_Dialog_NoCopying = 4
    case Lark_Conditions_FilePolicy_Dialog_NoDuplicates = 5
    case Lark_Conditions_FilePolicy_Dialog_NoDeleting = 6
    case Lark_Conditions_FilePolicy_Dialog_NoSharing = 7
    case Lark_Conditions_FilePolicy_Dialog_NoPreview = 8

    var title: String {
        switch self {
        case .Lark_Conditions_FilePolicy_Dialog_NoOperate:
            return I18N.Lark_Conditions_FilePolicy_Dialog_NoActionsAllowed
        case .Lark_Conditions_FilePolicy_Dialog_NoCopying:
            return I18N.Lark_Conditions_FilePolicy_Dialog_NoCopying
        case .Lark_Conditions_FilePolicy_Dialog_NoUpload:
            return I18N.Lark_Conditions_FilePolicy_Dialog_NoUpload
        case .Lark_Conditions_FilePolicy_Dialog_NoDownload:
            return I18N.Lark_Conditions_FilePolicy_Dialog_NoDownload
        case .Lark_Conditions_FilePolicy_Dialog_NoPrinting:
            return I18N.Lark_Conditions_FilePolicy_Dialog_NoPrinting
        case .Lark_Conditions_FilePolicy_Dialog_NoDuplicates:
            return I18N.Lark_Conditions_FilePolicy_Dialog_NoDuplicates
        case .Lark_Conditions_FilePolicy_Dialog_NoDeleting:
            return I18N.Lark_Conditions_FilePolicy_Dialog_NoDeleting
        case .Lark_Conditions_FilePolicy_Dialog_NoSharing:
            return I18N.Lark_Conditions_FilePolicy_Dialog_NoSharing
        case .Lark_Conditions_FilePolicy_Dialog_NoPreview:
            return I18N.Lark_Conditions_FilePolicy_Dialog_NoPreview
        }
    }
}

func getInterceptText(code: String) -> String {
    switch code {
    case "00", "01", "02":
        return I18N.Lark_Conditions_FilePolicy_Dialog_NoActionsAllowedBCOrgSettings
    case "10":
        return I18N.Lark_Conditions_FilePolicy_Dialog_CantUploadBecauseFilePolicy
    case "11":
        return I18N.Lark_Conditions_FilePolicy_Dialog_CantUploadFileBecauseFilePolicy
    case "12":
        return I18N.Lark_Conditions_FilePolicy_Dialog_CantUploadAttachBecauseFilePolicy
    case "20":
        return I18N.Lark_Conditions_FilePolicy_Dialog_CantDownloadSinceSettings
    case "21":
        return I18N.Lark_Conditions_FilePolicy_Dialog_OnlyDownloadAllowedFiles
    case "22":
        return I18N.Lark_Conditions_FilePolicy_Dialog_CantDownloadAttach
    case "30", "31", "32":
        return I18N.Lark_Conditions_FilePolicy_Dialog_CantPrintSinceSettings
    case "40":
        return I18N.Lark_Conditions_FilePolicy_Dialog_NoCopingAllowed
    case "41", "42":
        return I18N.Lark_Conditions_FilePolicy_Dialog_CantCopySinceSettings
    case "50", "51", "52":
        return I18N.Lark_Conditions_FilePolicy_Dialog_CantDuplicateSinceSettings
    case "60", "61", "62":
        return I18N.Lark_Conditions_FilePolicy_Dialog_OnlyDeleteAllowedFiles
    case "70":
        return I18N.Lark_Conditions_FilePolicy_Dialog_UnableToAccessFile
    case "71", "72":
        return I18N.Lark_Conditions_FilePolicy_Dialog_CantShareToPerson
    case "80", "81", "82":
        return I18N.Lark_Conditions_FilePolicy_Dialog_CantPreviewSinceSettings
    default:
        return I18N.Lark_Conditions_FilePolicy_Dialog_NoActionsAllowedBCOrgSettings
    }
}

func getLowCode(operate: EntityOperate) -> String {
    let str = operate.rawValue
    if str.contains("IM") { return "0" }
    if str.contains("CCM") {
        if str.contains("ATTACHMENT") {
            return "2"
        }
        return "1"
    }
    // 应该有一个兜底值
    return "0"
}

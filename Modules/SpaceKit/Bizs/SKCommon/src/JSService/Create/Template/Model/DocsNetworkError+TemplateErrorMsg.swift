//
//  String+TemplateErrorCode.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2022/3/24.
//  


import SKFoundation
import SKResource

extension DocsNetworkError.Code {
    public func templateErrorMsg() -> String {
        switch self {
        case .coldDocument:
            return BundleI18n.SKResource.CreationMobile_Operation_ReloadfromThirdParty
        case .templateNotPermission, .templateDeleted:
            return BundleI18n.SKResource.Doc_List_TemplateNoPermissionToast
        case .templateLimited:
            return BundleI18n.SKResource.CreationDoc_Template_ReachedLimit
        case .templateCollaboratorNotPermission:
            return BundleI18n.SKResource.CreationMobile_Template_OnlyEditorCanUse_Hover
        case .templateUnableToPreviewSecurityReason:
            return BundleI18n.SKResource.LarkCCM_Templates_UnableToPreview_SecurityReason_Mob
        default:
            return BundleI18n.SKResource.Doc_List_TemplateGeneralErrorToast
        }
    }
}

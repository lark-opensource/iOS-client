//
//  BTFiledUtils.swift
//  SKBitable
//
//  Created by yinyuan on 2023/11/22.
//

import SKFoundation
import UniverseDesignToast
import SKResource

class BTFiledUtils {
    
    static func showUneditableToast(fieldModel: BTFieldModel, view: UIView?) {
        guard !fieldModel.editable else { return }
        if let window = view?.window {
            switch fieldModel.uneditableReason {
            case .notSupported:
                if fieldModel.compositeType.isImmutableType {
                    UDToast.showWarning(with: BundleI18n.SKResource.Doc_Block_NotSupportModifyField, on: window)
                } else {
                    UDToast.showWarning(with: BundleI18n.SKResource.Doc_Block_NotSupportEditField, on: window)
                }
            case .fileReadOnly:
                break
            case .phoneLandscape:
                UDToast.showWarning(with: BundleI18n.SKResource.Doc_Block_NotSupportEditInLandscape, on: window)
            case .proAdd:
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_AdvancedPermission_UnableToUploadAttachment, on: window)
            case .others:
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermissionToEditFieldToast, on: window)
            case .bitableNotReady:
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_Record_LoadingCannotEdit_Mobile, on: window)
//            case .unreadable:
//                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToViewFieldContent, on: window)
            case .drillDown:
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_Dashboard_DrillDown_DataDetailCannotEdit_Toast, on: window)
            case .isSyncTable:
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_DataReference_SyncFromOtherBase_ActionNotSupported_Tooltip, on: window)
            case .isExtendField:
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_PeopleField_FieldWillSyncFromContact_Tooltip(), on: window)
            case .editAfterSubmit:
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_QuickAdd_EditAfterSubmit_Tooltip, on: window)
            case .isOnDemand:
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_Mobile_DataOverLimitNotSupport_Desc, on: window)
            }
        }
    }
}

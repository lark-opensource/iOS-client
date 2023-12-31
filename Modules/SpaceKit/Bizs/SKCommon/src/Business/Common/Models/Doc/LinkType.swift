//
//  LinkType.swift
//  SKCommon
//
//  Created by lijuyou on 2020/7/13.
//  


import Foundation
import SKResource

// From ShareLinkEditViewController+config.swift
public enum LinkType {
    enum Sub: Int {
        case closeLinkDes
        case linkForOrgReadDes
        case linkForOrgReadFolderDes
        case linkForOrgEditDes
        case linkForOrgEditFolderDes
        case anybodyKnownLinkCanReadDes
        case anybodyKnownLinkAndPasswordCanReadDes
        case anybodyKnownLinkCanReadFolderDes
        case anybodyKnownLinkCanEditDes
        case anybodyKnownLinkAndPasswordCanEditDes
        case toCAnybodyKnownLinkCanReadDes
        case toCAnybodyKnownLinkCanReadFolderDes
        case toCAnybodyKnownLinkCanEditDes
        // 关联组织
        case partnerTenantKnownLinkCanReadDes
        case partnerTenantKnownLinkCanReadFolderDes
        case partnerTenantKnownLinkCanEditDes
        // 可搜
        case peopleInOrgCanSearchAndView
        case peopleInOrgCanSearchAndEdit
        case peopleOnInternetCanViewPeopleInOrgCanSearch
        case peopleOnInternetCanEditPeopleInOrgCanSearch
        case anybodyKnownLinkAndPasswordCanViewPeopleInOrgCanSearch
        case anybodyKnownLinkAndPasswordCanEditPeopleInOrgCanSearch
        
        public var tenantName: String {
            return User.current.info?.tenantName ?? ""
        }
        public var text: String {
            switch self {
            case .closeLinkDes:
                return BundleI18n.SKResource.Doc_Share_CloseLinkDes
            case .linkForOrgReadDes:
                return BundleI18n.SKResource.CreationMobile_ECM_SharePanel_Link_InternalCanView
            case .linkForOrgReadFolderDes:
                return BundleI18n.SKResource.CreationMobile_ECM_SharePanel_Link_InternalCanView
            case .linkForOrgEditDes:
                return BundleI18n.SKResource.CreationMobile_ECM_SharePanel_Link_InternalCanEdit
            case .linkForOrgEditFolderDes:
                return BundleI18n.SKResource.CreationMobile_ECM_SharePanel_Link_InternalCanEdit
            case .anybodyKnownLinkCanReadDes:
                return BundleI18n.SKResource.Doc_Share_KnownLinkCanReadDes
            case .anybodyKnownLinkCanReadFolderDes:
                return BundleI18n.SKResource.Doc_Share_AnyKnownLinkCanReadDes
            case .anybodyKnownLinkCanEditDes:
                return BundleI18n.SKResource.Doc_Share_KnownLinkCanEditDes
            case .toCAnybodyKnownLinkCanReadDes:
                return BundleI18n.SKResource.Doc_Share_AnyKnownLinkCanReadDes
            case .toCAnybodyKnownLinkCanReadFolderDes:
                return BundleI18n.SKResource.Doc_Share_AnyKnownLinkCanReadDes
            case .toCAnybodyKnownLinkCanEditDes:
                return BundleI18n.SKResource.Doc_Share_AnyKnownLinkCanEditDes
            case .partnerTenantKnownLinkCanReadDes:
                return BundleI18n.SKResource.CreationMobile_ECM_SharePanel_View_RelatedOrg
            case .partnerTenantKnownLinkCanReadFolderDes:
                return BundleI18n.SKResource.CreationMobile_ECM_SharePanel_View_RelatedOrg
            case .partnerTenantKnownLinkCanEditDes:
                return BundleI18n.SKResource.CreationMobile_ECM_SharePanel_Edit_RelatedOrg
            case .peopleInOrgCanSearchAndView:
                return BundleI18n.SKResource.LarkCCM_Perm_PeopleInOrgCanSearchAndView_Dropdown(BundleI18n.SKResource.LarkCCM_Perm_PermType_CanSearchAndView)
            case .peopleInOrgCanSearchAndEdit:
                return BundleI18n.SKResource.LarkCCM_Perm_PeopleInOrgCanSearchAndView_Dropdown(BundleI18n.SKResource.LarkCCM_Perm_PermType_CanSearchAndEdit)
            case .peopleOnInternetCanViewPeopleInOrgCanSearch:
                return BundleI18n.SKResource.LarkCCM_Perm_PeopleOnInternetCanView_PeopleInOrgCanSearch_Dropdown(BundleI18n.SKResource.LarkCCM_Perm_PermType_CanView, BundleI18n.SKResource.LarkCCM_Perm_PermType_CanSearch)
            case .peopleOnInternetCanEditPeopleInOrgCanSearch:
                return BundleI18n.SKResource.LarkCCM_Perm_PeopleOnInternetCanEdit_PeopleInOrgCanSearch_Dropdown(BundleI18n.SKResource.LarkCCM_Perm_PermType_CanEdit, BundleI18n.SKResource.LarkCCM_Perm_PermType_CanSearch)
            case .anybodyKnownLinkAndPasswordCanReadDes:
                return BundleI18n.SKResource.LarkCCM_Perm_AnyoneWithLinkAndPassword(BundleI18n.SKResource.LarkCCM_Perm_PermType_CanView)
            case .anybodyKnownLinkAndPasswordCanEditDes:
                return BundleI18n.SKResource.LarkCCM_Perm_AnyoneWithLinkAndPassword(BundleI18n.SKResource.LarkCCM_Perm_PermType_CanEdit)
            case .anybodyKnownLinkAndPasswordCanViewPeopleInOrgCanSearch:
                return BundleI18n.SKResource.LarkCCM_Perm_AnyoneWithLinkAndPassword_PeopleInOrg(BundleI18n.SKResource.LarkCCM_Perm_PermType_CanView, BundleI18n.SKResource.LarkCCM_Perm_PermType_CanSearch)
            case .anybodyKnownLinkAndPasswordCanEditPeopleInOrgCanSearch:
                return BundleI18n.SKResource.LarkCCM_Perm_AnyoneWithLinkAndPassword_PeopleInOrg(BundleI18n.SKResource.LarkCCM_Perm_PermType_CanEdit, BundleI18n.SKResource.LarkCCM_Perm_PermType_CanSearch)
            }
        }
    }

    enum FormSub: Int {
        case orgMemberCanWriteDes
        case onlyInvitedCanWriteDes
        case anybodyKnownLinkCanWriteDes
        public var tenantName: String {
            return User.current.info?.tenantName ?? ""
        }
        public var text: String {
            switch self {
            case .orgMemberCanWriteDes:
                return BundleI18n.SKResource.Bitable_Form_InternalUserCanFillIn
            case .onlyInvitedCanWriteDes:
                return BundleI18n.SKResource.Bitable_Form_InvitedCollaboratorCanFillIn
            case .anybodyKnownLinkCanWriteDes:
                return BundleI18n.SKResource.Bitable_Form_AnyoneCanFillIn
            }
        }
    }
    
    public enum BitableSub: Int {
        case onlyInvitedPeopleCanView
        case peopleWithLinkInTheOrgCanView
        case peopleWithLinkOnTheInternetCanView
        public var text: String {
            switch self {
            case .onlyInvitedPeopleCanView:
                return BundleI18n.SKResource.Bitable_Share_OnlyInvitedPeopleCanView_Dropdown
            case .peopleWithLinkInTheOrgCanView:
                return BundleI18n.SKResource.Bitable_Share_PeopleWithLinkInTheOrgCanView_Dropdown
            case .peopleWithLinkOnTheInternetCanView:
                return BundleI18n.SKResource.Bitable_Share_PeopleWithLinkOnTheInternetCanView_Dropdown
            }
        }
    }
}

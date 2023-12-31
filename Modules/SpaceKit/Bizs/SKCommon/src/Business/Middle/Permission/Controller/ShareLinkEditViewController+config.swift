//
//  ShareLinkEditViewController+config.swift
//  SpaceKit
//
//  Created by liweiye on 2020/6/11.

import Foundation
import SKFoundation
import SKResource
import UniverseDesignColor
import LarkReleaseConfig
import SKInfra

enum ShareLinkEditSection: Int {
    /// 链接分享设置
    case shareLinkSetting
    /// 可搜索设置
    case searchableSetting
    /// 密码启用
    case passwordSwitch
    /// 更换密码和复制链接与密码
    case passwordChangeAndCopy
    
    static func instance(rawValue: Int, searchSettingEnable: Bool) -> Self? {
        if searchSettingEnable {
            switch rawValue {
            case 0:
                return .shareLinkSetting
            case 1:
                return .searchableSetting
            case 2:
                return .passwordSwitch
            case 3:
                return .passwordChangeAndCopy
            default:
                DocsLogger.error("Invalid ShareLinkEditSection: rawValue(\(rawValue)")
                spaceAssertionFailure("Invalid ShareLinkEditSection")
                return nil
            }
        } else {
            switch rawValue {
            case 0:
                return .shareLinkSetting
            case 1:
                return .passwordSwitch
            case 2:
                return .passwordChangeAndCopy
            default:
                DocsLogger.error("Invalid ShareLinkEditSection: rawValue(\(rawValue)")
                spaceAssertionFailure("Invalid ShareLinkEditSection")
                return nil
                return nil
            }
        }
    }

    var heightForHeaderInSection: CGFloat {
        switch self {
        case .shareLinkSetting, .searchableSetting, .passwordSwitch:
            return 36
        case .passwordChangeAndCopy:
            return 8
        }
    }

    var viewForHeaderInSection: UIView? {
        switch self {
        case .shareLinkSetting:
            return ShareLinkHeaderView(title: BundleI18n.SKResource.LarkCCM_Perm_LinkSharingPermSettings_Title)
        case .searchableSetting:
            return ShareLinkHeaderView(title: BundleI18n.SKResource.LarkCCM_Perm_SearchableSettings_Title)
        case .passwordSwitch:
            return ShareLinkHeaderView(title: BundleI18n.SKResource.Doc_Share_PasswordSetting)
        case .passwordChangeAndCopy:
            let view = UIView()
            view.backgroundColor = UDColor.bgBase
            return view
        }
    }

    func viewForFooterInSection(enableAnonymousAccess: Bool, isFolder: Bool) -> UIView? {
        switch self {
        case .shareLinkSetting, .searchableSetting, .passwordChangeAndCopy:
            return nil
        case .passwordSwitch:
            return enableAnonymousAccess ? nil : PasswordSettingFooterView(isFolder: isFolder)
        }
    }

    func heightForFooterInSection(enableAnonymousAccess: Bool) -> CGFloat {
        switch self {
        case .shareLinkSetting, .searchableSetting, .passwordChangeAndCopy:
            return 0.01
        case .passwordSwitch:
            return enableAnonymousAccess ? 0.01 : 22
        }
    }
}

extension ShareLinkEditViewController {

    var fileEntryIsFolder: Bool { self.shareEntity.type == .folder }

    var isToC: Bool {
        return User.current.info?.isToNewC == true
    }

    /// 是否支持文件夹对外分享
    var isFolder: Bool {
        return self.shareEntity.isFolder
    }
    
    var searchSettingEnable: Bool {
        guard UserScopeNoChangeFG.PLF.searchEntityEnable else {
            DocsLogger.info("searchSettingEnable: fg is disabled", component: LogComponents.permission)
            return false
        }
        guard shareEntity.wikiV2SingleContainer || shareEntity.spaceSingleContainer else {
            DocsLogger.info("searchSettingEnable: not wiki2.0 or space2.0", component: LogComponents.permission)
            return false
        }
        guard !shareEntity.isFolder && ![.minutes, .form].contains(shareEntity.type) else {
            DocsLogger.info("searchSettingEnable: docType is disabled", component: LogComponents.permission)
            return false
        }
        guard !isToC else {
            DocsLogger.info("searchSettingEnable: is to c user", component: LogComponents.permission)
            return false
        }
        guard !canShowPartnerTenantAccessLinkInfos else {
            DocsLogger.info("searchSettingEnable: can show partner tenant access link infos", component: LogComponents.permission)
            return false
        }
        guard publicPermissionMeta.linkShareEntityV2 != .close else {
            DocsLogger.info("searchSettingEnable: share link is closed", component: LogComponents.permission)
            return false
        }
        return true
    }

    /// 是否支持密码分享，需要根据文档/文件夹的FG来判断
    /// 同时需要判断该租户是否允许对外分享
    var shareWithPasswordEnable: Bool {
        let folderEnable = (SettingConfig.shareWithPasswordConfig?.folderEnable == true)
        let docEnable = (SettingConfig.shareWithPasswordConfig?.docEnable == true)
        if shareEntity.isFolder && !folderEnable { return false }
        if shareEntity.type.isBizDoc && !docEnable { return false }
        if shareEntity.wikiV2SingleContainer {
            return wikiV2_showAnyOneCanReadOrEdit
        }
        if shareEntity.isFormV1 || shareEntity.isBitableSubShare { return false }
        return publicPermissionMeta.canShowExternalAccessSwitch
    }

    var numberOfSections: Int {
        // 权限设置
        var count = 1
        // 可搜索设置
        if searchSettingEnable {
            count += 1
        }
        // 密码分享开启，则显示开关密码的section
        if shareEntity.enableShareWithPassWord && shareWithPasswordEnable {
            count += 1
            // 已经有密码了，就显示密码的section
            if hasLinkPassword && !linkPassword.isEmpty {
                count += 1
            }
        }
        return count
    }

    var wikiV2EditLinkInfos: [EditLinkInfo] {
        var linkInfo = toBEditLinkInfos
        if wikiV2_showPartnerTenantCanReadOrEdit {
            linkInfo.append(contentsOf: partnerTenantAccessLinkInfos)
        }
        if wikiV2_showAnyOneCanReadOrEdit {
            linkInfo.append(contentsOf: toBExternalAccessLinkInfos)
        }
        return linkInfo
    }

    private var wikiV2_showAnyOneCanReadOrEdit: Bool {
        //被租户和容器约束，不展示
        let blockType = publicPermissionMeta.blockOptions?.linkShareEntity(with: .anyoneCanRead)
        if !publicPermissionMeta.canShowExternalAccessSwitch || blockType == .containerLimit || blockType == .tenantLimit {
            return false
        }
        return true
    }

    private var wikiV2_showPartnerTenantCanReadOrEdit: Bool {
        //被租户和容器约束，不展示
        let blockType = publicPermissionMeta.blockOptions?.linkShareEntity(with: .partnerTenantCanRead)
        if !canShowPartnerTenantAccessLinkInfos || blockType == .containerLimit || blockType == .tenantLimit {
            return false
        }
        return true
    }
    
    var toBEditLinkInfos: [EditLinkInfo] {
        if fileEntryIsFolder {
            return [
                EditLinkInfo(mainStr: LinkType.Sub.closeLinkDes.text, chosenType: .close),
                EditLinkInfo(mainStr: LinkType.Sub.linkForOrgReadFolderDes.text, chosenType: .orgRead),
                EditLinkInfo(mainStr: LinkType.Sub.linkForOrgEditFolderDes.text, chosenType: .orgEdit)
            ]
        } else {
            return [
                EditLinkInfo(mainStr: LinkType.Sub.closeLinkDes.text, chosenType: .close),
                EditLinkInfo(mainStr: LinkType.Sub.linkForOrgReadDes.text, chosenType: .orgRead),
                EditLinkInfo(mainStr: LinkType.Sub.linkForOrgEditDes.text, chosenType: .orgEdit)
            ]
        }
    }

    var canShowPartnerTenantAccessLinkInfos: Bool {
        guard let adminExternalAccess = publicPermissionMeta.adminExternalAccess else {
                  return false
              }
        let partnerTenantChoices: Set<ShareLinkChoice> = [.partnerRead, .partnerEdit]
        // 当已选中关联组织链接分享选项可展示
        if let pre = previousChoice, partnerTenantChoices.contains(pre) { return true }
        // 没选中时，仅admin为关联组织共享时才展示
        return adminExternalAccess == .partnerTenant
    }

    var partnerTenantAccessLinkInfos: [EditLinkInfo] {
        let partnerReadInfo: EditLinkInfo
        let partnerEditInfo: EditLinkInfo
        if fileEntryIsFolder {
            partnerReadInfo = EditLinkInfo(mainStr: LinkType.Sub.partnerTenantKnownLinkCanReadFolderDes.text, chosenType: .partnerRead)
            partnerEditInfo = EditLinkInfo(mainStr: LinkType.Sub.partnerTenantKnownLinkCanEditDes.text, chosenType: .partnerEdit)
        } else {
            partnerReadInfo = EditLinkInfo(mainStr: LinkType.Sub.partnerTenantKnownLinkCanReadDes.text, chosenType: .partnerRead)
            partnerEditInfo = EditLinkInfo(mainStr: LinkType.Sub.partnerTenantKnownLinkCanEditDes.text, chosenType: .partnerEdit)
        }

        if publicPermissionMeta.adminExternalAccess == .partnerTenant {
            // admin为关联组织共享场景，两个都展示
            return [
                partnerReadInfo,
                partnerEditInfo
            ]
        }
        // 只显示当前选中的选项
        if previousChoice == .partnerRead {
            return [partnerReadInfo]
        } else if previousChoice == .partnerEdit {
            return [partnerEditInfo]
        } else {
            // 都没选中时，不展示这两个选项
            return []
        }
    }

    var toBExternalAccessLinkInfos: [EditLinkInfo] {
        var linkInfos: [EditLinkInfo]
        if fileEntryIsFolder {
            linkInfos = [
                EditLinkInfo(mainStr: LinkType.Sub.anybodyKnownLinkCanReadFolderDes.text,
                             chosenType: .anyoneRead)
            ]
        } else {
            linkInfos = [
                EditLinkInfo(mainStr: LinkType.Sub.anybodyKnownLinkCanReadDes.text,
                             chosenType: .anyoneRead)
            ]
        }
        if isFolder {
            return linkInfos
        }
        linkInfos.append(EditLinkInfo(mainStr: LinkType.Sub.anybodyKnownLinkCanEditDes.text,
                                      chosenType: .anyoneEdit))

        return linkInfos
    }

    var toCEditLinkInfos: [EditLinkInfo] {
        var linkInfos: [EditLinkInfo]
        if fileEntryIsFolder {
            linkInfos = [
                EditLinkInfo(mainStr: LinkType.Sub.closeLinkDes.text,
                             chosenType: .close),
                EditLinkInfo(mainStr: LinkType.Sub.toCAnybodyKnownLinkCanReadFolderDes.text,
                             chosenType: .anyoneRead)
            ]
        } else {
            linkInfos = [
                EditLinkInfo(mainStr: LinkType.Sub.closeLinkDes.text,
                             chosenType: .close),
                EditLinkInfo(mainStr: LinkType.Sub.toCAnybodyKnownLinkCanReadDes.text,
                             chosenType: .anyoneRead)
            ]
        }
        /// 文件夹不显示`互联网上任何知道链接的人都可以编辑`
        if isFolder {
            return linkInfos
        }

        linkInfos.append(EditLinkInfo(mainStr: LinkType.Sub.toCAnybodyKnownLinkCanEditDes.text,
                                      chosenType: .anyoneEdit))

        return linkInfos
    }

    var formEditLinkInfos: [EditLinkInfo] {
        var linkInfos: [EditLinkInfo] = [
            EditLinkInfo(mainStr: LinkType.FormSub.onlyInvitedCanWriteDes.text, chosenType: .close),
            EditLinkInfo(mainStr: LinkType.FormSub.orgMemberCanWriteDes.text, chosenType: .orgEdit),
            EditLinkInfo(mainStr: LinkType.FormSub.anybodyKnownLinkCanWriteDes.text, chosenType: .anyoneEdit)
        ]
        if isToC {
            linkInfos.removeAll(where: { $0.chosenType == .orgEdit })
        }
        if !publicPermissionMeta.canShowExternalAccessSwitch {
            linkInfos.removeAll(where: { $0.chosenType == .anyoneEdit })
        }
        return linkInfos
    }
    
    var bitableLinkInfos: [EditLinkInfo] {
        var linkInfos: [EditLinkInfo] = [
            EditLinkInfo(mainStr: LinkType.BitableSub.onlyInvitedPeopleCanView.text, chosenType: .close),
            EditLinkInfo(mainStr: LinkType.BitableSub.peopleWithLinkInTheOrgCanView.text, chosenType: .orgRead),
            EditLinkInfo(mainStr: LinkType.BitableSub.peopleWithLinkOnTheInternetCanView.text, chosenType: .anyoneRead)
        ]
        if shareEntity.bitableShareEntity?.meta?.constraintExternal == true {
            // Remove this option if external sharing is disabled
            linkInfos.removeAll(where: { $0.chosenType == .anyoneRead })
        }
        return linkInfos
    }


    /// mina 动态下发 service & privacy URL 解析
     public static let links: (String, String) = {
        if DocsSDK.isInLarkDocsApp {
            guard let docsManagerDelegate = HostAppBridge.shared.call(GetDocsManagerDelegateService()) as? DocsManagerDelegate else {
                DocsLogger.info("no share link toast URL")
                return ("", "")
            }
            let serviceSite = docsManagerDelegate.serviceTermURL
            let privacySite = docsManagerDelegate.privacyURL
            return (serviceSite, privacySite)
        } else {
            guard let config = CCMKeyValue.globalUserDefault.dictionary(forKey: UserDefaultKeys.shareLinkToastURL) else {
                DocsLogger.info("no share link toast URL")
                return ("", "")
            }
            var serviceSite = ""
            var privacySite = ""
            if var serviceURL = config["service_term_url"] as? String {
                serviceSite = "https://" + serviceURL.replacingOccurrences(of: "{lan}", with: DocsSDK.convertedLanguage)
            } else {
                serviceSite = ""
            }
            if var privacyURL = config["privacy_url"] as? String {
                privacySite = "https://" + privacyURL.replacingOccurrences(of: "{lan}", with: DocsSDK.convertedLanguage)
            } else {
                privacySite = ""
            }
            return (serviceSite, privacySite)
        }
     }()

    var enableAnonymousAccess: Bool {
        return currentChoice >= .anyoneRead
    }
}

extension ShareLinkEditViewController {

    // 表单 根据用户是小B/C还是B端以及海内海外版本判断应该显示的文案
    func makeFormToastMessage(selectedData: EditLinkInfo) -> UITextView {
        var msg: String = ""
        //KA
        guard DomainConfig.envInfo.isChinaMainland == true && !ReleaseConfig.isPrivateKA else {
            if publicPermissionMeta.externalAccessEnable == false {
                if selectedData.chosenType == .anyoneRead {
                    if fileEntryIsFolder {
                        msg = BundleI18n.SKResource.Doc_Share_FolderBOverseaAnonymousVisit
                    } else {
                        msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitTips
                    }
                } else {
                    msg = BundleI18n.SKResource.Doc_Permission_AnonymousEditTips
                }
            } else {
                if selectedData.chosenType == .anyoneRead {
                    if fileEntryIsFolder {
                        msg = BundleI18n.SKResource.Doc_Share_FolderBOverseaAnonymousVisit
                    } else {
                        msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitTips
                    }
                } else {
                    msg = BundleI18n.SKResource.Doc_Permission_AnonymousEditTips
                }
            }

            if let formSpecialFieldMessage = makeFormSpecialFieldMessage() {
                msg = formSpecialFieldMessage
            }

            let attritedMsg: NSMutableAttributedString = NSMutableAttributedString(string: msg)
            let paraph = NSMutableParagraphStyle()
            attritedMsg.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSRange(location: 0, length: msg.count))
            attritedMsg.addAttributes([NSAttributedString.Key.paragraphStyle: paraph], range: NSRange(location: 0, length: msg.count))
            toastTextView.attributedText = attritedMsg
            return toastTextView
        }

        if publicPermissionMeta.externalAccessEnable == false && isToC == false {
            if selectedData.chosenType == .anyoneRead {
                if fileEntryIsFolder {
                    msg = BundleI18n.SKResource.Doc_Share_FolderBNoExternalAnonymousVisit(BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
                } else {
                    msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitWithPrivacyTips(BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
                }
            } else {
                if shareEntity.isForm {
                    msg = BundleI18n.SKResource.Bitable_Form_NoticeForFormSharingDesc(lang: nil)
                } else {
                    msg = BundleI18n.SKResource.Doc_Permission_AnonymousEditWithPrivacyTips(BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
                }
            }
        } else {
            if selectedData.chosenType == .anyoneRead {
                if fileEntryIsFolder {
                    msg = BundleI18n.SKResource.Doc_Share_FolderBNoExternalAnonymousVisit(BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
                } else {
                    msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitWithPrivacyTips(BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
                }
            } else {
                if shareEntity.isForm {
                    msg = BundleI18n.SKResource.Bitable_Form_NoticeForFormSharingDesc(lang: nil)
                } else {
                    msg = BundleI18n.SKResource.Doc_Permission_AnonymousEditWithPrivacyTips(BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
                }
            }
        }

        if let formSpecialFieldMessage = makeFormSpecialFieldMessage() {
            msg = formSpecialFieldMessage
        }

        let attritedMsg: NSMutableAttributedString = NSMutableAttributedString(string: msg)
        let paraph = NSMutableParagraphStyle()
        attritedMsg.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSRange(location: 0, length: msg.count))
        attritedMsg.addAttributes([NSAttributedString.Key.paragraphStyle: paraph], range: NSRange(location: 0, length: msg.count))
        toastTextView.attributedText = attritedMsg
        return toastTextView
    }

    func makeFormSpecialFieldMessage() -> String? {
        guard shareEntity.isForm else { return nil }

        let hasUserField = shareEntity.formsCallbackBlocks.formHasUserField()
        let hasAttachmentField = shareEntity.formsCallbackBlocks.formHasAttachmentField()

        if hasUserField {
            if hasAttachmentField {
                return BundleI18n.SKResource.Bitable_Form_AttachmentAndPersonFieldNoticeDesc
            } else {
                return BundleI18n.SKResource.Bitable_Form_PersonFieldNoticeDesc
            }
        } else if hasAttachmentField {
            return BundleI18n.SKResource.Bitable_Form_AttachmentFieldNoticeDesc
        }

        return nil
    }

    // 根据用户是小B/C还是B端以及海内海外版本判断应该显示的文案
    func makeToastMessage(selectedData: EditLinkInfo) -> UITextView {
        var msg: String = ""
        let typeString: String
        if shareEntity.type == .minutes {
            typeString = BundleI18n.SKResource.CreationMobile_Minutes_name
        } else if shareEntity.type == .wikiCatalog {
            typeString = BundleI18n.SKResource.CreationMobile_Common_Page
        } else {
            typeString = BundleI18n.SKResource.CreationMobile_Common_Document
        }
        //海外
        guard DomainConfig.envInfo.isChinaMainland == true && !ReleaseConfig.isPrivateKA else {
            if publicPermissionMeta.externalAccessEnable == false {
                if selectedData.chosenType == .anyoneRead {
                    if fileEntryIsFolder {
                        msg = BundleI18n.SKResource.Doc_Share_FolderBOverseaAnonymousVisit
                    } else {
                        msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitTips_AddVariable(typeString)
                    }
                } else {
                    msg = BundleI18n.SKResource.Doc_Permission_AnonymousEditTips_AddVariable(typeString)
                }
            } else {
                if selectedData.chosenType == .anyoneRead {
                    if fileEntryIsFolder {
                        msg = BundleI18n.SKResource.Doc_Share_FolderBOverseaAnonymousVisit
                    } else {
                        msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitTips_AddVariable(typeString)
                    }
                } else {
                    msg = BundleI18n.SKResource.Doc_Permission_AnonymousEditTips_AddVariable(typeString)
                }
            }
            let attritedMsg: NSMutableAttributedString = NSMutableAttributedString(string: msg)
            let paraph = NSMutableParagraphStyle()
            attritedMsg.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSRange(location: 0, length: msg.count))
            attritedMsg.addAttributes([NSAttributedString.Key.paragraphStyle: paraph], range: NSRange(location: 0, length: msg.count))
            toastTextView.attributedText = attritedMsg
            return toastTextView
        }
        //国内
        if publicPermissionMeta.externalAccessEnable == false && isToC == false {
            if selectedData.chosenType == .anyoneRead {
                if fileEntryIsFolder {
                    msg = BundleI18n.SKResource.Doc_Share_FolderBNoExternalAnonymousVisit(BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
                } else {
                    msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitWithPrivacyTips_AddVariable(typeString,
                                                                                                         BundleI18n.SKResource.Doc_Share_ServiceTerm(),
                                                                                                         BundleI18n.SKResource.Doc_Share_Privacy)
                }
            } else {
                msg = BundleI18n.SKResource.Doc_Permission_AnonymousEditWithPrivacyTips_AddVariable(typeString, BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
            }
        } else {
            if selectedData.chosenType == .anyoneRead {
                if fileEntryIsFolder {
                    msg = BundleI18n.SKResource.Doc_Share_FolderBNoExternalAnonymousVisit(BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
                } else {
                    msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitWithPrivacyTips_AddVariable(typeString,
                                                                                                         BundleI18n.SKResource.Doc_Share_ServiceTerm(),
                                                                                                         BundleI18n.SKResource.Doc_Share_Privacy)
                }
            } else {
                msg = BundleI18n.SKResource.Doc_Permission_AnonymousEditWithPrivacyTips_AddVariable(typeString, BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
            }
        }
        // 向文本中插入超链接
        let attritedMsg: NSMutableAttributedString = NSMutableAttributedString(string: msg)
        let paraph = NSMutableParagraphStyle()
        attritedMsg.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSRange(location: 0, length: msg.count))
        attritedMsg.addAttributes([NSAttributedString.Key.paragraphStyle: paraph], range: NSRange(location: 0, length: msg.count))
        guard let serviceRange = msg.range(of: BundleI18n.SKResource.Doc_Share_ServiceTerm()), let privacyRange = msg.range(of: BundleI18n.SKResource.Doc_Share_Privacy) else {
            toastTextView.attributedText = attritedMsg
            return toastTextView
        }
        attritedMsg.addAttributes([NSAttributedString.Key.link: Self.links.0], range: msg.nsrange(fromRange: serviceRange))
        attritedMsg.addAttributes([NSAttributedString.Key.link: Self.links.1], range: msg.nsrange(fromRange: privacyRange))
        toastTextView.attributedText = attritedMsg
        return toastTextView
    }
}

public extension String {
    func nsrange(fromRange range: Range<String.Index>) -> NSRange {
        return NSRange(range, in: self)
    }
}

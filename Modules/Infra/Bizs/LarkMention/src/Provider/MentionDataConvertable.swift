//
//  MentionDataConvertable.swift
//  LarkMention
//
//  Created by Yuri on 2022/6/1.
//

import UIKit
import Foundation
import LarkSDKInterface
import RustPB
import LarkExtensions
import LarkRichTextCore

protocol MentionDataConvertable: AnyObject {
    /// 显示所有者 (默认显示更新时间)
    var showDocumentOwner: Bool { get set }
    var showChatterMail: Bool { get set }
    var currentTenantId: String { get }
    
    func convert(result: SearchResultType) -> PickerOptionType
    func convert(results: [SearchResultType]) -> [PickerOptionType]
}

extension MentionDataConvertable {
    func convert(result: SearchResultType) -> PickerOptionType {
        var option = PickerOption()
        option.name = result.title
        option.tags = convert(tags: result.tags)
        switch result.type {
        case .chatter:
            option.type = .chatter
            option.desc = result.summary
            option.subTitle = result.extra
            if case .chatter(let meta) = result.meta {
                if showChatterMail {
                    option.subTitle = NSAttributedString(string: mailStyleChange(mail: meta.mailAddress))
                }
                if meta.tenantID != currentTenantId {
                    option.tags?.append(.external)
                }
            }
        case .chat:
            option.type = .chat
            if case .chat(let meta) = result.meta {
                if meta.isCrossTenant {
                    if meta.isCrossWithKa {
                        option.tags?.append(.connect)
                    } else {
                        option.tags?.append(.external)
                    }
                }
                if meta.isPublicV2 {
                    option.tags?.append(.public)
                }
                if meta.isDepartment {
                    option.tags?.append(.team)
                }
                if meta.isOfficialOncall {
                    option.tags?.append(.officialOncall)
                }
                if meta.isTenant {
                    option.tags?.append(.allStaff)
                }
            }
        case .doc:
            option.type = .document
            if case .doc(let meta) = result.meta {
                if showDocumentOwner {
                    option.desc = NSAttributedString(string: BundleI18n.LarkMention.Lark_Mention_Owner_Mobile(meta.ownerName))
                } else {
                    var updateTime = Date.lf.getNiceDateString(TimeInterval(meta.updateTime))
                    updateTime = BundleI18n.LarkMention.Lark_Mention_LastModified_Mobile(updateTime)
                    option.desc = NSAttributedString(string: updateTime)
                }
                
                let image = LarkRichTextCoreUtils.docIcon(docType: meta.type, fileName: result.title.string)
                let mentionMetaDoc = MentionMetaDocType(image: image, docType: meta.type, url: meta.url)
                option.meta = .doc(mentionMetaDoc)

                if meta.isCrossTenant {
                    option.tags?.append(.external)
                }
                
            }
        case .wiki:
            option.type = .wiki
            if case .wiki(let meta) = result.meta {
                if showDocumentOwner {
                    option.desc = NSAttributedString(string: BundleI18n.LarkMention.Lark_Mention_Owner_Mobile(meta.ownerName))
                } else {
                    var updateTime = Date.lf.getNiceDateString(TimeInterval(meta.updateTime))
                    updateTime = BundleI18n.LarkMention.Lark_Mention_LastModified_Mobile(updateTime)
                    option.desc = NSAttributedString(string: updateTime)
                }
                let image = LarkRichTextCoreUtils.wikiIcon(docType: meta.type, fileName: result.title.string)
                let mentionMetaDoc = MentionMetaDocType(image: image, docType: meta.type, url: meta.url)
                option.meta = .wiki(mentionMetaDoc)
                
                if meta.isCrossTenant {
                    option.tags?.append(.external)
                }
            }
        default:
            option.type = .unknown
        }
        option.avatarID = result.avatarID
        option.avatarKey = result.avatarKey
        return option
    }
    
    func convert(results: [SearchResultType]) -> [PickerOptionType] {
        return results.compactMap { [weak self] in
            self?.convert(result: $0)
        }
    }
    
    private func convert(tags: [Basic_V1_Tag]) -> [PickerOptionTagType] {
        return tags.compactMap {
            switch $0 {
            case .onCall: return .oncall
            @unknown default: return nil
            }
        }
    }
    
    private func mailStyleChange(mail: String) -> String {
        if !mail.isEmpty {
            return ("<" + mail + ">")
        }
        return mail
    }
}

//
//  IMMentionDataConvertable.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/25.
//
import UIKit
import Foundation
import RustPB
import LarkSDKInterface
import LarkExtensions
import LarkRichTextCore

protocol IMMentionDataConvertable: AnyObject {
//    /// 显示所有者 (默认显示更新时间)
//    var showDocumentOwner: Bool { get set }
//    var showChatterMail: Bool { get set }
    
    func convert(result: SearchResultType) -> IMMentionOptionType
    func convert(results: [SearchResultType]) -> [IMMentionOptionType]
}

extension IMMentionDataConvertable {
    
    func convert(result: SearchResultType) -> IMMentionOptionType {
        var option = IMPickerOption()
        option.id = result.id
        option.name = result.title
        option.tags = convert(tags: result.tags)
        switch result.type {
        case .bot:
            option.type = .chatter
            option.subTitle = result.extra
            option.tags?.append(.robot)
            if case .chatter(let meta) = result.meta {
                option.isInChat = meta.isInChat
                option.desc = NSAttributedString(string: meta.description_p)
                option.tagData = meta.relationTag.toBasicTagData()
            }
        case .chatter:
            option.type = .chatter
            option.subTitle = result.extra
            if case .chatter(let meta) = result.meta {
                option.desc = NSAttributedString(string: meta.description_p)
                option.focusStatus = meta.customStatus
                option.tagData = meta.relationTag.toBasicTagData()
            }
        case .doc:
            option.type = .document
            if case .doc(let meta) = result.meta {
                option.desc = NSAttributedString(string: (BundleI18n.LarkIMMention.Lark_IM_SearchForMembersOrDocs_OwnerOfDocs_Text(meta.ownerName)))
                
                let image = LarkRichTextCoreUtils.docIcon(docType: meta.type, fileName: result.title.string)
                option.meta = .doc(IMMentionMetaDocType(image: image, url: meta.url, type: meta.type))
                option.tagData = meta.relationTag.toBasicTagData()
            }
        case .wiki:
            option.type = .wiki
            if case .wiki(let meta) = result.meta {
                option.desc = NSAttributedString(string: BundleI18n.LarkIMMention.Lark_IM_SearchForMembersOrDocs_OwnerOfDocs_Text(meta.ownerName))
                let image = LarkRichTextCoreUtils.wikiIcon(docType: meta.type, fileName: result.title.string)
                option.meta = .wiki(IMMentionMetaDocType(image: image, url: meta.url, type: meta.type))
                option.tagData = meta.relationTag.toBasicTagData()
            }
        default:
            option.type = .unknown
        }
        option.avatarID = result.avatarID
        option.avatarKey = result.avatarKey
        return option
    }
    
    func convert(results: [SearchResultType]) -> [IMMentionOptionType] {
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
}

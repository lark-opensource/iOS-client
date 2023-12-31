//
//  AtInfoContent.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/12/13.
//  


import UIKit
import LarkBaseKeyboard
import RustPB
import LarkDocsIcon

struct AtInfoContent {
    let type: Int
    let href: String
    let token: String
    let content: String // 用于显示的内容
    var range: NSRange?
    
    static var empty: AtInfoContent {
        AtInfoContent(type: 0, href: "", token: "", content: "")
    }
    
    mutating func update(range: NSRange) {
        self.range = range
    }
}



extension LarkDocsIcon.CCMDocsType {
    var pbType: RustPB.Basic_V1_Doc.TypeEnum {
        var pbType = RustPB.Basic_V1_Doc.TypeEnum.docx
        switch self {
        case .folder:        pbType = .folder
        case .doc:           pbType = .doc
        case .sheet:         pbType = .sheet
        case .myFolder:      pbType = .folder
        case .bitable:       pbType = .bitable
        case .baseAdd:       pbType = .bitable
        case .mindnote:      pbType = .mindnote
        case .file:          pbType = .file
        case .slides:        pbType = .slides
        case .wiki:          pbType = .wiki
        case .docX:          pbType = .docx
        case .sync:          pbType = .docxSyncedBlock
        case .wikiCatalog:   pbType = .wiki
        case .mediaFile:     pbType = .file
        case .imMsgFile:     pbType = .file
        default:
            pbType = .docx
        }
        return pbType
    }
}

extension AtInfoContent {
    
    func toDocsLinkAttr(attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        guard let url = URL(string: href) else { return  .init(string: "")}
        let ccmDocType = LarkDocsIcon.CCMDocsType(rawValue: self.type)
        let content: LinkTransformer.DocInsertContent = (content, ccmDocType.pbType, url, "")
        return LinkTransformer.transformToDocAttr(content, attributes: attributes)
    }
}

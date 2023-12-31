//
//  DocHandler+Delegate.swift
//  CCMMod
//
//  Created by huangzhikai on 2023/8/29.
//

import Foundation
import LarkModel
import SKFoundation

class SendDocsPickDelegate: SearchPickerDelegate {
    
    var sendDocBlock: SendDocBlock
    public init(sendDocBlock: @escaping SendDocBlock) {
        self.sendDocBlock = sendDocBlock
    }
    
    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        guard items.first != nil else {
            DocsLogger.error("send doc picker did finish without item")
            return false
        }
        var sendModelArr: [SendDocModel] = []
        for item in items {
            switch item.meta {
            case .doc(let meta):
                guard let docMeta = meta.meta else {
                    break
                }
                let sendModel = SendDocModel(id: docMeta.id, title: meta.title ?? "", ownerID: "", ownerName: "", url: docMeta.url, docType: docMeta.type, updateTime: 0, titleHitTerms: [], isCrossTenant: false, wikiSubType: docMeta.type, sendDocModelCanSelectType: .optionalType)
                sendModelArr.append(sendModel)
                break
            case .wiki(let meta):
                guard let wikiMeta = meta.meta else {
                    break
                }
                let sendModel = SendDocModel(id: wikiMeta.id, title: meta.title ?? "", ownerID: "", ownerName: "", url: wikiMeta.url, docType: wikiMeta.type, updateTime: 0, titleHitTerms: [], isCrossTenant: false, wikiSubType: wikiMeta.type, sendDocModelCanSelectType: .optionalType)
                sendModelArr.append(sendModel)
                break
            default:
                break
            }
            
        }
        self.sendDocBlock(true, sendModelArr)
        return true
    }
    
}

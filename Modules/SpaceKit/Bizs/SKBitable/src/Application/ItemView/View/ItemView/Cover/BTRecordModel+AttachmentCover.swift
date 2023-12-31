//
//  BTRecordModel+AttachmentCover.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/8/12.
//

import Foundation
import SKFoundation

extension BTRecordModel {
    var allAttachmentFields: [BTFieldModel] {
        var attachments = [BTFieldModel]()
        for field in originalFields {
            guard field.isAttachment else {
                continue
            }
            attachments.append(field)
        }
        return attachments
    }

    var currentCoverAttachmentField: BTFieldModel? {
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return nil
        }
        if viewMode == .submit || viewMode == .addRecord {
            return nil
        }
        for field in allAttachmentFields {
            guard field.fieldID == cardCoverId else {
                continue
            }
            return field
        }
        return nil
    }

    func attachmentCoverChanged(_ oldRecord: BTRecordModel?) -> Bool {
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return false
        }
        guard let oldRecord = oldRecord else {
            return false
        }
        let oldFieldIds = oldRecord.allAttachmentFields.map { $0.fieldID }.toJSONString() ?? ""
        let newFieldIds = allAttachmentFields.map { $0.fieldID }.toJSONString() ?? ""
        let oldEnableCover = oldRecord.coverChangeAble
        let newEnableCover = coverChangeAble
        let oldCoverId = oldRecord.cardCoverId
        let newCoverId = cardCoverId
        return oldFieldIds != newFieldIds || oldEnableCover != newEnableCover || oldCoverId != newCoverId
    }

    func shouldShowAttachmentCoverField() -> Bool {
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return false
        }
        return currentCoverAttachmentField != nil
    }
    
    func createAttachmentCoverFieldModelIfNeeded() -> BTFieldModel? {
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return nil
        }
        guard let field = currentCoverAttachmentField else {
            return nil
        }
        var attachmentCoverModel = BTFieldModel(recordID: recordID)
        attachmentCoverModel.updating(elementType: .attachmentCover)
        var attachments = field.attachmentValue
        for (idx, attachment) in attachments.enumerated() {
            var realAttachment = attachment
            realAttachment.isAttachmentCover = true
            attachments[idx] = realAttachment
        }
        attachmentCoverModel.update(attachmentValue: attachments)
        attachmentCoverModel.update(formTitle: field.name)
        return attachmentCoverModel
    }
}

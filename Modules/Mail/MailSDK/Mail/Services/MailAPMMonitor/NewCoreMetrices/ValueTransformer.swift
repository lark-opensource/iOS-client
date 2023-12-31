//
//  ValueTransformer.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/5/21.
//

import Foundation

extension NewCoreEvent {
    static func labelTransfor(labelId: String, allLabels: [MailFilterLabelCellModel]) -> String {
        if let cellModel = allLabels.first(where: { model in
            return model.labelId == labelId
        }) {
            switch cellModel.labelId {
            case Mail_LabelId_Important,
                 Mail_LabelId_Other,
                 Mail_LabelId_Inbox,
                 Mail_LabelId_FLAGGED,
                 Mail_LabelId_Draft,
                 Mail_LabelId_Sent,
                 Mail_LabelId_Outbox,
                 Mail_LabelId_Scheduled,
                 Mail_LabelId_Archived,
                 Mail_LabelId_Spam,
                 Mail_LabelId_SEARCH,
                 Mail_LabelId_Trash,
                 "FORWARD_CARD":
                return labelId
            default:
                if !cellModel.isSystem {
                    if cellModel.tagType == .label {
                        return "LABEL"
                    } else if cellModel.tagType == .folder {
                        return "FOLDER"
                    }
                } else {
                    assert(false)
                    return Mail_LabelId_Inbox
                }
            }
        } else {
//            assert(false)
            return labelId
        }
        return labelId
    }
}

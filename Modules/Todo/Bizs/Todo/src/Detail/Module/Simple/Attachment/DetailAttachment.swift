//
//  DetailAttachment.swift
//  Todo
//
//  Created by baiyantao on 2023/1/3.
//

import Foundation
import LKCommonsLogging
import LarkRichTextCore

struct DetailAttachment { }

// MARK: - 常量

extension DetailAttachment {
    static let emptyViewHeight: CGFloat = 48

    static let cellHeight: CGFloat = 76
    static let bottomSpace: CGFloat = 8
    static let headerHeight: CGFloat = 46

    static let footerItemHeight: CGFloat = 36
    static let footerBottomOffset: CGFloat = 6

    static let TaskLimit = 500
    static let CommentLimit = 12

    static let foldCount = 3
}

// MARK: - Logger

extension DetailAttachment {
    static let logger = Logger.log(DetailAttachment.self, category: "Todo.DetailAttachment")
}

// MARK: - Utils

extension DetailAttachment {
    static func attachments2CellDatas(
        _ attachments: [Rust.Attachment],
        canDelete: Bool? = nil
    ) -> [DetailAttachmentContentCellData] {
        return attachments.map { attachment in
            let coverSize = CGSize(width: 36, height: 36)
            let cellData = DetailAttachmentContentCellData(
                source: .rust(attachment: attachment),
                coverImage: LarkRichTextCoreUtils.fileIconColorful(with: attachment.name, size: coverSize),
                nameText: attachment.name,
                sizeText: DetailAttachment.getSizeText(strVal: attachment.fileSize),
                uploadState: .idle,
                canDelete: canDelete ?? attachment.canDelete
            )
            return cellData
        }
    }

    static func infos2CellDatas(_ infos: [AttachmentInfo]) -> [DetailAttachmentContentCellData] {
        return infos.map { info in
            let coverSize = CGSize(width: 36, height: 36)
            var cellData = DetailAttachmentContentCellData(
                source: .attachmentService(info: info),
                coverImage: LarkRichTextCoreUtils.fileIconColorful(with: info.fileInfo.name, size: coverSize),
                nameText: info.fileInfo.name,
                canDelete: true
            )

            let totalSizeText = DetailAttachment.getSizeText(intVal: info.fileInfo.size)
            switch info.uploadInfo.uploadStatus {
            case .uploading:
                let progress = info.uploadInfo.progress ?? 0
                cellData.uploadState = .inProgress(CGFloat(progress))
                let finishedSize = Float(info.fileInfo.size ?? 0) * progress
                let finishedSizeText: String
                if finishedSize.isInfinite || finishedSize.isNaN || finishedSize < 0 {
                    finishedSizeText = String(format: "%.2f B", 0)
                } else {
                    finishedSizeText = DetailAttachment.getSizeText(intVal: UInt(finishedSize))
                }
                cellData.sizeText = "\(finishedSizeText) / \(totalSizeText)"
            case .failed:
                cellData.uploadState = .failed
                cellData.sizeText = I18N.Todo_TaskAttachment_UnableToUpload_Label
            case .success, .cancel:
                cellData.uploadState = .idle
                cellData.sizeText = totalSizeText
            }
            return cellData
        }
    }

    static func infos2Attachments(_ infos: [AttachmentInfo]) -> [Rust.Attachment] {
        return infos.compactMap { info in
            guard let fileToken = info.uploadInfo.fileToken else {
                return nil
            }
            var attachment = Rust.Attachment()
            attachment.guid = info.uploadInfo.guid
            attachment.fileToken = fileToken
            attachment.name = info.fileInfo.name
            attachment.fileSize = "\(info.fileInfo.size ?? 0)"
            attachment.canDelete = true
            attachment.type = .file
            attachment.uploadMilliTime = info.fileInfo.uploadTime
            return attachment
        }
    }

    static func getSizeText(strVal: String?) -> String {
        guard let strVal = strVal, let intVal = Int64(strVal) else {
            return String(format: "%.2f B", 0)
        }
        return sizeStringFromSize(intVal)
    }

    static func getSizeText(intVal: UInt?) -> String {
        guard let intVal = intVal else {
            return String(format: "%.2f B", 0)
        }
        return sizeStringFromSize(Int64(intVal))
    }

    private static func sizeStringFromSize(_ size: Int64) -> String {
        let tokens = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]

        var size: Float = Float(size)
        var mulitiplyFactor = 0
        while size > 1_024 {
            size /= 1_024
            mulitiplyFactor += 1
        }
        if mulitiplyFactor < tokens.count {
            return deleteLastZero(str: String(format: "%.2f", size)) + " " + tokens[mulitiplyFactor]
        }
        return deleteLastZero(str: String(format: "%.2f", size))
    }

    private static func deleteLastZero(str: String) -> String {
        let splitStrs = str.split(separator: ".")
        // 如果没有小数位/入参str不合理，不进行处理
        if splitStrs.count != 2 { return str }

        var folatStr = splitStrs[1]
        // 去掉folatStr末尾的0，folatStr全为0则folatStr会变为""
        while !folatStr.isEmpty, folatStr.last == "0" {
            folatStr.removeLast()
        }

        // 如果folatStr变为空，则说明小数位全为0，则只需要展示整数部分
        if folatStr.isEmpty { return String(splitStrs[0]) }

        return splitStrs[0] + "." + folatStr
    }
}

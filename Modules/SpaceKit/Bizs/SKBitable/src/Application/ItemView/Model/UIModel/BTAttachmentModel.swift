//
//  BTAttachmentFieldModel.swift
//  DocsSDK
//
//  Created by linxin on 2020/3/17.
//  


import UIKit
import SKInfra
import HandyJSON
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import LarkDocsIcon

/// 附件信息，对应前端的 `IAttachmentInfo`
struct BTAttachmentModel: HandyJSON, Equatable, SKFastDecodable {
    var attachmentToken: String = ""
    var id: String = ""
    var mimeType: String = ""
    var name: String = "" // 根据这个的后缀决定文件类型
    var size: Int = 0
    var timeStamp: Double = 0.0
    var width: Int?
    var height: Int?
    var category: Int = 0 // 我们不关心这个值，只需要透传给前端
    var mountPointType: String = ""
    var mountToken: String = ""
    var extra: String = "" // 我们不关心这个值，只需要透传给 drive

    // native 逻辑字段，不是前端传进来的
    var isAttachmentCover: Bool = false

    var fileType: DriveFileType { DriveFileType(fileExtension: SKFilePath.getFileExtension(from: name)) }
    var iconImage: UIImage { fileType.squareImage ?? UDIcon.getIconByKey(.fileUnknowColorful, size: CGSize(width: 48, height: 48)) }
    var backgroundColor: UIColor { fileType.imageColor.background }
    var prefersThumbnail: Bool {
        fileType.isImage || fileType.isVideo || fileType.isWord || fileType.isExcel || fileType.isPPT || fileType.isPDF
            || [.aep, .ai, .psd, .sketch].contains(fileType)
    }

    static func ==(lhs: BTAttachmentModel, rhs: BTAttachmentModel) -> Bool {
        guard lhs.attachmentToken == rhs.attachmentToken else {
            return false
        }
        guard lhs.id == rhs.id else {
            return false
        }
        guard lhs.mimeType == rhs.mimeType else {
            return false
        }
        guard lhs.name == rhs.name else {
            return false
        }
        guard lhs.size == rhs.size else {
            return false
        }
        guard lhs.timeStamp == rhs.timeStamp else {
            return false
        }
        guard lhs.width == rhs.width else {
            return false
        }
        guard lhs.height == rhs.height else {
            return false
        }
        guard lhs.category == rhs.category else {
            return false
        }
        guard lhs.mountPointType == rhs.mountPointType else {
            return false
        }
        guard lhs.mountToken == rhs.mountToken else {
            return false
        }
        if !lhs.isAttachmentCover || !rhs.isAttachmentCover {
            /*
             1. extra 里面有递增的 base 级别的快照版本数据，会导致其他字段的变化，也触发附件的刷新
             2. 附件数据如果要变化，需要经历一次删除和添加，本身附件其他字段就会变化，这里应该不需要判断 extra 的相等
             3. 而且客户端的 extra 字段仅透传，如果有需要触发客户端更新的场景，应该另开个客户端需要感知的字段比较合理
             4. 控制影响范围仅对封面不判断 extra，这里后面可以是个优化点
             */
            guard lhs.extra == rhs.extra else {
                return false
            }
        }
        return true
    }
    
    static func deserialized(with dictionary: [String: Any]) -> BTAttachmentModel {
        var model = BTAttachmentModel()
        model.attachmentToken <~ (dictionary, "attachmentToken")
        model.id <~ (dictionary, "id")
        model.mimeType <~ (dictionary, "mimeType")
        model.name <~ (dictionary, "name")
        model.size <~ (dictionary, "size")
        model.timeStamp <~ (dictionary, "timeStamp")
        model.width <~ (dictionary, "width")
        model.height <~ (dictionary, "height")
        model.category <~ (dictionary, "category")
        model.mountPointType <~ (dictionary, "mountPointType")
        model.mountToken <~ (dictionary, "mountToken")
        model.extra <~ (dictionary, "extra")
        return model
    }
}

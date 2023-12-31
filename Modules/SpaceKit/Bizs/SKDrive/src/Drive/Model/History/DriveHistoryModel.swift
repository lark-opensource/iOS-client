//
//  DriveHistoryModel.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/4/12.
//

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignIcon
import LarkDocsIcon

/// History record model
struct DriveHistoryRecordModel: Codable {

    /// Action type
    enum RecordType: Int {
        case uploadNew = 1
        case rename
        case delete
        case recover

        var tag: String? {
            switch self {
            case .delete: return BundleI18n.SKResource.Drive_Drive_HistoryRecordDeleted
            default: return nil
            }
        }
    }

    var version: String?
    var isDeleted: Bool = false
    var type: Int?
    var name: String?
    var size: UInt64?
    var tag: Int?
    var sourceTag: Int?
    var editUserId: String?
    var editTime: Int64?
    var dataVersion: String?
    var sourceVersion: String?
    var sourceName: String?
    var cipherDelete: Bool?

    private enum CodingKeys: String, CodingKey {
        case version
        case isDeleted          = "is_deleted"
        case type
        case name
        case size
        case tag
        case sourceTag          = "source_tag"
        case editUserId         = "edit_uid"
        case editTime           = "edit_time"
        case dataVersion        = "data_version"
        case sourceVersion      = "source_version"
        case sourceName         = "source_name"
        case cipherDelete       = "cipher_delete"
    }

    init(dataDic: [String: Any]) {
        self.version = dataDic["version"] as? String
        self.isDeleted = (dataDic["is_deleted"] as? Bool) ?? false
        self.type = dataDic["type"] as? Int
        self.name = dataDic["name"] as? String
        self.size = dataDic["size"] as? UInt64
        self.tag = dataDic["tag"] as? Int
        self.sourceTag = dataDic["source_tag"] as? Int
        self.editUserId = dataDic["edit_uid"] as? String
        self.editTime = dataDic["edit_time"] as? Int64
        self.dataVersion = dataDic["data_version"] as? String
        self.sourceVersion = dataDic["source_version"] as? String
        self.sourceName = dataDic["source_name"] as? String
        self.cipherDelete = dataDic["cipher_delete"] as? Bool
    }
}

extension DriveHistoryRecordModel {
    var recordType: RecordType? {
        guard let type = type,
            let recordT = RecordType(rawValue: type) else { return nil }
        return recordT
    }

    var fileType: DriveFileType {
        return DriveFileType(fileExtension: fileExtension)
    }

    var fileExtension: String? {
        return SKFilePath.getFileExtension(from: fileName)
    }

    var recordHeight: CGFloat {
        return hideFileContainer ? DriveHistoryVersionTableCell.cellHideFileHeight : DriveHistoryVersionTableCell.cellHeight
    }

    private var isEn: Bool {
        return DocsSDK.currentLanguage == .en_US
    }
}

// MARK: - DriveHistoryTableCellPresenter
extension DriveHistoryRecordModel: DriveHistoryTableCellPresenter {
    var userName: String {
        guard let userID = editUserId,
            let userDic = DriveActivityViewModel.userInfoDic[userID] else { return "" }
        let userInfo = UserInfo(userID)
        userInfo.updatePropertiesFrom(JSON(userDic))
        return userInfo.nameForDisplay()
    }

    var timeStamp: String {
        guard let time = editTime else { return "" }
        return Double(time / 1000).stampDateFormatter
    }

    var recordWords: String {
        guard let recordType = recordType else { return "" }
        switch recordType {
        case .uploadNew:
            var tagDesc = ""
            if let tag = tag {
                tagDesc = "\(tag)"
                if tag == 1 { return BundleI18n.SKResource.Drive_Drive_HistoryRecordUploadNewVersion(tagDesc) }
            }
            return BundleI18n.SKResource.Drive_Drive_HistoryRecordUploadedTag(tagDesc)
        case .rename:
            var tagDesc = ""
            if let sourceTag = sourceTag {
                tagDesc = "\(sourceTag)"
            }
            return BundleI18n.SKResource.Drive_Drive_HistoryRecordRename(tagDesc, fileName)
        case .delete:
            var tagDesc = ""
            if let sourceTag = sourceTag {
                tagDesc = "\(sourceTag)"
            }
            return BundleI18n.SKResource.Drive_Drive_HistoryRecordDeleteVersion(tagDesc, fileName)
        case .recover:
            if let tag = tag, let sourceTag = sourceTag {
                let newtag = "\(tag)"
                let oldTag = "\(sourceTag)"
                return BundleI18n.SKResource.Drive_Drive_HistoryRecordRevertVersion(newtag, oldTag)
            } else {
                DocsLogger.error("sourceTag and tag is nil")
            }
            return ""
        }
    }

    var iconImage: UIImage? {
        if let keyDeleted = cipherDelete, keyDeleted {
            // 密钥删除无法获取文件类型，展示统一删除样式icon
            return UDIcon.getIconByKey(.fileRoundUnknowColorful, size: CGSize(width: 48, height: 48))
        }
        return fileType.roundImage
    }

    var fileName: String {
        if let keyDeleted = cipherDelete, keyDeleted {
            // 文档密钥删除展示统一文案
            return BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidTitle
        }
        if recordType == .delete {
            return sourceName ?? ""
        }
        return name ?? ""
    }

    var canSelected: Bool {
        if let keyDeleted = cipherDelete, keyDeleted { return false }
        guard let recordType = recordType, !isDeleted else { return false }
        return recordType == .uploadNew || recordType == .recover
    }

    var showDeletedStyle: Bool {
        return isDeleted || recordType == .delete
    }

    var hideFileContainer: Bool {
        return recordType == .delete || recordType == .rename
    }

    var tagString: String? {
        if isDeleted || recordType == .delete {
            return BundleI18n.SKResource.Drive_Drive_HistoryRecordDeleted
        }
        return nil
    }
}

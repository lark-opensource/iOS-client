//
//  DriveEntry.swift
//  SKCommon
//
//  Created by guoqp on 2020/9/8.
//

import Foundation
import UniverseDesignIcon
import SKFoundation
import SpaceInterface
import SKInfra
import LarkDocsIcon

public protocol DriveEntryProtocol {
    var copiable: Bool? { get }
    var fileType: String? { get }
    var driveInfo: DriveEntry.DriveInfo? { get }
    func updateFileType(_ fileType: String?)
}
extension DriveEntryProtocol where Self: SpaceEntry {
    public var copiable: Bool? { return (self as? DriveEntry)?.copiable }
    public var fileType: String? { return (self as? DriveEntry)?.fileType }
    public var driveInfo: DriveEntry.DriveInfo? { return (self as? DriveEntry)?.driveInfo }
    public func updateFileType(_ fileType: String?) { (self as? DriveEntry)?.updateFileType(fileType) }
}

open class DriveEntry: SpaceEntry {
    /// 能否使用其他app打开
    public private(set) var copiable: Bool?
    /// type == .file 时，用于定义文件类型
    public private(set) var fileType: String?
    public private(set) var driveInfo: DriveInfo?

    public override var defaultIcon: UIImage {
        if let subType = fileType {
            let driveType = DriveFileType(rawValue: subType) ?? .unknown
            return driveType.roundImage
                ?? UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
        } else {
            return super.defaultIcon
        }
    }

    public override var colorfulIcon: UIImage {
        guard let subType = fileType else {
            return super.colorfulIcon
        }
        let driveType = DriveFileType(rawValue: subType) ?? .unknown
        return driveType.squareImage
            ?? UDIcon.getIconByKey(.fileUnknowColorful, size: CGSize(width: 48, height: 48))
    }

    public override var canOpenWhenOffline: Bool {
        guard secretKeyDelete != true else {
            return false
        }
        guard type.offLineEnable else {
            return false
        }
        let fileExt = SKFilePath.getFileExtension(from: name)
        return DocsContainer.shared.resolve(DriveCacheServiceBase.self)?.canOpenOffline(token: objToken,
                                                                                        dataVersion: nil,
                                                                                        fileExtension: fileExt) ?? false
    }

    public func updateFileType(_ fileType: String?) {
        self.fileType = fileType?.lowercased()
    }

    public override func makeCopy(newNodeToken: String? = nil, newObjToken: String? = nil) -> DriveEntry {
        //swiftlint:disable force_cast
        let another = super.makeCopy(newNodeToken: newNodeToken, newObjToken: newObjToken) as! DriveEntry
        another.copiable = copiable
        another.fileType = fileType
        another.driveInfo = driveInfo
        return another
    }

    public override func equalTo(_ another: SpaceEntry) -> Bool {
        guard let compareEntry = another as? DriveEntry else { return false }
        return super.equalTo(compareEntry) &&
            copiable == compareEntry.copiable &&
            fileType == compareEntry.fileType &&
            driveInfo == compareEntry.driveInfo
    }

    public override var description: String {
        return "DriveEntry - " + super.description
    }
}

extension DriveEntry {
    public struct DriveInfo: Equatable {
        public let iconUrl: String
        public let iconEncrytedTyped: Bool
        public let iconKey: String
        public let iconNonce: String
        public init?(_ dict: [String: Any]) {
            guard let iconUrl = dict["icon"] as? String,
                let encryptedType = dict["icon_encrypted_type"] as? Bool,
                let iconKey = dict["icon_key"] as? String,
                let iconNonce = dict["icon_nonce"] as? String else {
                return nil
            }
            self.iconUrl = iconUrl
            self.iconEncrytedTyped = encryptedType
            self.iconKey = iconKey
            self.iconNonce = iconNonce
        }

        public static func == (lhs: DriveInfo, rhs: DriveInfo) -> Bool {
            return lhs.iconEncrytedTyped == rhs.iconEncrytedTyped &&
                lhs.iconUrl == rhs.iconUrl &&
                lhs.iconKey == rhs.iconKey &&
                lhs.iconNonce == rhs.iconNonce
        }
    }

    public override func updateExtra() {
        super.updateExtra()
        guard let extraDic = extra else { return }
        if let subtype = extraDic["subtype"] as? String {
            fileType = subtype.lowercased()
        }
        copiable = extraDic["copiable"] as? Bool
        driveInfo = DriveInfo(extraDic)
    }
}

private let driveFileSizeKey = "driveFileSizeKey"
extension SpaceEntry {
    /// 手动离线，仅用于drive文件显示文件大小用，
    /// 存在多端协同问题，可能不准，仅用于UI显示，不要用来做逻辑判断
    public var fileSize: UInt64 {
        get { return storedExtensionProperty[driveFileSizeKey] as? UInt64 ?? 0 }
        set { updateStoredExtensionProperty(key: driveFileSizeKey, value: newValue as Any) }
    }
}

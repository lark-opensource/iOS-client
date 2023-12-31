//
//  FolderEntry.swift
//  SKCommon
//
//  Created by guoqp on 2020/9/8.
//

import Foundation
import UniverseDesignIcon
import SpaceInterface

public protocol FolderEntryProtocol {
    var isShareFolder: Bool { get }
    var isOldShareFolder: Bool { get }
    var shareFolderInfo: FolderEntry.ShareFolderInfo? { get }
    var isShareRoot: Bool { get }
}
extension FolderEntryProtocol where Self: SpaceEntry {
    public var isShareFolder: Bool {
        guard let folder = self as? FolderEntry else {
            return false
        }
        return folder.isShareFolder
    }
    public var isOldShareFolder: Bool {
        guard let folder = self as? FolderEntry else {
            return false
        }
        return folder.isOldShareFolder
    }
    public var shareFolderInfo: FolderEntry.ShareFolderInfo? { return (self as? FolderEntry)?.shareFolderInfo }
    public var isShareRoot: Bool {
        guard let folder = self as? FolderEntry else {
            return false
        }
        return folder.isShareRoot()
    }
}

/// type == .folder
open class FolderEntry: SpaceEntry {
    ///旧node结构
    public private(set) var shareFolderInfo: ShareFolderInfo?
    public private(set) var folderType: FolderType = FolderType.unknownDefaultType


    public override var defaultIcon: UIImage {
        if isShareFolder || isShortCut {
            return UDIcon.getIconByKeyNoLimitSize(.fileSharefolderColorful)
        } else {
            return UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
        }
    }

    public override var colorfulIcon: UIImage {
        if isShareFolder || isShortCut {
            return UDIcon.getIconByKey(.fileSharefolderColorful, size: CGSize(width: 48, height: 48))
        } else {
            return UDIcon.getIconByKey(.fileFolderColorful, size: CGSize(width: 48, height: 48))
        }
    }
    
    public override var isShareFolder: Bool {
        return folderType.isShareFolder
    }

    public override var quickAccessImage: UIImage {
        return defaultIcon
    }

    public override var canOpenWhenOffline: Bool {
        guard secretKeyDelete != true else {
            return false
        }
        return type.offLineEnable
    }

    public override func makeCopy(newNodeToken: String? = nil, newObjToken: String? = nil) -> FolderEntry {
        //swiftlint:disable force_cast
        let another = super.makeCopy(newNodeToken: newNodeToken, newObjToken: newObjToken) as! FolderEntry
        another.shareFolderInfo = shareFolderInfo
        another.folderType = folderType
        return another
    }

    public override func equalTo(_ another: SpaceEntry) -> Bool {
        guard let compareEntry = another as? FolderEntry else { return false }
        return super.equalTo(compareEntry) &&
            folderType == compareEntry.folderType &&
            shareFolderInfo == compareEntry.shareFolderInfo &&
            shareVersion == another.shareVersion &&
            isHiddenStatus == another.isHiddenStatus
    }
    public override var description: String {
        return "FolderEntry - " + super.description
    }
}

extension FolderEntry {
    public override func updateExtra() {
        super.updateExtra()
        updateFolderType()
        updateShareFolderInfo()
    }

    private func updateFolderType() {
        let isShared = extra?["is_share_folder"] as? Bool
        folderType = FolderType(ownerType: ownerType, shareVersion: shareVersion, isShared: isShared)
    }
    private func updateShareFolderInfo() {
        guard let extraDic = extra else { return }
        shareFolderInfo = ShareFolderInfo(extraDic)
    }

    public struct ShareFolderInfo: Equatable {
        public var spaceID: String?
        public var shareRoot: Bool?

        public init(_ dict: [String: Any]) {
            self.spaceID = dict["space_id"] as? String
            self.shareRoot = dict["is_share_root"] as? Bool
        }

        public static func == (lhs: ShareFolderInfo, rhs: ShareFolderInfo) -> Bool {
            return lhs.spaceID == rhs.spaceID && lhs.shareRoot == rhs.shareRoot
        }
    }

    public func isShareRoot() -> Bool {
        return shareFolderInfo?.shareRoot ?? false
    }

    public var isOldShareFolder: Bool {
        folderType.isOldShareFolder
    }
    public override func isSupportedType() -> Bool {
        return folderType.isSupportedType && super.isSupportedType()
    }
    public func updateFolderType(_ folderType: FolderType) {
        self.folderType = folderType
    }
}

private let shareVersionKey = "shareVersionKey"
private let hiddenStatusKey = "hiddenStatusKey"
extension SpaceEntry {
    ///共享文件夹 新旧版本
    public var shareVersion: Int? {
        get { return storedExtensionProperty[shareVersionKey] as? Int }
        set { updateStoredExtensionProperty(key: shareVersionKey, value: newValue as Any) }
    }
    /// 共享文件夹显示态、隐藏态
    public var isHiddenStatus: Bool? {
        get { return storedExtensionProperty[hiddenStatusKey] as? Bool ?? false }
        set { updateStoredExtensionProperty(key: hiddenStatusKey, value: newValue as Any) }
    }
}

//
//  CollaboratorFileModel.swift
//  SKCommon
//
//  Created by guoqp on 2022/4/6.
//

import Foundation
import SKFoundation
import SpaceInterface

public final class CollaboratorFileModel {
    private(set) var objToken: String
    private(set) var docsType: ShareDocsType
    private(set) var isOwner: Bool
    private(set) var displayName: String //owner name
    private(set) var ownerID: String
    private(set) var tenantID: String
    private(set) var title: String

    private(set) var createTime: TimeInterval
    private(set) var createDate: String
    private(set) var creatorID: String

    ///允许转移owner
    public var enableTransferOwner: Bool

    private(set) var spaceID: String
    private(set) var folderType: FolderType?

    private(set) var templateMainType: TemplateMainType?
    public var wikiV2SingleContainer: Bool
    public var spaceSingleContainer: Bool

    // form
    private(set) var formMeta: FormShareMeta?
    public var isForm: Bool {
        isFormV1 || isFormV2
    }
    public var notShowUserGroupCell: Bool {
        UserScopeNoChangeFG.WJS.baseFormShareNotificationV2 && isForm
    }
    public var isFormV1: Bool {
        docsType == .form
    }
    public var isFormV2: Bool {
        docsType == .bitableSub(.form)
    }
    public var isBitableSubShare: Bool {
        docsType.isBitableSubType
    }
    private(set) var bitableShareEntity: BitableShareEntity?

    public var isFolder: Bool {
        if folderType != nil {
            return true
        }
        return false
    }

    public var isShareFolder: Bool {
        if let folderType = folderType,
           folderType.isShareFolder {
            return true
        }
        return false
    }

    public var isOldShareFolder: Bool {
        if let folderType = folderType,
           folderType.isOldShareFolder {
            return true
        }
        return false
    }
    public var isCommonFolder: Bool {
        if let folderType = folderType,
           !folderType.isShareFolder {
            return true
        }
        return false
    }

    public var isV2Folder: Bool {
        return isFolder && spaceSingleContainer
    }

    public var isSyncedBlock: Bool {
        return docsType == .sync
    }

    public var isSameTenantWithOwner: Bool {
        return self.tenantID == User.current.info?.tenantID
    }


    public init(objToken: String,
         docsType: ShareDocsType,
         title: String,
         isOWner: Bool,
         ownerID: String,
         displayName: String,
         spaceID: String,
         folderType: FolderType?,
         tenantID: String,
         createTime: TimeInterval,
         createDate: String,
         creatorID: String,
         templateMainType: TemplateMainType? = nil,
         wikiV2SingleContainer: Bool = false,
         spaceSingleContainer: Bool = false,
         enableTransferOwner: Bool,
         bitableShareEntity: BitableShareEntity? = nil,
         formMeta: FormShareMeta?) {
        self.objToken = objToken
        self.formMeta = formMeta
        self.docsType = docsType
        self.title = title
        self.isOwner = isOWner
        self.displayName = displayName
        self.ownerID = ownerID
        self.spaceID = spaceID
        self.tenantID = tenantID
        self.createTime = createTime
        self.createDate = createDate
        self.creatorID = creatorID
        self.folderType = folderType
        self.templateMainType = templateMainType
        self.bitableShareEntity = bitableShareEntity
        self.wikiV2SingleContainer = wikiV2SingleContainer
        self.spaceSingleContainer = spaceSingleContainer
        self.enableTransferOwner = enableTransferOwner
        if docsType == .form {
            spaceAssert(formMeta != nil, "formMeta must not nil while type is form")
        }
        if case .bitableSub = docsType {
            spaceAssert(bitableShareEntity != nil, "bitableShareEntity must not be nil while type is bitableSub")
        }
    }

    public func updateOwnerID(newOwnerID: String) {
        self.ownerID = newOwnerID
    }
}

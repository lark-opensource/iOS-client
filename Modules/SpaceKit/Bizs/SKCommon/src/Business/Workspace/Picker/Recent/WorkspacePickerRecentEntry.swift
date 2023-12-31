//
//  WorkspacePickerRecentEntry.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/9/27.
//

import Foundation
import UniverseDesignIcon
import SKResource
import SpaceInterface
import SKFoundation
import LarkDocsIcon

protocol WorkspacePickerUIRepresentable {
    var displayTitle: String { get }
    var icon: UIImage { get }
    var iconInfo: String? { get }
    var docsType: DocsType { get }
    var container: ContainerInfo? { get }
    var objToken: String { get }
    var subTitle: String? { get }
    var shouldShowExternalTag: Bool { get }
    var isFromMyLibrary: Bool { get }
}

enum WorkspacePickerRecentEntry {
    case wiki(entry: WorkspacePickerWikiEntry)
    case folder(entry: WorkspacePickerSpaceEntry)
}

extension WorkspacePickerRecentEntry: WorkspacePickerUIRepresentable {
    var container: LarkDocsIcon.ContainerInfo? {
        switch self {
        case let .wiki(entry):
            return nil
        case let .folder(entry):
            return entry.container
        }
    }
    
    var iconInfo: String? {
        realEntry.iconInfo
    }
    
    var docsType: SpaceInterface.DocsType {
        realEntry.docsType
    }
    
    var objToken: String {
        realEntry.objToken
    }
    
    private var realEntry: WorkspacePickerUIRepresentable {
        switch self {
        case let .wiki(entry):
            return entry
        case let .folder(entry):
            return entry
        }
    }

    var displayTitle: String {
        realEntry.displayTitle
    }

    var icon: UIImage {
        realEntry.icon
    }

    var subTitle: String? {
        let libraryTitle = UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? BundleI18n.SKResource.LarkCCM_NewCM_Personal_Title : BundleI18n.SKResource.LarkCCM_CM_MyLib_Menu
        return realEntry.isFromMyLibrary ? libraryTitle : realEntry.subTitle
    }

    var shouldShowExternalTag: Bool {
        realEntry.shouldShowExternalTag
    }
    
    var isFromMyLibrary: Bool {
        realEntry.isFromMyLibrary
    }
}

public struct WorkspacePickerWikiEntry: Decodable {
    public let wikiToken: String
    public let spaceID: String
    public let spaceName: String
    public let objToken: String
    private let objTypeValue: Int
    public var objType: DocsType { DocsType(rawValue: objTypeValue) }
    public let title: String
    private let spaceType: SpaceType?
    private let wikiSpaceCreateUid: String?
    public let iconInfo: String?
    
    private enum SpaceType: Int, Codable, Equatable {
        case team     = 0   //团队
        case personal = 1   //个人
        case library  = 2   //文档库
    }
    // 展示的知识库名称
    public var displayName: String {
        if spaceType == .library, wikiSpaceCreateUid == User.current.info?.userID {
            let title = UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? BundleI18n.SKResource.LarkCCM_NewCM_Personal_Title : BundleI18n.SKResource.LarkCCM_CM_MyLib_Menu
            return title
        } else {
            return spaceName
        }
    }

    private enum CodingKeys: String, CodingKey {
        case wikiToken = "wiki_token"
        case spaceID = "space_id"

        case objToken = "obj_token"
        case objTypeValue = "obj_type"

        case title
        case spaceName = "wiki_space_name"
        
        case spaceType = "wiki_space_type"
        case wikiSpaceCreateUid = "wiki_space_create_uid"
        
        case iconInfo = "icon_info"
        
    }
}

extension WorkspacePickerWikiEntry: WorkspacePickerUIRepresentable {
    var container: LarkDocsIcon.ContainerInfo? {
        return nil
    }
    
    var docsType: SpaceInterface.DocsType {
        objType
    }
    
    var displayTitle: String { title.isEmpty ? objType.untitledString : title }
    var icon: UIImage { WikiEntry.wikiListIcon(contentType: objType, name: title) }
    var subTitle: String? { spaceName }
    var shouldShowExternalTag: Bool { false }
    var isFromMyLibrary: Bool {
        spaceType == .library && wikiSpaceCreateUid == User.current.info?.userID
    }
}

public struct WorkspacePickerSpaceEntry {
    public let folderToken: String
    public let folderType: FolderType
    public let name: String
    public let isExternal: Bool
    public let extra: [String: Any]?
    // 不同的 API 会有不同的含义，用新接口时，subTitle 是父文件夹名字，用旧接口时，是最后编辑时间
    public var subTitle: String?
}

extension WorkspacePickerSpaceEntry: WorkspacePickerUIRepresentable {
    var container: LarkDocsIcon.ContainerInfo? {
        return ContainerInfo(isShareFolder: folderType.isShareFolder)
    }
    
    var iconInfo: String? {
        nil
    }
    
    var docsType: SpaceInterface.DocsType {
        .folder
    }
    
    var objToken: String {
        ""
    }
    
    var displayTitle: String { name.isEmpty ? BundleI18n.SKResource.Doc_Facade_UntitledDocument : name }
    var icon: UIImage {
        if folderType.isShareFolder {
            return UDIcon.getIconByKeyNoLimitSize(.fileSharefolderColorful)
        } else {
            return UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
        }
    }
    var shouldShowExternalTag: Bool {
        isExternal
    }
    var isFromMyLibrary: Bool { false }
}

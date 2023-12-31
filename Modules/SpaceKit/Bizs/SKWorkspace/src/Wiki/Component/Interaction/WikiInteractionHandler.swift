//
//  WikiInteractionHandler.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/6/30.
//

import Foundation
import RxSwift
import RxCocoa
import SKResource
import SKCommon
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon
import SwiftyJSON
import SpaceInterface

public final class WikiInteractionHandler {

    let networkAPI: WikiTreeNetworkAPI

    public struct Context {

        public enum SourceLocation: Equatable {
            // 本体在 wiki
            case inWiki(wikiToken: String, spaceID: String)
            // 本体不在 wiki，没有 wikiToken 和 spaceID
            case external
        }

        // 操作对象的 wikiToken，可能与实体 wikiToken 不一致(shortcut场景)
        public let wikiToken: String
        // 操作对象的 spaceID，可能与实体 spaceID 不一致(shortcut场景)
        public let spaceID: String

        public var wikiMeta: WikiMeta {
            WikiMeta(wikiToken: wikiToken, spaceID: spaceID)
        }

        // 实体信息，在 Wiki 或在 Space
        public var sourceLocation: SourceLocation
        // 实体的 objToken
        public let objToken: String
        // 实体的 objType
        public let objType: DocsType
        // 操作对象名字
        public let name: String?
        // 操作对象是shortcut时，本体的名字,非shortcut为nil
        public var originName: String?
        // 操作对象是否是shortcut
        public let isShortcut: Bool
        // 操作对象当前父节点信息
        public var parentWikiToken: String?
        // 是否是操作对象的owner
        public var isOwner: Bool

        public init(wikiToken: String,
                    spaceID: String,
                    sourceLocation: SourceLocation,
                    objToken: String,
                    objType: DocsType,
                    name: String?,
                    isShortcut: Bool,
                    isOwner: Bool,
                    parentWikiToken: String?) {
            self.spaceID = spaceID
            self.wikiToken = wikiToken
            self.sourceLocation = sourceLocation
            self.objToken = objToken
            self.objType = objType
            self.name = name
            self.isShortcut = isShortcut
            self.isOwner = isOwner
            self.parentWikiToken = parentWikiToken
        }

        public init(meta: WikiTreeNodeMeta, parentToken: String? = nil, originName: String? = nil) {
            wikiToken = meta.wikiToken
            spaceID = meta.spaceID
            if meta.originIsExternal {
                sourceLocation = .external
            } else {
                let sourceWikiToken = meta.originWikiToken ?? meta.wikiToken
                let sourceSpaceID = meta.originSpaceID ?? meta.spaceID
                sourceLocation = .inWiki(wikiToken: sourceWikiToken, spaceID: sourceSpaceID)
            }
            objToken = meta.objToken
            objType = meta.objType
            name = meta.displayTitle
            isShortcut = meta.isShortcut
            isOwner = meta.isOwner
            parentWikiToken = parentToken
            self.originName = originName
        }
    }

    // 涉及到新建节点的
    public struct CreateResponse {
        public enum Node: Equatable {
            case space(url: URL)
            case wiki(node: WikiServerNode, url: URL)
        }
        public let node: Node
        public let location: WorkspacePickerLocation
        public let statistic: StatisticResponse
        public var url: URL {
            switch node {
            case let .space(url):
                return url
            case let .wiki(_, url):
                return url
            }
        }
    }

    // 埋点用
    public struct StatisticResponse {
        public let pageToken: String
        public let objToken: String
        public let objType: DocsType
    }

    let disposeBag = DisposeBag()
    public let synergyUUID: String?

    public init(networkAPI: WikiTreeNetworkAPI, synergyUUID: String?) {
        self.networkAPI = networkAPI
        self.synergyUUID = synergyUUID
    }

    public convenience init(synergyUUID: String? = nil) {
        self.init(networkAPI: WikiNetworkManager.shared, synergyUUID: synergyUUID)
    }

    func getNodeInfo(wikiToken: String) -> Single<WikiServerNode> {
        networkAPI.getNodeMetaInfo(wikiToken: wikiToken)
    }

    func fetchPermission(wikiToken: String, spaceID: String) -> Single<WikiTreeNodePermission> {
        networkAPI.getNodePermission(spaceId: spaceID, wikiToken: wikiToken)
    }
}

// MARK: - Copy
extension WikiInteractionHandler {

    public typealias CopyContext = Context

    public enum CopyPickerLocation {
        case currentLocation
        case pick(location: WorkspacePickerLocation)

        public func getTargetSpaceID(currentSpaceID: String) -> String {
            switch self {
            case .currentLocation:
                return currentSpaceID
            case let .pick(location):
                return location.targetSpaceID
            }
        }

        public var targetModule: WorkspacePickerTracker.TargetModule {
            switch self {
            case .currentLocation:
                return .defaultLocation
            case let .pick(location):
                return location.targetModule
            }
        }

        public var targetFolderType: WorkspacePickerTracker.TargetFolderType? {
            switch self {
            case .currentLocation:
                return nil
            case let .pick(location):
                return location.targetFolderType
            }
        }
    }

    public typealias CopyPickerHandler = (UIViewController, CopyPickerLocation) -> Void
    public typealias CopyResponse = CreateResponse

    public func makeCopyPicker(context: CopyContext,
                               triggerLocation: WorkspacePickerTracker.TriggerLocation,
                               allowCopyToSpace: Bool,
                               allowCopyToCurrentLocation: Bool = true,
                               handler: @escaping CopyPickerHandler) -> UIViewController {
        let entranceConfig = PickerEntranceConfig(icon: UDIcon.copyFilled.ud.withTintColor(UDColor.primaryContentDefault),
                                                  title: BundleI18n.SKResource.LarkCCM_NewCM_MakeCopies_Option) { picker in
            handler(picker, .currentLocation)
        }
        let tracker = WorkspacePickerTracker(actionType: .makeCopyTo,
                                             triggerLocation: triggerLocation)
        var config = WorkspacePickerConfig(title: BundleI18n.SKResource.LarkCCM_Wiki_MoveACopyTo_Header_Mob,
                                           action: .copyWiki,
                                           extraEntranceConfig: allowCopyToCurrentLocation ? entranceConfig : nil ,
                                           entrances: .wikiOnly,
                                           ownerTypeChecker: { $0 ? nil : BundleI18n.SKResource.CreationMobile_ECM_UnableDuplicateDocToast },
                                           tracker: tracker) { location, picker in
            handler(picker, .pick(location: location))
        }
        if allowCopyToSpace {
            config.entrances = .wikiAndSpace
        }
        return WorkspacePickerFactory.createWorkspacePicker(config: config)
    }

    // TODO: picker 参数仅为了创建副本时能正确展示容量管理弹窗，DocsCreateDirector 目前强依赖此类型，待后续优化后去掉此实现
    public func confirmCopyTo(location: CopyPickerLocation, context: CopyContext, picker: UIViewController) -> Single<CopyResponse> {
        switch location {
        case .currentLocation:
            return confirmCopyToCurrentLocation(context: context)
        case let .pick(workspaceLocation):
            return confirmCopyTo(location: workspaceLocation, context: context, picker: picker)
        }
    }

    public func confirmCopyToCurrentLocation(context: CopyContext) -> Single<CopyResponse> {
        if let parentWikiToken = context.parentWikiToken, parentWikiToken != WikiTreeNodeMeta.sharedRootToken {
            // copy 到当前位置时，spaceName 和 nodeName 无法保证拿得到，目前只有移动场景需要关注 spaceName，这里暂不处理
            let location = WikiPickerLocation(wikiToken: parentWikiToken,
                                              nodeName: "",
                                              spaceID: context.spaceID,
                                              spaceName: "",
                                              isMylibrary: MyLibrarySpaceIdCache.isMyLibrary(context.spaceID))
            return confirmCopyToWiki(context: context, location: location)
                .map {
                    CopyResponse(node: .wiki(node: $0, url: $1),

                                 location: .wikiNode(location: location),
                                 statistic: $2)
                }
        }
        return getNodeInfo(wikiToken: context.wikiToken).flatMap { [weak self] node in
            guard let self = self else {
                throw WikiError.dataParseError
            }
            let location = WikiPickerLocation(wikiToken: node.parent,
                                              nodeName: "",
                                              spaceID: node.meta.spaceID,
                                              spaceName: "",
                                              isMylibrary: MyLibrarySpaceIdCache.isMyLibrary(node.meta.spaceID))
            return self.confirmCopyToWiki(context: context, location: location)
                .map {
                    // copy 到当前位置时，spaceName 和 nodeName 无法保证拿得到，目前只有移动场景需要关注 spaceName，这里暂不处理
                    CopyResponse(node: .wiki(node: $0, url: $1),
                                 location: .wikiNode(location: location),
                                 statistic: $2)
                }
        }
    }

    public func confirmCopyTo(location: WorkspacePickerLocation, context: CopyContext, picker: UIViewController) -> Single<CopyResponse> {
        switch location {
        case let .wikiNode(wikiLocation):
            return confirmCopyToWiki(context: context, location: wikiLocation)
                .map {
                    CopyResponse(node: .wiki(node: $0, url: $1), location: location, statistic: $2)
                }
        case let .folder(spaceLocation):
            guard spaceLocation.canCreateSubNode else {
                return .error(DocsNetworkError.forbidden)
            }
            return confirmCopyToSpace(context: context, folderToken: spaceLocation.folderToken, picker: picker)
                .map {
                    CopyResponse(node: .space(url: $0), location: location, statistic: $1)
                }
        }
    }

    private func confirmCopyToSpace(context: CopyContext,
                                    folderToken: String,
                                    picker: UIViewController) -> Single<(URL, StatisticResponse)> {
        switch context.sourceLocation {
        case let .inWiki(sourceWikiToken, sourceSpaceID):
            let title = Self.getCopyTitle(from: context)
            return networkAPI.copyWikiToSpace(sourceSpaceID: sourceSpaceID,
                                              sourceWikiToken: sourceWikiToken,
                                              objType: context.objType,
                                              title: title,
                                              folderToken: folderToken)
            .map { (token, url) in
                let response = StatisticResponse(pageToken: token,
                                                 objToken: token,
                                                 objType: context.objType)
                return (url, response)
            }
        case .external:
            let title = Self.getOriginTitle(from: context)
            let params = DocsCreateDirectorV2.TrackParameters(source: .other,
                                                              module: .wikiSpace,
                                                              ccmOpenSource: .copy)
            let request = WorkspaceManagementAPI.Space.CopyToSpaceRequest(
                sourceMeta: SpaceMeta(objToken: context.objToken, objType: context.objType),
                ownerType: singleContainerOwnerTypeValue,
                folderToken: folderToken,
                originName: title,
                fileSize: nil,
                trackParams: params
            )
            return WorkspaceManagementAPI.Space.copyToSpace(request: request,
                                                            router: picker as? DocsCreateViewControllerRouter)
            .map { url in
                let token = DocsUrlUtil.getFileToken(from: url) ?? context.objToken
                let response = StatisticResponse(pageToken: token, objToken: token, objType: context.objType)
                return (url, response)
            }
        }
    }

    private func confirmCopyToWiki(context: CopyContext,
                                   location: WikiPickerLocation) -> Single<(WikiServerNode, URL, StatisticResponse)> {
        let title = Self.getCopyTitle(from: context)
        switch context.sourceLocation {
        case let .inWiki(sourceWikiToken, sourceSpaceID):
            return networkAPI.copyWikiNode(sourceMeta: WikiMeta(wikiToken: sourceWikiToken, spaceID: sourceSpaceID),
                                           objType: context.objType,
                                           targetMeta: WikiMeta(location: location),
                                           title: title,
                                           synergyUUID: synergyUUID)
            .map { (node, url) in
                let response = StatisticResponse(pageToken: node.meta.wikiToken,
                                                 objToken: node.meta.objToken,
                                                 objType: node.meta.objType)
                return (node, url, response)
            }
        case .external:
            let needAsync = context.objType == .sheet
            return WorkspaceManagementAPI.Space.copyToWiki(objToken: context.objToken,
                                                           objType: context.objType,
                                                           location: location,
                                                           title: title,
                                                           needAsync: needAsync)
            .map { json, wikiToken in
                let data = try json.rawData()
                let decoder = JSONDecoder()
                let node = try decoder.decode(WikiServerNode.self, from: data)
                let response = StatisticResponse(pageToken: node.meta.wikiToken,
                                                 objToken: node.meta.objToken,
                                                 objType: node.meta.objType)
                let url = DocsUrlUtil.url(type: .wiki, token: wikiToken)
                return (node, url, response)
            }
        }
    }

    private static func getOriginTitle(from context: CopyContext) -> String {
        if context.isShortcut, let name = context.originName, !name.isEmpty {
            return name
        } else if let name = context.name, !name.isEmpty {
            return name
        } else {
            return context.objType.untitledString
        }
    }

    private static func getCopyTitle(from context: CopyContext) -> String {
        let title = getOriginTitle(from: context)
        if context.objType == .file, title.contains(".") {
            let arraySubstrings: [Substring]? = title.split(separator: ".")
            let lastName = arraySubstrings?.last ?? ""
            let suffix = "." + lastName
            let tmp = title
            let replaceC = " " + BundleI18n.SKResource.Doc_Facade_CopyDocSuffix + "." + lastName
            let newTitle = tmp.replacingOccurrences(of: suffix, with: replaceC)
            return newTitle
        } else {
            return "\(title) \(BundleI18n.SKResource.Doc_Facade_CopyDocSuffix)"
        }
    }
}

// MARK: - Shortcut To
extension WikiInteractionHandler {

    public typealias ShortcutPickerHandler = (UIViewController, WorkspacePickerLocation) -> Void
    public typealias ShortcutResponse = CreateResponse

    public func makeShortcutPicker(context: Context,
                                   triggerLocation: WorkspacePickerTracker.TriggerLocation,
                                   entrances: [WorkspacePickerEntrance],
                                   handler: @escaping ShortcutPickerHandler) -> UIViewController {
        let tracker = WorkspacePickerTracker(actionType: .shortcutTo,
                                             triggerLocation: triggerLocation)
        let config = WorkspacePickerConfig(title: BundleI18n.SKResource.LarkCCM_Wiki_AddShortcutTo_Header_Mob,
                                           action: .createWikiShortcut,
                                           entrances: entrances,
                                           ownerTypeChecker: { $0 ? nil : BundleI18n.SKResource.CreationMobile_ECM_UnableShortToast },
                                           tracker: tracker) { location, picker in
            handler(picker, location)
        }
        return WorkspacePickerFactory.createWorkspacePicker(config: config)
    }

    public func confirmShortcutTo(location: WorkspacePickerLocation, context: Context) -> Single<ShortcutResponse> {
        switch location {
        case let .wikiNode(wikiLocation):
            return confirmShortcutToWiki(context: context, location: wikiLocation)
                .map {
                    ShortcutResponse(node: .wiki(node: $0, url: $1), location: location, statistic: $2)
                }
        case let .folder(folderLocation):
            guard folderLocation.canCreateSubNode else {
                return .error(DocsNetworkError.forbidden)
            }
            return confirmShortcutToSpace(context: context, folderToken: folderLocation.folderToken)
                .map {
                    ShortcutResponse(node: .space(url: $0), location: location, statistic: $1)
                }
        }
    }

    private func confirmShortcutToSpace(context: Context,
                                        folderToken: String) -> Single<(URL, StatisticResponse)> {
        return networkAPI.shortcutWikiToSpace(objToken: context.objToken,
                                              objType: context.objType,
                                              folderToken: folderToken)
        .map { token, url in
            let response = StatisticResponse(pageToken: token,
                                             objToken: context.objToken,
                                             objType: context.objType)
            if folderToken.isEmpty {
                let url = UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? DocsUrlUtil.cloudDriveMyFolderURL : DocsUrlUtil.mySpaceURL
                return (url, response)
            } else {
                return (url, response)
            }
        }
    }

    private func confirmShortcutToWiki(context: Context, location: WikiPickerLocation) -> Single<(WikiServerNode, URL, StatisticResponse)> {
        let shortcutTitle = Self.getOriginTitle(from: context)
        switch context.sourceLocation {
        case let .inWiki(sourceWikiToken, _):
            return networkAPI.createShortcut(spaceID: location.spaceID,
                                             parentWikiToken: location.wikiToken,
                                             originWikiToken: sourceWikiToken,
                                             title: shortcutTitle,
                                             synergyUUID: synergyUUID)
            .map { node in
                let response = StatisticResponse(pageToken: node.meta.wikiToken,
                                                 objToken: node.meta.objToken,
                                                 objType: node.meta.objType)
                let url = DocsUrlUtil.url(type: .wiki, token: node.meta.wikiToken)
                return (node, url, response)
            }
        case .external:
            return WorkspaceManagementAPI.Space.shortcutToWiki(objToken: context.objToken,
                                                               objType: context.objType,
                                                               title: shortcutTitle,
                                                               location: location)
            .map { _, json in
                let data = try json.rawData()
                let decoder = JSONDecoder()
                let node = try decoder.decode(WikiServerNode.self, from: data)
                let response = StatisticResponse(pageToken: node.meta.wikiToken,
                                                 objToken: node.meta.objToken,
                                                 objType: node.meta.objType)
                let url = DocsUrlUtil.url(type: .wiki, token: node.meta.wikiToken)
                return (node, url, response)
            }
        }
    }
}

// MARK: - Rename
extension WikiInteractionHandler {
    public func rename(context: Context, newTitle: String) -> Completable {
        networkAPI.update(newTitle: newTitle, wikiToken: context.wikiToken)
    }
}

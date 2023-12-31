//
//  WorkspaceCreateDirector.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/2/6.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyJSON
import SKFoundation
import SpaceInterface
import SKInfra


public enum WorkspaceCreateLocation {
    // Wiki 挂载点，location 为 nil 表示创建到我的文档库根节点
    case wiki(location: (spaceID: String, parentWikiToken: String)?)
    // Space 挂载点，token 为 nil 表示创建到我的空间根节点
    case folder(token: String?, ownerType: Int)
    /// 默认创建位置受用户设置和若干 FG 控制
    /// 判断 default 可能需要依赖网络请求，无法前置判断，因此在 createDirector 内部处理
    case `default`

    // 创建到我的文档库根节点下
    public static var myLibrary: Self { .wiki(location: nil) }
    // Space 2.0 我的空间根节点
    public static var mySpaceV2: Self { .folder(token: nil, ownerType: singleContainerOwnerTypeValue) }
    // Space 1.0 我的空间根节点
    public static var mySpaceV1: Self { .folder(token: nil, ownerType: defaultOwnerType) }

    // Space 默认位置，受 FG 控制 1.0 或 2.0
    public static var spaceDefault: Self {
        if SettingConfig.singleContainerEnable {
            return mySpaceV2
        } else {
            return mySpaceV1
        }
    }
}

public extension WorkspaceCreateDirector {
    typealias Location = WorkspaceCreateLocation
}

public protocol WorkspaceDefaultLocationProvider {
    static func getDefaultCreateLocation() throws -> WorkspaceCreateLocation?
}

// 支持创建文档到 Wiki 或 Space
public final class WorkspaceCreateDirector {
    public typealias TrackParameters = DocsCreateDirectorV2.TrackParameters

    public let location: Location
    public let trackParameters: TrackParameters

    public init(location: Location, trackParameters: TrackParameters) {
        self.location = location
        self.trackParameters = trackParameters
    }
}

// MARK: - Default Create Location
extension WorkspaceCreateDirector: WorkspaceDefaultLocationProvider {

    private static var defaultCreateLocationKey: String {
        "workspace_default_create_location"
    }

    // 读缓存
    public static func getDefaultCreateLocation() throws -> WorkspaceCreateLocation? {
        if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
            return .myLibrary
        }
        return .spaceDefault
//        guard UserScopeNoChangeFG.WWJ.userDefaultLocationEnabled else {
//            CacheService.configCache.removeObject(forKey: defaultCreateLocationKey)
//            if UserScopeNoChangeFG.WWJ.defaultCreateInLibraryEnabled {
//                return .myLibrary
//            }
//            return .spaceDefault
//        }
//        guard let data: Data = CacheService.configCache.object(forKey: defaultCreateLocationKey) else {
//            return nil
//        }
//        let decoder = JSONDecoder()
//        let defaultLocation = try decoder.decode(WorkspaceManagementAPI.DefaultCreateLocation.self, from: data)
//        let location = convert(location: defaultLocation)
//        return location
    }

    /// 获取并按需更新默认创建位置
    public static func fetchDefaultCreateLocation() -> Single<WorkspaceCreateLocation> {
        if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
            return .just(.myLibrary)
        }
        return .just(.spaceDefault)
//        guard UserScopeNoChangeFG.WWJ.userDefaultLocationEnabled else {
//            DocsLogger.info("my library FG or user default location FG closed, create to space instead")
//            CacheService.configCache.removeObject(forKey: defaultCreateLocationKey)
//            if UserScopeNoChangeFG.WWJ.defaultCreateInLibraryEnabled {
//                return .just(.myLibrary)
//            }
//            return .just(.spaceDefault)
//        }
//        do {
//            guard let location = try getDefaultCreateLocation() else {
//                // 读不到缓存，直接拉网络
//                DocsLogger.info("cache location not found, fetch from server instead")
//                return updateDefaultCreateLocation()
//            }
//            // 读到缓存，同时异步拉一次更新一下
//            updateDefaultCreateLocation().subscribe()
//            return .just(location)
//        } catch {
//            // 缓存有脏数据，直接拉网络
//            DocsLogger.error("failed to parse cache location, fetch from server instead", error: error)
//            return updateDefaultCreateLocation()
//        }
    }

    // 获取并更新默认位置缓存
    public static func updateDefaultCreateLocation() -> Single<WorkspaceCreateLocation> {
        WorkspaceManagementAPI.getDefaultCreateLocation()
            .do { location in
                // 拉到后覆盖一下缓存
                let encoder = JSONEncoder()
                let data = try encoder.encode(location)
                CacheService.configCache.set(object: data, forKey: defaultCreateLocationKey)
            }
            .map { defaultLocation in
                let location = convert(location: defaultLocation)
                DocsLogger.info("get default location from server, default: \(defaultLocation), converted: \(location)")
                return location
            }
    }

    // 根据用户设置和 FG 转换为创建位置参数
    static func convert(location: WorkspaceManagementAPI.DefaultCreateLocation,
                        defaultCreateInLibrary: Bool = UserScopeNoChangeFG.WWJ.defaultCreateInLibraryEnabled) -> WorkspaceCreateLocation {
        switch location {
        case .myLibrary:
            return .myLibrary
        case .mySpace:
            return .spaceDefault
        case .none:
            if defaultCreateInLibrary {
                return .myLibrary
            } else {
                return .spaceDefault
            }
        }
    }
}

// MARK: - Create Empty Page
extension WorkspaceCreateDirector {
    
    public func create(docsType: DocsType,
                       templateSource: TemplateCenterTracker.TemplateSource? = nil,
                       completion: @escaping CreateCompletion) {
        switch location {
        case let .folder(token, ownerType):
            create(folderToken: token, ownerType: ownerType, docsType: docsType, templateSource: templateSource, completion: completion)
        case let .wiki(location):
            create(location: location, docsType: docsType, completion: completion)
        case .default:
            Self.fetchDefaultCreateLocation().subscribe { [self] location in
                switch location {
                case let .folder(token, ownerType):
                    create(folderToken: token, ownerType: ownerType, docsType: docsType, templateSource: templateSource, completion: completion)
                case let .wiki(location):
                    create(location: location, docsType: docsType, completion: completion)
                case .default:
                    spaceAssertionFailure("default should not be found when get from cache or server")
                    let ownerType = SettingConfig.singleContainerEnable ? singleContainerOwnerTypeValue : defaultOwnerType
                    create(folderToken: nil, ownerType: ownerType, docsType: docsType, templateSource: templateSource, completion: completion)
                }
            } onError: { error in
                DocsLogger.error("failed to get default location when create empty page", error: error)
                completion(nil, nil, docsType, nil, error)
            }
        }
    }

    private func create(folderToken: String?, 
                        ownerType: Int,
                        docsType: DocsType,
                        templateSource: TemplateCenterTracker.TemplateSource? = nil,
                        completion: @escaping CreateCompletion) {
        let director = DocsCreateDirectorV2(type: docsType, ownerType: ownerType, name: nil, in: folderToken ?? "", trackParamters: trackParameters)
        director.create(templateSource: templateSource, completion: completion)
        director.makeSelfReferenced()
    }

    private func create(location: (spaceID: String, parentWikiToken: String)?, docsType: DocsType, completion: @escaping CreateCompletion) {
        // 是否是创建到我的文档库根节点
        let isCreateInMylibraryRoot = location == nil
        // 无网且离线新建FG开，走离线新建逻辑
        let canCreateInOffline = !DocsNetStateMonitor.shared.isReachable && canOfflineCraeteDocsType(type: docsType)
        // 在线且在线走本地新建FG开，走离线新建逻辑
        let canLocalCreateInOnline = DocsNetStateMonitor.shared.isReachable && canOfflineCraeteDocsType(type: docsType)
        let useOfflineCreate = canCreateInOffline || canLocalCreateInOnline
        // wiki离线新建仅适用于文档库根节点
        if useOfflineCreate && isCreateInMylibraryRoot {
            let ownerType = SettingConfig.singleContainerEnable ? singleContainerOwnerTypeValue : defaultOwnerType
            let director = DocsCreateDirectorV2(location: .wiki(objType: docsType), ownerType: ownerType, name: nil, in: "", trackParamters: trackParameters)
            director.create(completion: completion)
            director.makeSelfReferenced()
            return
        }
        
        WorkspaceManagementAPI.Wiki.createNode(location: location,
                                               objType: docsType,
                                               templateToken: nil,
                                               synergyUUID: nil)
        .observeOn(MainScheduler.instance)
        .subscribe { data in
            guard let wikiToken = data["wiki_token"].string,
                  var url = data["url"].url else {
                DocsLogger.error("failed to get wiki token when create empty page in wiki")
                completion(nil, nil, .wiki, nil, DocsNetworkError.invalidData)
                return
            }
            //params: from: tab_create 帮助前端优化离线创建进入编辑状态速度
            let (controller, _) = SKRouter.shared.open(with: url, params: ["from": "tab_create"])
            completion(wikiToken, controller, .wiki, url.absoluteString, nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                // 创建成功后，触发一次最近列表刷新
                NotificationCenter.default.post(name: Notification.Name.Docs.refreshRecentFilesList, object: nil)
            })
        } onError: { error in
            DocsLogger.error("create wiki empty page failed", error: error)
            completion(nil, nil, .wiki, nil, error)
        }
        // 注意这里没有用 disposeBag，目的是为了达到类似 makeSelfReferenced 的效果，后续改造直接传给上层处理
    }
    
    private func canOfflineCraeteDocsType(type: DocsType) -> Bool {
        return type == .docX || type == .sheet || type == .mindnote
    }
}

// MARK: Create With Template
extension WorkspaceCreateDirector {
//    // (Token，BrowserVC，DocsType，网络请求错误码)
//    public typealias CreateCompletion = (String?, UIViewController?, DocsType, Error?) -> Void
    public func create(template: TemplateModel,
                       templateCenterSource: SKCreateTracker.TemplateCenterSource?,
                       templateSource: TemplateCenterTracker.TemplateSource? = nil,
                       autoOpen: Bool = true,
                       completion: @escaping CreateCompletion) {
        switch location {
        case let .folder(token, ownerType):
            create(folderToken: token,
                   ownerType: ownerType,
                   template: template,
                   templateCenterSource: templateCenterSource,
                   templateSource: templateSource,
                   autoOpen: autoOpen,
                   completion: completion)
        case let .wiki(location):
            create(location: location, template: template, completion: completion)
        case .default:
            // 这里需要在闭包内持有自己，因为没有外部持有 director，现有的设计里，director 都需要持有自己
            Self.fetchDefaultCreateLocation().subscribe { [self] location in
                switch location {
                case let .folder(token, ownerType):
                    create(folderToken: token,
                           ownerType: ownerType,
                           template: template,
                           templateCenterSource: templateCenterSource,
                           templateSource: templateSource,
                           autoOpen: autoOpen,
                           completion: completion)
                case let .wiki(location):
                    create(location: location, template: template, completion: completion)
                case .default:
                    spaceAssertionFailure("default should not be found when get from cache or server")
                    let ownerType = SettingConfig.singleContainerEnable ? singleContainerOwnerTypeValue : defaultOwnerType
                    create(folderToken: nil,
                           ownerType: ownerType,
                           template: template,
                           templateCenterSource: templateCenterSource,
                           templateSource: templateSource,
                           autoOpen: autoOpen,
                           completion: completion)
                }
            } onError: { error in
                DocsLogger.error("failed to get default location when create with template", error: error)
                completion(nil, nil, template.docsType, nil, error)
            }
        }
    }

    private func create(folderToken: String?,
                        ownerType: Int,
                        template: TemplateModel,
                        templateCenterSource: SKCreateTracker.TemplateCenterSource?,
                        templateSource: TemplateCenterTracker.TemplateSource? = nil,
                        autoOpen: Bool,
                        completion: @escaping CreateCompletion) {
        var extra = TemplateCenterTracker.formateStatisticsInfoForCreateEvent(source: .spaceTemplate, categoryName: nil, categoryId: nil)
        extra?[SKCreateTracker.sourceKey] = FromSource.spaceTemplate.rawValue
        let director = DocsCreateDirectorV2(location: .folder(objType: template.docsType),
                                            ownerType: ownerType,
                                            name: nil, in: folderToken ?? "",
                                            trackParamters: trackParameters)
        director.makeSelfReferenced()
        director.createByTemplate(templateObjToken: template.objToken,
                                  templateId: template.source == .createBlankDocs ? template.id : nil,
                                  templateType: template.templateMainType,
                                  templateCenterSource: templateCenterSource,
                                  templateSource: templateSource,
                                  statisticsExtra: extra,
                                  autoOpen: autoOpen,
                                  completion: completion)
    }

    private func create(location: (spaceID: String, parentWikiToken: String)?, template: TemplateModel, completion: @escaping CreateCompletion) {
        WorkspaceManagementAPI.Wiki.createNode(location: location,
                                               objType: template.docsType,
                                               templateToken: template.objToken,
                                               templateSource: template.templateSource,
                                               synergyUUID: nil)
        .observeOn(MainScheduler.instance)
        .subscribe { data in
            guard let wikiToken = data["wiki_token"].string,
                  let url = data["url"].url else {
                DocsLogger.error("failed to get wiki token when create with template in wiki")
                completion(nil, nil, .wiki, nil, DocsNetworkError.invalidData)
                return
            }
            let (controller, _) = SKRouter.shared.open(with: url)
            completion(wikiToken, controller, .wiki, url.absoluteString, nil)

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                // 创建成功后，触发一次最近列表刷新
                NotificationCenter.default.post(name: Notification.Name.Docs.refreshRecentFilesList, object: nil)
            })
        } onError: { error in
            DocsLogger.error("create wiki with template failed", error: error)
            completion(nil, nil, .wiki, nil, error)
        }
        // 注意这里没有用 disposeBag，目的是为了达到类似 makeSelfReferenced 的效果，后续改造直接传给上层处理
    }
}

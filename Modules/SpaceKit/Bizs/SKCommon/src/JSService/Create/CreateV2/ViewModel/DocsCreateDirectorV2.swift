//
//  DocsCreateDirectorV2.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/8/27.
//  swiftlint:disable file_length

import Foundation
import SwiftyJSON
import EENavigator
import SKFoundation
import SKUIKit
import SKResource
import LarkUIKit
import UniverseDesignToast
import UIKit
import SpaceInterface
import SKInfra
import LarkContainer

// 创建完成的产物。请尽量精简这个闭包内的参数
// (Token，BrowserVC，DocsType，URL, 网络请求错误码)
public typealias CreateCompletion = (String?, UIViewController?, DocsType, String?, Error?) -> Void
public typealias UploadCompletion = (DocsType, Bool) -> Void

public protocol SKCreateAPI {
    /// 创建，以及结果的回掉
    /// 请尽量精简这个闭包内的参数
    ///
    /// - Parameters:
    ///   - UIViewController: 结果页，比如 DocsBrowserVC 或者 SlideVC
    ///   - Error: 网络请求的结果
    func create(completion: CreateCompletion?)
    func upload(completion: UploadCompletion?)
}
extension SKCreateAPI {
    public func create(completion: CreateCompletion?) {}
    public func upload(completion: UploadCompletion?) {}
}

public final class DocsCreateDirectorV2: SKCreateAPI {

    public struct TrackParameters {
        let source: FromSource
        let module: PageModule
        public var ccmOpenSource: CCMOpenCreateSource
        public static func `default`() -> TrackParameters {
            return TrackParameters(source: .other, module: .home(.recent), ccmOpenSource: CCMOpenCreateSource.unknow)
        }

        public init(source: FromSource, module: PageModule, ccmOpenSource: CCMOpenCreateSource) {
            self.source = source
            self.module = module
            self.ccmOpenSource = ccmOpenSource
        }
    }
    
    public enum CreateLocation: Equatable {
        case folder(objType: DocsType)
        case wiki(objType: DocsType)
    }

    public weak var router: DocsCreateViewControllerRouter?
    weak var createVCDelegate: DocsCreateViewControllerDelegate?
    // 在 Completion 处，是否要处理跳转相关的逻辑
    // false: 只将结果回吐给上层
    // true: 处理跳转逻辑后，再把结果给上层
    public var handleRouter: Bool = false
    private var createRequest: DocsRequest<String>?
    private let parent: String
    private let type: DocsType
    //单容器需求： 新建时所处环境的ownerType, 文件夹内传当前文件夹的ownerType, 非文件夹内直接传单容器ownerType
    private let ownerType: Int
    private var name: String?
    private let trackParamters: TrackParameters
    private var completion: CreateCompletion?
    private var selfRetainBlock: (() -> Void)?
    // 创建至wiki(目前只有文档库)或folder的标志
    private var createLocation: CreateLocation
    /// 创建 Space 的文档
    ///
    /// - Parameters:
    ///   - type: 文档类型
    ///   - name: 文档名称
    ///   - folder: 创建的文件夹的 token
    ///   - trackParamters: 埋点相关的参数
    public convenience init(type: DocsType,
                            ownerType: Int,
                            name: String?,
                            in folder: String,
                            trackParamters: TrackParameters = TrackParameters.default()) {
        self.init(location: .folder(objType: type),
                  ownerType: ownerType,
                  name: name,
                  in: folder,
                  trackParamters: trackParamters)
    }
    
    public required init(location: CreateLocation,
                         ownerType: Int,
                         name: String?,
                         in folder: String,
                         trackParamters: TrackParameters = TrackParameters.default()) {
        switch location {
        case let .folder(objType):
            self.type = objType
        case let .wiki(objType):
            self.type = objType
        }
        self.createLocation = location
        self.ownerType = ownerType
        self.name = name
        self.parent = folder
        self.trackParamters = trackParamters
    }
    
    public func create(templateSource: TemplateCenterTracker.TemplateSource? = nil, completion: CreateCompletion? = nil) {
        coreCreate(templateSource: templateSource, completion: completion)
    }
    
    public func createByTemplate(templateObjToken: String,
                                 templateId: String? = nil,
                                 templateType: TemplateMainType,
                                 templateCenterSource: SKCreateTracker.TemplateCenterSource?,
                                 templateSource: TemplateCenterTracker.TemplateSource? = nil,
                                 statisticsExtra: [String: Any]?,
                                 autoOpen: Bool = true,
                                 completion: @escaping CreateCompletion) {
        createByTemplateCore(templateObjToken: templateObjToken,
                             templateId: templateId,
                             templateType: templateType,
                             templateCenterSource: templateCenterSource,
                             templateSource: templateSource,
                             statisticsExtra: statisticsExtra,
                             autoOpen: autoOpen,
                             completion: completion)
    }
    //创建副本
    public func createByCopy(orignalToken: String, docType: DocsType, name: String?, folderToken: String?, fileSize: Int64?, completion: @escaping CreateCompletion) {
        handlerCreatCopy(type: docType, name: name, token: orignalToken, parent: folderToken, fileSize: fileSize, completion: completion)
    }
    
    @discardableResult
    public func makeSelfReferenced() -> Self {
        self.selfRetainBlock = {
            spaceAssertionFailure("should not call \(self.selfRetainBlock.debugDescription)")
            DocsLogger.info("\(self)")
        }
        return self
    }
    
    @discardableResult
    func makeSelfUnReferfenced() -> Self {
        self.selfRetainBlock = nil
        return self
    }
}

// MARK: - Create Core
extension DocsCreateDirectorV2 {
    /// 使用模版创建
    private func createByTemplateCore(templateObjToken: String,
                                      templateId: String? = nil,
                                      templateType: TemplateMainType,
                                      templateCenterSource: SKCreateTracker.TemplateCenterSource?,
                                      templateSource: TemplateCenterTracker.TemplateSource? = nil,
                                      statisticsExtra: [String: Any]?,
                                      autoOpen: Bool,
                                      completion: @escaping CreateCompletion) {

        self.completion = completion
        let createCompletion: (TemplateCreateDocsResult?, Error?) -> Void = { [weak self] (result, error) in
            guard let self = self else { return }
            if DocsNetworkError.error(error, equalTo: DocsNetworkError.Code.createLimited) {
                DocsCreateDirectorV2.statisticsForCommerce(self.trackParamters)
            }
            DocsLogger.info("createByTemplateCore complete, success:\(result != nil), autoopen:\(autoOpen)")
            if let result = result,
               let objToken = result.objToken,
               let objType = result.objType,
               autoOpen, //如果不自动打开也直接回调
               DocsType(rawValue: objType).isEditorManagerHandleType() {
                
                var module: [String: Any]?
                module = ["module": self.trackParamters.module.rawValue]
                
                let templateTokenForSta: String = DocsTracker.encrypt(id: templateObjToken)
                var templateInfos: [String: Any] = ["token": templateTokenForSta]
                if templateType == .gallery {
                    templateInfos["token"] = templateObjToken
                    templateInfos[DocsTracker.Params.nonSensitiveToken] = true
                }
                
                let ccmOpenType = CCMOpenType.getOpenType(by: self.trackParamters.ccmOpenSource, isTemplate: true)
                // 记录一下，用于DocsLoader里面render方法给web传入参数，弹起键盘,用完就会清除
//                TemplateCreateFileRecord.saveCurCreatedFileObjtoken(objToken: result.objToken)
                let commonDependency = DocsContainer.shared.resolve(SKCommonDependency.self)!
                let browser = commonDependency.createCompleteV2(
                    token: objToken,
                    type: DocsType(rawValue: objType),
                    source: self.trackParamters.source,
                    ccmOpenType: ccmOpenType,
                    templateCenterSource: templateCenterSource,
                    templateSource: templateSource,
                    moduleDetails: module,
                    templateInfos: templateInfos,
                    extra: statisticsExtra
                )
                self.doCompletion(token: result.objToken, browser: browser, type: self.type, url: result.url, error: error)
            } else {
                //不自动打开也会走这个回调，是否失败需要看error
                let docsType = DocsType(rawValue: result?.objType ?? self.type.rawValue)
                completion(result?.objToken, nil, docsType, result?.url, error)
                self.makeSelfUnReferfenced()
            }
            
            if !autoOpen {
                return //如果不自动打开，就不用更新了
            }
            
            // 更新一下我的文档和最近浏览
            // 还要刷新子文件夹，所以用通知
            NotificationCenter.default.post(name: Notification.Name.Docs.RefreshPersonFile, object: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                // 虽然RN会推送的，但偶现推送不及时，所以还是强制刷一下
                NotificationCenter.default.post(name: Notification.Name.Docs.refreshRecentFilesList, object: nil)
            })
        }
        let req: DocsRequest<TemplateCreateDocsResult>
        if let source = templateSource, source.shouldUseNewForm(), let templateId = templateId {
            req = DocsRequestCenter.createBy(templateId: templateId,
                                             in: parent,
                                             from: self.router?.routerImpl,
                                             templateSource: templateSource,
                                             completion: createCompletion)
        } else {
            req = DocsRequestCenter.createByTemplate(type: type,
                                                         in: parent,
                                                         parameters: ["token": templateObjToken],
                                                         from: self.router?.routerImpl,
                                                         templateSource: templateSource,
                                                         completion: createCompletion)
        }
        req.makeSelfReferenced()
    }
    
    private func handlerCreatCopy(type: DocsType, name: String?, token: String, parent: String?, fileSize: Int64?, completion: @escaping CreateCompletion) {
        self.completion = completion
        let filetype = self.type
        if ownerType == singleContainerOwnerTypeValue {
            let req = DocsRequestCenter.createCopyV2(type: type,
                                                     name: name,
                                                     token: token,
                                                     parent: parent,
                                                     from: self.router?.routerImpl,
                                                     moudle: trackParamters.module,
                                                     fileSize: fileSize) { [weak self] (url, error) in
                self?.doCompletion(token: url, browser: nil, type: filetype, url: url, error: error)
                // 更新一下我的文档和最近浏览
                // 还要刷新子文件夹，所以用通知
                NotificationCenter.default.post(name: Notification.Name.Docs.RefreshPersonFile, object: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                    // 虽然RN会推送的，但偶现推送不及时，所以还是强制刷一下
                    NotificationCenter.default.post(name: Notification.Name.Docs.refreshRecentFilesList, object: nil)
                })
            }
            req.makeSelfReferenced()
        } else {
            
            let req = DocsRequestCenter.createCopy(type: type,
                                                   name: name,
                                                   token: token,
                                                   parent: parent,
                                                   from: self.router?.routerImpl,
                                                   moudle: trackParamters.module,
                                                   fileSize: fileSize) { [weak self] (url, error) in
                self?.doCompletion(token: url, browser: nil, type: filetype, url: url, error: error)
                // 更新一下我的文档和最近浏览
                // 还要刷新子文件夹，所以用通知
                NotificationCenter.default.post(name: Notification.Name.Docs.RefreshPersonFile, object: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                    // 虽然RN会推送的，但偶现推送不及时，所以还是强制刷一下
                    NotificationCenter.default.post(name: Notification.Name.Docs.refreshRecentFilesList, object: nil)
                })
            }
            req.makeSelfReferenced()
        }
    }
    
    /// 主要创建逻辑。分在线和离线
    private func coreCreate(templateSource: TemplateCenterTracker.TemplateSource? = nil, completion: CreateCompletion?) {
        self.completion = completion
        
        // wiki新建走到该场景后默认离线新建，在线新建逻辑在进入DocsCreateDirectorV2之前处理
        if case .wiki = createLocation, let userId = User.current.info?.userID {
            locallyCreate(userid: userId, name: name ?? "", type: type, folder: parent, ownerType: ownerType)
            return
        }

        //是否走离线逻辑
        if isCanLocallyCreate(), let userid = User.current.info?.userID {
            locallyCreate(userid: userid, name: name ?? "", type: type, folder: parent, ownerType: ownerType)
        } else {
            onlinelyCreate(type: type,
                           ownerType: ownerType,
                           name: name ?? "",
                           in: parent,
                           templateCenterSource: nil,
                           templateSource: templateSource,
                           statisticsExtra: nil)
        }
    }
    
    /// 是否走离线逻辑
    func isCanLocallyCreate(enableLocallyCreate: Bool = LKFeatureGating.enableLocallyCreate,
                                 protocolEnable: Bool = OpenAPI.offlineConfig.protocolEnable,
                      isAgentRepeatModuleEnable: Bool = OpenAPI.docs.isAgentRepeatModuleEnable) -> Bool {
        // 没有网络或者是开启了离线创建开关时，才支持离线创建 Docs。其他都走在线创建
        let enableLocalCreate = enableLocallyCreate && (self.type == .doc || self.type == .sheet || self.type == .docX)
        
        let needLocalCreate = enableLocalCreate || !DocsNetStateMonitor.shared.isReachable
        // 代理下模版复用也支持离线新建：OpenAPI.docs.isAgentRepeatModuleEnable
        
        let offlineCreate = protocolEnable == true || isAgentRepeatModuleEnable
        
        if needLocalCreate == true, offlineCreate == true, type.isSupportOfflineCreate {
            return true
        }
        
        return false
    }
    
    private func generateFakeTokenFor(_ userId: String, ownerType: Int?, isWiki: Bool = false) -> String {
        var fakeToken: String
        if !isWiki {
            fakeToken = "fake_" + userId + "_" + Int64(Date().timeIntervalSince1970 * 1000).description
        } else {
            // wiki离线新建的fakeToken中加上W标识，帮助后续log排查区分创建类型
            fakeToken = "fake_" + userId + "_W_" + Int64(Date().timeIntervalSince1970 * 1000).description
        }
        if let ownerType = ownerType {
            fakeToken += "_ownerType" + ownerType.description
        }
        return fakeToken
    }

    private func locallyCreate(userid: String, name: String, type: DocsType, folder: String, ownerType: Int) {
        let time = DocsTimeline()
        let fakeObjToken = generateFakeTokenFor(userid,
                                                ownerType: (ownerType == singleContainerOwnerTypeValue) ? singleContainerOwnerTypeValue : nil)
        let nodeToken = fakeObjToken
        let curTime = Date().timeIntervalSince1970
        var entryType: DocsType = type
        if case .wiki = createLocation {
            entryType = .wiki
        }
        let nodeInfo: [String: Any] = ["name": name,
                                       "obj_token": fakeObjToken,
                                       "token": nodeToken,
                                       "create_uid": userid,
                                       "owner_id": userid,
                                       "edit_uid": userid,
                                       // 如果有兼容问题需要转Int64, 请在NodeTable和Nodel 一起转
                                       "edit_time": curTime,
                                       "add_time": curTime,
                                       "create_time": curTime,
                                       "open_time": curTime,
                                       "activity_time": curTime,
                                       "my_edit_time": curTime,
                                       "parent": folder,
                                       "type": entryType.rawValue,
                                       "owner_type": ownerType,
                                       "node_type": 0]
        
        let fakeFileEntry = SpaceEntryFactory.createEntry(type: entryType,
                                                          nodeToken: nodeToken,
                                                          objToken: fakeObjToken)
        fakeFileEntry.updatePropertiesFrom(JSON(nodeInfo))
        if let userInfo = User.current.info {
            fakeFileEntry.update(ownerInfo: userInfo)
        }
        if let fakeWikiEntry = fakeFileEntry as? WikiEntry {
            let wikiInfo = WikiInfo(wikiToken: fakeObjToken, objToken: fakeObjToken, docsType: type, spaceId: "")
            fakeWikiEntry.update(wikiInfo: wikiInfo)
        }
        if entryType == .wiki {
            // 离线创建Wiki 需要构建wikiInfo
            let extra: [String: Any] = ["wiki_subtype": type.rawValue, "wiki_sub_token": fakeObjToken, "wiki_space_id": MyLibrarySpaceIdCache.get() ?? ""]
            fakeFileEntry.updateExtraValue(extra)
        }
        DocsLogger.info("locally create \(fakeObjToken.encryptToken), type is \(type.name)", component: LogComponents.offlineSyncDoc)
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        dataCenterAPI?.insert(fakeEntry: fakeFileEntry, folderToken: folder)
        // 对于离线新建的，必须要同步
        if  DocsNetStateMonitor.shared.isReachable == false {
            dataCenterAPI?.updateNeedSyncState(objToken: fakeObjToken, type: entryType, needSync: true, completion: nil)
        }

        if entryType == .wiki, type.isEditorManagerHandleType() {
            // 有文档库id缓存表示进入过文档库，可直接将fakeNode插入目录树DB中
            if let libraryId = MyLibrarySpaceIdCache.get() {
                let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
                
                let fakeNode = WikiNode(wikiToken: fakeObjToken, spaceId: libraryId, objToken: fakeObjToken, objType: type, title: name)
                
                if let wikiSrtorageAPI = try? userResolver.resolve(assert: WikiStorageBase.self) {
                    wikiSrtorageAPI.insertFakeNodeForLibrary(wikiNode: fakeNode)
                } else {
                    DocsLogger.error("can not get wikiSrtorageAPI")
                }
            }
            
            let parameters: [String: String] = ["objType": String(type.rawValue),
                                                "spaceId": MyLibrarySpaceIdCache.get() ?? "",
                                                "title": fakeFileEntry.name,
                                                "wikiToken": fakeObjToken]
            let url = DocsUrlUtil.url(type: .wiki, token: fakeObjToken).docs
                .addEncodeQuery(parameters: parameters)
            let (wikiContainer, _) = SKRouter.shared.open(with: url, params: ["from": "tab_create"])
            doCompletion(token: fakeObjToken, browser: wikiContainer, type: type, url: url.absoluteString, error: nil)
            return
        }
        

        let fakeUrl = DocsUrlUtil.url(type: type, token: fakeObjToken)
        if type.isEditorManagerHandleType() {
            let ccmOpenType = CCMOpenType.getOpenType(by: trackParamters.ccmOpenSource, isTemplate: false)
            let browser = DocsContainer.shared.resolve(SKCommonDependency.self)!.createCompleteV2(token: fakeObjToken,
                                                                                                  type: type,
                                                                                                  source: trackParamters.source,
                                                                                                  ccmOpenType: ccmOpenType,
                                                                                                  templateCenterSource: nil,
                                                                                                  templateSource: nil,
                                                                                                  moduleDetails: ["module": trackParamters.module.rawValue],
                                                                                                  templateInfos: nil,
                                                                                                  extra: nil)
            doCompletion(token: fakeObjToken, browser: browser, type: type, url: fakeUrl.absoluteString, error: nil)
        } else {
            doCompletion(token: fakeObjToken, browser: nil, type: type, url: fakeUrl.absoluteString, error: nil)
        }
        DocsTracker.createFile(with: folder, typeName: type.name, isSuccess: true, timeline: time)
    }
    
    private func onlinelyCreate(type: DocsType,
                                ownerType: Int,
                                name: String,
                                in folder: String,
                                templateCenterSource: SKCreateTracker.TemplateCenterSource?,
                                templateSource: TemplateCenterTracker.TemplateSource? = nil,
                                statisticsExtra: [String: Any]?) {
        let useNewAPI = (ownerType == singleContainerOwnerTypeValue)
        createRequest?.cancel()
        if useNewAPI {
            if type == .folder {
                createRequest = DocsRequestCenter.createFolderV2(name: name, parent: folder, desc: nil, completion: { [weak self] (token, error) in
                    guard let `self` = self else { return }
                    self.handleOnlinelyCreateReuslt(type: type,
                                                    name: name,
                                                    in: folder,
                                                    token: token,
                                                    templateCenterSource: templateCenterSource,
                                                    templateSource: templateSource,
                                                    statisticsExtra: statisticsExtra,
                                                    error: error)
                })
            } else {
                createRequest = DocsRequestCenter.createFileV2(type: type, name: name, parent: parent, completion: { [weak self] (token, error) in
                    guard let `self` = self else { return }
                    self.handleOnlinelyCreateReuslt(type: type,
                                                    name: name,
                                                    in: folder,
                                                    token: token,
                                                    templateCenterSource: templateCenterSource,
                                                    templateSource: templateSource,
                                                    statisticsExtra: statisticsExtra,
                                                    error: error)
                })
            }

        } else {
            createRequest = DocsRequestCenter.create(type: type, name: name, in: folder) { [weak self] (token, error) in
                guard let `self` = self else { return }
                self.handleOnlinelyCreateReuslt(type: type,
                                                name: name,
                                                in: folder,
                                                token: token,
                                                templateCenterSource: templateCenterSource,
                                                templateSource: templateSource,
                                                statisticsExtra: statisticsExtra,
                                                error: error)
            }
        }
}
    
    private func handleOnlinelyCreateReuslt(type: DocsType,
                                            name: String,
                                            in folder: String,
                                            token: String?,
                                            templateCenterSource: SKCreateTracker.TemplateCenterSource?,
                                            templateSource: TemplateCenterTracker.TemplateSource? = nil,
                                            statisticsExtra: [String: Any]?,
                                            error: Error?) {
        let time = DocsTimeline()
        // 用户需要付费，进行埋点
        if DocsNetworkError.error(error, equalTo: DocsNetworkError.Code.createLimited) {
            DocsCreateDirectorV2.statisticsForCommerce(trackParamters)
        }
        DocsTracker.createFile(with: folder, typeName: type.name, isSuccess: token != nil, timeline: time)
        
        if error != nil {
            doCompletion(token: nil, browser: nil, type: type, url: nil, error: error)
        }
        
        if type.isEditorManagerHandleType(), let token = token {
            
            let ccmOpenType = CCMOpenType.getOpenType(by: trackParamters.ccmOpenSource, isTemplate: false)
            
            let browser = DocsContainer.shared.resolve(SKCommonDependency.self)!.createCompleteV2(token: token,
                                                                                                  type: type,
                                                                                                  source: trackParamters.source,
                                                                                                  ccmOpenType: ccmOpenType,
                                                                                                  templateCenterSource: templateCenterSource,
                                                                                                  templateSource: templateSource,
                                                                                                  moduleDetails: ["module": trackParamters.module.rawValue],
                                                                                                  templateInfos: nil,
                                                                                                  extra: statisticsExtra)
            let url = DocsUrlUtil.url(type: type, token: token)
            doCompletion(token: token, browser: browser, type: type, url: url.absoluteString, error: error)
        } else if type == .folder {
            doCompletion(token: token, browser: nil, type: type, url: nil, error: error)
        }

        // 后台读写分离导致马上去 拉数据不一定能拉到最新的 数据，所以临时处理需要延迟pull
        // 等后续其他同学来优化吧
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {

            // 更新一下我的文档和最近浏览
            // 还要刷新子文件夹，所以用通知
            NotificationCenter.default.post(name: Notification.Name.Docs.RefreshPersonFile, object: nil)
            let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
            if type == .folder {
                dataCenterAPI?.refreshListData(of: .personalFolder, completion: nil)
            } else {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                    NotificationCenter.default.post(name: Notification.Name.Docs.refreshRecentFilesList, object: nil)
                })
            }
        })
    }
    private func doCompletion(token: String?, browser: UIViewController?, type: DocsType, url: String?, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?._doHandleRouterIfNeed(token: token, browser: browser, type: type, error: error)
            self?.completion?(token, browser, type, url, error)
            self?.makeSelfUnReferfenced()
        }
    }

    private func _doHandleRouterIfNeed(token: String?, browser: UIViewController?, type: DocsType, error: Error?) {
        guard handleRouter else { return }
        if type.isEditorManagerHandleType() {
            if let vc = browser {
                router?.routerPush(vc: vc, animated: true)
            }
            createVCDelegate?.createComplete(token: token, type: type, error: error)
        } else if type == .folder {
            guard let mainSceneWindow = Navigator.shared.mainSceneWindow else { return }
            // 成功时，completion 中会打开对应的 folder，这里不再处理
            guard let error = error else { return }
            if DocsNetworkError.error(error, equalTo: DocsNetworkError.Code.auditError) {
                UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_OpeationFailByPolicy(), on: mainSceneWindow)
            } else if let docsError = error as? DocsNetworkError {
                if docsError.code == .invalidParams {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_CreateFailed, on: mainSceneWindow)
                } else if let message = docsError.code.errorMessage {
                    UDToast.showFailure(with: message, on: mainSceneWindow)
                } else {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_CreateFailed, on: mainSceneWindow)
                }
            } else {
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_CreateFailed, on: mainSceneWindow)
            }
        }
    }
}

extension DocsCreateDirectorV2 {
    public static func isEditorManagerHandleType(_ type: DocsType) -> Bool {
        return type.isEditorManagerHandleType()
    }
}

public extension DocsType {
    func isEditorManagerHandleType() -> Bool {
        return (self == .doc || self == .sheet || self == .mindnote || self == .bitable || self == .docX)
    }
}

extension DocsCreateDirectorV2 {
    // 埋点说明: https://bytedance.feishu.cn/space/doc/doccnqYS6dsv28ppiHlZYm#
    class func statisticsForCommerce(_ parameter: TrackParameters) {
        var param: [String: String] = [:]
        param["action"] = "popup_window"
        param["item"] = "create"
        param["sub_item"] = "create_new_objs"
        // 如果是在 lark 聊天创建的，不需要 module
        if parameter.source != .larkCreate {
            param["module"] = parameter.module.rawValue
        }
        param["source"] = parameter.source == .larkCreate ? "lark_docs" : "docs_manage"
        DocsTracker.log(enumEvent: .clientCommerce, parameters: param)
    }
}

extension DocsCreateDirectorV2 {
    enum DocsCreateDirectorError: Error {
        case templateUnavailable
        case netIsUnreachable
        case curVCNil
    }
}

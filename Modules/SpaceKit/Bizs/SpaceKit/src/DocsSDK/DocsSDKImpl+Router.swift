//
//  SpaceKitImpl+Router.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/6/11.
//  


import Foundation
import EENavigator
import SpaceInterface
import SKCommon
import SKSpace
import SKUIKit
import SKBrowser
import SKResource
import SKFoundation
import LarkUIKit
import LarkReleaseConfig
import SpaceInterface
import SKInfra
import LarkContainer

// MARK: - Router

extension DocsSDKImpl {

    // MakeURLRouter

    // Note: 因为历史原因，路由跳转可能存在 URL/SpaceEntry 两种分化的逻辑
    // 有一部分业务已经兼容的比较好，将共同的依赖抽象到 SKRouterResource 协议里
    // 剩下一部分 `resource as? URL/SpaceEntry` 的逻辑希望早日迁移
    // TODO: makeURLRouter和registerRouter合并
    func makeURLRouter() {
        registerLike()
        registerTemplatePreview()
        registerTemplateCenter()
        registerFilePolicyControlOffLineValidate()
        registerSubordinateRecent()

        // Docs/Sheet/Mindnote 用的是同一个容器
        let types = supportTypes()
        SKRouter.shared.register(types: types) { [weak self] resource, params, docType -> UIViewController in
            guard self != nil else { return UIViewController() }
            if docType.supportVersionInfo, 
               DocsType(url: resource.url) != .wiki,
               resource.url.isVersion,
               !URLValidator.isVCFollowUrl(resource.url),
                !URLValidator.isInnerVersionUrl(resource.url) {
                return self?.userResolver.docs.browserDependency?.registerVersion(resource.url, params: params) ?? UIViewController()
            }
            // from
            guard let realURL = self?.getRealURL(from: resource.url, with: params) else {
                return UIViewController()
            }
            let queryParams = realURL.docs.queryParams ?? [:]
            // chatId
            let chatId = queryParams["chat_id"]
            let vcType: BrowserViewController.Type = {
                if chatId == nil || realURL.docs.isDocHistoryUrl {
                    return EditorManager.getDocsBrowserType(docType)
                } else {
                    return AnnouncementViewController.self
                }
            }()
            // FileConfig
            var fileConfig = FileConfig(vcType: vcType)
            fileConfig.chatId = chatId
            fileConfig.openSessionID = params?["session_id"] as? String
            let file = resource as? SpaceEntry
            fileConfig.isExternal = file?.isExternal ?? false
            fileConfig.docContext = params?["doc_context"] as? DocContext
            // fileConfig.extraInfos 只接收 [String: String]
            // 但是可能会传 "from_sdk": Bool 这种内容，于是过滤一下
            if var extra = params as? [String: Any] {
                var result: [String: String] = [:]
                extra.forEach({ (key, value) in
                    if let v = value as? String {
                        result[key] = v
                    }
                })
                let feed_id_key = "feed_id"
                if extra[feed_id_key] == nil {
                    let feed_id = queryParams[feed_id_key]
                    result[feed_id_key] = feed_id
                    extra[feed_id_key] = feed_id
                }
                fileConfig.extraInfos = result
                fileConfig.feedFromInfo = FeedFromInfo.deserialize(extra)
                DocsLogger.info("SKRouter route fileConfig - feedid:\(fileConfig.feedFromInfo?.feedId)")
            }
            // 记录一下开始 router 的时间
            if fileConfig.extraInfos != nil {
                if fileConfig.extraInfos?["start_time"] == nil {
                    fileConfig.extraInfos?["start_time"] = "\(Int(Date().timeIntervalSince1970 * 1000))"
                }
            } else {
                fileConfig.extraInfos = ["start_time": "\(Int(Date().timeIntervalSince1970 * 1000))"]
            }
            // init ViewController
            fileConfig.feedFromInfo?.record(.beforeEditorOpen)
            //这里取反，fg默认是关闭的
            if !UserScopeNoChangeFG.HZK.openDocAddFromParamDisable {
                //网络小程序来源
                fileConfig.openDocDesc = params?[DocsTracker.Params.openDocDesc] as? String
            }
            fileConfig.associateAppUrl = params?[RouterDefine.associateAppUrl] as? String
            fileConfig.associateAppUrlMetaId = params?[RouterDefine.associateAppUrlMetaId] as? Int
            
            //看下是否需要提前拉取SSR
            if DocHtmlCacheFetchManager.fetchSSRBeforeRenderEnable() {
                if let manager = try? Container.shared.getCurrentUserResolver().resolve(type: DocHtmlCacheFetchManager.self) {
                    manager.fetchDocHtmlCacheIfNeed(url: realURL)
                }
            }
            
            let openResult = EditorManager.shared.open(realURL, fileConfig: fileConfig)
            fileConfig.feedFromInfo?.record(.controllerInit)
            let vc = openResult.targetVC
            if vc == nil, let topvc = openResult.currentTopVC as? RepetitiveOpenBrowserHandler {
                topvc.didReceiveOpenRequestWhenTargetVcIsCurrentTop(fileConfig: fileConfig)
            }
            (vc as? AnnouncementViewController)?.announcementDelegate = EditorManager.shared.delegate
            if let docWebVC = vc as? BrowserViewController, let webView = docWebVC.browerEditor {
                webView.extraInfo = ExtraInfo(fromModule: file?.fromModule,
                                              fromSubmodule: file?.fromSubmodule)
            }
            return vc ?? ContinuePushedVC()
        }
        self.userResolver.docs.moduleManager.registerURLRouter()

        // Folder
        SKRouter.shared.register(types: [.folder]) { (resource, params, _) -> UIViewController? in
            guard let service = try? self.userResolver.resolve(assert: FolderRouterService.self) else {
                DocsLogger.warning("can not get FolderRouterService")
                return nil
            }
            return service.open(resource: resource, params: params)
        }
    }
    
    private func getRealURL(from url: URL, with params: SKRouter.Params?) -> URL {
        var source = FromSource.other
        if let entrySource = (params?[SKEntryBody.fromKey] as? FileListStatistics.Module)?.converToDocsFrom() {
            source = entrySource
        } else if let otherfrom = params?["docs_entrance"] as? String, let sourceFrom = FromSource(rawValue: otherfrom) {
            source = sourceFrom
        }
        var addQueryParams: [String: String] = ["from": source.rawValue]
        if let ccmOpenType = (params?[SKEntryBody.fromKey] as? FileListStatistics.Module)?.converToCCMOpenType(),
           ccmOpenType != .unknow {
            addQueryParams[CCMOpenTypeKey] = ccmOpenType.trackValue
        }
        let realURL = url.docs.addEncodeQuery(parameters: addQueryParams)
        return realURL
    }

    /// 离线打开文档,需本地cac管控鉴权
    func registerFilePolicyControlOffLineValidate() {
        SKRouter.shared.register(checker: { (resource, _) -> (Bool) in
            guard !DocsNetStateMonitor.shared.isReachable else { return false }
            let docsTypes: [DocsType] = [.doc, .docX, .bitable, .mindnote, .sheet, .wiki, .slides]
            guard docsTypes.contains(resource.docsType) else { return false }
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
                let request = PermissionRequest(entity: .ccm(token: "", type: resource.docsType),
                                                operation: .view,
                                                bizDomain: .ccm)
                let result = permissionSDK.validate(request: request)
                DocsLogger.info("offLineValidate with permissionSDK result: \(result)")
                return !result.allow
            } else {
                let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmContentPreview, fileBizDomain: .ccm,
                                                                   docType: resource.docsType, token: "")
                DocsLogger.info("offLineValidate result: \(result)")
                return !result.allow
            }
        }, interceptor: { (resource, params) -> (UIViewController) in
            DocsLogger.info("cac block permission, show router bottom vc")
            return SKRouterBottomViewController(.previewControlByCAC(token: "", type: resource.docsType), title: "")
        })
    }

    func registerLike() {
        SKRouter.shared.register(checker: { (resource, _) -> (Bool) in
            return URLValidator.isLikeListURL(resource.url)
        }, interceptor: { (resource, params) -> (UIViewController) in
            if let likeListVC = LikeListViewController(botUrl: resource.url.absoluteString) {
                let docType = resource.docsType
                var config = FileConfig(vcType: EditorManager.getDocsBrowserType(docType))
                config.extraInfos = params as? [String: String]
                likeListVC.fileConfig = config
                return likeListVC
            } else {
                spaceAssertionFailure("\(SKRouter.logComponent) LikeListViewController is nil")
                return UIViewController()
            }
        })

        SKRouter.shared.register(checker: { (resource, _) -> (Bool) in
            return URLValidator.checkIfCanOpenSaasURLInKA(url: resource.url)
        }, interceptor: { (resource, _) -> (UIViewController) in
            return SaverWebViewController(url: resource.url)
        })
    }

    func registerSubordinateRecent() {
        SKRouter.shared.register(checker: { (resource, params) -> (Bool) in
            guard URLValidator.isDocsURL(resource.url), resource.url.path == "/drive/listing" else { return false }
            if let queryParams = resource.url.docs.queryParams,
               let type = queryParams["type"],
               let ownerId = queryParams["owner_id"],
               type == "recent",
               !ownerId.isEmpty {
                return true
            }
            return false
        }, interceptor: { (resource, params) -> (UIViewController) in
            guard let vc = DocsContainer.shared.resolve(FolderRouterService.self)?.subordinateRecent(resource: resource, params: params) else {
                return UIViewController()
            }
            return vc
        })
    }

    /// 场景化模版预览
    func registerTemplatePreview() {
        SKRouter.shared.register { resource, _ in
            guard let url = resource as? URL, URLValidator.isDocsURL(url) else { return false }
            if let queryParams = url.docs.queryParams,
               let jumpTo = queryParams["jump_to"], jumpTo == "template_preview",
               queryParams["collectionId"] != nil {
                return true
            }
            return false
        } interceptor: { resource, _ in
            var collectionId = ""
            var type: TemplateModel.TemplateType = .collection
            if let url = resource as? URL, let queryParams = url.docs.queryParams {
                if let id = queryParams["collectionId"] {
                    collectionId = id
                }
                if let templateType = queryParams["templateType"], let typeInt = Int(templateType) {
                    type = TemplateModel.TemplateType(rawValue: typeInt) ?? type
                }
            }
            return TemplateCollectionPreviewViewController(
                collectionId: collectionId,
                networkAPI: TemplateDataProvider(),
                type: type)
        }
    }
    
    func registerTemplateCenter() {
        let templateCenter = TemplateCenterRouter()
        SKRouter.shared.register { resource, params in
            return templateCenter.check(resource: resource, params: params)
        } interceptor: { resource, params in
            return templateCenter.targetVC(resource: resource, params: params)
        }
        
        let templateCreate = TemplateDocsCreateRouter()
        SKRouter.shared.register { resource, params in
            return templateCreate.check(resource: resource, params: params)
        } interceptor: { resource, params in
            return templateCreate.targetVC(resource: resource, params: params)
        }
    }
    
    func registerRouter() {
        // SpaceEntry 支持跳转
        Navigator.shared.registerRoute(type: SKEntryBody.self) {
            return SKEntryRouterHandler()
        }

        Navigator.shared.registerRoute(type: SKNoticePushRouterBody.self) {
            return SKNoticePushRouterHandler()
        }
        
        Navigator.shared.registerRoute(type: TemplateCenterBody.self) { (body, request, res) in
            if let action = body.action, action == "create", let type = body.type {
                let vc = TemplateDocsCreateViewController(templateToken: body.token, templateId: body.templateId, docsType: DocsType(rawValue: type), clickFrom: body.clickFrom)
                res.end(resource: vc)
                return
            }
            guard let cache = DocsContainer.shared.resolve(SKCreateEnableTypesCache.self) else {
                spaceAssertionFailure("[Create] SKCreateEnableTypesCache can not be nil")
                return
            }
            cache.updateCreateEnableTypes()
            
            var source: TemplateCenterTracker.EnterTemplateSource = .promotionalDocs
            if let from = body.from, let enterSource = TemplateCenterTracker.EnterTemplateSource(rawValue: from) {
                source = enterSource
            } else if let from = body.enterSource, let enterSource = TemplateCenterTracker.EnterTemplateSource(rawValue: from) {
                source = enterSource
            }
            if (body.topicId != nil || (body.dcSceneId != nil && body.templateCategory != nil)),
                let fromVC = request.from.fromViewController {
                // 跳转到对应的专题模板界面,  有topId或DocComponent场景都使用此页面打开
                let dataProvider = TemplateDataProvider()
                let topicId = body.topicId ?? -1
                let categoryId = body.templateCategory
                let vm = TemplateThemeViewModel(networkAPI: dataProvider,
                                                cacheAPI: dataProvider,
                                                topID: topicId,
                                                categoryId: categoryId,
                                                docComponentSceneId: body.dcSceneId,
                                                objType: body.objType)
                var templateSource:TemplateCenterTracker.TemplateSource?
                if let bodyTemplateSource = body.templateSource {
                    templateSource = TemplateCenterTracker.TemplateSource(bodyTemplateSource)
                } else {
                    templateSource = TemplateCenterTracker.TemplateSource(enterSource: body.enterSource, source: source)
                }
                let vc = TemplateThemeListViewController(
                    fromViewWidth: fromVC.view.frame.width,
                    viewModel: vm,
                    filterType: nil,
                    objType: body.objType,
                    mountLocation: .spaceDefault,
                    targetPopVC: fromVC,
                    source: source,
                    templateSource: templateSource
                )
                vc.selectedDelegate = body.selectedDelegate
                vc.templatePageConfig = body.templatePageConfig
                res.end(resource: vc)

            } else {
                let dataProvider = TemplateDataProvider()
                dataProvider.templateSource = body.templateSource
                let vm = TemplateCenterViewModel(depandency: (networkAPI: dataProvider, cacheAPI: dataProvider),
                                                 shouldCacheFilter: false)
                var templ: TemplateCenterTracker.TemplateSource?
                if body.templateSource == "lark_survey" {
                    vm.templateSource = body.templateSource
                    templ = .lark_survey
                }
                let vc = TemplateCenterViewController(
                    viewModel: vm,
                    initialType: TemplateMainType(rawValue: body.templateType) ?? .gallery,
                    templateCategory: body.templateCategory,
                    objType: body.objType,
                    targetPopVC: request.from.fromViewController,
                    source: source,
                    templateSource: templ
                )
                vc.selectedDelegate = body.selectedDelegate
                vc.templatePageConfig = body.templatePageConfig
                res.end(resource: vc)
            }
        }

        Navigator.shared.registerRoute(type: TemplatePreviewBody.self) { body, _, res in
            let vc = NormalTemplatesPreviewVC(routerBody: body)
            if SKDisplay.pad {
                vc.preferredContentSize = TemplateCenterViewController.preferredContentSize
            }
            res.end(resource: vc)
        }
    }
    
//    private static func checkIfNeedSetupVCForIPadPopover(vc: UIViewController) {
//        if UIDevice.current.userInterfaceIdiom == .pad {
//            vc.modalPresentationStyle = .formSheet
//            vc.preferredContentSize = TemplateCenterViewController.preferredContentSize
//            vc.popoverPresentationController?.containerView?.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
//        }
//    }
    
    private func supportTypes() -> [DocsType] {
        var enableTypes: [DocsType] = [.doc, .sheet, .mindnote, .docX]
        let bitableEnable = DocsType.enableDocTypeDependOnFeatureGating(type: .bitable)
        if bitableEnable {
            enableTypes.append(.bitable)
        }
        let slidesEnable = DocsType.enableDocTypeDependOnFeatureGating(type: .slides)
        if slidesEnable {
            enableTypes.append(.slides)
        }
        let baseAddEnable = DocsType.enableDocTypeDependOnFeatureGating(type: .baseAdd)
        if baseAddEnable {
            enableTypes.append(.baseAdd)
        }
        return enableTypes
    }
}

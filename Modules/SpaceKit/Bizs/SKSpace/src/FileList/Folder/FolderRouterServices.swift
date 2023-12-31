//
//  FolderRouterServices.swift
//  SKECM
//
//  Created by guoqp on 2020/11/24.
//swiftlint:disable file_length

import Foundation
import SKCommon
import UniverseDesignToast
import UniverseDesignDialog
import UniverseDesignEmpty
import EENavigator
import LarkUIKit
import SKFoundation
import RxSwift
import SwiftyJSON
import SKUIKit
import SKResource
import SpaceInterface
import SKInfra
import LarkContainer
import SKWorkspace

public final class FromVCParser {
    init() {}

    class func fromVC(with params: [AnyHashable: Any]?) -> UIViewController {
        if let context = params as? [String: Any],
           let from = context[ContextKeys.from],
           let fromWrapper = from as? NavigatorFromWrapper,
           let fromVC = fromWrapper.fromViewController {
            return fromVC
        } else if let vc = Navigator.shared.mainSceneWindow?.fromViewController {
            return vc
        } else {
            return UIViewController()
        }
    }
}

extension SettingConfig {
    static var openFolderLinkTimeout: Double {
        return SettingConfig.isvMetaTimeout ?? 2.0
    }
}

private struct V1FolderInfo {
    let spaceID: String
    let isRoot: Bool
    let ownerID: String?
}

private struct OpenFolderContext {
    let folderToken: String
    let folderType: FolderType
    // v1 共享文件夹特有参数
    let v1FolderInfo: V1FolderInfo?
    var folderTitle: String?
    let initialState: SpaceCommonFolderContainerViewModel.InitialState
}

private enum FolderRouterAction {
    case openFolderVC(context: OpenFolderContext) //打开文件夹vc
    case openPermissionPromptVC //无权限页面，不能申请
    case openDefaultVC //兜底页
    case openFailVC //打开失败页
    case folderHasDeleted(token: String)  //文件夹被删除
    case folderNotFound
    case cacBlocked // cac管控
    case blockByTNS(info: TNSRedirectInfo)
}

enum FolderRouterServiceError: Error {
    case requestMetaFailed //请求meta失败
    case requestChildrenFailed //请求children失败
    case parseMetaFailed  //解析meta数据失败
    case parseChildrenFailed //解析children数据失败
}

struct FolderPermission {
    typealias ApplyPermissionState = SpaceFolderContainerController.ApplyPermissionState

    var hasPermission: Bool = false
    var applyPermissionState: ApplyPermissionState? //能否申请权限
    var showPasswordShare: Bool?  //是否密码分享
    var hasDeleted: Bool = false  //是否被删除
    var notFound: Bool = false //是否存在
    var cacBlocked: Bool = false ///cac管控

    // v1共享文件夹才有
    var shareVersion: Int?
    fileprivate var v1FolderInfo: V1FolderInfo?

    //v2文件夹才有
    var isShareFolder: Bool?

    init() {}

    public init(_ json: JSON, token: String) {
        if let node = json["data"]["entities"]["nodes"][token].dictionary {
            if let extra = node["extra"]?.dictionary, let spaceid = extra["space_id"]?.string {
                let isRoot = extra["is_share_root"]?.bool ?? false
                v1FolderInfo = V1FolderInfo(spaceID: spaceid, isRoot: isRoot, ownerID: node["owner_id"]?.string)
            }
            if let version = node["share_version"]?.int {
                shareVersion = version
            }
            if let extra = node["extra"]?.dictionary, let isShared = extra["is_share_folder"]?.bool {
                isShareFolder = isShared
            }
        }

        //被删除, code = 7
        if let code = json["code"].int, code == DocsNetworkError.Code.folderDeleted.rawValue {
            hasDeleted = true
            return
        }
        //不存在, code = 3
        if let code = json["code"].int, code == DocsNetworkError.Code.notFound.rawValue {
            notFound = true
            return
        }
        /// cac管控 code = 2002
        if let view = json["data"]["actions"]["view"].int, view == DocsNetworkError.Code.cacPermissonBlocked.rawValue {
            cacBlocked = true
            return
        }

        //有权限, code = 0
        if let code = json["code"].int, DocsNetworkError.isSuccess(code) {
            hasPermission = true
            return
        }
        //无权限，code == 4
        guard let code = json["code"].int, code == OpenAPI.ServerErrorCode.noPermission.rawValue else {
            DocsLogger.info("Parse folder children error, code is not noPermission value")
            return
        }
        if let permissionStatusCode = json["data"]["permission_status_code"].int,
            permissionStatusCode == DocsNetworkError.Code.passwordRequired.rawValue {
            showPasswordShare = true
        }
        let ownerJSON = json["meta"]["owner"]
        guard let canApplyPerm = ownerJSON["can_apply_perm"].bool else {
            DocsLogger.info("Parse folder children data error, no can_apply_perm key")
            applyPermissionState = .disallow
            return
        }

        if canApplyPerm {
            let aliasInfo = UserAliasInfo(json: ownerJSON["display_name"])
            if NSLocale.current.isChinese == false,
               ownerJSON["en_name"].stringValue.isEmpty == false {
                let ownerName = aliasInfo.currentLanguageDisplayName ?? ownerJSON["en_name"].stringValue
                applyPermissionState = .allow(ownerName: ownerName)
            } else {
                let ownerName = aliasInfo.currentLanguageDisplayName ?? ownerJSON["name"].stringValue
                applyPermissionState = .allow(ownerName: ownerName)
            }
        } else {
            applyPermissionState = .disallow
        }
    }
}


public final class FolderRouterManager {
    private var disposeBag = DisposeBag()
    private var resource: SKRouterResource?
    private var params: [AnyHashable: Any]?
    
    private let userResolver: UserResolver

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    // 处理逻辑 https://bytedance.feishu.cn/docs/doccnIJI8iZTrbZhriqVYzIUzFd#
    private func routerAction(_ token: String) -> Single<FolderRouterAction> {
        return folderInfo(token).flatMap { ownerType -> Single<FolderRouterAction> in
            guard let type = ownerType else {
                throw FolderRouterServiceError.parseMetaFailed
            }
            if type == singleContainerOwnerTypeValue {
                //新节点
                let permissionRequest = self.checkV2FolderPermission(folderToken: token)
                return permissionRequest.flatMap { folderPermisson -> Single<FolderRouterAction> in
                    return self.folderChildrenV2(token).flatMap { (code, title, json) -> Single<FolderRouterAction> in
                        var permisson = folderPermisson
                        if let code {
                            if code == DocsNetworkError.Code.tnsCrossBrandBlocked.rawValue {
                                DocsLogger.error("redirect to tns H5 when open folder url")
                                SKDataManager.shared.deleteSubFolderEntries(nodeToken: token)
                                if let url = json["url"].url {
                                    let info = TNSRedirectInfo(meta: SpaceMeta(objToken: token, objType: .folder),
                                                               redirectURL: url,
                                                               module: "folder",
                                                               appForm: .standard)
                                    return .just(.blockByTNS(info: info))
                                } else {
                                    DocsLogger.error("failed to parse url from tns block response")
                                }
                            }
                            if code == DocsNetworkError.Code.folderDeleted.rawValue {
                                permisson.hasDeleted = true
                            }
                            if code == DocsNetworkError.Code.notFound.rawValue {
                                permisson.notFound = true
                            }
                        }
                        let folderType = FolderType(ownerType: singleContainerOwnerTypeValue, shareVersion: nil, isShared: folderPermisson.isShareFolder)
                        return self.routerBy(folderPermisson: permisson, folderType: folderType, folderTitle: title, token: token)
                    }
                }
            } else if (type == oldFolderOwnerType) || (type == oldShareFolderOwnerType) {
                //旧节点
                return self.folderChildren(token).flatMap { (folderPermisson, title) -> Single<FolderRouterAction> in
                    let folderType = FolderType(ownerType: type, shareVersion: folderPermisson.shareVersion, isShared: nil)
                    return self.routerBy(folderPermisson: folderPermisson, folderType: folderType, folderTitle: title, token: token)
                }
            } else {
                //不认识的未知类型
                throw FolderRouterServiceError.parseMetaFailed
            }
        }
    }

    private func routerBy(folderPermisson: FolderPermission,
                          folderType: FolderType,
                          folderTitle: String?,
                          token: String) -> Single<FolderRouterAction> {
        //文件夹被删除
        if folderPermisson.hasDeleted {
            return .just(.folderHasDeleted(token: token))
        }
        if folderPermisson.notFound {
            return .just(.folderNotFound)
        }
        /// cac管控
        if folderPermisson.cacBlocked {
            return .just(.cacBlocked)
        }
        //有权限
        if folderPermisson.hasPermission {
            //筛掉不支持的类型
            guard folderType.isSupportedType else {
                return .just(.openDefaultVC)
            }
            let context = OpenFolderContext(folderToken: token,
                                            folderType: folderType,
                                            v1FolderInfo: folderPermisson.v1FolderInfo,
                                            folderTitle: folderTitle,
                                            initialState: .normal)
            return .just(.openFolderVC(context: context))
        }
        //密码访问
        if let showPasswordShare = folderPermisson.showPasswordShare, showPasswordShare {
            let context = OpenFolderContext(folderToken: token,
                                            folderType: folderType,
                                            v1FolderInfo: folderPermisson.v1FolderInfo,
                                            folderTitle: folderTitle,
                                            initialState: .requirePassword)
            return .just(.openFolderVC(context: context))
        }
        //申请
        guard let allowApplyPermisson = folderPermisson.applyPermissionState else {
            return .just(.openFailVC)
        }
        switch allowApplyPermisson {
        case let .allow(userName):
            let context = OpenFolderContext(folderToken: token,
                                            folderType: folderType,
                                            v1FolderInfo: folderPermisson.v1FolderInfo,
                                            folderTitle: folderTitle,
                                            initialState: .requirePermission(ownerName: userName))
            return .just(.openFolderVC(context: context))
        case .disallow:
            return .just(.openPermissionPromptVC)
        }
    }

    private func folderInfo(_ objToken: String) -> Single<Int?> {
        var params: [String: Any] = [String: Any]()
        params["obj_token"] = objToken
        params["obj_type"] = DocsType.folder.rawValue
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getEntityInfo, params: ["entities": [params]])
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        return request.rxStart().map { json -> Int? in
            let dict = JSON(json ?? "")
            if DocsNetworkError.isSuccess(dict["code"].int),
               let ownerType = dict["data"][objToken]["owner_type"].int {
                return ownerType
            }
            return nil
        }
    }

    private func checkV2FolderPermission(folderToken: String) -> Single<FolderPermission> {
        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        let service = permissionSDK.userPermissionService(for: .folder(token: folderToken))
        return service.updateUserPermission().map { response in
            var permission = FolderPermission()
            switch response {
            case .success:
                // 拉权限成功就算有权限
                permission.hasPermission = true
                let result = service.validate(exemptScene: .viewSpaceFolder)
                switch result.result {
                case .allow:
                    break
                case let .forbidden(denyType, _):
                    if denyType == .blockByFileStrategy || denyType == .blockByUserPermission(reason: .blockByCAC) {
                        permission.cacBlocked = true
                    }
                }
            case let .noPermission(statusCode, applyUserInfo):
                if statusCode == .passwordRequired {
                    permission.showPasswordShare = true
                }
                if let applyUserInfo {
                    permission.applyPermissionState = .allow(ownerName: applyUserInfo.getDisplayName())
                } else {
                    permission.applyPermissionState = .disallow
                }
            }
            return permission
        }.catchError { error in
            guard let docsError = error as? DocsNetworkError else {
                // 不认识的 error 直接抛
                throw error
            }
            var permission = FolderPermission()
            if docsError.code == .notFound {
                permission.notFound = true
            } else if docsError.code == .folderDeleted {
                permission.hasDeleted = true
            }
            return .just(permission)
        }
    }

    private func folderChildrenV2(_ token: String) -> Single<(Int?, String?, JSON)> {
        var params: [String: Any] = [
            "length": 10,
            "rank": "0",
            "asc": false
        ]
        if UserScopeNoChangeFG.WWJ.ccmTNSParamsEnable {
            params["interflow_filter"] = "CLIENT_VARS"
        }
        var folderChildrenPath = OpenAPI.APIPath.childrenListV3
        folderChildrenPath += "?token=\(token)"
        params.forEach {
            folderChildrenPath += "&\($0.key)=\($0.value)"
        }
        let objTypeArray: [DocsType] = [.folder, .doc, .sheet, .bitable, .mindnote, .file, .slides, .docX]
        objTypeArray.forEach {
            folderChildrenPath += "&shortcut_filter=\($0.rawValue)"
        }
        let request = DocsRequest<JSON>(path: folderChildrenPath, params: nil)
            .set(method: .GET)
            .set(headers: [:])
            .set(needVerifyData: false)
        return request.rxResponse().map { data, error -> (Int?, String?, JSON) in
            if let error {
                // TNS error 需要结合 data，单独处理下
                guard let docsError = error as? DocsNetworkError,
                   docsError.code == .tnsCrossBrandBlocked else {
                    throw error
                }
            }
            guard let json = data else {
                DocsLogger.error("request folder children failed")
                throw FolderRouterServiceError.requestChildrenFailed
            }
            let title: String? = json["data"]["entities"]["nodes"][token]["name"].string
            let code: Int? = json["code"].int
            return (code, title, json)
        }
    }

    private func folderChildren(_ token: String) -> Single<(FolderPermission, String?)> {
        let folderChildrenPath = OpenAPI.APIPath.folderDetail
        let params: [String: Any] = [   "token": token,
                                        "need_path": 1,
                                        "need_total": 1,
                                        "length": 10,
                                        "rank": "0",
                                        "asc": false]
        let request = DocsRequest<JSON>(path: folderChildrenPath, params: params)
            .set(method: .GET)
            .set(headers: [:])
            .set(needVerifyData: false)
        return request.rxStart().map { data -> (FolderPermission, String?) in
            guard let json = data else {
                DocsLogger.error("request folder children failed")
                throw FolderRouterServiceError.requestChildrenFailed
            }
            let permisson = FolderPermission(json, token: token)
            let title: String? = json["data"]["entities"]["nodes"][token]["name"].string
            return (permisson, title)
        }
    }
    
    private func showFolderHasDeletedRestoreView(for token: String, from fromVC: UIViewController) {
        let vc = SKRouterBottomViewController(.deleteResotre(token: token, completion: { [weak self] bottomVC in
            guard let self = self else { return }
            self.destinationController(for: token, sourceController: fromVC, completion: { [weak self] folderVC in
                guard let self = self else { return }
                
                self.userResolver.navigator.docs.showDetailOrPush(folderVC, from: fromVC)
                if let coordinate = bottomVC.navigationController?.transitionCoordinator {
                    coordinate.animate(alongsideTransition: nil) { _ in
                        bottomVC.navigationController?.viewControllers.removeAll(where: { $0 == bottomVC })
                    }
                } else {
                    bottomVC.navigationController?.viewControllers.removeAll(where: { $0 == bottomVC })
                }
            })
        }), title: "")
        userResolver.navigator.docs.showDetailOrPush(vc, from: fromVC)
    }
    private func showCacBlockedView(token: String, from fromVC: UIViewController) {
        let vc = SKRouterBottomViewController(.shareControlByCAC(token: token, type: .folder), title: BundleI18n.SKResource.Doc_Facade_Folder)
        userResolver.navigator.docs.showDetailOrPush(vc, from: fromVC)
    }

    private func showTNSBlockedView(info: TNSRedirectInfo, from fromVC: UIViewController) {
        userResolver.navigator.docs.showDetailOrPush(info.finalURL, from: fromVC, forcePush: true)
    }

    private func showDefaultView(from fromVC: UIViewController) {
        guard let url = self.resource as? URL else {
            DocsLogger.error("resource is not url")
            return
        }
        let vc = SKRouter.shared.defaultRouterView(url)
        userResolver.navigator.docs.showDetailOrPush(vc, from: fromVC)
    }

    private func showFailView(from fromVC: UIViewController) {
        let vc = SKRouterBottomViewController(.failurePrompt, title: BundleI18n.SKResource.Doc_Facade_Folder)
        userResolver.navigator.docs.showDetailOrPush(vc, from: fromVC)
    }

    private func showNotFoundView(from fromVC: UIViewController) {
        let vc = SKRouterBottomViewController(.empty(config: UDEmptyConfig(description: .init(descriptionText: BundleI18n.SKResource.Doc_Facade_FolderNoExist),
                                                                           type: .loadingFailure)),
                                              title: BundleI18n.SKResource.Doc_Facade_Folder)
        userResolver.navigator.docs.showDetailOrPush(vc, from: fromVC)
    }

    private func openPermissionPromptVC(token: String, from fromVC: UIViewController) {
        let type = ContentPromptype.permissionPrompt(token: token, type: .folder, ownerName: "", canApply: false, specialPermission: .normal)
        let vc = SKRouterBottomViewController(type, title: BundleI18n.SKResource.Doc_Facade_Folder)
        userResolver.navigator.docs.showDetailOrPush(vc, from: fromVC)
    }

    private func openFolderVC(context: OpenFolderContext, from fromVC: UIViewController) {
        var newContext = context
        newContext.folderTitle = context.folderTitle ?? BundleI18n.SKResource.Doc_Facade_Folder
        let vc = getFolderDetailController(context: newContext, from: .other)
        userResolver.navigator.docs.showDetailOrPush(vc, from: fromVC)
    }

    private func getFolderDetailController(context: OpenFolderContext,
                                           from: FromSource) -> UIViewController {
        let folderToken = context.folderToken
        SKCreateTracker.srcFolderID = DocsTracker.encrypt(id: folderToken)
        let viewModel: PermissionRestrictedFolderListViewModel
        let isShowInDetail: Bool = SKDisplay.pad && UserScopeNoChangeFG.MJ.newIpadSpaceEnable
        switch context.folderType {
        case .common:
            let dataModel = SubFolderDataModelV1(folderInfo: .init(token: folderToken, folderType: .personal))
            viewModel = SubFolderListViewModelV1(dataModel: dataModel, isShowInDetail: isShowInDetail)
        case .share:
            let info = context.v1FolderInfo
            let folderInfo = SpaceV1FolderInfo(token: folderToken, folderType: .share(spaceID: info?.spaceID ?? "", isRoot: info?.isRoot ?? false, ownerID: info?.ownerID))
            let dataModel = SubFolderDataModelV1(folderInfo: folderInfo)
            viewModel = SubFolderListViewModelV1(dataModel: dataModel, isShowInDetail: isShowInDetail)
        case .v2Common:
            let dataModel = SubFolderDataModelV2(folderToken: folderToken, isShareFolder: false)
            viewModel = SubFolderListViewModelV2(dataModel: dataModel, isShowInDetail: isShowInDetail)
        case .v2Shared:
            let dataModel = SubFolderDataModelV2(folderToken: folderToken, isShareFolder: true)
            viewModel = SubFolderListViewModelV2(dataModel: dataModel, isShowInDetail: isShowInDetail)
        case .unknown:
            spaceAssertionFailure()
            let dataModel = SubFolderDataModelV1(folderInfo: .init(token: folderToken, folderType: .personal))
            viewModel = SubFolderListViewModelV1(dataModel: dataModel, isShowInDetail: isShowInDetail)
        }

        let folderSection = FolderListSection(userResolver: userResolver,viewModel: viewModel, isShowInDetail: isShowInDetail)
        let containerVM = SpaceCommonFolderContainerViewModel(userResolver: userResolver,
                                                              title: context.folderTitle ?? "",
                                                              viewModel: viewModel,
                                                              initialState: context.initialState)
        let userID = userResolver.userID
        let homeVM = FolderHomeViewModel(userResolver: userResolver,
                                         listTools: folderSection.navTools,
                                         createEnableUpdated: viewModel.createEnabledUpdated,
                                         commonTrackParamsProvider: {
            containerVM.bizParams.params
        },
                                         createContextProvider: {
            // 延迟到获取时执行，原因是构造 VC 时，folder 信息可能还不准确
            viewModel.createContext
        }, searchContextProvider: {
            // 延迟到获取时执行，原因是构造 VC 时，folder 信息可能还不准确
            viewModel.searchContext
        })

        /// HomeUI
        let noticeVM = VerifyNoticeViewModel(userResolver: userResolver,
                                             token: folderToken,
                                             isSingleContainer: context.folderType.v2,
                                             bulletinManager: DocsContainer.shared.resolve(DocsBulletinManager.self)!,
                                             commonTrackParams: containerVM.bizParams.params)
        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeVM)
        
        let multiSection = SpaceMultiListSection<IpadMultiListHeaderView>(userResolver: userResolver,
                                                                          homeType: .defaultHome(isFromV2Tab: true)) {
            folderSection
        }
        let padHomeUI = SpaceHomeUI {
            multiSection
        }
        let phoneHomeUI = SpaceHomeUI {
            noticeSection
            SpaceSingleListSection(userResolver: userResolver, subSection: folderSection)
        }
        

        let phoneController = SpaceHomeViewController(userResolver: userResolver,
                                                         naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                         homeUI: phoneHomeUI,
                                                         homeViewModel: homeVM)
        let padHomeViewController = SpaceIpadHomeViewController(userResolver: userResolver,
                                                                naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                                homeUI: padHomeUI,
                                                                homeViewModel: homeVM,
                                                                ipadHomeConfig: .subFolder)
        let padController = SpaceIpadListViewControler(userResolver: userResolver,
                                                       title: nil,
                                                       rootViewController: padHomeViewController) {
            SpaceCreateIntent(context: viewModel.createContext, source: .other, createButtonLocation: .bottomRight)
        }
        
        let phoneContainerVC = SpaceFolderContainerController(userResolver: userResolver, contentViewController: phoneController, viewModel: containerVM)
        let padContainerVC = SpaceFolderContainerController(userResolver: userResolver, contentViewController: padController, viewModel: containerVM)
        if isShowInDetail {
            return padContainerVC
        } else {
            return phoneContainerVC
        }
    }
}

extension FolderRouterManager: FolderRouterService {

    public func open(resource: SKRouterResource, params: [AnyHashable: Any]?) -> UIViewController? {
        let fromVC = FromVCParser.fromVC(with: params)
        guard let folderToken = URLValidator.getFolderPath(url: resource.url) else {
            spaceAssertionFailure("somethine wrong here, so that i just return nil")
            return nil
        }
        self.params = params
        self.resource = resource

        if resource is URL {
            DispatchQueue.main.async { [weak self]  in
                guard let self = self else { return }
                self.open(token: folderToken, from: fromVC)
            }
        } else if let file = resource as? FolderEntry {
            // shortCut's owner 有可能不是本体的owner，不能走owner打开本体的逻辑
            if file.isShortCut, file.isSingleContainerNode {
                DispatchQueue.main.async { [weak self]  in
                    guard let self = self else { return }
                    self.open(token: file.objToken, from: fromVC)
                }
            } else if file.hasPermission { //有权限时直接打开，无权限也走一遍请求流程
                let source = (params?[SKEntryBody.fromKey] as? FileListStatistics.Module)?.converToDocsFrom() ?? .other
                let folderInfo = V1FolderInfo(spaceID: file.shareFolderInfo?.spaceID ?? "", isRoot: file.isShareRoot(), ownerID: file.ownerID)
                let context = OpenFolderContext(folderToken: file.objToken,
                                                folderType: file.folderType,

                                                v1FolderInfo: folderInfo,
                                                folderTitle: file.name,
                                                initialState: .normal)
                return getFolderDetailController(context: context,
                                                 from: source)
            } else {
                DispatchQueue.main.async { [weak self]  in
                    guard let self = self else { return }
                    self.open(token: file.objToken, from: fromVC)
                }
            }
        } else {
            spaceAssertionFailure("somethine wrong here, so that i just return nil")
            return nil
        }
        return nil
    }

    // 提供异步返回 folderToken 对应 VC 的 API，会弹 toast，但不会做路由跳转逻辑，目前用于列表创建文件夹后打开场景
    public func destinationController(for folderToken: String, sourceController: UIViewController, completion: @escaping (UIViewController) -> Void) {
        var handled = false
        // 局部handled变量，加锁保证线程安全
        let markHandled = {
            objc_sync_enter(handled)
            handled = true
            objc_sync_exit(handled)
        }
        let readHandled: (() -> Bool) = {
            objc_sync_enter(handled)
            let flag = handled
            objc_sync_exit(handled)
            return flag
        }

        let timeout = SettingConfig.openFolderLinkTimeout
        //超时逻辑，超时那就直接打开失败页面
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            guard !readHandled() else {
                return
            }
            markHandled()
            self.disposeBag = DisposeBag()
            DocsLogger.info("Folder请求meta超时", extraInfo: ["timeout": timeout, "token": folderToken.encryptToken])
            UDToast.removeToast(on: sourceController.view)
            let vc = SKRouterBottomViewController(.failurePrompt, title: BundleI18n.SKResource.Doc_Facade_Folder)
            completion(vc)
        }

        disposeBag = DisposeBag()
        UDToast.showDefaultLoading(on: sourceController.view, disableUserInteraction: true)
        routerAction(folderToken)
            .asSignal(onErrorJustReturn: .openFailVC)
            .emit(onNext: { [weak self] action in
                guard let self = self else { return }
                UDToast.removeToast(on: sourceController.view)
                guard !readHandled() else {
                    return
                }
                markHandled()
                switch action {
                case .openDefaultVC:
                    let vc = SKRouterBottomViewController(.unavailable(.defaultView), title: BundleI18n.SKResource.CreationMobile_ECM_SiteUnavailableTitle())
                    completion(vc)
                case let .openFolderVC(context):
                    var newContext = context
                    newContext.folderTitle = context.folderTitle ?? BundleI18n.SKResource.Doc_Facade_Folder
                    let vc = self.getFolderDetailController(context: context, from: .docCreate)
                    completion(vc)
                case .openPermissionPromptVC:
                    let type = ContentPromptype.permissionPrompt(token: folderToken, type: .folder, ownerName: "", canApply: false, specialPermission: .normal)
                    let vc = SKRouterBottomViewController(type, title: BundleI18n.SKResource.Doc_Facade_Folder)
                    completion(vc)
                case let .blockByTNS(info):
                    let resource = Navigator.shared.response(for: info.finalURL).resource
                    guard let controller = resource as? UIViewController else {
                        DocsLogger.error("failed to get H5 controller for tns URL")
                        let vc = SKRouterBottomViewController(.failurePrompt, title: BundleI18n.SKResource.Doc_Facade_Folder)
                        completion(vc)
                        return
                    }
                    completion(controller)
                default:
                    let vc = SKRouterBottomViewController(.failurePrompt, title: BundleI18n.SKResource.Doc_Facade_Folder)
                    completion(vc)
                }
            })
            .disposed(by: disposeBag)
    }

    public func subordinateRecent(resource: SKRouterResource, params: [AnyHashable : Any]?) -> UIViewController? {
        if let queryParams = resource.url.docs.queryParams,
           let ownerId = queryParams["owner_id"],
           !ownerId.isEmpty,
           let spaceVCFactory = try? userResolver.resolve(assert: SpaceVCFactory.self) {
            let title = BundleI18n.SKResource.LarkCCM_CM_LeaderAccess_RecentDocs_Title(BundleI18n.SKResource.Doc_Permission_AddUserSubDep)
            let subordinateRecentViewController = spaceVCFactory.makeSubordinateRecentViewController(subordinateID: ownerId)
            let containerVC = SpaceListContainerController(contentViewController: subordinateRecentViewController, title: title)
            return containerVC
        }
        return nil
    }

    private func open(token: String, from fromVC: UIViewController) {
        var handled = false
        // 局部handled变量，加锁保证线程安全
        let markHandled = {
            objc_sync_enter(handled)
            handled = true
            objc_sync_exit(handled)
        }
        let readHandled: (() -> Bool) = {
            objc_sync_enter(handled)
            let flag = handled
            objc_sync_exit(handled)
            return flag
        }

        let timeout = SettingConfig.openFolderLinkTimeout
        //超时逻辑，超时那就直接打开失败页面
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            guard !readHandled() else {
                return
            }
            markHandled()
            self.disposeBag = DisposeBag()
            DocsLogger.info("Folder请求meta超时", extraInfo: ["timeout": timeout, "token": token.encryptToken])
            UDToast.removeToast(on: fromVC.view)
            self.showFailView(from: fromVC)
        }

        disposeBag = DisposeBag()
        UDToast.showDefaultLoading(on: fromVC.view, disableUserInteraction: true)
        routerAction(token)
            .asSignal(onErrorJustReturn: .openFailVC)
            .emit(onNext: { [weak self] action in
                UDToast.removeToast(on: fromVC.view)
                guard !readHandled() else {
                    return
                }
                markHandled()
                switch action {
                case .openDefaultVC:
                    self?.showDefaultView(from: fromVC)
                case let .openFolderVC(context):
                    self?.openFolderVC(context: context, from: fromVC)
                case .openPermissionPromptVC:
                    self?.openPermissionPromptVC(token: token, from: fromVC)
                case let .folderHasDeleted(token):
                    self?.showFolderHasDeletedRestoreView(for: token, from: fromVC)
                case .folderNotFound:
                    self?.showNotFoundView(from: fromVC)
                case .cacBlocked:
                    self?.showCacBlockedView(token: token, from: fromVC)
                case let .blockByTNS(info):
                    self?.showTNSBlockedView(info: info, from: fromVC)
                default:
                    self?.showFailView(from: fromVC)
                }
            })
            .disposed(by: disposeBag)
    }
}

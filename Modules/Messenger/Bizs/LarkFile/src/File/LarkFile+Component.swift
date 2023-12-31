//
//  LarkFile+Component.swift
//  LarkFile
//
//  Created by ChalrieSu on 2018/6/29.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import UIKit
import Foundation
import LarkContainer
import RxSwift
import LarkModel
import Swinject
import EENavigator
import LKCommonsTracker
import LarkAlertController
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import LarkKAFeatureSwitch
import LarkFeatureGating
import UniverseDesignToast
import LarkCache
import LarkCore
import LarkAssembler
import BootManager
import LarkKASDKAssemble
import LKCommonsLogging
import RustPB
import LarkSetting
import LarkNavigator

enum File {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "lark.ios.messeger.userscope.refactor") //Global
        return v
    }
    static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

final class MessageFileBrowseHandler: UserTypedRouterHandler {

    static func compatibleMode() -> Bool { File.userScopeCompatibleMode }

    private static let logger = Logger.log(MessageFileBrowseHandler.self, category: "LarkFile.File")
    private let fileNavigation: FileNavigation
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var fileDependency: FileDependency?
    @ScopedInjectedLazy private var fileUtil: FileUtilService?
    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    init(fileNavigation: FileNavigation, resolver: UserResolver) {
        self.fileNavigation = fileNavigation
        super.init(resolver: resolver)
    }

    func handle(_ body: MessageFileBrowseBody, req: EENavigator.Request, res: Response) throws {

        guard let from = req.context.from() else {
            assertionFailure("缺少 From")
            return
        }
        // 不支持文件下载的时候，直接弹窗提示
        if !userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteFileDownload)) {
            if let window = req.from.fromViewController?.view.window {
                UDToast.showTips(
                    with: BundleI18n
                        .LarkFile
                        .Lark_Chat_FileSecurityRestrictDownloadActionGeneralMessage,
                    on: window
                )
            }
            res.end(resource: nil)
        } else {
            var handleBlock: (_ message: Message, _ body: MessageFileBrowseBody, _ from: NavigatorFrom) throws -> Void = {
                [weak self] message, body, from in
                guard let self = self else { return }
                let view = from.fromViewController?.view.window ?? from.fromViewController?.view
                if let view = view {
                    try self.getFileStateAndJudgeOpenFile(message: message, downloadFileScene: body.downloadFileScene, view: view) {
                        do {
                            let resouce = try self.syncHandle(with: message, body: body, from: from)
                            res.end(resource: resouce)
                        } catch {
                            res.end(error: error)
                        }
                    } failToOpenCallBack: {
                        res.end(error: nil)
                    }
                } else {
                    //通常来说总是会有view的；
                    //万一未来哪个场景没有view，就不提前调getFileState拦截了（因为弹不了toast，怕用户以为无响应），
                    //就直接让用户打开文件查看器，然后文件查看里的下载、解压缩等接口会报错
                    let resouce = try self.syncHandle(with: message, body: body, from: from)
                    res.end(resource: resouce)
                }
            }

            //ka文件清理提示优化需求的fg，这个需求对getFileStateRequest接口的调用时机做了改造
            var fileDeleteByScriptFG = (fgService?.dynamicFeatureGatingValue(with: "im.file.delete.by.script.toast") ?? false)
            if let message = body.message {
                if fileDeleteByScriptFG {
                    res.wait()
                    try handleBlock(message, body, from)
                } else {
                    let resouce = try self.syncHandle(with: message, body: body, from: from)
                    res.end(resource: resouce)
                }
            } else {
                res.wait()
                let messageAPI = try self.userResolver.resolve(assert: MessageAPI.self)
                messageAPI.fetchMessage(id: body.messageId)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] (message) in
                        do {
                            if fileDeleteByScriptFG {
                                try handleBlock(message, body, from)
                            } else {
                                guard let self = self else { return }

                                let resouce = try self.syncHandle(with: message, body: body, from: from)
                                res.end(resource: resouce)
                            }
                        } catch {
                            res.end(error: error)
                        }
                    }, onError: { (error) in
                        res.end(error: error)
                    })
                    .disposed(by: disposeBag)
            }
        }
    }

    private static var isRequesting = false
    private var canShowLoading = true
    private func getFileStateAndJudgeOpenFile(message: Message,
                                              downloadFileScene: RustPB.Media_V1_DownloadFileScene?,
                                              view: UIView,
                                              openFileBlock: @escaping (() -> Void),
                                              failToOpenCallBack: @escaping (() -> Void)) throws {
        guard Self.isRequesting == false else {
            return
        }
        Self.isRequesting = true
        self.tryToShowLoading(view: view)
        var authToken: String?
        if message.type == .file {
            authToken = (message.content as? FileContent)?.authToken
        } else if message.type == .folder {
            authToken = (message.content as? FolderContent)?.authToken
        }
        // 有缓存,此时需要调用获取文件状态，若文件可用则直接使用否则报错
        try resolver.resolve(assert: SecurityFileAPI.self).getFileStateRequest(
            messageId: message.id,
            sourceType: message.sourceType,
            sourceID: message.sourceID,
            authToken: authToken,
            downloadFileScene: downloadFileScene
        )
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (state) in
                guard let `self` = self else { return }
                self.removeLoadingHudAndResetFlag(view: view)
                switch state {
                case .normal:
                    openFileBlock()
                case .deleted:
                    self.onOpenFileFail(toastWith: BundleI18n.LarkFile.Lark_Legacy_FileWithdrawTip, view: view, failToOpenCallBack: failToOpenCallBack)
                case .recoverable:
                    self.onOpenFileFail(toastWith: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogWithin90Days, view: view, failToOpenCallBack: failToOpenCallBack)
                case .unrecoverable:
                    self.onOpenFileFail(toastWith: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogOver90Days, view: view, failToOpenCallBack: failToOpenCallBack)
                case .freedUp:
                    self.onOpenFileFail(toastWith: BundleI18n.LarkFile.Lark_IM_ViewOrDownloadFile_FileDeleted_Text, view: view, failToOpenCallBack: failToOpenCallBack)
                @unknown default:
                    self.onOpenFileFail(toastWith: nil, view: view, failToOpenCallBack: failToOpenCallBack)
                    fatalError("unknown")
                }
                Self.isRequesting = false
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                self.removeLoadingHudAndResetFlag(view: view)
                // 当服务出现错误，直接放过
                openFileBlock()
                Self.isRequesting = false
                Self.logger.error("getFileStateRequest error, error = \(error)")
            }, onCompleted: {
                Self.isRequesting = false
            }).disposed(by: self.disposeBag)
    }

    private func onOpenFileFail(toastWith text: String?, view: UIView, failToOpenCallBack: @escaping (() -> Void)) {
        if let text = text {
            UDToast.showTips(with: text, on: view)
        }
        failToOpenCallBack()
    }

    private func tryToShowLoading(view: UIView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak view] in
            guard self.canShowLoading,
                  let view = view else { return }
            UDToast.showLoading(on: view)
        }
    }

    private func removeLoadingHudAndResetFlag(view: UIView) {
        UDToast.removeToast(on: view)
        self.canShowLoading = false
    }

    private func syncHandle(with message: Message, body: MessageFileBrowseBody, from: NavigatorFrom) throws -> Resource {
        var fileInfo: FileContentBasicInfo?
        if let info = body.fileInfo {
            /// 优先使用业务方传入的文件信息打开预览
            fileInfo = info
        } else if let content = message.content as? FileContent {
            /// 从消息体上获取文件信息
            fileInfo = content
        } else {
            return EmptyResource()
        }
        guard let fileInfo = fileInfo else {
            return EmptyResource()
        }

        guard self.fileNavigation.checkFileDeletedStatus(with: message, from: from) else {
            return EmptyResource()
        }

        let chatAPI = try resolver.resolve(assert: ChatAPI.self)
        guard let chat = body.chatFromTodo ?? chatAPI.getLocalChat(by: message.channel.id) else {
            return EmptyResource()
        }

        //文件是否是支持在线预览的压缩包
        let isPreviewableZip = (fileUtil?.fileIsPreviewableZip(fileName: fileInfo.name, fileSize: fileInfo.size) ?? false)
        && !chat.isPrivateMode && !chat.isCrypto
        guard chat.isPrivateMode ||
                chat.isCrypto ||
                chat.isCrossWithKa ||
                FilePreviewers.canPreviewFileName(fileInfo.name) ||
                !(fileDependency?.canOpenSDKPreview(fileName: fileInfo.name, fileSize: fileInfo.size) ?? false) ||
                isPreviewableZip ||
                body.downloadFileScene == .todo else {
            openWithDirveSDK(
                from: from,
                message: message,
                chat: body.useLocalChat ? chat : nil,
                scene: body.scene,
                downloadFileScene: body.downloadFileScene,
                fileInfo: fileInfo,
                isInnerFile: body.isInnerFile,
                canForward: body.canForward,
                canSaveToDrive: body.canSaveToDrive
            )
            return EmptyResource()
        }

        // 打点
        self.trackOpenAttachCard(fileType: (fileInfo.name as NSString).pathExtension)

        let resolver = self.resolver
        let pushCenter = try resolver.userPushCenter
        let fileHasNoAuthorize: (Message.FileDeletedStatus) -> Void = { status in
            body.fileHasNoAuthorize?(status)
            pushCenter.post(PushFileUnauthorized(messageId: message.id,
                                                          fileDeletedStatus: message.fileDeletedStatus))
        }

        let context: [String: Any] = [
            "chat_type": self.getChatType(by: chat),
            "location": self.getLocation(from: body.scene),
            "chat_id": chat.id
        ]

        var extra: [String: Any] = [:]
        if let downloadFileScene = body.downloadFileScene {
            extra[FileBrowseFromWhere.DownloadFileSceneKey] = downloadFileScene
        }
        if case .favorite(let favoriteId) = body.scene {
            extra[FileBrowseFromWhere.FileFavoriteKey] = favoriteId
        }
        let fileMessageInfo: FileMessageInfo
        if body.isInnerFile {
            let info = FileFromFolderBasicInfo(
                key: fileInfo.key,
                authToken: fileInfo.authToken,
                authFileKey: fileInfo.authFileKey,
                size: fileInfo.size,
                name: fileInfo.name,
                cacheFilePath: "",
                filePreviewStage: fileInfo.filePreviewStage
            )
            fileMessageInfo = FileMessageInfo(userID: userResolver.userID, message: message, fileInfo: info, browseFromWhere: .folder(extra: extra))
        } else {
            fileMessageInfo = FileMessageInfo(userID: userResolver.userID, message: message, browseFromWhere: .file(extra: extra))
        }
        if isPreviewableZip {
            let vm = UnzipViewModel(pushCenter: pushCenter,
                                    fileAPI: try userResolver.resolve(assert: SecurityFileAPI.self),
                                    file: fileMessageInfo)
            let unzipVC = UnzipViewController(viewModel: vm,
                                              displayTopContainer: true,
                                              canOpenWithOtherApp: !chat.enableRestricted(.download),
                                              userGeneralSettings: try userResolver.resolve(assert: UserGeneralSettings.self))
            let folderMessageInfo = FolderMessageInfo(message: message, isFromZip: true, downloadFileScene: body.downloadFileScene, extra: extra)
            let subject = BehaviorSubject(value: FolderManagementViewController.localIsGridStyle)
            let viewWillTransitionSubject = PublishSubject<CGSize>()
            let menuOptins: FolderManagementMenuOptions = self.getMenuOptions(chat: chat,
                                                                              message: message,
                                                                              scene: body.scene,
                                                                              isOpeningInNewScene: body.isOpeningInNewScene,
                                                                              canViewInChat: body.canViewInChat,
                                                                              canForward: body.canForward)
            let contentView = FolderBrowserNavigationView(
                frame: .zero,
                dependency: FolderBrowserNavigationViewDependency(
                    folderMessageInfo: folderMessageInfo,
                    supportForwardCopy: menuOptins.contains(.forward),
                    chatFromTodo: body.chatFromTodo,
                    gridSubject: subject,
                    viewWillTransitionSubject: viewWillTransitionSubject,
                    pushCenter: pushCenter,
                    sourceScene: body.scene,
                    canFileClick: body.canFileClick,
                    useLocalChat: body.useLocalChat
                ),
                resolver: userResolver,
                rootVC: unzipVC
            )
            let folderManagementVC = FolderManagementViewController(
                configuration: self.getFolderManagementConfiguration(chat: chat,
                                                                     message: message,
                                                                     scene: body.scene,
                                                                     isOpeningInNewScene: body.isOpeningInNewScene,
                                                                     canViewInChat: body.canViewInChat,
                                                                     canForward: body.canForward,
                                                                     canSearch: body.canSearch),
                gridSubject: subject,
                viewWillTransitionSubject: viewWillTransitionSubject,
                contentView: contentView,
                sourceScene: body.scene,
                extra: extra,
                userResolver: userResolver
            )
            folderManagementVC.router = contentView
            contentView.targetVC = folderManagementVC
            return folderManagementVC
        }
        let fileBrowVC = try fileNavigation.fileBrowserController(
            file: fileMessageInfo,
            menuOptions: self.getMenuOptions(chat: chat,
                                             message: message,
                                             scene: body.scene,
                                             isOpeningInNewScene: body.isOpeningInNewScene,
                                             canViewInChat: body.canViewInChat,
                                             canForward: body.canForward,
                                             canSaveToDrive: body.canSaveToDrive),
            fileViewOptions: chat.isCrypto ? [.driveLocalPreview, .SDKCacheCrypto] : [],
            context: context
        )
        fileBrowVC.fileHasNoAuthorize = fileHasNoAuthorize
        fileBrowVC.operationEvent = body.operationEvent
        return fileBrowVC
    }

    private func getFolderManagementConfiguration(
        chat: Chat,
        message: Message,
        scene: FileSourceScene,
        isOpeningInNewScene: Bool,
        canViewInChat: Bool,
        canForward: Bool,
        canSearch: Bool
    ) -> FolderManagementConfiguration {
        let supportSearch: Bool
        let menuOptions: FolderManagementMenuOptions = getMenuOptions(chat: chat,
                                                                      message: message,
                                                                      scene: scene,
                                                                      isOpeningInNewScene: isOpeningInNewScene,
                                                                      canViewInChat: canViewInChat,
                                                                      canForward: canForward)
        switch scene {
        case .messageDetail, .chat, .mergeForward, .search, .pin, .favorite, .flag, .fileTab:
            supportSearch = true
        case .forwardPreview:
            supportSearch = false
        @unknown default:
            supportSearch = false
        }
        return FolderManagementConfiguration(menuOptions: menuOptions,
                                             supportSearch: supportSearch && canSearch,
                                             disableAction: message.disabledAction)
    }

    private func openWithDirveSDK(from: NavigatorFrom,
                                  message: Message,
                                  chat: Chat?,
                                  scene: FileSourceScene,
                                  downloadFileScene: RustPB.Media_V1_DownloadFileScene?,
                                  fileInfo: FileContentBasicInfo,
                                  isInnerFile: Bool,
                                  canForward: Bool,
                                  canSaveToDrive: Bool) {
        Self.logger.info("open SDKPreview ", additionalData: ["fileID": fileInfo.key])
        var supportForward = canForward
        if case .mergeForward = scene { supportForward = false }

        var extra: [String: Any] = [:]
        if case .forwardPreview = scene {
            supportForward = false
            extra["forwardPriview"] = true
        }
        if let downloadFileScene = downloadFileScene {
            extra[FileBrowseFromWhere.DownloadFileSceneKey] = downloadFileScene
        }
        if case .favorite(let favoriteId) = scene {
            extra[FileBrowseFromWhere.FileFavoriteKey] = favoriteId
        }
        if isInnerFile {
            fileDependency?.openSDKPreview(
                message: message,
                chat: chat,
                fileInfo: FileFromFolderBasicInfo(
                    key: fileInfo.key,
                    authToken: fileInfo.authToken,
                    authFileKey: fileInfo.authFileKey,
                    size: fileInfo.size,
                    name: fileInfo.name,
                    cacheFilePath: "",
                    filePreviewStage: fileInfo.filePreviewStage
                ),
                from: from,
                supportForward: supportForward,
                canSaveToDrive: canSaveToDrive,
                browseFromWhere: .folder(extra: extra)
            )
        } else {
            fileDependency?.openSDKPreview(
                message: message,
                chat: chat,
                fileInfo: nil,
                from: from,
                supportForward: supportForward,
                canSaveToDrive: canSaveToDrive,
                browseFromWhere: .file(extra: extra)
            )
        }
    }

    private func getMenuOptions(
        chat: Chat,
        message: Message,
        scene: FileSourceScene,
        isOpeningInNewScene: Bool, //是否是分屏打开
        canViewInChat: Bool,
        canForward: Bool
    ) -> FolderManagementMenuOptions {
        let filter: (FolderManagementMenuOptions) -> FolderManagementMenuOptions = { options in
            var result = options
            if chat.enableRestricted(.forward) || !canForward {
                result.remove(.forward)
            }
            if chat.enableRestricted(.download) {
                result.remove(.openWithOtherApp)
            }
            if message.disabledAction.actions[Int32(MessageDisabledAction.Action.saveToLocal.rawValue)] != nil {
                result.remove(.openWithOtherApp)
            }
            if isOpeningInNewScene || !canViewInChat {
                result.remove(.viewInChat)
            }
            return result
        }
        switch scene {
        case .messageDetail, .chat, .mergeForward, .search, .pin, .favorite, .flag, .fileTab:
            return filter([.forward, .viewInChat, .openWithOtherApp])
        case .forwardPreview:
            return []
        @unknown default:
            return []
        }
    }

    private func getMenuOptions(
        chat: Chat,
        message: Message,
        scene: FileSourceScene,
        isOpeningInNewScene: Bool, //是否是分屏打开
        canViewInChat: Bool,
        canForward: Bool,
        canSaveToDrive: Bool
    ) -> FileBrowseMenuOptions {
        if chat.isCrypto {
            return [.openWithOtherApp]
        }
        let filter: (FileBrowseMenuOptions) -> FileBrowseMenuOptions = { options in
            var result = options
            if chat.enableRestricted(.forward) || !canForward {
                result.remove(.forward)
            }
            if chat.enableRestricted(.download) {
                result.remove(.canSaveToAlbum)
                result.remove(.canSaveFileToDrive)
                result.remove(.openWithOtherApp)
            }
            if chat.isPrivateMode {
                /// 密盾群不支持「收藏」，「保存到云盘」
                result.remove(.favorite)
                result.remove(.canSaveFileToDrive)
            }
            if chat.isCrossWithKa {
                //私有互通不支持「保存到云盘」
                result.remove(.canSaveFileToDrive)
            }
            if !canSaveToDrive {
                result.remove(.canSaveFileToDrive)
            }
            if isOpeningInNewScene || !canViewInChat {
                result.remove(.viewInChat)
            }
            if let disabled = message.disabledAction.actions[Int32(MessageDisabledAction.Action.saveToLocal.rawValue)] {
                result.remove(.openWithOtherApp)
            }
            if let disabled = message.disabledAction.actions[Int32(MessageDisabledAction.Action.saveToSpace.rawValue)] {
                result.remove(.canSaveFileToDrive)
            }
            return result
        }
        switch scene {
        case .favorite, .flag:
            return filter([.forward, .canSaveToAlbum, .canSaveFileToDrive, .openWithOtherApp])
        case .messageDetail, .chat:
            return filter([.forward, .favorite, .canSaveToAlbum, .canSaveFileToDrive])
        case .mergeForward:
            return filter([.favorite, .canSaveToAlbum, .canSaveFileToDrive])
        case .search, .pin, .fileTab:
            return filter([.forward, .favorite, .viewInChat, .canSaveToAlbum, .canSaveFileToDrive])
        case .forwardPreview:
            return []
        @unknown default:
            return []
        }
    }

    private func getLocation(from scene: FileSourceScene) -> String {
        switch scene {
        case .messageDetail: return "thread"
        case .search, .fileTab: return "search"
        case .chat: return "main"
        case .pin: return "pin"
        case .favorite: return "favorites"
        case .flag: return "flag"
        case .mergeForward: return "mergeForward"
        case .forwardPreview: return "forwardPreview"
        @unknown default:
            return ""
        }
    }

    private func getChatType(by chat: Chat) -> String {
        let type: String
        if chat.isSingleBot {
            type = "single_bot"
        } else {
            switch chat.type {
            case .group:
                type = "group"
            case .p2P:
                type = "single"
            case .topicGroup:
                type = "topicGroup"
            @unknown default:
                assert(false, "new value")
                return "unknown"
            }
        }
        return type
    }

    private func trackOpenAttachCard(fileType: String) {
        Tracker.post(
            TeaEvent(
                "open_attach_card",
                category: "driver", params: [
                    "file_type": fileType
                ]
            )
        )
    }
}

final class RiskFileAppealHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { File.userScopeCompatibleMode }

    func handle(_ body: RiskFileAppealBody, req: EENavigator.Request, res: Response) throws {
        let pathSuffx = "/document-security-inspection/appeal"
        let schema = "https://"
        guard let domain = DomainSettingManager.shared.currentSetting[.securityWeb]?.first,
              var url = URL(string: schema + domain + pathSuffx) else {
            return
        }
        var parameters = [String: String]()
        parameters.updateValue(body.objToken, forKey: "obj_token")
        parameters.updateValue(String(body.version), forKey: "version")
        parameters.updateValue(String(body.fileType), forKey: "file_type")
        parameters.updateValue(body.locale.localeLanguageParamFormed(), forKey: "locale")
        url = url.append(parameters: parameters, forceNew: false)

        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkFile.Lark_FileSecurity_Dialog_UnableToDownload)
        alertController.setContent(text: BundleI18n.LarkFile.Lark_IM_FileContainsRiskyContentMightHarmDeviceAppealIfDisagree_Desc)
        alertController.addSecondaryButton(text: BundleI18n.LarkFile.Lark_FileSecurity_Button_Cancel)
        alertController.addPrimaryButton(text: BundleI18n.LarkFile.Lark_FileSecurity_Button_AppealNow,
                                         dismissCompletion: {
            self.userResolver.navigator.push(url, from: req.from)
        })

        res.end(resource: alertController)
    }
}

extension String {
    //处理本地获取的locale rawvalue 与前端所需参数不一致问题
    fileprivate func localeLanguageParamFormed() -> String {
       return self.lowercased().replacingOccurrences(of: "_", with: "-")
    }
}

final class LocalFileHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { File.userScopeCompatibleMode }

    let fileNavigation: FileNavigation

    init(fileNavigation: FileNavigation, resolver: UserResolver) {
        self.fileNavigation = fileNavigation
        super.init(resolver: resolver)
    }

    func handle(_ body: LocalFileBody, req: EENavigator.Request, res: Response) throws {
        let controller = try fileNavigation.localFileViewController(config: createConfig(body: body))
        controller.finishChoosingLocalFileBlock = { files in
            body.chooseLocalFiles?(files)
        }
        controller.choosingLocalFileBlock = { filePaths in
            body.chooseFilesChange?(filePaths)
        }
        controller.closeCallback = {
            body.cancelCallback?()
        }
        res.end(resource: controller)
    }

    private func createConfig(body: LocalFileBody) -> LocalFileViewControllerConfig {
        let gigaByte = 1024 * 1024 * 1024
        let config = LocalFileViewControllerConfig(
            maxSelectedCount: body.maxSelectCount ?? Int.max,
            maxAttachedFileSize: body.maxSingleFileSize ?? 100 * gigaByte,
            maxTotalAttachedFileSize: body.maxTotalFileSize ?? 100 * gigaByte,
            extraFilePaths: body.extraFilePaths,
            requestFrom: body.requestFrom ?? .other,
            showSystemAlbumVideo: body.showSystemAlbumVideo,
            title: body.title,
            sendButtonTitle: body.sendButtonTitle)
        return config
    }
}

final class MessageFolderFileBrowseHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { File.userScopeCompatibleMode }

    private let fileNavigation: FileNavigation
    @ScopedInjectedLazy private var chatAPI: ChatAPI?

    init(fileNavigation: FileNavigation, resolver: UserResolver) {
        self.fileNavigation = fileNavigation
        super.init(resolver: resolver)
    }

    func handle(_ body: MessageFolderFileBrowseBody, req: EENavigator.Request, res: Response) throws {
        // 不支持文件下载的时候，直接弹窗提示
        if !userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteFileDownload)) {
            if let window = req.from.fromViewController?.view.window {
                UDToast.showTips(
                    with: BundleI18n.LarkFile.Lark_Chat_FileSecurityRestrictDownloadActionGeneralMessage,
                    on: window
                )
            }
            res.end(resource: EmptyResource())
            return
        }
        guard self.fileNavigation.checkFileDeletedStatus(with: body.message, from: req.from) else {
            res.end(resource: EmptyResource())
            return
        }

        guard let chat = body.chatFromTodo ?? self.chatAPI?.getLocalChat(by: body.message.channel.id) else {
            res.end(resource: EmptyResource())
            return
        }

        var extra: [String: Any] = [:]
        if let downloadFileScene = body.downloadFileScene {
            extra[FileBrowseFromWhere.DownloadFileSceneKey] = downloadFileScene
        }
        if case .favorite(let favoriteId) = body.scene {
            extra[FileBrowseFromWhere.FileFavoriteKey] = favoriteId
        }
        let fileMessageInfo = FileMessageInfo(userID: userResolver.userID, message: body.message, fileInfo: body.fileInfo, browseFromWhere: .folder(extra: extra))
        // 打点
        self.trackOpenAttachCard(fileType: (fileMessageInfo.fileName as NSString).pathExtension)
        let context: [String: Any] = ["chat_type": self.getChatType(by: chat)]
        let pushCenter = try resolver.userPushCenter
        if body.isPreviewableZip {
            let vm = UnzipViewModel(pushCenter: pushCenter,
                                    fileAPI: try userResolver.resolve(assert: SecurityFileAPI.self),
                                    file: fileMessageInfo)
            let unzipVC = UnzipViewController(viewModel: vm, canOpenWithOtherApp: !chat.enableRestricted(.download),
                                              userGeneralSettings: try userResolver.resolve(assert: UserGeneralSettings.self))
            res.end(resource: unzipVC)
            return
        }
        let fileBrowseVC = try fileNavigation.fileBrowserController(
            file: fileMessageInfo,
            menuOptions: self.getMenuOptions(chat: chat,
                                             message: body.message,
                                             supportForwardCopy: body.supportForwardCopy),
            fileViewOptions: [],
            context: context
        )

        let fileHasNoAuthorize: (Message.FileDeletedStatus) -> Void = { _ in
            pushCenter.post(PushFileUnauthorized(messageId: body.message.id,
                                                               fileDeletedStatus: body.message.fileDeletedStatus))
        }
        fileBrowseVC.fileHasNoAuthorize = fileHasNoAuthorize
        res.end(resource: fileBrowseVC)
    }

    private func showAlert(title: String? = nil, message: String, from: NavigatorFrom) {
        let alertController = LarkAlertController()
        if let title = title {
            alertController.setTitle(text: title)
        }
        alertController.setContent(text: message)
        alertController.addPrimaryButton(text: BundleI18n.LarkFile.Lark_Legacy_Sure)
        userResolver.navigator.present(alertController, from: from)
    }

    private func getMenuOptions(chat: Chat, message: Message, supportForwardCopy: Bool) -> FileBrowseMenuOptions {
        if chat.isCrypto {
            return []
        }
        let filter: (FileBrowseMenuOptions) -> FileBrowseMenuOptions = { options in
            var result = options
            if chat.enableRestricted(.forward) {
                result.remove(.forwardCopy)
            }
            if chat.enableRestricted(.download) {
                result.remove(.canSaveToAlbum)
                result.remove(.openWithOtherApp)
            }
            return result
        }
        if supportForwardCopy {
            return filter([.forwardCopy, .canSaveToAlbum, .openWithOtherApp])
        } else {
            return filter([.canSaveToAlbum, .openWithOtherApp])
        }
    }

    private func getChatType(by chat: Chat) -> String {
        let type: String
        if chat.isSingleBot {
            type = "single_bot"
        } else {
            switch chat.type {
            case .group:
                type = "group"
            case .p2P:
                type = "single"
            case .topicGroup:
                type = "topicGroup"
            @unknown default:
                assert(false, "new value")
                return "unknown"
            }
        }
        return type
    }

    private func trackOpenAttachCard(fileType: String) {
        Tracker.post(
            TeaEvent(
                "open_attach_card",
                category: "driver", params: [
                    "file_type": fileType
                ]
            )
        )
    }
}

final class FolderManagementHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { File.userScopeCompatibleMode }

    @ScopedInjectedLazy private var messageAPI: MessageAPI?
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    private let disposeBag = DisposeBag()
    private let fileNavigation: FileNavigation

    init(fileNavigation: FileNavigation, resolver: UserResolver) {
        self.fileNavigation = fileNavigation
        super.init(resolver: resolver)
    }

    func handle(_ body: FolderManagementBody, req: EENavigator.Request, res: Response) throws {
        guard let from = req.context.from() else {
            assertionFailure("缺少 From")
            return
        }

        if !userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteFileDownload)) {
            if let window = req.from.fromViewController?.view.window {
                UDToast.showTips(
                    with: BundleI18n.LarkFile.Lark_Chat_FileSecurityRestrictDownloadActionGeneralMessage,
                    on: window
                )
            }
            res.end(resource: EmptyResource())
            return
        }

        if let message = body.message {
            let resource = try self.syncHandle(with: message, body: body, from: from)
            res.end(resource: resource)
        } else {
            res.wait()
            messageAPI?.fetchMessage(id: body.messageId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self, weak from] (message) in
                    guard let self = self, let from = from else { return }
                    do {
                        let resource = try self.syncHandle(with: message, body: body, from: from)
                        res.end(resource: resource)
                    } catch {
                        res.end(error: error)
                    }
                }, onError: { (error) in
                    res.end(error: error)
                }).disposed(by: disposeBag)
        }
    }

    private func getFolderManagementConfiguration(
        chat: Chat,
        message: Message,
        scene: FileSourceScene,
        isOpeningInNewScene: Bool, //是否是分屏打开
        canViewInChat: Bool,
        canForward: Bool,
        canSearch: Bool
    ) -> FolderManagementConfiguration {
        let filter: (FolderManagementMenuOptions) -> FolderManagementMenuOptions = { options in
            var result = options
            if chat.enableRestricted(.forward) || !canForward {
                result.remove(.forward)
            }
            if message.isRestricted {
                result.remove(.openWithOtherApp)
            }
            if isOpeningInNewScene || !canViewInChat {
                result.remove(.viewInChat)
            }
            return result
        }
        let supportSearch: Bool
        let menuOptions: FolderManagementMenuOptions
        switch scene {
        case .favorite, .flag:
            supportSearch = false
            menuOptions = filter([.forward])
        case .chat, .search, .fileTab, .messageDetail:
            supportSearch = true
            menuOptions = filter([.forward, .viewInChat])
        case .mergeForward:
            supportSearch = false
            menuOptions = []
        case .pin:
            supportSearch = false
            menuOptions = filter([.forward, .viewInChat])
        case .forwardPreview:
            supportSearch = false
            menuOptions = []
        @unknown default:
            supportSearch = false
            menuOptions = []
        }
        return FolderManagementConfiguration(menuOptions: menuOptions,
                                             supportSearch: supportSearch && canSearch,
                                             disableAction: message.disabledAction)
    }

    private func syncHandle(with message: Message, body: FolderManagementBody, from: NavigatorFrom) throws -> Resource {
        guard message.type == .folder,
              self.fileNavigation.checkFileDeletedStatus(with: message, from: from) else {
            return EmptyResource()
        }

        let extra: [AnyHashable: Any]
        guard let chat = body.chatFromTodo ?? chatAPI?.getLocalChat(by: message.channel.id) else {
            return EmptyResource()
        }
        extra = IMTracker.Param.chat(chat)
        let folderMessageInfo = FolderMessageInfo(message: message, isFromZip: false, downloadFileScene: body.downloadFileScene, extra: extra)
        let configuration = self.getFolderManagementConfiguration(chat: chat,
                                                                  message: message,
                                                                  scene: body.scene,
                                                                  isOpeningInNewScene: body.isOpeningInNewScene,
                                                                  canViewInChat: body.canViewInChat,
                                                                  canForward: body.canForward,
                                                                  canSearch: body.canSearch)
        let subject = BehaviorSubject(value: FolderManagementViewController.localIsGridStyle)
        let viewWillTransitionSubject = PublishSubject<CGSize>()

        let contentView = FolderBrowserNavigationView(
            frame: .zero,
            dependency: FolderBrowserNavigationViewDependency(
                folderMessageInfo: folderMessageInfo,
                supportForwardCopy: configuration.menuOptions.contains(.forward),
                chatFromTodo: body.chatFromTodo,
                gridSubject: subject,
                viewWillTransitionSubject: viewWillTransitionSubject,
                pushCenter: try resolver.userPushCenter,
                sourceScene: body.scene,
                canFileClick: body.canFileClick,
                useLocalChat: body.useLocalChat
            ),
            resolver: userResolver,
            firstLevelInformation: body.firstLevelInformation
        )

        let folderManagementVC = FolderManagementViewController(
            configuration: configuration,
            gridSubject: subject,
            viewWillTransitionSubject: viewWillTransitionSubject,
            contentView: contentView,
            sourceScene: body.scene,
            extra: extra,
            userResolver: userResolver
        )
        folderManagementVC.router = contentView
        contentView.targetVC = folderManagementVC
        return folderManagementVC
    }
}

public typealias FileDependency = MDFileDependency & DriveSDKFileDependency

public final class FileAssembly: LarkAssemblyInterface {

    public func registContainer(container: Container) {
        let user = container.inObjectScope(File.userScope)
        let userGraph = container.inObjectScope(File.userGraph)

        user.register(FileDownloadCenter.self) { r in FileDownloadCenter(userResolver: r) }

        userGraph.register(FileMessageInfoService.self) { r in FileMessageInfoProtocolImpl(userID: r.userID) }

        userGraph.register(MDFileDependency.self) { (r) -> MDFileDependency in
            try r.resolve(assert: FileDependency.self)
        }

        userGraph.register(DriveSDKFileDependency.self) { (r) -> DriveSDKFileDependency in
            try r.resolve(assert: FileDependency.self)
        }

        userGraph.register(LocalFileFetchService.self) { (r) -> LocalFileFetchService in
            LocalFileFetchServiceImpl(userID: r.userID)
        }

        user.register(FileUtilService.self) { (r) -> FileUtilService in
            FileUtilServiceImp(resolver: r)
        }

        userGraph.register(DriveSDKDependencyBridge.self) { (r, message: Message, fileInfo: FileContentBasicInfo?, browseFromWhere: FileBrowseFromWhere) -> DriveSDKDependencyBridge in
            DriveSDKDependencyImpl(message: message,
                                   fileInfo: fileInfo,
                                   browseFromWhere: browseFromWhere,
                                   resolver: r,
                                   pushCenter: try r.userPushCenter,
                                   passportUserService: try r.resolve(assert: PassportUserService.self))
        }

        userGraph.register(DriveSDKLocalDependencyBridge.self) { (r, messageId: String) -> DriveSDKLocalDependencyBridge in
            DriveSDKLocalDependencyImpl(messageId: messageId, pushCenter: try r.userPushCenter, passportUserService: try r.resolve(assert: PassportUserService.self))
        }

        user.register(RustEncryptFileDecodeService.self) { (r) -> RustEncryptFileDecodeService in
            return try RustEncryptFileDecodeServiceImpl(userResolver: r)
        }
    }

    public func registRouter(container: Container) {

        Navigator.shared.registerRoute.type(MessageFileBrowseBody.self).factory(cache: true, { r in
            MessageFileBrowseHandler(fileNavigation: FileNavigation(resolver: r), resolver: r)
        })

        Navigator.shared.registerRoute.type(LocalFileBody.self).factory { r in
            return LocalFileHandler(fileNavigation: FileNavigation(resolver: r), resolver: r)
        }

        Navigator.shared.registerRoute.type(RiskFileAppealBody.self).factory(RiskFileAppealHandler.init)

        Navigator.shared.registerRoute.type(MessageFolderFileBrowseBody.self).factory { r in
            return MessageFolderFileBrowseHandler(fileNavigation: FileNavigation(resolver: r), resolver: r)
        }

        Navigator.shared.registerRoute.type(FolderManagementBody.self).factory(cache: true, { r in
            FolderManagementHandler(fileNavigation: FileNavigation(resolver: r), resolver: r)
        })
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(TempDecodeFileCleanTask.self)
    }

    public init() {}
}

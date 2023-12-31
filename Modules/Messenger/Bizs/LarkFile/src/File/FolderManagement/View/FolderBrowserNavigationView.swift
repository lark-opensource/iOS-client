//
//  FolderBrowserNavigationView.swift
//  LarkFile
//
//  Created by 赵家琛 on 2021/4/8.
//

import UIKit
import Foundation
import LarkUIKit
import LarkMessengerInterface
import EENavigator
import LarkModel
import LarkContainer
import LarkSDKInterface
import RxSwift
import LarkCore
import LarkKASDKAssemble
import RustPB
import LarkFeatureGating
import LarkLocalizations

struct FolderBrowserNavigationViewDependency {
    let folderMessageInfo: FolderMessageInfo
    let supportForwardCopy: Bool
    let chatFromTodo: Chat?
    let gridSubject: BehaviorSubject<Bool>
    let viewWillTransitionSubject: PublishSubject<CGSize>
    let pushCenter: PushNotificationCenter
    let sourceScene: FileSourceScene
    // Office文件类型的鉴权涉及其他业务，消息链接化场景暂时屏蔽Office文件类型的点击事件（三端对齐）
    let canFileClick: ((_ fileName: String) -> Bool)?
    // 消息链接化场景无权限时（如单聊时转发出去的无权限消息链接）可能拉不到chat，使用内存中的Chat
    let useLocalChat: Bool

    var authToken: String? {
        if folderMessageInfo.message.type == .file, let content = folderMessageInfo.message.content as? FileContent {
            return content.authToken
        } else if folderMessageInfo.message.type == .folder, let content = folderMessageInfo.message.content as? FolderContent {
            return content.authToken
        }
        return nil
    }
    var authFileKey: String {
        if folderMessageInfo.message.type == .file, let content = folderMessageInfo.message.content as? FileContent {
            return content.key
        } else if folderMessageInfo.message.type == .folder, let content = folderMessageInfo.message.content as? FolderContent {
            return content.key
        }
        return ""
    }
}

final class FolderBrowserNavigationView: NavigationView, UserResolverWrapper {
    @ScopedInjectedLazy private var driveDependency: DriveSDKFileDependency?
    @ScopedInjectedLazy private var fileUtil: FileUtilService?
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy var fileAPI: SecurityFileAPI?

    let userResolver: UserResolver
    private let disposeBag = DisposeBag()
    private let dependency: FolderBrowserNavigationViewDependency

    weak var targetVC: FolderManagementViewController? {
        didSet {
            topViewControllerChanged()
        }
    }

    private var trackerCommonParams: [AnyHashable: Any] {
        var params: [AnyHashable: Any] = dependency.folderMessageInfo.extra
        switch dependency.sourceScene {
        // 消息-文件夹
        case .chat, .messageDetail:
            params["source"] = "from_msg_folder"
        // 文件tab
        case .fileTab:
            params["source"] = "from_file_tab"
        // 搜索侧文件夹
        case .search:
            params["source"] = "from_search_folder"
        // 其他
        default:
            params["source"] = "other"
        }
        params["page_type"] = "folder_view"
        return params
    }

    init(frame: CGRect,
         dependency: FolderBrowserNavigationViewDependency,
         resolver: UserResolver,
         rootVC: BaseFolderBrowserViewController? = nil,
         firstLevelInformation: FolderFirstLevelInformation? = nil) {
        self.dependency = dependency
        self.userResolver = resolver
        var rootVC = rootVC
        if rootVC == nil {
            var firstLevelInformation = firstLevelInformation
            if firstLevelInformation == nil,
               let folderContent = dependency.folderMessageInfo.message.content as? FolderContent {
                firstLevelInformation = FolderFirstLevelInformation(
                    key: folderContent.key,
                    authToken: folderContent.authToken,
                    authFileKey: folderContent.key,
                    name: folderContent.name,
                    size: folderContent.size
                )
            }
            if let firstLevelInformation = firstLevelInformation {
                let extra = dependency.folderMessageInfo.extra
                rootVC = FolderBrowserViewController(
                    viewModel: FolderBrowserViewModel(
                        key: firstLevelInformation.key,
                        authToken: firstLevelInformation.authToken,
                        authFileKey: firstLevelInformation.authFileKey,
                        name: firstLevelInformation.name,
                        size: firstLevelInformation.size,
                        downloadFileScene: dependency.folderMessageInfo.downloadFileScene,
                        gridSubject: dependency.gridSubject,
                        resolver: userResolver
                    ),
                    displayTopContainer: true,
                    viewWillTransitionSubject: dependency.viewWillTransitionSubject,
                    loadFristScreenDataSuccess: { _ in
                        /// 上报埋点
                        IMTracker.FileManage.View(extra: dependency.folderMessageInfo.extra,
                                                  sourceScene: dependency.sourceScene)
                    }
                )
            }
        }
        super.init(
            frame: frame,
            root: rootVC ?? UIViewController()
        )
        rootVC?.router = self
        sourceChangedHandler = { [weak self] sourceCount in
            self?.topViewControllerChanged()
            // 面包屑层级为 1 时才允许响应 VC 侧滑手势
            self?.targetVC?.naviPopGestureRecognizerEnabled = sourceCount < 2
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func topViewControllerChanged() {
        guard let targetVC = self.targetVC,
              let topVC = sources.last as? BaseFolderBrowserViewController else {
            return
        }
        targetVC.updateNavigationButton(styleButtonisHidden: topVC.getStyleButtonisHidden(),
                                        canOpenWithOtherApp: topVC.getCanOpenWithOtherApp())
    }
}

// MARK: - FolderBrowserRouter
extension FolderBrowserNavigationView: FolderBrowserRouter {
    //返回当前最上层viewController对应的文件类型（埋点用）
    func getTopVCFileType() -> FileType {
        if (currentSource as? UnzipViewController) != nil {
            return .compress_file
        }
        return .folder
    }
    func onVCStatusChanged(_ vc: BaseFolderBrowserViewController) {
        if vc == currentSource {
            topViewControllerChanged()
        }
    }
    func updateNavigationButton(styleButtonisHidden: Bool, canOpenWithOtherApp: Bool) {
        targetVC?.updateNavigationButton(styleButtonisHidden: styleButtonisHidden, canOpenWithOtherApp: canOpenWithOtherApp)
    }

    func didSelectFile(key: String, name: String, size: Int64, previewStage: Basic_V1_FilePreviewStage) {
        guard let from = self.targetVC else {
            assertionFailure("can not find from")
            return
        }
        if let canFileClick = dependency.canFileClick, !canFileClick(name) {
            return
        }
        let fileInfo = FileFromFolderBasicInfo(
            key: key,
            authToken: dependency.authToken,
            authFileKey: dependency.authFileKey,
            size: size,
            name: name,
            cacheFilePath: "",
            filePreviewStage: previewStage
        )
        let isPreviewableZip = fileUtil?.fileIsPreviewableZip(fileName: name, fileSize: size) ?? false
        IMTracker.FileManage.Click.singleFile(extra: self.trackerCommonParams,
                                              fileType: isPreviewableZip ? .compress_file : .file)
        if FilePreviewers.canPreviewFileName(name) ||
            !(driveDependency?.canOpenSDKPreview(fileName: name, fileSize: size) ?? false) ||
            dependency.folderMessageInfo.downloadFileScene == .todo || isPreviewableZip {
            let body = MessageFolderFileBrowseBody(
                message: dependency.folderMessageInfo.message,
                fileInfo: fileInfo,
                scene: self.dependency.sourceScene,
                downloadFileScene: dependency.folderMessageInfo.downloadFileScene,
                chatFromTodo: dependency.chatFromTodo,
                supportForwardCopy: dependency.supportForwardCopy,
                isPreviewableZip: isPreviewableZip
            )
            if isPreviewableZip {
                userResolver.navigator.getResource(body: body) { [weak self] resource in
                    guard let self = self else { return }
                    if let vc = resource as? UIViewController {
                        if let vc = vc as? BaseFolderBrowserViewController {
                            vc.router = self
                        }
                        self.push(source: vc)
                    }
                }
            } else {
                userResolver.navigator.push(body: body, from: from)
            }
        } else {
            var extra: [String: Any] = [:]
            if let downloadFileScene = dependency.folderMessageInfo.downloadFileScene {
                extra[FileBrowseFromWhere.DownloadFileSceneKey] = downloadFileScene
            }
            if case .favorite(let favoriteId) = dependency.sourceScene {
                extra[FileBrowseFromWhere.FileFavoriteKey] = favoriteId
            }
            driveDependency?.openSDKPreview(
                message: dependency.folderMessageInfo.message,
                chat: dependency.useLocalChat ? dependency.chatFromTodo : nil,
                fileInfo: fileInfo,
                from: from,
                supportForward: dependency.supportForwardCopy,
                canSaveToDrive: true,
                browseFromWhere: .folder(extra: extra)
            )
        }
    }

    func didSelectFolder(key: String, name: String, size: Int64, previewStage: Basic_V1_FilePreviewStage) {
        guard let from = self.targetVC else {
            assertionFailure("can not find from")
            return
        }
        IMTracker.FileManage.Click.singleFile(extra: self.trackerCommonParams,
                                              fileType: .folder)
        self.push(source: buildFolderBrowserViewController(key: key, name: name, size: size))
    }

    func buildFolderBrowserViewController(key: String, name: String, size: Int64, firstScreenData: Media_V1_BrowseFolderResponse? = nil) -> FolderBrowserViewController {
        let viewModel = FolderBrowserViewModel(key: key,
                                               authToken: dependency.authToken,
                                               authFileKey: dependency.authFileKey,
                                               name: name,
                                               size: size,
                                               downloadFileScene: dependency.folderMessageInfo.downloadFileScene,
                                               gridSubject: dependency.gridSubject,
                                               firstScreenData: firstScreenData,
                                               resolver: userResolver)
        let browseVC = FolderBrowserViewController(viewModel: viewModel,
                                                   viewWillTransitionSubject: dependency.viewWillTransitionSubject)
        browseVC.router = self
        IMTracker.FileManage.View(extra: trackerCommonParams,
                                  sourceScene: dependency.sourceScene)
        return browseVC
    }

    func forwardCopy() {
        guard let from = self.targetVC else {
            assertionFailure("can not find from")
            return
        }
        IMTracker.FileManage.More.Click.forwardCopy(extra: self.trackerCommonParams,
                                                    fileType: getTopVCFileType())
        guard let hierarchyFolderInfo = self.currentSource as? HierarchyFolderInfoProtocol else {
            return
        }

        let body = ForwardCopyFromFolderMessageBody(
            folderMessageId: dependency.folderMessageInfo.message.id,
            key: hierarchyFolderInfo.key,
            name: hierarchyFolderInfo.name,
            size: hierarchyFolderInfo.size,
            copyType: dependency.folderMessageInfo.isFromZip ? .zip : .folder
        )
        userResolver.navigator.present(body: body, from: from, prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
    }

    func goChat() {
        IMTracker.FileManage.More.Click.jumpToChat(extra: self.trackerCommonParams,
                                                   fileType: getTopVCFileType())
        guard let from = self.targetVC else {
            assertionFailure("can not find from")
            return
        }

        self.chatAPI?.fetchChat(by: dependency.folderMessageInfo.message.channel.id, forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chat) in
                guard let self = self, let chat = chat else { return }

                let message = self.dependency.folderMessageInfo.message
                if chat.chatMode == .threadV2 {
                    let body = ThreadDetailByIDBody(threadId: message.threadId,
                                                    loadType: .position,
                                                    position: message.threadPosition)
                    self.userResolver.navigator.push(body: body, from: from)
                    return
                }

                let body = ChatControllerByIdBody(
                    chatId: message.channel.id,
                    position: message.position,
                    messageId: message.id
                )
                self.userResolver.navigator.push(body: body, from: from)
            }).disposed(by: disposeBag)
    }

    func canDownloadFile(file: FileMessageInfo) -> Observable<Bool> {
        // 文件安全检测
        let shouldDetectFile = userResolver.fg.staticFeatureGatingValue(with: "messenger.file.detect")
        if !shouldDetectFile {
            return .just(true)
        }
        guard let fileAPI = fileAPI else { return Observable.just(true) }
        return fileAPI.canDownloadFile(
            detectRiskFileMeta: DetectRiskFileMeta(key: file.fileKey, messageRiskObjectKeys: file.riskObjectKeys)
        )
    }

    func openWithOtherApp() {
        IMTracker.FileManage.More.Click.openWithOtherApp(extra: self.trackerCommonParams, fileType: getTopVCFileType())
        guard let topVC = sources.last as? UnzipViewController else {
            return
        }
        canDownloadFile(file: topVC.viewModel.file)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] canDownload in
                guard let self = self,
                      let topVC = self.sources.last as? UnzipViewController,
                      let targetVC = self.targetVC else {
                    return
                }
                if !canDownload {
                    let body = RiskFileAppealBody(fileKey: topVC.viewModel.file.fileKey,
                                                  locale: LanguageManager.currentLanguage.rawValue)
                    self.userResolver.navigator.present(body: body, from: targetVC)
                } else {
                    let fileInfo = FileFromFolderBasicInfo(key: topVC.viewModel.file.fileKey,
                                                           authToken: topVC.viewModel.file.authToken,
                                                           authFileKey: topVC.viewModel.file.authFileKey,
                                                           size: topVC.viewModel.file.fileSize,
                                                           name: topVC.viewModel.file.fileName,
                                                           cacheFilePath: "",
                                                           filePreviewStage: topVC.viewModel.file.filePreviewStage)
                    let body = MessageFolderFileBrowseBody(message: self.dependency.folderMessageInfo.message,
                                                           fileInfo: fileInfo,
                                                           scene: self.dependency.sourceScene,
                                                           downloadFileScene: self.dependency.folderMessageInfo.downloadFileScene,
                                                           chatFromTodo: self.dependency.chatFromTodo,
                                                           supportForwardCopy: self.dependency.supportForwardCopy,
                                                           isPreviewableZip: false)
                    self.userResolver.navigator.push(body: body, from: targetVC)
                }
            })
            .disposed(by: disposeBag)
    }

    func goSearch() {
        guard let from = self.targetVC else {
            assertionFailure("can not find from")
            return
        }
        IMTracker.FileManage.Click.search(extra: self.trackerCommonParams)
        chatAPI?.fetchChat(by: dependency.folderMessageInfo.message.channel.id, forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chat) in
                guard let chat = chat else { return }
                let body = SearchInChatSingleBody(chatId: chat.id, type: .file, chatType: chat.type)
                if Display.pad {
                    var params = NaviParams()
                    params.forcePush = true
                    self.userResolver.navigator.push(body: body, naviParams: params, from: from)
                } else {
                    self.userResolver.navigator.present(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .fullScreen }
                    )
                }
            })
            .disposed(by: disposeBag)
    }
}

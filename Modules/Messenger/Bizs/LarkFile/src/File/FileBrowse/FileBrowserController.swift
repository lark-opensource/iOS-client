//
//  FileBrowserController.swift
//  Lark
//
//  Created by linlin on 2017/3/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import Homeric
import AVKit
import AVFoundation
import LarkActionSheet
import MobileCoreServices
import RxSwift
import LarkFoundation
import LarkModel
import Reachability
import LKCommonsLogging
import LKCommonsTracker
import LarkUIKit
import RxCocoa
import LarkCore
import WebKit
import UniverseDesignToast
import EENavigator
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureSwitch
import SuiteAppConfig
import LarkExtensions
import LarkContainer
import LarkFeatureGating
import LarkMedia
import WebBrowser
import LarkAlertController
import LarkCache
import LarkSplitViewController
import RustPB
import LarkReleaseConfig
import LarkKASDKAssemble
import SnapKit
import LarkLocalizations

public protocol MDFileDependency {
    func jumpToSpace(fileURL: URL, name: String?, fileType: String?, from: UIViewController)
    func showQuataAlertFromVC(_ vc: UIViewController)
}

struct FileViewOptions: OptionSet {
    public let rawValue: Int
    //是否使用drive本地预览组件
    public static let driveLocalPreview = FileViewOptions(rawValue: 1 << 0)
    //是否使用sdk缓存
    public static let SDKCache = FileViewOptions(rawValue: 1 << 1)
    //是否支持sdk加密缓存, SDKCacheCrypto能力包含SDKCache，同时支持加密. 与SDKCache均设置时，采用SDKCacheCrypto
    public static let SDKCacheCrypto = FileViewOptions(rawValue: 1 << 2)
}

final class FileBrowserController: LocalWebBrowserController, LoadingWKNavigationDelegate, UIDocumentInteractionControllerDelegate, UserResolverWrapper {
    // AudioSession 管理
    private static let audioScenario = AudioSessionScenario("lark.audio.fileBrowser", category: .playback)
    private let audioQueue = DispatchQueue(label: "lark.audio.fileBrowser.queue", qos: .userInteractive)

    static let logger = Logger.log(FileBrowserController.self, category: "Module.IM.Message")

    typealias ShowActionInfo = (showAction: Bool, sourceView: UIView?)

    // DATA
    private var file: FileMessageInfo
    private let menuOptions: FileBrowseMenuOptions
    private let fileViewOptions: FileViewOptions
    private var context: [String: Any]

    // API
    @ScopedInjectedLazy var chatAPI: ChatAPI?
    @ScopedInjectedLazy var chatSecurityAuditService: ChatSecurityAuditService?
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?

    private let fileAPI: SecurityFileAPI
    private let favoriteAPI: FavoritesAPI
    private let messageAPI: MessageAPI
    private let trackUtils: FileTrackUtil
    private let spaceStoreDriver: Driver<PushSaveToSpaceStoreState>
    private let fileDownloadTask: FileDownloadTask
    private let fileNavigation: FileNavigation
    private let messageDriver: Driver<PushChannelMessage>

    // View
    private let downloadView: FileDownloadView

    var operationEvent: ((FileOperationEvent) -> Void)?
    var fileHasNoAuthorize: ((Message.FileDeletedStatus) -> Void)?

    private var downloadDisposeBag = DisposeBag()
    private let disposeBag = DisposeBag()
    let userResolver: UserResolver

    @ScopedInjectedLazy private var dependency: FileDependency?
    @ScopedInjectedLazy private var fileDecodeService: RustEncryptFileDecodeService?
    @ScopedInjectedLazy private var passportUserService: PassportUserService?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if downloadView.alpha == 0 {
            return .allButUpsideDown
        } else {
            return .portrait
        }
    }
    lazy var isFeishuBrand: Bool = {
        passportUserService?.isFeishuBrand ?? true
    }()

    var url: URL
    let downloadCenter: FileDownloadCenter
    init(file: FileMessageInfo,
         menuOptions: FileBrowseMenuOptions,
         fileViewOptions: FileViewOptions,
         fileAPI: SecurityFileAPI,
         favoriteAPI: FavoritesAPI,
         messageAPI: MessageAPI,
         spaceStoreStateDriver: Driver<PushSaveToSpaceStoreState>,
         downloadFileDriver: Driver<PushDownloadFile>,
         messageDriver: Driver<PushChannelMessage>,
         fileNavigation: FileNavigation,
         context: [String: Any],
         appConfigService: AppConfigService,
         resolver: UserResolver) throws {

        self.file = file
        self.url = file.fileLocalURL
        self.menuOptions = menuOptions
        self.fileViewOptions = fileViewOptions

        self.fileAPI = fileAPI
        self.favoriteAPI = favoriteAPI
        self.messageAPI = messageAPI
        self.trackUtils = FileTrackUtil()
        self.spaceStoreDriver = spaceStoreStateDriver
        self.messageDriver = messageDriver
        self.userResolver = resolver
        var downloadSdkFileCacheStrategy: SDKFileCacheStrategy = .notUseSDKCache
        if fileViewOptions.contains(.SDKCache) {
            downloadSdkFileCacheStrategy = .SDKCache
        }
        //与SDKCache均设置时，采用SDKCacheCrypto
        if fileViewOptions.contains(.SDKCacheCrypto) {
            downloadSdkFileCacheStrategy = .SDKCacheCrypto
        }
        self.downloadCenter = try userResolver.resolve(assert: FileDownloadCenter.self)
        let task = downloadCenter.download(userID: userResolver.userID,
                                           file: file,
                                           fileAPI: fileAPI,
                                           sdkFileCacheStrategy: downloadSdkFileCacheStrategy,
                                           downloadFileDriver: downloadFileDriver,
                                           messageDriver: messageDriver)
        self.fileDownloadTask = task
        self.fileNavigation = fileNavigation
        self.context = context
        downloadView = FileDownloadView(icon: file.fileLadderIcon,
                                        name: file.fileName,
                                        size: file.fileSizeString,
                                        remainSize: {
                                            let size = task.remainDownloadSize
                                            return  ByteCountFormatter.string(fromByteCount: size, countStyle: .binary)
        })
        super.init(appConfigService: appConfigService)
        self.loadingNavigationDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        let scene: MediaMutexScene
        if case .video = file.fileFormat {
            scene = .imVideoPlay
        } else {
            scene = .imPlay
        }
        self.audioQueue.async {
            // 页面销毁时，恢复到上一个的audioAession状态
            LarkMediaManager.shared.unlock(scene: scene, options: .leaveScenarios)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.supportSecondaryOnly = true
        self.supportSecondaryPanGesture = true
        self.keyCommandToFullScreen = true
        self.autoAddSecondaryOnlyItem = true
        self.supportSecondaryOnlyButton = true
        self.fullScreenSceneBlock = { "file" }
        addRightBarButtonItemIfNeeded()

        title = file.fileName
        downloadView.delegate = self
        view.addSubview(downloadView)
        downloadView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        var isAutoDownload = false
        if !file.isFileExist, fileDownloadTask.currentStatus != .pause(byUser: true) {
            // 如果文件不存在，或者不是用户手动暂停，
            // wifi情况下，或者文件小于100m的时候，自动下载
            if Reachability()?.connection == .wifi || file.fileSize <= FileDownloadCenter.autoDonwloadSize {
                isAutoDownload = true
                Self.logger.info("file logic trace start autoDownload \(file.fileKey) \(file.messageId)")
                fileDownloadTask.start()
            }
        }

        Tracker.post(TeaEvent(Homeric.CLICK_FILE_IN_CHAT,
                              params: trackInfo.lf_update(["is_auto_download": isAutoDownload]))
            )

        fileDownloadTask.toast = { [weak self] text in
            guard let window = self?.view.window else { return }
            UDToast.showTips(with: text, on: window)
        }
        fileDownloadTask.statusObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (status) in
                guard let self = self else { return }
                FileTrackUtil.trackAppreciableDownload(task: self.fileDownloadTask, status: status)
                switch status {
                case .prepare:
                    self.downloadView.set(status: .prepareToDownload)
                case .downloading(progress: let progress, rate: let rate):
                    self.downloadView.set(status: .dowloading(percentage: progress, rate: rate))
                case .finish(_, let isCrypto):
                    Self.logger.info("file logic trace downloadFinish \(self.file.fileKey) \(self.file.messageId) \(isCrypto)")
                    self.downloadCenter.remove(task: self.fileDownloadTask)
                    if self.fileViewOptions.contains(.driveLocalPreview) {
                        if self.fileViewOptions.contains(.SDKCacheCrypto), isCrypto { //使用了sdk加密缓存，且被加密了
                            self.decodeFile()
                        } else {
                            self.openByLocalPreview(path: self.file.fileLocalURL)
                        }
                    } else {
                        self.addRightBarButtonItemIfNeeded()
                        self.openFile() // 下载完成后尝试打开文件
                        self.chatSecurityControlService?.downloadAsyncCheckAuthority(
                            event: .openInAnotherApp,
                            securityExtraInfo: SecurityExtraInfo(
                                senderUserId: (self.file.senderUserId as NSString).longLongValue,
                                senderTenantId: (self.file.senderTenantId as NSString).longLongValue)) { [weak self] authority in
                            guard let self else { return }
                            self.downloadView.set(status: .finish, authorityControlDeny: !authority.authorityAllowed)
                        }
                    }
                case .pause:
                    self.downloadView.set(status: .pause(percentage: self.fileDownloadTask.downloadedRatio))
                case .fail(error: let error):
                    FileBrowserController.logger.error(
                        "download file Fail",
                        additionalData: ["messageId": self.file.messageId],
                        error: error
                    )
                    switch error {
                    case .sourceFileBurned:
                        if let window = self.view.window {
                            UDToast.showFailure(with: BundleI18n.LarkFile.Lark_Legacy_FileHasBeenBurnedCanNotDownload, on: window)
                        }
                    case .sourceFileWithdrawn:
                        if let window = self.view.window {
                            UDToast.showFailure(with: BundleI18n.LarkFile.Lark_Legacy_FileHasBeenRecalledCanNotDownload, on: window)
                        }
                    // 文件被管理员删除
                    case .sourceFileShreddedByAdmin:
                        let alert = LarkAlertController()
                        alert.setContent(text: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogOver90Days)
                        alert.addPrimaryButton(text: BundleI18n.LarkFile.Lark_Legacy_IKnow, dismissCompletion: { [weak self] in
                            self?.popSelf()
                        })
                        self.userResolver.navigator.present(alert, from: self)
                    // 该文件已被管理员删除，如需找回，请联系管理员
                    case .sourceFileForzenByAdmin:
                        let alert = LarkAlertController()
                        alert.setContent(text: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogWithin90Days)
                        alert.addPrimaryButton(text: BundleI18n.LarkFile.Lark_Legacy_IKnow, dismissCompletion: { [weak self] in
                            self?.popSelf()
                        })
                        self.userResolver.navigator.present(alert, from: self)
                    case .sourceFileDeletedByAdminScript:
                        if let window = self.view.window {
                            UDToast.showFailure(with: BundleI18n.LarkFile.Lark_IM_ViewOrDownloadFile_FileDeleted_Text, on: window)
                        }
                    case .createDirFail, .downloadFail, .strategyControlDeny:
                        break
                    case  .downloadRequestFail(let errorCode):
                        Self.logger.error(
                            "downloadRequestFail: error_code:\(errorCode)",
                            additionalData: ["messageId": self.file.messageId],
                            error: error
                        )
                        break
                    // 管理员权限控制
                    case .securityControlDeny(_, let message):
                        switch self.file.fileFormat {
                        case .image:
                            self.chatSecurityControlService?.authorityErrorHandler(event: .saveImage, authResult: nil,
                                                                                  from: self,
                                                                                  errorMessage: message)
                        case .video:
                            self.chatSecurityControlService?.authorityErrorHandler(event: .saveVideo, authResult: nil,
                                                                                  from: self,
                                                                                  errorMessage: message)
                        default:
                            self.chatSecurityControlService?.authorityErrorHandler(event: .saveFile, authResult: nil,
                                                                                  from: self,
                                                                                  errorMessage: message)
                        }
                    /// 风险文件禁止下载
                    case .clientErrorRiskFileDisableDownload:
                        if let window = self.view.window {
                            let body = RiskFileAppealBody(fileKey: self.file.fileKey,
                                                          locale: LanguageManager.currentLanguage.rawValue)
                            self.userResolver.navigator.present(body: body, from: window)
                        }
                    }
                    self.downloadView.set(status: .fail)
                }
            })
            .disposed(by: disposeBag)

        // 更新message 获取最新cacheFilePath
        messageDriver
            .drive(onNext: { [weak self] (message) in
                guard let self = self, self.fileViewOptions.contains(.SDKCache) || self.fileViewOptions.contains(.SDKCacheCrypto) else { return }
                if message.message.id == self.file.messageId {
                    self.file.updateMessage(message.message)
                }
            })
            .disposed(by: disposeBag)
    }

    private func decodeFile() {
        self.downloadView.set(status: .decode)
        self.fileDecodeService?.decode(fileKey: self.file.fileKey, fileType: self.file.pathExtension, sourcePath: self.file.fileLocalURL, finish: { [weak self] result in
            switch result {
            case .success(let path):
                self?.openByLocalPreview(path: path)
            case .failure(let error):
                self?.downloadView.set(status: .decodeFail)
            }
        })
    }

    private func openByLocalPreview(path: URL) {
        guard let nav = self.navigationController, let dependency = self.dependency else {
            return
        }
        let drivePreviewVC = dependency.getLocalPreviewController(
            fileName: self.file.fileName,
            fileType: self.file.pathExtension,
            fileUrl: path,
            fileID: self.file.fileKey,
            messageId: self.file.messageId
        )
        userResolver.navigator.pop(from: self, animated: false) {
            self.userResolver.navigator.push(drivePreviewVC, from: nav, animated: false)
        }
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        /// 修复 iPad 中切换屏幕宽度的时候
        /// AVFullScreenController 导致 NavigaionBar 显示错误问题
        if parent == nil,
            let presentedViewController = self.presentedViewController {
            presentedViewController.dismiss(animated: false, completion: nil)
        }
    }

    /// 专门打点用的属性
    private var trackInfo: [String: Any] {
        var subContext: [String: Any] = [:]
        if let locationValue = self.context["location"] {
            subContext["location"] = locationValue
        }
        if let typeValue = self.context["chat_type"] {
            subContext["chat_type"] = typeValue
        }
        var params: [String: Any] = [:]
        params["file_ext"] = (file.fileName as NSString).pathExtension
        params["file_size"] = Double(file.fileSize) / 1024.0
        return params.lf_update(subContext)
    }

    private func addRightBarButtonItemIfNeeded() {
        if availableMenuItems() > 1 {
            let rightBarButtonItem = LKBarButtonItem(image: Resources.more)
            self.navigationItem.rightBarButtonItems = [rightBarButtonItem]
            rightBarButtonItem.button.addTarget(self, action: #selector(rightBarButtonItemClicked(sender:)), for: .touchUpInside)
        } else {
            navigationItem.rightBarButtonItems = []
        }
    }

    @discardableResult
    private func availableMenuItems(info: ShowActionInfo = (false, nil)) -> Int {
        var itemCount = 0
        let actionSheetAdapter = info.showAction ? ActionSheetAdapter() : nil
        let reminderLevel: ReminderLevel
        if let sourceView = info.sourceView {
            reminderLevel = .normal(source: sourceView.defaultSource)
        } else {
            reminderLevel = .high(view: self.view)
        }
        let actionSheet = actionSheetAdapter?.create(level: reminderLevel)

        // 文件存在，并且可以用Lark打开，展示用其他应用打开
        if menuOptions.contains(.openWithOtherApp) {
            if file.isFileExist, file.fileFormat.isCompatible {
                itemCount += 1
                chatSecurityControlService?.downloadAsyncCheckAuthority(
                    event: .openInAnotherApp,
                    securityExtraInfo: SecurityExtraInfo(
                        senderUserId: (self.file.senderUserId as NSString).longLongValue,
                        senderTenantId: (self.file.senderTenantId as NSString).longLongValue)) { [weak self] authority in
                    if authority.authorityAllowed {
                        actionSheetAdapter?.addItem(title: BundleI18n.LarkFile.Lark_Legacy_OpenInAnotherApp) { [weak self] in
                            self?.openWithOtherApp()
                        }
                    } else {
                        actionSheetAdapter?.addItem(title: BundleI18n.LarkFile.Lark_Legacy_OpenInAnotherApp,
                                                    textColor: UIColor.ud.N400) { [weak self] in
                            guard let self = self else { return }
                            self.chatSecurityControlService?.authorityErrorHandler(event: .openInAnotherApp,
                                                                                  authResult: authority,
                                                                                  from: self)
                        }
                    }
                }
            }
        }

        if menuOptions.contains(.canSaveToAlbum) && file.canSaveToAlbum {
            itemCount += 1
            actionSheetAdapter?.addItem(title: BundleI18n.LarkFile.Lark_Legacy_SaveToAlbum) { [weak self] in
                self?.saveToAlbum()
            }
        }

        if menuOptions.contains(.canSaveFileToDrive) {
            itemCount += 1
            actionSheetAdapter?.addItem(title: BundleI18n.LarkFile.Lark_Legacy_SaveFileToDrive) { [weak self] in
                self?.saveToCloudDisk()
            }
        }

        if menuOptions.contains(.forward) {
            itemCount += 1
            actionSheetAdapter?.addItem(title: BundleI18n.LarkFile.Lark_Legacy_ForwardToChat) { [weak self] in
                guard let self = self else { return }
                self.fileNavigation.gotoForward(messageId: self.file.messageId, from: self)
            }
        }

        if self.menuOptions.contains(.favorite) {
            itemCount += 1
            actionSheetAdapter?.addItem(title: BundleI18n.LarkFile.Lark_Legacy_SaveFavorite) { [weak self] in
                self?.favorite()
            }
        }

        if menuOptions.contains(.viewInChat) {
            itemCount += 1
            actionSheetAdapter?.addItem(title: BundleI18n.LarkFile.Lark_Legacy_ViewInChat) { [weak self] in
                guard let self = self else { return }
                self.operationEvent?(.viewFileInChat)
                self.fileNavigation.goChat(messageId: self.file.messageId, from: self)
            }
        }

        if menuOptions.contains(.forwardCopy) {
            itemCount += 1
            actionSheetAdapter?.addItem(title: BundleI18n.LarkFile.Lark_Legacy_ForwardToChat) { [weak self] in
                guard let self = self else { return }
                let body = ForwardCopyFromFolderMessageBody(folderMessageId: self.file.messageId, key: self.file.fileKey, name: self.file.fileName, size: self.file.fileSize, copyType: .file)
                self.userResolver.navigator.present(body: body, from: self, prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
            }
        }

        itemCount += 1
        actionSheetAdapter?.addCancelItem(title: BundleI18n.LarkFile.Lark_Legacy_Cancel)

        if info.showAction,
            let actionSheet = actionSheet {
            userResolver.navigator.present(actionSheet, from: self)
        }

        return itemCount
    }

    @objc
    private func rightBarButtonItemClicked(sender: UIButton) {
        availableMenuItems(info: (true, sender))
    }

    // MARK: 用其他应用打开
    private var documentIteractionController: UIDocumentInteractionController?
    private func openWithOtherApp(rect: CGRect? = nil) {
        guard !LarkCache.isCryptoEnable() else {
            if let window = self.view.window {
                UDToast.showFailure(with: BundleI18n.LarkFile.Lark_Core_SecuritySettingCannotShare, on: window)
            }
            return
        }

        Tracker.post(TeaEvent(Homeric.OPEN_IN_ANOTHER_APP,
                              params: trackInfo)
        )
        let iteractionController = UIDocumentInteractionController()
        self.documentIteractionController = iteractionController
        iteractionController.url = URL(fileURLWithPath: file.fileOriginPath)
        iteractionController.delegate = self
        iteractionController.presentOptionsMenu(from: rect ?? self.view.bounds, in: self.view, animated: true)
    }

    func documentInteractionController(_ controller: UIDocumentInteractionController, willBeginSendingToApplication application: String?) {
        self.chatAPI?.fetchChat(by: self.file.channelId, forceRemote: false)
            .subscribe(onNext: { [weak self] (chat) in
                guard let self = self, let chat = chat else { return }
                self.chatSecurityAuditService?.auditEvent(.fileOpenedWith3rdApp(chatId: self.file.channelId,
                                                                               chatType: chat.type,
                                                                               fileId: self.file.fileKey,
                                                                               fileType: (self.file.fileName as NSString).pathExtension,
                                                                               appId: application ?? ""),
                                                         isSecretChat: chat.isCrypto)
            }).disposed(by: self.disposeBag)
    }

    // MARK: 保存到相册
    private func saveToAlbum() {
        self.chatSecurityAuditService?.auditEvent(.downloadFile(key: self.file.fileKey),
                                                    isSecretChat: self.file.isCrptoMessage)
        guard file.canSaveToAlbum, let window = self.view.window else { return }
        switch file.fileFormat {
        case .video:
            let hideHUD = self.showLoadingHud()
            chatSecurityControlService?.downloadAsyncCheckAuthority(
                event: .saveVideo,
                securityExtraInfo: SecurityExtraInfo(
                    senderUserId: (self.file.senderUserId as NSString).longLongValue,
                    senderTenantId: (self.file.senderTenantId as NSString).longLongValue)) { [weak self] authority in
                guard let self = self else { return }
                guard authority.authorityAllowed else {
                    hideHUD()
                    self.chatSecurityControlService?.authorityErrorHandler(event: .saveVideo,
                                                                          authResult: authority,
                                                                          from: self)
                    return
                }
                guard !LarkCache.isCryptoEnable() else {
                    hideHUD()
                    UDToast.showFailure(with: BundleI18n.LarkFile.Lark_Core_SecuritySettingCannotShare, on: window)
                    return
                }
                try? Utils.saveVideo(token: FileToken.saveVideo.token, url: self.file.fileLocalURL) { (isSuccess, _) in
                    hideHUD()
                    if isSuccess {
                        UDToast.showSuccess(with: BundleI18n.LarkFile.Lark_Legacy_FileBrowserSaveSuccess, on: window)
                    } else {
                        UDToast.showFailure(with: BundleI18n.LarkFile.Lark_Legacy_FileBrowserSaveFail, on: window)
                    }
                }
            }
        case .image:
            let hideHUD = self.showLoadingHud()
            chatSecurityControlService?.downloadAsyncCheckAuthority(
                event: .saveImage,
                securityExtraInfo: SecurityExtraInfo(
                    senderUserId: (self.file.senderUserId as NSString).longLongValue,
                    senderTenantId: (self.file.senderTenantId as NSString).longLongValue)) { [weak self] authority in
                guard let self = self else { return }
                guard authority.authorityAllowed else {
                    hideHUD()
                    self.chatSecurityControlService?.authorityErrorHandler(event: .saveImage,
                                                                     authResult: authority,
                                                                     from: self)
                    return
                }

                guard !LarkCache.isCryptoEnable() else {
                    hideHUD()
                    UDToast.showFailure(with: BundleI18n.LarkFile.Lark_Core_SecuritySettingCannotShare, on: window)
                    return
                }
                guard let image = UIImage.read_(from: self.file.fileLocalPath) else {
                    hideHUD()
                    return
                }
                try? Utils.savePhoto(token: FileToken.savePhoto.token, image: image) { (isSuccess, _) in
                    hideHUD()
                    if isSuccess {
                        UDToast.showSuccess(with: BundleI18n.LarkFile.Lark_Legacy_FileBrowserSaveSuccess, on: window)
                    } else {
                        UDToast.showFailure(with: BundleI18n.LarkFile.Lark_Legacy_FileBrowserSaveFail, on: window)
                    }
                }
            }
        default:
            break
        }
    }

    // MARK: 保存到云盘
    private func saveToCloudDisk() {
        operationEvent?(.saveToDrive)
        guard !file.messageId.isEmpty else { return }
        self.chatAPI?.fetchChat(by: self.file.channelId, forceRemote: false)
            .subscribe(onNext: { [weak self] (chat) in
                guard let self = self, let chat = chat else { return }
                self.chatSecurityAuditService?.auditEvent(.saveToSpace(chatId: self.file.channelId,
                                                                      chatType: chat.type,
                                                                      fileId: self.file.fileKey,
                                                                      fileName: self.file.fileName,
                                                                      fileType: self.file.pathExtension),
                                                         isSecretChat: self.file.isCrptoMessage)
            }).disposed(by: self.disposeBag)
        trackUtils.trackAttachedFileSaveToCloudDisk(fileType: file.pathExtension,
                                                    chatType: self.context["chat_type"] as? String,
                                                    chatID: self.context["chat_id"] as? String,
                                                    messageId: file.messageId)
        let hud = UDToast.showLoading(with: BundleI18n.LarkFile.Lark_Legacy_SavingFileToDrive, on: view, disableUserInteraction: true)

        spaceStoreDriver
            .drive(onNext: { [weak self] (push) in
                hud.remove()
                guard let `self` = self, let window = self.view.window else { return }
                hud.remove()
                if push.state != .success {
                    UDToast.showFailure(with: BundleI18n.LarkFile.Lark_Legacy_FriendRequestSendFailed, on: window)
                } else {
                    UDToast.showSuccess(with: BundleI18n.LarkFile.Lark_Legacy_SavedFileToDrive, on: window)
                }
                self.trackUtils.trackAttachedFileCloudDiskSaveFinish(fileType: self.file.pathExtension,
                                                                     isSuccess: push.state == .success,
                                                                     fileSize: Int(self.file.fileSize))
            })
            .disposed(by: self.disposeBag)

        fileAPI.saveFileToSpaceStore(messageId: file.messageId, chatId: file.channelId, key: file.fileKey, sourceType: file.messageSourceType, sourceID: file.messageSourceId)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] (error) in
                guard let self = self else { return }
                if let apiError = error.underlyingError as? APIError {
                    switch apiError.type {
                    case .resourceHasBeenRemoved:
                        UDToast.showFailure(
                            with: BundleI18n.LarkFile.Lark_Legacy_FileSourceDelete,
                            on: self.view,
                            error: error
                        )
                        self.fileHasNoAuthorize?(.recalled)
                    case .staticResourceFrozenByAdmin:
                        UDToast.showFailure(
                            with: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogOver90Days,
                            on: self.view,
                            error: error
                        )
                        self.fileHasNoAuthorize?(.recoverable)
                    case .staticResourceShreddedByAdmin:
                        UDToast.showFailure(
                            with: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogWithin90Days,
                            on: self.view,
                            error: error
                        )
                        self.fileHasNoAuthorize?(.unrecoverable)
                    case .storageSpaceReachedLimit:
                        hud.remove()
                        if self.isFeishuBrand {
                            self.dependency?.showQuataAlertFromVC(self)
                        } else {
                            /// 海外租户
                            UDToast.showFailure(
                                with: BundleI18n.LarkFile.Lark_Legacy_FriendRequestSendFailed,
                                on: self.view,
                                error: error
                            )
                        }
                    default:
                        FileBrowserController.logger.error(
                            "文件保存到云盘请求失败",
                            additionalData: ["messageId": self.file.messageId],
                            error: error
                        )
                        UDToast.showFailure(
                            with: BundleI18n.LarkFile.Lark_Legacy_FriendRequestSendFailed,
                            on: self.view,
                            error: error
                        )
                    }
                }
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: 收藏
    private func favorite() {
        let messageID = file.messageId
        let hud = UDToast.showLoading(with: BundleI18n.LarkFile.Lark_Legacy_LoadingNow, on: self.view, disableUserInteraction: true)
        messageAPI.fetchMessagesMap(ids: [messageID], needTryLocal: true).subscribe(onNext: { [weak self] (messageMap) in
            guard let `self` = self, let window = self.view.window else { return }
            guard let message = messageMap[messageID] else {
                hud.showFailure(with: BundleI18n.LarkFile.Lark_Legacy_SaveBoxSaveFail, on: window)
                return
            }
            var favoritesTarget = RustPB.Favorite_V1_CreateFavoritesRequest.FavoritesTarget()
            favoritesTarget.id = messageID
            favoritesTarget.type = .favoritesMessage
            favoritesTarget.chatID = Int64(message.channel.id) ?? 0
            self.favoriteAPI.createFavorites(targets: [favoritesTarget])
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak window] (_) in
                    guard let window = window else { return }
                    hud.showSuccess(with: BundleI18n.LarkFile.Lark_Legacy_ChatViewFavorites, on: window)
                }, onError: { [weak window] error in
                    guard let window = window else { return }
                    hud.showFailure(with: BundleI18n.LarkFile.Lark_Legacy_SaveBoxSaveFail, on: window, error: error)
                })
                .disposed(by: self.disposeBag)
        }, onError: { [weak self] error in
            guard let window = self?.view.window else { return }
            hud.showFailure(with: BundleI18n.LarkFile.Lark_Legacy_SaveBoxSaveFail,
                            on: window,
                            error: error)
        }).disposed(by: disposeBag)
    }

    // MARK: 打开文件
    @discardableResult
    private func openFile() -> Bool {
        if let vc = FilePreviewers.previewFilePath(file.fileLocalPath) {
            addChild(vc)
            view.addSubview(vc.view)
            vc.view.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            return true
        }

        guard file.fileFormat.isCompatible else { return false }
        downloadView.alpha = 0
        BaseUIViewController.attemptRotationToDeviceOrientation()

        switch file.fileFormat {
        case .video, .audio:
            let scene: MediaMutexScene
            if case .video = file.fileFormat {
                scene = .imVideoPlay
            } else {
                scene = .imPlay
            }
            guard case .success(let resource) = LarkMediaManager.shared.tryLock(scene: scene, options: .mixWithOthers) else {
                return false
            }
            let playerVC = AVPlayerViewController()
            playerVC.player = AVPlayer(url: file.fileLocalURL)
            addChild(playerVC)
            view.addSubview(playerVC.view)
            playerVC.view.frame = view.bounds
            if case FileFormat.audio(_) = file.fileFormat {
                // 如果是播放音频，设置成可后台播放
                self.audioQueue.async {
                    resource.audioSession.enter(FileBrowserController.audioScenario)
                }
            }
        case .txt, .json:
//            self.webView.lkLoadRequest(URLRequest(url: file.fileLocalURL), prevUrl: nil)
            self.webView.lwvc_loadRequest(URLRequest(url: file.fileLocalURL))
            let textTemplate = """
            <html>
                <head> <meta name="viewport" content="width=device-width, initial-scale=1"> </head>
                <body> <pre style="word-wrap: break-word; white-space: pre-wrap;">%@</pre> </body>
            </html>
            """

            if let stringContent = stringContentForURL(file.fileLocalURL) {
                // use htmlEscape protect from XSS attacks
                self.webView.loadHTMLString(String(format: textTemplate, stringContent.lf.htmlEscape()), baseURL: nil)
            }

        case .md:
            if stringContentForURL(file.fileLocalURL) != nil {
                dependency?.jumpToSpace(fileURL: file.fileLocalURL, name: file.fileName, fileType: "md", from: self)
            }
        case .html:
//            self.webView.lkLoadRequest((URLRequest(url: file.fileLocalURL)), prevUrl: nil)
            self.webView.lwvc_loadRequest(URLRequest(url: file.fileLocalURL))
            if let stringContent = stringContentForURL(file.fileLocalURL) {
                self.webView.loadHTMLString(stringContent, baseURL: nil)
            }

        default:
//            self.webView.lkLoadRequest(URLRequest(url: file.fileLocalURL), prevUrl: file.fileLocalURL)
            self.webView.lwvc_loadRequest(URLRequest(url: file.fileLocalURL), prevUrl: file.fileLocalURL)
        }
        return true
    }

    private func stringContentForURL(_ url: URL) -> String? {

        let encodings = [
                            .utf8,
                            String.Encoding(rawValue: 0x80000631), //GBK18030
                            String.Encoding(rawValue: 0x80000632), //GBK
                            String.Encoding(rawValue: 0x80000503), //greek
                            String.Encoding(rawValue: 0x80000504)  //turkish
                        ]

        let resultData = (try? Data.read_(from: url))
        if let resultData = resultData {
            for encoding in encodings {
                if let resultString = String(data: resultData, encoding: encoding) {
                    return resultString
                }
            }
        }

        return nil
    }

    override func failViewTap() {
        super.failViewTap()
        self.removeFailView()
//        self.webView.lkLoadRequest(URLRequest(url: self.url), prevUrl: nil)
        self.webView.lwvc_loadRequest(URLRequest(url: self.url))
    }

    // MARK: - SecLinkWKNavigationDelegate

    func loadingWebview(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        if let url = navigationAction.request.url {
            self.url = url
        }
        decisionHandler(WKNavigationActionPolicy.allow)
    }

    func loadingWebview(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.removeFailView()
    }

    func loadingWebview(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.removeFailView()
    }

    func loadingWebview(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        FileBrowserController.logger.error(
            "loadingWebview didFail: url :\(String(describing: webView.url)) error:\(error.localizedDescription)",
            additionalData: ["messageId": self.file.messageId],
            error: error
        )
        self.showFailView()
    }

    func loadingWebview(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        FileBrowserController.logger.error(
            "loadingWebview didFailProvisionalNavigation: url :\(String(describing: webView.url)) error:\(error.localizedDescription)",
            additionalData: ["messageId": self.file.messageId],
            error: error
        )
        self.showFailView()
    }

}

extension FileBrowserController: FileDownloadViewDelegate {
    func downloadViewDidClickClose(_ downloadView: FileDownloadView) {
        Tracker.post(TeaEvent(Homeric.CLICK_CANCEL_DOWNLOAD_FILE,
                              params: trackInfo)
        )
        switch downloadView.status {
        case .dowloading, .pause, .fail:
            fileDownloadTask.cancel()
        case .prepareToDownload, .finish, .origin, .decode, .decodeFail:
            break
        }
    }

    func downloadViewDidClickBottomButton(_ downloadView: FileDownloadView) {
        switch downloadView.status {
        case .dowloading:
            Tracker.post(TeaEvent(Homeric.PAUSE_DOWNLOAD_FILE,
                                  params: trackInfo.lf_update(["method": "click_pause_download"]))
                )
            fileDownloadTask.pause(byUser: true)
        case .finish:
            if self.menuOptions.contains(.openWithOtherApp) {
                chatSecurityControlService?.downloadAsyncCheckAuthority(
                    event: .openInAnotherApp,
                    securityExtraInfo: SecurityExtraInfo(
                        senderUserId: (self.file.senderUserId as NSString).longLongValue,
                        senderTenantId: (self.file.senderTenantId as NSString).longLongValue)) { [weak self] authority in
                    guard let self = self else { return }
                    if authority.authorityAllowed {
                        self.openWithOtherApp(rect: downloadView.bottomButton.convert(downloadView.bottomButton.bounds, to: self.view))
                    } else {
                        self.chatSecurityControlService?.authorityErrorHandler(event: .openInAnotherApp, authResult: authority,
                                                                              from: self)
                    }
                }
            }
        case .fail, .pause:
            Tracker.post(TeaEvent(Homeric.RESUME_DOWNLOAD_FILE,
                                  params: trackInfo)
                )
            fileDownloadTask.start()
        case .prepareToDownload:
            Tracker.post(TeaEvent(Homeric.CLICK_DOWNLOAD_FILE,
                                  params: trackInfo)
                )
            fileDownloadTask.start()
        case .origin, .decode:
            break
        case .decodeFail:
            self.decodeFile()
        }
    }
}

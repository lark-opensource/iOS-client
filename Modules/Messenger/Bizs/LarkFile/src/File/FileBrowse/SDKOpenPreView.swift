//
//  SDKOpenPreView.swift
//  LarkFile
//
//  Created by kangsiwan on 2020/7/20.
//

import UIKit
import Foundation
import LarkModel
import LarkContainer
import LarkMessengerInterface
import LarkSDKInterface
import LarkAccountInterface
import LarkFoundation
import Reachability
import LarkFeatureSwitch
import RxCocoa
import LarkMessageBase
import RxSwift
import EENavigator
import LarkAlertController
import LarkFeatureGating
import LarkCore
import LKCommonsLogging
import LarkLocalizations
import UniverseDesignToast

public final class DriveSDKDependencyImpl: DriveSDKDependencyBridge {
    fileprivate static let logger = Logger.log(DriveSDKDependencyImpl.self, category: "Module.LarkFile.DriveSDKDependencyImpl")
    public let actionDependency: DriveSDKActionDependencyBridge
    public let moreDependency: DriveSDKMoreDependencyBridge

    public init(message: Message,
                fileInfo: FileContentBasicInfo?,
                browseFromWhere: FileBrowseFromWhere,
                resolver: UserResolver,
                pushCenter: PushNotificationCenter,
                passportUserService: PassportUserService) {
        moreDependency = DriveSDKMoreDependencyImpl(
            message: message,
            fileMessageInfo: FileMessageInfo(
                userID: resolver.userID,
                message: message,
                fileInfo: fileInfo,
                browseFromWhere: browseFromWhere
            ),
            resolver: resolver,
            pushCenter: pushCenter
        )
        actionDependency = DriveSDKActionDependencyImpl(messageId: message.id, pushCenter: pushCenter, passportUserService: passportUserService)
    }
}

final class DriveSDKActionDependencyImpl: DriveSDKActionDependencyBridge {
    let stopPreviewSignal: Observable<Reason>
    var closePreviewSignal: Observable<Void> { .never() }
    init(messageId: String, pushCenter: PushNotificationCenter, passportUserService: PassportUserService) {
        stopPreviewSignal = pushCenter.observable(for: PushChannelMessage.self)
            .filter { $0.message.id == messageId }
            .compactMap { push -> Reason? in
                // 判断文件所属消息是否被焚毁
                DriveSDKDependencyImpl.logger.info("recived stopPreviewSignal",
                                                   additionalData: ["messageId": messageId,
                                                                    "isBurned": "\(push.message.isBurned)",
                                                                    "fileDeletedStatus": "\(push.message.fileDeletedStatus)",
                                                                    "dlpState": "\(push.message.dlpState)"])
                if push.message.isBurned {
                    return Reason(reason: BundleI18n.LarkFile.Lark_Legacy_ThisMsgAutoDeletedAlready, image: nil)
                }
                // 判断文件DLP状态是否为不通过
                let meId = passportUserService.user.userID
                if push.message.dlpState == .dlpBlock && meId != push.message.fromId {
                    return Reason(reason: BundleI18n.LarkFile.Lark_IM_DLP_UnableToViewContainSensitiveInfo_Text, image: nil)
                }
                // 判断文件删除状态
                switch push.message.fileDeletedStatus {
                case .normal:
                    return nil
                // 文件被删除，可被管理员恢复
                case .recoverable:
                    return Reason(reason: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogWithin90Days, image: nil)
                // 文件彻底被删除
                case .unrecoverable:
                    return Reason(reason: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogOver90Days, image: nil)
                case .recalled:
                    return Reason(reason: BundleI18n.LarkFile.Lark_Legacy_FileWithdrawTip, image: nil)
                case .freedUp:
                    return Reason(reason: BundleI18n.LarkFile.Lark_IM_ViewOrDownloadFile_FileDeleted_Text, image: nil)
                @unknown default:
                    assertionFailure()
                    return nil
                }
            } ?? .never()
    }
}

struct EmptyBridge: DriveSDKFileProviderBridge {
    var fileSize: UInt64 { 0 }
    var localFileURL: URL? { nil }
    func canDownload(fromView: UIView?) -> Observable<Bool> { .empty() }
    func download() -> Observable<DriveSDKDownloadStateBridge> { .empty() }
    func cancelDownload() {}
}

final class DriveSDKMoreDependencyImpl: DriveSDKMoreDependencyBridge, UserResolverWrapper {
    var moreMenuVisable: Observable<Bool> { .just(true) }
    var moreMenuEnable: Observable<Bool> { .just(true) }

    @ScopedInjectedLazy var fileAPI: SecurityFileAPI?
    private let message: Message
    private let fileMessageInfo: FileMessageInfo
    private let disposeBag = DisposeBag()
    private let pushCenter: PushNotificationCenter

    var provider: DriveSDKFileProviderBridge {
        let pushDownloadFile = pushCenter.driver(for: PushDownloadFile.self)
        let pushChannelMessage = pushCenter.driver(for: PushChannelMessage.self)
        guard let fileAPI = fileAPI else { return EmptyBridge() }
        let fileDownloadTask = try? userResolver.resolve(type: FileDownloadCenter.self).download(userID: userResolver.userID,
                                                                                       file: fileMessageInfo,
                                                                                       fileAPI: fileAPI,
                                                                                       downloadFileDriver: pushDownloadFile,
                                                                                       messageDriver: pushChannelMessage)
        guard let fileDownloadTask = fileDownloadTask else { return EmptyBridge() }
        let provider = SDKFileProvider(file: fileMessageInfo, task: fileDownloadTask, userResolver: userResolver)
        return provider
    }

    func handleForward(vc: UIViewController) {
        // 服务端禁用 transmit 行为时,禁止转发
        if let disableBehavior = fileMessageInfo.disabledAction.actions[Int32(MessageDisabledAction.Action.transmit.rawValue)] {
            let errorMessage: String
            switch disableBehavior.code {
            case 311_150:
                errorMessage = BundleI18n.LarkFile.Lark_IM_MessageRestrictedCantForward_Hover
            default:
                errorMessage = BundleI18n.LarkFile.Lark_IM_UnableOperationDueToPermissionRestrictions_Toast
            }
            if let window = WindowTopMostFrom(vc: vc).fromViewController?.view {
                UDToast.showFailure(with: errorMessage, on: window)
            }
            return
        }

        switch self.fileMessageInfo.browseFromWhere {
        case .file(let extra):
            let transmitType: TransmitType
            if let favoriteId = extra[FileBrowseFromWhere.FileFavoriteKey] as? String {
                transmitType = .favorite(favoriteId)
            } else {
                transmitType = .message(message.id)
            }
            let body = ForwardMessageBody(message: message, type: transmitType, from: .file)
            userResolver.navigator.present(body: body, from: vc, prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
        case .folder:
            let body = ForwardCopyFromFolderMessageBody(
                folderMessageId: fileMessageInfo.messageId,
                key: fileMessageInfo.fileKey,
                name: fileMessageInfo.fileName,
                size: fileMessageInfo.fileSize,
                copyType: .file
            )
            userResolver.navigator.present(body: body, from: vc, prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
        }
    }

    let userResolver: UserResolver
    init(message: Message, fileMessageInfo: FileMessageInfo, resolver: UserResolver, pushCenter: PushNotificationCenter) {
        self.message = message
        self.fileMessageInfo = fileMessageInfo
        self.userResolver = resolver
        self.pushCenter = pushCenter
    }
}

final class SDKFileProvider: DriveSDKFileProviderBridge, UserResolverWrapper {
    var fileMessageInfo: FileMessageInfo
    var localFileURL: URL?
    var fileSize: UInt64
    var fileDownloadTask: FileDownloadTask
    var downloadStatus = BehaviorRelay<DriveSDKDownloadStateBridge>(value: .downloading(progress: 0.0))
    let disposeBag = DisposeBag()
    let shouldDetectFile: Bool
    @ScopedInjectedLazy var fileAPI: SecurityFileAPI?
    @ScopedInjectedLazy var fileDownloadCenter: FileDownloadCenter?
    let userResolver: UserResolver

    private lazy var subscribeOnInit = userResolver.fg
        .dynamicFeatureGatingValue(with: "messenger.file.sdkfileprovider.subscribe.optimize")

    func canDownload(fromView: UIView?) -> Observable<Bool> {
        // 服务端禁用saveToLocal行为时,禁止下载
        if let disableBehavior = fileMessageInfo.disabledAction.actions[Int32(MessageDisabledAction.Action.saveToLocal.rawValue)] {
            let errorMessage: String
            switch disableBehavior.code {
            case 311_150:
                errorMessage = BundleI18n.LarkFile.Lark_IM_MessageRestrictedCantDownload_Hover
            default:
                errorMessage = BundleI18n.LarkFile.Lark_IM_UnableOperationDueToPermissionRestrictions_Toast
            }
            self.toastErrorInMainThread(errorMessage, view: fromView)
            return .just(false)
        }

        // 文件安全检测
        if !shouldDetectFile {
            return .just(true)
        }

        guard let fileAPI = fileAPI else { return Observable.just(false) }
        return fileAPI
            .canDownloadFile(
                detectRiskFileMeta: DetectRiskFileMeta(
                    key: fileMessageInfo.fileKey,
                    messageRiskObjectKeys: fileMessageInfo.riskObjectKeys
                )
            )
            .observeOn(MainScheduler.instance)
            .map { [weak self] canDownload in
                guard let self = self else {
                    return true
                }
                if !canDownload {
                    guard let window = fromView?.window else { return false }
                    let body = RiskFileAppealBody(fileKey: self.fileMessageInfo.fileKey,
                                                  locale: LanguageManager.currentLanguage.rawValue)
                    self.userResolver.navigator.present(body: body, from: window)
                    return false
                }
                return true
            }.catchErrorJustReturn(true)
    }

    private func toastErrorInMainThread(_ text: String, view: UIView?) {
        DispatchQueue.main.async {
            guard let view = view?.window else { return }
            UDToast.showFailure(with: text, on: view)
        }
    }

    func download() -> Observable<DriveSDKDownloadStateBridge> {
        // 检测DLP的状态
        switch fileMessageInfo.dlpDownloadState {
        case .dlpBlock:
            return .just(.interrupted(reason: BundleI18n.LarkFile.Lark_IM_DLP_UnableToDownloadFileNew_Toast))
        case .dlpInProgress:
            return .just(.interrupted(reason: BundleI18n.LarkFile.Lark_IM_DLP_UnableToDownload_Toast))
        @unknown default:
            break
        }
        if self.fileMessageInfo.isFileExist {
            return .just(.success(fileURL: self.fileMessageInfo.fileLocalURL))
        } else {
            fileDownloadTask.start()
            if !subscribeOnInit {
                subscribeTaskState()
            }
        }
        return downloadStatus.asObservable()
    }

    private func subscribeTaskState() {
        fileDownloadTask.statusObservable.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (status) in
                guard let self = self else { return }
                FileTrackUtil.trackAppreciableDownload(task: self.fileDownloadTask, status: status)
                switch status {
                case .prepare:
                    self.downloadStatus.accept(.downloading(progress: 0.0))
                case .downloading(progress: let progress, rate: let rate):
                    self.downloadStatus.accept(.downloading(progress: Double(progress)))
                case .finish:
                    self.localFileURL = self.fileMessageInfo.fileLocalURL
                    self.downloadStatus.accept(.success(fileURL: self.fileMessageInfo.fileLocalURL))
                    self.fileDownloadCenter?.remove(task: self.fileDownloadTask)
                case .pause:
                    self.downloadStatus.accept(.interrupted(reason: BundleI18n.LarkFile.Lark_Legacy_FileSuspendDownload))
                case .fail(error: let error):
                    DriveSDKDependencyImpl.logger.error("fileDownloadTask fail, messageId: \(self.fileMessageInfo.messageId)", error: error)
                    switch error {
                    case .sourceFileBurned:
                        //文件已焚毁，无法下载
                        self.downloadStatus.accept(.interrupted(reason: BundleI18n.LarkFile.Lark_Legacy_FileHasBeenBurnedCanNotDownload))
                    case .sourceFileWithdrawn:
                        //文件已被发送者撤回
                        self.downloadStatus.accept(.interrupted(reason: BundleI18n.LarkFile.Lark_Legacy_FileHasBeenRecalledCanNotDownload))
                    case .createDirFail, .downloadFail, .downloadRequestFail, .securityControlDeny, .strategyControlDeny:
                        self.downloadStatus.accept(.interrupted(reason: BundleI18n.LarkFile.Lark_Legacy_FileDownloadFail))
                    case .sourceFileForzenByAdmin:
                        self.downloadStatus.accept(.interrupted(reason: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogWithin90Days))
                    case .sourceFileShreddedByAdmin:
                        self.downloadStatus.accept(.interrupted(reason: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogOver90Days))
                    case .sourceFileDeletedByAdminScript:
                        self.downloadStatus.accept(.interrupted(reason: BundleI18n.LarkFile.Lark_IM_ViewOrDownloadFile_FileDeleted_Text))
                    /// 风险文件禁止下载
                    case .clientErrorRiskFileDisableDownload:
                        self.downloadStatus.accept(.interrupted(reason: BundleI18n.LarkFile.Lark_FileSecurity_Dialog_UnableToDownload))
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    func cancelDownload() {
        fileDownloadTask.cancel()
    }

    init(file: FileMessageInfo, task: FileDownloadTask, userResolver: UserResolver) {
        self.fileMessageInfo = file
        self.fileSize = UInt64(file.fileSize)
        self.fileDownloadTask = task
        self.userResolver = userResolver
        self.shouldDetectFile = userResolver.fg.staticFeatureGatingValue(with: "messenger.file.detect")
        if subscribeOnInit {
            subscribeTaskState()
        }
        if fileMessageInfo.isFileExist {
            localFileURL = fileMessageInfo.fileLocalURL
            fileDownloadCenter?.remove(task: fileDownloadTask)
        }
    }
}

// MARK: DrivesSDK 本地预览
final class DriveSDKLocalDependencyImpl: DriveSDKLocalDependencyBridge {
    let actionDependency: DriveSDKActionDependencyBridge
    let moreDependency: DriveSDKLocalMoreDependencyBridge

    init(messageId: String, pushCenter: PushNotificationCenter, passportUserService: PassportUserService) {
        moreDependency = DriveSDKLocalMoreDependencyImpl(messageId: messageId, pushCenter: pushCenter)
        actionDependency = DriveSDKActionDependencyImpl(messageId: messageId, pushCenter: pushCenter, passportUserService: passportUserService)
    }
}

final class DriveSDKLocalMoreDependencyImpl: DriveSDKLocalMoreDependencyBridge {
    let moreMenuVisable: Observable<Bool>
    var moreMenuEnable: Observable<Bool> { .just(true) }

    init(messageId: String, pushCenter: PushNotificationCenter) {
        moreMenuVisable = pushCenter.observable(for: PushChannelMessage.self)
            .filter { $0.message.id == messageId }
            .map { push -> Bool in
                // 判断文件所属消息是否被焚毁
                return !push.message.isBurned
            }
    }
}

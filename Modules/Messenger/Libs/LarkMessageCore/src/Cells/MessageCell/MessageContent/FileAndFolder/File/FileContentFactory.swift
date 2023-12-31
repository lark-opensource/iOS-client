//
//  FileContentFactory.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/13.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import LarkInteraction
import LarkMessengerInterface
import LarkSDKInterface
import LarkContainer
import MobileCoreServices
import LarkKAFeatureSwitch
import RustPB

private typealias Path = LarkSDKInterface.PathWrapper

public class FileContentFactory<C: PageContext>: MessageSubFactory<C> {

    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is FileContent
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return FileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: FileContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            fileAndFolderActionHandler: FileContentActionHandler(context: context)
        )
    }

    public override func registerDragHandler<M: CellMetaModel, D: CellMetaModelDependency>(with dargManager: DragInteractionManager, metaModel: M, metaModelDependency: D) {
        let suiteFileDownloadFG = self.context.userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteFileDownload))
        let handler = FileContentDragHandler(fileService: self.context.fileMessageInfoService,
                                             fileAPI: self.context.fileAPI,
                                             chatSecurityService: self.context.chatSecurityService,
                                             pushCenter: self.context.resolver.userPushCenter,
                                             suiteFileDownloadFG: suiteFileDownloadFG)
        dargManager.register(handler)
    }
}

// 合并转发页面在消息链接化场景有些特殊处理（见VM）
public final class MergeForwardFileContentFactory<C: PageContext>: FileContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return FileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: MergeForwardFileContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            fileAndFolderActionHandler: FileContentActionHandler(context: context)
        )
    }
}

// 消息链接化场景
public final class MessageLinkFileContentFactory<C: PageContext>: FileContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        let config = FileAndFolderConfig(
            useLocalChat: true,
            canViewInChat: false,
            canForward: false,
            canSearch: false,
            canSaveToDrive: false,
            canOfficeClick: false
        )
        return FileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: FileContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, fileAndFolderConfig: config),
            fileAndFolderActionHandler: FileContentActionHandler(context: context)
        )
    }
}

// 群置顶场景
public final class ChatPinFileContentFactory<C: PageContext>: FileContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return FileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: FileContentViewModel(metaModel: metaModel,
                                                         metaModelDependency: metaModelDependency,
                                                         context: context,
                                                         fileAndFolderConfig: FileAndFolderConfig(showBottomBorder: false)),
            fileAndFolderActionHandler: FileContentActionHandler(context: context)
        )
    }
}

public final class ThreadFileContentFactory<C: PageContext>: FileContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return MessageDetailFileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: FileContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            fileAndFolderActionHandler: FileContentActionHandler(context: context)
        )
    }
}

public final class MessageDetailFileContentFactory<C: PageContext>: FileContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return MessageDetailFileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: FileContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            fileAndFolderActionHandler: FileContentActionHandler(context: context)
        )
    }
}

public final class PinFileContentFactory<C: PageContext>: FileContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return PinFileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: FileContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            fileAndFolderActionHandler: FileContentActionHandler(context: context)
        )
    }
}

struct FileContentDragHandler: DragInteractionHandler {

    struct FileError: Error {
    }

    private var fileService: FileMessageInfoService?
    private var fileAPI: SecurityFileAPI?
    private var chatSecurityService: ChatSecurityControlService?
    private var pushCenter: PushNotificationCenter
    private let suiteFileDownloadFG: Bool
    init(fileService: FileMessageInfoService?,
         fileAPI: SecurityFileAPI?,
         chatSecurityService: ChatSecurityControlService?,
         pushCenter: PushNotificationCenter,
         suiteFileDownloadFG: Bool) {
        self.fileService = fileService
        self.fileAPI = fileAPI
        self.chatSecurityService = chatSecurityService
        self.pushCenter = pushCenter
        self.suiteFileDownloadFG = suiteFileDownloadFG
    }

    func dragInteractionHandleViewTag() -> String {
        return "FileContent"
    }

    func dragInteractionCanHandle(context: DragContext) -> Bool {
        /// 不支持文件下载的时候，禁止文件拖拽
        if !suiteFileDownloadFG {
            return false
        }

        guard let message = context.getValue(key: DragContextKey.message) as? Message else {
                return false
        }
        if message.type != .file {
            return false
        }
        return true
    }

    func checkSecurity(message: Message, chat: Chat, view: UIView, key: String, completion: @escaping (Bool) -> Void) {
        guard let chatSecurityService else {
            completion(true)
            return
        }
        let chatType: Int64 = (chat.chatMode == .threadV2) ? 3 : ((chat.type == .p2P) ? 1 : 2)
        let info = SecurityExtraInfo(fileKey: key,
                                     chatID: (chat.id as NSString).longLongValue,
                                     chatType: chatType,
                                     senderUserId: (message.fromId as NSString).longLongValue,
                                     senderTenantId: ((message.fromChatter?.tenantId ?? "") as NSString).longLongValue,
                                     msgId: message.id)
        chatSecurityService.downloadAsyncCheckAuthority(event: .saveFile, securityExtraInfo: info, completion: { result in
            let allow = result.authorityAllowed
            if !allow {
                chatSecurityService.authorityErrorHandler(event: .saveFile, authResult: result, from: view.window)
            }
            completion(allow)
        })
    }

    func dragInteractionHandle(info: DragInteractionViewInfo, context: DragContext) -> [DragItem]? {
        let downloadFileScene = context.getValue(key: DragContextKey.downloadFileScene) as? RustPB.Media_V1_DownloadFileScene
        guard let message = context.getValue(key: DragContextKey.message)as? Message,
              let chat = context.getValue(key: DragContextKey.chat) as? Chat,
              let fileInfo = fileService?.getFileMessageInfo(message: message, downloadFileScene: downloadFileScene),
              let view = info.view else {
            return nil
        }
        let itemProvider: NSItemProvider

        /// 通过文件名获取文件 uti
        let pathExtension = (fileInfo.fileName as NSString).pathExtension
        let uti: String = (UTTypeCreatePreferredIdentifierForTag(
            kUTTagClassFilenameExtension,
            pathExtension as CFString,
            nil
        )?.takeRetainedValue() as String?) ?? UTI.Data

        /// 如果本地存在文件
        if Path(fileInfo.fileLocalPath).exists {
            let item = ItemProviderWriting(
                supportUTI: [uti]
            ) { (_, callback) -> Progress? in
                checkSecurity(message: message, chat: chat, view: view, key: fileInfo.fileKey, completion: { allow in
                    guard allow else {
                        callback(nil, FileError())
                        return
                    }
                    if let data = try? Data.read_(from: fileInfo.fileLocalURL) {
                        callback(data, nil)
                    } else {
                        callback(nil, FileError())
                    }
                })
                return nil
            }
            itemProvider = NSItemProvider(object: item)
        }
        /// 如果本地不存在文件
        else {
            let fileAPI = self.fileAPI
            let downloadFile = pushCenter.observable(for: PushDownloadFile.self)
            let item = ItemProviderWriting(
                supportUTI: [uti]
            ) { (_, callback) -> Progress? in
                let progress = Progress()
                progress.totalUnitCount = 100
                var dispose = DisposeBag()
                fileAPI?.canDownloadFile(
                    detectRiskFileMeta: DetectRiskFileMeta(
                        key: fileInfo.fileKey, messageRiskObjectKeys: message.riskObjectKeys
                    )
                ).flatMap({ canDownload in
                    if !canDownload {
                        return Observable.just(false)
                    }
                    return Observable.create { ob in
                        checkSecurity(message: message, chat: chat, view: view, key: fileInfo.fileKey, completion: { allow in
                            ob.onNext(allow)
                            ob.onCompleted()
                        })
                        return Disposables.create()
                    }
                }).subscribe(onNext: { [fileAPI, downloadFile] canDownload in
                    guard canDownload else {
                        callback(nil, FileError())
                        return
                    }
                    /// 触发文件下载
                    fileAPI?.downloadFile(
                        messageId: message.id,
                        key: fileInfo.fileKey,
                        authToken: fileInfo.authToken,
                        authFileKey: fileInfo.authFileKey,
                        absolutePath: fileInfo.fileLocalPath,
                        isCache: false,
                        type: .message,
                        channelId: message.channel.id,
                        sourceType: message.sourceType,
                        sourceID: message.sourceID,
                        downloadFileScene: downloadFileScene).subscribe(onError: { _ in
                            callback(nil, FileError())
                            dispose = DisposeBag()

                        }).disposed(by: dispose)

                    /// 监听文件下载进度
                    downloadFile.subscribe(onNext: { (push) in
                        switch push.state {
                        case .downloading:
                            if push.progress > 0 {
                                progress.completedUnitCount = Int64(push.progress)
                            }
                        case .downloadSuccess:
                            progress.completedUnitCount = 100
                            if let data = try? Data.read_(from: fileInfo.fileLocalURL) {
                                callback(data, nil)
                            } else {
                                callback(nil, FileError())
                            }
                            dispose = DisposeBag()
                        case .downloadFail, .downloadFailBurned, .downloadFailRecall:
                            callback(nil, FileError())
                            dispose = DisposeBag()
                        @unknown default:
                            break
                        }
                    }).disposed(by: dispose)
                }, onError: { _ in
                    callback(nil, FileError())
                    dispose = DisposeBag()
                }).disposed(by: dispose)

                return progress
            }
            itemProvider = NSItemProvider(object: item)
        }
        itemProvider.suggestedName = fileInfo.fileName
        var item = DragItem(dragItem: UIDragItem(itemProvider: itemProvider))
        let previewParams = UIDragPreviewParameters()
        previewParams.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        previewParams.visiblePath = UIBezierPath(
            roundedRect: view.bounds,
            cornerRadius: 8
        )
        item.params.targetDragPreviewParameters = previewParams
        return [item]
    }
}

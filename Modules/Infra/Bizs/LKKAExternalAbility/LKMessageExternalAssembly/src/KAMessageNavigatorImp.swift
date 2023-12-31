//
//  KAMessageNavigatorImp.swift
//  LKMessageExternalAssembly
//
//  Created by Ping on 2023/11/14.
//
import RxSwift
import EEAtomic
import LarkCache
import LarkModel
import EENavigator
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import LKMessageExternal
import LarkMessengerInterface
import ThreadSafeDataStructure

private typealias DownloadSuccess = (String) -> Void
private typealias DownloadFailed = (Error) -> Void

final class KAMessageNavigatorImp: KAMessageNavigator, UserResolverWrapper {
    var userResolver: UserResolver {
        return Container.shared.getCurrentUserResolver()
    }

    private let logger = Logger.log(LKMessageExternalAssembly.self, category: "KAMessageNavigatorImp")

    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy var messageAPI: MessageAPI?
    @ScopedInjectedLazy var fileAPI: SecurityFileAPI?
    @ScopedInjectedLazy var resourceAPI: ResourceAPI?
    @ScopedInjectedLazy var securityService: ChatSecurityControlService?
    // 文件下载是异步的，下载成功的状态通过Push回来
    private var fileDownloadCallback: SafeDictionary<String, [(DownloadSuccess, DownloadFailed)]> = [:] + .readWriteLock
    private let filePushSubOnce = AtomicOnce()

    func forward(message: KAMessage) {
        switch message.type {
        case .file:
            guard let body = message.body as? KAFileMessageProtocol else {
                return
            }
            logger.info("ka message forward, path: \(body.filePath)")
            let msg = ForwardLocalFileBody(localPath: body.filePath)
            Navigator.shared.present(body: msg, from: Navigator.shared.mainSceneTopMost ?? UIViewController()) {
                $0.modalPresentationStyle = .formSheet
            }
        case .image, .video, .others: return // 双端对齐，现在只支持文件
        @unknown default: return
        }
    }

    func getResources(messages: [KAMessage], onSuccess: @escaping ([KAMessageInfo]) -> Void, onError: @escaping (Error) -> Void) {
        let messageIDs = messages.map({ $0.id })
        logger.info("KAMessage getResources start -> \(messageIDs)")
        messageAPI?.fetchMessagesMap(ids: messageIDs, needTryLocal: true)
            .subscribe(onNext: { [weak self] messageMap in
                guard let self = self else {
                    onSuccess([])
                    return
                }
                let messages = messageIDs.compactMap { id in
                    if let message = messageMap[id], (message.type == .image || message.type == .media || message.type == .file) {
                        return message
                    }
                    return nil
                }
                // MGetMessages接口会返回回复消息，此处需要做一下筛选
                self.checkSecurity(messages: messages, onSuccess: onSuccess, onError: onError)
            }, onError: { [weak self] error in
                self?.logger.error("KAMessage getResources error -> \(messageIDs)", error: error)
                onError(error)
            })
            .disposed(by: disposeBag)
    }

    func downloadResource(messageInfo: KAMessageInfo, onSuccess: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        switch messageInfo.type {
        case .file, .video:
            downloadFile(messageInfo: messageInfo, onSuccess: onSuccess, onError: onError)
        case .image:
            downloadImage(messageInfo: messageInfo, onSuccess: onSuccess, onError: onError)
        @unknown default: onError(NSError(domain: "unknown KAMessageInfo", code: -1))
        }
    }

    /// 当前类初始化时机较早，不能在init中监听
    private func subscribeFilePushIfNeed() {
        filePushSubOnce.once {
            try? userResolver.userPushCenter.observable(for: PushDownloadFile.self)
                .subscribe(onNext: { [weak self] push in
                    guard let self = self else { return }
                    switch push.state {
                    case .downloadSuccess:
                        if !fileDownloadCallback.isEmpty {
                            let key = downloadKey(messageID: push.messageId, fileKey: push.key)
                            let callback = fileDownloadCallback.removeValue(forKey: key) ?? []
                            self.logger.info("KAMessage PushDownloadFile success -> \(key) -> \(callback.count)")
                            callback.forEach { (onSuccess, _) in
                                onSuccess(push.path)
                            }
                        }
                    case .downloadFail, .downloadCancel, .downloadFailBurned, .downloadFailRecall, .cancelByRisk:
                        if !fileDownloadCallback.isEmpty {
                            let key = downloadKey(messageID: push.messageId, fileKey: push.key)
                            let callback = fileDownloadCallback.removeValue(forKey: key) ?? []
                            self.logger.info("KAMessage PushDownloadFile error -> \(key) -> \(callback.count)")
                            callback.forEach { (_, onError) in
                                onError(NSError(domain: push.error?.displayMessage ?? "file download failed", code: Int(push.error?.code ?? -1)))
                            }
                        }
                    default: break
                    }
                })
                .disposed(by: disposeBag)
        }
    }

    private func downloadFile(messageInfo: KAMessageInfo, onSuccess: @escaping DownloadSuccess, onError: @escaping DownloadFailed) {
        subscribeFilePushIfNeed()

        fileDownloadCallback.safeWrite { callback in
            let key = downloadKey(messageID: messageInfo.messageID, fileKey: messageInfo.key)
            var values = callback[key] ?? []
            values.append((onSuccess, onError))
            callback[key] = values
        }
        self.logger.info("KAMessage downloadFile start -> \(messageInfo.messageID) -> \(messageInfo.key)")
        fileAPI?.downloadFile(
            messageId: messageInfo.messageID,
            key: messageInfo.key,
            authToken: nil,
            authFileKey: "",
            absolutePath: "",
            isCache: true,
            type: .message,
            channelId: messageInfo.channelID,
            sourceType: .typeFromMessage,
            sourceID: "",
            downloadFileScene: .chat
        )
        .subscribe()
        .disposed(by: disposeBag)
    }

    private func downloadKey(messageID: String, fileKey: String) -> String {
        return "\(messageID)_\(fileKey)"
    }

    private func downloadImage(messageInfo: KAMessageInfo, onSuccess: @escaping DownloadSuccess, onError: @escaping DownloadFailed) {
        assert(messageInfo.type == .image, "unmatched type!")
        logger.info("KAMessage downloadImage start -> \(messageInfo.messageID) -> \(messageInfo.key)")
        resourceAPI?.fetchResource(
            key: messageInfo.key,
            path: nil,
            authToken: nil,
            downloadScene: .chat,
            isReaction: false,
            isEmojis: false,
            avatarMap: nil
        )
        .subscribe(onNext: { [weak self] item in
            self?.logger.info("KAMessage downloadImage success -> \(messageInfo.messageID)")
            onSuccess(item.path)
        }, onError: { [weak self] error in
            self?.logger.error("KAMessage downloadImage error -> \(messageInfo.messageID)", error: error)
            onError(error)
        })
        .disposed(by: disposeBag)
    }

    private func checkSecurity(messages: [Message], onSuccess: @escaping ([KAMessageInfo]) -> Void, onError: @escaping (Error) -> Void) {
        let obs = messages.map({ self.isRestricted(message: $0) })
        if obs.isEmpty {
            onSuccess([])
            return
        }

        var messageInfos = [KAMessageInfo]()
        var restrictedIDs = [String]()
        Observable.merge(obs)
            .subscribe(onNext: { (message, isRestricted) in
                if isRestricted {
                    restrictedIDs.append(message.id)
                } else if let info = self.transformToMessageInfo(message: message) {
                    messageInfos.append(info)
                }
            }, onError: { [weak self] error in
                self?.logger.error("KAMessage checkSecurity error", error: error)
                onError(error)
            }, onCompleted: { [ weak self] in
                self?.logger.info("KAMessage getResources success -> \(messages.map({ $0.id })) -> restrictedIDs = \(restrictedIDs)")
                onSuccess(messageInfos)
                if !restrictedIDs.isEmpty {
                    onError(NSError(domain: "message is restricted: \(restrictedIDs)", code: -1001))
                }
            })
            .disposed(by: self.disposeBag)
    }

    private func isRestricted(message: Message) -> Observable<(Message, Bool)> {
        return Observable.create { [weak self] observer in
            let finish: (Bool) -> Void = { restricted in
                observer.onNext((message, restricted))
                observer.onCompleted()
            }
            // 被禁止转发
            if message.disabledAction.actions[Int32(MessageDisabledAction.Action.transmit.rawValue)] != nil {
                finish(true)
                return Disposables.create()
            }
            if !message.riskObjectKeys.isEmpty {
                finish(true)
                return Disposables.create()
            }
            if message.dlpState == .dlpBlock {
                finish(true)
                return Disposables.create()
            }
            if LarkCache.isCryptoEnable() {
                finish(true)
                return Disposables.create()
            }
            guard let securityService = self?.securityService,
                  let securityEvent = message.securityEvent,
                  let info = message.securityExtraInfo else {
                finish(false)
                return Disposables.create()
            }
            securityService.downloadAsyncCheckAuthority(event: securityEvent, securityExtraInfo: info, ignoreSecurityOperate: true) { result in
                finish(!result.authorityAllowed)
            }
            return Disposables.create()
        }
    }

    private func transformToMessageInfo(message: Message) -> KAMessageInfo? {
        if message.type == .image, let content = message.content as? ImageContent {
            return KAMessageInfo(
                type: .image,
                key: content.image.key,
                messageID: message.id,
                channelID: message.channel.id,
                name: "",
                size: content.originFileSize,
                mime: ""
            )
        }

        if message.type == .media, let content = message.content as? MediaContent {
            return KAMessageInfo(
                type: .video,
                key: content.key,
                messageID: message.id,
                channelID: message.channel.id,
                name: content.name,
                size: UInt64(content.size),
                mime: content.mime
            )
        }

        if message.type == .file, let content = message.content as? FileContent {
            return KAMessageInfo(
                type: .file,
                key: content.key,
                messageID: message.id,
                channelID: message.channel.id,
                name: content.name,
                size: UInt64(content.size),
                mime: content.mime
            )
        }
        return nil
    }
}

private extension Message {
    var securityEvent: SecurityControlEvent? {
        switch type {
        case .image: return .saveImage
        case .file: return .saveFile
        case .media: return .saveVideo
        default: return nil
        }
    }

    var securityExtraInfo: SecurityExtraInfo? {
        if type == .image, let content = content as? ImageContent {
            return SecurityExtraInfo(fileKey: content.image.origin.key, message: self)
        }
        if type == .media, let content = content as? MediaContent {
            return SecurityExtraInfo(fileKey: content.key, message: self)
        }
        if type == .file, let content = content as? FileContent {
            return SecurityExtraInfo(fileKey: content.key, message: self)
        }
        return nil
    }
}

//
//  MessengerDependencyImpl.swift
//  LarkTodo
//
//  Created by 张威 on 2021/1/21.
//

import Photos
import Swinject
import LarkContainer
import LarkFoundation
import LarkModel
import RxSwift
import RustPB
import TodoInterface
import LarkAccountInterface
import LarkRustClient
import ByteWebImage
import RxCocoa
import LarkEmotionKeyboard
import LarkBizTag
import UniverseDesignFont

#if MessengerMod
import LarkSDKInterface
import LarkSendMessage
import LarkMessageCore
import LarkMessengerInterface
import LarkCore
import TangramService
#endif

/// Todo 业务对 Messenger 业务相关的依赖实现

final class MessengerDependencyImpl: MessengerDependency, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    private let disposeBag = DisposeBag()

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func fetchMessages(byIds messageIds: [String]) -> Observable<[LarkModel.Message]> {
        #if MessengerMod
        guard let messageAPI = try? userResolver.resolve(assert: MessageAPI.self) else {
            return .just([])
        }
        return messageAPI.fetchMessages(ids: messageIds)
        #else
        return .just([])
        #endif
    }

    func replyMessages(byIds messageIds: [String], with content: String, replyInThreadSet: Set<String>) {
        #if MessengerMod
        let messageAPI = try? userResolver.resolve(assert: MessageAPI.self)
        messageAPI?.fetchMessages(ids: messageIds)
            .subscribe(onNext: { [weak self] messages in
                self?.doReplyMessages(messages, with: content, replyInThreadSet: replyInThreadSet)
            })
            .disposed(by: disposeBag)
        #endif
    }

    func checkAndCreateChats(byUserIds userIds: [String]) -> Observable<[String]> {
        #if MessengerMod
        guard let chatAPI = try? userResolver.resolve(assert: ChatAPI.self) else {
            return .just([])
        }
        var chats = [LarkModel.Chat]()
        var userIdsHasNoChat = [String]()
        return chatAPI.fetchLocalP2PChatsByUserIds(uids: userIds)
            .do(onNext: { chatsDic in
                userIds.forEach { userId in
                    if let chat = chatsDic[userId] {
                        chats.append(chat)
                    } else {
                        userIdsHasNoChat.append(userId)
                    }
                }
            })
            .catchErrorJustReturn([:])
            .flatMap { _ -> Observable<[LarkModel.Chat]> in
                guard !userIdsHasNoChat.isEmpty else {
                    return .just(chats)
                }
                return chatAPI.createP2pChats(uids: userIdsHasNoChat).map {
                    chats.append(contentsOf: $0)
                    return chats
                }
            }
            .map { $0.map(\.id) }
        #endif
        return .just([])
    }

    /// 基于 chatId & query 搜索 chatter
    func searchChatter(
        byQuery query: String,
        basedOnChat chatId: String
    ) -> Observable<ChatterSearchResultBasedOnChat> {
        let defaultRet = ChatterSearchResultBasedOnChat(
            isFromRemote: false,
            chatChatters: [:],
            chatters: [:],
            wantedChatterIds: [],
            inChatChatterIds: [],
            outChatChatterIds: []
        )
        #if MessengerMod
        guard let chatterAPI = try? userResolver.resolve(assert: ChatterAPI.self) else {
            return .just(defaultRet)
        }
        let mapTransform = { (chatter: Basic_V1_Chatter) -> ChatterSearchItem in
            return ChatterSearchItem(
                id: chatter.id,
                tenantId: chatter.tenantID,
                name: chatter.localizedName,
                otherName: .init(
                    alias: chatter.alias,
                    anotherName: chatter.anotherName,
                    localizedName: chatter.localizedName
                ),
                avatarKey: chatter.avatarKey,
                department: nil,
                tagInfo: chatter.tagInfo.transform(),
                isBot: chatter.type == .bot,
                isAnonymous: chatter.isAnonymous
            )
        }
        return chatterAPI.fetchAtListWithLocalOrRemote(chatId: chatId, query: query)
            .map { tuple -> ChatterSearchResultBasedOnChat in
                let (res, isFromRemote) = tuple
                let chatChatters = res.entity.chatChatters[chatId]?.chatters.mapValues(mapTransform) ?? [:]
                let chatters = res.entity.chatters.mapValues(mapTransform)
                return ChatterSearchResultBasedOnChat(
                    isFromRemote: isFromRemote,
                    chatChatters: chatChatters,
                    chatters: chatters,
                    wantedChatterIds: res.wantedMentionIds,
                    inChatChatterIds: res.inChatChatterIds,
                    outChatChatterIds: res.outChatChatterIds
                )
            }
        #else
        return .just(defaultRet)
        #endif
    }

    /// 基于 query 搜索 chatter
    func searchChatter(byQuery query: String) -> Observable<ChatterSearchResultBasedOnQuery> {
        let ret = ChatterSearchResultBasedOnQuery(isFromRemote: false, chatters: [])
        #if MessengerMod
        guard let searchAPI = try? userResolver.resolve(assert: SearchAPI.self) else {
            return .just(ret)
        }
        return searchAPI.universalSearch(query: query,
                                  scene: .rustScene(.searchChatters),
                                  begin: 0,
                                  end: 50,
                                  moreToken: nil,
                                  filter: nil,
                                  needSearchOuterTenant: true,
                                  authPermissions: [])
        .map { response -> ChatterSearchResultBasedOnQuery in
            let items = response.results.compactMap { result -> ChatterSearchItem? in
                guard case .chatter(let chatterMeta) = result.meta else { return nil }
                var tagData = Basic_V1_TagData()
                tagData.tagDataItems = chatterMeta.relationTag.tagDataItems.map({ item in
                    var new = Basic_V1_TagData.TagDataItem()
                    new.textVal = item.textVal
                    new.tagID = item.tagID
                    switch item.respTagType {
                    case .relationTagExternal:
                        new.respTagType = .relationTagExternal
                    case .relationTagPartner:
                        new.respTagType = .relationTagPartner
                    case .relationTagTenantName:
                        new.respTagType = .relationTagTenantName
                    case .relationTagUnset:
                        new.respTagType = .relationTagUnset
                    default: break
                    }
                    return new
                })
                return ChatterSearchItem(
                    id: chatterMeta.id,
                    tenantId: chatterMeta.tenantID,
                    name: result.title.string,
                    otherName: nil,
                    avatarKey: result.avatarKey,
                    department: nil,
                    tagInfo: tagData.transform(),
                    isBot: chatterMeta.type == .bot,
                    isAnonymous: false
                )
            }
            return .init(isFromRemote: true, chatters: items)
        }
        #else
        return .just(ret)
        #endif
    }

    func getMergedMessageDisplayInfo(entity: Basic_V1_Entity, message: Basic_V1_Message) -> (title: String, content: NSAttributedString) {
        #if MessengerMod
        let content = MergeForwardContent.transform(pb: message)
        content.complement(entity: entity, message: Message.transform(pb: message))

        // titleText
        let titleText = content.title

        // contentText
        let factory = DefaultMesageSummerizeFactory(userResolver: self.userResolver)
        let font = UDFont.body2
        let color = UIColor.ud.N600

        let mutText = content.messages.prefix(5)
            .compactMap { message -> NSAttributedString? in
                guard let chatter = content.chatters[message.fromId] else { return nil }
                return factory.getSummerize(
                    message: message,
                    chatterName: chatter.name,
                    fontColor: color,
                    urlPreviewProvider: { [weak self] elementID, customAttributes in
                        guard let self = self else { return nil }
                        var attr = customAttributes
                        attr[MessageInlineViewModel.iconColorKey] = color
                        attr[MessageInlineViewModel.tagTypeKey] = TagType.normal
                        let inlinePreviewVM = MessageInlineViewModel()
                        return inlinePreviewVM.getSummerizeAttrAndURL(
                            elementID: elementID,
                            message: message,
                            translatedInlines: nil,
                            isOrigin: true,
                            customAttributes: attr
                        )
                    }
                )
            }
            .reduce(NSMutableAttributedString(string: "")) { (a, b) in
                // 去除富文本里面的换行符
                let mutAttrText = NSMutableAttributedString(attributedString: b)
                mutAttrText.mutableString.replaceOccurrences(
                    of: "\n",
                    with: "",
                    options: [],
                    range: NSRange(location: 0, length: mutAttrText.length)
                )
                a.append(mutAttrText)
                a.append(NSAttributedString(string: "\n"))
                return a
            }
        mutText.addAttribute(.font, value: font, range: NSRange(location: 0, length: mutText.length))
        let text = mutText as NSAttributedString
        let contentText = text.lf.trimmedAttributedString(set: .whitespacesAndNewlines, position: .trail)

        return (titleText, contentText)
        #else
        return (title: "", content: NSAttributedString())
        #endif
    }

    func processPhotoAssets(_ assets: [PHAsset], isOriginal: Bool) -> [(image: UIImage, data: Data)] {
        #if MessengerMod
        guard let imageProcessor = try? userResolver.resolve(assert: SendImageProcessor.self) else {
            return []
        }
        let dependency = ImageInfoDependency(
            useOrigin: isOriginal,
            sendImageProcessor: imageProcessor
        )
        var ret = [(image: UIImage, data: Data)]()
        for asset in assets {
            let item = asset.imageInfo(dependency)
            ret.append((image: item.image ?? UIImage(), data: item.data ?? Data()))
        }
        return ret
        #else
        return []
        #endif
    }

    func uploadTakenPhoto(_ photo: UIImage, callback: @escaping (_ compressedImage: UIImage) -> Void) -> Observable<String> {
        #if MessengerMod
        let request = SendImageRequest(
            input: .image(photo),
            sendImageConfig: SendImageConfig(
                isSkipError: false,
                checkConfig: SendImageCheckConfig(
                    isOrigin: false,
                    scene: .TodoComment,
                    fromType: .image
                )
            ),
            uploader: TodoImageUploader(resolver: userResolver)
        )
        let processor = TodoImageProcessor(callback: callback)
        request.addProcessor(afterState: .compress, processor: processor, processorId: "todo.send.image.processor.compress")
        return SendImageManager.shared.sendImage(request: request)
        #else
        return .just("")
        #endif
    }

    func uploadPhotoAsset(_ asset: PHAsset, isOriginal: Bool, callback: @escaping (_ compressedImage: UIImage) -> Void) -> Observable<String> {
        #if MessengerMod
        let request = SendImageRequest(
            input: .asset(asset),
            sendImageConfig: SendImageConfig(
                isSkipError: false,
                checkConfig: SendImageCheckConfig(
                    isOrigin: isOriginal,
                    scene: .TodoComment,
                    fromType: .image
                )
            ),
            uploader: TodoImageUploader(resolver: userResolver)
        )
        let processor = TodoImageProcessor(callback: callback)
        request.addProcessor(afterState: .compress, processor: processor, processorId: "todo.send.image.processor.compress")
        return SendImageManager.shared.sendImage(request: request)
        #else
        return .just("")
        #endif
    }

    func parseImageUploaderError(_ error: Error) -> String? {
        #if MessengerMod
        if let imageError = error as? LarkSendImageError,
           let compressError = imageError.error as? CompressError,
           let errMsg = AttachmentImageError.getCompressError(error: compressError) {
            return errMsg
        }
        #endif
        return nil
    }

    private func doReplyMessages(_ messages: [Message], with content: String, replyInThreadSet: Set<String>) {
        #if MessengerMod
        guard let sendMessageAPI = try? userResolver.resolve(assert: SendMessageAPI.self) else {
            return
        }
        let richText = RustPB.Basic_V1_RichText.text(content)
        for message in messages {
            let context = APIContext(contextID: "")
            context.set(key: APIContext.replyInThreadKey, value: replyInThreadSet.contains(message.id))
            sendMessageAPI.sendText(
                context: context,
                content: richText,
                parentMessage: message,
                chatId: message.channel.id,
                threadId: message.threadId,
                stateHandler: nil
            )
        }
        #endif
    }

    func fetchChatName(
        by chatId: String,
        onSuccess: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        #if MessengerMod
        let chatAPI = try? userResolver.resolve(assert: ChatAPI.self)
        chatAPI?.fetchChat(by: chatId, forceRemote: false)
            .take(1).asSingle().observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] chat in
                    guard let self = self, let chat = chat else { return }
                    onSuccess(chat.name)
                }, onError: { error in
                    onError(error)
                }
            ).disposed(by: self.disposeBag)
        #endif
    }


    var is24HourTime: BehaviorRelay<Bool> {
        #if MessengerMod
        guard let userConfig = try? userResolver.resolve(assert: UserGeneralSettings.self) else {
            return .init(value: false)
        }
        return userConfig.is24HourTime
        #else
        return .init(value: false)
        #endif
    }

    func resourceAddrWithLanguage(key: String) -> String? {
        #if MessengerMod
        guard let config = try? userResolver.resolve(assert: UserAppConfig.self) else {
            return nil
        }
        return config.resourceAddrWithLanguage(key: key)
        #else
        return ""
        #endif
    }

    func updateRecentlyUsedReaction(reactionType: String) -> Observable<Void> {
        #if MessengerMod
        guard let reactionAPI = try? userResolver.resolve(assert: ReactionAPI.self) else {
            return .empty()
        }
        return reactionAPI.updateRecentlyUsedReaction(reactionType: reactionType)
        #else
        return .empty()
        #endif
    }

    var reactionService: EmojiDataSourceDependency {
        #if MessengerMod
        guard let reactionService = try? userResolver.resolve(assert: ReactionService.self) else {
            return EmojiImageService.default!
        }
        return reactionService as EmojiDataSourceDependency
        #else
        return EmojiImageService.default!
        #endif
    }
}

#if MessengerMod
private class TodoImageUploader: LarkSendImageUploader, UserResolverWrapper {
    typealias AbstractType = String
    var userResolver: LarkContainer.UserResolver

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    @ScopedInjectedLazy var imageAPI: ImageAPI?
    func imageUpload(request: LarkSendImageAbstractRequest) -> Observable<AbstractType> {
        return Observable.create { [weak self] observer in
            guard let self = self, let imageAPI = self.imageAPI, let data = request.getContext()["todo.send.image.data"] as? Data else {
                observer.onError(TodoImageError.uploaderGetContextFailed)
                return Disposables.create()
            }

            imageAPI.uploadSecureImage(
                data: data,
                type: .normal,
                imageCompressedSizeKb: 0
            ).subscribe(
                onNext: { token in
                    observer.onNext(token)
                    observer.onCompleted()
                },
                onError: { err in
                    observer.onError(err)
                }
            )

            return Disposables.create()
        }
    }
}

final class TodoImageProcessor: LarkSendImageProcessor {
    var callback: ((_ compressedImage: UIImage) -> Void)?
    init(callback: ((_ compressedImage: UIImage) -> Void)?) {
        self.callback = callback
    }

    public func imageProcess(sendImageState: SendImageState, request: LarkSendImageAbstractRequest) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self, let compressed = request.getCompressResult()?.first else {
                observer.onError(TodoImageError.getCompressResultFailed)
                return Disposables.create()
            }

            switch compressed.result {
            case .success(let res):
                guard let image = res.image, let data = res.data else {
                    observer.onError(TodoImageError.getCompressImageAndDataFailed)
                    return Disposables.create()
                }
                self.callback?(image)
                request.setContext(key: "todo.send.image.data", value: data)
                observer.onNext(())
                observer.onCompleted()
            case .failure(let err):
                observer.onError(err)
            }

            return Disposables.create()
        }
    }
}

private enum TodoImageError: Error {
    // 不能通过context获取到compress的结果
    case getCompressResultFailed
    // compressResult 是 success 但是没拿到 Image 和 Data
    case getCompressImageAndDataFailed
    // uploader 从 context 中取参数时失败
    case uploaderGetContextFailed
}
#endif

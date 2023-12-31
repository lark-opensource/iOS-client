//
//  OpenShareForwardAlertProvider.swift
//  LarkForward
//
//  Created by huangjianming on 2020/2/14.
//

import Foundation
import UIKit
import UniverseDesignToast
import RxSwift
import LarkSDKInterface
import LarkSendMessage
import LarkModel
import LarkContainer
import LarkMessengerInterface
import Photos
import LarkAlertController
import LKCommonsLogging
import EENavigator
import LarkUIKit
import LarkNavigation
import LarkStorage
import AppContainer
import Homeric
import LKCommonsTracker
import RustPB
import UniverseDesignDialog
import ByteWebImage
import LarkRichTextCore
import LarkFeatureGating
import LarkEMM
import LarkSensitivityControl
import LarkBaseKeyboard

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
struct OpenShareError: Error { }

enum OpenShareType: String {
    case text
    case image
    case video
    case web
    case unknow
}

private let larkOpenShareKey = "larkOpenShareKey"

protocol BaseItem {
    var input: String? { get }
    var type: OpenShareType { get }
}

struct TextItem: BaseItem {
    var input: String?
    var type: OpenShareType = .text

    let content: String
}

struct VideoItem: BaseItem {
    var input: String?
    var type: OpenShareType = .video
    let data: Data
}

struct ImageItem: BaseItem {
    var input: String?
    var type: OpenShareType = .image

    let image: UIImage
}

struct WebItem: BaseItem {
    var input: String?
    var type: OpenShareType = .web

    let urlString: String
    let title: String
    let desc: String
    let icon: UIImage?
    let isNewStyle: Bool

    init(urlString: String, title: String, desc: String?, iconData: Data?, isNewStyle: Bool) {
        self.urlString = urlString
        self.title = title
        self.desc = desc ?? urlString
        self.icon = iconData.flatMap { UIImage(data: $0) }
        self.isNewStyle = isNewStyle
    }
}

final class OpenShareMessageSender: UserResolverWrapper {
    @ScopedInjectedLazy var videoMessageSendService: VideoMessageSendService?
    @ScopedInjectedLazy var sendMessageAPI: SendMessageAPI?
    @ScopedInjectedLazy var messageAPI: MessageAPI?
    let disposeBag = DisposeBag()
    let userResolver: UserResolver
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    var createScene: Basic_V1_CreateScene?

    fileprivate func sendExtraText(
        text: String?,
        chatID: String,
        msgid: String? = nil) {
        guard let text = text, !text.isEmpty else {
            return
        }
        if let msgid = msgid {
            messageAPI?.fetchMessage(id: msgid).subscribe(onNext: { [weak self] (message) in
                guard let self = self else { return }
                let content = RustPB.Basic_V1_RichText.text(text)
                self.sendMessageAPI?.sendText(context: nil,
                                             content: content,
                                             parentMessage: message,
                                             chatId: chatID,
                                             threadId: nil,
                                             createScene: self.createScene,
                                             sendMessageTracker: nil,
                                             stateHandler: nil)
            }).disposed(by: self.disposeBag)
        } else {
            let content = RustPB.Basic_V1_RichText.text(text)
            self.sendMessageAPI?.sendText(context: nil,
                                         content: content,
                                         parentMessage: nil,
                                         chatId: chatID,
                                         threadId: nil,
                                         createScene: .commonShare,
                                         sendMessageTracker: nil,
                                         stateHandler: nil)
        }
    }

    fileprivate func sendExtraText(
        attributeText: NSAttributedString?,
        chatID: String,
        msgid: String? = nil) {
            guard let attributeText = attributeText, attributeText.length != 0 else {
            return
        }
        if let msgid = msgid {
            messageAPI?.fetchMessage(id: msgid).subscribe(onNext: { [weak self] (message) in
                guard let self = self else { return }
                if var richText = RichTextTransformKit.transformStringToRichText(string: attributeText) {
                    richText.richTextVersion = 1
                    self.sendMessageAPI?.sendText(context: nil,
                                                 content: richText,
                                                 parentMessage: message,
                                                 chatId: chatID,
                                                 threadId: nil,
                                                 createScene: self.createScene,
                                                 sendMessageTracker: nil,
                                                 stateHandler: nil)
                }
            }).disposed(by: self.disposeBag)
        } else {
            if var richText = RichTextTransformKit.transformStringToRichText(string: attributeText) {
                richText.richTextVersion = 1
                self.sendMessageAPI?.sendText(context: nil,
                                             content: richText,
                                             parentMessage: nil,
                                             chatId: chatID,
                                             threadId: nil,
                                             createScene: self.createScene,
                                             sendMessageTracker: nil,
                                             stateHandler: nil)
            }
        }
    }

    fileprivate func sendText(text: String, chatIds: [String], index: Int, input: String?) {
        guard !text.isEmpty || !chatIds.isEmpty else {
            return
        }
        OpenShareForwardAlertProvider.logger.info("into send text method")
        let content = RustPB.Basic_V1_RichText.text(text)
        sendMessageAPI?.sendText(context: nil,
                                content: content,
                                parentMessage: nil,
                                chatId: chatIds[index],
                                threadId: nil,
                                createScene: self.createScene,
                                sendMessageTracker: nil) { [weak self] (state) in
            guard let self = self else { return }
            switch state {
            case .finishSendMessage(_, _, let msgId, _, _):
                self.sendExtraText(text: input, chatID: chatIds[index], msgid: msgId)
                let nextIndex = index + 1
                if chatIds.count > nextIndex {
                    self.sendText(text: text, chatIds: chatIds, index: nextIndex, input: input)
                }
            case .errorQuasiMessage, .errorSendMessage, .otherError:
                self.sendExtraText(text: input, chatID: chatIds[index])
                let nextIndex = index + 1
                if chatIds.count > nextIndex {
                    self.sendText(text: text, chatIds: chatIds, index: index, input: input)
                }
            default: break
            }
        }
    }

    fileprivate func sendText(text: String, chatIds: [String], index: Int, attributeInput: NSAttributedString?) {
        guard !text.isEmpty || !chatIds.isEmpty else {
            return
        }

        guard let attributeInput = attributeInput else {
            return
        }
        OpenShareForwardAlertProvider.logger.info("into send text method")
        if attributeInput.length != 0 {
            if var richText = RichTextTransformKit.transformStringToRichText(string: attributeInput) {
                richText.richTextVersion = 1
                sendMessageAPI?.sendText(context: nil,
                                        content: richText,
                                        parentMessage: nil,
                                        chatId: chatIds[index],
                                        threadId: nil,
                                        createScene: self.createScene,
                                        sendMessageTracker: nil) { [weak self] (state) in
                    guard let self = self else { return }
                    switch state {
                    case .finishSendMessage(_, _, let msgId, _, _):
                        self.sendExtraText(attributeText: attributeInput, chatID: chatIds[index], msgid: msgId)
                        let nextIndex = index + 1
                        if chatIds.count > nextIndex {
                            self.sendText(text: text, chatIds: chatIds, index: nextIndex, attributeInput: attributeInput)
                        }
                    case .errorQuasiMessage, .errorSendMessage, .otherError:
                        self.sendExtraText(attributeText: attributeInput, chatID: chatIds[index])
                        let nextIndex = index + 1
                        if chatIds.count > nextIndex {
                            self.sendText(text: text, chatIds: chatIds, index: index, attributeInput: attributeInput)
                        }
                    default: break
                    }
                }
            }
        }

    }
    // nolint: duplicated_code
    fileprivate func sendImage(image: UIImage, chatIds: [String], index: Int, input: String?) {
        let imageResourceResult = ImageSourceResult(sourceType: .jpeg, data: image.jpegData(compressionQuality: Const.compressionQuality), image: image)
        let imageMessageInfo = ImageMessageInfo(
            originalImageSize: image.size,
            sendImageSource: SendImageSource(cover: { () -> ImageSourceResult in
                imageResourceResult
            }, origin: { () -> ImageSourceResult in
                imageResourceResult
            })
        )

        let chatID = chatIds[index]
        self.sendMessageAPI?.sendImage(context: nil,
                                      parentMessage: nil,
                                      useOriginal: true,
                                      imageMessageInfo: imageMessageInfo,
                                      chatId: chatID,
                                      threadId: nil,
                                      createScene: self.createScene,
                                      sendMessageTracker: nil) { [weak self] (state) in
                                        guard let self = self else { return }
                                        switch state {
                                        case .finishSendMessage(_, _, let msgId, _, _):
                                            self.sendExtraText(text: input, chatID: chatIds[index], msgid: msgId)

                                            let nextIndex = index + 1
                                            if chatIds.count > nextIndex {
                                                self.sendImage(image: image,
                                                               chatIds: chatIds,
                                                               index: nextIndex,
                                                               input: input)
                                            }
                                        case .errorQuasiMessage, .errorSendMessage, .otherError:
                                            self.sendExtraText(text: input, chatID: chatIds[index])

                                            let nextIndex = index + 1
                                            if chatIds.count > nextIndex {
                                                self.sendImage(image: image,
                                                               chatIds: chatIds,
                                                               index: nextIndex,
                                                               input: input)
                                            }
                                        default: break
                                        }
        }
    }

    fileprivate func sendImage(image: UIImage, chatIds: [String], index: Int, attributeInput: NSAttributedString?) {
        let imageResourceResult = ImageSourceResult(sourceType: .jpeg, data: image.jpegData(compressionQuality: Const.compressionQuality), image: image)
        let imageMessageInfo = ImageMessageInfo(
            originalImageSize: image.size,
            sendImageSource: SendImageSource(cover: { () -> ImageSourceResult in
                imageResourceResult
            }, origin: { () -> ImageSourceResult in
                imageResourceResult
            })
        )

        let chatID = chatIds[index]
        self.sendMessageAPI?.sendImage(context: nil,
                                      parentMessage: nil,
                                      useOriginal: true,
                                      imageMessageInfo: imageMessageInfo,
                                      chatId: chatID,
                                      threadId: nil,
                                      createScene: self.createScene,
                                      sendMessageTracker: nil) { [weak self] (state) in
                                        guard let self = self else { return }
                                        switch state {
                                        case .finishSendMessage(_, _, let msgId, _, _):
                                            self.sendExtraText(attributeText: attributeInput, chatID: chatIds[index], msgid: msgId)

                                            let nextIndex = index + 1
                                            if chatIds.count > nextIndex {
                                                self.sendImage(image: image,
                                                               chatIds: chatIds,
                                                               index: nextIndex,
                                                               attributeInput: attributeInput)
                                            }
                                        case .errorQuasiMessage, .errorSendMessage, .otherError:
                                            self.sendExtraText(attributeText: attributeInput, chatID: chatIds[index])

                                            let nextIndex = index + 1
                                            if chatIds.count > nextIndex {
                                                self.sendImage(image: image,
                                                               chatIds: chatIds,
                                                               index: nextIndex,
                                                               attributeInput: attributeInput)
                                            }
                                        default: break
                                        }
        }
    }
    // enable-lint: duplicated_code
    fileprivate func sendVideo(data: Data, chatIds: [String], index: Int, input: String?, from: NavigatorFrom) {
        guard let fileURL = try? saveMedia(data: data).url else {
            return
        }

        guard chatIds.count > index else {
            return
        }
        let params = SendVideoParams(content: .fileURL(fileURL),
                                     isCrypto: false,
                                     isOriginal: false,
                                     forceFile: false,
                                     chatId: chatIds[index],
                                     threadId: nil,
                                     parentMessage: nil,
                                     from: from)
        self.videoMessageSendService?.sendVideo(with: params,
                                               extraParam: nil,
                                               context: nil,
                                               createScene: self.createScene,
                                               sendMessageTracker: nil) { [weak self] (state) in
            guard let self = self else { return }
            switch state {
            case .finishSendMessage(_, _, let msgId, _, _):
                self.sendExtraText(text: input, chatID: chatIds[index], msgid: msgId)

                let nextIndex = index + 1
                if chatIds.count > nextIndex {
                    self.sendVideo(data: data, chatIds: chatIds, index: nextIndex, input: input, from: from)
                }
            case .errorQuasiMessage, .errorSendMessage, .otherError:
                self.sendExtraText(text: input, chatID: chatIds[index])

                let nextIndex = index + 1
                if chatIds.count > nextIndex {
                    self.sendVideo(data: data, chatIds: chatIds, index: nextIndex, input: input, from: from)
                }
            default: break
            }
        }
    }

    fileprivate func sendVideo(data: Data, chatIds: [String], index: Int, attributeInput: NSAttributedString?, from: NavigatorFrom) {
        guard let fileURL = try? saveMedia(data: data).url else {
            return
        }

        guard chatIds.count > index else {
            return
        }
        let params = SendVideoParams(content: .fileURL(fileURL),
                                     isCrypto: false,
                                     isOriginal: false,
                                     forceFile: false,
                                     chatId: chatIds[index],
                                     threadId: nil,
                                     parentMessage: nil,
                                     from: from)
        self.videoMessageSendService?.sendVideo(with: params,
                                               extraParam: nil,
                                               context: nil,
                                               createScene: self.createScene,
                                               sendMessageTracker: nil) { [weak self] (state) in
            guard let self = self else { return }
            switch state {
            case .finishSendMessage(_, _, let msgId, _, _):
                self.sendExtraText(attributeText: attributeInput, chatID: chatIds[index], msgid: msgId)

                let nextIndex = index + 1
                if chatIds.count > nextIndex {
                    self.sendVideo(data: data, chatIds: chatIds, index: nextIndex, attributeInput: attributeInput, from: from)
                }
            case .errorQuasiMessage, .errorSendMessage, .otherError:
                self.sendExtraText(attributeText: attributeInput, chatID: chatIds[index])

                let nextIndex = index + 1
                if chatIds.count > nextIndex {
                    self.sendVideo(data: data, chatIds: chatIds, index: nextIndex, attributeInput: attributeInput, from: from)
                }
            default: break
            }
        }
    }

    fileprivate func sendWebCard(urlString: String,
                                 title: String,
                                 desc: String,
                                 icon: UIImage?,
                                 chatIds: [String],
                                 index: Int,
                                 input: String?) {
        func send(urlString: String,
                  title: String,
                  desc: String,
                  iconToken: String? = nil,
                  chatIds: [String],
                  index: Int,
                  input: String?) {
            OpenShareForwardAlertProvider.logger.info("into webcard v2 API")
            chatIds.forEach({ [weak self] (chatId) in
                guard let self = self else { return }
                self.sendMessageAPI?.sendShareAppCardMessage(context: nil,
                                                        type: .h5(appID: nil,
                                                                title: title,
                                                                iconToken: iconToken,
                                                                desc: desc,
                                                                url: urlString),
                                                        chatId: chatId)
                    .subscribe(onNext: {
                        if let extraText = input, !extraText.isEmpty {
                            self.sendMessageAPI?.sendText(
                                context: nil,
                                content: RustPB.Basic_V1_RichText.text(extraText),
                                parentMessage: nil,
                                chatId: chatId,
                                threadId: nil,
                                createScene: self.createScene,
                                sendMessageTracker: nil,
                                stateHandler: nil
                            )
                        }
                    }, onError: { (error) in
                        OpenShareForwardAlertProvider.logger.error("发送链接卡片失败", error: error)
                    })
                    .disposed(by: self.disposeBag)
            })
        }

        if let icon = icon,
           let data = icon.pngData(),
           let imageAPI = try? BootLoader.container.resolve(assert: ImageAPI.self) {
            imageAPI.uploadSecureImage(data: data, type: .normal, imageCompressedSizeKb: Const.imageCompressedSizeKb, encrypt: false)
            .subscribe(onNext: { (token) in
                send(urlString: urlString,
                     title: title,
                     desc: desc,
                     iconToken: token,
                     chatIds: chatIds,
                     index: index,
                     input: input)
            }, onError: { (error) in
                OpenShareForwardAlertProvider.logger.error("上传图片错误", error: error)
            })
            .disposed(by: disposeBag)
        } else {
            send(urlString: urlString,
                 title: title,
                 desc: desc,
                 chatIds: chatIds,
                 index: index,
                 input: input)
        }
    }

    fileprivate func sendWebCard(urlString: String,
                                 title: String,
                                 desc: String,
                                 icon: UIImage?,
                                 chatIds: [String],
                                 index: Int,
                                 attributeInput: NSAttributedString?) {
        func send(urlString: String,
                  title: String,
                  desc: String,
                  iconToken: String? = nil,
                  chatIds: [String],
                  index: Int,
                  attributeInput: NSAttributedString?) {
            OpenShareForwardAlertProvider.logger.info("into webcard v2 API")
            self.sendMessageAPI?.sendShareAppCardMessage(context: nil,
                                                    type: .h5(appID: nil,
                                                            title: title,
                                                            iconToken: iconToken,
                                                            desc: desc,
                                                            url: urlString),
                                                    chatId: chatIds[index])
                .subscribe(onNext: {
                    if let extraText = attributeInput, extraText.length != 0 {
                        if var richText = RichTextTransformKit.transformStringToRichText(string: extraText) {
                            richText.richTextVersion = 1
                            self.sendMessageAPI?.sendText(context: nil,
                                                    content: richText,
                                                    parentMessage: nil,
                                                    chatId: chatIds[index],
                                                    threadId: nil,
                                                    createScene: self.createScene,
                                                    sendMessageTracker: nil,
                                                    stateHandler: nil)
                        }
                    }
                }, onError: { (error) in
                    OpenShareForwardAlertProvider.logger.error("发送链接卡片失败", error: error)
                })
                .disposed(by: self.disposeBag)
        }

        if let icon = icon,
           let data = icon.pngData(),
           let imageAPI = try? BootLoader.container.resolve(assert: ImageAPI.self) {
            imageAPI.uploadSecureImage(data: data,
                                       type: .normal,
                                       imageCompressedSizeKb: Const.imageCompressedSizeKb,
                                       encrypt: false)
            .subscribe(onNext: { (token) in
                send(urlString: urlString,
                     title: title,
                     desc: desc,
                     iconToken: token,
                     chatIds: chatIds,
                     index: index,
                     attributeInput: attributeInput)
            }, onError: { (error) in
                OpenShareForwardAlertProvider.logger.error("上传图片错误", error: error)
            })
            .disposed(by: disposeBag)
        } else {
            send(urlString: urlString,
                 title: title,
                 desc: desc,
                 chatIds: chatIds,
                 index: index,
                 attributeInput: attributeInput)
        }
    }
}

extension OpenShareMessageSender {
    enum Const {
        static let compressionQuality: CGFloat = 0.75
        static let imageCompressedSizeKb: Int64 = 300
    }
}

struct OpenShareContentAlertContent: ForwardAlertContent {
    var type: OpenShareType = .unknow
    var item: BaseItem?
    var scheme: URL? //scheme of third app to jump back
    var sourceAppName: String? //name of third app
    private static let logger = Logger.log(OpenShareContentAlertContent.self, category: "Module.Forward.OpenShare")
    init() {
        let config = PasteboardConfig(token: Token("LARK-PSDA-open_share_sdk_paste_data"))
        if let data = SCPasteboard.general(config).data(forPasteboardType: larkOpenShareKey) {
            let dict: [String: Any]? = try? PropertyListSerialization.propertyList(from: data,
                                                                                   options: [],
                                                                                    format: nil) as? [String: Any]
            if let dict = dict {
                self.scheme = URL(string: dict["scheme"] as? String ?? "")
                self.sourceAppName = dict["AppName"] as? String
                if let typeStr = dict["type"] as? String, let type = OpenShareType(rawValue: typeStr) {
                    Tracer.trackEnterOpenShareForward(source: self.sourceAppName ?? "", type: type.rawValue)
                    self.type = type
                    Tracker.post(TeaEvent(Homeric.SHARESDK_OPEN_FEISHU,
                                          params: ["type": self.type.rawValue, "appname": self.sourceAppName ?? "unknow App"]))
                    switch type {
                    case .text:
                        if let content = dict["content"]as? String {
                            self.item = TextItem(content: content)
                            return
                        }
                        assert(false, "data error")
                    case .image:
                        if let data = dict["data"] as? Data, let image = UIImage(data: data) {
                            self.item = ImageItem(image: image)
                            return
                        }
                        assert(false, "data error")
                    case .video:
                        if let data: Data = dict["data"] as? Data {
                            self.item = VideoItem(data: data)
                            return
                        }
                        assert(false, "data error")
                    case .web:
                        if let data = dict["data"] as? [String: Any],
                            let title = data["title"] as? String,
                            let urlString = data["urlString"] as? String {

                            let desc = data["desc"] as? String
                            let iconData = data["iconData"] as? Data
                            let isNewStyle = (data["newStyle"] as? NSNumber)?.boolValue
                            self.item = WebItem(urlString: urlString,
                                                title: title,
                                                desc: desc,
                                                iconData: iconData,
                                                isNewStyle: isNewStyle ?? false)
                            return
                        }
                        assert(false, "data error")
                    case .unknow: assert(false, "data error")
                    }
                    OpenShareContentAlertContent.logger.error("OpenShare Data Error")
                }
            }
        }
    }
}

enum ErrorCode: String {
    case success = "0"
    case commonError = "-1"
    case userCancel = "-2"
    case sendFail = "-3"
}

func transform(with scheme: URL, code: ErrorCode) -> URL {
    var param = ["code": "-1"]
    param["code"] = code.rawValue
    let scheme = scheme.append(parameters: param)
    return scheme
}

final class OpenShareForwardAlertProvider: ForwardAlertProvider {
    static let logger = Logger.log(OpenShareForwardAlertProvider.self, category: "Module.Forward.OpenShare")
    let disposeBag = DisposeBag()
    var sender: OpenShareMessageSender {
        return OpenShareMessageSender(userResolver: self.userResolver)
    }
    static var isShareSuccess = true

    override var isSupportMention: Bool {
        return false
    }

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? OpenShareContentAlertContent != nil {
            return true
        }
        return false
    }

    override var shouldCreateGroup: Bool {
        return true
    }

    override func isShowInputView(by items: [ForwardItem]) -> Bool {
        return true
    }

    private func createTextContentView() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        // 话题置灰
        let includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig()
        ]
        return includeConfigs
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let chatContent = content as? OpenShareContentAlertContent else { return nil }
        var view: UIView?

        switch chatContent.type {
        case .text:
            guard let item = chatContent.item as? TextItem else { break }
            let container = UIView()
            container.backgroundColor = .clear
            let label = createTextContentView()
            container.addSubview(label)
            label.snp.makeConstraints { (make) in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
            }
            label.text = item.content
            view = container
            OpenShareForwardAlertProvider.logger.info("alert text type")
        case .video:
            guard let item = chatContent.item as? VideoItem else { break }
            var image: UIImage?
            if let mediaUrl = try? saveMedia(data: item.data).url {
                image = try? firstFrame(with: mediaUrl, size: CGSize(width: 64, height: 64))
            }
            view = ForwardVideoConfirmFooter(length: item.data.count, image: image)
        case .image:
            guard let item = chatContent.item as? ImageItem else { break }
            view = ForwardRawImageMessageConfirmFooter(image: item.image)
        case .web:
            guard let item = chatContent.item as? WebItem else { break }
            let container = UIView()
            let label = createTextContentView()
            container.addSubview(label)
            label.snp.makeConstraints { (make) in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
            }
            label.text = BundleI18n.LarkForward.Lark_Legacy_WebMessageHolder + item.title
            view = container
            OpenShareForwardAlertProvider.logger.info("alert web type")
        case .unknow:
            assert(false, "data error")
            OpenShareForwardAlertProvider.logger.error("OpenShare Data Error")
        }

        return view
    }

    override var isSupportMultiSelectMode: Bool {
        return true
    }

    override func dismissAction() {
        guard let content = content as? OpenShareContentAlertContent, let scheme = content.scheme else { return }
        UIApplication.shared.open(transform(with: scheme, code: .userCancel))
    }

    let resultSubject = BehaviorSubject<[String]>(value: [])

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        sender.createScene = .commonShare
        OpenShareForwardAlertProvider.isShareSuccess = true
        guard let content = content as? OpenShareContentAlertContent,
              let window = from.view.window else { return .just([]) }
        let topmostWindow = WindowTopMostFrom(vc: from)
        let chatAndUserIds = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        guard (chatAndUserIds.chatIds.count + chatAndUserIds.userIds.count) > 0 else {
            hud.showFailure(
                with: BundleI18n.LarkForward.Lark_Legacy_ChatViewForwardingFailed,
                on: window
            )
            return Observable.error(OpenShareError())
        }

        Tracer.trackOpenShareForwardConfirmed(source: content.sourceAppName ?? "", type: content.type.rawValue)
        let resultSubject = PublishSubject<[String]>()

        return self.checkAndCreateChats(chatIds: chatAndUserIds.chatIds,
                                        userIds: chatAndUserIds.userIds).do(onNext: { [weak self] (chats) in
            if chats.count == 1 {
                let body = ChatControllerByChatBody(chat: chats[0])
                let rootVC = self?.userResolver.navigator.navigation
                _ = rootVC?.popToRootViewController(animated: false)
                self?.userResolver.navigator.push(body: body, from: topmostWindow, animated: false)
            }
        }).flatMap { [weak self] (chatModels) -> Observable<[String]> in
            guard let self = self else {
                return Observable.of([""])
            }
            let chatIDs = chatModels.map { $0.id }
            switch content.type {
            case .text:
                guard let item = content.item as? TextItem else { return Observable.of([""]) }
                self.sender.sendText(text: item.content, chatIds: chatIDs, index: 0, input: input)
                OpenShareForwardAlertProvider.logger.info("sureAction text type")
                return Observable.of([""])
            case .image:
                guard let item = content.item as? ImageItem else { return Observable.of([""]) }
                self.sender.sendImage(image: item.image, chatIds: chatIDs, index: 0, input: input)
                return Observable.of([""])
            case .video:
                guard let item = content.item as? VideoItem else { return Observable.of([""]) }
                self.sender.sendVideo(data: item.data, chatIds: chatIDs, index: 0, input: input, from: from)
                return Observable.of([""])
            case .web:
                guard let item = content.item as? WebItem else { return Observable.of([""]) }
                if item.isNewStyle {
                    self.sender.sendWebCard(urlString: item.urlString,
                                                              title: item.title,
                                                              desc: item.desc,
                                                              icon: item.icon,
                                                              chatIds: chatIDs,
                                                              index: 0,
                                                              input: input)
                } else {
                    self.sender.sendText(text: item.urlString, chatIds: chatIDs, index: 0, input: input)
                }
                OpenShareForwardAlertProvider.logger.info("sureAction web type newStyle: \(item.isNewStyle)")
                return Observable.of([""])
            case .unknow:
                resultSubject.onNext([""])
                resultSubject.onCompleted()
            }
            return resultSubject
        }.observeOn(MainScheduler.instance)
            .do(onError: { [weak self](error) in
                self?.handleErrorAfterSureAction(error: error, hud: hud, from: topmostWindow)
            }, onCompleted: {
                hud.remove()
                if let scheme = content.scheme, let AppName = content.sourceAppName {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [weak self] in
                        guard let self = self else { return }
                        OpenShareForwardAlertProvider.showAlert(scheme: scheme, appName: AppName, from: topmostWindow, userResolver: self.userResolver)
                    }
                }
            })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        sender.createScene = .commonShare
        OpenShareForwardAlertProvider.isShareSuccess = true
        guard let content = content as? OpenShareContentAlertContent,
              let window = from.view.window else { return .just([]) }
        let topmostWindow = WindowTopMostFrom(vc: from)
        let chatAndUserIds = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        guard (chatAndUserIds.chatIds.count + chatAndUserIds.userIds.count) > 0 else {
            hud.showFailure(
                with: BundleI18n.LarkForward.Lark_Legacy_ChatViewForwardingFailed,
                on: window
            )
            return Observable.error(OpenShareError())
        }

        Tracer.trackOpenShareForwardConfirmed(source: content.sourceAppName ?? "", type: content.type.rawValue)
        let resultSubject = PublishSubject<[String]>()

        return self.checkAndCreateChats(chatIds: chatAndUserIds.chatIds,
                                        userIds: chatAndUserIds.userIds).do(onNext: { [weak self] (chats) in
            if chats.count == 1 {
                let body = ChatControllerByChatBody(chat: chats[0])
                let rootVC = self?.userResolver.navigator.navigation
                _ = rootVC?.popToRootViewController(animated: false)
                self?.userResolver.navigator.push(body: body, from: topmostWindow, animated: false)
            }
        }).flatMap { [weak self] (chatModels) -> Observable<[String]> in
            guard let self = self else {
                return Observable.of([""])
            }
            let chatIDs = chatModels.map { $0.id }
            switch content.type {
            case .text:
                guard let item = content.item as? TextItem else { return Observable.of([""]) }
                self.sender.sendText(text: item.content, chatIds: chatIDs, index: 0, attributeInput: attributeInput)
                OpenShareForwardAlertProvider.logger.info("sureAction mention text type")
                return Observable.of([""])
            case .image:
                guard let item = content.item as? ImageItem else { return Observable.of([""]) }
                self.sender.sendImage(image: item.image, chatIds: chatIDs, index: 0, attributeInput: attributeInput)
                return Observable.of([""])
            case .video:
                guard let item = content.item as? VideoItem else { return Observable.of([""]) }
                self.sender.sendVideo(data: item.data, chatIds: chatIDs, index: 0, attributeInput: attributeInput, from: from)
                return Observable.of([""])
            case .web:
                guard let item = content.item as? WebItem else { return Observable.of([""]) }
                if item.isNewStyle {
                    self.sender.sendWebCard(urlString: item.urlString,
                                            title: item.title,
                                            desc: item.desc,
                                            icon: item.icon,
                                            chatIds: chatIDs,
                                            index: 0,
                                            attributeInput: attributeInput)
                } else {
                    self.sender.sendText(text: item.urlString, chatIds: chatIDs, index: 0, attributeInput: attributeInput)
                }
                OpenShareForwardAlertProvider.logger.info("sureAction mention web type newStyle: \(item.isNewStyle)")
                return Observable.of([""])
            case .unknow:
                resultSubject.onNext([""])
                resultSubject.onCompleted()
            }
            return resultSubject
        }.observeOn(MainScheduler.instance)
            .do(onError: { [weak self] (error) in
                self?.handleErrorAfterSureAction(error: error, hud: hud, from: topmostWindow)
            }, onCompleted: {
                hud.remove()
                if let scheme = content.scheme, let AppName = content.sourceAppName {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [weak self] in
                        guard let self = self else { return }
                        OpenShareForwardAlertProvider.showAlert(scheme: scheme, appName: AppName, from: topmostWindow, userResolver: self.userResolver)
                    }
                }
            })
    }

    private func handleErrorAfterSureAction(error: Error, hud: UDToast, from: NavigatorFrom) {
        OpenShareForwardAlertProvider.isShareSuccess = false
        guard let vc = from.fromViewController else {
            assertionFailure()
            return
        }
        forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: vc, error: error)
    }

    static func showAlert(scheme: URL, appName: String, from: NavigatorFrom, userResolver: UserResolver) {
        let alert = LarkAlertController()
        let collectViewWidth: CGFloat = UDDialog.Layout.dialogWidth - Const.collectViewWidthOffset
        let baseView = UIView()
        let containerView = UIView()
        baseView.addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview()
            make.width.equalTo(collectViewWidth)
            make.height.equalTo(173)
            make.right.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        let imageView = UIImageView()
        imageView.image = Resources.share_success
        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.height.width.equalTo(125)
        }

        let titleLabel = UILabel()
        titleLabel.text = BundleI18n.LarkForward.Lark_Legacy_ShareSuccess
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp_bottomMargin).offset(20)
            make.height.equalTo(22)
            make.left.right.equalToSuperview()
        }

        alert.setContent(view: baseView)
        alert.addPrimaryButton(text: BundleI18n.LarkForward.Lark_Legacy_StayFeishu())
        alert.addSecondaryButton(text: BundleI18n.LarkForward.Lark_Legacy_ShareBack + appName,
                                 dismissCompletion: {
            if OpenShareForwardAlertProvider.isShareSuccess {
                UIApplication.shared.open((transform(with: scheme, code: .success)))
            } else {
                UIApplication.shared.open((transform(with: scheme, code: .sendFail)))
            }
        })
        userResolver.navigator.present(alert, from: from)
    }

    /// 获取视频第一帧
    private func firstFrame(with file: URL, size: CGSize) throws -> UIImage? {
        let asset = AVURLAsset(url: file)
        let generator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)

        guard let videoTrack = asset.tracks(withMediaType: .video).first else { return nil }

        let size = videoTrack.naturalSize
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: size.width, height: size.height)

        let image = try generator.copyCGImage(at: CMTimeMake(value: 0, timescale: 10), actualTime: nil)
        return UIImage(cgImage: image)
    }
}

extension OpenShareForwardAlertProvider {
    enum Const {
        static let collectViewWidthOffset: CGFloat = 40.0
    }
}

func saveMedia(data: Data) throws -> IsoPath {
    let tempDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "OpenShare"
    let filePath = tempDir + "Temp.mp4"
    try? tempDir.createDirectoryIfNeeded()
    try filePath.createFileIfNeeded(with: data)
    return filePath
}

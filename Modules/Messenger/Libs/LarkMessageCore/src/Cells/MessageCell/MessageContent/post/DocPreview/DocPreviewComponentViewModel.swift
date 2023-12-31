//
//  DocPreviewComponentViewModel.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/19.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import LarkCore
import EENavigator
import AsyncComponent
import LarkMessengerInterface
import RxSwift
import LarkContainer
import RustPB
import ByteWebImage

public protocol DocPreviewViewModelContextDependency: DocChatLifeCycleServiceDependency {
    func preloadDocFeed(_ url: String, from source: String)
    var thumbnailDecryptionAvailable: Bool { get }
    func downloadThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], imageViewSize: CGSize) -> Observable<UIImage>
}

public extension DocPreviewViewModelContextDependency {
    var thumbnailDecryptionAvailable: Bool { return true }
}

public protocol DocPreviewViewModelContext: PageContext {
    var docPreviewdependency: DocPreviewViewModelContextDependency? { get }
    var contextScene: ContextScene { get }
    func isBurned(message: Message) -> Bool
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterId: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
}

public final class DocPreviewComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: DocPreviewViewModelContext>: MessageSubViewModel<M, D, C> {
    @PageContext.InjectedLazy var chatSecurityAuditService: ChatSecurityAuditService?
    @PageContext.InjectedLazy var askOwnerDependency: AskOwnerDependency?
    @PageContext.InjectedLazy var docPermissionDependency: DocPermissionDependency?

    var contentPreferMaxWidth: CGFloat {
        let maxWidthLimit: CGFloat = 400
        return min(maxWidthLimit, metaModelDependency.getContentPreferMaxWidth(message))
    }

    var isFromMe: Bool {
        return context.isMe(message.fromId, chat: metaModel.getChat())
    }

    var contentPadding: CGFloat {
        return metaModelDependency.contentPadding
    }

    var permissionDesc: String {
        return self.message.permissionDesc(chat: self.metaModel.getChat())
    }

    var singlePageDesc: String {
        return self.message.singlePageDesc()
    }

    var permissionText: String? {
        return self.message.permissionText(chat: self.metaModel.getChat())
    }

    var isChatMyself: Bool {
        return context.isMe(metaModel.getChat().chatterId, chat: metaModel.getChat())
    }

    private var isDisplay: Bool = false

    public override func willDisplay() {
        super.willDisplay()
        preloadContentIfNeededFor(message)
        isDisplay = true
    }

    public override func didEndDisplay() {
        super.didEndDisplay()
        isDisplay = false
    }

    deinit {
        if !isDisplay, let url = self.message.docAbstract {
            LarkImageService.shared.removeCache(resource: .default(key: url), options: .memory)
        }
    }

    private func preloadContentIfNeededFor(_ message: Message?) {
        guard let message = message else { return }
        let urls: [URL] = {
            var urls: [URL] = []
            var richText: RustPB.Basic_V1_RichText?
            if message.type == .text,
                let content = message.content as? TextContent {
                richText = content.richText
            } else if message.type == .post,
                let content = message.content as? PostContent {
                richText = content.richText
            } else if message.type == .card,
                let content = message.content as? CardContent {
                richText = content.richText
            }
            if let richText = richText {
                for element in richText.elements.values {
                    let text: String = {
                        switch element.tag {
                        case .a:
                            return element.property.anchor.href
                        case .link:
                            return element.property.link.url
                        @unknown default:
                            return ""
                        }
                    }()
                    guard let url = URL(string: text) else { continue }
                    urls.append(url)
                }
            }
            return urls
        }()
        urls.forEach { context.docPreviewdependency?.preloadDocFeed($0.absoluteString, from: "message") }
    }
}

// MARK: - DocPreviewActionDelegate
extension DocPreviewComponentViewModel: DocPreviewActionDelegate {
    public func docPreviewDidTappedDetail() {
        guard let urlStr = message.doc?.url, let url = try? URL.forceCreateURL(string: urlStr) else {
            tcLogger.error("[URLPreview] doc url create failed: \(message.doc?.url)")
            return
        }
        if self.context.contextScene == .newChat || self.context.contextScene == .threadChat {
            IMTracker.Chat.Main.Click.Msg.Doc(self.metaModel.getChat(), self.message, url, self.context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        } else if self.context.contextScene == .threadDetail || self.context.contextScene == .replyInThread {
            ChannelTracker.TopicDetail.Click.Msg.Doc(self.metaModel.getChat(), self.message)
        }
        let chat = metaModel.getChat()
        self.chatSecurityAuditService?.auditEvent(.clickLink(url: urlStr, chatId: chat.id, chatType: chat.type), isSecretChat: false)
        if let httpUrl = url.lf.toHttpUrl() {
            context.navigator(type: .push, url: httpUrl, params: NavigatorParams(context: [
                "from": "message",
                "message_type": "richtext",
                "scene": "messenger",
                "location": "messenger_chat"
            ]))
        }
    }

    public func docPreviewWillChangePermission(sourceView: UIView?) {
        guard let permission = message.docPermission, permission.optionalPermissions.isEmpty == false else { return }
        let body = DocChangePermissionBody(docPermission: permission, chat: metaModel.getChat(), sourceView: sourceView)
        context.navigator(type: .present, body: body, params: nil)
    }

    public var thumbnailDecryptionAvailable: Bool {
        return context.docPreviewdependency?.thumbnailDecryptionAvailable ?? false
    }

    public func downloadThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], imageViewSize: CGSize) -> Observable<UIImage> {
        return context.docPreviewdependency?.downloadThumbnail(url: url, fileType: fileType, thumbnailInfo: thumbnailInfo, imageViewSize: imageViewSize) ?? .empty()
    }
}

public final class PinDocPreviewComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: DocPreviewViewModelContext>: MessageSubViewModel<M, D, C> {
    public override var identifier: String {
        return "PinDocPreview"
    }

    public override var contentConfig: ContentConfig? {
        return ContentConfig(hasMargin: false, backgroundStyle: .white, maskToBounds: true, supportMutiSelect: true)
    }

    public var messageId: String {
        return message.id
    }

    var contentPreferMaxWidth: CGFloat {
        return metaModelDependency.getContentPreferMaxWidth(message) - 2 * metaModelDependency.contentPadding
    }

    public var displayContent: [ComponentWithContext<C>] {
        let props = UILabelComponentProps()
        props.text = self.message.docOwner
        props.font = UIFont.ud.body2
        props.numberOfLines = 1
        props.textColor = UIColor.ud.N500
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        return [UILabelComponent<C>(props: props, style: style)]
    }
}

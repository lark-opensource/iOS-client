//
//  URLPreviewComponentViewModel.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/6/23.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import LarkCore
import Swinject
import LarkMessengerInterface
import Homeric
import EENavigator
import LKCommonsTracker
import LarkContainer

protocol URLPreviewComponentViewModelContext: PageContext, ColorConfigContext {
    var contextScene: ContextScene { get }
    func isBurned(message: Message) -> Bool
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterID: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
}

final class URLPreviewComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: URLPreviewComponentViewModelContext>: MessageSubViewModel<M, D, C> {
    @PageContext.InjectedLazy var chatSecurityAuditService: ChatSecurityAuditService?

    override public var identifier: String {
        return "urlPreview"
    }

    /// 预览标题颜色
    lazy var titleColor: UIColor = {
        let isFromMe = context.isMe(message.fromChatter?.id ?? "", chat: metaModel.getChat())
        return context.getColor(for: .Message_Text_Foreground, type: isFromMe ? .mine : .other)
    }()

    /// 预览描述
    var content: NSAttributedString {
        return self.message.urlContent(textColor: self.contentColor)
    }
    lazy var contentColor: UIColor = {
        let isFromMe = context.isMe(message.fromChatter?.id ?? "", chat: metaModel.getChat())
        return context.getColor(for: .Message_Text_Foreground, type: isFromMe ? .mine : .other)
    }()

    /// 分割线颜色
    lazy var lineColor: UIColor = {
        let isFromMe = context.isMe(message.fromChatter?.id ?? "", chat: metaModel.getChat())
        return context.getColor(for: .Message_BubbleSplitLine, type: isFromMe ? .mine : .other)
    }()

    public var contentMaxWidth: CGFloat {
        return metaModelDependency.getContentPreferMaxWidth(message) - 2 * metaModelDependency.contentPadding
    }

    func tapContent() {
        guard let urlContent = self.message.urlContent, let url = URL(string: urlContent.url)?.lf.toHttpUrl() else { return }
        let chat = metaModel.getChat()
        self.chatSecurityAuditService?.auditEvent(.clickLink(url: urlContent.url, chatId: chat.id, chatType: chat.type), isSecretChat: false)

        if urlContent.hasVideoInfo {
            self.trackVideoPreviewClick(site: urlContent.videoInfo.site)
        }
        context.navigator(type: .push, url: url, params: NavigatorParams(
            context: ["scene": "messenger", "location": "messenger_chat", "from": "message", "chat_type": self.metaModel.getChat().trackType]
        ))
    }

    func tapVideo(cover: UIImageView) {
        if let urlContent = self.message.urlContent {
            self.trackVideoPreviewClick(site: urlContent.videoInfo.site)
            if self.context.contextScene == .newChat || self.context.contextScene == .threadChat {
                IMTracker.Chat.Main.Click.Msg.Media(self.metaModel.getChat(), self.message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
            } else if self.context.contextScene == .threadDetail || self.context.contextScene == .replyInThread {
                ChannelTracker.TopicDetail.Click.Msg.Media(self.metaModel.getChat(), self.message)
            }
            let videoInfo = urlContent.videoInfo
            var asset: Asset = Asset(sourceType: .image(urlContent.coverImage))
            asset.visibleThumbnail = cover
            asset.isVideo = true
            asset.videoUrl = urlContent.url
            asset.videoId = videoInfo.vid
            if let mediaContent = message.content as? MediaContent {
                asset.duration = mediaContent.duration
            }
            context.navigator(type: .present, body: PlayWebVideoBody(asset: asset, site: videoInfo.site), params: nil)
        }
    }

    private func trackVideoPreviewClick(site: VideoSite) {
        var source: String?
        switch site {
        case .xigua:
            source = "xigua"
        case .douyin:
            source = "douyin"
        case .youtube:
            source = "youtube"
        @unknown default:
            break
        }
        if let source = source {
            Tracker.post(TeaEvent(Homeric.VIDEO_URL_PLAY, params: ["video_source": source]))
        }
    }
}

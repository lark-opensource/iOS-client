//
//  ForwardMessageContentPreviewAlertConfig.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/19.
//

import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer
import LarkSetting

// 有消息实体的消息预览确认框配置
public class ForwardMessageContentPreviewAlertConfig: ForwardAlertConfig {
    @ScopedInjectedLazy var chatSecurity: ChatSecurityControlService?
    @ScopedInjectedLazy var chatAPI: ChatAPI?
    @ScopedInjectedLazy var messageAPI: MessageAPI?
    @ScopedInjectedLazy var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy var mergeForwardContentService: MergeForwardContentService?
    var disposeBag: DisposeBag = DisposeBag()
    /// 转发内容一级预览FG开关
    lazy var forwardDialogContentFG: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.dialog_content_new"))
    }()
    /// 转发内容二级预览FG开关
    lazy var forwardContentPreviewFG: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core_forward_content_preview"))
    }()
    lazy var contentPreviewHandler: LarkForwardContentPreviewHandler? = {
        guard let chatAPI = self.chatAPI,
              let messageAPI = self.messageAPI,
              let chatterAPI = self.chatterAPI
        else { return nil }
        let contentPreviewHandler = LarkForwardContentPreviewHandler(chatAPI: chatAPI,
                                                                     messageAPI: messageAPI,
                                                                     chatterAPI: chatterAPI,
                                                                     userResolver: userResolver)
        return contentPreviewHandler
    }()
    func clearDisposeBag() {
        disposeBag = DisposeBag()
    }
}

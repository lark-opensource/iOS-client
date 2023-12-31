//
//  ShareTodoHandler.swift
//  TodoMod
//
//  Created by 张威 on 2021/1/21.
//

#if MessengerMod
import LarkMessengerInterface
import LarkAccountInterface
import LarkModel
import Swinject
import EENavigator
import RxSwift
import TodoInterface
import LarkUIKit
import Todo
import UniverseDesignFont

/// 处理 Todo 分享（分享到 chat）

extension SelectSharingItemBody: ForwardAlertContent {}

public final class ShareTodoAlertProvider: ForwardAlertProvider {
    public override var needSearchOuterTenant: Bool { true }
    public override var maxSelectCount: Int { 10 }
    public override var isSupportMultiSelectMode: Bool { true }
    public override class func canHandle(content: ForwardAlertContent) -> Bool {
        return (content is SelectSharingItemBody)
    }
    public override func isShowInputView(by items: [ForwardItem]) -> Bool {
        return true
    }
    public override func getFilter() -> ForwardDataFilter? {
        guard let body = content as? SelectSharingItemBody else { return nil }
        let ignoreBot = body.ignoreBot
        return { (item) -> Bool in
            if item.type == .bot {
                if ignoreBot == true {
                    return false
                }
            }
            return true
        }
    }
    public override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        if let content = content as? SelectSharingItemBody, content.ignoreBot {
            return [
                ForwardUserEnabledEntityConfig(),
                ForwardGroupChatEnabledEntityConfig(),
                ForwardThreadEnabledEntityConfig()
            ]
        }
        return super.getForwardItemsIncludeConfigsForEnabled()
    }
    public override func getForwardItemsIncludeConfigs() -> IncludeConfigs? {
        if let content = content as? SelectSharingItemBody, content.ignoreBot {
            /// 下列默认实现表示不过滤
            return [
                ForwardUserEntityConfig(),
                ForwardGroupChatEntityConfig(),
                ForwardThreadEntityConfig()
            ]
        }
        return super.getForwardItemsIncludeConfigs()
    }
    public override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let body = content as? SelectSharingItemBody else {
            return nil
        }
        let contentView = ShareConfirmContentView()
        contentView.title = body.summary
        contentView.showIcon = body.showIcon
        return contentView
    }

    public override func dismissAction() {
        guard let body = content as? SelectSharingItemBody else { return }
        body.onCancel?()
    }

    public override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let body = content as? SelectSharingItemBody else {
            return .just([])
        }

        // 参考: ForwardAlertProvider#itemsToIds
        var shareItems = [SelectSharingItemBody.SharingItem]()
        for item in items {
            switch item.type {
            case .chat:
                shareItems.append(.chat(chatId: item.id))
            case .bot:
                shareItems.append(.bot(botId: item.id))
            case .user:
                shareItems.append(.user(userId: item.id))
            case .generalFilter:
                shareItems.append(.generalFilter(id: item.id))
            case .threadMessage:
                if let chatId = item.channelID {
                    shareItems.append(.thread(threadId: item.id, chatId: chatId))
                }
            case .replyThreadMessage:
                if let chatId = item.channelID {
                    shareItems.append(.replyThread(threadId: item.id, chatId: chatId))
                }
            case .unknown, .myAi:
                 break
            }
        }
        body.onConfirm?(shareItems, input)

        return .just([])
    }

    /// 填充到 ShareConfirm 里的 contentView

    private class ShareConfirmContentView: UIView {

        var title: String = "" {
            didSet { titleLabel.text = title }
        }

        var showIcon: Bool = true {
            didSet {
                if showIcon != oldValue {
                    remakeConstraints()
                }
            }
        }

        private let iconImageView = UIImageView()
        private let titleLabel = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = UIColor.ud.bgFloatOverlay
            layer.cornerRadius = 5

            iconImageView.image = Todo.Resources.share

            titleLabel.numberOfLines = 3
            titleLabel.lineBreakMode = .byTruncatingMiddle
            titleLabel.textColor = UIColor.ud.textTitle
            titleLabel.font = UDFont.systemFont(ofSize: 14)

            addSubview(iconImageView)
            addSubview(titleLabel)

            remakeConstraints()
        }

        private func remakeConstraints() {
            iconImageView.isHidden = !showIcon
            if showIcon {
                iconImageView.snp.remakeConstraints { make in
                    make.width.height.equalTo(64)
                    make.left.top.equalTo(10)
                    make.bottom.equalToSuperview().offset(-10)
                }
                titleLabel.snp.remakeConstraints { make in
                    make.top.equalTo(iconImageView.snp.top).offset(4)
                    make.bottom.lessThanOrEqualTo(iconImageView.snp.bottom).offset(-4)
                    make.left.equalTo(iconImageView.snp.right).offset(10)
                    make.right.equalToSuperview().offset(-10)
                }
            } else {
                titleLabel.snp.remakeConstraints { make in
                    make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12))
                    make.height.equalTo(36)
                }
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }
}
#endif

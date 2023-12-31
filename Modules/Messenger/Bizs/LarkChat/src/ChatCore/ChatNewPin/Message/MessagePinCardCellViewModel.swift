//
//  MessagePinCardCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/31.
//

import Foundation
import LarkOpenChat
import RustPB
import LarkModel
import RichLabel
import LarkExtensions
import AsyncComponent
import LarkContainer
import LarkMessengerInterface
import UniverseDesignIcon
import LarkCore
import ThreadSafeDataStructure
import LarkMessageCore
import LarkMessageBase
import LarkSDKInterface
import EENavigator

public class MessagePinCardCellViewModel: ChatPinCardCellViewModel,
                                          ChatPinCardActionProvider, ChatPinCardRenderAbility {
    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .messagePin
    }

    public class var reuseIdentifier: String? {
        return "MessagePinCardCellViewModel"
    }

    public override class func canInitialize(context: ChatPinCardContext) -> Bool {
        return true
    }

    private var metaModel: ChatPinCardCellMetaModel?
    private let enableMessageEngine: Bool
    @ScopedInjectedLazy private var topNoticeService: ChatTopNoticeService?
    private let contentAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                                    .foregroundColor: UIColor.ud.textTitle]
    private let unfairLock: UnsafeMutablePointer<os_unfair_lock_s>
    private var layoutEngine: LKTextLayoutEngine
    private var writeLayoutEngine: LKTextLayoutEngine
    private var textParser: LKTextParser
    private var writeTextParser: LKTextParser

    public required init(context: ChatPinCardContext) {
        unfairLock = UnsafeMutablePointer.allocate(capacity: 1)
        unfairLock.initialize(to: os_unfair_lock_s())
        self.layoutEngine = LKTextLayoutEngineImpl()
        self.writeLayoutEngine = LKTextLayoutEngineImpl()
        self.textParser = LKTextParserImpl()
        self.writeTextParser = LKTextParserImpl()
        self.enableMessageEngine = context.userResolver.fg.staticFeatureGatingValue(with: "im.chat.pinned.msg")
        super.init(context: context)
    }

    deinit {
         unfairLock.deallocate()
     }

    public override func modelDidChange(model: ChatPinCardCellMetaModel) {
        self.metaModel = model
        guard let message = (model.pin.payload as? MessageChatPinPayload)?.message,
              MessagePinUtils.checkVisible(message: message, chat: model.chat) else {
            canShowMessage = false
            return
        }
        canShowMessage = true
        if enableMessageEngine {
            self.updateComponentRenderer(model)
        } else {
            let summerizeAttrStr = self.topNoticeService?.getTopNoticeMessageSummerize(message, customAttributes: contentAttributes) ?? NSAttributedString(string: "")
            let messageSummerize = NSMutableAttributedString(attributedString: summerizeAttrStr)
            switch message.type {
            case .text, .post:
                if message.isMultiEdited {
                    messageSummerize.append(NSAttributedString(string: BundleI18n.LarkChat.Lark_IM_EditMessage_Edited_Label,
                                                               attributes: [.font: UIFont.systemFont(ofSize: 12),
                                                                            .foregroundColor: UIColor.ud.textCaption]))
                }
            default:
                break
            }

            writeTextParser.originAttrString = messageSummerize
            writeTextParser.parse()
            writeLayoutEngine.outOfRangeText = NSAttributedString(string: "\u{2026}", attributes: self.contentAttributes)
            writeLayoutEngine.attributedText = writeTextParser.renderAttrString
            writeLayoutEngine.preferMaxWidth = self.context.contentAvailableMaxWidth
            os_unfair_lock_lock(unfairLock)
            self.textParser = writeTextParser.clone() as? LKTextParserImpl ?? LKTextParserImpl()
            self.layoutEngine = writeLayoutEngine.clone() as? LKTextLayoutEngineImpl ?? LKTextLayoutEngineImpl()
            os_unfair_lock_unlock(unfairLock)
        }
    }

    public func getActionItems() -> [ChatPinActionItemType] {
        if canShowMessage {
            return [.item(ChatPinActionItem(title: BundleI18n.LarkChat.Lark_IM_GroupChatUnclipMessage_ViewInChat_Button,
                                            image: UDIcon.getIconByKey(.viewinchatOutlined, size: CGSize(width: 20, height: 20)),
                                            handler: JumpToChatPinCardActionHandler(targetVC: self.context.targetViewController,
                                                                                    nav: self.context.userResolver.navigator,
                                                                                    auditService: try? self.context.userResolver.resolve(assert: ChatSecurityAuditService.self)))),
                    .commonType(.stickToTop),
                    .commonType(.unSticktoTop),
                    .commonType(.unPin)]
        } else {
            return [.commonType(.unPin)]
        }
    }

    private let iconSize: CGFloat = 18
    private var canShowMessage: Bool = false

    public func getIconConfig() -> ChatPinIconConfig? {
        guard let messagePayload = self.metaModel?.pin.payload as? MessageChatPinPayload,
              let message = messagePayload.message,
              self.canShowMessage else {
            return nil
        }
        let iconResource = ChatPinIconResource.resource(resource: .avatar(key: message.fromChatter?.avatarKey ?? "",
                                                                          entityID: message.fromChatter?.id ?? "",
                                                                          params: .init(sizeType: .size(iconSize))),
                                                        config: ChatPinIconResource.ImageConfig(tintColor: nil, placeholder: nil))
        return ChatPinIconConfig(iconResource: iconResource, size: CGSize(width: iconSize, height: iconSize), cornerRadius: iconSize / 2)
    }

    public func createTitleView() -> MessagePinCardTitleView {
        return MessagePinCardTitleView(frame: .zero)
    }

    public func updateTitletView(_ view: MessagePinCardTitleView) {
        if let metaModel = metaModel,
           let message = (metaModel.pin.payload as? MessageChatPinPayload)?.message,
           self.canShowMessage {
            let title = message.fromChatter?.displayName(chatId: metaModel.chat.id,
                                                         chatType: metaModel.chat.type,
                                                         scene: .reply) ?? ""
            let timeStr = message.createTime.lf.cacheFormat("MessagePinCardCellViewModel", formater: {
                $0.lf.formatedTime_v2()
            })
            view.update(notVisible: false, tipAttr: nil, title: title, timeStr: timeStr)
        } else {
            view.update(notVisible: true, tipAttr: self.messageNotVisibleAttrText, title: "", timeStr: "")
        }
    }

    public func getTitleSize() -> CGSize {
        if self.canShowMessage {
            return CGSize(width: self.context.headerAvailableMaxWidth - iconSize, height: MessagePinCardTitleView.titleFont.figmaHeight)
        } else {
            let textHeight = messageNotVisibleAttrText.componentTextSize(for: CGSize(width: self.context.headerAvailableMaxWidth, height: CGFloat.infinity), limitedToNumberOfLines: 0).height
            return CGSize(width: self.context.headerAvailableMaxWidth, height: textHeight + 5)
        }
    }

    private var messageEnginVMFactory: MessageEngineCellViewModelFactory<PageContext>? {
        return try? self.context.userResolver.resolve(assert: MessageEngineCellViewModelFactory.self)
    }

    private var engineVM: SafeAtomic<MessageListEngineViewModel<MessageEngineMetaModel, MessageEngineCellMetaModelDependency, PageContext>?> = nil + .readWriteLock

    private var engineVMDependency: MessageEngineCellMetaModelDependency?
    private func updateComponentRenderer(_ metaModel: ChatPinCardCellMetaModel) {
        guard let vmFactory = self.messageEnginVMFactory  else { return }

        guard let message = (metaModel.pin.payload as? MessageChatPinPayload)?.message else {
            return
        }
        let chat = metaModel.chat

        let metaModel = MessageEngineMetaModel(message: message, getChat: { return chat })

        engineVMDependency?.contentPreferMaxWidth = { [weak self] message in
            return ChatCellUIStaticVariable.getContentPreferMaxWidth(
                message: message,
                maxCellWidth: self?.context.contentAvailableMaxWidth ?? 0,
                maxContentWidth: self?.context.contentAvailableMaxWidth ?? 0,
                bubblePadding: 0
            )
        }
        engineVMDependency?.maxCellWidth = { [weak self] _ in return self?.context.contentAvailableMaxWidth ?? 0 }
        if let engineVM = self.engineVM.value, let metaModelDependency = self.engineVMDependency {
            // 如果messageID变更，则完全替换
            if !engineVM.update(metaModels: [metaModel], metaModelDependency: metaModelDependency) {
                engineVM.reset(metaModels: [metaModel], metaModelDependency: metaModelDependency)
            }
        } else {
            let engineVM = MessageListEngineViewModel(
                metaModels: [metaModel],
                metaModelDependency: { [weak self] renderer in
                    let metaModelDependency = MessageEngineCellMetaModelDependency(
                        renderer: renderer,
                        contentPadding: 0,
                        contentPreferMaxWidth: { [weak self] message in
                            return ChatCellUIStaticVariable.getContentPreferMaxWidth(
                                message: message,
                                maxCellWidth: self?.context.contentAvailableMaxWidth ?? 0,
                                maxContentWidth: self?.context.contentAvailableMaxWidth ?? 0,
                                bubblePadding: 0
                            )
                        },
                        maxCellWidth: { [weak self] _ in return self?.context.contentAvailableMaxWidth ?? 0 },
                        updateRootComponent: { [weak self] in
                            self?.engineVM.value?.updateRootComponent()
                        },
                        avatarConfig: MessageEngineAvatarConfig(showAvatar: false),
                        headerConfig: MessageEngineHeaderConfig(showHeader: false)
                    )
                    self?.engineVMDependency = metaModelDependency
                    return metaModelDependency
                },
                vmFactory: vmFactory
            )
            self.engineVM.value = engineVM
        }
    }

    public func createContentView() -> MessagePinCardContentView {
        return MessagePinCardContentView()
    }

    public func updateContentView(_ view: MessagePinCardContentView) {
        view.tapView.gestureRecognizers?.forEach({ view.removeGestureRecognizer($0) })
        _ = view.tapView.lu.addTapGestureRecognizer(action: #selector(onClickContent), target: self)
        view.setInteractionEnabled(self.enableMessageEngine && isMessageInteractionEnabled)

        if self.enableMessageEngine {
            view.containerView.isHidden = false
            view.contentLabel.isHidden = true
            self.engineVM.value?.renderer.bind(to: view.containerView)
            self.engineVM.value?.renderer.render(view.containerView)
        } else {
            view.containerView.isHidden = true
            view.contentLabel.isHidden = false
            os_unfair_lock_lock(unfairLock)
            view.contentLabel.textParser = textParser
            let engine = layoutEngine
            os_unfair_lock_unlock(unfairLock)
            view.contentLabel.setForceLayout(engine)
            view.contentLabel.backgroundColor = UIColor.clear
        }
    }

    private var isMessageInteractionEnabled: Bool {
        guard let metaModel = self.metaModel,
              let message = (metaModel.pin.payload as? MessageChatPinPayload)?.message else {
            return false
        }
        return message.type == .card
    }

    @objc
    private func onClickContent() {
        guard let metaModel = self.metaModel,
              let message = (metaModel.pin.payload as? MessageChatPinPayload)?.message else {
            return
        }
        MessagePinUtils.onClick(
            message: message,
            chat: metaModel.chat,
            pinID: metaModel.pin.id,
            navigator: self.context.userResolver.navigator,
            targetVC: self.context.targetViewController,
            auditService: try? self.context.userResolver.resolve(assert: ChatSecurityAuditService.self)
        )
        IMTracker.Chat.Sidebar.Click.open(metaModel.chat, topId: metaModel.pin.id, messageId: message.id, type: .message)
    }

    public func getContentSize() -> CGSize {
        if !canShowMessage {
            return .zero
        }
        if enableMessageEngine {
            return self.engineVM.value?.renderer.size() ?? .zero
        } else {
            let size = self.writeLayoutEngine.layout(size: CGSize(width: self.context.contentAvailableMaxWidth, height: CGFloat.infinity))
            os_unfair_lock_lock(unfairLock)
            self.layoutEngine = self.writeLayoutEngine.clone()
            os_unfair_lock_unlock(unfairLock)
            return size
        }
    }

    public var showCardFooter: Bool {
        return canShowMessage
    }

    public var supportFold: Bool {
        return true
    }

    private var messageNotVisibleAttrText: NSAttributedString {
        if (metaModel?.pin.payload as? MessageChatPinPayload)?.message?.isDeleted ?? false {
            let attrText = NSAttributedString(
                string: BundleI18n.LarkChat.Lark_IM_PinnedMessageDeleted_Text,
                attributes: [.font: UIFont.systemFont(ofSize: 14),
                             .foregroundColor: UIColor.ud.textCaption]
            )
            return attrText
        } else {
            return notVisibleDefaultAttrText
        }
    }

    private var notVisibleDefaultAttrText: NSAttributedString = {
        let messageNotVisibleAttrText = NSAttributedString(
            string: BundleI18n.LarkChat.Lark_IM_SuperApp_PinnedItemNotVisible_Text,
            attributes: [.font: UIFont.systemFont(ofSize: 14),
                         .foregroundColor: UIColor.ud.textCaption]
        )
        return messageNotVisibleAttrText
    }()
}

extension MessagePinCardCellViewModel: ChatPinCardCellLifeCycle {
    public func willDisplay() {
        self.engineVM.value?.willDisplay()
    }

    public func didEndDisplay() {
        self.engineVM.value?.didEndDisplay()
    }

    public func onResize() {
        self.engineVM.value?.onResize()
    }
}

public final class MessagePinCardContentView: UIView {

    var contentLabel: LKLabel = LKLabel()
    var containerView: UIView = UIView()
    var tapView: UIView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(contentLabel)
        self.addSubview(containerView)
        self.addSubview(tapView)
        containerView.isUserInteractionEnabled = false
        contentLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tapView.isUserInteractionEnabled = true
        tapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    func setInteractionEnabled(_ enable: Bool) {
        tapView.isHidden = enable
        containerView.isUserInteractionEnabled = enable
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class MessagePinCardTitleView: UIView {

    static let titleFont = UIFont.systemFont(ofSize: 14, weight: .medium)

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = Self.titleFont
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    private lazy var lineView: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        return lineView
    }()

    private lazy var timeLabel: UILabel = {
        let timeLabel = UILabel()
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = UIColor.ud.textPlaceholder
        timeLabel.numberOfLines = 1
        return timeLabel
    }()

    private lazy var notVisibleTipLabel: UILabel = {
        let tipLabel = UILabel()
        tipLabel.numberOfLines = 0
        return tipLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(notVisibleTipLabel)
        self.addSubview(titleLabel)
        self.addSubview(lineView)
        self.addSubview(timeLabel)
        notVisibleTipLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        titleLabel.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
        }
        lineView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(6)
            make.centerY.equalToSuperview()
            make.width.equalTo(1)
            make.height.equalTo(12)
        }
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(lineView.snp.right).offset(6)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    func update(notVisible: Bool, tipAttr: NSAttributedString?, title: String, timeStr: String) {
        if notVisible {
            notVisibleTipLabel.isHidden = false
            notVisibleTipLabel.attributedText = tipAttr
            titleLabel.isHidden = true
            lineView.isHidden = true
            timeLabel.isHidden = true
        } else {
            notVisibleTipLabel.isHidden = true
            titleLabel.isHidden = false
            titleLabel.text = title
            lineView.isHidden = false
            timeLabel.isHidden = false
            timeLabel.text = timeStr
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Message {
    var canShowForChatPin: Bool {
        return !isDeleted && isVisible && !isBurned
    }
}

struct MessagePinUtils {
    static func checkVisible(message: Message, chat: Chat) -> Bool {
        if message.threadMessageType == .threadReplyMessage {
            return message.canShowForChatPin
        } else {
            return message.canShowForChatPin && message.position > chat.firstMessagePostion
        }
    }

    static func onClick(message: Message, chat: Chat, pinID: Int64, navigator: Navigatable, targetVC: UIViewController, auditService: ChatSecurityAuditService?) {
        guard Self.checkVisible(message: message, chat: chat) else { return }

        auditService?.auditEvent(.chatPin(type: .clickBackToChat(chatId: chat.id, pinId: pinID)),
                                 isSecretChat: false)
        if message.threadMessageType == .threadReplyMessage {
            let body = ReplyInThreadByModelBody(message: message,
                                                chat: chat,
                                                loadType: .position,
                                                position: message.threadPosition,
                                                sourceType: .other)
            navigator.push(body: body, from: targetVC)
        } else {
            let body = ChatControllerByChatBody(chat: chat,
                                                position: message.position,
                                                messageId: message.id)
            navigator.push(body: body, from: targetVC)
        }
    }
}

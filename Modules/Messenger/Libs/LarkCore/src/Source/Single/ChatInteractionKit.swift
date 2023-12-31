//
//  ChatInteractionKit.swift
//  LarkCore
//
//  Created by 李晨 on 2020/3/24.
//

import UIKit
import Foundation
import LarkInteraction
import LarkAlertController
import EENavigator
import LarkUIKit
import LarkModel
import RxSwift
import RxCocoa
import SnapKit
import LarkBizAvatar
import LarkRichTextCore
import LarkContainer

public protocol ChatInteractionKitDelegate: AnyObject {
    /// 是否可以响应手势
    func canHandleDropInteraction() -> Bool
    /// 响应的 Chat
    func handleDropChatModel() -> Chat
    /// 处理 Image 类型 item
    func handleImageTypeDropItem(image: UIImage)
    /// 处理 Text 类型 item
    func handleTextTypeDropItem(text: String)
    /// 处理 File 类型 item
    func handleFileTypeDropItem(name: String?, url: URL)
    /// targetViewController
    func interactionTargetController() -> UIViewController
}

/// Chat 拖拽工具
public final class ChatInteractionKit {
    let userResolver: UserResolver
    public typealias ChatID = String

    /// chat 支持的item类型
    public static var supportTypes: [DropItemType] = [
        .classType(UIImage.self),
        .classType(NSString.self),
        .UTIURLType(UTI.Data)
    ]

    /// chat message detail 支持的item类型
    public static var messageDetailSupportTypes: [DropItemType] = [
        .classType(UIImage.self),
        .classType(NSString.self)
    ]

    static private let chatDropItemsSubject = PublishSubject<(ChatID, [DropItemValue])>()
    public static var chatDropItemsDriver: Driver<(ChatID, [DropItemValue])> {
        return chatDropItemsSubject.asDriver(onErrorJustReturn: ("", []))
    }

    /// 设置临时的 DropItems
    public static func setDropItems(chatID: ChatID, items: [DropItemValue]) {
        tmpDropItems = (chatID, items)
        chatDropItemsSubject.onNext((chatID, items))
    }

    /// 获取 DropItems，会清除缓存
    public static func getDropItems(chatID: ChatID) -> [DropItemValue] {
        guard let tmp = tmpDropItems else {
            return []
        }
        tmpDropItems = nil
        if tmp.0 != chatID { return [] }
        return tmp.1
    }

    public static func cleanDropItems() {
        tmpDropItems = nil
    }

    static var tmpDropItems: (ChatID, [DropItemValue])?

    public weak var delegate: ChatInteractionKitDelegate?

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    /// 创建 Drop 拖拽手势
    public func createDropInteraction(itemTypes: [DropItemType] = ChatInteractionKit.supportTypes) -> DropInteraction {
        let dropInteraction = DropInteraction.create(canHandle: { [weak self] (_, _) -> Bool in
            return self?.delegate?.canHandleDropInteraction() ?? false
        },
        itemTypes: itemTypes,
        itemOptions: [.notSupportCurrentApplication]) { [weak self] (values) in
            guard let `self` = self else { return }
            self.handleDropValues(values)
        }
        return dropInteraction
    }

    public func handleDropValues(_ values: [DropItemValue]) {
        DispatchQueue.main.async {
            self.asyncHandleDropValues(values)
        }
    }

    private func asyncHandleDropValues(_ values: [DropItemValue]) {
        guard self.delegate?.canHandleDropInteraction() ?? false else { return }
        guard let targetVC = self.delegate?.interactionTargetController() else {
            return
        }

        guard let chat = self.delegate?.handleDropChatModel() else { return }
        if self.needConfirmValues(values) {
            let alertController = LarkAlertController()
            if values.count == 1 {
                alertController.setTitle(text: BundleI18n.LarkCore.Lark_Legacy_ChatViewSendTo, alignment: .left)
                alertController.setContent(
                    view: self.createConfirmContentView(
                        chat: chat,
                        values: values)
                    )
            } else {
                let content = BundleI18n.LarkCore.Lark_Chat_iPadDragSeveralProjects("\(values.count)", chat.displayName)
                alertController.setContent(text: content)
            }

            alertController.addCancelButton()
            alertController.addPrimaryButton(text: BundleI18n.LarkCore.Lark_Legacy_LarkConfirm, dismissCompletion: { [weak self] in
                self?.processDropValues(values)
            })
            userResolver.navigator.present(alertController, from: targetVC)
        } else {
            self.processDropValues(values)
        }
    }

    private func needConfirmValues(_ values: [DropItemValue]) -> Bool {
        guard values.count == 1 else { return true }
        if case let .classType(item) = values.first?.itemData,
            item is NSString {
            return false
        }
        return true
    }

    private func processDropValues(_ values: [DropItemValue]) {
        for value in values {
            switch value.itemData {
            case .classType(let data):
                if let image = data as? UIImage {
                    self.delegate?.handleImageTypeDropItem(image: image)
                } else if let text = data as? String {
                    self.delegate?.handleTextTypeDropItem(text: text)
                } else {
                    assertionFailure()
                }
            case let .UTIURLType(_, url):
                self.delegate?.handleFileTypeDropItem(name: value.suggestedName, url: url)
            default:
                assertionFailure()
            }
        }
    }

    private func createConfirmContentView(chat: Chat, values: [DropItemValue]) -> UIView {
        let baseView = UIView()
        baseView.backgroundColor = UIColor.ud.N00

        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.alignment = .leading
        verticalStack.spacing = 0

        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.spacing = 10
        verticalStack.addArrangedSubview(horizontalStack)

        let avatarView: BizAvatar = BizAvatar()
        avatarView.setAvatarByIdentifier(chat.id, avatarKey: chat.avatarKey, avatarViewParams: .init(sizeType: .size(32)))
        horizontalStack.addArrangedSubview(avatarView)
        avatarView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(32)
        }

        let nameLabel = UILabel()
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.textAlignment = .center
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.text = chat.displayName
        horizontalStack.addArrangedSubview(nameLabel)

        if let value = values.first {
            verticalStack.setCustomSpacing(10, after: horizontalStack)
            let footer = footerViewBy(value: value)
            verticalStack.addArrangedSubview(footer)
            footer.snp.makeConstraints { (maker) in
                maker.width.equalToSuperview()
                maker.width.equalTo(240)
            }
        }

        return verticalStack
    }

    private func footerViewBy(value: DropItemValue) -> UIView {
        switch value.itemData {
        case let .classType(item):
            if let string = item as? NSString {
                return TextConfirmFooter(message: string as String)
            } else if let image = item as? UIImage {
                return ImageConfirmFooter(userResolver: self.userResolver, image: image)
            } else {
                assertionFailure()
            }
        case let .UTIURLType(_, url):
            return FileConfirmFooter(fileName: value.suggestedName, url: url)
        default:
            assertionFailure()
        }
        return UIView()
    }
}

final class TextConfirmFooter: BaseConfirmFooter {
    var message: String

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: String) {
        self.message = message
        super.init()

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 4
        label.lineBreakMode = .byTruncatingTail
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }
        label.text = message
    }
}

final class FileConfirmFooter: BaseConfirmFooter {
    private var fileName: String
    private var url: URL

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(fileName: String, url: URL) {
        self.fileName = fileName
        self.url = url
        super.init()
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.image = LarkRichTextCoreUtils.fileIcon(with: fileName)

        self.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.width.height.equalTo(64)
            make.left.top.equalTo(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        let nameLabel = UILabel()
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.text = fileName
        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imgView.snp.top).offset(4)
            make.left.equalTo(imgView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
        }

        let sizeLabel = UILabel()
        sizeLabel.numberOfLines = 1
        sizeLabel.font = UIFont.systemFont(ofSize: 12)
        sizeLabel.textColor = UIColor.ud.N500
        self.addSubview(sizeLabel)
        sizeLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(imgView.snp.bottom).offset(-4)
            make.left.equalTo(imgView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        if let resources = try? url.resourceValues(forKeys: [.fileSizeKey]),
            let fileSize = resources.fileSize {
            let size = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .binary)
            let sizeString = "(\(size))"
            sizeLabel.text = sizeString
        }
    }
}

class BaseConfirmFooter: UIView {

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.N100
        self.layer.cornerRadius = 5
    }
}

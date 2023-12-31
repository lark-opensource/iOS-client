//
//  ChatTabSearchFileTableViewCell.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/4/22.
//

import UIKit
import RustPB
import Foundation
import LarkUIKit
import LarkCore
import UniverseDesignIcon
import LKCommonsTracker
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkKeyboardKit
import LarkSearchCore
import LarkListItem
import AvatarComponent
import LarkContainer

final class ChatTabSearchFileTableViewCell: UITableViewCell {
    static let reuseId = "ChatTabSearchFileTableViewCell"

    private let containerGuide = UILayoutGuide()
    private let stackView = UIStackView()
    private let personInfoView = ListItem()
    private let goToMessageButton = UIButton()
    // 局域网传输icon
    private lazy var lanTransIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        imageView.image = Resources.lan_Trans_Icon
        return imageView
    }()

    private(set) var viewModel: ChatTabSearchFileCellViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectedBackgroundView = SearchCellSelectedView()
        self.backgroundColor = UIColor.ud.bgBody
        contentView.addLayoutGuide(containerGuide)
        containerGuide.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(67).priority(.high)
        }

        stackView.spacing = 20
        stackView.axis = .horizontal
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(-16)
        }

        personInfoView.rightMarginConstraint.update(offset: 0)
        var config = AvatarComponentUIConfig()
        config.style = .square
        personInfoView.avatarView.setAvatarUIConfig(config)
        personInfoView.checkBox.isHidden = true
        personInfoView.additionalIcon.isHidden = true
        personInfoView.bottomSeperator.isHidden = true
        personInfoView.infoLabel.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
        }
        stackView.addArrangedSubview(personInfoView)

        goToMessageButton.setImage(UDIcon.getIconByKey(.viewinchatOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1).withRenderingMode(.alwaysTemplate), for: .normal)
        goToMessageButton.tintColor = UIColor.ud.iconN2
        goToMessageButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 900), for: .horizontal)
        goToMessageButton.hitTestEdgeInsets = .init(edges: -10)
        stackView.addArrangedSubview(goToMessageButton)
        goToMessageButton.addTarget(self, action: #selector(gotoMessageButtonDidClick), for: .touchUpInside)
        contentView.addSubview(lanTransIcon)
        lanTransIcon.snp.makeConstraints { (make) in
            make.right.equalTo(personInfoView.avatarView.snp.right).offset(4)
            make.bottom.equalTo(personInfoView.avatarView.snp.bottom).offset(6)
            make.size.equalTo(24)
        }
        lanTransIcon.isHidden = true
    }

    override func layoutSubviews() {
        let frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6))
        self.selectedBackgroundView?.frame = frame
        self.selectedBackgroundView?.layer.cornerRadius = 8
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateCellStyle(animated: animated)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateCellStyle(animated: animated)
    }

    private func clearStatus() {
        personInfoView.avatarView.image = nil
        personInfoView.nameLabel.text = ""
        personInfoView.nameTag.clean()
        personInfoView.nameTag.isHidden = true
        personInfoView.setDescription(NSAttributedString(string: ""), descriptionType: ListItem.DescriptionType.onDefault)
        personInfoView.infoLabel.text = ""
        personInfoView.additionalIcon.clean()
        personInfoView.additionalIcon.isHidden = true
    }

    func update(viewModel: ChatTabSearchFileCellViewModel) {
        clearStatus()

        self.viewModel = viewModel
        if SearchFeatureGatingKey.enableSearchSubFile.isUserEnabled(userResolver: viewModel.userResolver) {
            updateFileItem()
        } else {
            updateMessageItem()
        }
    }

    func updateMessageItem() {
        guard let searchResult = self.viewModel?.data, case let .message(messageMeta) = searchResult.meta else { return }

        // nameLabel
        personInfoView.nameLabel.attributedText = searchResult.title
        // infoLabel
        let summary = NSMutableAttributedString(attributedString: searchResult.summary)
        summary.append(NSAttributedString(string: " "))
        summary.append(NSAttributedString(string: Date.lf.getNiceDateString(TimeInterval(messageMeta.updateTime))))
        personInfoView.infoLabel.attributedText = summary

        if messageMeta.contentType == .folder {
            personInfoView.avatarView.image = UDIcon.getIconByKey(.fileFolderColorful, size: CGSize(width: 40, height: 40))
            lanTransIcon.isHidden = !messageMeta.hasFileMeta || messageMeta.fileMeta.extra.source != .lanTrans
        } else if messageMeta.hasFileMeta, !messageMeta.fileMeta.name.isEmpty {
            // 头像
            let image = LarkCoreUtils.fileIconColorful(with: messageMeta.fileMeta.name, size: CGSize(width: 40, height: 40))
            personInfoView.avatarView.image = image
            // 局域网文件显示特定icon
            lanTransIcon.isHidden = messageMeta.fileMeta.extra.source != .lanTrans
        } else {
            assertionFailure("unknown meta data")
        }
    }

    func updateFileItem() {
        guard let searchResult = self.viewModel?.data, case let .messageFile(messageFileMeta) = searchResult.meta else { return }

        // nameLabel
        personInfoView.nameLabel.attributedText = searchResult.title
        // infoLabel
        let summary = NSMutableAttributedString(attributedString: searchResult.summary)
        summary.append(NSAttributedString(string: " "))
        summary.append(NSAttributedString(string: Date.lf.getNiceDateString(TimeInterval(messageFileMeta.createTime))))
        personInfoView.infoLabel.attributedText = summary

        if messageFileMeta.fileType == .folder {
            personInfoView.avatarView.image = UDIcon.getIconByKey(.fileFolderColorful, size: CGSize(width: 40, height: 40))
            lanTransIcon.isHidden = !messageFileMeta.hasFileMeta || messageFileMeta.fileMeta.source != .lanTrans
        } else if messageFileMeta.hasFileMeta, !messageFileMeta.fileMeta.name.isEmpty {
            // 头像
            let image = LarkCoreUtils.fileIconColorful(with: messageFileMeta.fileMeta.name, size: CGSize(width: 40, height: 40))
            personInfoView.avatarView.image = image
            // 局域网文件显示特定icon
            lanTransIcon.isHidden = messageFileMeta.fileMeta.source != .lanTrans
        } else {
            assertionFailure("unknown meta data")
        }
    }

    @objc
    private func gotoMessageButtonDidClick() {
        viewModel?.gotoChat()
    }

    func updateCellStyle(animated: Bool) {
        let action: () -> Void = {
            switch (self.isHighlighted, self.isSelected) {
            case (_, true):
                self.selectedBackgroundView?.backgroundColor = UIColor.ud.fillActive
            case (true, false):
                self.selectedBackgroundView?.backgroundColor = UIColor.ud.fillFocus
            default:
                self.selectedBackgroundView?.backgroundColor = UIColor.ud.bgBody
            }
        }
        if animated {
            UIView.animate(withDuration: 0.25, animations: action)
        } else {
            action()
        }
    }
}

final class ChatTabSearchFileCellViewModel {
    let data: SearchResultType
    let chatId: String
    var indexPath: IndexPath?
    private let router: ChatTabSearchFileRouter
    weak var fromVC: UIViewController?
    let userResolver: UserResolver
    init(userResolver: UserResolver,
         chatId: String,
         data: SearchResultType,
         router: ChatTabSearchFileRouter) {
        self.userResolver = userResolver
        self.data = data
        self.router = router
        self.chatId = chatId
    }

    func goNextPage() {
        guard let fromVC = self.fromVC else {
            assertionFailure("fromVC not set")
            return
        }
        switch data.meta {
        case .message(let messageMeta):
            if messageMeta.contentType == .folder {
                router.pushFolderManagementViewController(messageId: messageMeta.id, firstLevelInformation: nil, fromVC: fromVC)
            } else if messageMeta.hasFileMeta, !messageMeta.fileMeta.name.isEmpty {
                router.pushFileBrowserViewController(chatId: chatId, messageId: messageMeta.id, fileInfo: nil, isInnerFile: false, fromVC: fromVC)
            } else {
                router.pushToChatOrReplyInThreadController(chatId: chatId,
                                                           toMessagePosition: messageMeta.position,
                                                           threadId: messageMeta.threadID,
                                                           threadPosition: messageMeta.threadPosition,
                                                           fromVC: fromVC,
                                                           isFolder: false)
            }
        case .messageFile(let messageFileMeta):
            if messageFileMeta.fileType == .folder {
                router.pushFolderManagementViewController(
                    messageId: messageFileMeta.messageID,
                    firstLevelInformation: FolderFirstLevelInformation(
                        key: messageFileMeta.fileMeta.key,
                        authToken: nil,
                        authFileKey: messageFileMeta.fileMeta.key,
                        name: messageFileMeta.fileMeta.name,
                        size: messageFileMeta.fileMeta.size
                    ),
                    fromVC: fromVC
                )
            } else if messageFileMeta.hasFileMeta, !messageFileMeta.fileMeta.name.isEmpty {
                var fileInfo: FileInfo?
                if messageFileMeta.isInnerFile {
                    fileInfo = FileInfo(
                        key: messageFileMeta.fileMeta.key,
                        authToken: nil,
                        authFileKey: "",
                        size: messageFileMeta.fileMeta.size,
                        name: messageFileMeta.fileMeta.name,
                        filePreviewStage: .normal
                     )
                }
                router.pushFileBrowserViewController(chatId: chatId,
                                                     messageId: messageFileMeta.messageID,
                                                     fileInfo: fileInfo,
                                                     isInnerFile: messageFileMeta.isInnerFile,
                                                     fromVC: fromVC)
            } else {
                router.pushToChatOrReplyInThreadController(chatId: chatId,
                                                           toMessagePosition: messageFileMeta.messagePosition,
                                                           threadId: messageFileMeta.threadID,
                                                           threadPosition: messageFileMeta.threadPosition,
                                                           fromVC: fromVC,
                                                           isFolder: false)
            }
        default: break
        }
    }

    func gotoChat() {
        guard let fromVC = self.fromVC else {
            assertionFailure("fromVC not set")
            return
        }
        switch data.meta {
        case .message(let messageMeta):
            router.pushToChatOrReplyInThreadController(chatId: chatId,
                                                       toMessagePosition: messageMeta.position,
                                                       threadId: messageMeta.threadID,
                                                       threadPosition: messageMeta.threadPosition,
                                                       fromVC: fromVC,
                                                       isFolder: messageMeta.contentType == .folder)
        case .messageFile(let fileMeta):
            router.pushToChatOrReplyInThreadController(chatId: chatId,
                                                       toMessagePosition: fileMeta.messagePosition,
                                                       threadId: fileMeta.threadID,
                                                       threadPosition: fileMeta.threadPosition,
                                                       fromVC: fromVC,
                                                       isFolder: fileMeta.fileType == .folder)
        default: break
        }
    }
}

private struct FileInfo: FileContentBasicInfo {
    let key: String
    let authToken: String?
    let authFileKey: String
    let size: Int64
    let name: String
    let cacheFilePath: String = ""
    let filePreviewStage: Basic_V1_FilePreviewStage
}

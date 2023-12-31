//
//  ForwardCopyFromFolderMessageAlert.swift
//  LarkForward
//
//  Created by 赵家琛 on 2021/4/21.
//

import UIKit
import Foundation
import LarkModel
import UniverseDesignToast
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import EENavigator
import LarkCore
import LarkContainer

struct ForwardCopyFromFolderMessageAlertContent: ForwardAlertContent {
    let folderMessageId: String
    let key: String
    let name: String
    let size: Int64
    let copyType: ForwardCopyFromFolderMessageBody.CopyType
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class ForwardCopyFromFolderMessageAlertProvider: ForwardAlertProvider {

    @ScopedInjectedLazy private var forwardService: ForwardService?

    override var isSupportMention: Bool {
        return true
    }

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ForwardCopyFromFolderMessageAlertContent != nil {
            return true
        }
        return false
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        return [ForwardUserEnabledEntityConfig(),
                ForwardGroupChatEnabledEntityConfig(),
                ForwardBotEnabledEntityConfig(),
                ForwardThreadEnabledEntityConfig(),
                ForwardMyAiEnabledEntityConfig()]
    }

    override func getForwardItemsIncludeConfigs() -> IncludeConfigs? {
        return [ForwardUserEntityConfig(),
                ForwardGroupChatEntityConfig(),
                ForwardBotEntityConfig(),
                ForwardThreadEntityConfig(),
                ForwardMyAiEntityConfig()]
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let content = content as? ForwardCopyFromFolderMessageAlertContent else {
            return nil
        }

        let container = BaseForwardConfirmFooter()

        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        container.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.width.equalTo(64)
            make.height.equalTo(64)
            make.left.top.bottom.equalToSuperview().inset(8)
        }
        switch content.copyType {
        case .file, .zip:
            imgView.image = LarkCoreUtils.fileLadderIcon(with: content.name)
        case .folder:
            imgView.image = Resources.imageForwardFolder
        }

        let nameLabel = UILabel()
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        container.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imgView.snp.top).offset(4)
            make.left.equalTo(imgView.snp.right).offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        let sizeLabel = UILabel()
        sizeLabel.numberOfLines = 1
        sizeLabel.font = UIFont.systemFont(ofSize: 12)
        sizeLabel.textColor = UIColor.ud.N500
        container.addSubview(sizeLabel)
        sizeLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(imgView.snp.bottom).offset(-4)
            make.left.equalTo(imgView.snp.right).offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        nameLabel.text = content.name
        let size = ByteCountFormatter.string(fromByteCount: content.size, countStyle: .binary)
        let sizeString = "(\(size))"
        sizeLabel.text = sizeString

        return container
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ForwardCopyFromFolderMessageAlertContent,
              let forwardService = self.forwardService,
              let window = from.view.window else { return .just([]) }
        let hud = UDToast.showLoading(on: window)

        let userIDs = self.itemsToIds(items).userIds
        let chatIDs = items.filter { $0.type == .chat }.map { $0.id }
        let threadIDAndChatIDs = items.filter { $0.type.isThread }.map { ($0.id, $0.channelID ?? "") }
        return forwardService
            .forwardCopyFromFolderMessage(
                folderMessageId: messageContent.folderMessageId,
                key: messageContent.key,
                chatIds: chatIDs,
                userIds: userIDs,
                threadIDAndChatIDs: threadIDAndChatIDs,
                extraText: input ?? ""
            )
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak window] (_, filePermCheck) in
                hud.remove()
                if let window = window,
                    let filePermCheck = filePermCheck {
                    UDToast.showTips(with: filePermCheck.toast, on: window)
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                shareErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            }).map({ (chatIds, _) in return chatIds })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ForwardCopyFromFolderMessageAlertContent,
              let forwardService = self.forwardService,
              let window = from.view.window else { return .just([]) }
        let hud = UDToast.showLoading(on: window)

        let userIDs = self.itemsToIds(items).userIds
        let chatIDs = items.filter { $0.type == .chat }.map { $0.id }
        let threadIDAndChatIDs = items.filter { $0.type.isThread }.map { ($0.id, $0.channelID ?? "") }
        return forwardService
            .forwardCopyFromFolderMessage(
                folderMessageId: messageContent.folderMessageId,
                key: messageContent.key,
                chatIds: chatIDs,
                userIds: userIDs,
                threadIDAndChatIDs: threadIDAndChatIDs,
                attributeExtraText: attributeInput ?? NSAttributedString(string: "")
            )
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak window] (_, filePermCheck) in
                hud.remove()
                if let window = window,
                    let filePermCheck = filePermCheck {
                    UDToast.showTips(with: filePermCheck.toast, on: window)
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                shareErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            }).map({ (chatIds, _) in return chatIds })
    }
}

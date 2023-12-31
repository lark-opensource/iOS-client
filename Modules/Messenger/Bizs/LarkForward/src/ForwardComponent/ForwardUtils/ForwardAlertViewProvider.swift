//
//  ForwardAlertViewProvider.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/17.
//

import UIKit
import Foundation
import SnapKit
import LarkModel
import LarkCore
import LarkUIKit
import RxSwift
import EditTextView
import LarkMessengerInterface
import LarkBizAvatar
import UniverseDesignDialog
import LarkFeatureGating
import LKCommonsLogging
import EENavigator
import UniverseDesignToast
import LarkSearchCore

// nolint: long_function,magic_number -- 代码可读性治理无QA，不做复杂修改
// TODO: 转发单测建设时优化该逻辑
// TODO: Do not use magic number.
let alertCollectViewWidth: CGFloat = UDDialog.Layout.dialogWidth - 40
let alertLineSpacing: CGFloat = 10

final class ForwardAlertViewProvider: NSObject {
    static let logger = Logger.log(ForwardAlertViewProvider.self)
    static let avatarSize: CGSize = CGSize(width: 40, height: 40)
    private let forwardChats: [ForwardItem]
    private let forwardConfig: ForwardConfig
    private var itemWidth: CGFloat = ForwardAlertViewProvider.avatarSize.width
    private let itemHeight: CGFloat = ForwardAlertViewProvider.avatarSize.height
    private let isShowInputView: Bool
    private let disposeBag: DisposeBag = DisposeBag()

    //根据forwardChats数决定ui样式内容，参见具体需求设计
    init(forwardChats: [ForwardItem], forwardConfig: ForwardConfig) {
        self.forwardChats = forwardChats
        self.forwardConfig = forwardConfig
        self.isShowInputView = forwardConfig.addtionNoteConfig.enableAdditionNote
        if self.forwardChats.count == 1 {
            itemWidth = alertCollectViewWidth
        }
    }

    private func presentPreviewViewController(item: ForwardItem, from: UIViewController) {
        let chatID = item.type == .chat ? item.id : (item.chatId ?? "")
        //未开启过会话的单聊，chatID为空时，需传入uid
        let userID = chatID.isEmpty ? item.id : ""
        if !TargetPreviewUtils.canTargetPreview(forwardItem: item) {
            if let window = from.view.window {
                UDToast.showTips(with: BundleI18n.LarkForward.Lark_IM_UnableToPreviewContent_Toast, on: window)
            }
        } else if TargetPreviewUtils.isThreadGroup(forwardItem: item) {
            //话题群
            let threadChatPreviewBody = ThreadPreviewByIDBody(chatID: chatID)
            self.forwardConfig.alertConfig.userResolver.navigator.present(body: threadChatPreviewBody, wrap: LkNavigationController.self, from: from)
        } else {
            //会话
            let chatPreviewBody = ForwardChatMessagePreviewBody(chatId: chatID, userId: userID, title: item.name)
            self.forwardConfig.alertConfig.userResolver.navigator.present(body: chatPreviewBody, wrap: LkNavigationController.self, from: from)
        }
        SearchTrackUtil.trackPickerSelectClick(scene: "forward", clickType: .chatDetail(target: "none"))
    }
    // nolint: duplicated_code
    func createConfirmContentView() -> (UIView, LarkEditTextView?) {
        let baseView = UIView()
        let layout = UICollectionViewFlowLayout()
        let avartCount = Display.typeIsLike == .iPhone5 ? 4 : 5

        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumInteritemSpacing = (alertCollectViewWidth - CGFloat(avartCount) * itemWidth) / CGFloat(avartCount) + 1
        layout.minimumLineSpacing = alertLineSpacing

        let line: CGFloat = forwardChats.count <= avartCount ? 1 : 2
        let collectHeight = line * itemHeight + alertLineSpacing * (line - 1)
        let chatCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        chatCollectionView.backgroundColor = UIColor.clear
        var arrowIconShow = false
        if forwardConfig.targetConfig.enableTargetPreview {
            //目标点击手势
            chatCollectionView.rx.modelSelected(ForwardItem.self)
                .subscribe(onNext: { [weak self] item in
                    guard let self = self, let from = self.forwardConfig.alertConfig.targetVc else { return }
                    self.presentPreviewViewController(item: item, from: from)
                })
            // 单选时展示目标预览入口箭头icon
            arrowIconShow = true
        }
        if forwardChats.count > 1 {
            let cellIndentifier = String(describing: ForwardAlertAvatarCollectionViewCell.self)
            chatCollectionView.register(ForwardAlertAvatarCollectionViewCell.self, forCellWithReuseIdentifier: cellIndentifier)
            Observable.just(forwardChats).bind(to: chatCollectionView.rx.items) { (collectionView, row, _) in
                let indexPath = IndexPath(row: row, section: 0)
                let chat = self.forwardChats[row]
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIndentifier, for: indexPath)
                if let cell = cell as? ForwardAlertAvatarCollectionViewCell {
                    let avatarId = chat.avatarId ?? chat.id
                    cell.setContent(avatarId, avatarKey: chat.avatarKey, image: chat.type == .replyThreadMessage ? Resources.messageThreadIcon : nil) {
                        Self.logger.error("Forward.Cell: sure alert load avatar {id: \(avatarId), key: \(chat.avatarKey)}, error: \($0)")
                    }
                }
                return cell
            }.disposed(by: disposeBag)
        } else {
            let cellIndentifier = String(describing: AvatarWithRightNameCollectionViewCell.self)
            chatCollectionView.register(AvatarWithRightNameCollectionViewCell.self, forCellWithReuseIdentifier: cellIndentifier)
            Observable.just(forwardChats).bind(to: chatCollectionView.rx.items) { (collectionView, row, _) in
                let indexPath = IndexPath(row: row, section: 0)
                let chat = self.forwardChats[row]
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIndentifier, for: indexPath)
                if let cell = cell as? AvatarWithRightNameCollectionViewCell {
                    let avatarId = chat.avatarId ?? chat.id
                    cell.showArrowIcon(arrowIconShow)
                    cell.setContent(chat.avatarKey, id: avatarId, userName: chat.name, image: chat.type == .replyThreadMessage ? Resources.messageThreadIcon : nil) {
                        Self.logger.error("Forward.Cell: sure alert load avatar {id: \(avatarId), key: \(chat.avatarKey)}, error: \($0)")
                    }
                }
                return cell
            }.disposed(by: disposeBag)
        }

        baseView.addSubview(chatCollectionView)

        chatCollectionView.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview()
            make.height.equalTo(collectHeight)
            make.right.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        var lastView: UIView = chatCollectionView
        if let footer = forwardConfig.alertConfig.getContentView() {
            baseView.addSubview(footer)
            footer.snp.makeConstraints { (make) in
                make.left.equalTo(chatCollectionView)
                make.width.equalTo(chatCollectionView)
                make.top.equalTo(chatCollectionView.snp.bottom).offset(12)
                if !isShowInputView {
                    make.bottom.equalToSuperview()
                } else {
                    make.bottom.lessThanOrEqualToSuperview()
                }
            }
            if !isShowInputView {
                return (baseView, nil)
            }
            lastView = footer
        }

        if isShowInputView {
            let inputView = LarkEditTextView()
            let font = UIFont.systemFont(ofSize: 14)
            let defaultTypingAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.ud.textTitle,
                .paragraphStyle: {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineSpacing = 2
                    return paragraphStyle
                }()
            ]
            inputView.defaultTypingAttributes = defaultTypingAttributes
            inputView.font = font
            inputView.placeholder = BundleI18n.LarkForward.Lark_Forward_NoteMention
            inputView.placeholderTextColor = UIColor.ud.textPlaceholder
            inputView.textContainerInset = UIEdgeInsets(top: 11, left: 10, bottom: 11, right: 10)
            inputView.backgroundColor = .clear
            inputView.layer.borderWidth = 1
            inputView.layer.ud.setBorderColor(UIColor.ud.N300)
            inputView.layer.cornerRadius = 6
            inputView.maxHeight = 55

            baseView.addSubview(inputView)
            inputView.snp.makeConstraints { (make) in
                make.top.equalTo(lastView.snp.bottom).offset(10)
                make.left.right.bottom.equalToSuperview()
                make.height.greaterThanOrEqualTo(36)
                make.height.lessThanOrEqualTo(55)
            }
            return (baseView, inputView)
        }
        return (baseView, nil)
    }
    // enable-lint: duplicated_code
}

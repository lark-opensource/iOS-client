//
//  VoIPChatContentViewModel.swift
//  Action
//
//  Created by Prontera on 2019/6/21.
//

import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import RxCocoa
import EENavigator
import RichLabel

protocol VoIPChatContentViewModelContext: UserViewModelContext {}

class VoIPChatContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: VoIPChatContentViewModelContext>: MessageSubViewModel<M, D, C> {
    override var identifier: String {
        return "VoIPChatContent"
    }

    var content: SystemContent {
        return (self.message.content as? SystemContent)!
    }

    override init(metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>) {
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    private var callID: String? {
        guard let info = e2eeinfo else {
            return nil
        }
        return context.isMe(info.e2EeFromID) ? info.e2EeToID : info.e2EeFromID
    }

    private let disposeBag = DisposeBag()

    private var e2eeinfo: SystemContent.E2EECallInfo? {
        return content.e2eeCallInfo
    }

    var preferMaxLayoutWidth: CGFloat {
        return metaModelDependency.getContentPreferMaxWidth(self.message)
    }

    private(set) var callText = NSMutableAttributedString()
    private(set) var attributedString = NSMutableAttributedString()
    let labelFont = UIFont.systemFont(ofSize: 16)

    private func getAttributedString(message: Message) {
        guard let info = e2eeinfo else {
            self.callText = NSMutableAttributedString()
            return
        }
        /// 当前方法在子线程执行，需要使用LKAsyncAttachment
        let attachment = LKAsyncAttachment(
            viewProvider: { [weak self] in
                guard let `self` = self else { return UIView() }
                return self.callIcon
            },
            size: CGSize(width: 20, height: 20)
        )
        attachment.fontDescent = labelFont.descender
        attachment.fontAscent = labelFont.ascender
        let resultAttributedString = NSMutableAttributedString(
            string: LKLabelAttachmentPlaceHolderStr,
            attributes: [LKAttachmentAttributeName: attachment]
        )
        let callText = String.lf.decode(
            template: content.template,
            contents: content.values
        )
        resultAttributedString.append(NSAttributedString(
            string: " " + callText,
            attributes: LKLabel.lu.basicAttribute(
                foregroundColor: UIColor.ud.textPlaceholder
            )
        ))
        if content.systemType != .userCallE2EeVoiceDuration {
            let title: String = " " + (context.isMe(info.e2EeFromID) ? I18n.Lark_View_CallAgain : I18n.Lark_View_CallBack)

            let titleWidth = title.lu.width(font: labelFont, height: 17)
            /// 当前方法在子线程执行，需要使用LKAsyncAttachment
            let attachment = LKAsyncAttachment(
                viewProvider: { [weak self] in
                    guard let `self` = self else { return UIView() }
                    self.restartButton.setTitle(title, for: .normal)
                    self.restartButton.frame = CGRect(x: 0, y: 0, width: titleWidth, height: 17)
                    return self.restartButton
                }, size: CGSize(width: titleWidth, height: 17)
            )
            attachment.fontDescent = labelFont.descender
            attachment.fontAscent = labelFont.ascender
            resultAttributedString.append(NSAttributedString(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKAttachmentAttributeName: attachment]
            ))
        }
        attributedString = resultAttributedString
    }

    private lazy var callIcon: UIImageView = {
        let callIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        callIcon.image = BundleResources.Chat.icon_encryptied_call
        return callIcon
    }()

    override func initialize() {
        self.getAttributedString(message: self.message)
    }

    func resetButtonTapped() {
        guard let targetVC = context.targetVC else {
            return
        }
        if let callID = callID, let url = URL(string: "//client/byteview/callvoip") {
            context.userResolver.navigator.present(url, context: ["userID": callID], from: targetVC, prepare: { $0.modalPresentationStyle = .fullScreen })
        }
    }

    private lazy var restartButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentMode = .left
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = labelFont
        button.contentEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
        button.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.resetButtonTapped()
            }).disposed(by: disposeBag)
        return button
    }()

    /// 拨号/回拨消息不会变化
    override func shouldUpdate(_ new: Message) -> Bool {
        return false
    }
}

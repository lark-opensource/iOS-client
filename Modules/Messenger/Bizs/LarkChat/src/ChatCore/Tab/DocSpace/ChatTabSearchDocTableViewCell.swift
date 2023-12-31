//
//  ChatTabSearchDocTableViewCell.swift
//  LarkChat
//
//  Created by Zigeng on 2022/5/6.
//

import Foundation
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import RustPB
import CryptoSwift
import LarkSearchCore
import LarkSearchFilter
import UIKit
import LarkModel
import LarkUIKit
import LarkTag
import LarkAvatar
import LarkCore
import LarkExtensions
import LarkBizAvatar
import UniverseDesignActionPanel
import LarkContainer
import Homeric
import LKCommonsTracker
import LarkBizTag

final class ChatTabSearchDocTableViewCell: UITableViewCell {
    static let reuseId = "ChatTabSearchDocTableViewCell"
    private(set) var viewModel: ChatTabSearchDocCellViewModel?
    let avatarSize: CGFloat = 40
    let avatarView: UIImageView
    let titleLabel: UILabel
    let subtitleLabel: UILabel
    let textWarrperView: UIView

    private lazy var builder = TagViewBuilder()
    private lazy var tagView = builder.build()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        avatarView = UIImageView()
        avatarView.ud.setMaskView()
        titleLabel = UILabel()
        subtitleLabel = UILabel()
        textWarrperView = UIView()
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let layoutGuide = UILayoutGuide()
        contentView.addLayoutGuide(layoutGuide)
        layoutGuide.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.height.equalTo(67).priority(.high)
        }

        selectedBackgroundView = SearchCellSelectedView()
        self.backgroundColor = UIColor.ud.bgBody

        self.contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints({ make in
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        })

        self.contentView.addSubview(textWarrperView)
        textWarrperView.snp.makeConstraints { (make) in
            make.left.equalTo(self.avatarView.snp.right).offset(12)
            make.centerY.equalTo(avatarView)
            make.right.equalToSuperview().offset(-16)
        }

        textWarrperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        })
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)
        textWarrperView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints({ make in
            make.left.equalToSuperview()
            make.top.equalTo(self.titleLabel.snp.bottom).offset(7)
            make.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        })
        subtitleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)

        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle

        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = UIColor.ud.textPlaceholder

        let moreButton: UIButton = UIButton(type: .custom)
        moreButton.setImage(Resources.tabCellMore.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = UIColor.ud.iconN2
        moreButton.addTarget(self, action: #selector(moreActionTapped(btn:)), for: .touchUpInside)
        self.contentView.addSubview(moreButton)
        moreButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }

        textWarrperView.snp.remakeConstraints({ (make) in
            make.left.equalTo(self.avatarView.snp.right).offset(12)
            make.centerY.equalTo(avatarView)
            make.right.lessThanOrEqualTo(moreButton.snp.left).offset(-31)
        })

        self.contentView.addSubview(tagView)
        tagView.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.titleLabel)
            make.height.equalTo(16)
            make.right.lessThanOrEqualTo(moreButton.snp.left).offset(-4)
            make.left.equalTo(self.titleLabel.snp.right).offset(6)
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateCellStyle(animated: animated)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateCellStyle(animated: animated)
    }

    override func layoutSubviews() {
        let frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6))
        self.selectedBackgroundView?.frame = frame
        self.selectedBackgroundView?.layer.cornerRadius = 8
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    @objc
    func goChat() {
        self.viewModel?.gotoChat()
    }

    @objc
    func moreActionTapped(btn sender: UIButton) {
        self.viewModel?.moreAction(sender)
    }

    func update(viewModel: ChatTabSearchDocCellViewModel) {
        self.viewModel = viewModel
        guard let meta = viewModel.docMeta() else { return }

        let title = viewModel.data.title
        if case .wiki = viewModel.data.meta {
            avatarView.image = LarkCoreUtils.wikiIconColorful(docType: meta.type, fileName: title.string)
        } else {
            avatarView.image = LarkCoreUtils.docIconColorful(docType: meta.type, fileName: title.string)
        }

        let summary = NSMutableAttributedString(attributedString: viewModel.data.summary)
        summary.append(NSAttributedString(string: " "))
        summary.append(NSAttributedString(string: Date.lf.getNiceDateString(TimeInterval(meta.updateTime))))

        titleLabel.attributedText = title
        subtitleLabel.attributedText = summary

        if meta.relationTag.tagDataItems.isEmpty == false {
            var dataItems: [TagDataItem] = []
            meta.relationTag.tagDataItems.forEach({ item in
                let dataItem = LarkBizTag.TagDataItem(text: item.textVal,
                                                      tagType: item.respTagType.transform())
                dataItems.append(dataItem)
            })
            builder.update(with: dataItems)
            tagView.isHidden = false
        } else {
            tagView.isHidden = true
        }
    }
}

final class ChatTabSearchDocCellViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    let data: SearchResultType
    let chatId: String
    var indexPath: IndexPath?
    private let router: ChatTabSearchDocRouter
    weak var fromVC: UIViewController?
    private let chatAPI: ChatAPI
    private let chatDocDependency: ChatDocDependency

    init(userResolver: UserResolver,
         chatId: String,
         data: SearchResultType,
         router: ChatTabSearchDocRouter) throws {
        self.userResolver = userResolver
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.chatDocDependency = try userResolver.resolve(assert: ChatDocDependency.self)
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
        case .doc(let docMeta):
            router.pushDocViewController(chatId: self.chatId, docUrl: docMeta.url, fromVC: fromVC)
        case .wiki(let wikiMeta):
            router.pushDocViewController(chatId: self.chatId, docUrl: wikiMeta.url, fromVC: fromVC)
        default: break
        }
    }

    func preloadDocs() {
        switch data.meta {
        case .doc(let docMeta):
            router.preloadDocs(docMeta.url)
        case .wiki(let wikiMeta):
            router.preloadDocs(wikiMeta.url)
        default: break
        }
    }

    func moreAction(_ btn: UIButton) {
        guard let fromVC = self.fromVC else {
            assertionFailure("fromVC or btnSourceView not set")
            return
        }
        let sourceView = btn
        let sourceRect: CGRect = CGRect(origin: .zero, size: sourceView.bounds.size)
        let popSource = UDActionSheetSource(sourceView: sourceView, sourceRect: sourceRect)
        let actionsheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false, popSource: popSource))
        actionsheet.addDefaultItem(text: BundleI18n.LarkChat.Lark_IM_AddTab_Button, action: { [weak self] in
            guard let self = self,
                  let fromVC = self.fromVC,
                  let chat = self.chatAPI.getLocalChat(by: self.chatId) else {
                      assertionFailure("Failed to unwrapped Weak!")
                      return
            }
            let id: String
            let ownerName: String
            let url: String
            let docType: RustPB.Basic_V1_Doc.TypeEnum
            let ownerID: String
            switch self.data.meta {
            case .doc(let meta):
                id = meta.id
                ownerName = meta.ownerName
                ownerID = meta.ownerID
                docType = meta.type
                url = meta.url
            case .wiki(let meta):
                id = meta.id
                ownerName = meta.ownerName
                ownerID = meta.ownerID
                docType = .wiki
                url = meta.url
            default: return
            }
            let setDocNameModel = ChatAddTabSetDocModel(chatId: self.chatId,
                                                        chat: chat,
                                                        id: id,
                                                        url: url,
                                                        docType: docType,
                                                        title: self.data.title.string,
                                                        titleHitTerms: [],
                                                        ownerID: ownerID,
                                                        ownerName: ownerName)
            guard let setLabelNameControllerVC = try? ChatTabSetDocNameController(
                userResolver: self.userResolver,
                setDocNameModel: setDocNameModel,
                addCompletion: { [weak self] tabContent in
                    guard let self = self, let fromVC = self.fromVC else { return }
                    fromVC.presentedViewController?.dismiss(animated: true)
                    let nav = fromVC.navigationController
                    self.navigator.push(
                        body: ChatControllerByChatBody(chat: chat),
                        from: fromVC,
                        animated: false,
                        completion: { [weak self]  _, _ in
                            guard let nav = nav, let router = self?.router else { return }
                            router.jumpToTab(tabContent, targetVC: nav)
                        }
                    )
                }
            ) else { return }
            self.navigator.present(
                setLabelNameControllerVC,
                wrap: LkNavigationController.self,
                from: fromVC,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
            )
            if !url.isEmpty,
               let url = URL(string: url) {
                let token = self.chatDocDependency.isSupportURLType(url: url).2
                Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_LIST_CLICK,
                                      params: ["click": "tab_add",
                                               "target": "im_chat_doc_page_add_view",
                                               "file_id": token],
                                      md5AllowList: ["file_id"]))

            }
        })
        actionsheet.addDefaultItem(text: BundleI18n.LarkChat.Lark_Legacy_JumpToChat, action: { [weak self] in
            guard let self = self, let fromVC = self.fromVC else {
                assertionFailure("fromVC not set")
                return
            }
            switch self.data.meta {
            case .doc(let docMeta):
                self.router.pushChatViewController(chatId: self.chatId, toMessagePosition: docMeta.position, fromVC: fromVC, extraInfo: ["docUrl": docMeta.url])
            case .wiki(let wikiMeta):
                self.router.pushChatViewController(chatId: self.chatId, toMessagePosition: wikiMeta.docMetaType.position, fromVC: fromVC, extraInfo: ["docUrl": wikiMeta.url])
            default: break
            }
        })
        actionsheet.setCancelItem(text: BundleI18n.LarkChat.Lark_Legacy_Cancel)
        navigator.present(actionsheet, from: fromVC)

        var docUrl: String = ""
        switch data.meta {
        case .doc(let docMeta):
            docUrl = docMeta.url
        case .wiki(let wikiMeta):
            docUrl = wikiMeta.url
        default: break
        }
        if !docUrl.isEmpty,
           let url = URL(string: docUrl) {
           let token = chatDocDependency.isSupportURLType(url: url).2
            Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_LIST_CLICK,
                                  params: ["click": "more",
                                           "target": "none",
                                           "file_id": token],
                                  md5AllowList: ["file_id"]))

        }
    }

    func gotoChat() {
        guard let fromVC = self.fromVC else {
            assertionFailure("fromVC not set")
            return
        }
        switch data.meta {
        case .doc(let docMeta):
            router.pushChatViewController(chatId: self.chatId, toMessagePosition: docMeta.position, fromVC: fromVC, extraInfo: ["docUrl": docMeta.url])
        case .wiki(let wikiMeta):
            router.pushChatViewController(chatId: self.chatId, toMessagePosition: wikiMeta.docMetaType.position, fromVC: fromVC, extraInfo: ["docUrl": wikiMeta.url])
        default: break
        }
    }

    func docMeta() -> SearchMetaDocType? {
        switch data.meta {
        case .doc(let meta): return meta
        case .wiki(let wiki): return wiki.docMetaType
        default: return nil
        }
    }
}

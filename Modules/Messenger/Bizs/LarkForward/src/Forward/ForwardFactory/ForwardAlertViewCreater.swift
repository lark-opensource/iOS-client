//
//  ForwardAlertViewCreater.swift
//  LarkForward
//
//  Created by 姚启灏 on 2019/2/19.
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
import LarkContainer

// nolint: duplicated_code,long_function,magic_number -- v2转发逻辑，v3转发全业务GA后可删除
// TODO: Do not use magic number.
let collectViewWidth: CGFloat = UDDialog.Layout.dialogWidth - 40
let lineSpacing: CGFloat = 10

final class ForwardAlertViewCreater: NSObject {
    static let logger = Logger.log(ForwardAlertViewCreater.self)
    static let avatarSize: CGSize = CGSize(width: 40, height: 40)
    private let forwardChats: [ForwardItem]
    private let forwardProvider: ForwardAlertProvider
    private var itemWidth: CGFloat = ForwardAlertViewCreater.avatarSize.width
    private let itemHeight: CGFloat = ForwardAlertViewCreater.avatarSize.height
    private let isShowInputView: Bool
    private let disposeBag: DisposeBag = DisposeBag()

    // 转发支持目标预览 FG
    private lazy var isSupportTargetPreview: Bool = {
        userResolver.fg.staticFeatureGatingValue(with: "core.forward.target_preview")
    }()

    //根据forwardChats数决定ui样式内容，参见具体需求设计
    let userResolver: LarkContainer.UserResolver
    init(userResolver: LarkContainer.UserResolver, forwardChats: [ForwardItem], forwardProvider: ForwardAlertProvider) {
        self.userResolver = userResolver
        self.forwardChats = forwardChats
        self.forwardProvider = forwardProvider
        self.isShowInputView = forwardProvider.isShowInputView(by: forwardChats)
        if self.forwardChats.count == 1 {
            itemWidth = collectViewWidth
        }
    }

    private func presentPreviewViewController(item: ForwardItem, from: UIViewController) {
        let chatID = item.chatId ?? ""
        //未开启过会话的单聊，chatID为空时，需传入uid
        let userID = chatID.isEmpty ? item.id : ""
        if !TargetPreviewUtils.canTargetPreview(forwardItem: item) {
            if let window = from.view.window {
                UDToast.showTips(with: BundleI18n.LarkForward.Lark_IM_UnableToPreviewContent_Toast, on: window)
            }
        } else if TargetPreviewUtils.isThreadGroup(forwardItem: item) {
            //话题群
            let threadChatPreviewBody = ThreadPreviewByIDBody(chatID: chatID)
            self.forwardProvider.userResolver.navigator.present(body: threadChatPreviewBody, wrap: LkNavigationController.self, from: from)
        } else {
            //会话
            let chatPreviewBody = ForwardChatMessagePreviewBody(chatId: chatID, userId: userID, title: item.name)
            self.forwardProvider.userResolver.navigator.present(body: chatPreviewBody, wrap: LkNavigationController.self, from: from)
        }
        SearchTrackUtil.trackPickerSelectClick(scene: forwardProvider.pickerTrackScene, clickType: .chatDetail(target: "none"))
    }
    // nolint: duplicated_code
    func createConfirmContentView() -> (UIView, LarkEditTextView?) {
        let baseView = UIView()
        let layout = UICollectionViewFlowLayout()
        let avartCount = Display.typeIsLike == .iPhone5 ? 4 : 5

        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumInteritemSpacing = (collectViewWidth - CGFloat(avartCount) * itemWidth) / CGFloat(avartCount) + 1
        layout.minimumLineSpacing = lineSpacing

        let line: CGFloat = forwardChats.count <= avartCount ? 1 : 2
        let collectHeight = line * itemHeight + lineSpacing * (line - 1)
        let chatCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        chatCollectionView.backgroundColor = UIColor.clear
        var arrowIconShow = false
        if isSupportTargetPreview {
            //目标点击手势
            chatCollectionView.rx.modelSelected(ForwardItem.self)
                .subscribe(onNext: { [weak self] item in
                    guard let self = self, let from = self.forwardProvider.targetVc as? UIViewController else { return }
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
        var footer = forwardProvider.containBurnMessage() ? ForwardMessageBurnConfirmFooter() : forwardProvider.getContentView(by: forwardChats)
        if let footer = footer {
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

public final class ForwardAlertAvatarCollectionViewCell: UICollectionViewCell {
    var avatarView: BizAvatar = .init(frame: .zero)
    private lazy var thumbnailAvatarView: BizAvatar = {
        let avatarView = BizAvatar()
        avatarView.isHidden = true
        return avatarView
    }()
    private var thumbnailwidth: CGFloat = 0
    override init(frame: CGRect) {
        super.init(frame: frame)

        avatarView = BizAvatar(frame: self.bounds)
        self.contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        thumbnailwidth = self.bounds.width / 2.0
        self.avatarView.addSubview(thumbnailAvatarView)
        self.thumbnailAvatarView.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
            make.size.equalTo(CGSize(width: thumbnailwidth - 1, height: thumbnailwidth - 1))
        }
    }
    public override func layoutSubviews() {
        super.layoutSubviews()
        if self.bounds.width / 2.0 != thumbnailwidth {
            self.thumbnailwidth = self.bounds.width / 2.0
            self.thumbnailAvatarView.snp.remakeConstraints { make in
                make.right.bottom.equalToSuperview()
                make.size.equalTo(CGSize(width: thumbnailwidth - 1, height: thumbnailwidth - 1))
            }
        }
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setContent(_ id: String, avatarKey: String, image: UIImage?, avatarErrorHandler: ((Error) -> Void)? = nil) {
        self.thumbnailAvatarView.isHidden = image == nil
        if let image = image {
            self.avatarView.setAvatarByIdentifier("0", avatarKey: "")
            self.avatarView.image = image
            self.thumbnailAvatarView.image = nil
            self.thumbnailAvatarView.setAvatarByIdentifier(id, avatarKey: avatarKey) {
                if case let .failure(error) = $0 {
                    avatarErrorHandler?(error)
                }
            }
        } else {
            self.avatarView.image = nil
            self.avatarView.setAvatarByIdentifier(id, avatarKey: avatarKey) {
                if case let .failure(error) = $0 {
                    avatarErrorHandler?(error)
                }
            }
        }
    }
}

public class BaseForwardConfirmFooter: UIView {

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)

        self.backgroundColor = UIColor.ud.bgFloatOverlay
        self.layer.cornerRadius = 5
    }
}

public class NewBaseForwardConfirmFooter: UIView {

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)

        self.backgroundColor = UIColor.ud.bgFloat
        self.layer.cornerRadius = 8
        self.layer.borderWidth = 1
        self.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
    }
}

public class BaseTapForwardConfirmFooter: BaseForwardConfirmFooter {

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var disposeBag: DisposeBag = DisposeBag()
    public var didClickAction: (() -> Void)?
    public lazy var nextImageView: UIImageView = {
        let imageView = UIImageView(image: Resources.forwardNext)
        return imageView
    }()

    override init() {
        super.init()

        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe(onNext: { [weak self] (_) in
            guard let self = self else { return }
            guard let clickAction = self.didClickAction else { return }
            clickAction()
        })
        self.addGestureRecognizer(tap)
    }
}

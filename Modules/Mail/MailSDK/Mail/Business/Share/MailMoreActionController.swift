//
//  MoreViewController.swift
//  MailSDK
//
//  Created by Ryan on 2019/12/10.
//

import UIKit

typealias MailActionCallBack = (_ sender: UIView?) -> Void
typealias MailSwitchActionCallBack = (_ status: Bool) -> Void

enum MailContextActionItemType {
    case cancelScheduleSend
    case turnOffTranslation
    case translate
    case reply
    case replyAll
    case forward
    case reEdit
    case recall
    case forwardToChat
    case unsubscribe
    case trashMessage
    case deleteMessagePermanently
    case emlAsAttachment
    case blockSender
    case revertScale
    case jumpToThread // 打开所在会话 feed特有
    
    /// 上报埋点
    /// https://bytedance.feishu.cn/sheets/WC2LszXv2hxrp2tPT4hcvaXynMb?scene=multi_page&sub_scene=message
    var coreEventName: String {
        switch self {
        case .cancelScheduleSend:
            return "cancel_time_send"
        case .turnOffTranslation:
            return "cancel_translate_email"
        case .translate:
            return "translate_email"
        case .reply:
            return "reply"
        case .replyAll:
            return "reply_all"
        case .forward:
            return "forward"
        case .reEdit:
            return "edit_again"
        case .recall:
            return "mail_recall"
        case .forwardToChat:
            return "email_share"
        case .unsubscribe:
            return "unsubscribe"
        case .trashMessage:
            return "trash"
        case .deleteMessagePermanently:
            return "delete_clean"
        case .emlAsAttachment:
            return "eml_as_attachment"
        case .blockSender:
            return "blockSender"
        case .revertScale:
            return "revertScale"
        case .jumpToThread:
            return "jumpToThread"
        }
    }
    
    /// action是否有二次确认，有的话需要再二次确认时处理埋点上报
    /// 参考 deleteMessage永久删除 和 handleUnsubscribe取消订阅 处理
    var handleTrackOnAlert: Bool {
        switch self {
        case .cancelScheduleSend, .turnOffTranslation, .translate, .reply, .replyAll, .forward, .reEdit, .recall, .forwardToChat, .trashMessage, .emlAsAttachment, .blockSender, .revertScale, .jumpToThread:
            return false
        case .deleteMessagePermanently, .unsubscribe:
            return true
            
        }
    }

    var messageItemGroupNumber: Int {
        switch self {
        case .jumpToThread:
            return 0
        case .reply, .replyAll, .forward, .emlAsAttachment:
            return 1
        case .forwardToChat:
            return 2
        case .trashMessage, .deleteMessagePermanently, .unsubscribe, .blockSender:
            return 3
        case .revertScale:
            return 4
        case .reEdit, .recall:
            return 5
        case .translate, .turnOffTranslation:
            return 6
        case .cancelScheduleSend:
            return 999
            
        }
    }
}

// 显示样式
enum MailActionItemDisplayType {
    case iconWithText
    case textWithStatus
    case textWithSwitch
}

protocol MailActionItemProtocol {
    var title: String { get }
    var disable: Bool { get }
    var udGroupNumber: Int { get }
    var actionType: ActionType { get }
    var displayType: MailActionItemDisplayType { get }
}

struct MailActionItem: MailActionItemProtocol {
    var title: String
    var icon: UIImage
    var disable: Bool = false
    ///  对应UD组件的分组序号
    var udGroupNumber: Int
    var actionCallBack: MailActionCallBack
    var tintColor: UIColor?
    var actionType: ActionType
    let displayType: MailActionItemDisplayType = .iconWithText

    init(title: String, icon: UIImage, actionType: ActionType = .unknown, udGroupNumber: Int = 999, tintColor: UIColor? = nil, actionCallBack: @escaping MailActionCallBack) {
        self.title = title
        self.icon = icon
        self.tintColor = tintColor
        self.udGroupNumber = udGroupNumber
        self.actionCallBack = actionCallBack
        self.actionType = actionType
    }
}

struct MailActionStatusItem: MailActionItemProtocol {
    var title: String
    var disable: Bool = false
    var udGroupNumber: Int
    var actionType: ActionType
    let displayType: MailActionItemDisplayType = .textWithStatus
    var actionCallBack: MailActionCallBack
    var status: String

    init(title: String, actionType: ActionType, udGroupNumber: Int = 999, status: String = "", actionCallBack: @escaping MailActionCallBack) {
        self.title = title
        self.actionType = actionType
        self.udGroupNumber = udGroupNumber
        self.actionCallBack = actionCallBack
        self.status = status
    }
}

struct MailActionSwitchItem: MailActionItemProtocol {
    var title: String
    var disable: Bool = false
    var udGroupNumber: Int
    var actionType: ActionType
    let displayType: MailActionItemDisplayType = .textWithSwitch
    var actionCallBack: MailSwitchActionCallBack
    var status: Bool

    init(title: String, actionType: ActionType, udGroupNumber: Int = 999, status: Bool = false, actionCallBack: @escaping MailSwitchActionCallBack) {
        self.title = title
        self.actionType = actionType
        self.udGroupNumber = udGroupNumber
        self.actionCallBack = actionCallBack
        self.status = status
    }
}

extension Array where Element == MailActionItem {
//    func intoSectionItems() -> [[MailActionItem]] {
//        return sorted(by: { item1, item2 in
//            return item1.udGroupNumber < item2.udGroupNumber
//        })
//            .reduce(into: [[MailActionItem]]()) { tempo, item in
//                if let lastArray = tempo.last {
//                    if lastArray.first?.udGroupNumber == item.udGroupNumber {
//                        let head: [[MailActionItem]] = Array(tempo.dropLast())
//                        let tail: [[MailActionItem]] = [lastArray + [item]]
//                        tempo = head + tail
//                    } else {
//                        tempo.append([item])
//                    }
//                } else {
//                    tempo = [[item]]
//                }
//            }
//    }
}

enum MoreActionHeaderIconType {
    /// show image as icon
    case image(_ image: UIImage)
    /// show text with backgroundColor as icon
    case text(_ text: String, backgroundColor: UIColor)
    /// show avatar with userId as icon
    case avatar(_ userId: String, name: String)
    /// show original Icon without corner
    case imageWithoutCorner(_image:UIImage)
}

struct MoreActionHeaderConfig {
    let iconType: MoreActionHeaderIconType
    let title: String
    let subtitle: String?
    var stranger: Bool = false
}

class MailMoreActionController: WidgetViewController {
    lazy var upperCollectionView: UICollectionView = {
        return setupCollectionView()
    }()
    lazy var lowerCollectionView: UICollectionView = {
        return setupCollectionView()
    }()
    let upperItems: [MailActionItem]
    let lowerItems: [MailActionItem]
    struct Layout {
        static let panelHeight: CGFloat = 130
        static let collectionTopPadding: CGFloat = 34
        static let collectionLeftPadding: CGFloat = 25
        static let collectionItemWidth: CGFloat = 54
        static let collectionItemHeight: CGFloat = 93
        static let cancelPanelHeight: CGFloat = 57
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    init(upperItems: [MailActionItem], lowerItems: [MailActionItem]) {
        self.upperItems = upperItems
        self.lowerItems = lowerItems
        let contentHeight = 323 - (upperItems.isEmpty ? Layout.panelHeight : 0)
        super.init(contentHeight: contentHeight)
        contentView.backgroundColor = UIColor.ud.bgBodyOverlay
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupCancelButton()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: {  [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.updateCollectionViewLineSpacing(width: size.width)
            }, completion: nil)
        super.viewWillTransition(to: size, with: coordinator)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCollectionViewLineSpacing(width: view.bounds.width)
    }

    func setupView() {
        if !upperItems.isEmpty {
            contentView.addSubview(upperCollectionView)
            upperCollectionView.snp.makeConstraints { (make) in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(Layout.panelHeight)
            }

            contentView.addSubview(lowerCollectionView)
            lowerCollectionView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(upperCollectionView.snp.bottom)
                make.height.equalTo(Layout.panelHeight)
            }

            let line = UIView()
            line.backgroundColor = UIColor.ud.lineBorderCard
            contentView.addSubview(line)
            line.snp.makeConstraints { (make) in
                make.right.equalToSuperview()
                make.left.equalTo(28)
                make.top.equalTo(upperCollectionView.snp.bottom)
                make.height.equalTo(1)
            }
        } else {
            contentView.addSubview(lowerCollectionView)
            lowerCollectionView.snp.makeConstraints { (make) in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(Layout.panelHeight)
            }
        }
    }

    private func updateCollectionViewLineSpacing(width: CGFloat) {
        func minimumLineSpacing(width: CGFloat) -> CGFloat {
            let magicNumber: CGFloat = width > 375 ? 5 : 4
            let leftPadding: CGFloat = 15
            let isOverSize = lowerItems.count > Int(magicNumber + 1)
            let space: CGFloat = (width - leftPadding) - 54 * (isOverSize ? (magicNumber + 0.5) : (magicNumber + 1))
            return space / magicNumber
        }

        for collectionView in [upperCollectionView, lowerCollectionView] {
            if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                let space = minimumLineSpacing(width: width)
                flowLayout.minimumLineSpacing = space
            }
        }
    }

    private func setupCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        let leftPadding: CGFloat = 15
        layout.sectionInset = UIEdgeInsets(top: Layout.collectionTopPadding,
                                           left: leftPadding,
                                           bottom: 20,
                                           right: leftPadding)
        layout.itemSize = CGSize(width: Layout.collectionItemWidth,
                                 height: Layout.collectionItemHeight)
        layout.scrollDirection = .horizontal

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceHorizontal = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(MoreActionCell.self,
                                forCellWithReuseIdentifier: MoreActionCell.reuseIdentifier)
        return collectionView
    }

    func setupCancelButton() {
        let cancelButton = UIButton()
        cancelButton.backgroundColor = UIColor.ud.bgBodyOverlay
        cancelButton.setTitle(BundleI18n.MailSDK.Mail_Alert_Cancel, for: .normal)
        cancelButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        cancelButton.addTarget(self, action: #selector(onCancelButtonClick), for: .touchUpInside)
        contentView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(lowerCollectionView.snp.bottom)
            make.height.equalTo(Layout.cancelPanelHeight)
        }
    }

    @objc
    func onCancelButtonClick() {
        animatedView(isShow: false) {}
    }
}

extension MailMoreActionController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView == upperCollectionView ? upperItems.count : lowerItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reusableCell = collectionView.dequeueReusableCell(withReuseIdentifier: MoreActionCell.reuseIdentifier, for: indexPath)
        guard let cell = reusableCell as? MoreActionCell else {
            assertionFailure("can not find cell")
            return reusableCell
        }
        let items = collectionView == upperCollectionView ? upperItems : lowerItems
        let item = items[indexPath.row]
        cell.itemLabel.text = item.title
        cell.itemImageView.image = item.icon.withRenderingMode(.alwaysTemplate)
        if let iconTintColor = item.tintColor {
            cell.itemImageView.tintColor = iconTintColor
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dismiss(animated: false) {
            let items = collectionView == self.upperCollectionView ? self.upperItems : self.lowerItems
            let item = items[indexPath.row]
            item.actionCallBack(nil)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? MoreActionCell else { return }
        cell.itemView.backgroundColor = UIColor.ud.udtokenTableBgPress
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? MoreActionCell else { return }
        cell.itemView.backgroundColor = UIColor.ud.bgBodyOverlay
    }
}

class MoreActionCell: UICollectionViewCell {
    lazy var itemLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = UIColor.ud.textCaption
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    lazy var itemView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBodyOverlay
        view.layer.cornerRadius = 27
        return view
    }()

    lazy var itemImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.tintColor = UIColor.ud.iconN1
        return imgView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(itemView)
        itemView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(54)
        }
        itemView.addSubview(itemImageView)
        itemImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(26)
            make.center.equalToSuperview()
        }
        contentView.addSubview(itemLabel)
        itemLabel.snp.makeConstraints { (make) in
            make.top.equalTo(itemView.snp.bottom).offset(5)
            make.left.right.equalToSuperview()
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MailMoreActionController: MailMessagePadRemoveHandling {
    func dismissOnMailMessageRemove() {
        animatedView(isShow: false)
    }
}

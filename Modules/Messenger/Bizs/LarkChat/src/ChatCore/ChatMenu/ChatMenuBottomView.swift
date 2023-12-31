//
//  ChatMenuBottomView.swift
//  LarkChat
//
//  Created by Zigeng on 2022/9/8.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkCore
import LKCommonsLogging
import UniverseDesignIcon
import LarkGuide
import LarkGuideUI
import LarkContainer
import LarkMessengerInterface

protocol ChaMenutKeyboardDelegate: AnyObject {
    func didClickKeyboardButton()
}

struct ChatBottomMenuConfig {
    static let cellPadding: CGFloat = 8
    static let cellHeight: CGFloat = 46
    static let expandMenuIcon: UIImage = Resources.menu_outlined
    static let expandIconSize: CGSize = CGSize(width: 12, height: 12)
    static let customIconSize: CGSize = CGSize(width: 16, height: 16)
    static let maxCellCount: Int = 3
    static let font = UIFont.systemFont(ofSize: 14)
}

final class ChatMenuBottomView: UIView, UserResolverWrapper {
    var userResolver: UserResolver { vm.userResolver }
    private weak var keyboardDelegate: ChaMenutKeyboardDelegate?
    private var vm: ChatMenuViewModel
    private let disposeBag: DisposeBag = DisposeBag()
    var chatFromWhere: ChatFromWhere = .ignored
    private weak var chatVC: UIViewController?
    @ScopedInjectedLazy private var newGuideManager: NewGuideService?
    private var showGuideAlready: Bool = false

    private var itemWidth: CGFloat {
        guard !vm.dataSource.isEmpty else { return 0 }
        let itemWidth: CGFloat = ((self.collectionView.frame.size.width + ChatBottomMenuConfig.cellPadding) / CGFloat(itemCount)) - ChatBottomMenuConfig.cellPadding
        return max(itemWidth, CGFloat.leastNonzeroMagnitude)
    }

    private var itemCount: Int {
        self.vm.dataSource.count <= ChatBottomMenuConfig.maxCellCount ? vm.dataSource.count : ChatBottomMenuConfig.maxCellCount
    }

    fileprivate var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: .init())

    private let hasMenuItemSignal: ReplaySubject<Bool> = ReplaySubject<Bool>.create(bufferSize: 1)
    lazy var hasMenuItemDriver: Driver<Bool> = {
        return hasMenuItemSignal.asDriver(onErrorJustReturn: false)
    }()
    var hasMenuItem: Bool = false {
        didSet {
            hasMenuItemSignal.onNext(hasMenuItem)
            if hasMenuItem { showKeyboardGuideIfNeeded() }
        }
    }
    private let hasKeyboardEntry: Bool
    private lazy var loadingView: UIView = {
        let loadingView = UIView()
        loadingView.backgroundColor = UIColor.ud.bgBody
        loadingView.layer.cornerRadius = 6
        return loadingView
    }()

    public init(vm: ChatMenuViewModel, delegate: ChaMenutKeyboardDelegate, hasKeyboardEntry: Bool, chatVC: UIViewController) {
        self.vm = vm
        self.keyboardDelegate = delegate
        self.hasKeyboardEntry = hasKeyboardEntry
        self.chatVC = chatVC
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBodyOverlay
        if hasKeyboardEntry {
            self.initKeyboardButton()
        }
        self.initCollectionView()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        showKeyboardGuideIfNeeded()
    }

    private func showKeyboardGuideIfNeeded() {
        guard self.hasMenuItem, self.hasKeyboardEntry else { return }
        if showGuideAlready { return }
        showGuideAlready = true
        DispatchQueue.main.async {
            let keyboardGuideKey = "im_chat_input_menu_onboard_reverse"
            let rect = self.keyboardButton.convert(self.keyboardButton.bounds, to: nil)
            let guideAnchor = TargetAnchor(targetSourceType: .targetRect(rect),
                                           arrowDirection: .down,
                                           targetRectType: .rectangle)
            let item = BubbleItemConfig(guideAnchor: guideAnchor,
                                        textConfig: TextInfoConfig(detail: BundleI18n.LarkChat.Lark_IM_Mobile_FunctionMenuSwitchToText_Onboard))
            let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: UIColor.clear)
            let singleBubbleConfig = SingleBubbleConfig(bubbleConfig: item, maskConfig: maskConfig)
            self.newGuideManager?.showBubbleGuideIfNeeded(guideKey: keyboardGuideKey,
                                                         bubbleType: .single(singleBubbleConfig),
                                                         dismissHandler: nil)
        }
    }

    /// 按钮 - 切换至键盘
    private lazy var keyboardButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.menuDisplayOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        button.backgroundColor = UIColor.ud.bgBody
        button.addTarget(self, action: #selector(didClickKeyboardBtn), for: .touchUpInside)
        button.layer.cornerRadius = 8
        return button
    }()

    private func initKeyboardButton() {
        self.addSubview(keyboardButton)
        self.keyboardButton.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(ChatBottomMenuConfig.cellPadding)
            make.height.width.equalTo(ChatBottomMenuConfig.cellHeight)
        }
    }

    @objc
    private func didClickKeyboardBtn() {
        IMTracker.Chat.Main.Click.ChatMenuSwitch(self.vm.getChat(), switchToInput: true, self.chatFromWhere)
        self.keyboardDelegate?.didClickKeyboardButton()
    }

    /// 初始化菜单
    private func initCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: menuCollectionLayout)
        self.collectionView.register(ChatMenuBottomCell.self, forCellWithReuseIdentifier: ChatMenuBottomCell.reuseIdentifier)
        collectionView.isScrollEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        self.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ChatBottomMenuConfig.cellPadding)
            if hasKeyboardEntry {
                make.left.equalTo(keyboardButton.snp.right).offset(ChatBottomMenuConfig.cellPadding)
            } else {
                make.left.equalToSuperview().offset(ChatBottomMenuConfig.cellPadding)
            }
            make.right.equalToSuperview().offset(-ChatBottomMenuConfig.cellPadding)
            make.height.equalTo(ChatBottomMenuConfig.cellHeight)
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-ChatBottomMenuConfig.cellPadding)
        }
        self.collectionView.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.collectionView.reloadData()
        self.vm.tableRefreshDriver.drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.hasMenuItem = self.itemCount != 0
            self.collectionView.reloadData()
            self.loadingView.isHidden = true
            self.dismissMenuExtendVCIfNeeded()
        }).disposed(by: disposeBag)

        self.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalTo(collectionView)
        }
    }

    func dismissMenuExtendVCIfNeeded() {
        if let menuExtendVC = self.chatVC?.presentedViewController as? ChatMenuExtendViewController {
            menuExtendVC.dismiss(animated: true)
        }
    }

    private var menuCollectionLayout: UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = ChatBottomMenuConfig.cellPadding
        return layout
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func trackView() {
        self.vm.trackView()
    }
}

extension ChatMenuBottomView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemCount
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatMenuBottomCell.reuseIdentifier, for: indexPath)
        guard let cell = cell as? ChatMenuBottomCell else {
            return cell
        }
        let cellInfo = vm.dataSource[indexPath.row]
        var imageType: ChatMenuImageType
        if cellInfo.subMenuItems.isEmpty {
            imageType = cellInfo.buttonItem.imageKey.isEmpty ? .none : ChatMenuImageType.key(cellInfo.buttonItem.imageKey)
        } else {
            imageType = ChatMenuImageType.uiImage(ChatBottomMenuConfig.expandMenuIcon)
        }
        cell.setMenuCell(image: imageType, text: cellInfo.buttonItem.name)
        return cell
    }
}

extension ChatMenuBottomView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: IndexPath(row: indexPath.row, section: indexPath.section)) else {
            return
        }
        let minWidth = collectionView.frame.size.width / 3
        vm.didClickBottomItem(index: indexPath.row, source: cell, minWidth: minWidth)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: itemWidth, height: ChatBottomMenuConfig.cellHeight)
    }
}

final class ChatMenuBottomCell: UICollectionViewCell {
    static var reuseIdentifier = "ChatMenuBottomCell"
    private static let logger = Logger.log(ChatMenuBottomCell.self, category: "LarkChat.ChatMenuBottomCell")
    private let icon = UIImageView()
    private let label = UILabel()
    let layoutGuide = UILayoutGuide()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
        self.layer.cornerRadius = 6
        self.label.font = ChatBottomMenuConfig.font
        self.label.textColor = UIColor.ud.textTitle
        self.label.numberOfLines = 2
        self.addSubview(icon)
        self.addSubview(label)
        self.addLayoutGuide(layoutGuide)
        layoutGuide.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().inset(4)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = UIColor.ud.fillHover
        super.touchesBegan(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = UIColor.ud.bgBody
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = UIColor.ud.bgBody
        super.touchesCancelled(touches, with: event)
    }

    func setMenuCell(image: ChatMenuImageType, text: String) {
        switch image {
        case .uiImage(let image):
            self.icon.image = image
            setHasImageLayout(ChatBottomMenuConfig.expandIconSize)
        case .key(let key):
            setHasImageLayout(ChatBottomMenuConfig.customIconSize)
            self.loadImage(key: key)
        case .none:
            setNoImageLayout()
        }
        self.label.text = text
        self.label.invalidateIntrinsicContentSize()
    }

    func loadImage(key: String) {
        self.icon.bt.setLarkImage(with: .default(key: key)) { [weak self] res in
            guard let self = self else { return }
            switch res {
            case .success(let imageResult):
                guard let image = imageResult.image else { return }
                self.icon.image = image
            case .failure(let error):
                Self.logger.error("set image fail", error: error)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.icon.bt.setLarkImage(with: .default(key: ""))
    }

    private func setHasImageLayout(_ iconSize: CGSize) {
        icon.isHidden = false
        icon.snp.remakeConstraints { make in
            make.size.equalTo(iconSize)
            make.left.equalTo(layoutGuide.snp.left)
            make.centerY.equalToSuperview()
        }
        label.snp.remakeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(2)
            make.right.equalTo(layoutGuide.snp.right)
            make.centerY.equalToSuperview()
        }
    }

    private func setNoImageLayout() {
        icon.isHidden = true
        label.snp.remakeConstraints { make in
            make.left.equalTo(layoutGuide.snp.left)
            make.right.equalTo(layoutGuide.snp.right)
            make.centerY.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.label.invalidateIntrinsicContentSize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

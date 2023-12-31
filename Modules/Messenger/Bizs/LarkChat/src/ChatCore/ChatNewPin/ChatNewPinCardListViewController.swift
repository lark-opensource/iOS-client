//
//  ChatNewPinCardListViewController.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/10.
//

import Foundation
import LarkUIKit
import LKCommonsLogging
import LarkModel
import LarkMessageCore
import LarkMessageBase
import LarkSDKInterface
import RxSwift
import RxCocoa
import LarkCore
import LarkContainer
import LarkMessengerInterface
import EENavigator
import LarkOpenChat
import UniverseDesignIcon
import UniverseDesignToast
import UniverseDesignEmpty
import AppContainer
import RichLabel

final class ChatNewPinCardListViewController: BaseUIViewController,
                                              UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let logger = Logger.log(ChatNewPinCardListViewController.self, category: "Module.IM.ChatPin")

    class AddButton: UIControl {

        static var padding: CGFloat { 6 }
        static var iconSize: CGFloat { 20 }

        private lazy var iconImageView: UIImageView = {
            let iconImageView = UIImageView()
            iconImageView.image = UDIcon.getIconByKey(.addSheetOutlined, renderingMode: .alwaysTemplate, size: CGSize(width: Self.iconSize, height: Self.iconSize))
            iconImageView.tintColor = UIColor.ud.iconN1
            return iconImageView
        }()

        private lazy var titleLabel: UILabel = {
            let titleLabel = UILabel()
            titleLabel.font = UIFont.systemFont(ofSize: 16)
            titleLabel.textColor = UIColor.ud.textTitle
            titleLabel.text = BundleI18n.LarkChat.Lark_Legacy_Add
            return titleLabel
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(iconImageView)
            addSubview(titleLabel)
            iconImageView.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(Self.padding)
                make.size.equalTo(Self.iconSize)
                make.centerY.equalToSuperview()
            }
            titleLabel.snp.makeConstraints { make in
                make.left.equalTo(iconImageView.snp.right).offset(2)
                make.top.bottom.right.equalToSuperview().inset(Self.padding)
            }
        }

        func set(_ enable: Bool) {
            if enable {
                iconImageView.tintColor = UIColor.ud.iconN1
                titleLabel.textColor = UIColor.ud.iconN1
            } else {
                iconImageView.tintColor = UIColor.ud.iconDisabled
                titleLabel.textColor = UIColor.ud.iconDisabled
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private lazy var addButton: AddButton = {
        let addButton = AddButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        addButton.addTarget(self, action: #selector(clickAdd), for: .touchUpInside)
        return addButton
    }()

    private struct UIOutputIndentify {
        static let dragGesture: String = "ChatPinCard_DragGesture"
    }

    private class ChatNewPinCardListCollectionFlowLayout: UICollectionViewFlowLayout {
        override func layoutAttributesForInteractivelyMovingItem(at indexPath: IndexPath, withTargetPosition position: CGPoint) -> UICollectionViewLayoutAttributes {
            let attributes = super.layoutAttributesForInteractivelyMovingItem(at: indexPath, withTargetPosition: position)
            attributes.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            return attributes
        }
    }

    class EmptyContainerView: UIView {

        private lazy var emptyView: UDEmptyView = {
            let emptyView = UDEmptyView(config: .init(description: .init(descriptionText: BundleI18n.LarkChat.Lark_IM_NewPin_NoPins_EmptyState),
                                                      imageSize: 100,
                                                      type: .noMessageLog))
            emptyView.useCenterConstraints = true
            emptyView.backgroundColor = UIColor.ud.bgBase
            return emptyView
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(emptyView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        public override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window = self.window else { return }
            emptyView.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalTo(window)
            }
        }
    }

    private lazy var emptyView: EmptyContainerView = EmptyContainerView()

    private lazy var collectionView: UICollectionView = {
        let collectionViewLayout = ChatNewPinCardListCollectionFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumLineSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.setLoadMoreHandlerDelegate(self.viewModel)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        collectionView.register(ChatPinListTipCell.self, forCellWithReuseIdentifier: ChatPinListTipCell.reuseIdentifier)
        collectionView.register(ChatPinOnboardingCollectionViewCell.self, forCellWithReuseIdentifier: ChatPinOnboardingCollectionViewCell.reuseIdentifier)
        collectionView.register(ChatTopNoticeCardCollectionViewCell.self, forCellWithReuseIdentifier: ChatTopNoticeCardCollectionViewCell.reuseIdentifier)
        collectionView.register(ChatOldPinEntranceCardCollectionViewCell.self, forCellWithReuseIdentifier: ChatOldPinEntranceCardCollectionViewCell.reuseIdentifier)
        ChatPinCardModule.getReuseIdentifiers().forEach {
            collectionView.register(ChatPinListCardContainerCell.self, forCellWithReuseIdentifier: $0)
        }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressEvent(gesture:)))
        collectionView.addGestureRecognizer(longPressGesture)
        return collectionView
    }()

    private lazy var titleView: ChatNewPinCardListTitleView = {
        return ChatNewPinCardListTitleView(
            navigator: self.viewModel.userResolver.navigator,
            userGeneralSettings: try? self.viewModel.userResolver.resolve(assert: UserGeneralSettings.self),
            targetVC: self,
            chat: self.viewModel.chat
        )
    }()

    private var draggingCell: ChatPinListCardBaseCell?
    private var draggingCellOriginCenter: CGPoint = .zero
    private var draggingStartPoint: CGPoint = .zero
    private var dragHeightDic: [Int: Int] = [:]
    private var originalDragIndexPath: IndexPath?
    private var showCrossRegionDragTip: Bool = false

    private lazy var placeholderChatView: PlaceholderChatView = {
        let placeholderChatView = PlaceholderChatView(isDark: false,
                                                      title: BundleI18n.LarkChat.Lark_IM_RestrictedMode_ScreenRecordingEmptyState_Text,
                                                      subTitle: BundleI18n.LarkChat.Lark_IM_RestrictedMode_ScreenRecordingEmptyState_Desc)
        placeholderChatView.setNavigationBarDelegate(self)
        return placeholderChatView
    }()

    private let viewModel: ChatNewPinCardListViewModel
    private let disposeBag = DisposeBag()
    private let pageContainer = PageServiceContainer()
    private var screenProtectService: ChatScreenProtectService?
    private var displayCardTrackDic: [Int64: IMTrackerChatPinType] = [:]

    init(viewModel: ChatNewPinCardListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.supportSecondaryOnly = true
        viewModel.targetVC = self
        let screenProtectService = ChatScreenProtectService(chat: self.viewModel.chatBehaviorRelay,
                                                            getTargetVC: { [weak self] in return self },
                                                            userResolver: viewModel.userResolver)
        self.pageContainer.register(ChatScreenProtectService.self) {
            return screenProtectService
        }
        self.screenProtectService = screenProtectService
        self.pageContainer.pageInit()
    }

    @objc
    override func backItemTapped() {
        super.backItemTapped()
        IMTracker.Chat.Sidebar.Click.close(self.viewModel.chat)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        pageContainer.pageDeinit()

        if !self.displayCardTrackDic.isEmpty {
            IMTracker.Chat.Sidebar.TopCard.View(self.viewModel.chat, topList: displayCardTrackDic.map { ($0.key, $0.value) })
        }
    }

    override var navigationBarStyle: LarkUIKit.NavigationBarStyle {
        return .custom(UIColor.ud.bgBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
        self.navigationItem.titleView = titleView
        self.view.backgroundColor = UIColor.ud.bgBase
        self.view.addSubview(emptyView)
        emptyView.isHidden = true
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.viewModel.availableMaxWidth = self.view.bounds.width
        self.bindViewModel()
        self.viewModel.setup()

        self.screenProtectService?.observe(screenCaptured: { [weak self] captured in
            if captured {
                self?.setupPlaceholderView()
            } else {
                self?.removePlaceholderView()
            }
        })
        self.screenProtectService?.observeEnterBackground(targetVC: self)

        pageContainer.pageViewDidLoad()
        IMTracker.Chat.Sidebar.View(self.viewModel.chat)
        self.viewModel.securityAuditService?
            .auditEvent(.chatPin(type: .showChatPinList(chatId: self.viewModel.chat.id)), isSecretChat: false)
        self.viewModel.guideService?.didShowedGuide(guideKey: ChatPinSummaryContainerView.onboardingDotKey)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pageContainer.pageWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pageContainer.pageDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pageContainer.pageWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pageContainer.pageDidDisappear()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let availableMaxWidth = self.view.bounds.width
        if availableMaxWidth != self.viewModel.availableMaxWidth {
            self.viewModel.availableMaxWidth = availableMaxWidth
            self.viewModel.onResize()
        }
    }

    private func scrollToFirstCard() {
        let section = ChatNewPinCardListViewModel.unStickPinCardIndex
        guard collectionView.numberOfSections > section, collectionView.numberOfItems(inSection: section) > 0 else {
            return
        }
        collectionView.scrollToItem(at: IndexPath(item: 0, section: section), at: .top, animated: false)
    }

    private func bindViewModel() {
        self.viewModel.tableRefreshDriver.drive(onNext: { [weak self] refreshType in
            guard let self = self else { return }
            self.logger.info("chatPinCardTrace tableRefreshDriver onNext \(self.viewModel.chat.id) \(refreshType.describ)")
            switch refreshType {
            case .refreshTable(let hasMore):
                self.collectionView.reloadData()
                if let hasMore = hasMore {
                    self.collectionView.hasFooter = hasMore
                }
                self.collectionView.enableBottomLoadMore(self.viewModel.getPinsLoadMoreEnable.value && !self.isDragging)
            case .pinsUpdate(indexPaths: let indexPaths):
                UIView.performWithoutAnimation {
                    self.collectionView.reloadItems(at: indexPaths)
                }
            case .scrollToTop:
                self.scrollToFirstCard()
            }
            self.showEmptyTipIfNeeded()
        }).disposed(by: self.disposeBag)

        self.viewModel.enableUIOutputDriver.filter({ return $0 })
            .drive(onNext: { [weak self] _ in
                self?.collectionView.reloadData()
                self?.showEmptyTipIfNeeded()
            }).disposed(by: self.disposeBag)

        self.viewModel.getPinsLoadMoreEnableDriver
            .drive(onNext: { [weak self] (enable) in
                guard let self = self else { return }
                self.collectionView.enableBottomLoadMore(enable && !self.isDragging)
            }).disposed(by: self.disposeBag)

        self.viewModel.pinPermissionBehaviorRelay
            .asDriver()
            .drive(onNext: { [weak self] permissionResult in
                guard let self = self else { return }
                if case .success = permissionResult {
                    self.addButton.set(true)
                } else {
                    self.addButton.set(false)
                }
            }).disposed(by: self.disposeBag)

        self.viewModel.onboardingDisplayDriver
            .drive(onNext: { [weak self] in
                self?.titleView.displayOnboarding()
            }).disposed(by: self.disposeBag)
    }

    private func showEmptyTipIfNeeded() {
        let dataSourceIsEmpty = self.viewModel.uiDataSource.flatMap { $0 }.isEmpty
        self.collectionView.isHidden = dataSourceIsEmpty
        self.emptyView.isHidden = !dataSourceIsEmpty
    }

    @objc
    private func clickAdd() {
        IMTracker.Chat.Sidebar.Click.addTop(self.viewModel.chat)
        self.viewModel.handleAddPin()
    }

    /// 添加占位的界面
    private func setupPlaceholderView() {
        self.isNavigationBarHidden = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        /// 显示占位图
        self.view.addSubview(placeholderChatView)
        placeholderChatView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    /// 移除占位的界面
    private func removePlaceholderView() {
        self.isNavigationBarHidden = false
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        /// 移除占位图
        self.placeholderChatView.removeFromSuperview()
    }

    private var isDragging: Bool = false {
        didSet {
            guard isDragging != oldValue else { return }
            if isDragging {
                self.viewModel.uiDataSource
                    .flatMap { $0 }
                    .compactMap { $0 as? ChatPinCardContainerCellViewModel }
                    .forEach { cellVM in
                        cellVM.updateDragState(isDragging: true)
                    }
                self.collectionView.enableBottomLoadMore(false)
            } else {
                self.originalDragIndexPath = nil
                self.showCrossRegionDragTip = false
                self.draggingCell?.updateDragState(isDragging: false)
                self.draggingCell = nil
                self.dragHeightDic = [:]
                self.viewModel.uiDataSource
                    .flatMap { $0 }
                    .compactMap { $0 as? ChatPinCardContainerCellViewModel }
                    .forEach { cellVM in
                        cellVM.updateDragState(isDragging: false)
                    }
                self.collectionView.enableBottomLoadMore(self.viewModel.getPinsLoadMoreEnable.value)
            }
        }
    }

    @objc
    private func longPressEvent(gesture: UILongPressGestureRecognizer) {
        let gestureState = gesture.state

        switch gestureState {
        case .began:
            guard ChatNewPinConfig.supportPinToTop(self.viewModel.userResolver.fg) else { return }
            let point = gesture.location(in: collectionView)
            guard let selectedIndexPath = collectionView.indexPathForItem(at: point),
                  let draggingCell = collectionView.cellForItem(at: selectedIndexPath) as? ChatPinListCardBaseCell,
                  let cardCellVM = self.viewModel.uiDataSource[selectedIndexPath.section][selectedIndexPath.item] as? ChatPinCardContainerCellViewModel else {
                return
            }
            guard !cardCellVM.metaModel.pin.isOld else {
                UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_NewPin_EarlierPinnedCantReorder_Toast, on: self.view)
                return
            }
            guard canMoveAt(section: selectedIndexPath.section) else {
                return
            }
            switch self.viewModel.pinPermissionBehaviorRelay.value {
            case .success:
                break
            case .failure(reason: let reason):
                UDToast.showTips(with: reason, on: self.view)
                return
            }
            guard self.collectionView.beginInteractiveMovementForItem(at: selectedIndexPath) else {
                return
            }
            self.isDragging = true
            self.originalDragIndexPath = selectedIndexPath
            self.showCrossRegionDragTip = true
            self.draggingStartPoint = gesture.location(in: self.collectionView)
            draggingCell.updateDragState(isDragging: true)
            self.draggingCellOriginCenter = draggingCell.center
            self.draggingCell = draggingCell
            self.viewModel.uiOutput(enable: false, indentify: UIOutputIndentify.dragGesture)
        case .changed:
            self.showCrossRegionDragTipIfNeeded(gesture)
            collectionView.updateInteractiveMovementTargetPosition(CGPoint(x: self.collectionView.bounds.width / 2,
                                                                           y: self.draggingCellOriginCenter.y + gesture.location(in: self.collectionView).y - draggingStartPoint.y))
        case .ended:
            self.isDragging = false
            self.collectionView.endInteractiveMovement()
            self.viewModel.uiOutput(enable: true, indentify: UIOutputIndentify.dragGesture)
        default:
            self.isDragging = false
            collectionView.cancelInteractiveMovement()
            self.viewModel.uiOutput(enable: true, indentify: UIOutputIndentify.dragGesture)
        }
    }

    private func canMoveAt(section: Int) -> Bool {
        return section == ChatNewPinCardListViewModel.unStickPinCardIndex || section == ChatNewPinCardListViewModel.stickPinCardIndex
    }

    private func showCrossRegionDragTipIfNeeded(_ gesture: UILongPressGestureRecognizer) {
        guard showCrossRegionDragTip else { return }
        guard let beginDragSection = self.originalDragIndexPath?.section else { return }
        let point = gesture.location(in: collectionView)
        guard let endDragSection = collectionView.indexPathForItem(at: point)?.section else { return }
        switch (beginDragSection, endDragSection) {
        case (ChatNewPinCardListViewModel.stickPinCardIndex, ChatNewPinCardListViewModel.unStickPinCardIndex):
            showCrossRegionDragTip = false
            UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_NewPin_ClickUnprioritizeToMove_Toast, on: self.view)
        case (ChatNewPinCardListViewModel.unStickPinCardIndex, ChatNewPinCardListViewModel.stickPinCardIndex):
            showCrossRegionDragTip = false
            UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_NewPin_ClickPrioritizeToMove_Toast, on: self.view)
        default:
            break
        }
    }

    // MARK: - UICollectionViewDelegate && UICollectionViewDataSource && UICollectionViewDelegateFlowLayout
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.viewModel.uiDataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.uiDataSource[section].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == ChatNewPinCardListViewModel.onboardingIndex {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatPinOnboardingCollectionViewCell.reuseIdentifier, for: indexPath)
            if let onboardingCell = cell as? ChatPinOnboardingCollectionViewCell,
               let cellVM = self.viewModel.uiDataSource[indexPath.section][indexPath.item] as? ChatPinOnboardingCellViewModel {
                let cellHeight = onboardingCell.updateAndLayout(targetVC: self,
                                                                nav: self.viewModel.userResolver.navigator,
                                                                chat: self.viewModel.chat,
                                                                detailLinkConfig: (try? self.viewModel.userResolver.resolve(assert: UserGeneralSettings.self))?.chatPinOnboardingDetailLinkConfig,
                                                                closeHandler: cellVM.closeHandler)
                cellVM.height = cellHeight
            }
            return cell
        } else if indexPath.section == ChatNewPinCardListViewModel.topNoticeIndex {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatTopNoticeCardCollectionViewCell.reuseIdentifier, for: indexPath)
            if let topNoticeCell = cell as? ChatTopNoticeCardCollectionViewCell,
               let cellVM = self.viewModel.uiDataSource[indexPath.section][indexPath.item] as? ChatPinCardTopNoticeCellViewModel {
                topNoticeCell.update(cellViewModel: cellVM)
            }
            return cell
        } else if indexPath.section == ChatNewPinCardListViewModel.oldPinEntryIndex {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatOldPinEntranceCardCollectionViewCell.reuseIdentifier, for: indexPath)
            if let pinEntranceCell = cell as? ChatOldPinEntranceCardCollectionViewCell {
                pinEntranceCell.update(chat: self.viewModel.chat, targetVC: self, nav: self.viewModel.userResolver.navigator)
            }
            return cell
        } else if indexPath.section == ChatNewPinCardListViewModel.stickPinCardIndex || indexPath.section == ChatNewPinCardListViewModel.unStickPinCardIndex {
            let pinCellVM = self.viewModel.uiDataSource[indexPath.section][indexPath.item]
            let reuseIdentifier = pinCellVM.identifier
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)

            if let cellVM = pinCellVM as? ChatPinTipCellViewModel {
                if let tipCell = cell as? ChatPinListTipCell {
                    tipCell.update(cellVM.title)
                }

            } else if let cellVM = pinCellVM as? ChatPinCardContainerCellViewModel {
                if let pinCardCell = cell as? ChatPinListCardContainerCell {
                    cellVM.render(pinCardCell)
                    pinCardCell.actionHandler = { [weak cellVM, weak self] moreButton in
                        guard let cellVM = cellVM, let self = self else { return }
                        let pin = cellVM.metaModel.pin
                        IMTracker.Chat.Sidebar.Click.more(self.viewModel.chat, topId: pin.id, messageId: nil, type: IMTrackerChatPinType(type: pin.type))
                        self.viewModel.handleMoreAction(sourceView: moreButton, actionItemTypes: cellVM.getActionItemTypes(), pinModel: cellVM.metaModel.pin)
                    }
                }
            }
            return cell
        } else {
            assertionFailure("index out of range")
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var item = indexPath.item
        if isDragging, indexPath.section == self.originalDragIndexPath?.section {
            item = dragHeightDic[item] ?? item
        }
        return CGSize(
            width: self.view.bounds.width,
            height: self.viewModel.uiDataSource[indexPath.section][item].getCellHeight()
        )
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.section < self.viewModel.uiDataSource.count,
              indexPath.item < self.viewModel.uiDataSource[indexPath.section].count else {
            return
        }
        let cellVM = self.viewModel.uiDataSource[indexPath.section][indexPath.item]
        cellVM.willDisplay()
        if let cardVM = cellVM as? ChatPinCardContainerCellViewModel {
            self.displayCardTrackDic[cardVM.metaModel.pin.id] = IMTrackerChatPinType(type: cardVM.metaModel.pin.type)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.section < self.viewModel.uiDataSource.count,
              indexPath.item < self.viewModel.uiDataSource[indexPath.section].count else {
            return
        }
        self.viewModel.uiDataSource[indexPath.section][indexPath.item].didEndDisplay()
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return canMoveAt(section: indexPath.section)
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        self.viewModel.reorder(
            from: sourceIndexPath.item,
            to: destinationIndexPath.item,
            isTop: sourceIndexPath.section == ChatNewPinCardListViewModel.stickPinCardIndex
        )
    }

    private func resetDragHeightDic(from: Int, to: Int) {
        dragHeightDic = [:]
        if from < to {
            for i in from..<to {
                dragHeightDic[i] = i + 1
            }
            dragHeightDic[to] = from
        } else if from > to {
            for i in (to + 1)...from {
                dragHeightDic[i] = i - 1
            }
            dragHeightDic[to] = from
        }
    }

    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt currentIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        guard canMoveAt(section: proposedIndexPath.section) else {
            return currentIndexPath
        }
        guard let cardCellVM = self.viewModel.uiDataSource[proposedIndexPath.section][proposedIndexPath.item] as? ChatPinCardContainerCellViewModel,
              !cardCellVM.metaModel.pin.isOld else {
            return currentIndexPath
        }
        if let originalIndexPath = self.originalDragIndexPath {
            if originalIndexPath.section != proposedIndexPath.section {
                return currentIndexPath
            }
            resetDragHeightDic(from: originalIndexPath.item, to: proposedIndexPath.item)
        }
        return proposedIndexPath
    }

    func collectionView(_ collectionView: UICollectionView,
                        targetIndexPathForMoveOfItemFromOriginalIndexPath originalIndexPath: IndexPath,
                        atCurrentIndexPath currentIndexPath: IndexPath,
                        toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        if proposedIndexPath.section != originalIndexPath.section {
            return currentIndexPath
        }

        guard let cardCellVM = self.viewModel.uiDataSource[proposedIndexPath.section][proposedIndexPath.item] as? ChatPinCardContainerCellViewModel,
              !cardCellVM.metaModel.pin.isOld else {
            return currentIndexPath
        }

        if currentIndexPath.item != proposedIndexPath.item {
            resetDragHeightDic(from: originalIndexPath.item, to: proposedIndexPath.item)
        }
        return proposedIndexPath
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.collectionView.excutePreload()
    }
}

extension ChatNewPinCardListViewController: PlaceholderChatNavigationBarDelegate {
    func backButtonClicked() {
        self.viewModel.userResolver.navigator.pop(from: self)
    }
}

extension ChatNewPinCardListViewController: PageAPI {
    func insertAt(by chatter: Chatter?) {}
    func reply(message: LarkModel.Message, partialReplyInfo: PartialReplyInfo?) {}
    func reedit(_ message: LarkModel.Message) {}
    func multiEdit(_ message: LarkModel.Message) {}
    var pageSupportReply: Bool { return false }
    var topNoticeSubject: BehaviorSubject<ChatTopNotice?>? { return nil }
    func viewWillEndDisplay() {}
    func viewDidDisplay() {}
    func getSelectionLabelDelegate() -> LKSelectionLabelDelegate? {
        return nil
    }
    func jumpToChatLastMessage(tableScrollPosition: UITableView.ScrollPosition, needDuration: Bool) {}
    func showGuide(key: String) {}
    func getChatThemeScene() -> ChatThemeScene { return  .defaultScene }
}

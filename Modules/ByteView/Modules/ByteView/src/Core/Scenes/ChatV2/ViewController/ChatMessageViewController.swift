//
//  ChatMessageViewController.swift
//  ByteView
//
//  Created by wulv on 2020/12/14.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import RxCocoa
import UniverseDesignTheme
import ByteViewUI
import ByteViewCommon
import UniverseDesignIcon
import UniverseDesignColor
import RichLabel
import ByteViewNetwork
import ByteViewTracker

final class ChatMessageViewController: VMViewController<ChatMessageViewModel>, UITableViewDelegate, UITableViewDataSource {

    // MARK: Propertys
    private(set) var keyboardInfo: [AnyHashable: Any]?
    private(set) var firstPositionBeforeUpLoad: Int?
    var isLoadingMore: Bool = false // 是否正在上拉或下拉加载中，需要根据当前状态决定是否恢复翻译菜单
    var hasScrollToDefaultPosition = false // 仅首次拉取数据回来自动定位到默认位置
    private var lastIndexPath: IndexPath?
    private var isScanningLastMessage = true
    var fromSource = ""

    // === 会中翻译相关 ===
    var isTranslateEnabled: Bool { !viewModel.meeting.isE2EeMeeing }
    var menu: VCMenuViewController?
    // 选中的范围，目前同一时间只可能有一个选中区间
    var selectedRange: NSRange?
    var selectedLabel: LKSelectionLabel?
    var selectedCell: UITableViewCell?
    var translateItem: TranslateMenuItem?
    // 用于解决 iPad 上的手势冲突，具体参考 handleConflictGesture 方法注释
    var panGesture: UIPanGestureRecognizer?

    // MARK: UI
    private lazy var barCloseButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)),
                        for: .normal)
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN3, size: CGSize(width: 24, height: 24)),
                        for: .highlighted)
        button.addInteraction(type: .highlight, shape: .roundedRect(CGSize(width: 44, height: 36), 8.0))
        return button
    }()

    fileprivate let cellIdentifier = "ChatMessageCell"
    private(set) lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: .zero, style: .grouped)
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.register(viewType: ChatMessageHeaderView.self)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    private lazy var topIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.color = UIColor.ud.N300
        view.hidesWhenStopped = false
        return view
    }()
    private lazy var bottomIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.color = UIColor.ud.N300
        view.hidesWhenStopped = false
        return view
    }()

    private var isWebinarRehearsing: Bool = false {
        didSet {
            guard self.isWebinarRehearsing != oldValue else {
                return
            }
            updateWebinarRehearsalLayout()
        }
    }

    private lazy var webinarRehearsalHintView: UIView = {
        let label = UILabel()
        label.text = I18n.View_G_ChatNoSynceRehearsal
        label.font = .systemFont(ofSize: 14.0, weight: .regular)
        label.textAlignment = .center
        label.textColor = UDColor.textPlaceholder
        let wrapperView = UIView()
        wrapperView.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8.0, left: 16.0, bottom: 8.0, right: 16.0))
        }
        wrapperView.backgroundColor = self.view.backgroundColor
        return wrapperView
    }()


    private(set) lazy var editView: ChatMessageEditView = {
        let view = ChatMessageEditView(frame: .zero)
        view.layer.ud.setShadowColor(UIColor.ud.shadowDefaultSm)
        view.layer.shadowOpacity = 0.15
        view.layer.shadowRadius = 20.0
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        return view
    }()

    private lazy var bottomCover: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private lazy var scrollButton: ChatMessageScrollButton = {
        let button = ChatMessageScrollButton(frame: .zero)
        button.layer.cornerRadius = Layout.ScrollHeight * 0.5
        button.layer.borderWidth = 0.5
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var scrollButtonShadowLayer: CALayer = {
        let subLayer = CALayer()
        subLayer.frame = scrollButton.frame
        subLayer.cornerRadius = scrollButton.layer.cornerRadius
        subLayer.ud.setBackgroundColor(UIColor.ud.N00, bindTo: self.view)
        subLayer.ud.setShadowColor(UIColor.ud.N900, bindTo: self.view)
        subLayer.shadowOpacity = 0.1
        subLayer.shadowRadius = 8.0
        subLayer.shadowOffset = CGSize(width: 0, height: 4)
        subLayer.masksToBounds = false
        return subLayer
    }()

    private lazy var tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        return tapGesture
    }()

    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        let longPressGuesture = UILongPressGestureRecognizer()
        return longPressGuesture
    }()

    // MARK: bindViewModel
    override func bindViewModel() {
        layoutTableView()
        layoutIndicatorView()
        layoutBottomView()
        layoutScrollButton()
        bindTranslation()

        self.viewModel.meeting.webinarManager?.addListener(self)
    }

    deinit {
        viewModel.recordUnSendText(editView.getText())
    }

    lazy var setScrollButtonHidden: Debounce<Bool> = {
        debounce(interval: .milliseconds(500)) { [weak self] shouldHide in
            self?.scrollButton.isHidden = shouldHide
            self?.scrollButtonShadowLayer.isHidden = shouldHide
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = .bottom
        viewModel.addListener(self)

        setupNavigation()
        setupTableView()
        setupIndicatorViews()
        setupBottomView()
        setupScrollButton()
        setupTapGuesture()

        viewModel.pullMessages()
        addNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // phone横屏进入chat时会强转竖屏，此时viewDidLoad拿不到正确的safeArea，需要在willAppear再刷新一下
        updateBottomView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.post(.init(name: Self.viewAppearNotification,
                                              object: self,
                                              userInfo: [Self.viewAppearKey: true]))
        MeetingTracksV2.trackChatMessageDisplay(fromSource: fromSource)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
        resetSelection()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        NotificationCenter.default.post(.init(name: Self.viewAppearNotification,
                                              object: self,
                                              userInfo: [Self.viewAppearKey: false]))
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.editView.remakeTextViewLayout()
        if scrollButtonShadowLayer.frame != scrollButton.frame {
            scrollButtonShadowLayer.frame = scrollButton.frame
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if newContext.layoutChangeReason.isOrientationChanged || newContext.layoutChangeReason == .refresh {
            self.editView.remakeTextViewLayout()
            self.updateWebinarRehearsalLayout()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard viewModel.historyEnable else { return nil }
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withType: ChatMessageHeaderView.self) else { return nil }
        let isMeetingOwner = viewModel.meeting.myself.isMeetingOwner
        headerView.labelText = isMeetingOwner
        ? I18n.View_G_ChatHistoryDoc_Placeholder
        : I18n.View_G_RecordedChatToView_Placeholder
        return headerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfMessages
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ChatMessageCell,
              let message = viewModel.message(at: indexPath.row) else {
            return UITableViewCell()
        }
        configCell(messageCell: cell, cellViewModel: message)
        return cell
    }

    private func configCell(messageCell: ChatMessageCell, cellViewModel: ChatMessageCellModel) {
        self.viewModel.updateMessageTranslation(cellViewModel)
        messageCell.config(with: cellViewModel)
        messageCell.labelDragModeUpdateClosure = { [weak self] inDragMode in
            guard let self = self else { return }
            if inDragMode {
                self.menu?.hide(animated: true)
                self.tableView.isScrollEnabled = false
            } else {
                self.menu?.show(animated: true)
                self.tableView.isScrollEnabled = true
            }
        }
        messageCell.labelRangeDidSelectedClosure = { [weak self] range in
            self?.selectedRange = range
            self?.updateTranslateItem(with: range)
        }
        messageCell.tapAvatarClosure = { [weak self] in
            self?.viewModel.openProfileAction.execute(cellViewModel.userId)
        }
        messageCell.tapLinkClosure = { [weak self] url in
            self?.viewModel.openLinkAction.execute(url)
        }
        messageCell.updatePreferredMaxLayoutWidth(with: self.tableView.frame.width)
        messageCell.setNeedsLayout()
    }

    func handleConflictGesture() {
        // 长按选中文本后，尝试拖动改变选中范围时，LKSelectionLabel 有自定义的 HitTest 逻辑和 touches 处理逻辑。
        // 由于手势响应优先级高于触摸事件，改变选中范围的拖动手势会与 tableView 的滑动手势、formSheet vc 的 dismiss 手势冲突，
        // 具体到聊天页的应用场景，会与后者（dismiss 拖动手势）冲突，
        // 因此这里只需要在 label 到 presentedView 中间任意层级添加一个拖动手势，吃掉 dismiss 的拖动手势即可。
        // 注意该手势必须是 cancelsTouchesInView = false，因为要把触摸事件传给 LKSelectionLabel 处理。

        // 更好的做法是该逻辑封装在 LKSelection 内部，但由于主站各应用场景有特殊性，无法统一封装，因此暂时放在业务侧处理
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan.cancelsTouchesInView = false
        view.addGestureRecognizer(pan)
        self.panGesture = pan
    }

    @objc private func handlePan() {
        // 空实现，作用参考 handleConflictGesture 注释
    }

    override func viewLayoutContextDidChanged() {
        super.viewLayoutContextDidChanged()
        if Display.pad {
            self.updateBottomView()
        }
    }
}

// MARK: - Layout
extension ChatMessageViewController {

    private enum Layout {
        static var MarginRight: CGFloat {
            VCScene.safeAreaInsets.right
        }
        static var MarginLeft: CGFloat {
            VCScene.safeAreaInsets.left
        }
        static var EditBottom: CGFloat {
            let isRegular = Display.pad && VCScene.rootTraitCollection?.horizontalSizeClass == .regular
            return isRegular ? 0 : VCScene.safeAreaInsets.bottom
        }
        static let IndicatorSize: CGSize = CGSize(width: 40, height: 40)
        static let ScrollToBottom: CGFloat = 18
        static let ScrollHeight: CGFloat = 36
    }

    private func updateWebinarRehearsalLayout() {
        if self.isWebinarRehearsing {
            self.view.addSubview(webinarRehearsalHintView)
            webinarRehearsalHintView.snp.remakeConstraints { make in
                make.top.equalTo(self.view.safeAreaLayoutGuide)
                make.left.right.equalToSuperview()
            }
            tableView.snp.remakeConstraints { (maker) in
                maker.top.equalTo(webinarRehearsalHintView.snp.bottom)
                maker.left.equalToSuperview().inset(Layout.MarginLeft)
                maker.right.equalToSuperview().inset(Layout.MarginRight)
                maker.bottom.equalToSuperview().priority(.low)
            }
        } else {
            webinarRehearsalHintView.removeFromSuperview()
            tableView.snp.remakeConstraints { (maker) in
                maker.top.equalToSuperview()
                maker.left.equalToSuperview().inset(Layout.MarginLeft)
                maker.right.equalToSuperview().inset(Layout.MarginRight)
                maker.bottom.equalToSuperview().priority(.low)
            }
        }
    }

    private func layoutTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.left.equalToSuperview().inset(Layout.MarginLeft)
            maker.right.equalToSuperview().inset(Layout.MarginRight)
            maker.bottom.equalToSuperview().priority(.low)
        }
    }

    private func layoutIndicatorView() {
        view.addSubview(bottomIndicatorView)
        bottomIndicatorView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(tableView.snp.bottom)
            maker.size.equalTo(Layout.IndicatorSize)
        }

        view.addSubview(topIndicatorView)
        topIndicatorView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(tableView.snp.top)
            maker.size.equalTo(Layout.IndicatorSize)
        }
    }

    private func layoutBottomView() {
        editView.setText(viewModel.context.chatRecordText)
        view.addSubview(editView)
        editView.snp.makeConstraints { (maker) in
            maker.top.equalTo(tableView.snp.bottom).priority(.high)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(editView.getEditViewHeight())
            maker.bottom.equalToSuperview().inset(Layout.EditBottom)
        }

        view.addSubview(bottomCover)
        bottomCover.snp.makeConstraints { (maker) in
            maker.top.equalTo(editView.snp.bottom)
            maker.left.right.bottom.equalToSuperview()
        }
    }

    private func updateBottomView() {
        editView.snp.updateConstraints { (maker) in
            maker.bottom.equalToSuperview().inset(Layout.EditBottom)
        }
    }

    private func layoutScrollButton() {
        view.addSubview(scrollButton)
        scrollButton.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(editView.snp.top).offset(-Layout.ScrollToBottom)
            maker.height.equalTo(Layout.ScrollHeight)
        }
        scrollButton.layoutIfNeeded()
        view.layer.insertSublayer(scrollButtonShadowLayer, below: scrollButton.layer)
        scrollButtonShadowLayer.isHidden = true
        scrollButton.isHidden = true
    }
}

// MARK: - Navigation
extension ChatMessageViewController {

    static let viewAppearNotification = Notification.Name(rawValue: "ByteView.ChatMessage.ChatMessagesViewAppear")
    static let viewAppearKey = "appear"

    private func setupNavigation() {
        setNavigationItemTitle(text: I18n.View_M_ChatButton, color: .ud.textTitle)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: barCloseButton)
        barCloseButton.rx.action = viewModel.closeAction
    }
}

// MARK: - TableView
extension ChatMessageViewController {

    private func setupTableView() {
        tableView.rx.contentOffset
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] contentOffset in
                guard let self = self else { return }
                if contentOffset.y <= 0 {
                    // 下拉
                    let topOffset = max(contentOffset.y, -Layout.IndicatorSize.height)
                    self.topIndicatorView.transform = CGAffineTransform(translationX: 0, y: -topOffset)
                }
                let transformOffsetY = self.transformOffsetY
                if transformOffsetY > 0 {
                    // 上拉
                    let bottomOffset = min(transformOffsetY, Layout.IndicatorSize.height)
                    self.bottomIndicatorView.transform = CGAffineTransform(translationX: 0, y: -bottomOffset)
                }
            })
            .disposed(by: rx.disposeBag)

        tableView.rx.willBeginDragging
            .observeOn(MainScheduler.asyncInstance)
            .subscribe({ [weak self] _ -> Void in
                self?.menu?.hide(animated: true)
            })
            .disposed(by: rx.disposeBag)

        tableView.rx.didScroll.subscribe(onNext: { [weak self] in
            self?.handleTableViewScroll()
        }).disposed(by: rx.disposeBag)

        // 停止滚动时，处理menu状态
        Observable.merge(tableView.rx.didEndDecelerating.asObservable(), tableView.rx.didEndDragging.filter { !$0 }.map { _ in })
            .observeOn(MainScheduler.asyncInstance)
            .subscribe({ [weak self] _ -> Void in
                guard let self = self, !self.isLoadingMore else { return }
                self.updateMenuStateWhenEndScroll()
            })
            .disposed(by: rx.disposeBag)

        tableView.rx.didEndDragging
            .observeOn(MainScheduler.asyncInstance)
            .compactMap { [weak self] _ -> ChatMessageViewModel.LoadDirection? in
                guard let self = self else { return nil }
                let contentOffset = self.tableView.contentOffset
                if contentOffset.y < 0 {
                    // 下拉
                    let needLoad = contentOffset.y <= -Layout.IndicatorSize.height
                    if !needLoad {
                        return nil
                    }
                    self.isLoadingMore = true
                    return .up
                }
                let transformOffsetY = self.transformOffsetY
                if transformOffsetY > 0 {
                    // 上拉
                    let needLoad = transformOffsetY >= Layout.IndicatorSize.height
                    if !needLoad {
                        return nil
                    }
                    self.isLoadingMore = true
                    return .down
                }
                return nil
            }
            .bind(to: viewModel.triggerLoadMoreObserver)
            .disposed(by: rx.disposeBag)

        tableView.rx.willDisplayCell
            .map { $0.1 }
            .bind(to: viewModel.willDisplayCellObserver)
            .disposed(by: rx.disposeBag)
    }

    private var transformOffsetY: CGFloat {
        let maxOffset = max(tableView.contentSize.height - tableView.frame.height, 0)
        let errorOffset: CGFloat = 0.5
        let transformOffsetY = tableView.contentOffset.y - floor(maxOffset) + errorOffset // 误差0.5
        return transformOffsetY
    }

    private func handleTableViewScroll() {
        // 首次进入页面跳到默认位置前不要记录 indexPath 信息，防止把跳转前的位置保存，覆盖了原本应该跳到的位置
        guard hasScrollToDefaultPosition else { return }
        let indexPath = lastVisibleIndexPath
        if indexPath != lastIndexPath {
            lastIndexPath = indexPath

            if let indexPath = lastIndexPath {
                viewModel.updateReadMessage(for: indexPath)
            }
            updateScrollButton()
        }
    }

    private func autoScrollTableView() {
        if let scrollPosition = viewModel.autoScrollPosition, !hasScrollToDefaultPosition {
            viewModel.defaultAutoScrollPosition = nil
            scrollToPosition(position: scrollPosition)
        } else if let message = viewModel.unreadMessage, shouldAutoScrollToBottom {
            scrollToPosition(position: message.position, animated: true)
            updateTransformWithKeyboard()
        } else if let position = firstPositionBeforeUpLoad {
            scrollToPosition(position: position, at: .top)
            firstPositionBeforeUpLoad = nil
        }
    }

    private func scrollToBottom() {
        guard let lastPosition = viewModel.positionForLastMessage else { return }
        scrollToPosition(position: lastPosition)
    }

    private func scrollToPosition(position: Int,
                                  at scrollPosition: UITableView.ScrollPosition = .bottom,
                                  animated: Bool = false) {
        if let index = self.viewModel.messageIndex(for: position) {
            self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: scrollPosition, animated: animated)
        } else {
            // 找不到时滑至最底
            self.tableView.vc.scrollToBottom(animated: animated)
        }
    }

    private func updateScrollButton() {
        // 三种情况下 scrollButton 的显示隐藏可能变化：1. 用户滑动时；2. 冻结态收到新消息时；3. 收到翻译结果时
        let shouldHide = viewModel.isScanningLastMessage(currentIndexPath: lastIndexPath)
        // debounce on shouldHide
        if isScanningLastMessage != shouldHide {
            isScanningLastMessage = shouldHide
            setScrollButtonHidden(shouldHide)
        }
    }

    private var shouldAutoScrollToBottom: Bool {
        viewModel.shouldAutoScrollToBottom(scanningIndexPath: lastIndexPath)
    }

    var lastVisibleIndexPath: IndexPath? {
        // !!! 不能用 tableView.indexPathsForVisibleRows?.last，在特定情况下不准
        // https://stackoverflow.com/questions/4099188/uitableviews-indexpathsforvisiblerows-incorrect
        guard let cell = tableView.visibleCells.last else { return nil }
        return tableView.indexPath(for: cell)
    }
}

// MARK: - IndicatorView
extension ChatMessageViewController {

    private func setupIndicatorViews() {
        viewModel.frontLoadingDriver
            .asObservable()
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] isLoading in
                guard let self = self else { return }
                let duration = 0.5
                if isLoading {
                    self.tableView.bounces = false
                    self.topIndicatorView.startAnimating()
                    UIView.animate(withDuration: duration) {
                        self.tableView.contentInset.top = Layout.IndicatorSize.height
                    }
                } else {
                    // 极端情况下，isLoading为true后立刻为false，加延时保证上面动画执行完再往下执行
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        self.tableView.bounces = true
                        self.topIndicatorView.stopAnimating()
                        UIView.animate(withDuration: duration) {
                            self.tableView.contentInset.top = 0
                            self.topIndicatorView.transform = .identity
                            self.recoveryMenu()
                        }
                    }
                }
            })
            .disposed(by: rx.disposeBag)

        viewModel.frontLoadingRelay
            .asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] load in
                guard let self = self else { return }
                if load {
                    // 记录当前浏览位置
                    guard let firstCell = self.tableView.visibleCells.first,
                          let indexPath = self.tableView.indexPath(for: firstCell),
                          let message = self.viewModel.message(at: indexPath.row) else { return }
                    self.firstPositionBeforeUpLoad = message.position
                }
            })
            .disposed(by: rx.disposeBag)

        viewModel.backLoadingDriver
            .asObservable()
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] isLoading in
                guard let self = self else { return }
                let duration = 0.5
                if isLoading {
                    self.tableView.bounces = false
                    self.bottomIndicatorView.startAnimating()

                    let bottomH: CGFloat
                    if self.tableView.contentSize.height <= self.tableView.frame.size.height {
                        bottomH = self.tableView.frame.size.height - self.tableView.contentSize.height + Layout.IndicatorSize.height
                    } else {
                        bottomH = Layout.IndicatorSize.height
                    }
                    UIView.animate(withDuration: duration) {
                        self.tableView.contentInset.bottom = bottomH
                    }
                } else {
                    // 极端情况下，isLoading为true后立刻为false，加延时保证上面动画执行完再往下执行
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        self.tableView.bounces = true
                        self.bottomIndicatorView.stopAnimating()
                        UIView.animate(withDuration: duration) {
                            self.tableView.contentInset.bottom = 0
                            self.bottomIndicatorView.transform = .identity
                            self.recoveryMenu()
                        }
                    }
                }
            })
            .disposed(by: rx.disposeBag)
    }
}

// MARK: - BottomView
extension ChatMessageViewController {

    private func setupBottomView() {
        let allowSendMessage = viewModel.allowSendMessage
        let banText = viewModel.meeting.subType == .webinar ? I18n.View_G_MessageBanned : I18n.View_G_BanAllFromMessage
        self.updatePlaceholder(text: allowSendMessage ? viewModel.topic : banText, allowSendMessage: allowSendMessage)
        viewModel.updatePlaceholderClosure = { [weak self] (text, allowSendMessage) in
            Util.runInMainThread {
                self?.updatePlaceholder(text: text, allowSendMessage: allowSendMessage)
            }
        }

        editView.sendClosure = { [weak self] text in
            if let text = text {
                VCTracker.post(name: .vc_meeting_chat_send_message_click,
                               params: [.click: "send_message",
                                        "location": "send_message_view"])
                self?.viewModel.sendMessage(content: text)
                self?.editView.clearText()
                self?.scrollToBottom()
            }
        }

        editView.beforeEdit = { [weak self] in
            self?.scrollToBottom()
        }
    }

    private func updatePlaceholder(text: String, allowSendMessage: Bool) {
        if !allowSendMessage {
            self.editView.endEditing()
            self.editView.clearText()
        }
        self.editView.placeHolderLabel.attributedText = NSAttributedString(string: text, config: .body)
        self.editView.placeHolderLabel.textColor = allowSendMessage ? .ud.textPlaceholder : .ud.textDisabled
        self.editView.allowInput = allowSendMessage
    }
}

// MARK: - ScrollButton
extension ChatMessageViewController {

    private func setupScrollButton() {

        scrollButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.pullLatestPage { [weak self] messages in
                    guard let self = self, !messages.isEmpty else { return }
                    DispatchQueue.main.async {
                        self.scrollToBottom()
                    }
                }
            })
            .disposed(by: rx.disposeBag)

        viewModel.unreadCountObservable
            // 防抖
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { [weak self] unreadCount in
                guard let self = self else { return }
                if unreadCount > 0 {
                    self.refreshScrollButtonShadowLayer(type: .messageTip(count: unreadCount))
                    self.scrollButton.layer.ud.setBorderColor(UIColor.clear)
                    self.scrollButton.style = .messageTip(count: unreadCount)
                } else {
                    self.refreshScrollButtonShadowLayer(type: .normal)
                    self.scrollButton.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
                    self.scrollButton.style = .normal
                }
            })
            .disposed(by: rx.disposeBag)
    }

    private func refreshScrollButtonShadowLayer(type: ChatMessageScrollButton.Style) {
        if #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
            switch type {
            case .normal:
                self.scrollButtonShadowLayer.ud.setShadowColor(UIColor.ud.shadowDefaultMd, bindTo: self.view)
            default:
                self.scrollButtonShadowLayer.ud.setShadowColor(UIColor.ud.shadowPriMd, bindTo: self.view)
            }
        } else {
            self.scrollButtonShadowLayer.ud.setShadowColor(UIColor.ud.N900, bindTo: self.view)
        }
    }
}

// MARK: - Gesture
extension ChatMessageViewController {

    private func setupTapGuesture() {
        view.addGestureRecognizer(tapGesture)
        tapGesture.isEnabled = false
        tapGesture.rx.event
            .observeOn(MainScheduler.instance)
            .bind { [weak self] _ in
                self?.view.endEditing(true)
            }
            .disposed(by: rx.disposeBag)

        if isTranslateEnabled {
            tableView.addGestureRecognizer(longPressGesture)
            longPressGesture.rx.event
                .observeOn(MainScheduler.instance)
                .bind { [weak self] gesture in
                    guard let self = self, !self.isShowingMenu(), gesture.state == .began else { return }
                    // 获取tableview中的触摸位置
                    let location = gesture.location(in: gesture.view)
                    self.showMenu(location: location)
                }
                .disposed(by: rx.disposeBag)
        }

        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .map { _ in Void() }
            .subscribe(onNext: { [weak self] in
                self?.tapGesture.isEnabled = true
            })
            .disposed(by: rx.disposeBag)

        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillHideNotification)
            .map { _ in Void() }
            .subscribe(onNext: { [weak self] in
                self?.tapGesture.isEnabled = false
            })
            .disposed(by: rx.disposeBag)
    }
}

// MARK: - Notification
extension ChatMessageViewController {

    private func addNotifications() {

        NotificationCenter.default.rx
            .notification(UIApplication.willResignActiveNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if Display.pad {
                    // 失去焦点前主动收起键盘，防止ipad前后台切换、拖动分屏比例时出现的各种键盘相关异常
                    self?.view.endEditing(true)
                }
            })
            .disposed(by: rx.disposeBag)

        let keyboardWillShowOb = NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .map { [weak self] notification -> Void in
                ChatMessageViewModel.logger.info("keyboard - keyboardWillShowNotification, notification = \(notification)")
                self?.keyboardInfo = notification.userInfo
                return Void()
            }

        let keyboardWillHideOb = NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillHideNotification)
            .map { [weak self] _ -> Void in
                ChatMessageViewModel.logger.info("keyboard - keyboardWillHideNotification")
                self?.keyboardInfo = nil
                return Void()
            }
            .startWith( Void() )

        let keyboardDidHideOb = NotificationCenter.default.rx
            .notification(UIResponder.keyboardDidHideNotification)
            .map { [weak self] _ -> Void in
                ChatMessageViewModel.logger.info("keyboard - keyboardDidHideNotification")
                self?.keyboardInfo = nil
                return Void()
            }
            .startWith( Void() )

        Observable.combineLatest(keyboardWillShowOb, keyboardWillHideOb, keyboardDidHideOb)
            /*
             iPad modalPresentationStyle = formSheet，横屏下。
             self.view会往上移动，但是要等动画设置完成才知道移动的目标位置，所以增加了Dispatch，获取移动的目标位置。
             */
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, self.menu == nil else { return }
                self.updateTransformWithKeyboard()
            })
            .disposed(by: rx.disposeBag)
    }
}

extension ChatMessageViewController: ChatMessageViewModelDelegate {
    func messagesDidChange(messages: [ChatMessageCellModel]) {
        // Main Thread
        if viewModel.isFrozen {
            // 冻结态下新消息来时不更新列表，但是未读消息提示要更新
            updateScrollButton()
        } else {
            tableView.reloadData()
            autoScrollTableView()
            hasScrollToDefaultPosition = true
            // 更新当前已读消息，当前屏幕最后一行下标，以及滚动按钮状态
            // 对于非冻结态，当 tableView 不满一屏时添加消息，或首次进入页面首次加载数据时，scrollViewDidScroll 都不会调用，因此在数据更新后手动调用一次该方法。
            // 多余的调用由于类似 distinctUntilChange 的逻辑，不会有影响
            handleTableViewScroll()
        }
    }

    func translationInfoDidChange() {
        // Main Thread
        if !viewModel.isFrozen {
            tableView.reloadData()
        }
    }

    func translationResultDidChange(sources: [String: TranslateSource]) {
        // Main Thread
        if !viewModel.isFrozen {
            tableView.reloadData()
            scrollToBottomAfterTranslation(sources: sources)
            // 自动翻译打开时，用户点击回到底部按钮，触发自动翻译，翻译完用户可能就不在底部了，
            // 此时没法再帮用户滚动到底部，会有很多 edge case，因此采用翻译完如果用户不在底部就显示出回到底部按钮的策略
            handleTableViewScroll()
        }
    }
}

extension ChatMessageViewController: WebinarRoleListener {
    func webinarDidChangeRehearsal(isRehearsing: Bool, oldValue: Bool?) {
        DispatchQueue.main.async {
            self.isWebinarRehearsing = isRehearsing
        }
    }
}

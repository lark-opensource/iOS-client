//
//  SubtitleHistoryView.swift
//  ByteView
//
//  Created by yangyao on 2021/1/11.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxSwift
import Action
import SnapKit
import ByteViewUI
import ByteViewTracker
import UniverseDesignIcon

extension SubtitleHistoryView: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        numberOfRows = viewModel.viewDatas.count
        return numberOfRows
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let vm = viewModel.subtitleViewDataForRow(at: indexPath) else { return 0 }
        let offset: CGFloat = vm.needMerge ? 12 : 38
        if vm.isShowAll, let h = cellHeightCache[vm.segId] {
            return h + offset
        }
        let h = SubtitleHistoryCell.getCellHeight(with: vm, width: tableView.bounds.width)
        cellHeightCache[vm.segId] = h
        return h + offset
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel.subtitleViewDataForRow(at: indexPath), let identifier = vm.identifier, let cell =
            tableView.dequeueReusableCell(withIdentifier: identifier) as? SubtitleHistoryBaseCell else {
                return UITableViewCell()
        }
        if let c = cell as? SubtitleHistoryCell {
            c.isAlignRight = viewModel.isSubtitleAlignRight
        }
        cell.containerWidth = tableView.bounds.width
        cell.service = viewModel.service
        cell.cellHeight = cellHeightCache[vm.segId] ?? 0
         _ = cell.updateViewModel(vm: vm)

        if let c = cell as? SubtitleHistoryCell {
            if let currentSelectedId = self.viewModel.currentSelectedId, vm.segId == currentSelectedId {
                c.selectedRange = self.viewModel.currentSelectedRange
            } else {
                c.selectedRange = nil
            }
        }

        if let c = cell as? SubtitleHistoryDocCell {
            if let currentSelectedId = self.viewModel.currentSelectedId, vm.segId == currentSelectedId {
                c.selectedRange = self.viewModel.currentSelectedRange
            } else {
                c.selectedRange = nil
            }
            c.gotoDocs = { [weak self] url in
                guard let `self` = self else { return }
                VCTracker.post(name: .vc_meeting_subtitle_page, params: [.action_name: "docs_link"])
                self.openDocBlock?(url)
            }
        }
        return cell
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset.y
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleScrollToBottomButtonHidden()
        if self.lastContentOffset > scrollView.contentOffset.y {
            for (index, cell) in tableView.visibleCells.enumerated() where index == 0 {
                if let indexPath = tableView.indexPath(for: cell) {
                    let currentIndex = indexPath.row
                    SubtitleTracksV2.trackClickScrollProgress(current: currentIndex, total: tableView.numberOfRows(inSection: 0))
                }
            }
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            handleScrollToBottomButtonHidden()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.viewModel.isSearchMode {
            self.viewModel.bottomButtonShowSubject.onNext(())
        }

        oldContentOffset = self.tableView.contentOffset.y
    }
}

extension SubtitleHistoryView: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    func setupLongPress() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        longPressGesture.minimumPressDuration = 1.0 // 1 second press
        longPressGesture.delegate = self
        longPressGesture.cancelsTouchesInView = false
        self.tableView.addGestureRecognizer(longPressGesture)
    }

    func setupTapPress() {
        let singlePressGesture = UITapGestureRecognizer(target: self, action: #selector(tapPress))
        singlePressGesture.delegate = self
        singlePressGesture.cancelsTouchesInView = false
        self.tableView.addGestureRecognizer(singlePressGesture)
    }

    @objc
    func tapPress(gesture: UIGestureRecognizer) {

        if gesture.state == .ended {
            let touchPoint = gesture.location(in: self.tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                // do your task on single tap
                self.hideKeyBoard()
                if let cell = tableView.cellForRow(at: indexPath) as? SubtitleHistoryBaseCell {
                    cell.hideMenu()
                }
            }
        }
    }

    @objc
    func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {

        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {

            let touchPoint = longPressGestureRecognizer.location(in: self.tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                if let cell = tableView.cellForRow(at: indexPath) as? SubtitleHistoryBaseCell, cell.shouldShowMenu {
                    cell.showMenu()
                }
            }
        }
    }
}

class SubtitleHistoryView: UIView {
    var viewModel: SubtitlesViewModel!

    private var disposeBag = DisposeBag()
    var tableView = BaseTableView()

    private var oldContentOffset: CGFloat = 0

    private lazy var searchView: SubtitleSearchView = {
        let searchView = SubtitleSearchView()
        searchView.filterBlock = { [weak self] viewController in
            self?.filterBlock?(viewController)
        }
        searchView.clearBlock = { [weak self] in
            self?.tableView.reloadData()
        }
        return searchView
    }()
    private var searchBottomView = SubtitleSearchBottomView()
    private var searchBottomExtView = UIView()
    private var viewForGuide = UIView()
    var filterBlock: ((SubtitlesFilterViewController) -> Void)?
    var openDocBlock: ((String) -> Void)?
    private var lastContentOffset: CGFloat = 0

    private var scrollToBottomButtonContainer: UIView = {
        let view = UIView()
        view.layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.layer.shadowRadius = 10
        view.layer.shadowOpacity = 1
        view.isHidden = true
        return view
    }()
    private lazy var scrollToBottomButton: SubtitleHistoryFloatBackView = {
        let button = SubtitleHistoryFloatBackView()
        button.addTarget(self, action: #selector(didClickScrollToBottomButton(_:)), for: .touchUpInside)
        return button
    }()
    private lazy var asrStatusView = ASRStatusView()
    private lazy var loadingView: SubtitleHistoryLoadingView = {
        let loadingView = SubtitleHistoryLoadingView()
        loadingView.isHidden = false
        loadingView.play()
        return loadingView
    }()

    private var isScrollAfterMenuHidden = false
    private var tableViewBottomConstraint: Constraint?
    private var receiveNewSubtitle: Bool = false {
        didSet {
            self.updateScrollToBottomButton()
            if receiveNewSubtitle {
                self.scrollToBottomButton.changeButtonStyleToText()
            } else {
                self.scrollToBottomButton.changeButtonStyleToIcon()
            }
        }
    }

    private lazy var visualEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.isHidden = !padRegularStyle
        return effectView
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textCaption
        label.text = I18n.View_G_NoOneSpeaking_Text
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private var numberOfRows: Int = 0
    private var scrollsToBottomAutomatically = false
    private var isPush = false

    init(viewModel: SubtitlesViewModel) {
        super.init(frame: .zero)
        self.viewModel = viewModel
        setupView()
        doLayout()
        bindViewModel()
        setupLongPress()
        setupTapPress()
        self.viewModel.smoothSubtitleBlock = { [weak self] in
            self?.showSubtitleSmooth()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var padRegularStyle: Bool {
        return traitCollection.userInterfaceIdiom == .pad && VCScene.rootTraitCollection?.horizontalSizeClass == .regular
    }

    func setupView() {
        backgroundColor = padRegularStyle ? UIColor.ud.N00.withAlphaComponent(0.8) : UIColor.ud.bgBody

        setShadow()

        addSubview(visualEffectView)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.indicatorStyle = .black
        tableView.canCancelContentTouches = false
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        let footerView = UIView()
        footerView.frame = CGRect(x: 0, y: 0, width: 1, height: 16 + safeAreaInsets.bottom)
        footerView.backgroundColor = .clear
        tableView.tableFooterView = footerView
        tableView.register(SubtitleHistoryCell.self, forCellReuseIdentifier: SubtitleHistoryCell.description())
        tableView.register(SubtitleHistoryDocCell.self, forCellReuseIdentifier: SubtitleHistoryDocCell.description())
        tableView.register(SubtitleHistoryBehaviorCell.self, forCellReuseIdentifier: SubtitleHistoryBehaviorCell.description())
        tableView.delegate = self
        tableView.dataSource = self

        pullOldData()

        addSubview(searchView)
        addSubview(tableView)
        addSubview(searchBottomView)
        addSubview(searchBottomExtView)
        scrollToBottomButtonContainer.addSubview(scrollToBottomButton)
        addSubview(scrollToBottomButtonContainer)
        addSubview(loadingView)
        addSubview(statusLabel)
        searchView.viewModel = viewModel

        searchBottomView.viewModel = viewModel

        searchBottomExtView.backgroundColor = searchBottomView.backgroundColor
        if let shadowColor = searchBottomExtView.layer.vc.shadowColor {
            searchBottomExtView.ud.setLayerShadowColor(shadowColor)
        }
        searchBottomExtView.layer.shadowOffset = searchView.layer.shadowOffset
        searchBottomExtView.layer.shadowRadius = searchView.layer.shadowRadius
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        backgroundColor = padRegularStyle ? UIColor.ud.N00.withAlphaComponent(0.8) : UIColor.ud.bgBody
        visualEffectView.isHidden = !padRegularStyle
        setShadow()
        doLayout()
    }

    func setShadow() {
        layer.ud.setShadowColor(padRegularStyle ? UIColor.ud.rgb(0x1F2329).withAlphaComponent(0.06) : UIColor.clear)
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 2
        layer.shadowOpacity = 1.0
    }

    func doLayout() {
        visualEffectView.snp.remakeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        searchView.snp.remakeConstraints { (maker) in
            maker.height.equalTo(52.0)
            maker.left.right.equalTo(safeAreaLayoutGuide)
            maker.top.equalToSuperview()
        }

        searchBottomView.snp.remakeConstraints { (maker) in
            maker.height.equalTo(40)
            maker.left.right.equalTo(safeAreaLayoutGuide)
            maker.bottom.lessThanOrEqualTo(vc.keyboardLayoutGuide.snp.top)
            maker.bottom.lessThanOrEqualTo(searchBottomExtView.snp.top)
        }
        searchBottomExtView.snp.remakeConstraints { (maker) in
            maker.left.right.equalTo(safeAreaLayoutGuide)
            maker.top.equalTo(safeAreaLayoutGuide.snp.bottom)
            maker.bottom.equalToSuperview()
        }
        setTableViewConstraint(viewModel.isSearchMode)

        loadingView.snp.remakeConstraints {
            $0.center.equalToSuperview()
        }

        statusLabel.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        scrollToBottomButton.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        if padRegularStyle {
            scrollToBottomButtonContainer.snp.remakeConstraints { (maker) in
                maker.height.equalTo(40.0)
                maker.centerX.equalToSuperview()
                maker.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-16.0)
            }
        } else {
            scrollToBottomButtonContainer.snp.remakeConstraints { (maker) in
                maker.height.equalTo(receiveNewSubtitle ? 38 : 48)
                maker.right.equalTo(safeAreaLayoutGuide.snp.right).offset(-16.0)
                maker.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-48.0).priority(.low)
                maker.bottom.lessThanOrEqualTo(vc.keyboardLayoutGuide.snp.top).offset(-16.0)
            }
        }

        layoutIfNeeded()

        scrollToBottomButton.addInteraction(type: .highlight)
    }

    private func showSubtitleSmooth() {
        let reloadRows = viewModel.reloadRows
        var indexPaths: [IndexPath] = []
        if viewModel.reloadAllNum > 0 {
            tableView.reloadData()
            scrollToBottom()
            viewModel.updateReloadAllNum()
        } else {
            let lastVisibleRow = tableView.indexPathsForVisibleRows?.last?.row ?? Int.max
            reloadRows.forEach { index in
                if index >= viewModel.viewDatas.count {
                    viewModel.updateReloadRows(with: index)
                    return
                }
                let data = viewModel.viewDatas[index]
                if data.isShowAll, data.isShowAnnotation {
                    viewModel.updateReloadRows(with: index)
                    return
                }
                if index > lastVisibleRow {
                    data.updateWordEnd()
                } else {
                    indexPaths.append(IndexPath(row: index, section: 0))
                }
            }
            if numberOfRows == viewModel.viewDatas.count {
                if !indexPaths.isEmpty {
                    UIView.performWithoutAnimation {
                        self.tableView.reloadRows(at: indexPaths, with: .none)
                    }
                    scrollToBottom()
                }
            } else {
                tableView.reloadData()
                scrollToBottom()
            }
        }
    }

    private func scrollToBottom() {
        if scrollsToBottomAutomatically, !viewModel.isSearchMode {
            // false 为push，自动滑动到底部
            self.scrollToEnd(animated: isPush)
        }
    }

    private func updateScrollToBottomButton() {
        scrollToBottomButtonContainer.snp.remakeConstraints { (maker) in
            maker.height.equalTo(receiveNewSubtitle ? 38 : 48)
            maker.right.equalTo(safeAreaLayoutGuide.snp.right).offset(-16.0)
            maker.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-48.0).priority(.low)
            maker.bottom.lessThanOrEqualTo(vc.keyboardLayoutGuide.snp.top).offset(-16.0)
        }
    }

    func viewWillTransition() {
        cellHeightCache = [:]
        tableView.reloadData()
        scrollToBottom()
    }

    @objc func didClickScrollToBottomButton(_ sender: UIView) {
        SubtitleTracks.trackScrollToBottom()
        SubtitleTracksV2.trackClickBackToBottom()
        self.scrollToBottomButtonContainer.isHidden = true
        self.receiveNewSubtitle = false
        self.scrollToBottomButton.changeButtonStyleToIcon()
        self.viewModel.clickBottomButtonAction { [weak self] in
            guard let self = self else { return }
            if self.viewModel.isMenuShow {
                self.isScrollAfterMenuHidden = true
            } else {
                self.scrollToEnd()
            }
        }
    }

    func bindViewModel() {
        var offsetToBottom: CGFloat = 0.0 // 用于插入数据后保持当前可视内容不变
        scrollsToBottomAutomatically = false // 用于新增数据自动滑到底部

        // 监听字幕语言变化
        viewModel.changeSubtitleLanguageObservable.subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.pullOldData()
            }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)

        // 监听选中数据的变化
        viewModel.jumpObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self](row) in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                if self.isHandleScroll(index: row) {
                    self.tableView.reloadData()
                    self.tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .middle, animated: true)
                }
            }
            }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)

        // 监听推送数据
        viewModel.bottomButtonShowObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.scrollToBottomButtonContainer.isHidden = self.getScrollToBottomHiddden()
            }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)

        // 监听数据

        viewModel.subtitleViewDatasObservable.do(onNext: { [weak self] (_, tableViewScrollType) in
            guard let `self` = self else { return }
            if !self.getScrollToBottomHiddden() {
                self.receiveNewSubtitle = true
            }
            switch tableViewScrollType {
            case .forcesKeepingPosition:
                offsetToBottom = self.tableView.contentSize.height - self.tableView.contentOffset.y
            case .normal:
                break
            case .autoScrollToBottom(let isPush):
                if !self.viewModel.isLoading && !self.tableView.isTracking && !self.tableView.isDecelerating {
                    if isPush {
                        // 如果是push，则需要判断先前是否处于最低部
                        self.scrollsToBottomAutomatically = self.scrollToBottomButtonContainer.isHidden
                    } else {
                        self.scrollsToBottomAutomatically = true
                    }
                } else {
                    self.scrollsToBottomAutomatically = false
                }
            } })
            .subscribe(onNext: { [weak self] (_, tableViewScrollType) in
                guard let `self` = self else { return }
                switch tableViewScrollType {
                case .forcesKeepingPosition:
                    // 获取更早的数据
                    self.tableView.reloadData()
                    if self.viewModel.isSearchMode, self.viewModel.needJump,
                       let index = self.viewModel.getCurrentSelectIndex() {
                        // 通过快速跳转获取更早的数据
                        self.viewModel.jumpSelectedAtRow(index: index)
                    } else {
                        // 通过主动下划获取更早的数据
                        self.tableView.layoutIfNeeded()
                        var contentOffset = self.tableView.contentOffset
                        contentOffset.y = min(self.tableView.vc.bottomEdgeContentOffset,
                                              self.tableView.contentSize.height - offsetToBottom)
                        if contentOffset.y > 0 {
                            self.tableView.contentOffset = contentOffset
                        }
                    }
                case .normal:
                    // 获取较新的数据
                    if self.viewModel.isSearchMode, self.viewModel.needJump,
                        let index = self.viewModel.getCurrentSelectIndex(), self.isHandleScroll(index: index) {
                        // 通过快速跳转获取较新的数据
                        self.tableView.reloadData()
                        self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
                    } else {
                        if !self.viewModel.isSearchMode {
                            self.scrollToBottomButtonContainer.isHidden = self.getScrollToBottomHiddden()
                        }
                    }
                case .autoScrollToBottom(let isPush):
                    self.isPush = isPush
                }
        }).disposed(by: disposeBag)

        viewModel.subtitleViewDatasObservable
            .map { !$0.0.isEmpty }
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] hasData in
                if hasData {
                    self?.loadingView.isHidden = true
                    self?.loadingView.stop()
                    self?.statusLabel.isHidden = true
                } else {
                    let isHidden = !(self?.statusLabel.isHidden ?? true)
                    self?.loadingView.isHidden = isHidden
                    self?.loadingView.play()
                }
            })
            .disposed(by: disposeBag)

        // 监听清除数据，然后清除cell height cache
        viewModel.clearDataObservable.subscribe(onNext: { [weak self](_) in
            guard let `self` = self else { return }
            self.cellHeightCache = [:]
            }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)

        // menu 消失且有新数据时刷新UI，并跳到底部
        viewModel.reloadDataWhehMenuHidden = {[weak self] in
            self?.tableView.reloadData()
            if let `self` = self, self.scrollToBottomButtonContainer.isHidden || self.isScrollAfterMenuHidden {
                self.isScrollAfterMenuHidden = false
                self.scrollToEnd()
            }
        }

        // 加载控件相关
        viewModel.needsPullOldRefreshControlDriver.drive(onNext: { [weak self] in
            guard let `self` = self else { return }

            if $0 {
                self.tableView.loadMoreDelegate?.addTopLoading(handler: { [weak self] in self?.triggerOldRefreshing() })
                // 由于PullDownBackgroundView无法直接设置颜色，因此采用Hook的方法
                if let subviews = self.tableView.loadMoreDelegate?.topLoadingView?.subviews,
                    let indicator = subviews.compactMap({ $0 as? UIActivityIndicatorView }).first {
                    indicator.color = UIColor.clear
                    let loadingView = LoadingView(style: .blue)
                    indicator.addSubview(loadingView)
                    loadingView.snp.makeConstraints {
                        $0.edges.equalToSuperview()
                    }
                    loadingView.play()
                }
            } else {
                self.tableView.loadMoreDelegate?.removeTopLoading()
            }
        }).disposed(by: disposeBag)

        viewModel.isPullOldLoadingDriver.asObservable().filter({ !$0 }).subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.tableView.loadMoreDelegate?.endTopLoading(hasMore: true)
        }).disposed(by: disposeBag)

        viewModel.needsPullNewRefreshControlDriver.drive(onNext: { [weak self] in
            guard let `self` = self else { return }

            if $0 {
                self.tableView.loadMoreDelegate?.addBottomLoading { [weak self] in
                    self?.triggerNewRefreshing()
                }
                // 由于PullDownBackgroundView无法直接设置颜色，因此采用Hook的方法
                if let subviews = self.tableView.loadMoreDelegate?.bottomLoadingView?.subviews,
                    let indicator = subviews.compactMap({ $0 as? UIActivityIndicatorView }).first {
                    indicator.color = UIColor.clear
                    let loadingView = LoadingView(style: .blue)
                    indicator.addSubview(loadingView)
                    loadingView.snp.makeConstraints {
                        $0.edges.equalToSuperview()
                    }
                    loadingView.play()
                }
            } else {
                self.tableView.loadMoreDelegate?.removeBottomLoading()
            }
        }).disposed(by: disposeBag)

        viewModel.isPullNewLoadingDriver.asObservable().filter({ !$0 }).subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.tableView.loadMoreDelegate?.endBottomLoading(hasMore: true)
        }).disposed(by: disposeBag)

        viewModel.asrStatusTextsDriver.drive(onNext: { [weak self] statusText in
            guard let `self` = self else { return }

            if let statusText = statusText {
                if statusText == "NoOneSpeaking" {
                    self.statusLabel.isHidden = !self.viewModel.viewDatas.isEmpty
                    if self.loadingView.isHidden == false {
                        self.loadingView.isHidden = true
                        self.loadingView.stop()
                    }
                } else {
                    self.asrStatusView.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: 32)
                    self.asrStatusView.loadingTipView.start(with: statusText)
                    self.tableView.tableFooterView = self.asrStatusView
                    self.scrollToEnd()
                    self.statusLabel.isHidden = true
                }
            } else {
                if self.tableView.tableFooterView != nil {
                    self.asrStatusView.loadingTipView.stop()
                    self.tableView.tableFooterView = nil
                }
                self.statusLabel.isHidden = true
            }
        }).disposed(by: disposeBag)

        viewModel.searchBottomViewBlock = { [weak self] in
            guard let `self` = self else { return }
            Util.runInMainThread {
                self.searchBottomView.isHidden = !self.viewModel.isSearchMode
                self.searchBottomExtView.isHidden = !self.viewModel.isSearchMode

                self.setTableViewConstraint(self.viewModel.isSearchMode)
                if self.viewModel.isSearchMode {
                    self.tableViewBottomConstraint?.activate()
                } else {
                    self.tableViewBottomConstraint?.deactivate()
                    self.searchView.clearInput()
                }
            }
        }
    }

    func setTableViewConstraint(_ searchModeOn: Bool) {
        tableView.snp.remakeConstraints { (maker) in
            maker.top.equalTo(searchView.snp.bottom)
            maker.left.right.equalTo(safeAreaLayoutGuide)
            if searchModeOn {
                maker.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).priority(.low)
            } else {
                maker.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
            }
            tableViewBottomConstraint = maker.bottom.lessThanOrEqualTo(searchBottomView.snp.top).constraint
        }
    }

    func hideKeyBoard() {
        endEditing(true)
    }

    private func triggerOldRefreshing() {
        pullOldData()
    }

    private func triggerNewRefreshing() {
        viewModel.pullNewAction.execute().subscribe().disposed(by: disposeBag)
    }

    private func pullOldData() {
        viewModel.pullOldAction.execute().subscribe().disposed(by: disposeBag)
    }

    private func isHandleScroll(index: Int) -> Bool {
        let rows = self.tableView.numberOfRows(inSection: 0)
        let result = index < rows
        if (index < self.viewModel.count) && (index >= 0 ) && result {
            return true
        }
        return false
    }

    func handleScrollToBottomButtonHidden() {
        scrollToBottomButtonContainer.isHidden = getScrollToBottomHiddden()
        if getScrollToBottomHiddden() {
            receiveNewSubtitle = false
        }
        updateScrollToBottomButton()
    }
    // 判断是否在底部
    func getScrollToBottomHiddden() -> Bool {
        let scrollHeight = tableView.contentOffset.y + tableView.bounds.height - tableView.adjustedContentInset.bottom
        let tolerance: CGFloat = viewModel.isSearchMode ? 41 : 1
        return (tableView.contentSize.height < scrollHeight + tolerance) // 1.0 for tolerance
    }

    deinit {
    }

    // MARK: - Height
    private var cellHeightCache: [Int: CGFloat] = [:]
    private let cellTemplate = SubtitleHistoryCell(style: .default, reuseIdentifier: "template")
    private let followCellTemplate = SubtitleHistoryDocCell(style: .default, reuseIdentifier: "followTemplate")
    private let behaviorCellTemplate = SubtitleHistoryBehaviorCell(style: .default, reuseIdentifier: "behaviorCellTemplate")

    private func scrollToEnd(animated: Bool = true) {
        receiveNewSubtitle = false
        DispatchQueue.main.async {
            if self.tableView.contentSize.height > self.tableView.frame.height &&
                self.tableView.contentSize.height - self.tableView.frame.height > self.oldContentOffset {
                // nolint-next-line: magic number
                UIView.animate(withDuration: 0.1) {
                    self.tableView.contentOffset = CGPoint(x: 0, y: self.tableView.contentSize.height - self.tableView.frame.height)
                }
            }
            self.scrollToBottomButtonContainer.isHidden = true
        }
    }
}

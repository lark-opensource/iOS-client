//
//  TranscriptViewController.swift
//  ByteView
//
//  Created by 陈乐辉 on 2023/6/17.
//

import Foundation
import RichLabel
import SnapKit
import ByteViewUI
import ByteViewTracker
import UniverseDesignIcon
import ByteViewNetwork
import ByteViewSetting
import ByteViewCommon

class TranscriptViewController: VMViewController<TranscriptViewModel>, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {

    enum Layout {
        static let switchButtonHeight: CGFloat = 54
        static let filterPeopleHeight: CGFloat = 44
        static let searchBottomHeight: CGFloat = 40
    }

    private lazy var closeButton: UIBarButtonItem = {
        let imgKey: UniverseDesignIcon.UDIconType = isScene ? .closeOutlined : .leftOutlined
        let color = preferredNavigationBarStyle.displayParams.buttonTintColor
        let highlighedColor = preferredNavigationBarStyle.displayParams.buttonHighlightTintColor
        let actionButton = UIButton()
        actionButton.setImage(UDIcon.getIconByKey(imgKey, iconColor: color, size: CGSize(width: 24, height: 24)), for: .normal)
        actionButton.setImage(UDIcon.getIconByKey(imgKey, iconColor: highlighedColor, size: CGSize(width: 24, height: 24)), for: .highlighted)
        actionButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        return UIBarButtonItem(customView: actionButton)
    }()

    private lazy var translateButton: UIBarButtonItem = {
        let color = preferredNavigationBarStyle.displayParams.buttonTintColor
        let highlighedColor = preferredNavigationBarStyle.displayParams.buttonHighlightTintColor
        let actionButton = UIButton()
        actionButton.setImage(UDIcon.getIconByKey(.translateOutlined, iconColor: color, size: CGSize(width: 24, height: 24)), for: .normal)
        actionButton.setImage(UDIcon.getIconByKey(.translateOutlined, iconColor: highlighedColor, size: CGSize(width: 24, height: 24)), for: .highlighted)
        actionButton.addTarget(self, action: #selector(translateAction), for: .touchUpInside)
        return UIBarButtonItem(customView: actionButton)
    }()

    private lazy var searchView: SubtitleSearchView = {
        let searchView = SubtitleSearchView()
        searchView.transctiptViewModel = viewModel
        return searchView
    }()

    private lazy var filterPeopleView: TranscriptFilterPeopleView = {
        let view = TranscriptFilterPeopleView()
        view.isHidden = true
        view.button.addTarget(self, action: #selector(clearFilterAction), for: .touchUpInside)
        return view
    }()

    private lazy var tableView: BaseTableView = {
        let tableView = BaseTableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.indicatorStyle = .black
        tableView.canCancelContentTouches = false
        tableView.keyboardDismissMode = .onDrag
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.register(SubtitleHistoryCell.self, forCellReuseIdentifier: SubtitleHistoryCell.description())
        tableView.register(SubtitleHistoryDocCell.self, forCellReuseIdentifier: SubtitleHistoryDocCell.description())
        tableView.register(SubtitleHistoryBehaviorCell.self, forCellReuseIdentifier: SubtitleHistoryBehaviorCell.description())
        tableView.delegate = self
        tableView.dataSource = self

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        longPressGesture.minimumPressDuration = 1.0 // 1 second press
        longPressGesture.delegate = self
        longPressGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(longPressGesture)

        let singlePressGesture = UITapGestureRecognizer(target: self, action: #selector(tapPress))
        singlePressGesture.delegate = self
        singlePressGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(singlePressGesture)

        return tableView
    }()

    private lazy var loadingView: TranscriptLoadingView = {
        let loadingView = TranscriptLoadingView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 20))
        loadingView.play()
        return loadingView
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textCaption
        let text = viewModel.isAllMuted ? I18n.View_G_NoOneTalkNow : I18n.View_G_Transcribe_WaitNotice
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 22
        paragraphStyle.minimumLineHeight = 22
        paragraphStyle.alignment = .center
        label.attributedText = NSAttributedString(string: text, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var switchButton: TranscriptSwitchButton = {
        let button = TranscriptSwitchButton(type: .custom)
        button.isTranscribing = viewModel.isTranscribing
        button.addTarget(viewModel, action: #selector(TranscriptViewModel.transcriptSwitchAction), for: .touchUpInside)
        return button
    }()

    private lazy var scrollToBottomButtonContainer: UIView = {
        let view = UIView()
        view.layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.layer.shadowRadius = 10
        view.layer.shadowOpacity = 1
        view.isHidden = true
        view.addSubview(scrollToBottomButton)
        scrollToBottomButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }()

    private lazy var scrollToBottomButton: SubtitleHistoryFloatBackView = {
        let button = SubtitleHistoryFloatBackView()
        button.addTarget(self, action: #selector(didClickScrollToBottomButton(_:)), for: .touchUpInside)
        button.addInteraction(type: .highlight)
        button.titleLabel.attributedText = NSAttributedString(string: I18n.View_G_NewContent_Scroll, config: .boldBodyAssist)
        return button
    }()

    private lazy var searchBottomView: SubtitleSearchBottomView = {
        let sv = SubtitleSearchBottomView()
        sv.transcriptViewModel = viewModel
        sv.isHidden = true
        return sv
    }()

    var isScene: Bool = false

    private var cellHeightCache: [Int: CGFloat] = [:]

    private var isScrollToBottomAutomatically: Bool = false

    var meeting: InMeetMeeting {
        viewModel.meeting
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        meeting.router.addListener(self)
        viewModel.addListener(self)
        meeting.participant.addListener(self)
        meeting.addMyselfListener(self)
        meeting.addListener(self)
        viewModel.fetchLatestTranscritps()
        DispatchQueue.main.async {
            self.transcribeStatusDidChanged(status: self.viewModel.transcriptStatus)
        }
    }

    deinit {
    }

    override func setupViews() {
        super.setupViews()
        setNavigationItemTitle(text: I18n.View_G_Transcribe_Title, color: .ud.textTitle)
        view.backgroundColor = UIColor.ud.bgBody
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = translateButton

        view.addSubview(searchView)
        searchView.snp.remakeConstraints { make in
            make.height.equalTo(56.0)
            make.left.right.equalTo(view.safeAreaLayoutGuide)
            make.top.equalToSuperview()
        }

        view.addSubview(tableView)
        updateTableViewLayout()

        view.addSubview(filterPeopleView)
        filterPeopleView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(searchView.snp.bottom)
        }

        view.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.center.equalTo(tableView)
        }

        view.addSubview(switchButton)
        switchButton.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(Layout.switchButtonHeight)
        }

        view.addSubview(searchBottomView)
        updateSearchBottomViewLayout()

        view.addSubview(scrollToBottomButtonContainer)
        updateScrollToBottomButtonLayout(isIcon: true)
        scrollToBottomButton.changeButtonStyleToIcon()
    }

    override func bindViewModel() {
        super.bindViewModel()
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.cellHeightCache = [:]
        self.tableView.reloadData()
        self.scrollToBottomIfNeeded()
    }

    func close() {
        if #available(iOS 13.0, *), VCScene.supportsMultipleScenes {
            let info = InMeetTranscribeDefine.generateSceneInfo(with: meeting.meetingId)
            VCScene.closeScene(info)
        } else {
            meeting.router.setWindowFloating(false)
        }
    }

    // MARK: - action
    @objc func closeAction() {
        close()
        MeetSettingTracks.trackHideTranscriptPanel(location: "transcript_panel")
    }

    @objc private func translateAction() {
        let viewController = meeting.setting.ui.createTranscriptLanguageViewController(context: TranscriptLanguageContext())
        if Display.pad {
            guard let sourceView = translateButton.customView else { return }
            let popoverConfig = DynamicModalPopoverConfig(sourceView: sourceView,
                                                          sourceRect: sourceView.bounds,
                                                          backgroundColor: UIColor.clear,
                                                          permittedArrowDirections: .up)
            let regularConfig = DynamicModalConfig(presentationStyle: .popover,
                                                   popoverConfig: popoverConfig,
                                                   backgroundColor: .clear,
                                                   needNavigation: true)
            meeting.router.presentDynamicModal(viewController,
                                              regularConfig: regularConfig,
                                              compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true),
                                              from: self)
        } else {
            let vc = NavigationController(rootViewController: viewController)
            vc.modalPresentationStyle = .pageSheet
            meeting.larkRouter.present(vc, animated: true)
        }
    }

    @objc private func clearFilterAction() {
        viewModel.clearFilter()
        VCTracker.post(name: .vc_meeting_transcribe_click, params: ["click": "delete_filter", "location": "delete_name"])
    }

    @objc func didClickScrollToBottomButton(_ sender: UIView) {
        scrollToBottomButtonContainer.isHidden = true
        scrollToBottomButton.changeButtonStyleToIcon()
        updateScrollToBottomButtonLayout(isIcon: true)
        updateTableViewLayout()
        scrollToBottom()
    }


    // MARK: - UITableViewDelegate & UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.transcripts.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < viewModel.transcripts.count else { return 0 }
        let vm = viewModel.transcripts[indexPath.row]
        let offset: CGFloat = vm.needMerge ? 12 : 38
        if let h = cellHeightCache[vm.segId] {
            return h + offset
        }
        let h = SubtitleHistoryCell.getCellHeight(with: vm, width: view.safeAreaLayoutGuide.layoutFrame.width)
        cellHeightCache[vm.segId] = h
        return h + offset
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < viewModel.transcripts.count else { return UITableViewCell() }
        let vm = viewModel.transcripts[indexPath.row]
        guard let identifier = vm.identifier, let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? SubtitleHistoryBaseCell else {
                return UITableViewCell()
        }
        if let c = cell as? SubtitleHistoryCell {
            c.isAlignRight = viewModel.isAlignRight
        }
        cell.containerWidth = view.safeAreaLayoutGuide.layoutFrame.width
        cell.cellHeight = cellHeightCache[vm.segId] ?? 0
        _ = cell.updateViewModel(vm: vm)

        if let c = cell as? SubtitleHistoryCell {
            if let currentSelectedId = viewModel.currentSelectedId, vm.segId == currentSelectedId {
                c.selectedRange = viewModel.currentSelectedRange
            } else {
                c.selectedRange = nil
            }
        }

        if let c = cell as? SubtitleHistoryDocCell {
            if let currentSelectedId = viewModel.currentSelectedId, vm.segId == currentSelectedId {
                c.selectedRange = viewModel.currentSelectedRange
            } else {
                c.selectedRange = nil
            }
            c.gotoDocs = { [weak self] url in
                guard let `self` = self else { return }
                VCTracker.post(name: .vc_meeting_subtitle_page, params: [.action_name: "docs_link"])
                self.meeting.larkRouter.gotoDocs(urlString: url, context: ["from": "subtitles"], from: self)
            }
        }
        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleScrollToBottomButtonHidden()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            handleScrollToBottomButtonHidden()
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    @objc
    func tapPress(gesture: UIGestureRecognizer) {
        if gesture.state == .ended {
            let touchPoint = gesture.location(in: tableView)
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

    // MARK: -
    func hideKeyBoard() {
        view.endEditing(true)
    }

    func isScrolledToBottom() -> Bool {
        let height = tableView.frame.size.height
        let distanceFromBottom = tableView.contentSize.height - tableView.contentOffset.y
        return distanceFromBottom <= height
    }

    func handleScrollToBottomButtonHidden() {
        scrollToBottomButtonContainer.isHidden = isScrolledToBottom()
        if isScrolledToBottom() {
            updateScrollToBottomButtonLayout(isIcon: true)
            scrollToBottomButton.changeButtonStyleToIcon()
        }
    }
}


extension TranscriptViewController {

    func pullRefresh() {
        viewModel.fetchBeforeTranscritps()
    }

    func loadMore() {
        viewModel.fetchAfterTranscritps()
    }
}

extension TranscriptViewController {

    func updateTableViewLayout() {
        let top = filterPeopleView.isHidden ? 0 : Layout.filterPeopleHeight
        let bottom = (switchButton.isHidden ? 0 : Layout.switchButtonHeight) + (searchBottomView.isHidden ? 0 : Layout.searchBottomHeight)
        tableView.snp.remakeConstraints { make in
            make.left.right.equalTo(view.safeAreaLayoutGuide)
            make.top.equalTo(searchView.snp.bottom).offset(top)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-bottom)
        }
    }

    func updateTableViewFooterView() {
        let isEmpty = viewModel.transcripts.isEmpty
        statusLabel.isHidden = !isEmpty
        if tableView.tableFooterView == nil, !isEmpty, viewModel.isTranscribing {
            tableView.tableFooterView = loadingView
            scrollToBottomIfNeeded()
        }
        if isEmpty || !viewModel.isTranscribing {
            tableView.tableFooterView = nil
        }
    }

    func updateStatusLabel() {
        guard viewModel.transcripts.isEmpty else { return }
        if viewModel.transcriptStatus == .pause {
            let pid = meeting.info.host.participantId
            let service = meeting.httpClient.participantService
            service.participantInfo(pid: pid, meetingId: meeting.meetingId) { [weak self] info in
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.maximumLineHeight = 22
                paragraphStyle.minimumLineHeight = 22
                paragraphStyle.alignment = .center
                self?.statusLabel.attributedText = NSAttributedString(string: I18n.View_G_TranscribeMeeting_Description(info.name), attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
            }
        } else {
            let text = viewModel.isAllMuted ? I18n.View_G_NoOneTalkNow : I18n.View_G_Transcribe_WaitNotice
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.maximumLineHeight = 22
            paragraphStyle.minimumLineHeight = 22
            paragraphStyle.alignment = .center
            statusLabel.attributedText = NSAttributedString(string: text, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        }
    }

    func updateSwitchButton() {
        if viewModel.transcriptStatus == .initializing {
            switchButton.isTranscribing = true
            switchButton.setTitle(I18n.View_G_Transcribe_Starting, for: .normal)
        } else {
            switchButton.isTranscribing = viewModel.isTranscribing
        }
        switchButton.isHidden = viewModel.isTranscribing ? !meeting.setting.canStartTranscribe : false
    }

    func scrollToBottomIfNeeded() {
        if tableView.isTracking || tableView.isDecelerating || tableView.isDragging || !scrollToBottomButtonContainer.isHidden || viewModel.isSearchMode { return }
        scrollToBottom()
    }

    func scrollToBottom() {
        tableView.vc.scrollToBottom(animated: true)
        scrollToBottomButtonContainer.isHidden = true
    }

    func updateScrollToBottomButtonLayout(isIcon: Bool) {
        let h = isIcon ?  48 : 38
        let bottomOffset = (switchButton.isHidden ? -48 : -70) + (searchBottomView.isHidden ? 0 : -Layout.searchBottomHeight)
        let keyboardBottomOffset = searchBottomView.isHidden ? -16: (-16 - Layout.searchBottomHeight)
        scrollToBottomButtonContainer.snp.remakeConstraints { (maker) in
            maker.height.equalTo(h)
            maker.right.equalTo(-16)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).offset(bottomOffset).priority(.low)
            maker.bottom.lessThanOrEqualTo(view.vc.keyboardLayoutGuide.snp.top).offset(keyboardBottomOffset)
        }
    }

    func updateSearchBottomViewLayout() {
        let bottomOffset: CGFloat = switchButton.isHidden ? 0 : Layout.switchButtonHeight
        searchBottomView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(Layout.searchBottomHeight)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-bottomOffset).priority(.low)
            make.bottom.lessThanOrEqualTo(view.vc.keyboardLayoutGuide.snp.top)
        }
    }

    func isHandleScroll(index: Int) -> Bool {
        let rows = tableView.numberOfRows(inSection: 0)
        let result = index < rows
        if (index < viewModel.transcripts.count) && (index >= 0 ) && result {
            return true
        }
        return false
    }
}


extension TranscriptViewController: TranscriptViewModelDelegate {
    func transcriptsDidUpdated() {
        updateTableViewFooterView()
        tableView.loadMoreDelegate?.endTopLoading(hasMore: true)
        tableView.loadMoreDelegate?.endBottomLoading(hasMore: true)
        let offsetToBottom = tableView.contentSize.height - tableView.contentOffset.y
        tableView.reloadData()
        if viewModel.keepPosition {
            var contentOffset = tableView.contentOffset
            contentOffset.y = min(tableView.vc.bottomEdgeContentOffset,
                                  tableView.contentSize.height - offsetToBottom)
            if contentOffset.y > 0 {
                tableView.contentOffset = contentOffset
            }
            viewModel.keepPosition = false
        } else {
            scrollToBottomIfNeeded()
        }
    }

    func transcriptsDataWillClear() {
        cellHeightCache.removeAll()
    }

    func didReceivedNewTranscript() {
        if !scrollToBottomButtonContainer.isHidden {
            scrollToBottomButton.changeButtonStyleToText()
            updateScrollToBottomButtonLayout(isIcon: false)
        }
    }

    func selectedSearchResultDidChangeTo(row: Int) {
        if isHandleScroll(index: row) {
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .middle, animated: true)
        }
    }

    func filterModeDidChanged() {
        if let selectedUser = viewModel.filterViewModel.selectedUser {
            filterPeopleView.button.config(with: selectedUser)
        }
        filterPeopleView.isHidden = !viewModel.isFilterMode
        updateTableViewLayout()
    }

    func searchModeDidChanged() {
        searchBottomView.isHidden = !viewModel.isSearchMode
        updateSearchBottomViewLayout()
        updateTableViewLayout()
        updateScrollToBottomButtonLayout(isIcon: true)
        scrollToBottomButton.changeButtonStyleToIcon()
    }

    func transcribeStatusDidChanged(status: TranscriptInfo.TranscriptStatus) {
        updateSwitchButton()
        updateTableViewFooterView()
        updateTableViewLayout()
        updateScrollToBottomButtonLayout(isIcon: true)
        scrollToBottomButton.changeButtonStyleToIcon()
        updateSearchBottomViewLayout()
        updateStatusLabel()
    }

    func pullRefreshVisibleDidChanged() {
        if viewModel.hasBeforeData {
            tableView.loadMoreDelegate?.addTopLoading(handler: { [weak self] in self?.pullRefresh() })
            // 由于PullDownBackgroundView无法直接设置颜色，因此采用Hook的方法
            if let subviews = tableView.loadMoreDelegate?.topLoadingView?.subviews,
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
            tableView.loadMoreDelegate?.removeTopLoading()
        }
    }

    func loadMoreVisibleDidChanged() {
        if viewModel.hasAfterData {
            tableView.loadMoreDelegate?.addBottomLoading { [weak self] in
                self?.loadMore()
            }
            // 由于PullDownBackgroundView无法直接设置颜色，因此采用Hook的方法
            if let subviews = tableView.loadMoreDelegate?.bottomLoadingView?.subviews,
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
            tableView.loadMoreDelegate?.removeBottomLoading()
        }
    }
}

extension TranscriptViewController: RouterListener {
    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        if !isFloating {
            if #available(iOS 13.0, *), VCScene.supportsMultipleScenes { return }
            dismiss(animated: false)
            navigationController?.dismiss(animated: true)
        }
    }
}

extension TranscriptViewController: InMeetParticipantListener {

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        DispatchQueue.main.async {
            self.updateStatusLabel()
        }
    }
}

extension TranscriptViewController: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        DispatchQueue.main.async {
            self.updateSwitchButton()
            self.updateStatusLabel()
        }
    }
}

extension TranscriptViewController: InMeetMeetingListener {
    func didReleaseInMeetMeeting(_ meeting: InMeetMeeting) {
        if VCScene.supportsMultipleScenes { return }
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: false)
            self.navigationController?.dismiss(animated: true)
        }
    }
}

class TranscriptSwitchButton: UIButton {

    private lazy var line: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.lineDividerDefault
        return v
    }()

    var isTranscribing: Bool = true {
        didSet {
            let titleColor: UIColor = isTranscribing ? .ud.functionDangerContentDefault : .ud.primaryContentDefault
            let pressedColor: UIColor = isTranscribing ? .ud.udtokenBtnTextBgDangerPressed : .ud.udtokenBtnTextBgPriPressed
            let bgImage = UIImage.vc.fromColor(pressedColor, size: bounds.size, cornerRadius: 6)
            let title = isTranscribing ? I18n.View_G_Transcribe_StopButton : I18n.View_G_Transcribe_StartButton
            setTitle(title, for: .normal)
            setTitleColor(titleColor, for: .normal)
            setBackgroundImage(bgImage, for: .highlighted)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        vc.setBackgroundColor(.ud.bgBody, for: .normal)
        vc.setBackgroundColor(.ud.bgBody, for: .highlighted)
        titleLabel?.font = UIFont.systemFont(ofSize: 16)

        addSubview(line)
        line.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

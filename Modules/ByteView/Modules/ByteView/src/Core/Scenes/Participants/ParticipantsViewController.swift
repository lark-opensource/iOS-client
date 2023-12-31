//
//  ParticipantsViewController.swift
//  ByteView
//
//  Created by LUNNER on 2019/1/8.
//

import UIKit
import SnapKit
import LarkSegmentedView
import UniverseDesignIcon
import ByteViewTracker
import ByteViewUI

final class ParticipantsViewController: VMViewController<ParticipantsViewModel>, UITableViewDelegate, UITableViewDataSource {

    enum ScrollToLobbyList {
        case none
        case normal
        case attendee
        case suggest
    }

    enum ListType: String {
        case inMeet
        case suggestion
        case attendee

        var defaultTitle: String {
            switch self {
            case .inMeet:
                return I18n.View_M_AllNumber(0)
            case .suggestion:
                return I18n.View_M_SuggestionsNumberBraces(0)
            case .attendee:
                return I18n.View_G_AttendeeTab(0)
            }
        }
    }

    lazy var customNaviBar = CustomNavigationBar()
    var useCustomNaviBar: Bool {
        if Display.phone, #available(iOS 13.0, *) { return true }
        return false
    }
    var customNaviSettingButton: UIButton { customNaviBar.rightButton }
    var customNaviCloseButton: UIButton { customNaviBar.leftButton }
    var customNaviTitleContainer: UIView { customNaviBar.titleContainerView }

    lazy var settingButton: UIBarButtonItem = {
        let color = preferredNavigationBarStyle.displayParams.buttonTintColor
        let highlighedColor = preferredNavigationBarStyle.displayParams.buttonHighlightTintColor
        let actionButton = UIButton()
        actionButton.setImage(UDIcon.getIconByKey(.adminSettingOutlined, iconColor: color, size: CGSize(width: 24, height: 24)), for: .normal)
        actionButton.setImage(UDIcon.getIconByKey(.adminSettingOutlined, iconColor: highlighedColor, size: CGSize(width: 24, height: 24)), for: .highlighted)
        actionButton.addTarget(self, action: #selector(didSet), for: .touchUpInside)
        actionButton.addInteraction(type: .highlight, shape: .roundedRect(CGSize(width: 44, height: 36), 8.0))
        return UIBarButtonItemFactory.create(customView: actionButton, size: CGSize(width: 32, height: 44))
    }()

    lazy var segmentedDataSource: JXSegmentedTitleDataSource = {
       let datasource = JXSegmentedTitleDataSource()
        datasource.widthForTitleClosure = { [weak self] _ -> CGFloat in
            guard let self = self else { return 0 }
            let viewWidth = self.navigationController?.view.bounds.size.width ?? self.view.bounds.size.width
            let itemWidth = viewWidth / CGFloat(self.controllersDatasource.count)
            return itemWidth
        }
        datasource.isTitleColorGradientEnabled = false
        datasource.titleNormalFont = UIFont.systemFont(ofSize: 14)
        datasource.titleSelectedFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        datasource.titleNormalColor = UIColor.ud.textCaption
        datasource.titleSelectedColor = UIColor.ud.primaryContentDefault
        datasource.titles = segmentedTypes.map { self.segmentTitle(for: $0, participantsCount: 0) }
        // 去除item之间的间距
        datasource.itemWidthIncrement = 0
        datasource.itemSpacing = 0
        return datasource
    }()

    lazy var segmentedView: JXSegmentedView = {
        let segmentedView = JXSegmentedView()
        segmentedView.dataSource = segmentedDataSource

        let indicator = JXSegmentedIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorColor = UIColor.ud.primaryContentDefault
        indicator.lineStyle = .lengthen

        segmentedView.backgroundColor = UIColor.ud.bgFloat
        segmentedView.indicators = [indicator]
        segmentedView.isContentScrollViewClickTransitionAnimationEnabled = false
        segmentedView.contentEdgeInsetLeft = 0
        segmentedView.contentEdgeInsetRight = 0

        segmentedView.listContainer = listContainerView
        segmentedView.addBorder(edges: .bottom, color: .ud.lineDividerDefault, thickness: 0.5)
        segmentedView.delegate = self
        return segmentedView
    }()

    /// webinar 嘉宾tab 举手标识
    lazy var paneListHandsupIcon: UIImageView = {
        let key = viewModel.meeting.setting.handsUpEmojiKey
        let image = EmojiResources.getEmojiSkin(by: key)
        let imageView = UIImageView(image: image)
        imageView.isHidden = true
        return imageView
    }()
    /// webinar 观众tab 举手标识
    lazy var attendeesHandsupIcon: UIImageView = {
        let key = viewModel.meeting.myself.settings.conditionEmojiInfo?.handsUpEmojiKey
        let image = EmojiResources.getEmojiSkin(by: key)
        let imageView = UIImageView(image: image)
        imageView.isHidden = true
        return imageView
    }()

    lazy var placeHolderView: UIView = {
        let placeHolderView = UIView()
        placeHolderView.backgroundColor = UIColor.ud.bgFloat
        return placeHolderView
    }()

    lazy var timerbanner = BreakoutRoomTimerBanner()
    var searchViewBelowBannerConstraint: Constraint?
    var searchViewAtTopConstraint: Constraint?

    lazy var listContainerView: JXSegmentedListContainerView = {
        let view = JXSegmentedListContainerView(dataSource: self)
        return view
    }()

    var controllersDatasource: [JXSegmentedListContainerViewListDelegate]
    var segmentedTypes: [ListType] = []

    lazy var searchResultMaskView: UIView = {
        let stackView = UIStackView(arrangedSubviews: [participantSearchHeaderView, resultBackgroundView])
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.isHidden = true

        let backView = UIView(frame: stackView.bounds)
        backView.backgroundColor = UIColor.ud.bgFloat.withAlphaComponent(0.5)
        backView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        stackView.insertSubview(backView, at: 0)
        return stackView
    }()

    lazy var searchView: SearchBarView = {
        let searchView = SearchBarView(frame: CGRect.zero, isNeedCancel: true, isNeedShare: true)
        searchView.iconImageDimension = 18
        searchView.clipsToBounds = true
        searchView.cancelButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        searchView.shareButton.addTarget(self, action: #selector(searchShareButtonAction(_:)), for: .touchUpInside)
        return searchView
    }()

    lazy var participantSearchHeaderView: ParticipantSearchHeaderView = {
        let view = ParticipantSearchHeaderView(frame: .zero)
        view.isHidden = true
        return view
    }()

    lazy var resultBackgroundView: UIView = {
        let view = UIView(frame: .zero)
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(tapResultBackgroundView(_:)))
        view.addGestureRecognizer(tap)
        return view
    }()

    lazy var searchResultView: SearchContainerView = {
        let searchContainerView = SearchContainerView(frame: .zero)
        searchContainerView.tableView.rowHeight = 66
        searchContainerView.backgroundColor = UIColor.ud.bgFloat
        searchContainerView.tableView.keyboardDismissMode = .none
        searchContainerView.tableView.backgroundColor = UIColor.ud.bgFloat
        searchContainerView.tableView.separatorStyle = .none
        searchContainerView.tableView.keyboardDismissMode = .onDrag
        searchContainerView.tableView.delaysContentTouches = false
        searchContainerView.tableView.delegate = self
        searchContainerView.tableView.dataSource = self
        searchContainerView.tableView.register(cellType: SearchParticipantCell.self)
        // 屏蔽父试图tap相应
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        searchContainerView.addGestureRecognizer(tapGesture)
        return searchContainerView
    }()

    lazy var startSearchDebounce: Debounce<String> = {
        debounce(interval: .milliseconds(300)) { [weak self] text in
            self?.startSearch(text: text)
        }
    }()

    let titleView = UIView()
    let titleLabel = UILabel()
    let countLabel = UILabel()

    var isFirstAppear: Bool = true
    let autoScrollToLobby: ParticipantsViewController.ScrollToLobbyList
    weak var sharePopover: AlignPopoverViewController?

    init(subViewControllers: [JXSegmentedListContainerViewListDelegate], autoScrollToLobby: ParticipantsViewController.ScrollToLobbyList = .none) {
        self.controllersDatasource = subViewControllers
        self.autoScrollToLobby = autoScrollToLobby
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupViews() {
        view.backgroundColor = UIColor.ud.bgFloat
        edgesForExtendedLayout = .bottom
        setNavigationBar()
        setSearchViewPlaceholder(I18n.View_G_SASearchOrCall)
        layoutTopArea()
        layoutSegmentedView()
        layoutSearchView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard viewModel.meeting.type == .call, viewModel.canInvite else {
            return
        }
        // nolint-next-line: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.searchView.textField.becomeFirstResponder()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.resolver.viewContext.post(.participantsDidAppear)
        if isFirstAppear {
            VCTracker.post(name: viewModel.meeting.type == .call ? .vc_call_page_invite : .vc_meeting_page_invite,
                           params: [.action_name: "display"])
            // iOS 13后ipad formsheet样式导航栏的高度为56,系统存在导航栏高度更新不及时的问题
            if #available(iOS 13.0, *), Display.pad {
                navigationController?.navigationBar.setNeedsLayout()
            }
            isFirstAppear = false
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.resolver.viewContext.post(.participantsDidDisappear)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        segmentedView.layer.shadowPath = UIBezierPath(rect: segmentedView.bounds).cgPath
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if Display.phone, newContext.layoutChangeReason.isOrientationChanged {
            placeHolderView.snp.updateConstraints { maker in
                maker.height.equalTo(segmentedViewTopOffset(canInvited: viewModel.canInvite) + (newContext.layoutType.isRegular ? 2 : 0))
            }
            searchResultMaskView.snp.updateConstraints { make in
                make.top.equalTo(searchView.snp.bottom).offset(searchResultMaskViewTopOffset)
            }
        }
        self.segmentedView.reloadData()
    }

    override func bindViewModel() {
        bindSegmentedView()
        bindMaskViewHidden()
        bindSearchView()
        updateManipulatorActionSheet(isIPadLayout: false)
        bindBreakoutRoom()
    }

    func hiddenSetting(isHidden: Bool) {
        guard !useCustomNaviBar else {
            customNaviSettingButton.isHidden = isHidden
            return
        }
        guard let customView = navigationItem.rightBarButtonItem?.customView else { return }
        if isHidden && !customView.isHidden {
            customView.isHidden = true
        }
        if !isHidden && customView.isHidden {
            customView.isHidden = false
        }
    }

    override func doBack() {
        super.doBack()
        MeetingTracksV2.trackClickCloseButton(isSharingContent: viewModel.meeting.shareData.isSharingContent,
                                              isMinimized: viewModel.router.isFloating,
                                              isMore: false)
    }

    @objc func didSet() {
        MeetingTracksV2.trackParticipantsSettingButtonClick(isSharingContent: viewModel.meeting.shareData.isSharingContent)
        let context = InMeetSecurityContextImpl(meeting: viewModel.meeting, fromSource: .participant)
        let vc = viewModel.setting.ui.createInMeetSecurityViewController(context: context)
        viewModel.router.push(vc, from: self)
    }

    @objc func searchShareButtonAction(_ b: Any) {
        sharePopover = viewModel.tapShareView(sourceView: searchView.shareButton)
        sharePopover?.fullScreenDetector = viewModel.resolver.viewContext.fullScreenDetector
    }

    @objc func tapResultBackgroundView(_ t: Any) {
        searchView.resetSearchBar()
        searchResultMaskView.isHidden = true
        searchView.cancelButton.isHidden = true
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath),
              let searchCell = cell as? SearchParticipantCell,
              let cellModel = viewModel.searchDataSource[safeAccess: indexPath.row] else { return }

        let searchBox = cellModel.searchBox
        searchView.textField.resignFirstResponder()
        let completion: () -> Void = {
            Util.runInMainThread {
                self.searchView.resetSearchBar()
                self.searchResultMaskView.isHidden = true
            }
        }
        if searchBox.state == .joined, let participant = searchBox.participant, let displayName = cellModel.displayName {
            // 添加对joined状态搜索结果的点击事件
            viewModel.tapInMeetingParticipantCell(sourceView: cell,
                                                  participant: participant,
                                                  displayName: displayName,
                                                  originalName: cellModel.originalName,
                                                  source: .searchList)
        } else if searchBox.isJoining {
            // 添加对非joined状态搜索结果的点击事件
            viewModel.manipulateOtherSearchParticipants(cellView: searchCell,
                                                        searchCellModel: cellModel,
                                                        manipulateCompletion: completion)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.searchDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let model = viewModel.searchDataSource[safeAccess: indexPath.row] else { return UITableViewCell() }
        // 配置搜索列表中的其它状态用户
        let cell = tableView.dequeueReusableCell(withType: SearchParticipantCell.self, for: indexPath)
        cell.configure(with: model)
        if !model.searchBox.isJoining {
            cell.tapEventButton = { [weak self, weak cell] in
                guard let self = self, let cell = cell else { return }
                self.searchView.textField.resignFirstResponder()
                if model.enableInvitePSTN {
                    self.viewModel.searchCallMore(with: model, sender: cell.eventButton) { [weak self] in
                        self?.searchView.resetSearchBar()
                        self?.searchResultMaskView.isHidden = true
                    }
                } else {
                    self.searchView.resetSearchBar()
                    self.searchResultMaskView.isHidden = true
                    self.viewModel.searchCall(with: model.searchBox)
                }
            }
        }
        cell.tapAvatarAction = { [weak self] in
            if let participant = model.searchBox.participant {
                self?.viewModel.jumpToUserProfile(participantId: participant.participantId, isLarkGuest: participant.isLarkGuest)
            } else if let byteviewUser = model.searchBox.userItem?.byteviewUser {
                self?.viewModel.jumpToUserProfile(participantId: byteviewUser.participantId, isLarkGuest: false)
            }
        }
        return cell
    }
}

extension ParticipantsViewController: JXSegmentedListContainerViewDataSource {
    func numberOfLists(in listContainerView: JXSegmentedListContainerView) -> Int {
        return segmentedTypes.count
    }

    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> JXSegmentedListContainerViewListDelegate {
        return controllersDatasource[index]
    }
}

extension ParticipantsViewController: JXSegmentedViewDelegate {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        guard segmentedTypes.count > index else { return }

        let isSharingContent = viewModel.meeting.shareData.isSharingContent
        let type = segmentedTypes[index]
        switch type {
        case .inMeet:
            MeetingTracksV2.trackClickAllParticipants(isSharingContent: isSharingContent, isMinimized: false, isMore: false)
        case .suggestion:
            MeetingTracksV2.trackClickSuggestions(isSharingContent: isSharingContent, isMinimized: false, isMore: false)
        case .attendee: break
        }

        if type != .suggestion,
           let vc = controllersDatasource.first(where: { $0 is SuggestionParticipantsViewController }) as? SuggestionParticipantsViewController {
            vc.exitMultiSelectStyleIfNeeded()
        }
    }

    func segmentedView(_ segmentedView: LarkSegmentedView.JXSegmentedView, didScrollSelectedItemAt index: Int) {
        guard segmentedTypes.count > index else { return }
        if index > 0,
           let vc = controllersDatasource.first(where: { $0 is BaseViewController }) as? BaseViewController,
           vc.isFirstDidAppear {
            // segmentedView 有bug，scrollAtIndex时不会走didAppear，需要手动layout
            vc.view.setNeedsLayout()
        }
    }
}

extension ParticipantsViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        updateManipulatorActionSheet(isIPadLayout: isRegular)
    }
}

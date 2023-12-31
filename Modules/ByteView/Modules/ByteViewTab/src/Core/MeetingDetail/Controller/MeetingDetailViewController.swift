//
//  MeetingDetailViewController.swift
//  MeetingDetail
//
//  Created by chenyizhuo on 2021/1/15.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ByteViewUI
import ByteViewCommon
import ByteViewNetwork
import UniverseDesignEmpty
import UniverseDesignIcon
import ByteViewTracker

final class MeetingDetailViewController: VMViewController<MeetingDetailViewModel>, UIScrollViewDelegate {

    let barInset: CGFloat = Display.iPhoneXSeries ? 8 : 4

    lazy var scrollView: ByteViewTabScrollView = {
        let scrollView = ByteViewTabScrollView()
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.ud.bgFloat
        return scrollView
    }()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()

    private var resolver = MeetingDetailComponentResolver()

    lazy var headerView = MeetingDetailHeaderView(resolver: resolver)
    lazy var footerView: UIView = UIView()
    lazy var itemViews: [UIView] = [headerView] + components + [footerView]

    // 顺序: 会议纪要，统计/Bitable，群组入口，妙计，入会/离会信息，历史会议合集，相关文档，会中聊天，日程签到，投票
    lazy var components: [MeetingDetailComponent] = [
        MeetingDetailNotesCellComponent.self,
        MeetingDetailStatisticsCellComponent.self,
        MeetingDetailGroupChatBodyComponent.self,
        MeetingDetailRecordCellComponent.self,
        MeetingDetailCallHistoryComponent.self,
        MeetingDetailCollectionBodyComponent.self,
        MeetingDetailFollowCellComponent.self,
        MeetingDetailChatHistoryCellComponent.self,
        MeetingDetailCheckinInfoCellComponent.self,
        MeetingDetailVoteStatisticsCellComponent.self
    ].compactMap { resolver.resolve($0) }

    private var isLastRegular = Util.rootTraitCollection?.horizontalSizeClass == .regular // 上次是不是regular
    private var hasUpdateScrollViewAtFirst = false
    private var router: TabRouteDependency? { viewModel.router }

    private var isRegular: Bool {
        Util.rootTraitCollection?.horizontalSizeClass == .regular
    }

    lazy var businessLoadingView: BusinessLoadingView = {
        var view = BusinessLoadingView()
        view.backgroundColor = .clear
        return view
    }()

    lazy var shareButton: UIButton = {
        let color = UIColor.ud.iconN1
        let highlighedColor = UIColor.ud.N500.dynamicColor
        var icon: UDIconType = .shareOutlined
        let shareButton = UIButton()
        shareButton.setImage(UDIcon.getIconByKey(icon, iconColor: color, size: CGSize(width: 24, height: 24)), for: .normal)
        shareButton.setImage(UDIcon.getIconByKey(icon, iconColor: highlighedColor, size: CGSize(width: 24, height: 24)), for: .highlighted)
        shareButton.addTarget(self, action: #selector(didShare), for: .touchUpInside)
        shareButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: barInset, bottom: 0, right: -barInset)
        shareButton.isHidden = true
        return shareButton
    }()

    lazy var backButton: UIBarButtonItem = {
        let color = UIColor.ud.iconN1
        let highlighedColor = UIColor.ud.N500.dynamicColor
        var icon: UDIconType = Display.pad ? .closeOutlined : .leftOutlined
        let actionButton = UIButton()
        actionButton.setImage(UDIcon.getIconByKey(icon, iconColor: color), for: .normal)
        actionButton.setImage(UDIcon.getIconByKey(icon, iconColor: highlighedColor), for: .highlighted)
        actionButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
        actionButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -barInset, bottom: 0, right: barInset)
        return UIBarButtonItemFactory.create(customView: actionButton, size: CGSize(width: 32, height: 44))
    }()

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if !hasUpdateScrollViewAtFirst {
            updateScrollView(width: view.bounds.width)
            hasUpdateScrollViewAtFirst = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBase
        viewModel.hostViewController = self

        NotificationCenter.default.addObserver(self, selector: #selector(didTapUserName(_:)), name: .didTapUserNameNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItem = UIBarButtonItemFactory.create(customView: shareButton, size: CGSize(width: 32, height: 44))
        setNavigationBarBgColor(UIColor.ud.N50.dynamicColor)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateScrollView(width: size.width)
        headerView.updateLayout()
        (components + headerView.components).forEach {
            $0.updateLayout()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func setupViews() {
        super.setupViews()

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalToSuperview()
        }

        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.right.equalTo(view)
            make.edges.equalToSuperview()
        }

        itemViews.forEach {
            add(contentView: $0)
            $0.layer.masksToBounds = true
            if $0 === footerView {
                $0.isHidden = false
                $0.layer.masksToBounds = true
            }
        }

        (components + headerView.components).forEach {
            $0.setupViews()
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        viewModel.commonInfo.addObserver(self)
        viewModel.historyInfos.addObserver(self)

        (components + headerView.components).forEach {
            $0.bindViewModel(viewModel: viewModel)
        }

        fetchData()
    }

    private func fetchData() {
        showBusinessLoading()

        viewModel.fetchData { [weak self] result in
            Util.runInMainThread {
                switch result {
                case .success:
                    self?.hideBusinessLoading()
                case .failure:
                    self?.showServerErrorHint {
                        self?.fetchData()
                    }
                }
            }
        }
    }

    func updateViews() {
        guard let commonInfo = viewModel.commonInfo.value else { return }

        headerView.infoView.isHidden = viewModel.isCall && !viewModel.isValid1v1Call

        // 针对普通详情页与1v1详情页stackview上下边距不一样，在这更改
        let hideCallTypeButtons = !((viewModel.isMeetingEnd && commonInfo.meetingType == .call) || viewModel.tabListItem?.phoneType == .outsideEnterprisePhone)
        if hideCallTypeButtons {
            headerView.contentView.spacing = 24
        } else {
            headerView.contentView.spacing = 20
            headerView.contentView.snp.updateConstraints {
                $0.bottom.equalToSuperview().inset(20)
            }
        }

        let hideShareButton = viewModel.meetingNumber?.isEmpty != false || !viewModel.isMeetingOngoing
        shareButton.isHidden = hideShareButton
    }

    private func add(contentView view: UIView) {
        stackView.addArrangedSubview(view)
        view.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            if view === footerView {
                make.height.equalTo(Display.pad ? 20 : 8)
            }
        }
    }

    private func updateScrollView(width: CGFloat) {
        let isCardMode = viewModel.globalDependency.splitDisplayMode(for: self) == .allVisible
        let inset = isCardMode ? max(36 * width / 749, 16) : 0
        scrollView.snp.updateConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(isCardMode ? 16 : 0)
        }
        stackView.snp.updateConstraints { (make) in
            make.left.right.equalTo(view).inset(inset)
        }

        stackView.spacing = isCardMode ? 16 : 8
        itemViews.forEach {
            $0.layer.cornerRadius = isCardMode ? 4 : 0
        }

        businessLoadingView.backgroundColor = isCardMode ? UIColor.ud.N50 : UIColor.ud.N50
    }

    func showBusinessLoading() {
        scrollView.backgroundColor = .ud.N50
        setupBusinessLoading()
        businessLoadingView.showLoading()
    }

    // 请求数据时无网络提示
    func showNoNetworkHint(tappedAction: (() -> Void)?) {
        scrollView.backgroundColor = .ud.N50
        setupBusinessLoading()
        businessLoadingView.showFailed { [weak self] in
            self?.showBusinessLoading()
            tappedAction?()
        }
    }

    // 请求数据时服务接口异常
    func showServerErrorHint(tappedAction: (() -> Void)?) {
        scrollView.backgroundColor = .ud.N50
        setupBusinessLoading()
        businessLoadingView.showFailed { [weak self] in
            self?.showBusinessLoading()
            tappedAction?()
        }
    }

    func hideBusinessLoading() {
        // nolint-next-line: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            self?.businessLoadingView.hideLoading()
            self?.scrollView.backgroundColor = .ud.bgFloat
        }
    }

    private func setupBusinessLoading() {
        let topOffset = UIApplication.shared.statusBarFrame.height + (navigationController?.navigationBar.intrinsicContentSize.height ?? 0)
        if businessLoadingView.superview == nil {
            view.addSubview(businessLoadingView)
            businessLoadingView.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.centerY.equalToSuperview().offset(-topOffset / 2)
                maker.height.equalTo(156)
                maker.width.equalTo(240)
            }
        }
        view.bringSubviewToFront(businessLoadingView)
    }

    @objc func didTapUserName(_ notification: Notification) {
        guard let userID = notification.userInfo?["userID"] as? String else { return }
        guard let commonInfo = viewModel.commonInfo.value else { return }
        MeetTabTracks.trackMeetTabDetailOperation(.clickUserLink, isOngoing: commonInfo.meetingStatus == .meetingOnTheCall, isCall: commonInfo.meetingType == .call)
        viewModel.handleAvatarTapped(userID: userID)
    }

    @objc func didShare() {
        guard let commonInfo = viewModel.commonInfo.value, let meetingID = viewModel.meetingID else {
            return
        }
        MeetTabTracks.trackMeetTabDetailOperation(.clickShare, isOngoing: viewModel.isMeetingOngoing, isCall: commonInfo.meetingType == .call)
        guard commonInfo.canCopyMeetingInfo else {
            Toast.show(I18n.View_MV_MeetingLocked_Toast, on: self.view)
            return
        }
        viewModel.tabViewModel.router?.shareMeetingCard(meetingId: meetingID, from: self) { [weak self] in
                return self?.viewModel.commonInfo.value?.canCopyMeetingInfo == true
            }
    }

    @objc func didTapBackButton() {
        MeetTabTracks.trackClickClose()
        doBack()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            scrollView.contentOffset.y = 0
        }
    }
}

extension MeetingDetailViewController: MeetingDetailCommonInfoObserver, MeetingDetailHistoryInfoObserver {
    func didReceive(data: TabHistoryCommonInfo) {
        updateViews()
    }

    func didReceive(data: [HistoryInfo]) {
        updateViews()
    }
}

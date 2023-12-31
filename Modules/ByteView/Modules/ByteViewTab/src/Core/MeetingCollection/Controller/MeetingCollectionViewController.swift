//
//  MeetingCollectionViewController.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/6/7.
//

import Foundation
import ByteViewUI
import ByteViewCommon
import RxSwift
import UIKit
import UniverseDesignColor
import FigmaKit
import ByteViewNetwork
import UniverseDesignIcon

final class MeetingCollectionViewController: VMViewController<MeetingCollectionViewModel> {

    var preloadEnabled: Bool = true
    var preloadBag: DisposeBag = DisposeBag()
    var preloadWorkItem: DispatchWorkItem?

    let historyDataSource = MeetTabHistoryDataSource()
    var historyLoadMoreBag = DisposeBag()

    var naviBar = MeetingCollectionNavigationBar()
    var backgroundView = UIView()
    lazy var backgroundImageView: UIImageView = {
        let backgroundImageView = UIImageView()
        backgroundImageView.contentMode = .scaleAspectFill
        return backgroundImageView
    }()

    lazy var headerView = MeetingCollectionHeader(userId: viewModel.userId)
    lazy var footerView = MeetingCollectionFooter()
    var tableViewBackgroundView = UIView()
    lazy var tabResultView: MeetTabResultView = MeetTabResultView(frame: .zero)
    let historyRefreshAnimator = RefreshAnimator(frame: .zero)
    var historyLoadMoreAnimator: RefreshAnimator {
        return RefreshAnimator(frame: .zero)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isNavigationBarHidden = true
        viewModel.isRegularGetter = { [weak self] in
            return self?.traitCollection.isRegular ?? false
        }
        configNaviBar()
        configTableView()
        configLinkLabel()
        setupHistory()

        viewModel.loadData()

        MeetTabTracks.trackEnterMeetingCollection(isAIType: viewModel.collectionType == .ai)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            self?.configHeaderView()
            self?.updateBackgroundColor()
            self?.updateLayout()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configHeaderView()
        updateBackgroundColor()
    }

    var lastBounds: CGRect?
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard tabResultView.tableView.bounds != lastBounds else { return }
        lastBounds = tabResultView.tableView.bounds
        configHeaderView()
        DispatchQueue.main.async {
            self.updateBackgroundColor()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func bindViewModel() {
        super.bindViewModel()

        viewModel.collectionObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
            self?.naviBar.bindViewModel(collection: $0)
            self?.headerView.bindViewModel($0)
        }).disposed(by: rx.disposeBag)

        viewModel.monthLimitObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
            self?.footerView.bindViewModel(monthLimit: $0)
        }).disposed(by: rx.disposeBag)
    }

    func configTableView() {
        tabResultView.tableView.register(MeetingCollectionTableViewCell.self, forCellReuseIdentifier: MeetingCollectionTableViewCell.cellIdentifier)
        tabResultView.tableView.register(MeetingCollectionMonthTableViewCell.self, forCellReuseIdentifier: String(describing: MeetingCollectionMonthTableViewCell.self))
        tabResultView.tableView.register(MeetingCollectionYearTableViewCell.self, forCellReuseIdentifier: String(describing: MeetingCollectionYearTableViewCell.self))

        MeetTabHistoryDataSource.configHeaderView(tabResultView.tableView)
        tabResultView.tableView.register(MeetingCollectionPadSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: String(describing: MeetingCollectionPadSectionHeaderView.self))
        tabResultView.tableView.register(MeetingCollectionPadLoadMoreSectionFooterView.self, forHeaderFooterViewReuseIdentifier: String(describing: MeetingCollectionPadLoadMoreSectionFooterView.self))


        tabResultView.backgroundColor = .clear
        tabResultView.tableView.tableHeaderView = headerView
        tabResultView.tableView.tableFooterView = footerView
        tableViewBackgroundView.backgroundColor = UIColor.ud.bgBody

        addHistoryLoadMore()
        addHistoryRefreshBar()
        addLoadError([viewModel.historyDataSource], result: tabResultView)
    }

    func configNaviBar() {
        naviBar.backButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: rx.disposeBag)
    }

    func configHeaderView() {
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: headerView.calculateHeight())
        let totalCellHeight = CGFloat(viewModel.historyDataSource.current.count) * 78.0
        let headerHeight = headerView.frame.height + 8.0
        let estimatedFooterHeight = footerView.calculateHeight()
        if !traitCollection.isRegular,
           headerHeight + totalCellHeight + estimatedFooterHeight <= view.bounds.height {
            let footerViewHeight = view.bounds.height - totalCellHeight - headerView.frame.height
            footerView.isTopConstraint = false
            footerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: footerViewHeight)
        } else {
            footerView.isTopConstraint = true
            footerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: footerView.calculateHeight())
        }
        tabResultView.tableView.reloadData()
        updateTableViewBackgroundViewHeight()
    }

    func updateTableViewBackgroundViewHeight(_ offset: CGFloat = 0) {
        if traitCollection.isRegular { return }
        let y = tableViewBackgroundView.frame.origin.y
        guard tableViewBackgroundView.frame.isEmpty ||
                y > tabResultView.tableView.contentSize.height - offset || // 下边界
                y < headerView.frame.height + offset || // 上边界
                tableViewBackgroundView.frame.size.width != view.bounds.width else {
            return
        }
        var newY = max(0, tabResultView.tableView.contentSize.height - offset)
        newY = min(view.bounds.height, newY)
        tableViewBackgroundView.frame = CGRect(x: 0,
                                               y: newY,
                                               width: view.bounds.width,
                                               height: view.bounds.height)
    }

    func updateBackgroundColor() {
        backgroundImageView.alpha = 1.0
        let direction: GradientDirection = traitCollection.isRegular ? .topToBottom : .rightToLeft
        var colorSet: [UIColor] = viewModel.bgColorSet
        if #available(iOS 12.0, *), traitCollection.userInterfaceStyle == .dark {
            backgroundImageView.alpha = viewModel.bgAlphaDark
            colorSet = viewModel.bgDarkColorSet
        }
        backgroundView.backgroundColor = UIColor.fromGradientWithDirection(direction, frame: backgroundView.frame, colors: colorSet)
        backgroundImageView.image = viewModel.bgImage
        tableViewBackgroundView.isHidden = traitCollection.isRegular
        backgroundView.setNeedsLayout()
    }

    func updateLayout() {
        if traitCollection.isRegular {
            backgroundImageView.snp.remakeConstraints {
                if viewModel.collectionType == .ai {
                    $0.top.equalToSuperview().offset(-86.0)
                    $0.right.equalToSuperview()
                } else {
                    $0.top.right.equalToSuperview()
                }
                $0.width.equalTo(650.0)
                $0.height.equalTo(380.0)
            }
            naviBar.snp.remakeConstraints {
                $0.left.top.right.equalToSuperview()
                $0.height.equalTo(84.0)
            }
        } else {
            backgroundImageView.snp.remakeConstraints {
                $0.top.equalToSuperview()
                $0.right.equalToSuperview().offset(62.0)
                $0.width.equalTo(438.0)
                $0.height.equalTo(256.0)
            }
            naviBar.snp.remakeConstraints {
                $0.left.top.right.equalToSuperview()
                $0.height.equalTo(88.0)
            }
        }
    }

    func configLinkLabel() {
        tabResultView.linkHandler = { [weak self] in
            self?.viewModel.loadData()
        }
    }

    override func setupViews() {
        view.addSubview(backgroundView)
        view.addSubview(backgroundImageView)
        view.addSubview(tableViewBackgroundView)
        view.addSubview(tabResultView)
        view.addSubview(naviBar)

        backgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        tabResultView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        updateLayout()
    }

    func gotoMeetingDetail(tabListItem: TabListItem) {
        let viewModel = MeetingDetailViewModel(tabViewModel: self.viewModel.tabViewModel,
                                               queryID: tabListItem.meetingID,
                                               tabListItem: tabListItem,
                                               source: .collection)
        let vc = MeetingDetailViewController(viewModel: viewModel)
        if Display.pad {
            self.presentDynamicModal(vc,
                                     regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                     compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension CollectionInfo {

    var tagContent: String {
        switch collectionType {
        case .calendar: return I18n.View_G_EventCollection
        case .ai: return I18n.View_G_SmartCollectFor(collectionTitle)
        default: return ""
        }
    }

    var titleContent: String {
        switch collectionType {
        case .calendar: return I18n.View_G_EventCollectFor(collectionTitle)
        case .ai: return I18n.View_G_SmartCollectFor(collectionTitle)
        default: return ""
        }
    }
}

extension CollectionInfo.CollectionType {
    var typeContent: String {
        switch self {
        case .calendar: return I18n.View_G_EventCollectColor
        case .ai: return I18n.View_G_SmartCollectColor
        default: return ""
        }
    }
}

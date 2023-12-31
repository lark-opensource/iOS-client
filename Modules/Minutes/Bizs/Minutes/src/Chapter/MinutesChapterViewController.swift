//
//  MinutesChapterViewController.swift
//  Minutes
//
//  Created by ByteDance on 2023/9/4.
//

import UIKit
import Foundation
import RoundedHUD
import LarkUIKit
import EENavigator
import MinutesFoundation
import MinutesNetwork
import UniverseDesignToast
import UniverseDesignColor
import LarkContainer
import LarkAccountInterface
import LarkSetting
import UniverseDesignIcon
import FigmaKit

protocol MinutesChapterTabDelegate: AnyObject {
    func didFetchedChapters(_ chapters: [MinutesChapterInfo])
    func getCurTranslationChosenLanguage() -> Language
    func didSelectChapter(_ time: Int)
}


extension MinutesChapterViewController: PagingViewListViewDelegate {
    public func listView() -> UIView {
        return view
    }

    public func listScrollView() -> UIScrollView {
        return self.tableView
    }
}

extension MinutesChapterViewController: MinutesInfoChangedListener {
    public func onMinutesInfoAgendaStatusUpdate(newStatus: NewSummaryStatus, oldStatus: NewSummaryStatus) {
        if (newStatus != oldStatus) {
            fetchSummaries(language: self.delegate?.getCurTranslationChosenLanguage() ?? .default)
        }
    }
}

class MinutesChapterViewController: UIViewController, UserResolverWrapper {
    var scrollDirectionBlock: ((Bool) -> Void)?
    var lastOffset: CGFloat = 0.0

    @ScopedProvider var featureGatingService: FeatureGatingService?
    
    private var isLingoFGEnabled: Bool {
        return featureGatingService?.staticFeatureGatingValue(with: .lingoEnabled) == true
    }

    var passportUserService: PassportUserService? {
        try? userResolver.resolve(assert: PassportUserService.self)
    }
    var dependency: MinutesDependency? {
        return try? userResolver.resolve(assert: MinutesDependency.self)
    }

    weak var delegate: MinutesChapterTabDelegate?

    var didSelectedRow: Int?

    let tracker: MinutesTracker

    var isInTranslationMode: Bool = false

    var isFold: Bool = false
    var items: [MinutesChapterInfo] {
        return isFold ? viewModel.foldData : viewModel.data
    }
    let viewModel: MinutesChapterViewModel

    lazy var header: MinutesAIChapterHeaderView = {
        let v = MinutesAIChapterHeaderView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 84))
        v.text = BundleI18n.Minutes.MMWeb_G_SmartChapters_Title
        v.foldButton.addTarget(self, action: #selector(fold), for: .touchUpInside)
        v.feedbackView.feelgoodAction = {
            [weak self] (name:BusinessTrackerName, params:[String:AnyHashable]) in
            guard let wSelf = self else { return }
            wSelf.sendFeelgood(name, params)
        }
        v.feedbackView.clickAction = {
            [weak self] (isLiked:Bool, isChecked:Bool) in
            guard let wSelf = self else { return }
            wSelf.tracker.tracker(name: .detailClick, params: ["click": isLiked ? "like" : "dislike", "is_checked":isChecked ? "true":"false", "content_type": "agenda"])
        }
        return v
    }()

    lazy var loadingView: MinutesSummaryLoadingContainerView = {
        return MinutesSummaryLoadingContainerView()
    }()

    lazy var emptyView: MinutesSummaryEmptyContainerView = {
        let view = MinutesSummaryEmptyContainerView()
        view.text = BundleI18n.Minutes.MMWeb_G_MeetingTooShortNoSmartChaps_Desc
        return view
    }()

    lazy var tableView: MinutesTableView = {
        let tableView = MinutesTableView(frame: CGRect.zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        if #available(iOS 13.0, *) {
            tableView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(MinutesChapterCell.self, forCellReuseIdentifier: MinutesChapterCell.description())
        tableView.tableHeaderView = header

        let footer = MinutesAIFooterView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 63))
        tableView.tableFooterView = footer

        return tableView
    }()

    var auroraView: AuroraView?

    private lazy var refreshHeader: MinutesRefreshHeaderAnimator = MinutesRefreshHeaderAnimator(frame: .zero)

    let userResolver: UserResolver

    let player: MinutesVideoPlayer
    let minutes: Minutes

    var layoutWidth: CGFloat = 0 {
        didSet {
            guard Display.pad else { return }
            auroraView?.frame = CGRect(x: 10, y: 20 - tableView.contentOffset.y, width: layoutWidth - 20, height: view.bounds.height)
        }
    }

    public init(resolver: UserResolver, minutes: Minutes, player: MinutesVideoPlayer) {
        self.userResolver = resolver
        self.minutes = minutes
        self.player = player
        self.viewModel = MinutesChapterViewModel(minutes: minutes, userResolver: resolver, player: player)
        self.tracker = MinutesTracker(minutes: minutes)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.minutes.info.listeners.addListener(self)

        view.backgroundColor = UIColor.ud.bgBody

        if let colorMain = UDColor.AIPrimaryFillDefault(ofSize: CGSize(width: 144, height: 144)), let colorSub = UDColor.AIPrimaryFillDefault(ofSize: CGSize(width: 332, height: 156)), let colorReflection = UDColor.AIPrimaryFillDefault(ofSize: CGSize(width: 144, height: 144)) {
            let auroraView = getAuroraViewView(auroraColors: (colorMain, colorSub, colorReflection),
                                               auroraOpacity: 0.1)
            auroraView.layer.cornerRadius = 10

            auroraView.layer.masksToBounds = true

            self.auroraView = auroraView

            view.addSubview(auroraView)

            auroraView.frame = CGRect(x: 10, y: 20, width: layoutWidth - 20, height: view.bounds.height)
        }


        tableView.es.addPullToRefresh(animator: refreshHeader) { [weak self] in
            guard let self = self else { return }
            self.fetchSummaries(language: self.delegate?.getCurTranslationChosenLanguage() ?? .default, forceRefresh: true, completionHandler: { [weak self] _ in
                self?.tableView.es.stopPullToRefresh()
            })
        }

        view.addSubview(tableView)
        view.addSubview(loadingView)
        view.addSubview(emptyView)

        tableView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }

        loadingView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        emptyView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }

        showLoadingView(true)
        fetchSummaries(language: self.delegate?.getCurTranslationChosenLanguage() ?? .default)

        viewModel.reload = { [weak self] time in
            self?.tableView.reloadData()
            self?.delegate?.didSelectChapter(time)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard Display.pad else { return }
        auroraView?.frame = CGRect(x: 10, y: 20 - tableView.contentOffset.y, width: layoutWidth - 20, height: view.bounds.height)
    }

    func fetchSummaries(language: Language? = nil, forceRefresh: Bool = false, completionHandler: ((Bool) -> Void)? = nil) {
        viewModel.fetchSummaries(language: language, completionHandler: { [weak self] success in
            guard let self = self else { return }
            if success {
                self.isInTranslationMode = (language != nil) && language != .default
                self.header.feedbackView.reset()
                self.tableView.reloadData()

                self.showLoadingView(self.viewModel.minutes.info.agendaStatus != .complete)
                if self.viewModel.minutes.info.agendaStatus == .complete {
                    self.showEmptyView(self.items.isEmpty == true)
                }
                self.delegate?.didFetchedChapters(self.items)

                if forceRefresh {
                    self.viewModel.clearDictCache()
                }
                self.queryVisibleCellDict()
            }
            completionHandler?(success)
        })
    }


    @objc func fold() {
        isFold = !isFold
        header.foldButton.transform = header.foldButton.transform.rotated(by: .pi)
        self.tableView.reloadData()
    }

    private func showLoadingView(_ show: Bool) {
        emptyView.isHidden = true
        loadingView.isHidden = !show
    }

    private func showEmptyView(_ show: Bool) {
        loadingView.isHidden = true
        emptyView.isHidden = !show
    }

    private func getAuroraViewView(auroraColors: (UIColor, UIColor, UIColor), auroraOpacity: CGFloat) -> AuroraView {
        let auroraView = AuroraView(config: .init(
            mainBlob: .init(color: auroraColors.0, frame: CGRect(x: -44, y: -26, width: 168, height: 104), opacity: 1),
            subBlob: .init(color: auroraColors.1, frame: CGRect(x: -32, y: -131, width: 284, height: 197), opacity: 1),
            reflectionBlob: .init(color: auroraColors.2, frame: CGRect(x: 122, y: -71, width: 248, height: 129), opacity: 1)
        ))
        auroraView.blobsOpacity = auroraOpacity
        return auroraView
    }

    func queryVisibleCellDict() {
        guard isLingoFGEnabled && viewModel.minutes.isLingoOpen else { return }
        guard let visibleIndexPath = tableView.indexPathsForVisibleRows else { return }
        let rows = visibleIndexPath.map({$0.row})
        viewModel.queryDict(rows: rows, completion: { [weak self] in
            self?.tableView.reloadData()
        })
    }
}

extension MinutesChapterViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesChapterCell.description(), for: indexPath)
                as? MinutesChapterCell else { return UITableViewCell() }
        cell.setInfo(items[indexPath.row], width: self.tableView.frame.width, isInTranslationMode: isInTranslationMode)
        cell.index = indexPath.row
        if indexPath.row == 0 {
            cell.updateUI(isFirst: true, isLast: false)
        } else if indexPath.row == items.count - 1 {
            cell.updateUI(isFirst: false, isLast: true)
        } else {
            cell.updateUI(isFirst: false, isLast: false)
        }
        cell.didTextTappedBlock = { [weak self] phrase in
            if let phrase = phrase, let dictId = phrase.dictId {
                MinutesLogger.detail.info("phrase chapter: \(phrase)")
                self?.dependency?.messenger?.showEnterpriseTopic(abbrId: dictId, query: phrase.name)

                self?.tracker.tracker(name: .detailClick, params: ["click": "lingo"])
            }

            self?.viewModel.selectItem(indexPath.row)

            self?.tracker.tracker(name: .detailClick, params: ["click": "agenda", "target": "none"])
        }
        return cell
    }
}

extension MinutesChapterViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastOffset = scrollView.contentOffset.y
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if lastOffset > scrollView.contentOffset.y {
            scrollDirectionBlock?(false)
        } else if lastOffset < scrollView.contentOffset.y {
            scrollDirectionBlock?(true)
        }
        auroraView?.frame = CGRect(x: 10, y: 20 - scrollView.contentOffset.y, width: layoutWidth - 20, height: view.bounds.height)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        queryVisibleCellDict()
    }
}

extension MinutesChapterViewController {
    func noticeButtonClicked() {
        fetchSummaries(language: self.delegate?.getCurTranslationChosenLanguage() ?? .default, forceRefresh: true)
    }
    
    func sendFeelgood(_ name:BusinessTrackerName, _ params:[String:AnyHashable]) {
        tracker.tracker(name:name, params:params)
    }
}

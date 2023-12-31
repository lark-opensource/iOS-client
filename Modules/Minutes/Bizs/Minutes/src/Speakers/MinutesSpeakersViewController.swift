//
//  MinutesSpeakersViewController.swift
//
//
//  Created by ByteDance on 2023/8/29.
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
import LarkAccountInterface
import LarkSetting
import UniverseDesignIcon
import LarkContainer

protocol MinutesSpeakersTabDelegate: AnyObject {
    func addSpeakerDetail(_ module: MinutesSpeakerDetailModule, mask: UIView)
    func selectSpeaker(_ speakerName: String, time: CGFloat, isEnd: Bool)
    func reloadSegment(_ count: Int)
    func getCurrentTranslationChosenLanguage() -> Language
    func showOriginalSpeakerSummary(attributedString: NSAttributedString)
}

extension MinutesSpeakersViewController: PagingViewListViewDelegate {
    public func listView() -> UIView {
        return view
    }

    public func listScrollView() -> UIScrollView {
        return self.tableView
    }
}

class MinutesSpeakersViewController: UIViewController, UserResolverWrapper {
    var passportUserService: PassportUserService? {
        try? userResolver.resolve(assert: PassportUserService.self)
    }
    @ScopedProvider var featureGatingService: FeatureGatingService?
    var dependency: MinutesDependency? {
        return try? userResolver.resolve(assert: MinutesDependency.self)
    }

    private var isLingoFGEnabled: Bool {
        return featureGatingService?.staticFeatureGatingValue(with: .lingoEnabled) == true
    }

    var lastTime: Date?

    var curMatchedIndex: Int?
    var isLastExceed: Bool = false
    var module: MinutesSpeakerDetailModule?
    var mask: UIView?

    var didSelectedRow: Int?
    var curSpeakerInfo: MinutesSpeakerTimelineInfo?
    var curPlayIndex: Int?

    weak var delegate: MinutesSpeakersTabDelegate?

    var items: [MinutesSpeakerTimelineInfo] = []

    var scrollDirectionBlock: ((Bool) -> Void)?
    var lastOffset: CGFloat = 0.0

    let tracker: MinutesTracker
    lazy var loadingView: MinutesSummaryLoadingContainerView = {
        return MinutesSummaryLoadingContainerView()
    }()

    lazy var emptyView: MinutesSummaryEmptyContainerView = {
        let view = MinutesSummaryEmptyContainerView()
        view.text = BundleI18n.Minutes.MMWeb_G_NobodySpeaks_Desc
        return view
    }()

    var isFold: Bool = true
    lazy var tableView: MinutesTableView = {
        let tableView = MinutesTableView(frame: CGRect.zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        if #available(iOS 13.0, *) {
            tableView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        tableView.register(MinutesSpeakersCell.self, forCellReuseIdentifier: MinutesSpeakersCell.description())
        if viewModel.showSpeakerSummary {
            let header = MinutesSpeakerHeaderView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 40))
            header.foldAction = { [weak self, weak header] in
                guard let self = self, let header = header else { return }
                self.isFold = !self.isFold
                header.feedbackView.isHidden = self.isFold
                header.foldButton.image = UDIcon.getIconByKey(self.isFold ? .downBottomOutlined : .upTopOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 16, height: 16))
                header.textLabel.text = self.isFold ? BundleI18n.Minutes.MMWeb_G_ShowSpeakerSummary_Button : BundleI18n.Minutes.MMWeb_G_HideSpeakerSummary_Button
                self.tableView.reloadData()

                var stayDuration: TimeInterval = 0

                let curTabTime = Date()
                if let last = lastTime {
                    let duration = curTabTime.timeIntervalSince(last)
                    stayDuration = duration * 1000
                }

                self.tracker.tracker(name: .detailClick, params: ["click": self.isFold ? "fold_speaker_summary" : "show_speaker_summary", "duration": String(format: "%.2f", stayDuration)])
            }
            header.feedbackView.feelgoodAction = {
                [weak self] (name:BusinessTrackerName, params:[String:AnyHashable]) in
                guard let wSelf = self else { return }
                wSelf.tracker.tracker(name:name, params:params)
            }
            header.feedbackView.clickAction = {
                [weak self] (isLiked:Bool, isChecked:Bool) in
                guard let wSelf = self else { return }
                wSelf.tracker.tracker(name: .detailClick, params: ["click": isLiked ? "like" : "dislike", "is_checked":isChecked ? "true":"false", "content_type": "speaker_summary"])
            }

            header.feedbackView.isHidden = self.isFold
            tableView.tableHeaderView = header
        }
        return tableView
    }()

    var isNewPan: Bool = false

    let userResolver: UserResolver

    let minutes: Minutes
    let viewModel: MinutesSpeakersViewModel
    let player: MinutesVideoPlayer
    // 播放事件 -> 查看select是否为空  不为空则到第一个播放
    public init(resolver: UserResolver, minutes: Minutes, player: MinutesVideoPlayer) {
        self.userResolver = resolver
        self.player = player
        self.minutes = minutes
        self.viewModel = MinutesSpeakersViewModel(resolver: resolver,  minutes: minutes)
        self.tracker = MinutesTracker(minutes: minutes)
        super.init(nibName: nil, bundle: nil)
        self.player.listeners.addListener(self)

        lastTime = Date()

        NotificationCenter.default.addObserver(self, selector: #selector(didTouchedProgressBar), name: .didTouchedProgressBar, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func didTouchedProgressBar() {
        self.items = self.items.enumerated().map { (_, i) in
            return MinutesSpeakerTimelineInfo(participant: i.participant, speakerTimeline: i.speakerTimeline, speakerDuration: i.speakerDuration, videoDuration: i.videoDuration, percent: i.percent, color: i.color, thumbInfo: MinutesSpeakerTimelineInfo.Thumb(show: false, index: 0, progress: 0), summaryStatus: i.summaryStatus, content: i.content, isInTranslateMode: i.isInTranslateMode, dPhrases: i.dPhrases)
        }
        self.tableView.reloadData()
        self.clear()
    }

    private func clear() {
        didSelectedRow = nil
        curSpeakerInfo = nil
    }

    public func onSpeakerDataUpdate(language: Language, reload: Bool = true, callback: (() -> Void)? = nil) {
        viewModel.onSpeakerDataUpdate(language: language, reload: reload, callback: callback)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.minutes.info.listeners.addListener(self)

        view.backgroundColor = UIColor.ud.bgBody

        view.addSubview(tableView)
        view.addSubview(loadingView)
        view.addSubview(emptyView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        showLoadingView(true)

        queryVisibleCellDict()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.viewModel.onDataUpdated = { [weak self] in
            self?.items = self?.viewModel.speakersTimeline ?? []
            self?.tableView.reloadData()
            self?.showEmptyView(self?.items.isEmpty == true)
            if let count = self?.items.count, count != 0 {
                self?.delegate?.reloadSegment(count)
            }
            self?.queryVisibleCellDict()
        }
        self.viewModel.addSpeakerObserver(speakerContainerWidth: self.view.bounds.width - 40, language: self.delegate?.getCurrentTranslationChosenLanguage() ?? .default)
    }

    private func showLoadingView(_ show: Bool) {
        emptyView.isHidden = true
        loadingView.isHidden = !show
    }

    private func showEmptyView(_ show: Bool) {
        loadingView.isHidden = true
        emptyView.isHidden = !show
    }

    func queryVisibleCellDict() {
        guard isLingoFGEnabled && viewModel.minutes.isLingoOpen else { return }

        guard let visibleIndexPath = tableView.indexPathsForVisibleRows else { return }
        let rows = visibleIndexPath.map({$0.row})
        viewModel.queryDict(rows: rows, completion: { [weak self] in
            guard let self = self else { return }
            self.items = self.viewModel.speakersTimeline 
            self.tableView.reloadData()
        })
    }
}

extension MinutesSpeakersViewController: MinutesInfoChangedListener {
    public func onMinutesInfoSpeakerStatusUpdate(newStatus: NewSummaryStatus, oldStatus: NewSummaryStatus) {

        if (newStatus != oldStatus) {
            self.viewModel.onSpeakerDataUpdate()
        }
    }
}


extension MinutesSpeakersViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesSpeakersCell.description(), for: indexPath)
                as? MinutesSpeakersCell else { return UITableViewCell() }
        cell.setInfo(items[indexPath.row], width: tableView.frame.width)
        cell.isFold = isFold
        cell.menuOriginalBlock = { [weak self] in
            guard let self = self else { return }
            self.showOriginalTextView(indexPath.row)
        }
        cell.panBegan = { [weak self] (index) in
            guard let self = self else { return }
            self.isNewPan = true
        }
        cell.showSpeakerDetail = { [weak self] in
            guard let self = self else { return }
            self.showDetailModule(indexPath, index: nil)
        }
        cell.openProfileBlock = { [weak self] userId in
            guard let self = self, let userId = userId else { return }
            MinutesProfile.personProfile(chatterId: userId, from: self, resolver: self.userResolver)
        }
        // index: 单个说话人点击的原始时间轴index
        cell.updateProgress = { [weak self] (index, progress, finished, tProgress, playTime, width) in
            guard let self = self else { return }
            if !finished {
                self.player.stop()
            }

            if finished == true || self.isNewPan == true {
                self.items = self.items.enumerated().map { (idx, i) in
                    return MinutesSpeakerTimelineInfo(participant: i.participant, speakerTimeline: i.speakerTimeline, speakerDuration: i.speakerDuration, videoDuration: i.videoDuration, percent: i.percent, color: i.color, thumbInfo: MinutesSpeakerTimelineInfo.Thumb(show: idx == indexPath.row, index: index, progress: progress), summaryStatus: i.summaryStatus, content: i.content, isInTranslateMode: i.isInTranslateMode, dPhrases: i.dPhrases)
                }
                if self.isNewPan == true {
                    // 不刷新拖动的item，防止拖动被打断
                    var indexPaths = self.tableView.indexPathsForVisibleRows
                    indexPaths?.removeAll(where: { $0.row == indexPath.row } )

                    if let path = indexPaths {
                        self.tableView.reloadRows(at: path, with: .none)
                    }
                } else {
                    self.tableView.reloadData()
                }
                self.isNewPan = false
            }
            if finished {
                self.delegate?.selectSpeaker("", time: 0, isEnd: true)

                self.didSelectedRow = indexPath.row
                self.handleSpeakerPlay(playTime / 1000)

                self.tracker.tracker(name: .playbarClick, params: ["click": "speaker_detail"])
            } else {
                let speaker = self.items[indexPath.row]
                self.delegate?.selectSpeaker(speaker.participant.userName, time: playTime, isEnd: false)
                self.didSelectedRow = nil
            }
            if finished {
                if width <= 22 {
                    self.showDetailModule(indexPath, index: index)
                }
            }
        }
        cell.didTextTappedBlock = { [weak self] phrase in
            if let phrase = phrase, let dictId = phrase.dictId {
                MinutesLogger.detail.info("phrase speaker: \(phrase)")
                self?.dependency?.messenger?.showEnterpriseTopic(abbrId: dictId, query: phrase.name)
                self?.tracker.tracker(name: .detailClick, params: ["click": "lingo"])
            }
        }

        return cell
    }

    func showOriginalTextView(_ row: NSInteger) {
        guard viewModel.originSpeakersTimeline.indices.contains(row) else {
            return
        }
        let info = viewModel.originSpeakersTimeline[row]

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 22
        paragraphStyle.minimumLineHeight = 22

        let content = info.content ?? ""
        let text = NSAttributedString(string: content,
                                  attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .regular),
                                               .foregroundColor: UIColor.ud.textCaption,
                                               .paragraphStyle: paragraphStyle])
        self.delegate?.showOriginalSpeakerSummary(attributedString: text)
    }

    func showDetailModule(_ indexPath: IndexPath, index: Int?) {
        self.didSelectedRow = indexPath.row

        self.module?.removeFromSuperview()
        self.mask?.removeFromSuperview()

        let module = MinutesSpeakerDetailModule(player: self.player, resolver: self.userResolver, minutes: minutes)
        module.openProfileBlock = { [weak self] userId in
            guard let self = self, let userId = userId else { return }
            MinutesProfile.personProfile(chatterId: userId, from: self, resolver: self.userResolver)
        }
        let mask = UIButton()
        mask.addTarget(self, action: #selector(closeModule), for: .touchUpInside)
        mask.backgroundColor = UIColor.ud.bgMask
        self.mask = module

        self.delegate?.addSpeakerDetail(module, mask: mask)
        module.configure(with: self.items[indexPath.row], index: index)
        self.module = module
    }

    @objc func closeModule() {
        self.module?.removeFromSuperview()
    }
}

extension MinutesSpeakersViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        queryVisibleCellDict()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastOffset = scrollView.contentOffset.y
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if lastOffset > scrollView.contentOffset.y {
            scrollDirectionBlock?(false)
        } else if lastOffset < scrollView.contentOffset.y {
            scrollDirectionBlock?(true)
        }
    }
}

extension MinutesSpeakersViewController: MinutesVideoPlayerListener {
    func videoEngineDidLoad() {

    }
    func videoEngineDidChangedStatus(status: PlayerStatusWrapper) {

    }
    func videoEngineDidChangedPlaybackTime(time: PlaybackTime) {
        guard didSelectedRow != nil else {
            return
        }
        if isLastExceed == true {
            if let row = self.didSelectedRow, self.items.indices.contains(row), let startTime = self.items[row].speakerTimeline.first?.startTime {
                self.handleSpeakerPlay(CGFloat(startTime / 1000))
            }
            isLastExceed = false
            return
        }

        let playTime = Int(CGFloat(time.time) * 1000)

        if let curSpeakerInfo = curSpeakerInfo {
            let timeline = curSpeakerInfo.speakerTimeline

            var matchedIndex: Int?
            if let index = timeline.firstIndex(where: { playTime > $0.startTime && playTime < $0.stopTime } ) {
                matchedIndex = index
            } else if let index = timeline.firstIndex(where: { playTime <= $0.startTime } ) {
                matchedIndex = index
            }

            if let i = matchedIndex {
                if let cur = curPlayIndex, i > cur, timeline.indices.contains(i) {
                    let playTime = timeline[i].startTime
                    handleSpeakerPlay(CGFloat(playTime / 1000))
                }
                curPlayIndex = i
            }
        }
        var matchedSpeakerInfo: MinutesSpeakerTimelineInfo?
        var matchedIdx: Int?

        for (index, speakerInfo) in self.items.enumerated() {
            let timeline = speakerInfo.speakerTimeline
            for (idx, t) in timeline.enumerated() {
                // 匹配到说话人
                if playTime >= t.startTime && playTime <= t.stopTime && index == self.didSelectedRow {
                    let progress = CGFloat(playTime - t.startTime) / CGFloat(t.stopTime - t.startTime)
                    matchedSpeakerInfo = speakerInfo
                    matchedSpeakerInfo?.thumbInfo = MinutesSpeakerTimelineInfo.Thumb(show: true, index: idx, progress: progress)
                    matchedIdx = index
                    break
                }
            }
            if matchedIdx != nil {
                break
            }
        }

        curSpeakerInfo = matchedSpeakerInfo
        if let matchedSpeakerInfo = matchedSpeakerInfo {
            self.items = self.items.enumerated().map { (idx, i) in
                return idx == matchedIdx ? matchedSpeakerInfo : MinutesSpeakerTimelineInfo(participant: i.participant, speakerTimeline: i.speakerTimeline, speakerDuration: i.speakerDuration, videoDuration: i.videoDuration, percent: i.percent, color: i.color, thumbInfo: MinutesSpeakerTimelineInfo.Thumb(show: false, index: 0, progress: 0) , summaryStatus: i.summaryStatus, content: i.content, isInTranslateMode: i.isInTranslateMode, dPhrases: i.dPhrases)
            }
            self.tableView.reloadData()
        }

        isLastExceed = false
        if let row = self.didSelectedRow, self.items.indices.contains(row), let stopTime = self.items[row].speakerTimeline.last?.stopTime {
            if playTime >= stopTime {
                isLastExceed = true
                player.pause()
            }
        }
    }
}

extension MinutesSpeakersViewController {
    func handleSpeakerPlay(_ playTime: CGFloat) {
        player.seekVideoPlaybackTime(TimeInterval(playTime))
    }
}


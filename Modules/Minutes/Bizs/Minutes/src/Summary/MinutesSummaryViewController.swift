//
//  MinutesSummaryViewController.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/5/12.
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
import AudioToolbox
import FigmaKit

protocol MinutesSummaryViewControllerDelegate: AnyObject {
    func showOriginalTextViewBy(summary: UIViewController, attributedString: NSAttributedString)
}

final class MinutesSummaryViewController: UIViewController, UserResolverWrapper {

    var passportUserService: PassportUserService? {
        try? userResolver.resolve(assert: PassportUserService.self)
    }
    @ScopedProvider var featureGatingService: FeatureGatingService?

    private var isLingoFGEnabled: Bool {
        return featureGatingService?.staticFeatureGatingValue(with: .lingoEnabled) == true
    }

    private var viewModel: MinutesSummaryViewModel
    
    private  lazy var feedbackDict : [Int:Bool] = {
        return [:]
    }()

    var dependency: MinutesDependency? {
        return try? userResolver.resolve(assert: MinutesDependency.self)
    }

    let tracker: MinutesTracker

    lazy var loadingView: MinutesSummaryLoadingContainerView = {
        return MinutesSummaryLoadingContainerView()
    }()

    lazy var emptyView: MinutesSummaryEmptyContainerView = {
        let view = MinutesSummaryEmptyContainerView()
        view.text = BundleI18n.Minutes.MMWeb_G_MeetingTooShortNoSummary_Desc
        return view
    }()

    private func getAuroraViewView(auroraColors: (UIColor, UIColor, UIColor), auroraOpacity: CGFloat) -> AuroraView {
        let auroraView = AuroraView(config: .init(
            mainBlob: .init(color: auroraColors.0, frame: CGRect(x: -44, y: -26, width: 168, height: 104), opacity: 1),
            subBlob: .init(color: auroraColors.1, frame: CGRect(x: -32, y: -131, width: 284, height: 197), opacity: 1),
            reflectionBlob: .init(color: auroraColors.2, frame: CGRect(x: 122, y: -71, width: 248, height: 129), opacity: 1)
        ))
        auroraView.blobsOpacity = auroraOpacity
        return auroraView
    }

    lazy var tableView: MinutesTableView = {
        let tableView: MinutesTableView = MinutesTableView(frame: CGRect.zero, style:. grouped)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        if #available(iOS 13.0, *) {
            tableView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.estimatedRowHeight = 110
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(MinutesSummaryTableViewCell.self, forCellReuseIdentifier: MinutesSummaryTableViewCell.description())

        let header = MinutesAIHeaderView(frame: CGRect(x: 0, y: 0, width: view.bounds.width - 20, height: 84))
        header.text = BundleI18n.Minutes.MMWeb_G_MeetingNotesHere_Desc
        header.foldButton.isHidden = true
        tableView.tableHeaderView = header
        
        let footer = MinutesAIFooterView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 63))
        tableView.tableFooterView = footer
        return tableView
    }()

    var videoPlayer: MinutesVideoPlayer?

    private lazy var header: MinutesRefreshHeaderAnimator = MinutesRefreshHeaderAnimator(frame: .zero)

    weak var delegate: MinutesSummaryViewControllerDelegate?

    var scrollDirectionBlock: ((Bool) -> Void)?
    var lastOffset: CGFloat = 0.0

    var layoutWidth: CGFloat = 0

    weak var dataProvider: MinutesSubtitlesViewDataProvider?

    private var currentLanguage: Language = .default
    private var isInTranslationMode: Bool {
        return currentLanguage != .default
    }

    var auroraView: AuroraView?
    let userResolver: UserResolver

    public init(resolver: UserResolver, minutes: Minutes) {
        self.userResolver = resolver
        self.viewModel = MinutesSummaryViewModel(minutes: minutes, userResolver: resolver)
        self.tracker = MinutesTracker(minutes: minutes)
        super.init(nibName: nil, bundle: nil)
        self.viewModel.storeOriginalSummaries(isNeedRequest: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        addContentView()
        
        showLoadingView(viewModel.minutes.info.summaries?.summaryStatus != .complete)
        if viewModel.minutes.info.summaries?.summaryStatus == .complete {
            showEmptyView(viewModel.showEmptyView)
        }
        queryLingo()

        addInfoCallback()
    }


    func queryLingo() {
        if isLingoFGEnabled && viewModel.minutes.isLingoOpen {
            for (section, _) in viewModel.data.enumerated() {
                viewModel.queryDict(with: section) { [weak self] in
                    self?.tableView.reloadData()
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard Display.pad else { return }
        auroraView?.frame = CGRect(x: 10, y: 20 - tableView.contentOffset.y, width: layoutWidth - 20, height: view.bounds.height)
    }
    
    func addContentView() {
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

        tableView.es.addPullToRefresh(animator: header) { [weak self] in
            guard let wSelf = self else { return }
            wSelf.requestNewData(language: wSelf.currentLanguage)
        }
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        tableView.reloadData()

        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func addInfoCallback() {
        viewModel.minutes.info.listeners.addListener(self)
    }
}

extension MinutesSummaryViewController: MinutesInfoChangedListener {
    public func onMinutesInfoSummaryStatusUpdate(newStatus: NewSummaryStatus, oldStatus: NewSummaryStatus) {
        if (newStatus != oldStatus) {
            self.startFetchRequest()
        }
    }
}
// MAKR: - UITableViewDataSource && UITableViewDelegate

extension MinutesSummaryViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.data.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.data[section].values.first?.count ?? 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.clear
        let titleLabel = UILabel()
        containerView.addSubview(titleLabel)

        titleLabel.text = viewModel.data[section].keys.first
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .left
        titleLabel.textColor = UIColor.ud.textCaption
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)

        let topSpace: CGFloat = section == 0 ? 0 : 10
        let itemValue = viewModel.data[section].values.first?.first

        let leftMargin = 16
        let rightMargin = 16
        if itemValue?.isSubsection == true {
            titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            if itemValue?.isSubsectionHeader == true {
                let sectionHeaderTitleLabel = UILabel()

                sectionHeaderTitleLabel.text = itemValue?.subsectionHeaderTitle
                sectionHeaderTitleLabel.numberOfLines = 1
                sectionHeaderTitleLabel.textAlignment = .left
                sectionHeaderTitleLabel.textColor = UIColor.ud.textCaption
                sectionHeaderTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
                containerView.addSubview(sectionHeaderTitleLabel)

                if titleLabel.text?.isEmpty == true {
                    sectionHeaderTitleLabel.snp.makeConstraints { (make) in
                        make.left.equalToSuperview().offset(leftMargin)
                        make.top.equalToSuperview().offset(topSpace)
                        make.bottom.equalToSuperview().offset(-12)
                        make.height.equalTo(20)
                    }
                    titleLabel.snp.makeConstraints { (make) in
                        make.left.equalTo(sectionHeaderTitleLabel)
                        make.right.equalToSuperview().offset(-rightMargin)
                        make.top.equalToSuperview()
                        make.height.equalTo(1)
                    }
                } else {
                    sectionHeaderTitleLabel.snp.makeConstraints { (make) in
                        make.left.equalToSuperview().offset(leftMargin)
                        make.top.equalToSuperview().offset(topSpace)
                        make.height.equalTo(20)
                    }
                    titleLabel.snp.makeConstraints { (make) in
                        make.left.equalTo(sectionHeaderTitleLabel)
                        make.right.equalToSuperview().offset(-rightMargin)
                        make.top.equalTo(sectionHeaderTitleLabel.snp.bottom).offset(12)
                        make.bottom.equalToSuperview().offset(-12)
                        make.height.equalTo(20)
                    }
                }
            } else {
                if titleLabel.text?.isEmpty == true {
                    titleLabel.snp.makeConstraints { (make) in
                        make.left.equalToSuperview()
                        make.right.equalToSuperview().offset(-rightMargin)
                        make.top.equalToSuperview()
                        make.height.equalTo(1)
                    }
                } else {
                    titleLabel.snp.makeConstraints { (make) in
                        make.left.equalToSuperview().offset(leftMargin)
                        make.right.equalToSuperview().offset(-rightMargin)
                        make.top.equalToSuperview().offset(12)
                        make.bottom.equalToSuperview().offset(-12)
                        make.height.equalTo(20)
                    }
                }
            }
        } else {
            // no subsection
            titleLabel.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(leftMargin)
                make.right.equalToSuperview().offset(-rightMargin)
                make.top.equalToSuperview().offset(topSpace)
                make.bottom.equalToSuperview().offset(-12)
                make.height.equalTo(20)
            }
        }
        //当sectionId为（ContentType_Summary_AIMainPoint、ContentType_Summary_AITodo），显示点赞/点踩入口；
        if let array = viewModel.data[section].values.first {
            if let sectionId = array.first?.sectionId {
                if sectionId == MinutesSummaryContentType.AISumary.rawValue || sectionId == MinutesSummaryContentType.AITodo.rawValue {
                let type =  sectionId == MinutesSummaryContentType.AISumary.rawValue ? MinutesFeedbackViewType.sumary : MinutesFeedbackViewType.todo
                var feedbackStatus : MinutesFeedbackStatus = .none
                if let currentStatus = feedbackDict[sectionId] {
                    feedbackStatus = currentStatus ? .checked : .unChecked
                }
                let feedbackView = MinutesFeedbackView(frame: .zero, type: type, likeStatus: feedbackStatus)
                containerView.addSubview(feedbackView)
                
                titleLabel.snp.updateConstraints { (make) in
                    make.right.equalToSuperview().offset(-rightMargin-52)
                }
                    
                feedbackView.snp.makeConstraints { (make) in
                    make.centerY.equalTo(titleLabel)
                    make.right.equalToSuperview().offset(-rightMargin)
                    make.height.equalTo(20)
                    make.width.equalTo(52)
                }

                feedbackView.clickAction = {
                    [weak self] (isLiked:Bool, isChecked:Bool) in
                    guard let wSelf = self else { return }
                    
                    
                    var content_type = "summary"
                    if type == .todo {
                        content_type = "todo"
                    }
                    
                    wSelf.tracker.tracker(name: .detailClick, params: ["click": isLiked ? "like" : "dislike", "is_checked":isChecked ? "true" : "false", "content_type": content_type])
                    
                    if !isChecked {
                        wSelf.feedbackDict[sectionId] = nil
                    } else {
                        wSelf.feedbackDict[sectionId] = isLiked
                    }
                }
                
                feedbackView.feelgoodAction = {
                    [weak self] (name:BusinessTrackerName,params:[String:AnyHashable]) in
                    guard let wSelf = self else { return }
                    wSelf.sendFeelgood(name, params)
                    }
                }
            }
        }
        return containerView
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesSummaryTableViewCell.description(), for: indexPath)
                as? MinutesSummaryTableViewCell else { return UITableViewCell() }
        if let array = viewModel.data[indexPath.section].values.first {
            cell.setData(data: array[indexPath.row],
                         currentUserPermission: viewModel.minutes.info.currentUserPermission,
                         isInTranslationMode: isInTranslationMode,
                         layoutWidth: layoutWidth - 20,
                         passportUserService: passportUserService)
            let contentId: String = array[indexPath.row].contentId
            cell.onClickCheckboxClosure = { [weak self] isChecked, startTime in
                guard let wSelf = self else { return }

                wSelf.tracker.tracker(name: .detailClick, params: ["click": "todo", "target": "none"])

                wSelf.viewModel.requestCheckbox(contentId: contentId, isChecked: isChecked)
                wSelf.viewModel.updateCheckStatus(with: indexPath, isChecked: isChecked)

                if isChecked {
                    if let time = startTime {
                        wSelf.videoPlayer?.seekVideoPlaybackTime(Double(time) / 1000)
                    }
                    AudioServicesPlaySystemSound(1520)
                }
            }
            cell.onClickCheckboxLabel = { [weak self] startTime in
                guard let wSelf = self else { return }
                if let time = startTime {
                    wSelf.videoPlayer?.seekVideoPlaybackTime(Double(time) / 1000)
                }
            }
            cell.onClickUserProfile = { [weak self] userId in
                guard let wSelf = self else { return }

                wSelf.dependency?.messenger?.pushOrPresentPersonCardBody(chatterID: userId, from: wSelf)
            }
            cell.onClickCopyBlock = { [weak self] in
                guard let topVC = self?.userResolver.navigator.mainSceneTopMost else { return }
                UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_CopiedSuccessfully, on: topVC.view)
            }
            cell.onClickSeeOriginText = { [weak self] contentId in
                guard let wSelf = self, let someContentId = contentId else { return }
                wSelf.showOriginalTextView(someContentId)
            }
            cell.didTextTappedBlock = { [weak self] phrase in
                if let phrase = phrase, let dictId = phrase.dictId {
                    MinutesLogger.detail.info("phrase summary: \(phrase)")
                    self?.dependency?.messenger?.showEnterpriseTopic(abbrId: dictId, query: phrase.name)
                    self?.tracker.tracker(name: .detailClick, params: ["click": "lingo"])
                }
            }
        }
        return cell
    }
}

extension MinutesSummaryViewController {

    func noticeButtonClicked() {
        startFetchRequest()
    }

    func enterSearch() {
        if tableView.header == nil { return }
        tableView.es.removeRefreshHeader()
    }

    func exitSearch() {
        if tableView.header != nil { return }
        tableView.es.addPullToRefresh(animator: header) { [weak self] in
            guard let wSelf = self else { return }
            wSelf.requestNewData(language: wSelf.currentLanguage)
        }
    }

    func showOriginalTextView(_ contentId: String) {
        guard let contentString = viewModel.getOriginalSummaryContent(with: contentId) else { return }
        let attributedString = MinutesSummaryTableViewCell.getAttributedString(.text, contentText: contentString, passportUserService: passportUserService, onClickNameAction: {  [weak self] userId in
            guard let wSelf = self else { return }
            wSelf.dependency?.messenger?.pushOrPresentPersonCardBody(chatterID: userId, from: wSelf)
        })

        self.delegate?.showOriginalTextViewBy(summary: self, attributedString: attributedString)
    }
}

extension MinutesSummaryViewController {
    func requestNewData(language: Language) {
        currentLanguage = language

        tableView.visibleCells.forEach { cell in
            guard let cell = cell as? MinutesSummaryTableViewCell else { return }
            cell.hideMenu()
            cell.hideSelectionDot()
        }

        startFetchRequest()
    }

    private func startFetchRequest() {
        viewModel.minutes.info.fetchSummaries(catchError: true, language: currentLanguage, completionHandler: { [weak self] result in
            guard let wSelf = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    wSelf.tableView.es.stopPullToRefresh()

                    wSelf.showLoadingView(data.summaryStatus != .complete)

                    wSelf.viewModel.minutes.info.summaries = data
                    wSelf.viewModel.parseSummariesData()
                    if data.summaryStatus == .complete {
                        wSelf.showEmptyView(wSelf.viewModel.showEmptyView)
                    }
                    wSelf.feedbackDict.removeAll()

                    wSelf.tableView.becomeFirstResponder()
                    wSelf.tableView.reloadData()
                    wSelf.queryLingo()
                case .failure:break
                }
            }
        })
    }

    private func showLoadingView(_ show: Bool) {
        emptyView.isHidden = true
        loadingView.isHidden = !show
    }

    private func showEmptyView(_ show: Bool) {
        emptyView.isHidden = !show
    }
}

extension MinutesSummaryViewController: UIScrollViewDelegate {
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

    func scrollToDetination(with contentId: String) {
        var isFind: Bool = false
        for (sectionIndex, sectionList) in viewModel.data.enumerated() {
            if let contentList = sectionList.values.first {
                for (contentIndex, content) in contentList.enumerated() where content.contentId == contentId {
                    isFind = true
                    let indexPath = IndexPath(row: contentIndex, section: sectionIndex)
                    if tableView.indexPathExists(indexPath: indexPath) {
                        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                    }
                    break
                }
            }
        }
        if !isFind {
            guard let topVC = userResolver.navigator.mainSceneTopMost else { return }
            UDToast.showFailure(with: BundleI18n.Minutes.MMWeb_G_AtMentionContentDeleted_Toast, on: topVC.view, delay: 2)
        }
    }
}

extension MinutesSummaryViewController: PagingViewListViewDelegate {
    public func listView() -> UIView {
        return view
    }

    public func listScrollView() -> UIScrollView {
        return self.tableView
    }
}

extension MinutesSummaryViewController {
    private func sendFeelgood(_ name:BusinessTrackerName, _ params:[String:AnyHashable]) {
        tracker.tracker(name: name, params: params)
    }
}

class MinutesSummaryHeaderView: UIView {
    lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.image = UDIcon.getIconByKey(.myaiColorful, size: CGSize(width: 14, height: 14))
        return iconView
    }()

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.numberOfLines = 0
        textLabel.textColor = UIColor.ud.textPlaceholder
        textLabel.font = .systemFont(ofSize: 12, weight: .regular)
        textLabel.text = BundleI18n.Minutes.MMWeb_G_Transcribe_Disclaimer
        return textLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(iconView)
        addSubview(textLabel)

        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(14)
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(textLabel).offset(3)
        }
        textLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(4)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MinutesSummaryLoadingContainerView: UIView {
    let loadingView = MinutesSummaryLoadingView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBody
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-30)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MinutesSummaryLoadingView: UIView {
    lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.loadingOutlined, iconColor: UIColor.ud.primaryContentDefault)
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(.pi * 2.0)
        rotateAnimation.duration = 1.0
        rotateAnimation.isCumulative = true
        rotateAnimation.repeatCount = .greatestFiniteMagnitude
        rotateAnimation.isRemovedOnCompletion = false

        imageView.layer.add(rotateAnimation, forKey: "NetworkNotReachableRotationAnimation")
        return imageView
    }()

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.numberOfLines = 0
        textLabel.textColor = UIColor.ud.textPlaceholder
        textLabel.text = BundleI18n.Minutes.MMWeb_G_WorkingonIt_Tooltip
        textLabel.textAlignment = .center
        textLabel.font = .systemFont(ofSize: 14)
        return textLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(iconView)
        addSubview(textLabel)

        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        textLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(8)
            make.centerX.equalTo(iconView)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MinutesSummaryEmptyContainerView: UIView {
    let emptyView = MinutesSummaryEmptyView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBody
        addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-30)
        }
    }

    var text: String? {
        didSet {
            emptyView.textLabel.text = text
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MinutesSummaryEmptyView: UIView {
    lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = BundleResources.Minutes.illustration_empty_neutral_no_contentempty
        return imageView
    }()

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.numberOfLines = 0
        textLabel.textColor = UIColor.ud.textPlaceholder
        textLabel.text = ""
        textLabel.textAlignment = .center
        textLabel.font = .systemFont(ofSize: 14)
        return textLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBody
        addSubview(textLabel)
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        textLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


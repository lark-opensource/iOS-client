//
//  MinutesAudioContentView.swift
//  Minutes
//
//  Created by yangyao on 2021/3/12.
//

import UIKit
import MinutesFoundation
import UniverseDesignToast
import YYText
import LarkContainer
import MinutesNetwork
import UniverseDesignIcon

protocol MinutesAudioRecordingViewDelegate: AnyObject {
    func containerViewController() -> UIViewController
}

class MinutesAudioContentView: UIView {
    let userResolver: UserResolver
    
    var serialQueue: DispatchQueue {
        MinutesAPI.workQueue
    }
    private var viewModel: MinutesAudioContentViewModel
    private let tracker: MinutesTracker

    var commentsViewModel: MinutesCommentsViewModel?

    weak var delegate: MinutesAudioRecordingViewDelegate?

    weak var originalTextView: MinutesOriginalTextView?

    var viewData: [MinutesParagraphViewModel] = []

    var scrollDirectionBlock: ((Bool) -> Void)?

    var lastOffset: CGFloat = 0.0

    var autoToBottomTimer: Timer?
    var isDragged: Bool = false
    var isInCommentPage: Bool = false {
        didSet {
            isDragged = isInCommentPage
        }
    }
    
    var viewWidth: CGFloat = 0.0
    
    var containerVC: UIViewController? {
        return delegate?.containerViewController()
    }

    var isScrollingToRect: Bool = false
    var currentLongPressTextView: YYTextView?

    var isInBottom: Bool {
        return ceil(tableView.contentOffset.y) >= ceil(tableView.contentSize.height - tableView.frame.size.height)
    }

    lazy var reciableTracker = MinutesAudioDataTextDisplayedReciableTracker(viewModel.minutes.objectToken)

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MinutesRecordSubtitleCell.self, forCellReuseIdentifier: MinutesRecordSubtitleCell.description())
        tableView.separatorStyle = .none
        // reload之后offset会变
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        tableView.showsVerticalScrollIndicator = false
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()

    lazy var toBottomButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(UDIcon.getIconByKey(.downBottomOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(
            width: 24, height: 24)), for: .normal)
        button.layer.shadowColor = UIColor.ud.staticBlack.withAlphaComponent(0.08).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 1.0
        button.layer.cornerRadius = 24
        button.backgroundColor = .white
        button.addTarget(self, action: #selector(toBottomInvoke), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    init(resolver: UserResolver, frame: CGRect, minutes: Minutes, isInAudioPreview: Bool) {
        self.userResolver = resolver
        viewModel = MinutesAudioContentViewModel(minutes: minutes)
    
        tracker = MinutesTracker(minutes: minutes)
        super.init(frame: frame)

        viewWidth = frame.width
        addSubview(tableView)
        addSubview(toBottomButton)

        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        toBottomButton.snp.makeConstraints { (maker) in
            maker.size.equalTo(48)
            maker.right.equalToSuperview().offset(-20)
            isInAudioPreview ? maker.bottom.equalToSuperview().offset(-128) : maker.bottom.equalToSuperview().offset(-20)

        }
    }

    func prepareForAudioListening() {
        self.viewModel.setParagraphUpdater()
        self.viewModel.onDataUpdated = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.viewData = self.viewModel.data
                self.reloadData()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func toBottomInvoke() {
        if !isInBottom {
            isDragged = false
            tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentSize.height - tableView.frame.size.height), animated: true)
            toBottomButton.isHidden = true
        }
    }

    func observeEditMenu() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleLongPressRects), name: NSNotification.Name(rawValue: YYTextViewIsInLongPressSelectionRects), object: nil)
    }

    @objc func handleLongPressRects(_ notification: Notification) {
        if let object = notification.object as? [Any] {
            if let rectCount = object.first as? Int {
                let isInLongPressSelectionRects = rectCount > 0
                tableView.canCancelContentTouches = !isInLongPressSelectionRects
                tableView.delaysContentTouches = !isInLongPressSelectionRects
            }

            if let textView = object.last as? YYTextView {
                if let cur = currentLongPressTextView, textView.tag != cur.tag {
                    if let cell = tableView.cellForRow(at: subtitleIndexPath(cur.tag)) as? MinutesRecordSubtitleCell {
                        cell.hideSelectionDot()
                    }
                    currentLongPressTextView = textView
                } else {
                    currentLongPressTextView = textView
                }
            }
        }
    }
    func syncHighligtedCommentId(_ commentId: String?, indexPath: IndexPath) -> NSRange? {
        guard indexPath.row < viewModel.data.count else { return nil }

        let pVM: MinutesParagraphViewModel = viewModel.data[indexPath.row]
        // 更新comment id
        commentsViewModel?.highligtedCommentId = commentId
        // 同步高亮
        let range = pVM.highlightCommentRange(commentId)
        return range
    }

    // 清除高亮
    func clearCommentHighlight(_ indexPath: IndexPath) {
        guard indexPath.row < viewModel.data.count else { return }

        let pVM = viewModel.data[indexPath.row]
        pVM.selectedRange = nil
    }

    func updateCommentAndHighlightInfo(_ response: CommonCommentResponse, indexPath: IndexPath, didCompleted: (() -> Void)?) {
        guard indexPath.row < viewModel.data.count else { return }
        let pVM: MinutesParagraphViewModel = viewModel.data[indexPath.row]
        
        updateCommentsVM(response, pVM: pVM)

        // 更新highlight信息
        guard var paragraphs = viewModel.paragraphs, let paragraph = response.subtitles[pVM.pid] else { return }
        
        let old = viewModel.data[indexPath.row]
        // 替换
        paragraphs[indexPath.row] = paragraph
        calculate(with: paragraphs, didCompleted: didCompleted)
    }
    
    func updateCommentsVM(_ response: CommonCommentResponse, pVM: MinutesParagraphViewModel) {
        // 获取最新评论的comment id并更新
        if let commentsInfo = response.comments[pVM.pid],
           let commentList = commentsInfo.commentList,
           let newComment = commentList.sorted(by: { $0.createTime < $1.createTime }).last {
            commentsViewModel?.commentsInfo[pVM.pid] = commentsInfo
            commentsViewModel?.highligtedCommentId = newComment.id
        }
    }
    
    func calculate(with paragraphs: [Paragraph], didCompleted: (() -> Void)?) {
        viewModel.calculate(containerWidth: frame.width,
                            paragraphs: paragraphs,
                            lastSentenceFinal: viewModel.lastSentenceFinal,
                            commentsInfo: commentsViewModel?.commentsInfo,
                            highlightedCommentId: commentsViewModel?.highligtedCommentId,
                            isInTranslationMode: viewModel.isInTranslationMode){ [weak self] data in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.viewModel.data = data
                self.viewModel.paragraphs = paragraphs
                didCompleted?()
            }
        }
    }
    
    func setParagraphs(_ paragraphs: [Paragraph],
                       lastSentenceFinal: Bool,
                       commentsInfo: [String: ParagraphCommentsInfo],
                       isInTranslationMode: Bool,
                       didCompleted: (() -> Void)?) {
        serialQueue.async {
            let width = self.viewWidth
            self.commentsViewModel = MinutesCommentsViewModel(minutes: self.viewModel.minutes,
                                                         commentsInfo: commentsInfo,
                                                         highligtedCommentId: self.commentsViewModel?.highligtedCommentId,
                                                         isInTranslationMode: isInTranslationMode)
            self.viewModel.calculate(containerWidth: width,
                                     paragraphs: paragraphs,
                                     lastSentenceFinal: lastSentenceFinal,
                                     commentsInfo: self.commentsViewModel?.commentsInfo,
                                     highlightedCommentId: self.commentsViewModel?.highligtedCommentId,
                                     isInTranslationMode: isInTranslationMode) { [weak self] data in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.viewModel.data = data
                    self.viewModel.containerWidth = width
                    self.viewModel.paragraphs = paragraphs
                    self.viewModel.isInTranslationMode = isInTranslationMode
                    self.viewModel.lastSentenceFinal = lastSentenceFinal
                    
                    self.viewData = self.viewModel.data
                    self.reloadData()
                    didCompleted?()
                }
            }
        }
    }

    private func updateParagraphs(_ paragraphs: [Paragraph],
                       commentsInfo: [String: ParagraphCommentsInfo]) {
        serialQueue.async {
            self.commentsViewModel = MinutesCommentsViewModel(minutes: self.viewModel.minutes,
                                                         commentsInfo: commentsInfo,
                                                         highligtedCommentId: self.commentsViewModel?.highligtedCommentId,
                                                         isInTranslationMode: self.viewModel.isInTranslationMode)
            self.calculate(with: paragraphs)
        }
    }
    
    func calculate(with paragraphs: [Paragraph]) {
        self.viewModel.calculate(containerWidth: self.viewWidth,
                                 paragraphs: paragraphs,
                                 lastSentenceFinal: self.viewModel.lastSentenceFinal,
                                 commentsInfo: self.commentsViewModel?.commentsInfo,
                                 highlightedCommentId: self.commentsViewModel?.highligtedCommentId,
                                 isInTranslationMode: self.viewModel.isInTranslationMode) { [weak self] data in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.viewModel.data = data
                self.viewModel.paragraphs = paragraphs
                self.viewData = self.viewModel.data
                self.reloadData()
            }
        }
    }
    
    func reloadData(scrollToBottom: Bool = true) {
        self.reciableTracker.trackTextDisplayedEvent(self.viewData.last?.paragraph.stopTime)
        // 刷新UI
        self.tableView.reloadData()

        if !self.isDragged {
            if scrollToBottom {
                self.toBottomInvoke()
            }
        }
    }
}

extension MinutesAudioContentView: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewData.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row >= 0 && indexPath.row < viewData.count {
            return viewData[indexPath.row].cellHeight
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return createSubtitleCell(tableView, indexPath: indexPath)
    }

    func createSubtitleCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        
        guard indexPath.row >= 0 && indexPath.row < viewData.count else {
            return UITableViewCell()
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesRecordSubtitleCell.description(), for: indexPath) as? MinutesRecordSubtitleCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        let pVM: MinutesParagraphViewModel = viewData[indexPath.row]
        cell.configure(pVM, tag: indexPath.row)
        cell.menuCommentsBlock = { [weak self] copiedString, selectedRange in
            guard let self = self else { return }

            // 取最新的，数据可能被远端更新
            // 目前没有录音评论功能
            let pVM = self.viewData[indexPath.row]
            // 同步高亮
            pVM.selectedRange = selectedRange
            self.tableView.reloadRows(at: [indexPath], with: .none)
            if !self.isInBottom {
                // 定位到相关位置
                let offsetY = MinutesSubtileUtils.rangeOffsetIn(self.viewData, row: indexPath.row, range: selectedRange)
                self.scrollTo(offset: offsetY)
            }

            let offsetAndSize = pVM.findOffsetAndSizeInSentence(selectedRange: selectedRange)
            let info: [String: Any] = [AddCommentsVCParams.isNewComment: true,
                                       AddCommentsVCParams.pid: pVM.pid,
                                       AddCommentsVCParams.quote: copiedString,
                                       AddCommentsVCParams.offsetAndSize: offsetAndSize,
                                       AddCommentsVCParams.selectedRange: selectedRange]

            let commentsVC = MinutesAddCommentsViewController(commentsViewModel: self.commentsViewModel, info: info)
            commentsVC.commentSuccessBlock = { [weak self, weak commentsVC] response in
                guard let self = self, let commentsVC = commentsVC else { return }
                commentsVC.dismiss(animated: false, completion: nil)
                // 本地更新评论数据和highlight信息
                // 同时paragraphCommentsUpdate也会推送更新，包括评论数据和highlight
                // 先comment update成功通知，再callback
                self.serialQueue.async {
                    self.updateCommentAndHighlightInfo(response, indexPath: indexPath) { [weak self] in
                        self?.showCommentsCardVC(indexPath, response: response, needScrollToBottom: true)
                    }
                }
            }
            commentsVC.dismissSelfBlock = { [weak self] text in
                guard let self = self else { return }
                // 子线程处理数据
                self.serialQueue.async {
                    self.clearCommentHighlight(indexPath)
                    DispatchQueue.main.async {
                        self.tableView.reloadRows(at: [indexPath], with: .none)
                    }
                }
            }
            self.containerVC?.present(commentsVC, animated: false, completion: nil)
        }
        cell.showCommentsBlock = { [weak self] in
            self?.showCommentsCardVC(indexPath)
        }
        cell.copySuccessBlock = { [weak self] in
            guard let self = self else { return }
            let targetView = self.userResolver.navigator.mainSceneWindow?.fromViewController?.view
            MinutesToast.showTips(with: BundleI18n.Minutes.MMWeb_G_CopiedSuccessfully, targetView: targetView)
        }
        return cell
    }

    func showCommentsCardVC(_ indexPath: IndexPath,
                            response: CommonCommentResponse? = nil, needScrollToBottom: Bool = false) {
        guard indexPath.row < viewData.count else { return }
        let pVM: MinutesParagraphViewModel = viewData[indexPath.row]

        // 确定第几页
        var currentCount: NSInteger = 0
        if let response = response {
            if let commentsInfo = response.comments[pVM.pid],
               let subtitle = response.subtitles[pVM.pid],
               let commentList = commentsInfo.commentList,
               let highligtedCommentId = commentsViewModel?.highligtedCommentId {
                for (idx, c) in commentList.enumerated() where c.id == highligtedCommentId {
                    currentCount = idx
                    break
                }
            }
        }

        // 弹出评论页面
        isInCommentPage = true
        let commentsCardVC = MinutesCommentsCardViewController(resolver: userResolver, minutes: viewModel.minutes,
                                                               pid: pVM.pid,
                                                               commentsViewModel: commentsViewModel,
                                                               currentCount: currentCount,
                                                               needScrollToBottom: needScrollToBottom)
        commentsCardVC.currentHighlightedBlock = { [weak self] comment in
            guard let self = self else { return }

            self.serialQueue.async {
                // 子线程同步高亮数据
                let range = self.syncHighligtedCommentId(comment.id, indexPath: indexPath)
                DispatchQueue.main.async {
                    // 主线程替换数据
                    self.viewData = self.viewModel.data
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                    if !self.isInBottom {
                        // 定位到相关位置
                        if let range = range {
                            let offsetY = MinutesSubtileUtils.rangeOffsetIn(self.viewData, row: indexPath.row, range: range)
                            self.scrollTo(offset: offsetY)
                        }
                    }
                }
            }
        }
        commentsCardVC.dismissBlock = { [weak self] in
            guard let self = self else { return }

            self.isInCommentPage = false
            self.serialQueue.async {
                // 同步高亮数据
                self.syncHighligtedCommentId(nil, indexPath: indexPath)
                DispatchQueue.main.async {
                    // 刷新UI
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        }
        self.containerVC?.present(commentsCardVC, animated: false, completion: nil)
    }
}

extension MinutesAudioContentView: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDragged = true
        hideMenu()

        lastOffset = scrollView.contentOffset.y
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if lastOffset > scrollView.contentOffset.y {
            scrollDirectionBlock?(false)
        } else if lastOffset < scrollView.contentOffset.y {
            scrollDirectionBlock?(true)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidStopped()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidStopped()
        }
    }

    func scrollViewDidStopped() {
        let needHidden = isInBottom
        // 滚动到底部回归自动滚动
        if isInBottom {
            isDragged = false
        }
        if toBottomButton.isHidden != needHidden {
            toBottomButton.isHidden = needHidden
        }
    }

    func hideMenu() {
        if let cur = currentLongPressTextView {
            if let cell = tableView.cellForRow(at: subtitleIndexPath(cur.tag)) as? MinutesRecordSubtitleCell {
                cell.hideMenu()
            }
        }
    }
}

extension MinutesAudioContentView {
    func subtitleIndexPath(_ row: NSInteger) -> IndexPath {
        return IndexPath(row: row, section: 0)
    }

    func scrollTo(offset: CGFloat) {
        MinutesSubtileUtils.runOnMain {
            guard self.isScrollingToRect == false else { return }

            self.isScrollingToRect = true
            self.tableView.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.isScrollingToRect = false
            }
        }
    }

    func scrollTo(indexPath: IndexPath, animated: Bool = true) {
        MinutesSubtileUtils.runOnMain {
            guard self.isScrollingToRect == false else { return }

            self.isScrollingToRect = true
            if self.tableView.indexPathExists(indexPath: indexPath) {
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.isScrollingToRect = false
            }
        }
    }
}

extension MinutesAudioContentView {
    private func onCommentsUpdate(_ data: ([String], Bool)) {
        serialQueue.async {
            // 翻译状态下不自动更新
            if self.viewModel.isInTranslationMode {
                return
            }
            // 评论更新和highligh更新
            self.updateParagraphs(self.viewModel.minutes.data.subtitles, commentsInfo: self.viewModel.minutes.data.paragraphComments)
        }
    }
}

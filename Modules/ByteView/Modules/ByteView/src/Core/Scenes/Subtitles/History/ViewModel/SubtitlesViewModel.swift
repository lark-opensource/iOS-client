//
//  SubtitlesViewModel.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/8/12.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import ByteViewNetwork
import ByteViewUI

class SubtitlesViewModel: InMeetMeetingProvider {

    private let store: SubtitlesStore
    private let disposeBag = DisposeBag()

    // 字幕历史数据相关 (由于性能问题，必须是存储属性)
    private let stateRelay: BehaviorRelay<SubtitlesViewState>
    private var stateDriver: Driver<SubtitlesViewState> {
        return stateRelay.asDriver()
    }
    private var state: SubtitlesViewState {
        get {
            return stateRelay.value
        }
        set {
            if !isMenuShow {
                SubtitlesStore.logger.info("Subtitle Menu ISHidden: 发送数据 count = \(newValue.count)")
                stateRelay.accept(newValue)
            } else {
                SubtitlesStore.logger.info("Subtitle Menu ISShowIng: 停止接收数据 oldcount = \(state.count)  newcount = \(newValue.count)")
            }
        }
    }

    var viewDatas: [SubtitleViewData] {
        return state.subtitlesViewData?.subtitleViewDatas ?? []
    }

    var reloadRows: Set<Int> {
        return store.reloadRows
    }

    var reloadAllNum: Int {
        return store.reloadAllNum
    }

    // 搜索相关
    private(set) var isSearchMode: Bool = false {
        didSet { searchBottomViewBlock?() }
    }
    var searchBottomViewBlock: (() -> Void)?

    //搜索后定位定到第一个检索结果的标识符
    var isFirstLocation: Bool = false
    var isFilterMode = false // 筛选模式
    var isOpenAutoScrollInSearchFilter = false // 在搜索和筛选状态时，如果来了新消息，显示置底按钮，当点击置底按钮时，不是跳转到底部而是重新请求数据
    var isFetchNewDataInSearchFilter = false // 在搜索和筛选状态时，来了新消息
    var currentSelectedId: Int? //当前选中的segId
    var currentSelectedRange: NSRange? //当前选中的segId下的range
    private var currentTempSelectedId: Int? //当前选中的segId临时值
    private var currentSelectedTempRange: NSRange? //当前选中的segId下的range临时值
    /// 当前的筛选人（nil代表没有筛选）
    private var filterPeople: ParticipantId?

    // 通知tableview需要跳转到哪一行
    private let jumpSubject = PublishSubject<Int>()
    var jumpObservable: Observable<Int> {
        return jumpSubject.asObservable()
    }

    // 通知快速跳转的【下一个跳转】按钮是否要置灰
    private let bottomHighlightSubject = PublishSubject<Bool>()
    var bottomHighlightObservable: Observable<Bool> {
        return bottomHighlightSubject.asObservable()
            .distinctUntilChanged()
    }

    // 通知快速跳转的【上一个跳转】按钮是否要置灰
    private let topHighlightSubject = PublishSubject<Bool>()
    var topHighlightObservable: Observable<Bool> {
        return topHighlightSubject.asObservable()
            .distinctUntilChanged()
    }

    // 搜索是否可用
    private let searchFilterEnableSubject = PublishSubject<Bool>()
    var searchFilterEnableObservable: Observable<Bool> {
        return searchFilterEnableSubject.asObservable()
            .distinctUntilChanged()
    }

    // 搜索模式下，vc页面的置底按钮是否要强制显示
    let bottomButtonShowSubject = PublishSubject<Void>()
    var bottomButtonShowObservable: Observable<Void> {
        return bottomButtonShowSubject.asObservable()
    }

    // 筛选按钮是否要高亮
    private let filterButtonSelectSubject = PublishSubject<Bool>()
    var filterObservable: Observable<Bool> {
        return filterButtonSelectSubject.asObservable()
            .distinctUntilChanged()
    }

    // 清除数据
    private let clearDataSubject = PublishSubject<Void>()
    var clearDataObservable: Observable<Void> {
        return clearDataSubject.asObservable()
    }

    // 长按文字复制相关
    var isMenuShow = false
    typealias ListReloadDataWhehMenuHiddenBlock = () -> Void
    var reloadDataWhehMenuHidden: ListReloadDataWhehMenuHiddenBlock?

    // 翻译语言切换相关
    private let subtitleLanguagesSubject = PublishSubject<Void>()

    var count: Int {
        return state.count
    }

    var isLoading: Bool {
        return state.isLoading
    }

    var needJump: Bool {
        return state.needJump
    }

    var smoothSubtitleBlock: (() -> Void)?
    var timer: Timer?
    var isSubtitleAlignRight: Bool = false
    var meeting: InMeetMeeting { store.meeting }

    init(meeting: InMeetMeeting, subtitle: InMeetSubtitleViewModel) {
        self.isSubtitleAlignRight = subtitle.isSubtitleAlignRight
        self.store = SubtitlesStore(meeting: meeting, subtitle: subtitle)
        self.stateRelay = BehaviorRelay(value: store.state)
        // nolint-next-line: magic number
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
            self?.showSubtitleSmooth()
        })
        //监听列表数据
        store.stateObservable
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] state in
                guard let `self` = self else { return }
                if self.isSearchMode {
                    if let tempState = self.handlaSearchData(state: state) {
                         self.state = tempState
                         self.sendHighlightSingnal()
                        if self.isFirstLocation {
                            self.updateToFirst()    //搜索后tableview定位到第一个匹配字符
                            self.isFirstLocation = false
                        }
                     } else {
                         self.state = state
                         self.sendHighlightSingnal()
                         self.isFirstLocation = true
                     }
                } else {
                    self.state = state
                    self.sendHighlightSingnal()
                }
            })
            .disposed(by: disposeBag)

        // 监听 search 接口
        store.searchDataObservable
            .subscribe(onNext: { [weak self] (searchData)  in
                guard let `self` = self else { return }
                if searchData.hasMore {
                    self.store.fetchSearchMacthData(pattern: searchData.pattern)// 递归调用
                } else {
                    if !searchData.matches.isEmpty {
                        self.isSearchMode = true
                        self.clearData()
                        self.fetchSubtitlesInSearchMode(isForward: false, targetSeqID: self.store.searchData?.matches.first?.segId)
                    } else {
                        // 没有搜索到内容
                        /*
                        // update cell 的range数据
                        if let state = self.resetRanges() {
                            self.state = state
                        }
                        */
                        self.clearData()
                        // 拉最新的数据
                        self.pullOldAction.execute()
                            .subscribe()
                            .disposed(by: self.disposeBag)
                    }
                }
                }, onError: { (_) in

            }, onCompleted: {

            }, onDisposed: nil)
            .disposed(by: disposeBag)

        store.searchFilterEnableObservable.subscribe(onNext: { [weak self](enable) in
            guard let `self` = self else { return }
            self.searchFilterEnableSubject.onNext(enable)
            }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)

        store.viewModel = self

        subtitle.addObserver(self)
        // 监听menux展示与隐藏
        // name: NSNotification.Name(rawValue: "FloatMenuViewShow"),
        NotificationCenter.default.addObserver(self, selector: #selector(willShowMenuHandler),
                                               name: UIMenuController.willShowMenuNotification,
                                               object: nil)

        // name: NSNotification.Name(rawValue: "FloatMenuViewHidden"),
        NotificationCenter.default.addObserver(self, selector: #selector(didHideMenuHandler),
                                               name: UIMenuController.didHideMenuNotification,
                                               object: nil)
    }

    // MARK: - 事件
    // 下拉控件，拉取旧的数据
    lazy var pullOldAction: CocoaAction = {
        return CocoaAction(workFactory: { [weak self] _ in
            guard let `self` = self else {
                return .empty()
            }
            return self.store.fetchSubtitles(isForward: true, targetSeqID: self.state.subtitlesViewData?.subtitleViewDatas.first?.segId)
                .asObservable()
                .map({ _ in })
        })
    }()

    // 上划控件，拉取新的数据
    lazy var pullNewAction: CocoaAction = {
        return CocoaAction(workFactory: { [weak self] _ in
            guard let `self` = self else {
                return .empty()
            }

            return self.store.fetchSubtitles(isForward: false, targetSeqID: self.state.subtitlesViewData?.subtitleViewDatas.last?.segId)
                .asObservable()
                .map({ _ in })
        })
    }()

    deinit {
        timer?.invalidate()
    }

    private func showSubtitleSmooth() {
        smoothSubtitleBlock?()
    }

    func updateReloadRows(with index: Int) {
        store.reloadRows.remove(index)
    }

    func updateReloadAllNum() {
        if store.reloadAllNum <= 0 {
            store.reloadAllNum = 0
            return
        }
        store.reloadAllNum -= 1
    }

    // 进入筛选页面
    func filterAction(_ button: UIButton, text: String?) -> SubtitlesFilterViewController {
        var state: FilterViewModel.FilterInitializeState
        if let people = self.filterPeople {
            state = .filterPeople(people: people)
        } else {
            state = .none
        }
        let viewModel = SubtitleFilterViewModel(meeting: store.meeting, state: state) { [weak self] (filterPeople) in
            guard let `self` = self else { return }
            //  筛选成功回调
            self.startFilterMode(filterPeople: filterPeople)
            self.handleFilterDataTask(text: text)
        } clearBlock: { [weak self] in
            guard let `self` = self else { return }
            //  清除筛选回调
            self.clearFilterMode()
            self.handleFilterDataTask(text: text)
        }

        let viewController = SubtitlesFilterViewController(viewModel: viewModel)


        if Display.pad {
            let popoverConfig = DynamicModalPopoverConfig(sourceView: button,
                                                          sourceRect: button.bounds,
                                                          backgroundColor: UIColor.clear,
                                                          permittedArrowDirections: .up)
            let regularConfig = DynamicModalConfig(presentationStyle: .popover,
                                                   popoverConfig: popoverConfig,
                                                   backgroundColor: .clear,
                                                   needNavigation: true)
            router.presentDynamicModal(viewController,
                                       regularConfig: regularConfig,
                                       compactConfig: regularConfig)
        } else {
            let vc = NavigationController(rootViewController: viewController)
            vc.modalPresentationStyle = .pageSheet
            larkRouter.present(vc, animated: true)
        }

        return viewController
    }
}

// MARK: - 供外界监听的流
extension SubtitlesViewModel {

    // 监听获取数据
    var subtitleViewDatasObservable: Observable<([SubtitleViewData], SubtitleTableViewScrollType)> {
        return stateDriver
            .map({
                guard let viewData = $0.subtitlesViewData else {
                    return ([], .forcesKeepingPosition)
                }

                return (viewData.subtitleViewDatas, viewData.tableViewScrollType)
            })
            .distinctUntilChanged({ $0.0 == $1.0 })//阻止 Observable 发出相同的元素
            .asObservable()
    }

    // 下拉控件
    var needsPullOldRefreshControlDriver: Driver<Bool> {
        return stateDriver
            .map({ $0.pullOldAllowsRefreshing })
            .distinctUntilChanged()
    }

    // 结束下拉
    var isPullOldLoadingDriver: Driver<Bool> {
        return stateDriver
            .map({ $0.isLoading })
            .distinctUntilChanged()
    }

    // 上划控件
    var needsPullNewRefreshControlDriver: Driver<Bool> {
        return stateDriver
            .map({ $0.pullNewAllowsRefreshing })
            .distinctUntilChanged()
    }

    // 结束上划
    var isPullNewLoadingDriver: Driver<Bool> {
        return stateDriver
            .map({ $0.isLoading })
            .distinctUntilChanged()
    }

    //监听ASR状态
    var asrStatusTextsDriver: Driver<String?> {
        return store.asrStatusValue
            .map {
                switch $0 {
                case .recoverableException:
                    return I18n.View_G_SubtitlesReconnecting
                case .openSuccessed(let isRecover, let isAllMuted):
                    guard !isRecover else { return nil }
                    if isAllMuted { return "NoOneSpeaking" }
                    return nil
                default:
                    return nil
                }
        }
        .distinctUntilChanged()
        .asDriver(onErrorJustReturn: nil)
    }

    // 切换语言
    var changeSubtitleLanguageObservable: Observable<Void> {
        return subtitleLanguagesSubject.asObservable()
    }
}

// MARK: - 提供给外界tableview的数据
extension SubtitlesViewModel {

    // 获取ViewData
    func subtitleViewDataForRow(at indexPath: IndexPath) -> SubtitleViewData? {
        let index = indexPath.row
        guard let viewDatas = state.subtitlesViewData?.subtitleViewDatas, index < viewDatas.count else {
            return nil
        }
        return viewDatas[index]
    }
}

// MARK: - 监听copy menu的显示与隐藏
extension SubtitlesViewModel {

    @objc private func willShowMenuHandler() {
        self.isMenuShow = true
    }

    @objc private func didHideMenuHandler() {
        // 在menu消失时，需要展示新的消息
        self.isMenuShow = false
        let state = self.store.state
        if state != self.state {
            SubtitlesStore.logger.info("Subtitle Menu ISHidden: 重新赋值并发送信号")
            self.state = state
            if let reloadDataWhehMenuHidden = self.reloadDataWhehMenuHidden {
                reloadDataWhehMenuHidden()
            }
        }
    }
}

// 搜索相关
extension SubtitlesViewModel {

    // MARK: - 状态管理
    // 开始搜索
    func startSearch(text: String) {
        clearSelecteInfo()
        self.store.fetchSearchMacthData(pattern: text)
    }

    // 搜索模式
    func beginSearchMode() {
        if !isSearchMode {
            self.isSearchMode = true
        }
    }

    // 清除搜索（当搜索框字符串为空的时候）
    func clearSearchMode() {
        clearSelecteInfo()
        if isSearchMode {
            self.isSearchMode = false
            //  重置 viewData 的range
            if let state = resetRanges() {
                self.state = state
            }
        }
    }

    // 清除当前页面数据
    private func clearData() {
        self.state = .emptyData
        self.store.state = .emptyData
        self.clearDataSubject.onNext(())
    }

    // 清除搜索信息
    private func clearSelecteInfo() {
        self.currentSelectedRange = nil
        self.currentSelectedId = nil
        self.currentTempSelectedId = nil
        self.currentSelectedTempRange = nil
        self.store.searchData = nil
        resetBottomButtonStatus()
        sendNoHighlightSingnal()
    }

    // 重置 viewData 的range
    func resetRanges() -> SubtitlesViewState? {
        guard var viewData = self.state.subtitlesViewData else {
            return nil
        }

        var subtitleViewDatas: [SubtitleViewData] = []
        for subtitle in viewData.subtitleViewDatas { //遍历字幕
            subtitle.changeMatch(range: [])// 重置
            subtitleViewDatas.append(subtitle)
        }
        var tempState = self.state
        viewData.update(subtitleViewDatas: subtitleViewDatas)
        tempState.update(viewData)
        return tempState
    }

    // MARK: - 对拉下来的数据，进行高亮处理
    private func handlaSearchData(state: SubtitlesViewState) -> SubtitlesViewState? {

        guard var viewData = state.subtitlesViewData, let searchData = self.store.searchData else {
            return nil
        }

        // 用于快速跳转，设置Selected信息
        if self.currentTempSelectedId != nil, self.currentSelectedTempRange != nil {
            self.currentSelectedId = self.currentTempSelectedId
            self.currentSelectedRange = self.currentSelectedTempRange
            self.currentTempSelectedId = nil
            self.currentSelectedTempRange = nil
        }

        var subtitleViewDatas: [SubtitleViewData] = []
        for subtitle in viewData.subtitleViewDatas { //遍历字幕
            subtitle.changeMatch(range: [])// 重置
            for match in searchData.matches where match.segId == subtitle.segId {//遍历搜索命中的match数组
                // 给字幕数据添加ranges数组
                var ranges: [NSRange] = []
                for start in match.startPos {
                    if subtitle.eventType == .follow, let docTitle = subtitle.behaviorDocLinkTitle {
                        if start + searchData.pattern.count <= docTitle.count {
                            // 纠错
                            ranges.append(NSRange(location: start, length: searchData.pattern.count))
                        } else {
                            SubtitlesStore.logger.error("Subtitle match: content:\(String(describing: subtitle.behaviorDocLinkTitle)) pattern:\(searchData.pattern) startPos:\(match.startPos)")
                        }
                    } else {
                        if start + searchData.pattern.count <= subtitle.translatedContent.length {
                            // 纠错
                            ranges.append(NSRange(location: start, length: searchData.pattern.count))
                        } else {
                            SubtitlesStore.logger.error("Subtitle match: content:\(subtitle.translatedContent) pattern:\(searchData.pattern) startPos:\(match.startPos)")
                        }
                    }
                }
                subtitle.changeMatch(range: ranges)
                if self.currentSelectedId == nil && !ranges.isEmpty {
                    // 用于第一次获取，给一个默认值
                    self.currentSelectedId = subtitle.segId
                    self.currentSelectedRange = ranges.first
                }
                if subtitle.segId == self.currentSelectedId, let currentSelectedRange = self.currentSelectedRange, !subtitle.ranges.contains(currentSelectedRange) {
                    // 纠错
                    self.currentSelectedRange = subtitle.ranges.first // last也可以
                    SubtitlesStore.logger.error("Subtitle rectifyMatch: content:\(subtitle.translatedContent)pattern:\(searchData.pattern)startPos:\(match.startPos)")
                }
            }
            subtitleViewDatas.append(subtitle)
        }
        var tempState = state
        viewData.update(subtitleViewDatas: subtitleViewDatas)
        tempState.update(viewData)
        return tempState
    }

    // MARK: - 快速跳转
    // 快速跳转 - 跳转到下一个结果
    func updateBottom() {

        // 如果没有字幕数据就返回
        guard let subtitleList = self.state.subtitlesViewData?.subtitleViewDatas, !subtitleList.isEmpty  else {
            return
        }

        // 如果没有搜索数组就返回
        guard let searchData = self.store.searchData else {
            return
        }

        let matches = searchData.matches
        guard !matches.isEmpty else {
            return
        }

        // 如果没有当前选中的数据就返回，需要进一步查询
        guard let currentSelectedId = self.currentSelectedId, let currentSelectedRange = self.currentSelectedRange else {
            let nextMatchInfo = getNextSubtitleInfoWhenDataIsNoExist(searchText: searchData.pattern, subtitleList: subtitleList, matches: matches)
            guard let nextMatch = nextMatchInfo.1, let nextRange = nextMatchInfo.2 else {
                return
            }
            requestDataWhenSelectedDataIsNoExist(isForward: false, match: nextMatch, range: nextRange)
            return
        }

        // 根据id获取当前选中的subtitle
        guard let currentSelectSubtitle = getViewDataBySegId(segId: currentSelectedId, subtitleList: subtitleList) else {
            return
        }

        if currentSelectSubtitle.ranges.last == currentSelectedRange {
            // 马上将变为不是同一行
            //获取下一个待命中的match的id
            var tempNextMatch: SubtitleSearchMatch?
            if let index = matches.firstIndex(where: { $0.segId == currentSelectedId }), (index + 1) < matches.count {
                tempNextMatch = matches[index + 1]
            }

            guard let nextMatch = tempNextMatch else {
                return
            }

            //获取下一个待命中的subtitle
            if let nextSubTitle = getViewDataBySegId(segId: nextMatch.segId, subtitleList: subtitleList) {
                //  如果有足够的数据，不需要进行请求，也就是目标id在字幕数据里
                self.setSelectData(currentSelectedId: nextSubTitle.segId, currentSelectedRange: nextSubTitle.ranges.first)
                if let index = getCurrentSelectIndex(state: self.state) {
                    jumpSelectedAtRow(index: index)
                }
            } else {
                guard let nextRangeStart = nextMatch.startPos.first, !searchData.pattern.isEmpty else {
                    return
                }
                requestDataWhenSelectedDataIsNoExist(isForward: false, match: nextMatch, range: NSRange(location: nextRangeStart, length: searchData.pattern.count))
            }
        } else {
            // 同一行向后移动
            let ranges = currentSelectSubtitle.ranges
            if let index = ranges.firstIndex(of: currentSelectedRange), (index + 1) < ranges.count {
                self.setSelectData(currentSelectedId: self.currentSelectedId, currentSelectedRange: ranges[index + 1])
            }

            if let index = getCurrentSelectIndex(state: self.state) {
                jumpSelectedAtRow(index: index)
            }
        }
    }

    // 快速跳转 - 跳转到上一个结果
    func updateTop() {

        // 如果没有字幕数据就返回
        guard let subtitleList = self.state.subtitlesViewData?.subtitleViewDatas, !subtitleList.isEmpty  else {
            return
        }

        // 如果没有搜索数组就返回
        guard let searchData = self.store.searchData else {
            return
        }

        let matches = searchData.matches
        guard !matches.isEmpty else {
            return
        }

        // 如果没有当前选中的数据就返回，因为没有方向去操作移动选中
        guard let currentSelectedId = self.currentSelectedId, let currentSelectedRange = self.currentSelectedRange else {
            let matchInfo = getLastSubtitleInfoWhenDataIsNoExist(searchText: searchData.pattern, subtitleList: subtitleList, matches: matches)
            guard let lastMatch = matchInfo.1, let lastRange = matchInfo.2 else {
                return
            }
            requestDataWhenSelectedDataIsNoExist(isForward: true, match: lastMatch, range: lastRange)
            return
        }

        // 根据id获取当前选中的subtitle
        guard let currentSelectSubtitle = getViewDataBySegId(segId: currentSelectedId, subtitleList: subtitleList) else {
            return
        }

        if currentSelectSubtitle.ranges.first == currentSelectedRange {
            // 马上将变为不是同一行
            //获取上一个待命中的match的id
            var tempLastMatch: SubtitleSearchMatch?
            if let index = matches.firstIndex(where: { $0.segId == currentSelectedId }), index > 0 {
                tempLastMatch = matches[index - 1]
            }

            guard let lastMatch = tempLastMatch else {
                return
            }

            //获取上一个待命中的subtitle
            if let lastSubTitle = getViewDataBySegId(segId: lastMatch.segId, subtitleList: subtitleList) {
                //  如果有足够的数据，不需要进行请求，也就是目标id在字幕数据里
                self.setSelectData(currentSelectedId: lastSubTitle.segId, currentSelectedRange: lastSubTitle.ranges.last)
                if let index = getCurrentSelectIndex(state: self.state) {
                    jumpSelectedAtRow(index: index)
                }
            } else {
                guard let lastRangeStart = lastMatch.startPos.last, !searchData.pattern.isEmpty else {
                    return
                }
                requestDataWhenSelectedDataIsNoExist(isForward: true, match: lastMatch, range: NSRange(location: lastRangeStart, length: searchData.pattern.count))
            }
        } else {
            // 同一行向前移动
            let ranges = currentSelectSubtitle.ranges
            if let index = ranges.firstIndex(of: currentSelectedRange), index > 0 {
                self.setSelectData(currentSelectedId: self.currentSelectedId, currentSelectedRange: ranges[index - 1])
            }

            if let index = getCurrentSelectIndex(state: self.state) {
                jumpSelectedAtRow(index: index)
            }
        }
    }

    private func updateToFirst() {

        // 如果没有字幕数据就返回
        guard let subtitleList = self.state.subtitlesViewData?.subtitleViewDatas, !subtitleList.isEmpty  else {
            return
        }

        // 如果没有搜索数组就返回
        guard let searchData = self.store.searchData else {
            return
        }

        let matches = searchData.matches
        guard !matches.isEmpty else {
            return
        }

        guard let currentSelectedId = self.currentSelectedId else {
            let matchInfo = getLastSubtitleInfoWhenDataIsNoExist(searchText: searchData.pattern, subtitleList: subtitleList, matches: matches)
            guard let lastMatch = matchInfo.1, let lastRange = matchInfo.2 else {
                return
            }
            requestDataWhenSelectedDataIsNoExist(isForward: true, match: lastMatch, range: lastRange)
            return
        }

        guard let currentSelectSubtitle = getViewDataBySegId(segId: currentSelectedId, subtitleList: subtitleList), let firstRange = currentSelectSubtitle.ranges.first else {
            return
        }

        self.setSelectData(currentSelectedId: self.currentSelectedId, currentSelectedRange: firstRange)

        if let index = getCurrentSelectIndex(state: self.state) {
            jumpSelectedAtRow(index: index)
        }
    }


    // 通过快速跳转且没有足够的数据时，请求pull接口请求字幕列表数据，
    private func requestDataWhenSelectedDataIsNoExist(isForward: Bool, match: SubtitleSearchMatch, range: NSRange) {
         if self.currentTempSelectedId != nil, self.currentSelectedTempRange != nil {
             // 防止用户多次点击快速跳转按钮
             return
         }
        self.clearData()
        self.currentTempSelectedId = match.segId
        self.currentSelectedTempRange = range
        self.fetchSubtitlesInSearchMode(isForward: isForward, targetSeqID: match.segId)
    }

    // 通过快速跳转进行pull接口请求返回字幕列表数据
    private func fetchSubtitlesInSearchMode(isForward: Bool, targetSeqID: Int? = nil) {
        resetBottomButtonStatus()
        self.store.fetchSubtitlesInSearchMode(isForward: isForward, targetSeqID: targetSeqID).subscribe().disposed(by: disposeBag)
    }

    // 通知tableview跳转到指定的目标cell
    func jumpSelectedAtRow(index: Int) {
        self.jumpSubject.onNext(index)
    }

    // MARK: - 设置快速跳转按钮是否可点击
    //设置inputView里面的上下箭头是否可以点击
    private func sendHighlightSingnal() {
        guard let subtitleList = self.state.subtitlesViewData?.subtitleViewDatas, !subtitleList.isEmpty, let searchData = self.store.searchData else {
            // 发送置灰信号
            sendNoHighlightSingnal()
            return
        }

        let matches = searchData.matches
        guard !matches.isEmpty else {
            sendNoHighlightSingnal()
            return
        }

        let searchText = searchData.pattern
        guard !searchText.isEmpty else {
            sendNoHighlightSingnal()
            return
        }

        if let currentSelectedId = self.currentSelectedId, let currentSelectedRange = self.currentSelectedRange {
            // 根据id找到选中的subtitle
            guard let currentSelectSubtitle = getViewDataBySegId(segId: currentSelectedId, subtitleList: subtitleList) else {
                // 如果在当前数据源中中没有找到，进一步查找确认
                judgeButtonIsHighlight(searchText: searchText, subtitleList: subtitleList, matches: matches)
                return
            }

            // 设置topArrowButton是否可以点击
            let topIsNotHighlight = matches.first?.segId == currentSelectedId && currentSelectSubtitle.ranges.first == currentSelectedRange
            sendTopHighlightSingnal(isHighlight: !topIsNotHighlight)

            // 设置bottomArrowButton是否可以点击
            let bottomIsNotHighlight = matches.last?.segId == currentSelectedId && currentSelectSubtitle.ranges.last == currentSelectedRange
            sendBottomHighlightSingnal(isHighlight: !bottomIsNotHighlight)

        } else {
            // 如果在当前数据源中中没有找到当前选中的sedid，进一步判断是否可以高亮
            judgeButtonIsHighlight(searchText: searchText, subtitleList: subtitleList, matches: matches)
        }
    }

    private func sendNoHighlightSingnal() {
        topHighlightSubject.onNext(false)
        bottomHighlightSubject.onNext(false)
    }

    private func sendTopHighlightSingnal(isHighlight: Bool) {
        topHighlightSubject.onNext(isHighlight)
    }

    private func sendBottomHighlightSingnal(isHighlight: Bool) {
        bottomHighlightSubject.onNext(isHighlight)
    }

    // 如果在当前数据源中中没有找到当前选中的sedid，进一步判断是否可以高亮
    private func judgeButtonIsHighlight(searchText: String, subtitleList: [SubtitleViewData], matches: [SubtitleSearchMatch]) {
        let topIsHighlight = getLastSubtitleInfoWhenDataIsNoExist(searchText: searchText, subtitleList: subtitleList, matches: matches).0
        sendTopHighlightSingnal(isHighlight: topIsHighlight)

        let bottomIsHighlight = getNextSubtitleInfoWhenDataIsNoExist(searchText: searchText, subtitleList: subtitleList, matches: matches).0
        sendBottomHighlightSingnal(isHighlight: bottomIsHighlight)
    }

    // 如果选中的不在当前数据源中，进一步判断inputView里的上下箭头按钮是否高亮
    private func getLastSubtitleInfoWhenDataIsNoExist(searchText: String, subtitleList: [SubtitleViewData], matches: [SubtitleSearchMatch]) -> (Bool, SubtitleSearchMatch?, NSRange?) {
        guard let subtitle = subtitleList.first else {
            return (false, nil, nil)
        }

        guard let lastMatch = matches.reversed().first(where: { $0.segId < subtitle.segId }) else {
            return (false, nil, nil)
        }

        guard let lastRangeStart = lastMatch.startPos.last, !searchText.isEmpty else {
            return (false, nil, nil)
        }
        return (true, lastMatch, NSRange(location: lastRangeStart, length: searchText.count))
    }

    private func getNextSubtitleInfoWhenDataIsNoExist(searchText: String, subtitleList: [SubtitleViewData], matches: [SubtitleSearchMatch]) -> (Bool, SubtitleSearchMatch?, NSRange?) {
        guard let subtitle = subtitleList.last else {
            return (false, nil, nil)
        }

        guard let nextMatch = matches.first(where: { $0.segId > subtitle.segId }) else {
            return (false, nil, nil)
        }

        guard let nextRangeStart = nextMatch.startPos.first, !searchText.isEmpty else {
            return (false, nil, nil)
        }
        return (true, nextMatch, NSRange(location: nextRangeStart, length: searchText.count))
    }

    // MARK: - 通用的方法
    // 获取命中的index
    func getCurrentSelectIndex() -> Int? {
        return getCurrentSelectIndex(state: self.state)
    }

    var indexOfSearchData: Int? {
        let currentSelectedId = self.currentSelectedId
        guard let currentStartPos = self.currentSelectedRange?.location else {
            return nil
        }
        return flatMatchData?.firstIndex(where: { (segID, pos) -> Bool in
            segID == currentSelectedId && pos == currentStartPos
        })
    }

    var numOfSearchData: Int? {
        return flatMatchData?.count
    }

    var flatMatchData: [(segID: Int, pos: Int)]? {
        return store.searchData?.matches.reduce([], { (data, match) -> [(Int, Int)] in
            var d = data
            for m in match.startPos {
                d.append((match.segId, m))
            }
            return d
        })
    }

    private func getCurrentSelectIndex(state: SubtitlesViewState) -> Int? {
        if let currentSelectedId = self.currentSelectedId, let subtitleList = state.subtitlesViewData?.subtitleViewDatas, !subtitleList.isEmpty {
            return subtitleList.firstIndex(where: { $0.segId == currentSelectedId })
        }
        return nil
    }

    // 根据id找到 SubtitleViewData
    private func getViewDataBySegId(segId: Int, subtitleList: [SubtitleViewData]) -> SubtitleViewData? {
        subtitleList.first(where: { $0.segId == segId })
    }

    // 设置命中的数据
    private func setSelectData(currentSelectedId: Int?, currentSelectedRange: NSRange?) {
        self.currentSelectedId = currentSelectedId
        self.currentSelectedRange = currentSelectedRange
        sendHighlightSingnal()
    }
}

// MARK: - 筛选相关
extension SubtitlesViewModel {

    // 进入筛选模式
    private func startFilterMode(filterPeople: ParticipantId) {
        resetBottomButtonStatus()
        isFilterMode = true
        self.filterPeople = filterPeople
        filterButtonSelectSubject.onNext(true)
    }

    // 清除筛选模式
    private func clearFilterMode() {
        resetBottomButtonStatus()
        isFilterMode = false
        filterPeople = nil
        filterButtonSelectSubject.onNext(false)
    }

    // 处理筛选状态下的数据任务
    private func handleFilterDataTask(text: String?) {
        // 重新拉取数据
        if let searchText = text, !searchText.isEmpty {
            // 如果搜索框有文字，使用搜索接口，拉最旧的数据
            self.startSearch(text: searchText)
        } else {
            // 清除数据
            self.clearData()
            // 如果搜索框没有文字，走普通的pull接口
            // 拉最新的数据
            self.pullOldAction.execute()
                .subscribe()
                .disposed(by: disposeBag)
        }
    }
}

// MARK: - 置底按钮相关
extension SubtitlesViewModel {
    // 点击置底按钮
    func clickBottomButtonAction(completion: @escaping (() -> Void)) {
        if (self.isFilterMode || self.isSearchMode) && self.isFetchNewDataInSearchFilter && !self.isOpenAutoScrollInSearchFilter {
            self.clearData()
            self.isOpenAutoScrollInSearchFilter = true
            self.isFetchNewDataInSearchFilter = false
            self.currentSelectedId = nil
            self.currentSelectedRange = nil
            pullOldAction.execute()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    completion()
                }).disposed(by: disposeBag)
        } else {
            completion()
        }
    }

    func resetBottomButtonStatus() {
        self.isOpenAutoScrollInSearchFilter = false
        self.isFetchNewDataInSearchFilter = false
    }
}

extension SubtitlesViewModel: InMeetSubtitleViewModelObserver {
    func didChangeSubtitleLanguage(_ language: String, oldValue: String?) {
        isSubtitleAlignRight = language == "ar"
        if oldValue == nil { return }
        self.clearData()
        self.clearSearchMode()
        self.clearFilterMode()
        //  更换翻译语言需要调用Rust的SYNC_SUBTITLES
        let breakoutRoomId = self.meeting.data.breakoutRoomId
        let request = SyncSubtitlesRequest(meetingId: self.store.meetingID, breakoutRoomId: breakoutRoomId, forceSync: true)
        self.store.meeting.httpClient.send(request)
        //  更改语言后需要设置flag为true通知再次Rust全量拉取数据
        self.store.hasFirstCallSyncSubtitles = true
        self.subtitleLanguagesSubject.onNext(())
    }
}

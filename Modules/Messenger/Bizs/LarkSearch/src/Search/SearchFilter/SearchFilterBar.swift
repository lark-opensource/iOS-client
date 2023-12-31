//
//  SearchFilterBar.swift
//  LarkSearch
//
//  Created by SolaWing on 2021/3/30.
//

import UIKit
import Foundation
import LarkSearchFilter
import LarkSDKInterface
import LarkSearchCore
import RxSwift
import RxCocoa
import LarkMessengerInterface
import EENavigator
import LarkUIKit
import LKCommonsTracker
import Homeric
import LarkCore
import LarkContainer
import LarkNavigator

protocol SearchFilterBarDelegate: AnyObject {
    var containerVC: UIViewController { get }
    var filterPageLocation: String? { get } // 统计字段
    func filterBarDidChangeByUser(_ view: SearchFilterBar, changedFilter: SearchFilter?)
}

extension SearchFilterBarDelegate where Self: UIViewController {
    var containerVC: UIViewController { self }
}

class SearchFilterBar: BaseSearchFilterBar, UserResolverWrapper {

    final class TextValueController: SearchFilterBarItemController {
        var touch: ControlEvent<()> { _view.rx.controlEvent(.touchUpInside) }
        var value: SearchFilter {
            didSet { valueChange() }
        }
        var style: FilterBarStyle {
            didSet {
                _view.style = style
            }
        }
        var view: UIView { _view }
        private lazy var _view = TextValueCell(frame: .zero, style: style, shouldHideExpandArrow: value.sameType(with: .docOwnedByMe(false, userResolver.userID)))
        let userResolver: UserResolver
        init(value: SearchFilter, style: FilterBarStyle, userResolver: UserResolver) {
            self.style = style
            self.value = value
            self.userResolver = userResolver
            valueChange()
        }
        func valueChange() {
            assert(value.isTextType)
            assert(Thread.isMainThread, "should occur on main thread!")
            if value.isEmpty {
                // filter的title没区分value和title，现在也是value覆盖title的，所以这样写没问题，强依赖实现
                _view.title = value.title ?? ""
                _view.value = nil // clear and trigger update
                /// 筛选器为空，不响应【取消】
                _view.switchCancel(cancelEnabled: false)
            } else {
                _view.value = value.title
                /// 筛选器有值，支持【取消】
                _view.switchCancel(cancelEnabled: true)
            }
        }
    }

    final class TextAvatarController: SearchFilterBarItemController {
        var touch: ControlEvent<()> { _view.button.rx.controlEvent(.touchUpInside) }
        var value: SearchFilter {
            didSet { valueChange() }
        }
        var style: FilterBarStyle {
            didSet {
                _view.style = style
            }
        }
        var view: UIView { _view }
        private lazy var _view = TextAvatarCell(frame: .zero, style: style)
        init(value: SearchFilter, style: FilterBarStyle) {
            self.style = style
            self.value = value
            valueChange()
        }
        func valueChange() {
            assert(value.isTextAvatarType)
            assert(Thread.isMainThread, "should occur on main thread!")
            let avatarViews = value.getAvatarViews()
            let breakedTitle = value.breakedTitle
            _view.value = (breakedTitle: breakedTitle, avatarViews: avatarViews)
        }
    }
    final class AvatarsController: SearchFilterBarItemController {
        func moreMember(number num: Int) -> String {
            if num < 1 {
                return ""
            }
            return BundleI18n.LarkSearch.Lark_NewFilter_Search_ChoseMoreSearchItems(num) + " "
        }
        var touch: ControlEvent<()> { _view.rx.controlEvent(.touchUpInside) }
        var value: SearchFilter {
            didSet { valueChange() }
        }
        var view: UIView { _view }
        private lazy var _view = AvatarsCell(frame: .zero, style: style)
        var  style: FilterBarStyle {
            didSet {
                _view.style = style
            }
        }
        init(value: SearchFilter, style: FilterBarStyle) {
            self.style = style
            self.value = value
            valueChange()
        }
        func valueChange() {
            assert(value.isAvatarsType)
            assert(Thread.isMainThread, "should occur on main thread!")
            let leftPartTitle = value.title
            let avatarViews = value.getAvatarViews()
            let remainNumber = value.avatarKeys.count - 1
            let rightPartTitle = moreMember(number: remainNumber)
            _view.value = (leftPartTitle, avatarViews, rightPartTitle)
            if value.isEmpty {
                /// 筛选器为空，不响应【取消】
                _view.switchCancel(cancelEnabled: false)
            } else {
                /// 筛选器有值，支持【取消】
                _view.switchCancel(cancelEnabled: true)
            }
        }
    }

    private var itemControllers: [SearchFilterBarItemController] = [] {
        didSet {
            oldValue.forEach { $0.view.removeFromSuperview() }
            itemControllersBag = DisposeBag()

            for i in itemControllers {
                contentView.addArrangedSubview(i.view)
                i.touch.subscribe(onNext: { [weak self] in
                                      self?.touch(filter: i)
                                  }).disposed(by: itemControllersBag)
            }
            // TODO: reset button display
        }
    }
    weak var delegate: SearchFilterBarDelegate?
    var itemControllersBag = DisposeBag()
    public override var style: FilterBarStyle {
        didSet {
            setStyle(style)
        }
    }
    let userResolver: UserResolver
    init(userResolver: UserResolver, frame: CGRect = .zero, filters: [SearchFilter], delegate: SearchFilterBarDelegate, style: FilterBarStyle = .light) {
        self.userResolver = userResolver
        self.delegate = delegate
        super.init(frame: frame, style: style)

        self.filters = filters

        setStyle(style)
        self.resetView.addTarget(self, action: #selector(touchResetButton), for: .touchUpInside)
    }

    private func setStyle(_ style: FilterBarStyle) {
        let backgroundColor: UIColor
        switch style {
        case .light:
            backgroundColor = UIColor.ud.bgBody
        case .dark:
            backgroundColor = UIColor.ud.bgBase
        }
        self.backgroundColor = backgroundColor
        gradientView.colors = [backgroundColor.withAlphaComponent(0), backgroundColor, backgroundColor]
        for itemController in itemControllers {
            itemController.style = style
        }
    }

    override var intrinsicContentSize: CGSize { .init(width: UIView.noIntrinsicMetric, height: 60) }

    /// 给外部使用的filter，实际值存放在对应的controller上..
    var filters: [SearchFilter] {
        get { itemControllers.map { $0.value } }
        set {
            defer { filterChange(byUser: false) }

            let new = newValue.filter { $0.displayType != .unknown }
            // 大部分都是更新value，不更新type，简单尝试复用
            if new.count == itemControllers.count {
                let filters = self.filters
                if zip(new, filters).allSatisfy({ $1.displayType == $0.displayType }) {
                    for (v, controller) in zip(new, itemControllers) {
                        controller.value = v
                    }
                    return
                }
            }
            // rebuild
            self.itemControllers = new.compactMap { [weak self] in
                guard let self = self else { return nil }
                switch $0.displayType {
                case .avatars:
                    let itemController = AvatarsController(value: $0, style: self.style)
                    (itemController.view as? BaseSearchFilterBar.AvatarsCell)?.expandDownFilledView.onClick = { [weak self] in
                        itemController.value = itemController.value.reset()
                        self?.filterChange(byUser: true)
                    }
                    return itemController
                case .text:
                    let itemController = TextValueController(value: $0, style: self.style, userResolver: self.userResolver)
                    (itemController.view as? BaseSearchFilterBar.TextValueCell)?.expandDownFilledView.onClick = { [weak self] in
                        itemController.value = itemController.value.reset()
                        self?.filterChange(byUser: true)
                    }
                    return itemController
                case .textAvatar:
                    return TextAvatarController(value: $0, style: self.style)
                default:
                    assertionFailure("unreachable code!!")
                    return nil
                }
            }
        }
    }

    /// - Parameters:
    ///   - byUser: 用户UI控件触发导致的变更
    func filterChange(byUser: Bool, changedFilter: SearchFilter? = nil) {
        self.resetVisible = itemControllers.contains { !$0.value.isEmpty }
        if byUser { delegate?.filterBarDidChangeByUser(self, changedFilter: changedFilter) }
    }

    fileprivate func filterChange(from: SearchFilterBarItemController) {
       filterChange(byUser: true, changedFilter: from.value)
       refocus(filter: from)
     }

     private func refocus(filter: SearchFilterBarItemController) {
       self.layoutIfNeeded() // 更新布局和ScrollView位置
       let rect = filter.view.convert(filter.view.bounds, to: scrollView)
       scrollView.scrollRectToVisible(rect, animated: true)
     }

    @objc
    func touchResetButton() {
        for i in itemControllers {
            i.value = i.value.reset()
        }
        filterChange(byUser: true)
    }

    func replaceFilter(filter: SearchFilter) {
        guard let replaceIndex = filters.firstIndex(where: { $0.sameType(with: filter) }) else { return }
        filters[replaceIndex] = filter
    }

    /// picker implemented
    fileprivate func touch(filter: SearchFilterBarItemController) {
        // TODO: 部分filter感觉效果一样，可以考虑合并?
        guard let delegate = delegate else { return }
        if let info = filter.value.logInfo {
            SearchFilterWrapperView.logger.info("[LarkSearch] advance search update \(info.name) filter",
                                                additionalData: info.data)
        }
        handle(filter: filter, delegate: delegate) { [weak self] in
            self?.removeSelectedRecommendFilters(current: filter.value)
        }
    }

    func removeAllRecommendFilters() {
        self.filters = self.filters.filter({ item in
            if case .recommend = item { return false }
            return true
        })
    }

    func removeSelectedRecommendFilters(current: SearchFilter) {
        self.filters = self.filters.filter({ item in
            if case let .recommend(recommended) = item {
                return !current.sameType(with: recommended)
            }
            return true
        })
    }

    func markAllFilterNotRecommend() {
        self.filters = self.filters.map({ item in
            if case let .commonFilter(.mainFrom(fromIds, recommends, _, isRecommendResultSelected)) = item {
                return .commonFilter(.mainFrom(fromIds: fromIds, recommends: recommends, fromType: .user, isRecommendResultSelected: isRecommendResultSelected))
            }
            if case let .chatter(mode, items, recommends, _, isRecommendResultSelected) = item {
                return .chatter(mode: mode, picker: items, recommends: recommends, fromType: .user, isRecommendResultSelected: isRecommendResultSelected)
            }
            if case let .docFrom(fromIds, recommends, _, isRecommendResultSelected) = item {
                return .docFrom(fromIds: fromIds, recommends: recommends, fromType: .user, isRecommendResultSelected: isRecommendResultSelected)
            }
            return item
        })
    }

    fileprivate func handle(filter: SearchFilterBarItemController, delegate: SearchFilterBarDelegate, completion: (() -> Void)? = nil) {
        switch filter.value {
        case let .recommend(recommended):
            if let recommendFilterIndex = itemControllers.firstIndex(where: { $0.value.sameType(with: filter.value) }) {
                filters.remove(at: recommendFilterIndex)
            }
            for (index, itemController) in itemControllers.enumerated() where itemController.value.sameType(with: recommended) {
                itemController.value = recommended
            }
            if let recommendedController = itemControllers.first(where: {
                $0.value.sameType(with: recommended)
            }) {
                filterChange(byUser: true, changedFilter: filter.value)
                refocus(filter: recommendedController)
            } else {
                filterChange(from: filter)
            }
        case let .commonFilter(commonFilter):
            switch commonFilter {
            case let .mainFrom(fromIds, recommends, _, _):
                touchChatterPicker(items: fromIds, delegate: delegate, title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark, recommendList: recommends) { [weak self] (items, isRecommendSelected) in
                    filter.value = .commonFilter(.mainFrom(fromIds: items, recommends: [], fromType: .user, isRecommendResultSelected: isRecommendSelected))
                    completion?()
                    self?.filterChange(from: filter)
                }
            case .mainDate(let date):
                var body: SearchDateFilterBody
                if let date = date {
                    body = SearchDateFilterBody(startDate: date.startDate, endDate: date.endDate, enableSelectFuture: false)
                } else {
                    body = SearchDateFilterBody(startDate: nil, endDate: Date(), enableSelectFuture: false)
                }
                body.fromView = filter.view
                filter.view.window?.endEditing(true)
                body.confirm = { (vc, startDate, endDate) in
                    filter.value = .commonFilter(.mainDate(date: SearchFilter.FilterDate(startDate: startDate, endDate: endDate)))
                    vc.dismiss(animated: false, completion: nil)
                    self.filterChange(from: filter)
                }
                navigator.present(body: body, from: delegate.containerVC)
                /// 这个文件已经是旧的了，为修复warning补齐
            case .mainIn, .mainWith:
                fallthrough // use unknown default setting to fix warning
            @unknown default:
                assert(false, "new value")
                break
            }
        case let .chatter(mode, items, recommends, _, _):
            // TODO 区分群内
            touchChatterPicker(filter: filter,
                               items: items,
                               mode: mode,
                               title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark,
                               recommendList: recommends,
                               delegate: delegate,
                               finish: completion)
        case let .docFrom(fromIds, recommends, _, _):
            touchChatterPicker(items: fromIds, delegate: delegate, title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark, recommendList: recommends) { [weak self] (items, isRecommendResultSelected) in
                filter.value = .docFrom(fromIds: items, recommends: [], fromType: .user, isRecommendResultSelected: isRecommendResultSelected)
                completion?()
                self?.filterChange(from: filter)
            }
        case .date(let date, let source):
            var body: SearchDateFilterBody
            if let date = date {
                body = SearchDateFilterBody(startDate: date.startDate, endDate: date.endDate, enableSelectFuture: false)
            } else {
                body = SearchDateFilterBody(startDate: nil, endDate: Date(), enableSelectFuture: false)
            }
            body.fromView = filter.view
            filter.view.window?.endEditing(true)
            body.confirm = { [weak self] (vc, startDate, endDate) in
                filter.value = .date(date: SearchFilter.FilterDate(startDate: startDate, endDate: endDate), source: source)
                completion?()
                vc.dismiss(animated: false, completion: nil)
                self?.filterChange(from: filter)
            }
            navigator.present(body: body, from: delegate.containerVC)
            touchFilterStat(name: Homeric.SEARCH_FILTER_TIME)
        case .messageMatch(let selectedTypes):
            let selection = MessageContentMatchSelection(defaultTypes: selectedTypes)
            let viewController = MultiSelectionViewController(selection: selection, isModeled: Display.pad)
            viewController.didSelecteItems = { [weak self] (types, from) in
                if let types = types as? [SearchFilter.MessageContentMatchType] {
                    filter.value = .messageMatch(types)
                }
                completion?()
                from.dismiss(animated: true, completion: nil)
                self?.filterChange(from: filter)
            }
            if Display.pad {
                navigator.present(viewController, wrap: LkNavigationController.self, from: delegate.containerVC,
                                         prepare: { $0.modalPresentationStyle = .formSheet })
            } else {
                viewController.modalPresentationStyle = .overCurrentContext
                viewController.transitioningDelegate = viewController
                navigator.present(viewController, from: delegate.containerVC, animated: true)
            }
        case .docOwnedByMe(let value, let uid):
            filter.value = .docOwnedByMe(!value, uid)
            completion?()
            self.filterChange(from: filter)
        case .messageType(let selectedType):
            let selection = MessageSelection(userResolver: userResolver, selectedType: selectedType)
            let viewController = SingleSelectionFilterViewController(selection: selection, isModeled: Display.pad)
            viewController.didSelectType = { [weak self] (type, from) in
                if let type = type as? MessageFilterType {
                    filter.value = .messageType(type)
                } else {
                    filter.value = .messageType(.all)
                }
                completion?()
                from.dismiss(animated: true, completion: nil)
                self?.filterChange(from: filter)
            }
            if Display.pad {
                navigator.present(viewController, wrap: LkNavigationController.self, from: delegate.containerVC,
                                         prepare: { $0.modalPresentationStyle = .formSheet })
            } else {
                viewController.modalPresentationStyle = .overCurrentContext
                viewController.transitioningDelegate = viewController
                navigator.present(viewController, from: delegate.containerVC, animated: true)
            }
        case let .chatMemeber(mode, selectedItems):
            touchChatterPicker(items: selectedItems, delegate: delegate, title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark) { [weak self] (items, _) in
                filter.value = .chatMemeber(mode: mode, picker: items)
                completion?()
                self?.filterChange(from: filter)
            }
            if mode == .thread {
                touchFilterStat(name: Homeric.SEARCH_FILTER_CHANNELS_MEMBER)
            }
        case let .docSharer(docItems):
            touchChatterPicker(items: docItems, delegate: delegate, title: BundleI18n.LarkSearch.Lark_Search_ResultTagShared) { [weak self] (items, _) in
                filter.value = .docSharer(items)
                completion?()
                self?.filterChange(from: filter)
            }
        case .chatType(let defaultTypes):
            let selection = ChatFilterSelection(defaultTypes: defaultTypes)
            let viewController = MultiSelectionViewController(selection: selection, isModeled: Display.pad)
            viewController.didSelecteItems = { [weak self] (types, from) in
                if let types = types as? [ChatFilterType] {
                    filter.value = .chatType(types)
                }
                completion?()
                from.dismiss(animated: true, completion: nil)
                self?.filterChange(from: filter)
            }
            if Display.pad {
                navigator.present(viewController, wrap: LkNavigationController.self, from: delegate.containerVC,
                                         prepare: { $0.modalPresentationStyle = .formSheet })
            } else {
                viewController.modalPresentationStyle = .overCurrentContext
                viewController.transitioningDelegate = viewController
                navigator.present(viewController, from: delegate.containerVC, animated: true)
            }
        case .chatKeyWord(let keyWord):
            let vc = ChatKeyWordFilterViewController(keyWord: keyWord)
            vc.didEnterKeyWord = { [weak self] (keyWord, vc) in
                filter.value = .chatKeyWord(keyWord ?? "")
                completion?()
                vc.dismiss(animated: true, completion: nil)
                self?.filterChange(from: filter)
            }
            vc.modalPresentationStyle = .overCurrentContext
            vc.transitioningDelegate = vc
            navigator.present(vc, from: delegate.containerVC, animated: true)
        case .threadType(let type):
            let vc = ThreadTypeFilterViewController(selectedType: type)
            vc.threadTypeHandler = { [weak self] (type, vc) in
                filter.value = .threadType(type)
                completion?()
                vc.dismiss(animated: true, completion: nil)
                self?.filterChange(from: filter)
                Tracker.post(TeaEvent(Homeric.SEARCH_FILTER_CHANNELS_TYPE, params: ["type": type.trackInfo]))
            }
            vc.modalPresentationStyle = .overCurrentContext
            vc.transitioningDelegate = vc
            navigator.present(vc, from: delegate.containerVC, animated: true)
        case .docCreator(let items, let uid):
            touchChatterPicker(items: items, delegate: delegate, title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark) { [weak self] (items, _) in
                filter.value = .docCreator(items, uid)
                completion?()
                self?.filterChange(from: filter)
            }
            touchFilterStat(name: Homeric.SEARCH_FILTER_DOCS_OWNER)
        case .wikiCreator(let items):
            touchChatterPicker(items: items, delegate: delegate, title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark) { [weak self] (items, _) in
                filter.value = .wikiCreator(items)
                completion?()
                self?.filterChange(from: filter)
            }
            touchFilterStat(name: Homeric.SEARCH_FILTER_WIKI_OWNER)
        case .docType(let type):
            let selection = DocTypeSelection(selectedType: type)
            let viewController = SingleSelectionFilterViewController(selection: selection, isModeled: Display.pad)
            viewController.didSelectType = { [weak self] (type, from) in
                if let type = type as? SearchFilter.DocType {
                    filter.value = .docType(type)
                } else {
                    filter.value = .docType(.all)
                }
                completion?()
                from.dismiss(animated: true, completion: nil)
                self?.filterChange(from: filter)
            }
            if Display.pad {
                navigator.present(viewController, wrap: LkNavigationController.self, from: delegate.containerVC,
                                         prepare: { $0.modalPresentationStyle = .formSheet })
            } else {
                viewController.modalPresentationStyle = .overCurrentContext
                viewController.transitioningDelegate = viewController
                navigator.present(viewController, from: delegate.containerVC, animated: true)
            }
        case .docContentType(let type):
            let selection = DocContentSelection(selectedType: type)
            let viewController = SingleSelectionFilterViewController(selection: selection, isModeled: Display.pad)
            viewController.didSelectType = { [weak self] (type, from) in
                if let type = type as? DocContentType {
                    filter.value = .docContentType(type)
                } else {
                    filter.value = .docContentType(.fullContent)
                }
                completion?()
                from.dismiss(animated: true, completion: nil)
                self?.filterChange(from: filter)
            }
            if Display.pad {
                navigator.present(viewController, wrap: LkNavigationController.self, from: delegate.containerVC,
                                         prepare: { $0.modalPresentationStyle = .formSheet })
            } else {
                viewController.modalPresentationStyle = .overCurrentContext
                viewController.transitioningDelegate = viewController
                navigator.present(viewController, from: delegate.containerVC, animated: true)
            }
        case .docFormat(let types, let source):
            let selection = DocTypeFilterSelection(defaultTypes: types)
            let viewController = MultiSelectionViewController(selection: selection, isModeled: Display.pad)
            viewController.didSelecteItems = { [weak self] (types, from) in
                if let types = types as? [DocFormatType] {
                    filter.value = .docFormat(types, source)
                }
                completion?()
                from.dismiss(animated: true, completion: nil)
                self?.filterChange(from: filter)
            }
            if Display.pad {
                navigator.present(viewController, wrap: LkNavigationController.self, from: delegate.containerVC,
                                         prepare: { $0.modalPresentationStyle = .formSheet })
            } else {
                viewController.modalPresentationStyle = .overCurrentContext
                viewController.transitioningDelegate = viewController
                navigator.present(viewController, from: delegate.containerVC, animated: true)
            }
        case .docSortType(let type):
            let selection = DocSortTypeSelection(selectedType: type)
            let viewController = SingleSelectionFilterViewController(selection: selection, isModeled: Display.pad)
            viewController.didSelectType = { [weak self] (type, from) in
                if let type = type as? SearchFilter.DocSortType {
                    filter.value = .docSortType(type)
                } else {
                    filter.value = .docSortType(.mostRelated)
                }
                completion?()
                from.dismiss(animated: true, completion: nil)
                self?.filterChange(from: filter)
            }
            if Display.pad {
                navigator.present(viewController, wrap: LkNavigationController.self, from: delegate.containerVC,
                                         prepare: { $0.modalPresentationStyle = .formSheet })
            } else {
                viewController.modalPresentationStyle = .overCurrentContext
                viewController.transitioningDelegate = viewController
                navigator.present(viewController, from: delegate.containerVC, animated: true)
            }
        case .groupSortType(let type):
            let selection = GroupSortTypeSelection(selectedType: type)
            let viewController = SingleSelectionFilterViewController(selection: selection, isModeled: Display.pad)
            viewController.didSelectType = { [weak self] (type, from) in
                if let type = type as? SearchFilter.GroupSortType {
                    filter.value = .groupSortType(type)
                } else {
                    filter.value = .groupSortType(.mostRelated)
                }
                completion?()
                from.dismiss(animated: true, completion: nil)
                self?.filterChange(from: filter)
            }
            if Display.pad {
                navigator.present(viewController, wrap: LkNavigationController.self, from: delegate.containerVC,
                                         prepare: { $0.modalPresentationStyle = .formSheet })
            } else {
                viewController.modalPresentationStyle = .overCurrentContext
                viewController.transitioningDelegate = viewController
                navigator.present(viewController, from: delegate.containerVC, animated: true)
            }
        case .general(_), .chat(_, _), .docPostIn(_), .docFolderIn(_), .docWorkspaceIn(_), .withUsers, .messageAttachmentType, .messageChatType, .specificFilterValue(_, _, _):
            fallthrough // use unknown default setting to fix warning
        @unknown default:
            assert(false, "new value")
            break
        }
    }

    private func showUniversalPicker(pickType: UniversalPickerType,
                                     items: [ForwardItem],
                                     from: UIViewController,
                                     finish: @escaping ([ForwardItem]) -> Void) {
        var body = SearchUniversalPickerBody(pickType: pickType,
                                             selectedItems: items)
        body.didFinishPick = { (viewController, items) in
            viewController.dismiss(animated: true, completion: nil)
            finish(items)
        }
        navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepare: { $0.modalPresentationStyle = .formSheet })
    }

    fileprivate func touchChatterPicker(filter: SearchFilterBarItemController,
                                        items: [SearchChatterPickerItem],
                                        mode: ChatFilterMode,
                                        title: String,
                                        recommendList: [SearchResultType] = [],
                                        delegate: SearchFilterBarDelegate,
                                        finish: (() -> Void)?) {
        touchChatterPicker(items: items, delegate: delegate, title: title, recommendList: recommendList) { [weak self] (items, isRecommendResultSelected) in
            filter.value = .chatter(mode: mode, picker: items, recommends: [], fromType: .user, isRecommendResultSelected: isRecommendResultSelected)
            finish?()
            self?.filterChange(from: filter)
        }

        switch mode {
        case .thread:
            touchFilterStat(name: Homeric.SEARCH_FILTER_POSTS_MEMBER)
        @unknown default:
            touchFilterStat(name: Homeric.SEARCH_FILTER_PEOPLE)
        }
    }
    fileprivate func touchChatterPicker(items: [SearchChatterPickerItem],
                                        delegate: SearchFilterBarDelegate,
                                        title: String,
                                        recommendList: [SearchResultType] = [],
                                        finish: @escaping ([SearchChatterPickerItem], Bool) -> Void) {
        guard let chatterAPI = try? userResolver.resolve(assert: ChatterAPI.self) else { return }
        var body = ChatterPickerBody()
        body.defaultSelectedChatterIds = items.map { $0.chatterID }
        body.selectStyle = items.isEmpty ? .singleMultiChangeable : .multi
        body.title = title
        body.allowSelectNone = items.isEmpty ? false : true
        body.enableSearchBot = true
        body.supportUnfoldSelected = true
        body.recommendList = recommendList
        body.hasSearchFromFilterRecommend = true
        body.selectedCallback = { (vc, result) in
            var items = [SearchChatterPickerItem]()
            let chatterIDs = result.chatterInfos.map { $0.ID }
            let botItems = result.botInfos.map { SearchChatterPickerItem.bot($0) }
            items.append(contentsOf: botItems)
            if !chatterIDs.isEmpty {
                chatterAPI.getChatters(ids: chatterIDs)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { (chatterMap) in
                        vc?.dismiss(animated: true, completion: nil)

                        let chatterItems = chatterIDs
                            .compactMap { chatterMap[$0] }
                            .map { SearchChatterPickerItem.chatter($0) }
                        items.append(contentsOf: chatterItems)
                        finish(items, result.isRecommendSelected)
                    }).disposed(by: self.itemControllersBag)
            } else {
                vc?.dismiss(animated: true, completion: nil)
                finish(items, result.isRecommendSelected)
            }
        }
        navigator.present(body: body, from: delegate.containerVC, prepare: { $0.modalPresentationStyle = .formSheet })
    }
    @inlinable
    func touchFilterStat(name: String, params: [String: String] = [:]) {
        var params = params
        if let location = delegate?.filterPageLocation {
            params["location"] = location
        }
        Tracker.post(TeaEvent(name, params: params))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
protocol SearchInChatFilterBarDelegate: SearchFilterBarDelegate {
    var chatID: String { get }
    var enableMindnote: Bool { get }
    var enableBitable: Bool { get }
}
final class SearchInChatFilterBar: SearchFilterBar {

    init(userResolver: UserResolver, frame: CGRect = .zero, filters: [SearchFilter], delegate: SearchInChatFilterBarDelegate) {
        super.init(userResolver: userResolver, frame: frame, filters: filters, delegate: delegate, style: .light)
        scrollView.snp.makeConstraints {
            $0.left.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override fileprivate func handle(filter: SearchFilterBarItemController, delegate parentDelegate: SearchFilterBarDelegate, completion: (() -> Void)? = nil) {
        guard let delegate = parentDelegate as? SearchInChatFilterBarDelegate else {
            super.handle(filter: filter, delegate: parentDelegate)
            return
        }
        switch filter.value {
        case let .chatter(mode, items, _, _, _):
            var body = SearchGroupChatterPickerBody(title: BundleI18n.LarkSearch.Lark_Legacy_SelectLabel,
                                                    chatId: delegate.chatID,
                                                    selectedChatterIds: items.map { $0.chatterID })
            body.confirm = { [weak self] (vc, chatters) in
                let items = chatters.map { SearchChatterPickerItem.chatter($0) }
                filter.value = .chatter(mode: mode, picker: items, recommends: [], fromType: .user, isRecommendResultSelected: false)
                completion?()
                vc.dismiss(animated: true, completion: nil)
                self?.filterChange(from: filter)
            }
            navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: delegate.containerVC,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
            touchFilterStat(name: Homeric.SEARCH_FILTER_PEOPLE)
        case .docFormat(_, let source):
            let enableNewSlides = SearchFeatureGatingKey.docNewSlides.isUserEnabled(userResolver: userResolver)
            let viewController = DocFilterViewController(enableMindnote: delegate.enableMindnote, enableBitable: delegate.enableBitable, isModeled: Display.pad, enableNewSlides: enableNewSlides)
            viewController.didFinishChoosingFilter = { [weak self] (from, docType) in
                filter.value = .docFormat([docType], source)
                completion?()
                from.dismiss(animated: true, completion: nil)
                self?.filterChange(from: filter)
                self?.touchFilterStat(name: Homeric.SEARCH_FILTER_DOCS_TYPE, params: ["type": docType.trackInfo])
            }
            if Display.pad {
                navigator.present(viewController, wrap: LkNavigationController.self, from: delegate.containerVC,
                                         prepare: { $0.modalPresentationStyle = .formSheet })
            } else {
                navigator.present(viewController, from: delegate.containerVC, animated: false)
            }
        default:
            super.handle(filter: filter, delegate: delegate)
        }
    }
}

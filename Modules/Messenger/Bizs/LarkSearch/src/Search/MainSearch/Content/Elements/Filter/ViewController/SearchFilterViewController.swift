//
//  SearchFilterViewController.swift
//  LarkSearch
//
//  Created by Patrick on 2022/5/19.
//

import Foundation
import LarkSearchFilter
import RxSwift
import RxCocoa
import LarkSearchCore
import LarkSDKInterface
import LarkMessengerInterface
import EENavigator
import LarkUIKit
import UIKit
import Homeric
import LarkContainer
import LKCommonsTracker
import LarkModel
import UniverseDesignToast

protocol SearchFilterViewModelFactory {
    func makeSearchFilterViewModel() -> SearchFilterViewModel?
}

final class SearchFilterViewController: NiblessViewController, UserResolverWrapper, SearchPickerDelegate {
    let viewModel: SearchFilterViewModel
    let userResolver: UserResolver
    weak var container: UIViewController?
    var commonlyUsedFiltersHasDocOwnedByMe: Bool
    private var newPickerAction: (selectItemFilterBlock: ((LarkModel.PickerItem) -> Bool)?,
                                  finishBlock: ([LarkModel.PickerItem]) -> Void)?
    private lazy var filterView: BaseSearchFilterBar = {
        let view = BaseSearchFilterBar(frame: .zero, style: .light)
        return view
    }()
    private var itemControllersBag = DisposeBag()
    private var itemControllers: [SearchFilterBarItemController] = [] {
        didSet {
            oldValue.forEach { $0.view.removeFromSuperview() }
            itemControllersBag = DisposeBag()

            for i in itemControllers {
                filterView.contentView.addArrangedSubview(i.view)
                i.touch
                    .subscribe(onNext: { [weak self] in
                        self?.touch(filter: i)
                    })
                    .disposed(by: itemControllersBag)
            }
            // TODO: reset button display
        }
    }

    // 深色还是浅色
    var style: FilterBarStyle {
        didSet {
            setStyle(style)
        }
    }
    private func setStyle(_ style: FilterBarStyle) {
        let backgroundColor: UIColor
        switch style {
        case .light:
            backgroundColor = UIColor.ud.bgBody
        case .dark:
            backgroundColor = UIColor.ud.bgBase
        }
        filterView.backgroundColor = backgroundColor
        filterView.gradientView.colors = [backgroundColor.withAlphaComponent(0), backgroundColor, backgroundColor]
        for itemController in itemControllers {
            itemController.style = style
        }
    }

    init(userResolver: UserResolver, viewModel: SearchFilterViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.style = viewModel.config.filterBarStyle
        self.commonlyUsedFiltersHasDocOwnedByMe = false
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupSubscribe()
        viewModel.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.viewDidAppear(animated)
    }

    private func setupViews() {
        view.addSubview(filterView)
        filterView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        setStyle(style)
        filterView.resetView.addTarget(self, action: #selector(touchResetButton), for: .touchUpInside)
    }

    private let disposeBag = DisposeBag()
    private func setupSubscribe() {
        viewModel.shouldReloadFilters
            .drive(onNext: { [weak self] shouldReloadFilters in
                guard let self = self, shouldReloadFilters else { return }
                defer {
                    self.filterChange(byUser: false)
                }
                let recommendFilters = self.viewModel.recommendFilters.filter { $0.displayType != .unknown }
                let commonlyUsedFilters = self.viewModel.commonlyUsedFilters.filter { $0.displayType != .unknown }
                let filters = self.viewModel.filters.filter { $0.displayType != .unknown }
                // rebuild
                let recommendItems = self.makeFilterItems(filters: recommendFilters)
                let items = self.makeFilterItems(filters: self.mergeAndDeleteDuplicatedFilters(commonlyUsedFilters, filters))
                self.itemControllers = recommendItems + items
            })
            .disposed(by: disposeBag)
        viewModel.filterRefocus.drive( onNext: { [weak self] filters in
            guard let self = self else { return }
            if let firstFilter = filters.first(where: { filter in
                !filter.isEmpty
            }) {
                self.refoucTo(filter: firstFilter)
            }
        })
    }

    private func refoucTo(filter: SearchFilter) {
        if let targetItemController = self.itemControllers.first(where: { item in
            item.value.sameType(with: filter)
        }) {
            refocus(filter: targetItemController)
        }
    }

    private func makeFilterItems(filters: [SearchFilter]) -> [SearchFilterBarItemController] {
        return filters.compactMap {
            switch $0.displayType {
            case .avatars:
                let itemController = AvatarsController(value: $0, style: self.style)
                (itemController.view as? BaseSearchFilterBar.AvatarsCell)?.expandDownFilledView.onClick = { [weak self, weak itemController] in
                    self?.filterChange(byUser: true, changedFilter: itemController?.value.reset())
                }
                return itemController
            case .text:
                let itemController = TextValueController(value: $0, style: self.style, userResolver: userResolver)
                (itemController.view as? BaseSearchFilterBar.TextValueCell)?.expandDownFilledView.onClick = { [weak self, weak itemController] in
                    self?.filterChange(byUser: true, changedFilter: itemController?.value.reset())
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

    // User Interaction
    private func touch(filter: SearchFilterBarItemController) {
        guard let container = container else {
            return
        }
        handle(filter: filter, from: container) { [weak self] in
            self?.viewModel.removeAllRecommendFilters()
        }
    }

    private func handle(filter: SearchFilterBarItemController,
                        from: UIViewController,
                        completion: (() -> Void)? = nil) {
        switch filter.value {
        case let .recommend(recommended):
            viewModel.removeRecommendFilter(filter.value)
            for (index, itemController) in itemControllers.enumerated() where itemController.value.sameType(with: recommended) {
                itemController.value = recommended
                recommendFilterChange(from: itemController, changedFilter: recommended)
            }
        case let .specificFilterValue(commonlyUsed, title, isSelect):
            let newFilter = SearchFilter.specificFilterValue(commonlyUsed, title, !isSelect)
            self.commonlyUsedFilterChange(from: filter, changedFilter: newFilter)
            if !isSelect {
                self.viewModel.clickCommonlyUsedFilter(filter: newFilter)
            }
            completion?()
        case let .commonFilter(commonFilter):
            switch commonFilter {
            case let .mainFrom(fromIds, recommends, _, _):
                showChatterPicker(items: fromIds,
                                  title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark,
                                  from: from,
                                  recommendList: recommends) { [weak self] (items, isRecommendSelected) in
                    guard let self = self else { return }
                    let newFilter = SearchFilter.commonFilter(.mainFrom(fromIds: items, recommends: [], fromType: .user, isRecommendResultSelected: isRecommendSelected))
                    completion?()
                    self.filterChange(from: filter, changedFilter: newFilter)
                }
            case let .mainWith(withIds):
                showChatterPicker(items: withIds,
                                  title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark,
                                  from: from) { [weak self] (items, _) in
                    guard let self = self else { return }
                    let newFilter = SearchFilter.commonFilter(.mainWith(items))
                    completion?()
                    self.filterChange(from: filter, changedFilter: newFilter)
                }
            case let .mainIn(items):
                showUniversalPicker(pickType: .chat(chatMode: .unlimited),
                                    items: items,
                                    supportFrozenChat: true,
                                    from: from) { [weak self] pickedItems in
                    guard let self = self else { return }
                    let newFilter = SearchFilter.commonFilter(.mainIn(inIds: pickedItems))
                    filter.value = newFilter
                    completion?()
                    self.filterChange(from: filter, changedFilter: newFilter)
                }
            case .mainDate(let date):
                showDatePicker(date: date, enableSelectFuture: true, from: from, fromView: filter.view) { [weak self] startDate, endDate in
                    guard let self = self else { return }
                    let newFilter: SearchFilter
                    if startDate == nil, endDate == nil {
                        newFilter = SearchFilter.commonFilter(.mainDate(date: nil))
                    } else {
                        newFilter = SearchFilter.commonFilter(.mainDate(date: SearchFilter.FilterDate(startDate: startDate, endDate: endDate)))
                    }
                    completion?()
                    self.filterChange(from: filter, changedFilter: newFilter)
                }
            }
        case let .general(generalFilter):
            switch generalFilter {
            case let .user(info, items):
                showChatterPicker(items: items,
                                  title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark,
                                  from: from) { [weak self] pickerItems, _ in
                    guard let self = self else { return }
                    let newFilter = SearchFilter.general(.user(info, pickerItems))
                    completion?()
                    self.filterChange(from: filter, changedFilter: newFilter)
                }
            case let .userChat(info, items):
                showUniversalPicker(pickType: .userAndGroupChat,
                                    items: items,
                                    from: from) { [weak self] pickers in
                    guard let self = self else { return }
                    let newFilter = SearchFilter.general(.userChat(info, pickers))
                    completion?()
                    self.filterChange(from: filter, changedFilter: newFilter)
                }
            case let .date(info, date):
                showDatePicker(date: date, enableSelectFuture: true, from: from, fromView: filter.view) { [weak self] startDate, endDate in
                    guard let self = self else { return }
                    let newFilter: SearchFilter
                    if startDate == nil, endDate == nil {
                        newFilter = SearchFilter.general(.date(info, nil))
                    } else {
                        newFilter = SearchFilter.general(.date(info, SearchFilter.FilterDate(startDate: startDate, endDate: endDate)))
                    }
                    completion?()
                    self.filterChange(from: filter, changedFilter: newFilter)
                }
            case let .multiple(info, values):
                switch info.filterType {
                case .predefineEnumFilter:
                    let availableItems = info.predefineEnumValues.map { GeneralMultiFilterType(name: $0.displayText, id: $0.id) }
                    let selectedItems = values.flatMap { value -> GeneralMultiFilterType? in
                        if case let .predefined(info) = value {
                            return GeneralMultiFilterType(name: info.name, id: info.id)
                        }
                        return nil
                    }
                    let selection = GeneralMultiSelection(title: info.displayName, availableItems: availableItems, selectedItems: selectedItems)
                    showMultiSelection(selection: selection, from: from) { [weak self] types in
                        guard let self = self else { return }
                        var newFilter: SearchFilter = .general(.multiple(info, []))
                        if let types = types as? [GeneralMultiFilterType] {
                            newFilter = .general(.multiple(info, types.map { .predefined(SearchChatterPickerItem.GeneralFilterOption(name: $0.name, id: $0.id)) }))
                        }
                        completion?()
                        self.filterChange(from: filter, changedFilter: newFilter)
                    }
                case .searchableFilter:
                    let items = values.flatMap { value -> ForwardItem? in
                        if case let .searchable(item) = value {
                            return item
                        }
                        return nil
                    }
                    showUniversalPicker(pickType: .filter(info),
                                        items: items,
                                        enableMyAi: false,
                                        from: from) { [weak self] pickedItems in
                        guard let self = self else { return }
                        let newFilter = SearchFilter.general(.multiple(info, pickedItems.map { .searchable($0) }))
                        completion?()
                        self.filterChange(from: filter, changedFilter: newFilter)
                    }
                @unknown default: break
                }

            case let .single(info, value):
                switch info.filterType {
                case .predefineEnumFilter:
                    let availableItems = info.predefineEnumValues.map { GeneralSingleFilterType(name: $0.displayText, id: $0.id) }
                    let selectedItem = GeneralSingleFilterType(value: value)
                    let selection = GeneralSinleSelection(title: info.displayName, availableItems: availableItems, selectedItem: selectedItem)
                    showSingleSelection(selection: selection, from: from) { [weak self] type in
                        guard let self = self else { return }
                        var newFilter: SearchFilter
                        if let type = type as? GeneralSingleFilterType {
                            newFilter = .general(.single(info, .predefined(SearchChatterPickerItem.GeneralFilterOption(name: type.name, id: type.id))))
                        } else {
                            newFilter = .general(.single(info, nil))
                        }
                        completion?()
                        self.filterChange(from: filter, changedFilter: newFilter)
                    }
                case .searchableFilter:
                    var items: [ForwardItem] = []
                    if let value = value,
                       case let .searchable(item) = value {
                        items.append(item)
                    }
                    showUniversalPicker(pickType: .filter(info),
                                        items: items,
                                        selectMode: .Single,
                                        enableMyAi: false,
                                        from: from) { [weak self] pickedItems in
                        guard let self = self else { return }
                        let newFilter: SearchFilter
                        if let pickedItem = pickedItems.first {
                            newFilter = SearchFilter.general(.single(info, .searchable(pickedItem)))
                        } else {
                            newFilter = SearchFilter.general(.single(info, nil))
                        }
                        completion?()
                        self.filterChange(from: filter, changedFilter: newFilter)
                    }
                @unknown default: break
                }
            case let .calendar(info, selectedCalendars):
                showCalendarPicker(selectedCalendars: selectedCalendars,
                                   title: filter.value.name,
                                   from: from) { [weak self] newSelectedItems in
                    guard let self = self else { return }
                    let newFilter: SearchFilter = .general(.calendar(info, newSelectedItems))
                    completion?()
                    self.filterChange(from: filter, changedFilter: newFilter)
                }
            case let .mailUser(info, pickers):
                showMailUserPicker(selected: pickers,
                                   title: filter.value.name,
                                   from: from) { [weak self] newSelected in
                    guard let self = self else { return }
                    let newFilter: SearchFilter = .general(.mailUser(info, newSelected))
                    completion?()
                    self.filterChange(from: filter, changedFilter: newFilter)
                }
            case let .inputTextFilter(info, texts):
                showInputTextFilterPicker(selectedTexts: texts,
                                          title: filter.value.name,
                                          from: from) { [weak self] newSelected in
                    guard let self = self else { return }
                    let newFilter: SearchFilter = .general(.inputTextFilter(info, newSelected))
                    completion?()
                    self.filterChange(from: filter, changedFilter: newFilter)
                }
            }
        case let .chat(mode, items):
            showUniversalPicker(pickType: .chat(chatMode: mode),
                                items: items,
                                supportFrozenChat: true,
                                from: from) { [weak self] pickedItems in
                guard let self = self else { return }
                let newFilter = SearchFilter.chat(mode: mode, picker: pickedItems)
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case let .docPostIn(items):
            showUniversalPicker(pickType: .chat(chatMode: .unlimited),
                                items: items,
                                supportFrozenChat: true,
                                from: from) { [weak self] pickedItems in
                guard let self = self else { return }
                let newFilter = SearchFilter.docPostIn(pickedItems)
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case let .docFolderIn(selectedItems):
            showUniversalPicker(pickType: .folder, items: selectedItems, from: from) { [weak self] pickedItems in
                guard let self = self else { return }
                let newFilter = SearchFilter.docFolderIn(pickedItems)
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case let .docWorkspaceIn(selectedItems):
            showUniversalPicker(pickType: .workspace, items: selectedItems, from: from) { [weak self] pickedItems in
                guard let self = self else { return }
                let newFilter = SearchFilter.docWorkspaceIn(pickedItems)
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case let .chatter(mode, items, recommends, _, _):
            // TODO 区分群内
            showChatterPicker(items: items,
                              title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark,
                              from: from,
                              recommendList: recommends) { [weak self] pickerdItems, isRecommendResultSelected in
                guard let self = self else { return }
                let newFilter = SearchFilter.chatter(mode: mode, picker: pickerdItems, recommends: [], fromType: .user, isRecommendResultSelected: isRecommendResultSelected)
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case let .withUsers(selectedItems):
            showChatterPicker(items: selectedItems,
                              title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark,
                              from: from) { [weak self] items, _ in
                guard let self = self else { return }
                let newFilter = SearchFilter.withUsers(items)
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case let .docFrom(fromIds, recommends, _, _):
            showChatterPicker(items: fromIds,
                              title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark,
                              from: from,
                              recommendList: recommends) { [weak self] pickerdItems, isRecommendResultSelected in
                guard let self = self else { return }
                let newFilter = SearchFilter.docFrom(fromIds: pickerdItems, recommends: [], fromType: .user, isRecommendResultSelected: isRecommendResultSelected)
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case .date(let date, let source):
            var enableSelectFuture: Bool = true
            switch source {
            case .doc, .message:
                enableSelectFuture = false
            default:
                break
            }
            showDatePicker(date: date, enableSelectFuture: enableSelectFuture, from: from, fromView: filter.view) { [weak self] startDate, endDate in
                guard let self = self else { return }
                let newFilter: SearchFilter
                if startDate == nil, endDate == nil {
                    newFilter = SearchFilter.date(date: nil, source: source)
                } else {
                    newFilter = SearchFilter.date(date: SearchFilter.FilterDate(startDate: startDate, endDate: endDate), source: source)
                }
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case .messageMatch(let selectedTypes):
            let selection = MessageContentMatchSelection(defaultTypes: selectedTypes)
            showMultiSelection(selection: selection, from: from) { [weak self] types in
                guard let self = self else { return }
                var newFilter: SearchFilter = .messageMatch([])
                if let types = types as? [SearchFilter.MessageContentMatchType] {
                    newFilter = .messageMatch(types)
                }
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case .docOwnedByMe(let value, let uid):
            let newFilter = SearchFilter.docOwnedByMe(!value, uid)
            completion?()
            self.filterChange(from: filter, changedFilter: newFilter)
            if SearchFeatureGatingKey.enableCommonlyUsedFilter.isUserEnabled(userResolver: userResolver) &&
                self.commonlyUsedFiltersHasDocOwnedByMe &&
                value {
                self.viewModel.clickCommonlyUsedFilter(filter: newFilter)
            }
        case .messageType(let selectedType):
            let selection = MessageSelection(userResolver: userResolver, selectedType: selectedType)
            showSingleSelection(selection: selection, from: from) { [weak self] type in
                guard let self = self else { return }
                var newFilter: SearchFilter
                if let type = type as? MessageFilterType {
                    newFilter = .messageType(type)
                } else {
                    newFilter = .messageType(.all)
                }
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case .messageAttachmentType(let selectedType):
            let selection = MessageAttachmentSelection(selectedType: selectedType)
            showSingleSelection(selection: selection, from: from) { [weak self] type in
                guard let self = self else { return }
                var newFilter: SearchFilter
                if let type = type as? MessageAttachmentFilterType {
                    newFilter = .messageAttachmentType(type)
                } else {
                    newFilter = .messageAttachmentType(.unknownAttachmentType)
                }
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case let .chatMemeber(mode, selectedItems):
            showChatterPicker(items: selectedItems, title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark, from: from) { [weak self] items, _ in
                guard let self = self else { return }
                let newFilter = SearchFilter.chatMemeber(mode: mode, picker: items)
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case let .docSharer(docItems):
            showChatterPicker(items: docItems, title: BundleI18n.LarkSearch.Lark_Search_ResultTagShared, from: from) { [weak self] items, _ in
                guard let self = self else { return }
                let newFilter = SearchFilter.docSharer(items)
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case .chatType(let defaultTypes):
            let selection = ChatFilterSelection(defaultTypes: defaultTypes)
            showMultiSelection(selection: selection, from: from) { [weak self] types in
                guard let self = self else { return }
                var newFilter: SearchFilter = .chatType([])
                if let types = types as? [ChatFilterType] {
                    newFilter = .chatType(types)
                }
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case .chatKeyWord(let keyWord):
            let vc = ChatKeyWordFilterViewController(keyWord: keyWord)
            vc.didEnterKeyWord = { [weak self] (keyWord, vc) in
                let newFilter = SearchFilter.chatKeyWord(keyWord ?? "")
                completion?()
                vc.dismiss(animated: true, completion: nil)
                self?.filterChange(from: filter, changedFilter: newFilter)
            }
            vc.modalPresentationStyle = .overCurrentContext
            vc.transitioningDelegate = vc
            navigator.present(vc, from: from, animated: true)
        case .threadType(let type):
            let vc = ThreadTypeFilterViewController(selectedType: type)
            vc.threadTypeHandler = { [weak self] (type, vc) in
                let newFilter = SearchFilter.threadType(type)
                completion?()
                vc.dismiss(animated: true, completion: nil)
                self?.filterChange(from: filter, changedFilter: newFilter)
                Tracker.post(TeaEvent(Homeric.SEARCH_FILTER_CHANNELS_TYPE, params: ["type": type.trackInfo]))
            }
            vc.modalPresentationStyle = .overCurrentContext
            vc.transitioningDelegate = vc
            navigator.present(vc, from: from, animated: true)
        case .docCreator(let items, _):
            showChatterPicker(items: items, title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark, from: from) { [weak self, weak userResolver] items, _ in
                guard let self = self, let userResolver = userResolver else { return }
                let newFilter = SearchFilter.docCreator(items, userResolver.userID)
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case .wikiCreator(let items):
            showChatterPicker(items: items, title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark, from: from) { [weak self] items, _ in
                guard let self = self else { return }
                let newFilter = SearchFilter.wikiCreator(items)
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case .docType(let type):
            let selection = DocTypeSelection(selectedType: type)
            showSingleSelection(selection: selection, from: from) { [weak self] type in
                guard let self = self else { return }
                var newFilter: SearchFilter
                if let type = type as? SearchFilter.DocType {
                    newFilter = .docType(type)
                } else {
                    newFilter = .docType(.all)
                }
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case .docContentType(let type):
            let selection = DocContentSelection(selectedType: type)
            showSingleSelection(selection: selection, from: from) { [weak self] type in
                guard let self = self else { return }
                var newFilter: SearchFilter
                if let type = type as? DocContentType {
                    newFilter = .docContentType(type)
                } else {
                    newFilter = .docContentType(.fullContent)
                }
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case .docFormat(let types, let source):
            let selection = DocTypeFilterSelection(defaultTypes: types)
            showMultiSelection(selection: selection, from: from) { [weak self] types in
                guard let self = self else { return }
                var newFilter: SearchFilter = .docFormat([], source)
                if let types = types as? [DocFormatType] {
                    newFilter = .docFormat(types, source)
                }
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case .docSortType(let type):
            let selection = DocSortTypeSelection(selectedType: type)
            showSingleSelection(selection: selection, from: from) { [weak self] type in
                guard let self = self else { return }
                var newFilter: SearchFilter
                if let type = type as? SearchFilter.DocSortType {
                    newFilter = .docSortType(type)
                } else {
                    newFilter = .docSortType(.mostRelated)
                }
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case .messageChatType(let type):
            let selection = ChatTypeSelection(selectedType: type)
            showSingleSelection(selection: selection, from: from) { [weak self] type in
                guard let self = self else { return }
                var newFilter: SearchFilter
                if let type = type as? SearchFilter.MessageChatFilterType {
                    newFilter = .messageChatType(type)
                } else {
                    newFilter = .messageChatType(.all)
                }
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        case .groupSortType(let type):
            let selection = GroupSortTypeSelection(selectedType: type)
            showSingleSelection(selection: selection, from: from) { [weak self] type in
                guard let self = self else { return }
                var newFilter: SearchFilter
                if let type = type as? SearchFilter.GroupSortType {
                    newFilter = .groupSortType(type)
                } else {
                    newFilter = .groupSortType(.mostRelated)
                }
                completion?()
                self.filterChange(from: filter, changedFilter: newFilter)
            }
        @unknown default:
            assert(false, "new value")
            break
        }
    }

    @objc
    func touchResetButton() {
        let resettedFilters = viewModel.filters.map { $0.reset() }
        let resettedCommonlyFilters = viewModel.commonlyUsedFilters.map { $0.reset() }
        viewModel.removeAllRecommendFilters()
        viewModel.replaceAllCommonlyUsedFilters(resettedCommonlyFilters)
        viewModel.replaceAllFilters(resettedFilters)
    }

    /// - Parameters:
    ///   - byUser: 用户UI控件触发导致的变更
    func filterChange(byUser: Bool, changedFilter: SearchFilter? = nil) {
        filterView.resetVisible = itemControllers.contains { !$0.value.isEmpty }
        if byUser { viewModel.replaceFilter(changedFilter) }
    }

     private func refocus(filter: SearchFilterBarItemController) {
         filterView.layoutIfNeeded() // 更新布局和ScrollView位置
         let rect = filter.view.convert(filter.view.bounds, to: filterView.scrollView)
         filterView.scrollView.scrollRectToVisible(rect, animated: true)
     }

    private func filterChange(from: SearchFilterBarItemController, changedFilter: SearchFilter) {
       filterChange(byUser: true, changedFilter: changedFilter)
       refocus(filter: from)
     }

    private func commonlyUsedFilterChange(from: SearchFilterBarItemController, changedFilter: SearchFilter) {
        viewModel.clickCommonlyUsedFilter(changedFilter)
        refocus(filter: from)
    }

    private func recommendFilterChange(from: SearchFilterBarItemController, changedFilter: SearchFilter) {
        viewModel.recommendFilterChanged(for: changedFilter)
        filterChange(from: from, changedFilter: changedFilter)
        viewModel.markAllFilterNotRecommend()
    }

    // MARK: - Router
    private func showChatterPicker(items: [SearchChatterPickerItem],
                                   title: String,
                                   from: UIViewController,
                                   enableMyAi: Bool = SearchFeatureGatingKey.myAiMainSwitch.isEnabled,
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
        body.enableMyAi = enableMyAi
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
        navigator.present(body: body, from: from, prepare: { $0.modalPresentationStyle = .formSheet })
    }

    private func showUniversalPicker(pickType: UniversalPickerType,
                                     items: [ForwardItem],
                                     selectMode: SearchUniversalPickerBody.SelectMode = .Multi,
                                     enableMyAi: Bool = SearchFeatureGatingKey.myAiMainSwitch.isEnabled,
                                     supportFrozenChat: Bool? = nil,
                                     from: UIViewController,
                                     finish: @escaping ([ForwardItem]) -> Void) {
        var body = SearchUniversalPickerBody(pickType: pickType,
                                             selectedItems: items,
                                             selectMode: selectMode,
                                             enableMyAi: enableMyAi,
                                             supportFrozenChat: supportFrozenChat)
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

    private func showSingleSelection(selection: SearchFilterSingleSelection,
                                     from: UIViewController,
                                     finish: @escaping (SearchFilterItem?) -> Void) {
        let viewController = SingleSelectionFilterViewController(selection: selection, isModeled: Display.pad)
        viewController.didSelectType = { (type, from) in
            from.dismiss(animated: true, completion: nil)
            finish(type)
        }
        if Display.pad {
            navigator.present(viewController,
                                     wrap: LkNavigationController.self,
                                     from: from,
                                     prepare: { $0.modalPresentationStyle = .formSheet })
        } else {
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.transitioningDelegate = viewController
            navigator.present(viewController, from: from, animated: true)
        }
    }

    private func showMultiSelection(selection: SearchFilterMultiSelection,
                                    from: UIViewController,
                                    finish: @escaping ([SearchFilterItem]) -> Void) {
        let viewController = MultiSelectionViewController(selection: selection, isModeled: Display.pad)
        viewController.didSelecteItems = { (types, from) in
            from.dismiss(animated: true, completion: nil)
            finish(types)
        }
        if Display.pad {
            navigator.present(viewController, wrap: LkNavigationController.self,
                                     from: from,
                                     prepare: { $0.modalPresentationStyle = .formSheet })
        } else {
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.transitioningDelegate = viewController
            navigator.present(viewController, from: from, animated: true)
        }
    }

    private func showDatePicker(date: SearchFilter.FilterDate?,
                                enableSelectFuture: Bool = false,
                                from: UIViewController,
                                fromView: UIView,
                                finish: @escaping (Date?, Date?) -> Void) {
        var body: SearchDateFilterBody
        if let date = date {
            body = SearchDateFilterBody(startDate: date.startDate, endDate: date.endDate, enableSelectFuture: enableSelectFuture)
        } else {
            let endDate = enableSelectFuture ? nil : Date()
            body = SearchDateFilterBody(startDate: nil, endDate: endDate, enableSelectFuture: enableSelectFuture)
        }
        body.fromView = fromView
        fromView.window?.endEditing(true)
        body.confirm = { (vc, startDate, endDate) in
            vc.dismiss(animated: false, completion: nil)
            finish(startDate, endDate)
        }
        navigator.present(body: body, from: from)
    }

    private func showCalendarPicker(selectedCalendars: [MainSearchCalendarItem],
                                    title: String,
                                    from: UIViewController,
                                    finish: @escaping ([MainSearchCalendarItem]) -> Void) {
        let viewController = SearchCalendarsFilterViewController(userResolver: userResolver,
                                                                 title: title,
                                                                 selectedCalendarItems: selectedCalendars,
                                                                 completion: { items in
            finish(items)
        })
        userResolver.navigator.present(viewController,
                                 wrap: LkNavigationController.self,
                                 from: from,
                                 prepare: { $0.modalPresentationStyle = .formSheet },
                                 animated: true)
    }

    private func showMailUserPicker(selected: [LarkModel.PickerItem],
                                    title: String,
                                    from: UIViewController,
                                    finish: @escaping ([LarkModel.PickerItem]) -> Void) {
        var body = ContactSearchPickerBody()
        let featureConfig = PickerFeatureConfig(
            scene: .searchFilterByOpenMail,
            multiSelection: .init(isOpen: true, preselectItems: selected),
            navigationBar: .init(title: title, sureText: BundleI18n.LarkSearch.Lark_Legacy_Sure, closeColor: UIColor.ud.iconN1,
                                 canSelectEmptyResult: true, sureColor: UIColor.ud.primaryContentDefault),
            searchBar: .init(hasBottomSpace: false, autoFocus: true)
        )
        let chatterEntity = PickerConfig.ChatterEntityConfig(talk: .all,
                                                             resign: .unresigned,
                                                             externalFriend: .noExternalFriend,
                                                             existsEnterpriseEmail: .onlyExistsEnterpriseEmail)
        let chatEntity = PickerConfig.ChatEntityConfig(tenant: .inner,
                                                       join: .all,
                                                       publicType: .all,
                                                       crypto: .all,
                                                       searchByUser: .closeSearchByUser,
                                                       field: PickerConfig.ChatField(showEnterpriseMail: true))
        let mailUserEntity = PickerConfig.MailUserEntityConfig(extras: ["scene": "MAIL-MAIL_SEARCH_FILTER_SCENE"])

        let searchConfig = PickerSearchConfig(entities: [
            chatterEntity,
            chatEntity,
            mailUserEntity
        ], scene: "FILTER_MAIL_USER", permission: [])

        let contactConfig = PickerContactViewConfig(entries: [
            PickerContactViewConfig.Organization(preferEnterpriseEmail: true)
        ])

        body.featureConfig = featureConfig
        body.searchConfig = searchConfig
        body.contactConfig = contactConfig
        body.delegate = self

        let filterBlock: ((LarkModel.PickerItem) -> Bool) = { item in
            switch item.meta {
            case .chatter(let meta):
                return !(meta.enterpriseMailAddress ?? "").isEmpty
            case .chat(let meta):
                return !(meta.enterpriseMailAddress ?? "").isEmpty
            case .mailUser(let meta):
                return !(meta.mailAddress ?? "").isEmpty
            default:
                break
            }
            return false
        }

        self.newPickerAction = (filterBlock, finish)
        userResolver.navigator.present(body: body, from: from, prepare: { $0.modalPresentationStyle = .formSheet })
    }

    private func showInputTextFilterPicker(selectedTexts: [String],
                                    title: String,
                                    from: UIViewController,
                                    finish: @escaping ([String]) -> Void) {
        let viewController = SearchInputFilterViewController(userResolver: userResolver,
                                                             title: title,
                                                             selectedTexts: selectedTexts,
                                                             completion: { newSelectedTexts in
            finish(newSelectedTexts)
        })
        userResolver.navigator.present(viewController,
                                 wrap: LkNavigationController.self,
                                 from: from,
                                 prepare: { $0.modalPresentationStyle = .formSheet },
                                 animated: true)
    }

    //常用筛选器 与 普通筛选器合并去重，常用筛选器中重复部分被删除，普通筛选器中重复部分移到原来常用筛选器的位置
    //目前仅docTab下的【归我所有】会出现重复
    private func mergeAndDeleteDuplicatedFilters(_ commonlyUsed: [SearchFilter], _ normal: [SearchFilter]) -> [SearchFilter] {
        guard !commonlyUsed.isEmpty else { return normal }
        var commonlyUsedDuplicatedIndex: Int?
        var normalDuplicatedOne: SearchFilter?
        var normalDuplicatedIndex: Int?

        for (index, filter) in commonlyUsed.enumerated() {
            if case .specificFilterValue(.docOwnedByMe(_, _), _, _) = filter {
                commonlyUsedDuplicatedIndex = index
                break
            }
        }
        for (index, filter) in normal.enumerated() {
            if case .docOwnedByMe(_, _) = filter {
                normalDuplicatedOne = filter
                normalDuplicatedIndex = index
                break
            }
        }

        if let commonlyUsedIndex = commonlyUsedDuplicatedIndex,
           let normalOne = normalDuplicatedOne,
           let normalIndex = normalDuplicatedIndex {
            commonlyUsedFiltersHasDocOwnedByMe = true
            var commonly = commonlyUsed
            var normal = normal
            commonly[commonlyUsedIndex] = normalOne
            normal.remove(at: normalIndex)
            return commonly + normal
        } else {
            return commonlyUsed + normal
        }
    }

    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [LarkModel.PickerItem]) -> Bool {
        if let finish = newPickerAction?.finishBlock {
            finish(items)
        }
        newPickerAction = nil
        return true
    }

    func pickerWillSelect(pickerVc: SearchPickerControllerType, item: LarkModel.PickerItem, isMultiple: Bool) -> Bool {
        if let filterBlock = newPickerAction?.selectItemFilterBlock {
            let result = filterBlock(item)
            if let window = pickerVc.view.window, !result {
                UDToast.showTips(with: BundleI18n.LarkSearch.Lark_Contacts_NoBusinessEmail, on: window)
            }
            return result
        }
        return true
    }

    func pickerDidCancel(pickerVc: SearchPickerControllerType) -> Bool {
        newPickerAction = nil
        return true
    }

    func pickerDidDismiss(pickerVc: SearchPickerControllerType) {
        newPickerAction = nil
    }
}

protocol SearchFilterBarItemController: AnyObject {
    var value: SearchFilter { get set }
    var view: UIView { get }
    var touch: ControlEvent<()> { get }
    var style: FilterBarStyle { get set }
}

extension SearchFilterViewController {
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
        private lazy var _view = BaseSearchFilterBar.TextValueCell(frame: .zero, style: style, shouldHideExpandArrow: shouldHideExpandArrow)
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
                _view.title = value.title
                _view.value = nil // clear and trigger update
                /// 筛选器为空，不响应[取消]
                _view.switchCancel(cancelEnabled: false)
            } else {
                _view.value = value.title
                /// 筛选器有值，支持[取消]
                _view.switchCancel(cancelEnabled: true)
            }
        }
        var shouldHideExpandArrow: Bool {
            switch value {
            case .docOwnedByMe(_):
                return true
            case .specificFilterValue(_, _, _):
                return true
            default:
                return false
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
        private lazy var _view = BaseSearchFilterBar.TextAvatarCell(frame: .zero, style: style)
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
        private lazy var _view = BaseSearchFilterBar.AvatarsCell(frame: .zero, style: style)
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
            let remainNumber = value.avatarInfos.count - 1
            let rightPartTitle = moreMember(number: remainNumber)
            _view.value = (leftPartTitle, avatarViews, rightPartTitle)
            if value.isEmpty {
                /// 筛选器为空，不响应[取消]
                _view.switchCancel(cancelEnabled: false)
            } else {
                /// 筛选器有值，支持[取消]
                _view.switchCancel(cancelEnabled: true)
            }
        }
    }
}

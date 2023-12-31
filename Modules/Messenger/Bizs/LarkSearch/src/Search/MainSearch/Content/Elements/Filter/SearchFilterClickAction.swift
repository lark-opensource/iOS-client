//
//  SearchFilterClickAction.swift
//  LarkSearch
//
//  Created by wangjingcan on 2023/7/2.
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
import LKCommonsTracker
import LarkContainer
import LarkAccountInterface
import LarkModel
import UniverseDesignToast

final class SearchFilterClickAction: SearchPickerDelegate {
    let userResolver: UserResolver
    private let disposeBag = DisposeBag()
    private let shouldChangeSearchFilterSubject = PublishSubject<SearchFilter?>()
    var shouldChangeSearchFilter: Driver<SearchFilter?> {
        return shouldChangeSearchFilterSubject.asDriver(onErrorJustReturn: nil)
    }
    private let shouldResetSearchFiltersSubject = PublishSubject<Bool>()
    var shouldResetSearchFilters: Driver<Bool> {
        return shouldResetSearchFiltersSubject.asDriver(onErrorJustReturn: false)
    }
    private let shouldSelectedTabSubject = PublishSubject<SearchTab?>()
    var shouldSelectedTab: Driver<SearchTab?> {
        return shouldSelectedTabSubject.asDriver(onErrorJustReturn: nil)
    }

    // 选择归我所有后，高级搜索内文档所有者需要补充“我”
    // 如果用户选择文档所有者过滤器后，回调给外部的筛选器需要去掉额外补充这个“我”
    // 比较合适的是给Chatter加属性，但Chatter是公共模型不太合适
    // 如果有其他方案可以随时替换
    private var mockSelfChatter: Chatter?
    private var searchPopupHelper: SearchPopupHelper?
    private var newPickerAction: (selectItemFilterBlock: ((LarkModel.PickerItem) -> Bool)?,
                                  finishBlock: ([LarkModel.PickerItem]) -> Void)?

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    public func handle(filter: SearchFilter, from: UIViewController,
                       completion: ((SearchFilter) -> Void)? = nil) {
        switch filter {
        case .recommend:
            return
            //
        case .specificFilterValue:
            //
            return
        case let .commonFilter(commonFilter):
            switch commonFilter {
            case let .mainFrom(fromIds, recommends, _, _):
                showChatterPicker(items: fromIds,
                                  title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark,
                                  from: from,
                                  recommendList: recommends) { (items, isRecommendSelected) in
                    let newFilter = SearchFilter.commonFilter(.mainFrom(fromIds: items, recommends: [], fromType: .user, isRecommendResultSelected: isRecommendSelected))
                    completion?(newFilter)
                }
            case let .mainWith(withIds):
                showChatterPicker(items: withIds,
                                  title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark,
                                  from: from) { (items, _) in
                    let newFilter = SearchFilter.commonFilter(.mainWith(items))
                    completion?(newFilter)
                }
            case let .mainIn(items):
                showUniversalPicker(pickType: .chat(chatMode: .unlimited),
                                    items: items,
                                    supportFrozenChat: true,
                                    from: from) { pickedItems in
                    let newFilter = SearchFilter.commonFilter(.mainIn(inIds: pickedItems))
                    completion?(newFilter)
                }
            case .mainDate(let date):
                showDatePicker(date: date, enableSelectFuture: true, from: from, fromView: nil) { startDate, endDate in
                    let newFilter: SearchFilter
                    if startDate == nil, endDate == nil {
                        newFilter = SearchFilter.commonFilter(.mainDate(date: nil))
                    } else {
                        newFilter = SearchFilter.commonFilter(.mainDate(date: SearchFilter.FilterDate(startDate: startDate, endDate: endDate)))
                    }
                    completion?(newFilter)
                }
            }
        case let .general(generalFilter):
            switch generalFilter {
            case let .user(info, items):
                showChatterPicker(items: items,
                                  title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark,
                                  from: from) { pickerdItems, _ in
                    let newFilter = SearchFilter.general(.user(info, pickerdItems))
                    completion?(newFilter)
                }
            case let .userChat(info, items):
                showUniversalPicker(pickType: .userAndGroupChat,
                                    items: items,
                                    from: from) { pickers in
                    let newFilter = SearchFilter.general(.userChat(info, pickers))
                    completion?(newFilter)
                }
            case let .date(info, date):
                showDatePicker(date: date, enableSelectFuture: true, from: from, fromView: nil) { startDate, endDate in
                    let newFilter: SearchFilter
                    if startDate == nil, endDate == nil {
                        newFilter = SearchFilter.general(.date(info, nil))
                    } else {
                        newFilter = SearchFilter.general(.date(info, SearchFilter.FilterDate(startDate: startDate, endDate: endDate)))
                    }
                    completion?(newFilter)
                }
            case let .multiple(info, values):
                switch info.filterType {
                case .predefineEnumFilter:
                    let availableItems = info.predefineEnumValues.map { GeneralMultiFilterType(name: $0.displayText, id: $0.id) }
                    let selectedItems = values.compactMap { value -> GeneralMultiFilterType? in
                        if case let .predefined(info) = value {
                            return GeneralMultiFilterType(name: info.name, id: info.id)
                        }
                        return nil
                    }
                    let selection = GeneralMultiSelection(title: info.displayName, availableItems: availableItems, selectedItems: selectedItems)
                    showMultiSelection(selection: selection, from: from) { types in
                        var newFilter: SearchFilter = .general(.multiple(info, []))
                        if let types = types as? [GeneralMultiFilterType] {
                            newFilter = .general(.multiple(info, types.map { .predefined(SearchChatterPickerItem.GeneralFilterOption(name: $0.name, id: $0.id)) }))
                        }
                        completion?(newFilter)
                    }
                case .searchableFilter:
                    let items = values.compactMap { value -> ForwardItem? in
                        if case let .searchable(item) = value {
                            return item
                        }
                        return nil
                    }
                    showUniversalPicker(pickType: .filter(info),
                                        items: items,
                                        enableMyAi: false,
                                        from: from) { pickedItems in
                        let newFilter = SearchFilter.general(.multiple(info, pickedItems.map { .searchable($0) }))
                        completion?(newFilter)
                    }
                default: break
                }

            case let .single(info, value):
                switch info.filterType {
                case .predefineEnumFilter:
                    let availableItems = info.predefineEnumValues.map { GeneralSingleFilterType(name: $0.displayText, id: $0.id) }
                    let selectedItem = GeneralSingleFilterType(value: value)
                    let selection = GeneralSinleSelection(title: info.displayName, availableItems: availableItems, selectedItem: selectedItem)
                    showSingleSelection(selection: selection, from: from) { type in
                        var newFilter: SearchFilter
                        if let type = type as? GeneralSingleFilterType {
                            newFilter = .general(.single(info, .predefined(SearchChatterPickerItem.GeneralFilterOption(name: type.name, id: type.id))))
                        } else {
                            newFilter = .general(.single(info, nil))
                        }
                        completion?(newFilter)
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
                                        from: from) { pickedItems in
                        let newFilter: SearchFilter
                        if let pickedItem = pickedItems.first {
                            newFilter = SearchFilter.general(.single(info, .searchable(pickedItem)))
                        } else {
                            newFilter = SearchFilter.general(.single(info, nil))
                        }
                        completion?(newFilter)
                    }
                default: break
                }
            case let .calendar(info, selectedCalendars):
                showCalendarPicker(selectedCalendars: selectedCalendars,
                                   title: filter.name,
                                   from: from) { newSelected in
                    let newFilter: SearchFilter = SearchFilter.general(.calendar(info, newSelected))
                    completion?(newFilter)
                }
            case let .mailUser(info, pickers):
                showMailUserPicker(selected: pickers,
                                   title: filter.name,
                                   from: from) { newSelected in
                    let newFilter: SearchFilter = SearchFilter.general(.mailUser(info, newSelected))
                    completion?(newFilter)
                }
            case let .inputTextFilter(info, texts):
                showInputTextFilterPicker(selectedTexts: texts,
                                          title: filter.name,
                                          from: from) { newSelected in
                    let newFilter: SearchFilter = SearchFilter.general(.inputTextFilter(info, newSelected))
                    completion?(newFilter)
                }
            }
        case let .chat(mode, items):
            showUniversalPicker(pickType: .chat(chatMode: mode),
                                items: items,
                                supportFrozenChat: true,
                                from: from) { pickedItems in
                let newFilter = SearchFilter.chat(mode: mode, picker: pickedItems)
                completion?(newFilter)
            }
        case let .docPostIn(items):
            showUniversalPicker(pickType: .chat(chatMode: .unlimited),
                                items: items,
                                supportFrozenChat: true,
                                from: from) { pickedItems in
                let newFilter = SearchFilter.docPostIn(pickedItems)
                completion?(newFilter)
            }
        case let .docFolderIn(selectedItems):
            showUniversalPicker(pickType: .folder, items: selectedItems, from: from) { pickedItems in
                let newFilter = SearchFilter.docFolderIn(pickedItems)
                completion?(newFilter)
            }
        case let .docWorkspaceIn(selectedItems):
            showUniversalPicker(pickType: .workspace, items: selectedItems, from: from) { pickedItems in
                let newFilter = SearchFilter.docWorkspaceIn(pickedItems)
                completion?(newFilter)
            }
        case let .chatter(mode, items, recommends, _, _):
            showChatterPicker(items: items,
                              title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark,
                              from: from,
                              recommendList: recommends) { pickerdItems, isRecommendResultSelected in
                let newFilter = SearchFilter.chatter(mode: mode, picker: pickerdItems, recommends: [], fromType: .user, isRecommendResultSelected: isRecommendResultSelected)
                completion?(newFilter)
            }
        case let .withUsers(selectedItems):
            showChatterPicker(items: selectedItems,
                              title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark,
                              from: from) { items, _ in
                let newFilter = SearchFilter.withUsers(items)
                completion?(newFilter)
            }
        case let .docFrom(fromIds, recommends, _, _):
            showChatterPicker(items: fromIds,
                              title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark,
                              from: from,
                              recommendList: recommends) { pickerdItems, isRecommendResultSelected in
                let newFilter = SearchFilter.docFrom(fromIds: pickerdItems, recommends: [], fromType: .user, isRecommendResultSelected: isRecommendResultSelected)
                completion?(newFilter)
            }
        case .date(let date, let source):
            var enableSelectFuture: Bool = true
            switch source {
            case .doc, .message:
                enableSelectFuture = false
            default:
                break
            }
            showDatePicker(date: date, enableSelectFuture: enableSelectFuture, from: from, fromView: nil) { startDate, endDate in
                let newFilter: SearchFilter
                if startDate == nil, endDate == nil {
                    newFilter = SearchFilter.date(date: nil, source: source)
                } else {
                    newFilter = SearchFilter.date(date: SearchFilter.FilterDate(startDate: startDate, endDate: endDate), source: source)
                }
                completion?(newFilter)
            }
        case .messageMatch(let selectedTypes):
            let selection = MessageContentMatchSelection(defaultTypes: selectedTypes)
            showMultiSelection(selection: selection, from: from) {types in
                var newFilter: SearchFilter = .messageMatch([])
                if let types = types as? [SearchFilter.MessageContentMatchType] {
                    newFilter = .messageMatch(types)
                }
                completion?(newFilter)
            }
        case .docOwnedByMe:
            return
        case .messageType(let selectedType):
            let selection = MessageSelection(userResolver: userResolver, selectedType: selectedType)
            showSingleSelection(selection: selection, from: from) { type in
                var newFilter: SearchFilter
                if let type = type as? MessageFilterType {
                    newFilter = .messageType(type)
                } else {
                    newFilter = .messageType(.all)
                }
                completion?(newFilter)
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
                completion?(newFilter)
            }
        case let .chatMemeber(mode, selectedItems):
            showChatterPicker(items: selectedItems, title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark, from: from) { items, _ in
                let newFilter = SearchFilter.chatMemeber(mode: mode, picker: items)
                completion?(newFilter)
            }
        case let .docSharer(docItems):
            showChatterPicker(items: docItems, title: BundleI18n.LarkSearch.Lark_Search_ResultTagShared, from: from) { items, _ in
                let newFilter = SearchFilter.docSharer(items)
                completion?(newFilter)
            }
        case .chatType(let defaultTypes):
            let selection = ChatFilterSelection(defaultTypes: defaultTypes)
            showMultiSelection(selection: selection, from: from) { types in
                var newFilter: SearchFilter = .chatType([])
                if let types = types as? [ChatFilterType] {
                    newFilter = .chatType(types)
                }
                completion?(newFilter)
            }
        case .chatKeyWord(let keyWord):
            let vc = ChatKeyWordFilterViewController(keyWord: keyWord)
            vc.didEnterKeyWord = { (keyWord, vc) in
                let newFilter = SearchFilter.chatKeyWord(keyWord ?? "")
                completion?(newFilter)
                vc.dismiss(animated: true, completion: nil)
            }
            vc.modalPresentationStyle = .overCurrentContext
            vc.transitioningDelegate = vc
            Navigator.shared.present(vc, from: from, animated: true)
        case .threadType(let type):
            let vc = ThreadTypeFilterViewController(selectedType: type)
            vc.threadTypeHandler = { (type, vc) in
                let newFilter = SearchFilter.threadType(type)
                completion?(newFilter)
                vc.dismiss(animated: true, completion: nil)
                Tracker.post(TeaEvent(Homeric.SEARCH_FILTER_CHANNELS_TYPE, params: ["type": type.trackInfo]))
            }
            vc.modalPresentationStyle = .overCurrentContext
            vc.transitioningDelegate = vc
            Navigator.shared.present(vc, from: from, animated: true)
        case .docCreator(let items, let uid):
            showChatterPicker(items: self.reduceSelfInDocCreatorIfNeed(items: items), title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark, from: from) { items, _ in
                let newFilter = SearchFilter.docCreator(items, uid)
                completion?(newFilter)
            }
        case .wikiCreator(let items):
            showChatterPicker(items: items, title: BundleI18n.LarkSearch.Lark_Legacy_SelectLark, from: from) { items, _ in
                let newFilter = SearchFilter.wikiCreator(items)
                completion?(newFilter)
            }
        case .docType(let type):
            let selection = DocTypeSelection(selectedType: type)
            showSingleSelection(selection: selection, from: from) { type in
                var newFilter: SearchFilter
                if let type = type as? SearchFilter.DocType {
                    newFilter = .docType(type)
                } else {
                    newFilter = .docType(.all)
                }
                completion?(newFilter)
            }
        case .docContentType(let type):
            let selection = DocContentSelection(selectedType: type)
            showSingleSelection(selection: selection, from: from) { type in
                var newFilter: SearchFilter
                if let type = type as? DocContentType {
                    newFilter = .docContentType(type)
                } else {
                    newFilter = .docContentType(.fullContent)
                }
                completion?(newFilter)
            }
        case .docFormat(let types, let source):
            let selection = DocTypeFilterSelection(defaultTypes: types)
            showMultiSelection(selection: selection, from: from) { types in
                var newFilter: SearchFilter = .docFormat([], source)
                if let types = types as? [DocFormatType] {
                    newFilter = .docFormat(types, source)
                }
                completion?(newFilter)
            }
        case .docSortType(let type):
            let selection = DocSortTypeSelection(selectedType: type)
            showSingleSelection(selection: selection, from: from) { type in
                var newFilter: SearchFilter
                if let type = type as? SearchFilter.DocSortType {
                    newFilter = .docSortType(type)
                } else {
                    newFilter = .docSortType(.mostRelated)
                }
                completion?(newFilter)
            }
        case .messageChatType(let type):
            let selection = ChatTypeSelection(selectedType: type)
            showSingleSelection(selection: selection, from: from) { type in
                var newFilter: SearchFilter
                if let type = type as? SearchFilter.MessageChatFilterType {
                    newFilter = .messageChatType(type)
                } else {
                    newFilter = .messageChatType(.all)
                }
                completion?(newFilter)
            }
        case .groupSortType(let type):
            let selection = GroupSortTypeSelection(selectedType: type)
            showSingleSelection(selection: selection, from: from) { type in
                var newFilter: SearchFilter
                if let type = type as? SearchFilter.GroupSortType {
                    newFilter = .groupSortType(type)
                } else {
                    newFilter = .groupSortType(.mostRelated)
                }
                completion?(newFilter)
            }
        default:
            assert(false, "new value")
            break
        }
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
                    }).disposed(by: self.disposeBag)
            } else {
                vc?.dismiss(animated: true, completion: nil)
                finish(items, result.isRecommendSelected)
            }
        }
        Navigator.shared.present(body: body, from: from, prepare: { $0.modalPresentationStyle = .formSheet })
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
        Navigator.shared.present(
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
            Navigator.shared.present(viewController,
                                     wrap: LkNavigationController.self,
                                     from: from,
                                     prepare: { $0.modalPresentationStyle = .formSheet })
        } else {
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.transitioningDelegate = viewController
            Navigator.shared.present(viewController, from: from, animated: true)
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
            Navigator.shared.present(viewController, wrap: LkNavigationController.self,
                                     from: from,
                                     prepare: { $0.modalPresentationStyle = .formSheet })
        } else {
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.transitioningDelegate = viewController
            Navigator.shared.present(viewController, from: from, animated: true)
        }
    }

    // TODO from view
    private func showDatePicker(date: SearchFilter.FilterDate?,
                                enableSelectFuture: Bool = false,
                                from: UIViewController,
                                fromView: UIView?,
                                finish: @escaping (Date?, Date?) -> Void) {
        var body: SearchDateFilterBody
        if let date = date {
            body = SearchDateFilterBody(startDate: date.startDate, endDate: date.endDate, enableSelectFuture: enableSelectFuture)
        } else {
            let endDate = enableSelectFuture ? nil : Date()
            body = SearchDateFilterBody(startDate: nil, endDate: endDate, enableSelectFuture: enableSelectFuture)
        }
        body.fromView = fromView
        fromView?.window?.endEditing(true)
        body.confirm = { (vc, startDate, endDate) in
            vc.dismiss(animated: false, completion: nil)
            finish(startDate, endDate)
        }
        Navigator.shared.present(body: body, from: from)
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
        var contactSearchPickerBody = ContactSearchPickerBody()
        let featureConfig = PickerFeatureConfig(
            scene: .searchFilterByOpenMail,
            multiSelection: .init(isOpen: true, preselectItems: selected),
            navigationBar: .init(title: title, sureText: BundleI18n.LarkSearch.Lark_Legacy_Sure, closeColor: UIColor.ud.iconN1,
                                 canSelectEmptyResult: true, sureColor: UIColor.ud.primaryContentDefault),
            searchBar: .init(hasBottomSpace: false, autoFocus: true)
        )
        let chatEntity = PickerConfig.ChatEntityConfig(tenant: .inner,
                                                       join: .all,
                                                       publicType: .all,
                                                       crypto: .all,
                                                       searchByUser: .closeSearchByUser,
                                                       field: PickerConfig.ChatField(showEnterpriseMail: true))
        let chatterEntity = PickerConfig.ChatterEntityConfig(talk: .all,
                                                             resign: .unresigned,
                                                             externalFriend: .noExternalFriend,
                                                             existsEnterpriseEmail: .onlyExistsEnterpriseEmail)
        let mailUserEntity = PickerConfig.MailUserEntityConfig(extras: ["scene": "MAIL-MAIL_SEARCH_FILTER_SCENE"])

        let searchConfig = PickerSearchConfig(entities: [
            chatterEntity,
            chatEntity,
            mailUserEntity
        ], scene: "FILTER_MAIL_USER", permission: [])

        let contactConfig = PickerContactViewConfig(entries: [
            PickerContactViewConfig.Organization(preferEnterpriseEmail: true)
        ])

        contactSearchPickerBody.featureConfig = featureConfig
        contactSearchPickerBody.searchConfig = searchConfig
        contactSearchPickerBody.contactConfig = contactConfig
        contactSearchPickerBody.delegate = self

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
        userResolver.navigator.present(body: contactSearchPickerBody, from: from, prepare: { $0.modalPresentationStyle = .formSheet })
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

    func showAdvancedSearch(fromVC: UIViewController, supportFilters: [SearchFilter]) {
        var selectDocOwnMe = false
        var filters = supportFilters.filter { filter in
            switch filter {
            case .specificFilterValue(_, _, _):
                return false
            case .docOwnedByMe(let ownByMe, _):
                selectDocOwnMe = ownByMe
                return false
            default:
                return true
            }
        }

        self.mockSelfChatter = nil
        if selectDocOwnMe {
            var docCreatorPickers = [SearchChatterPickerItem]()
            if let docCreatorIndex = filters.firstIndex(where: { filter in
                switch filter {
                case .docCreator(let pickers, _):
                    //let userResolver = Container.shared.getCurrentUserResolver()
                    let passportService = try? self.userResolver.resolve(assert: PassportUserService.self)
                    let chatterAPI = try? self.userResolver.resolve(assert: ChatterAPI.self)
                    if let user = passportService?.user {
                        let exitsSelf = !pickers.filter({ $0.chatterID == user.userID }).isEmpty
                        if !exitsSelf, let chatter = chatterAPI?.getChatterFromLocal(id: user.userID) {
                            self.mockSelfChatter = chatter
                            docCreatorPickers.append(SearchChatterPickerItem.chatter(chatter))
                        }
                    }
                    docCreatorPickers.append(contentsOf: pickers)
                    return true
                default:
                    return false
                }
            }) {
                filters[docCreatorIndex] = .docCreator(docCreatorPickers, userResolver.userID)
            }
        }

        let contentView = SearchAdvancedFilterView(frame: .zero, dataSource: filters)
        let popupContainer = SearchPopupHelper()
        self.searchPopupHelper = popupContainer
        contentView.itemSelect.drive(onNext: { [weak self, weak popupContainer, weak fromVC] filter in
            guard let self = self,
                  let fromVC = fromVC,
                  let container = popupContainer,
                  let filter = filter else { return }
            container.dismiss { [weak self, weak fromVC] in
                guard let self = self,
                      let fromVC = fromVC else { return }
                self.handle(filter: filter, from: fromVC) { [weak self] changedFilter in
                    self?.shouldChangeSearchFilterSubject.onNext(changedFilter)
                }
            }
        }).disposed(by: disposeBag)
        contentView.closeTapEvent.rx.event.asDriver().drive(onNext: { [weak popupContainer] _ in
            popupContainer?.dismiss(completion: {})
        })
        .disposed(by: disposeBag)
        contentView.resetFilterEvent.rx.event.asDriver().drive(onNext: { [weak self, weak popupContainer] _ in
            guard let self = self, let container = popupContainer else { return }
            container.dismiss(completion: {})
            self.shouldResetSearchFiltersSubject.onNext(true)
        })
        .disposed(by: disposeBag)
        popupContainer.show(sourceVC: fromVC, contentView: contentView)
    }

    private func reduceSelfInDocCreatorIfNeed(items: [SearchChatterPickerItem]) -> [SearchChatterPickerItem] {
        guard let chatter = self.mockSelfChatter, let first = items.first else { return items }
        var newItems = [SearchChatterPickerItem](items)
        if case .chatter(let innerChatter) = first, innerChatter == chatter {
            newItems.removeFirst()
        }
        return newItems
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

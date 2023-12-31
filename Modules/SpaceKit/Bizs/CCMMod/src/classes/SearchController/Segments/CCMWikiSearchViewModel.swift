//
//  CCMWikiSearchViewModel.swift
//  CCMMod
//
//  Created by Weston Wu on 2023/6/5.
//
#if MessengerMod
import LarkSearchCore
import LarkModel
import LarkContainer
import RustPB
import Foundation
import SKFoundation
import SKResource
import SKWikiV2
import RxSwift
import RxRelay
import RxCocoa
import SpaceInterface
import SKCommon
import LarkMessengerInterface

class CCMWikiSearchViewModel: CCMSearchSegmentViewModelType {

    static var wikiSpaceRecommendProviderKey: String { "wiki-space-recommend" }

    private let resolver: UserResolver

    var segmentTitles: [String] {
        [
            SKResource.BundleI18n.SKResource.Doc_Facade_Wiki ,
            SKResource.BundleI18n.SKResource.Doc_List_Space
        ]
    }

    weak var defaultView: PickerRecommendListView?

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func segmentView(at index: Int) -> CCMSearchFilterViewType {
        switch index {
        case 0:
            let viewModel = CCMWikiSpaceSearchViewModel(userResolver: resolver)
            let view = CCMSearchSegmentPlaceHolderView(viewModel: viewModel)
            return view
        case 1:
            let viewModel = CCMWikiNodeSearchViewModel(resolver: resolver)
            let view = CCMSearchFilterConfigView(viewModel: viewModel)
            return view
        default:
            spaceAssertionFailure("segment index out of bounds")
            let viewModel = CCMWikiSpaceSearchViewModel(userResolver: resolver)
            let view = CCMSearchSegmentPlaceHolderView(viewModel: viewModel)
            return view
        }
    }

    func didSwitch(at index: Int) {
        guard let defaultView else { return }
        switch index {
        case 0:
            defaultView.switchProvider(by: Self.wikiSpaceRecommendProviderKey)
        case 1:
            defaultView.switchProvider()
        default:
            spaceAssertionFailure("segment index out of bounds")
        }
        defaultView.reload()
    }
}

class CCMWikiSpaceSearchViewModel: CCMSearchSegmentPlaceHolderViewModelType {

    private let actionInput = PublishRelay<CCMSearchAction>()
    var actionSignal: Signal<CCMSearchAction> { actionInput.asSignal() }
    
    private let userResolver: UserResolver
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func generateSearchConfig() -> PickerSearchConfig {
        PickerSearchConfig(entities: [
            PickerConfig.WikiSpaceEntityConfig()
        ])
    }

    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        guard let item = items.first else {
            DocsLogger.error("wiki space picker did finish without item")
            return false
        }
        guard case let .wikiSpace(meta) = item.meta,
              let wikiSpaceMeta = meta.meta else {
            DocsLogger.error("un-expected item meta type found: \(item.meta.type)")
            return false
        }

        let controller = WikiVCFactory.makeWikiSpaceViewController(userResolver: userResolver, spaceID: wikiSpaceMeta.spaceID)
        actionInput.accept(.push(controller: controller))
        return false
    }
}

private enum CCMWikiSearchError: Error {
    case viewModelReleased
}

class CCMWikiNodeSearchViewModel: CCMSearchFilterViewModelType {
    /// 由于可能同时存在多个 SearchPickerController 的 Delegate 指向 viewModel，
    /// viewModel 同一时刻只应该受到一个 controller 的 Delegate 事件，这里通过状态控制
    private enum PickerDelegateType {
        /// 来自搜索本身的 delegate 事件
        case search
        /// 来自过滤文件夹的 delegate 事件
        case wikiSpaceFilter
        // 来自过滤所有者的 delegate 事件
        case owner
        // 来自过滤所在会话的 delegate 事件
        case chat
    }

    typealias WikiSpaceInfo = CCMSearchWikiSpaceFilterItemView.WikiSpaceInfo
    typealias OwnerInfo = CCMSearchOwnerFilterItemView.OwnerInfo
    typealias ChatInfo = CCMSearchChatFilterItemView.ChatInfo

    private let actionInput = PublishRelay<CCMSearchAction>()
    var actionSignal: Signal<CCMSearchAction> { actionInput.asSignal() }
    let resetInput = PublishRelay<Void>()
    // 所属知识空间状态
    private let spaceFilterState = BehaviorRelay<[PickerWikiSpaceMeta]>(value: [])
    // 类型过滤状态
    private let typeFilterState = BehaviorRelay<[CCMTypeFilterOption]>(value: [])
    // 所有者过滤状态
    private let ownerFilterState = BehaviorRelay<[PickerChatterMeta]>(value: [])
    // 所在会话过滤状态
    private let chatFilterState = BehaviorRelay<[LarkSearchChatPickerItemProtocol]>(value: [])
    // private let chatFilterState = BehaviorRelay<[PickerChatMeta]>(value: [])

    // 用于控制 SearchPickerDelegate 需要响应哪一个 picker 的请求
    private var pickerDelegateType = PickerDelegateType.search

    private let resolver: UserResolver

    private let disposeBag = DisposeBag()

    // 文件夹内需要预选中当前文件夹
    init(resolver: UserResolver) {
        self.resolver = resolver
        setup()
    }

    private func setup() {
        resetInput.subscribe(onNext: { [weak self] in
            self?.reset()
        })
        .disposed(by: disposeBag)
    }

    private func reset() {
        spaceFilterState.accept([])
        typeFilterState.accept([])
        ownerFilterState.accept([])
        chatFilterState.accept([])
        updateSearchConfig()
    }

    private func createWikiSpaceFilterItem() -> CCMSearchFilterItemView {
        let spaceItem = CCMSearchWikiSpaceFilterItemView()
        spaceFilterState.map { wikiSpaceMetas -> [WikiSpaceInfo] in
            wikiSpaceMetas.compactMap { meta -> WikiSpaceInfo? in
                guard let wikiSpaceMeta = meta.meta else {
                    return nil
                }
                return WikiSpaceInfo(spaceID: wikiSpaceMeta.spaceID, name: wikiSpaceMeta.spaceName)
            }
        }
        .bind(to: spaceItem.selectionsRelay)
        .disposed(by: disposeBag)
        spaceItem.rx.controlEvent(.touchUpInside)
            .withLatestFrom(spaceFilterState)
            .map { [weak self] wikiSpaceMetas -> CCMSearchAction in
                guard let self else {
                    throw CCMWikiSearchError.viewModelReleased
                }
                let controller = self.createWikiSpaceFilterController(selections: wikiSpaceMetas)
                controller.pickerDelegate = self
                self.pickerDelegateType = .wikiSpaceFilter
                return .present(controller: controller)
            }
            .subscribe(onNext: { [weak self] action in
                self?.actionInput.accept(action)
            })
            .disposed(by: disposeBag)
        spaceItem.didClickReset.subscribe(onNext: { [weak self] in
            guard let self else { return }
            self.spaceFilterState.accept([])
            self.updateSearchConfig()
        })
        .disposed(by: disposeBag)
        return spaceItem
    }

    private func createTypeFilterItem() -> CCMSearchFilterItemView {
        let typeItem = CCMSearchTypeFilterItemView()
        typeFilterState.bind(to: typeItem.selectionsRelay).disposed(by: disposeBag)

        typeItem.rx.controlEvent(.touchUpInside)
            .withLatestFrom(typeFilterState)
            .map { [weak self] selections -> CCMSearchAction in
                let controller = CCMTypeFilterController(selections: selections, showFolderOption: false)
                controller.completion = { selections in
                    guard let self else { return }
                    self.typeFilterState.accept(selections)
                    self.updateSearchConfig()
                }
                return CCMSearchAction.present(controller: controller)
            }
            .subscribe(onNext: { [weak self] action in
                self?.actionInput.accept(action)
            })
            .disposed(by: disposeBag)
        typeItem.didClickReset.subscribe(onNext: { [weak self] in
            guard let self else { return }
            self.typeFilterState.accept([])
            self.updateSearchConfig()
        })
        .disposed(by: disposeBag)
        return typeItem
    }

    private func createOwnerFilterItem() -> CCMSearchFilterItemView {
        let ownerItem = CCMSearchOwnerFilterItemView()
        ownerFilterState.map { chatMetas -> [OwnerInfo] in
            chatMetas.map { chatMeta -> OwnerInfo in
                OwnerInfo(entityID: chatMeta.id, avatarKey: chatMeta.avatarKey)
            }
        }
        .bind(to: ownerItem.selectionsRelay)
        .disposed(by: disposeBag)
        ownerItem.rx.controlEvent(.touchUpInside)
            .withLatestFrom(ownerFilterState)
            .map { [weak self] ownerMetas -> CCMSearchAction in
                guard let self else {
                    throw CCMWikiSearchError.viewModelReleased
                }
                var searchChatterBody = self.createOwnerFilterController(selections: ownerMetas)
                searchChatterBody.delegate = self
                self.pickerDelegateType = .owner
                return.presentBody(searchChatterBody)
            }
            .subscribe(onNext: { [weak self] action in
                self?.actionInput.accept(action)
            })
            .disposed(by: disposeBag)
        ownerItem.didClickReset.subscribe(onNext: { [weak self] in
            guard let self else { return }
            self.ownerFilterState.accept([])
            self.updateSearchConfig()
        })
        .disposed(by: disposeBag)
        return ownerItem
    }

    private func createChatFilterItem() -> CCMSearchFilterItemView {
        let chatItem = CCMSearchChatFilterItemView()
        chatFilterState.map { chatMetas -> [ChatInfo] in
            chatMetas.map { meta -> ChatInfo in
                return ChatInfo(entityID: meta.groupID ?? meta.chatID, avatarKey: meta.avatarKey)
                // return ChatInfo(entityID: meta.id, avatarKey: meta.avatarKey)
            }
        }
        .bind(to: chatItem.selectionsRelay)
        .disposed(by: disposeBag)

        chatItem.rx.controlEvent(.touchUpInside)
            .withLatestFrom(chatFilterState)
            .map { [weak self] chatMetas -> CCMSearchAction in
                guard let self else {
                    throw CCMWikiSearchError.viewModelReleased
                }
                let searchChatBody = self.createChatFilterController(selections: chatMetas)
                return .presentBody(searchChatBody)
                /*
                let controller = self.createChatFilterController(selections: chatMetas)
                controller.pickerDelegate = self
                self.pickerDelegateType = .chat
                return .present(controller: controller)
                */
            }
            .subscribe(onNext: { [weak self] action in
                self?.actionInput.accept(action)
            })
            .disposed(by: disposeBag)
        chatItem.didClickReset.subscribe(onNext: { [weak self] in
            guard let self else { return }
            self.chatFilterState.accept([])
            self.updateSearchConfig()
        })
        .disposed(by: disposeBag)
        return chatItem
    }

    private func updateSearchConfig() {
        let config = generateSearchConfig()
        actionInput.accept(.update(searchConfig: config))
    }

    func createItems() -> [CCMSearchFilterItemView] {
        [
            createWikiSpaceFilterItem(),
            createTypeFilterItem(),
            createOwnerFilterItem(),
            createChatFilterItem()
        ]
    }

    func generateSearchConfig() -> PickerSearchConfig {
        var wikiConfig = PickerConfig.WikiEntityConfig(belongUser: .all,
                                                       belongChat: .all,
                                                       types: Basic_V1_Doc.TypeEnum.allCases,
                                                       spaceIds: [])

        let ownerIDs = ownerFilterState.value.map(\.id)
        if !ownerIDs.isEmpty {
            wikiConfig.belongUser = .belong(ownerIDs)
        }

        let chatIDs = chatFilterState.value.map { meta in
            meta.groupID ?? meta.chatID
        }
        // let chatIDs = chatFilterState.value.map { $0.id }
        if !chatIDs.isEmpty {
            wikiConfig.belongChat = .belong(chatIDs)
        }

        let types = typeFilterState.value.flatMap(\.searchType)
        if !types.isEmpty {
            wikiConfig.types = types
        }
        wikiConfig.spaceIds = spaceFilterState.value.compactMap(\.meta?.spaceID)
        return PickerSearchConfig(entities: [wikiConfig])
    }
}

// MARK: SearchNode - SearchPickerDelegate
extension CCMWikiNodeSearchViewModel {
    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        switch pickerDelegateType {
        case .search:
            return searchPickerDidFinish(picker: pickerVc, items: items)
        case .wikiSpaceFilter:
            return wikiSpaceFilterPickerDidFinish(picker: pickerVc, items: items)
        case .owner:
            return ownerFilterPickerDidFinish(picker: pickerVc, items: items)
        case .chat:
            return true
            // return chatFilterPickerDidFinish(picker: pickerVc, items: items)
        }
    }

    func pickerDidCancel(pickerVc: SearchPickerControllerType) -> Bool {
        pickerDelegateType = .search
        return true
    }

    func pickerDidDismiss(pickerVc: SearchPickerControllerType) {
        pickerDelegateType = .search
    }
}



// Search Delegate
private extension CCMWikiNodeSearchViewModel {
    func searchPickerDidFinish(picker: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        guard let item = items.first else {
            DocsLogger.error("picker did finish without item")
            return false
        }
        guard case let .wiki(meta) = item.meta,
              let wikiMeta = meta.meta else {
            DocsLogger.error("un-expected item meta type found: \(item.meta.type)")
            return false
        }
        /// meta.id -> objToken
        /// wikiMeta.id -> objToken
        /// wikiMeta.type -> objType
        /// wikiMeta.token -> wikiToken
        guard let url = URL(string: wikiMeta.url) else {
            DocsLogger.error("invalid item meta url found, fallback with token and type")
            let url = DocsUrlUtil.url(type: .wiki, token: wikiMeta.token)
            actionInput.accept(.openURL(url: url))
            return false
        }
        actionInput.accept(.openURL(url: url))
        // 打开文档
        return false
    }
}

// MARK: Search Node - WikiSpace Filter delegate
private extension CCMWikiNodeSearchViewModel {

    func createWikiSpaceFilterController(selections: [PickerWikiSpaceMeta]) -> SearchPickerNavigationController {
        let controller = SearchPickerNavigationController(resolver: resolver)
        controller.searchConfig = PickerSearchConfig(entities: [
            PickerConfig.WikiSpaceEntityConfig()
        ])

        let defaultView = PickerRecommendListView(resolver: resolver)
        let providerKey = "wiki-space-key"
        defaultView.add(provider: CCMWikiSearchSpaceRecommendProvider(), for: providerKey)
        defaultView.switchProvider(by: providerKey)
        controller.defaultView = defaultView

        let preSelections = selections.map { wikiSpaceMeta in
            PickerItem(meta: .wikiSpace(wikiSpaceMeta))
        }

        let multiSelectionConfig = PickerFeatureConfig.MultiSelection(isOpen: true,
                                                                      isDefaultMulti: !preSelections.isEmpty,
                                                                      canSwitchToMulti: true,
                                                                      canSwitchToSingle: false,
                                                                      preselectItems: preSelections,
                                                                      selectedViewStyle: .label {
            SKResource.BundleI18n.SKResource.LarkCCM_CM_Search_NumWorkspaceSelected_Placeholder($0)
        })
        let naviBarConfig = PickerFeatureConfig.NavigationBar(title: SKResource.BundleI18n.SKResource.LarkCCM_CM_Search_InWorkspace_Placeholder,
                                                              sureText: SKResource.BundleI18n.SKResource.Doc_Facade_Ok,
                                                              canSelectEmptyResult: true)
        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false,
                                                            autoFocus: true)
        controller.featureConfig = PickerFeatureConfig(scene: .ccmFilterByWikiSpace,
                                                       multiSelection: multiSelectionConfig,
                                                       navigationBar: naviBarConfig,
                                                       searchBar: searchBarConfig)
        return controller
    }

    func wikiSpaceFilterPickerDidFinish(picker: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        // 还原回响应 search 的事件
        pickerDelegateType = .search
        let selections = items.compactMap { item -> PickerWikiSpaceMeta? in
            guard case let .wikiSpace(wikiSpaceMeta) = item.meta,
                  wikiSpaceMeta.meta != nil else {
                DocsLogger.error("un-expect type: \(item.meta.type) found in wiki space filter picker delegate")
                return nil
            }
            return wikiSpaceMeta
        }
        self.spaceFilterState.accept(selections)
        self.updateSearchConfig()
        return true
    }
}

// MARK: Search Node - Owner Filter Delegate
private extension CCMWikiNodeSearchViewModel {

    func createOwnerFilterController(selections: [PickerChatterMeta]) -> ContactSearchPickerBody {
        var body = ContactSearchPickerBody()
        let preSelectedItems: [PickerItem] = selections.map { PickerItem(meta: .chatter($0)) }
        let multiSelectionConfig = PickerFeatureConfig.MultiSelection(isOpen: true,
                                                                      isDefaultMulti: !preSelectedItems.isEmpty,
                                                                      canSwitchToMulti: true,
                                                                      canSwitchToSingle: false,
                                                                      preselectItems: preSelectedItems)
        let naviBarConfig = PickerFeatureConfig.NavigationBar(title: SKResource.BundleI18n.SKResource.Doc_At_Select,
                                                              sureText: SKResource.BundleI18n.SKResource.Doc_Facade_Ok,
                                                              canSelectEmptyResult: true)
        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false,
                                                            autoFocus: true)
        body.featureConfig = .init(
            scene: .ccmFilterByOwner,
            multiSelection: multiSelectionConfig,
            navigationBar: naviBarConfig,
            searchBar: searchBarConfig
        )

        body.searchConfig = PickerSearchConfig(entities: [
            // ChatterEntityConfig 代表人员
            PickerConfig.ChatterEntityConfig(tenant: .all, talk: .all, field: .init()),
        ])

        body.contactConfig = .init(entries: [
            PickerContactViewConfig.External(),
            PickerContactViewConfig.Organization(),
            PickerContactViewConfig.RelatedOrganization()
        ])

        return body
    }

    func ownerFilterPickerDidFinish(picker: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        // 还原回响应 search 的事件
        pickerDelegateType = .search
        let selections = items.compactMap { item -> PickerChatterMeta? in
            guard case let .chatter(chatterMeta) = item.meta else {
                DocsLogger.error("un-expect type: \(item.meta.type) found in owner filter picker delegate")
                return nil
            }
            return chatterMeta
        }
        self.ownerFilterState.accept(selections)
        self.updateSearchConfig()
        return true
    }
}

// MARK: Search Node - Chat Filter Delegate
private extension CCMWikiNodeSearchViewModel {
    func createChatFilterController(selections: [LarkSearchChatPickerItemProtocol]) -> LarkSearchChatPickerBody {
        var body = LarkSearchChatPickerBody()
        body.selectedItems = selections
        body.didFinishPickChats = { [weak self] picker, items in
            picker.dismiss(animated: true)
            guard let self else { return }
            self.chatFilterState.accept(items)
            self.updateSearchConfig()
        }
        return body
    }

    func createChatFilterController(selections: [PickerChatMeta]) -> SearchPickerNavigationController {
        let controller = SearchPickerNavigationController(resolver: resolver)
        controller.searchConfig = PickerSearchConfig(entities: [
            PickerConfig.ChatEntityConfig(tenant: .all, field: .init(relationTag: true))
        ])
        controller.defaultView = PickerRecommendListView(resolver: resolver)

        let preSelectedItems: [PickerItem] = selections.map { PickerItem(meta: .chat($0)) }
        let multiSelectionConfig = PickerFeatureConfig.MultiSelection(isOpen: true, preselectItems: preSelectedItems)
        let naviBarConfig = PickerFeatureConfig.NavigationBar(title: SKResource.BundleI18n.SKResource.Doc_At_Select,
                                                              sureText: SKResource.BundleI18n.SKResource.Doc_Facade_Ok,
                                                              canSelectEmptyResult: true)
        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false,
                                                            autoFocus: true)
        controller.featureConfig = PickerFeatureConfig(scene: .ccmFilterByChat,
                                                       multiSelection: multiSelectionConfig,
                                                       navigationBar: naviBarConfig,
                                                       searchBar: searchBarConfig)
        return controller
    }

    /*
    func chatFilterPickerDidFinish(picker: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        // 还原回响应 search 的事件
        pickerDelegateType = .search
        let selections = items.compactMap { item -> PickerChatMeta? in
            guard case let .chat(chatMeta) = item.meta else {
                DocsLogger.error("un-expect type: \(item.meta.type) found in chat filter picker delegate")
                return nil
            }
            return chatMeta
        }
        self.chatFilterState.accept(selections)
        self.updateSearchConfig()
        return true
    }
    */
}
#endif

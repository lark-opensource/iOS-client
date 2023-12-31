//
//  CCMSpaceSearchViewModel.swift
//  CCMMod
//
//  Created by Weston Wu on 2023/5/31.
//

#if MessengerMod
import UIKit
import SKFoundation
import SKCommon
import SKResource
import SpaceInterface
import LarkSearchCore
import LarkModel
import LarkContainer
import RustPB
import RxSwift
import RxRelay
import RxCocoa
import LarkMessengerInterface

private enum CCMSpaceSearchError: Error {
    case viewModelReleased
}

class CCMSpaceSearchViewModel: CCMSearchFilterViewModelType {
    /// 由于可能同时存在多个 SearchPickerController 的 Delegate 指向 viewModel，
    /// viewModel 同一时刻只应该受到一个 controller 的 Delegate 事件，这里通过状态控制
    private enum PickerDelegateType {
        /// 来自搜索本身的 delegate 事件
        case search
        /// 来自过滤文件夹的 delegate 事件
        case folderFilter
        /// 来自过滤所有者的 delegate 事件
        case owner
        /// 来自过滤所在会话的 delegate 事件
        case chat
    }

    typealias FolderInfo = CCMSearchFolderFilterItemView.FolderInfo
    typealias OwnerInfo = CCMSearchOwnerFilterItemView.OwnerInfo
    typealias ChatInfo = CCMSearchChatFilterItemView.ChatInfo

    private let actionInput = PublishRelay<CCMSearchAction>()
    var actionSignal: Signal<CCMSearchAction> { actionInput.asSignal() }
    let resetInput = PublishRelay<Void>()

    // 归我所有状态
    private let ownedFilterState = BehaviorRelay<Bool>(value: false)
    // 所属文件夹状态
    private let folderFilterState = BehaviorRelay<[PickerDocMeta]>(value: [])
    // 类型过滤状态
    private let typeFilterState = BehaviorRelay<[CCMTypeFilterOption]>(value: [])
    // 所有者过滤状态
    private let ownerFilterState = BehaviorRelay<[PickerChatterMeta]>(value: [])
    // 所在会话过滤状态
    private let chatFilterState = BehaviorRelay<[LarkSearchChatPickerItemProtocol]>(value: [])
    // 用于控制 SearchPickerDelegate 需要响应哪一个 picker 的请求
    private var pickerDelegateType = PickerDelegateType.search

    private let resolver: UserResolver

    private let disposeBag = DisposeBag()
    
    // 文件夹内需要预选中当前文件夹
    init(currentFolder: FolderInfo?, resolver: UserResolver) {
        self.resolver = resolver
        if let currentFolder {
            var rustMeta = RustPB.Search_V2_DocMeta()
            rustMeta.id = currentFolder.token
            rustMeta.type = .folder
            rustMeta.isShareFolder = currentFolder.isShareFolder

            let pickerMeta = PickerDocMeta(title: currentFolder.name, meta: rustMeta)
            folderFilterState.accept([pickerMeta])
        }
        setup()
    }

    private func setup() {
        resetInput.subscribe(onNext: { [weak self] in
            self?.reset()
        })
        .disposed(by: disposeBag)
    }

    private func reset() {
        ownedFilterState.accept(false)
        folderFilterState.accept([])
        typeFilterState.accept([])
        ownerFilterState.accept([])
        chatFilterState.accept([])
        updateSearchConfig()
    }

    func createItems() -> [CCMSearchFilterItemView] {
        return [
            createOwnedByMeFilterItem(),
            createFolderFilterItem(),
            createTypeFilterItem(),
            createOwnerFilterItem(),
            createChatFilterItem()
        ]
    }

    private func createOwnedByMeFilterItem() -> CCMSearchFilterItemView {
        let ownedItem = CCMSearchOwnedFilterItemView()
        ownedFilterState.bind(to: ownedItem.activeRelay).disposed(by: disposeBag)
        
        ownedItem.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
            guard let self else { return }
            self.ownedFilterState.accept(!self.ownedFilterState.value)
            self.updateSearchConfig()
        })
        .disposed(by: disposeBag)
        return ownedItem
    }

    private func createFolderFilterItem() -> CCMSearchFilterItemView {
        let folderItem = CCMSearchFolderFilterItemView()
        folderFilterState
            .map { docMetas -> [FolderInfo] in
                docMetas.map { docMeta in
                    FolderInfo(token: docMeta.id,
                               name: docMeta.title ?? DocsType.folder.untitledString,
                               isShareFolder: docMeta.meta?.isShareFolder ?? false)
                }
            }
            .bind(to: folderItem.selectionsRelay)
            .disposed(by: disposeBag)
        folderItem.rx.controlEvent(.touchUpInside)
            .withLatestFrom(folderFilterState)
            .map { [weak self] selections -> CCMSearchAction in
                guard let self else {
                    throw CCMSpaceSearchError.viewModelReleased
                }
                let controller = self.createFolderFilterController(selections: selections)
                controller.pickerDelegate = self
                self.pickerDelegateType = .folderFilter
                return .present(controller: controller)
            }
            .subscribe(onNext: { [weak self] action in
                self?.actionInput.accept(action)
            })
            .disposed(by: disposeBag)
        folderItem.didClickReset.subscribe(onNext: { [weak self] in
            guard let self else { return }
            self.folderFilterState.accept([])
            self.updateSearchConfig()
        })
        .disposed(by: disposeBag)
        return folderItem
    }

    private func createTypeFilterItem() -> CCMSearchFilterItemView {
        let typeItem = CCMSearchTypeFilterItemView()
        typeFilterState.bind(to: typeItem.selectionsRelay).disposed(by: disposeBag)

        typeItem.rx.controlEvent(.touchUpInside)
            .withLatestFrom(typeFilterState)
            .map { [weak self] selections -> CCMSearchAction in
                let controller = CCMTypeFilterController(selections: selections, showFolderOption: true)
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
                    throw CCMSpaceSearchError.viewModelReleased
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
            }
        }
        .bind(to: chatItem.selectionsRelay)
        .disposed(by: disposeBag)

        chatItem.rx.controlEvent(.touchUpInside)
            .withLatestFrom(chatFilterState)
            .map { [weak self] chatMetas -> CCMSearchAction in
                guard let self else {
                    throw CCMSpaceSearchError.viewModelReleased
                }
                let searchChatBody = self.createChatFilterController(selections: chatMetas)
                return .presentBody(searchChatBody)
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
        DocsLogger.info("update search config called")
        let config = generateSearchConfig()
        actionInput.accept(.update(searchConfig: config))
    }

    func generateSearchConfig() -> PickerSearchConfig {
        var docConfig = PickerConfig.DocEntityConfig(belongUser: .all,
                                                     belongChat: .all,
                                                     types: Basic_V1_Doc.TypeEnum.allCases,
                                                     folderTokens: [])


        if ownedFilterState.value, self.resolver.valid {
            let currentUserID = self.resolver.userID
            docConfig.belongUser = .belong([currentUserID])
        } else {
            let ownerIDs = ownerFilterState.value.map(\.id)
            if !ownerIDs.isEmpty {
                docConfig.belongUser = .belong(ownerIDs)
            }
        }
        let chatIDs = chatFilterState.value.map { meta in
            meta.groupID ?? meta.chatID
        }
        if !chatIDs.isEmpty {
            docConfig.belongChat = .belong(chatIDs)
        }

        let types = typeFilterState.value.flatMap(\.searchType)
        if !types.isEmpty {
            docConfig.types = types
        }
        docConfig.folderTokens = folderFilterState.value.map(\.id)
        return PickerSearchConfig(entities: [docConfig])
    }

    func generateBitableSearchConfig() -> PickerSearchConfig {
        var docConfig = PickerConfig.DocEntityConfig(belongUser: .all,
                                                     belongChat: .all,
                                                     types: [Basic_V1_Doc.TypeEnum.bitable],
                                                     folderTokens: [])
        var wikiConfig = PickerConfig.WikiEntityConfig(types: [Basic_V1_Doc.TypeEnum.bitable])

        if ownedFilterState.value, self.resolver.valid {
            let currentUserID = self.resolver.userID
            docConfig.belongUser = .belong([currentUserID])
        } else {
            let ownerIDs = ownerFilterState.value.map(\.id)
            if !ownerIDs.isEmpty {
                docConfig.belongUser = .belong(ownerIDs)
            }
        }
        let chatIDs = chatFilterState.value.map { meta in
            meta.groupID ?? meta.chatID
        }
        if !chatIDs.isEmpty {
            docConfig.belongChat = .belong(chatIDs)
        }

        let types = typeFilterState.value.flatMap(\.searchType)
        if !types.isEmpty {
            docConfig.types = types
        }
        docConfig.folderTokens = folderFilterState.value.map(\.id)
        
        return PickerSearchConfig(entities: [docConfig, wikiConfig])
    }
}


// MARK: SearchPickerDelegate
extension CCMSpaceSearchViewModel {
    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        switch pickerDelegateType {
        case .search:
            return searchPickerDidFinish(picker: pickerVc, items: items)
        case .folderFilter:
            return folderFilterPickerDidFinish(picker: pickerVc, items: items)
        case .owner:
            return ownerFilterPickerDidFinish(picker: pickerVc, items: items)
        case .chat:
            return true
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
private extension CCMSpaceSearchViewModel {
    func searchPickerDidFinish(picker: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        guard let item = items.first else {
            DocsLogger.error("picker did finish without item")
            return false
        }
        guard case let .doc(meta) = item.meta,
              let docMeta = meta.meta else {
            DocsLogger.error("un-expected item meta type found: \(item.meta.type)")
            return false
        }

        guard let url = URL(string: docMeta.url) else {
            DocsLogger.error("invalid item meta url found, fallback with token and type")
            let token = meta.id
            let objType = DocsType(pbDocsType: docMeta.type)
            let url: URL
            // 理论上 shortcut 不会被搜到，不会进入下面的分支
            if objType == .spaceShortcut {
                // shortcut 要用原始 url 打开
                let originToken = docMeta.oriID
                let originType = DocsType(pbDocsType: docMeta.oriType)
                url = DocsUrlUtil.url(type: originType, token: originToken)
            } else {
                url = DocsUrlUtil.url(type: objType, token: token)
            }
            actionInput.accept(.openURL(url: url))
            return false
        }
        actionInput.accept(.openURL(url: url))
        // 打开文档
        return false
    }
}

// 搜索场景过滤所在文件夹的二级搜索
private extension CCMSpaceSearchViewModel {

    func createFolderFilterController(selections: [PickerDocMeta]) -> SearchPickerNavigationController {
        let controller = SearchPickerNavigationController(resolver: self.resolver)
        // 按所有者过滤时，只搜人
        controller.searchConfig = PickerSearchConfig(entities: [
            PickerConfig.DocEntityConfig(types: [.folder],
                                         searchContentTypes: [.onlyTitle])
        ])
        controller.defaultView = PickerRecommendListView(resolver: self.resolver)
        let preSelections = selections.map { docMeta in
            PickerItem(meta: .doc(docMeta))
        }

        let multiSelectionConfig = PickerFeatureConfig.MultiSelection(isOpen: true,
                                                                      isDefaultMulti: !preSelections.isEmpty,
                                                                      canSwitchToMulti: true,
                                                                      canSwitchToSingle: false,
                                                                      preselectItems: preSelections,
                                                                      selectedViewStyle: .label {
            SKResource.BundleI18n.SKResource.Lark_ASLSearch_DocsTabFilters_InFolder_SelectMultipleFoldersMobile($0)
        })
        let naviBarConfig = PickerFeatureConfig.NavigationBar(title: SKResource.BundleI18n.SKResource.LarkCCM_CM_Search_InFolder_Option,
                                                              sureText: SKResource.BundleI18n.SKResource.Doc_Facade_Ok,
                                                              canSelectEmptyResult: true)
        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false,
                                                            autoFocus: true)
        controller.featureConfig = PickerFeatureConfig(scene: .ccmFilterByFolder,
                                                       multiSelection: multiSelectionConfig,
                                                       navigationBar: naviBarConfig,
                                                       searchBar: searchBarConfig)
        return controller
    }

    func folderFilterPickerDidFinish(picker: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        // 还原回响应 search 的事件
        pickerDelegateType = .search
        let selections = items.compactMap { item -> PickerDocMeta? in
            guard case let .doc(docMeta) = item.meta else {
                DocsLogger.error("un-expect type: \(item.meta.type) found in folder filter picker delegate")
                return nil
            }
            guard case .folder = docMeta.meta?.type else {
                DocsLogger.error("un-expect doc type: \(docMeta.meta?.type) found in folder filter picker delegate")
                return nil
            }
            return docMeta
        }
        self.folderFilterState.accept(selections)
        self.updateSearchConfig()
        return true
    }
}

// 搜索场景过滤所有者的二级搜索
private extension CCMSpaceSearchViewModel {
    func createOwnerFilterController(selections: [PickerChatterMeta]) -> ContactSearchPickerBody {
        var body = ContactSearchPickerBody()
        let preSelectedItems: [PickerItem] = selections.map { PickerItem(meta: .chatter($0)) }
        let naviBarConfig = PickerFeatureConfig.NavigationBar(title: SKResource.BundleI18n.SKResource.Doc_At_Select,
                                                              sureText: SKResource.BundleI18n.SKResource.Doc_Facade_Ok,
                                                              canSelectEmptyResult: true)
        let multiSelectionConfig = PickerFeatureConfig.MultiSelection(isOpen: true,
                                                                      isDefaultMulti: !preSelectedItems.isEmpty,
                                                                      canSwitchToMulti: true,
                                                                      canSwitchToSingle: false,
                                                                      preselectItems: preSelectedItems)
        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false,
                                                            autoFocus: true)
        body.featureConfig = .init(
            scene: .ccmFilterByOwner,
            multiSelection: multiSelectionConfig,
            navigationBar: naviBarConfig,
            searchBar: searchBarConfig
        )

        body.searchConfig = PickerSearchConfig(entities: [
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

// 搜索场景过滤所在会话的二级搜索
private extension CCMSpaceSearchViewModel {
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
}

#endif

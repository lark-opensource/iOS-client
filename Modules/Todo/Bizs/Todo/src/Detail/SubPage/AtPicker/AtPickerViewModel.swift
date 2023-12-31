//
//  AtPickerViewModel.swift
//  Todo
//
//  Created by 张威 on 2021/2/8.
//

import LarkContainer
import RustPB
import RxSwift
import RxCocoa
import TodoInterface
import LarkAccountInterface
import LarkBizTag

/// AtPicker - ViewModel

final class AtPickerViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    let rxViewState = BehaviorRelay<ListViewState>(value: .idle)
    let rxUpdateList = PublishRelay<Void>()

    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy private var formatApi: FormatRuleApi?
    @ScopedInjectedLazy private var messengerDependency: MessengerDependency?
    @ScopedInjectedLazy private var passportService: PassportUserService?

    private let disposeBag = DisposeBag()
    private var sections = [Section]()
    private var lastSearch: (query: String?, disposable: Disposable?)
    private lazy var currentTenantID = passportService?.userTenant.tenantID ?? ""
    private var formatRule: Rust.FormatRule = .unknown

    private var chatId: String?

    init(resolver: UserResolver, chatId: String?) {
        self.userResolver = resolver
        self.chatId = chatId
        fetchFormatRule()
    }

    func fetchFormatRule() {
        Detail.logger.info("begin fetchFormatRule")
        formatApi?.getAnotherNameFormat().take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] rule in
                    guard let self = self else { return }
                    Detail.logger.info("fetchFormatRule succeed")
                    self.formatRule = rule
                    self.sections = self.updateSections(self.sections)
                    if !self.sections.isEmpty {
                        self.rxViewState.accept(.data)
                    }
                },
                onError: { err in
                    Detail.logger.info("fetchFormatRule, failed, \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    /// 更新 query
    func updateQuery(_ query: String) {
        precondition(Thread.isMainThread, "should be invoked in mainThread")
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query != lastSearch.query else { return }

        lastSearch.query = query
        lastSearch.disposable?.dispose()

        // - InChat
        //   - noQuery: fetchAtListWithLocalOrRemote
        //   - hasQuery: 大搜.rustScene(.searchChatters)
        // - NotInChat
        //   - noQuery: fetchApi.getRecommendedUsers
        //   - hasQuery: 大搜.rustScene(.searchChatters)

        let rxResult: Single<[Section]>
        if !query.isEmpty {
            rxResult = getRecommendedUsers(byQuery: query)
        } else {
            if let chatId = chatId {
                rxResult = getRecommendedUsers(withChatId: chatId, query: query)
            } else {
                rxResult = getRecommendedUsers()
            }
        }
        rxViewState.accept(.loading)
        lastSearch.disposable = rxResult
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] sections in
                guard let self = self, self.lastSearch.query == query else { return }
                if sections.isEmpty {
                    self.rxViewState.accept(.empty)
                } else {
                    self.sections = self.updateSections(sections)
                    self.rxUpdateList.accept(void)
                    self.rxViewState.accept(.data)
                }
            })
    }

}

// MARK: - Fetch Data

extension AtPickerViewModel {

    // MARK: InChat

    private func getRecommendedUsers(withChatId chatId: String, query: String) -> Single<[Section]> {
        guard let messengerDependency = messengerDependency else { return .just([]) }
        Detail.logger.info("getRecommendedUsers(withChatId:) invoked. chatId: \(chatId), query: \(query)")

        let mapToCellItems = { (chatterIds: [String], res: ChatterSearchResultBasedOnChat) -> [CellItem] in
            return chatterIds.compactMap { chatterId -> CellItem? in
                guard let item = res.chatChatters[chatterId] ?? res.chatters[chatterId] else {
                    return nil
                }
                guard !item.isBot, !item.isAnonymous else {
                    return nil
                }
                var user = User(chatterId: chatterId, tenantId: item.tenantId, name: item.name, avatarKey: item.avatarKey)
                user.otherName = item.otherName
                return CellItem(user: user, department: nil, tagInfo: item.tagInfo)
            }
        }
        return messengerDependency.searchChatter(byQuery: query, basedOnChat: chatId)
            .filter { $0.isFromRemote }
            .map { result -> [Section] in
                let wantedCellItems = mapToCellItems(result.wantedChatterIds, result)
                let inChatCellItems = mapToCellItems(result.inChatChatterIds, result)
                let outChatCellItems = mapToCellItems(result.outChatChatterIds, result)
                var sections = [Section]()
                if !wantedCellItems.isEmpty {
                    sections.append(.init(title: I18N.Todo_Task_Mention, cellItems: wantedCellItems))
                }
                if !inChatCellItems.isEmpty {
                    sections.append(.init(title: I18N.Todo_Task_ChatMembers, cellItems: inChatCellItems))
                }
                if !outChatCellItems.isEmpty {
                    sections.append(.init(title: I18N.Todo_Task_NonChatMembers, cellItems: outChatCellItems))
                }
                return sections
            }
            .take(1)
            .asSingle()
    }

    // MARK: Not InChat

    private func getRecommendedUsers() -> Single<[Section]> {
        guard let fetchApi = fetchApi else { return .just([]) }
        Detail.logger.info("getRecommendedUsers invoked")
        return fetchApi.getRecommendedUsers(byCount: 50)
            .catchErrorJustReturn([])
            .map { users in
                let users = users.filter { !$0.chatter.isAnonymous && $0.chatter.type != .bot }
                let cellItems = users.map { CellItem(chatter: $0.chatter, department: $0.department) }
                if !cellItems.isEmpty {
                    return [Section(title: I18N.Todo_Task_ProbabilityAtPersonHint, cellItems: cellItems)]
                } else {
                    return []
                }
            }
            .take(1)
            .asSingle()
    }

    private func getRecommendedUsers(byQuery query: String) -> Single<[Section]> {
        guard let messengerDependency = messengerDependency else { return .just([]) }
        Detail.logger.info("getRecommendedUsers(byQuery:) invoked. query: \(query)")
        precondition(!query.isEmpty)
        return messengerDependency.searchChatter(byQuery: query)
            .filter { $0.isFromRemote }
            .map { result -> [Section] in
                let items = result.chatters.filter { !$0.isAnonymous && !$0.isBot }
                let cellItems = items.map { item -> CellItem in
                    return CellItem(
                        user: User(
                            chatterId: item.id,
                            tenantId: item.tenantId,
                            name: item.name,
                            avatarKey: item.avatarKey
                        ),
                        department: item.department,
                        tagInfo: item.tagInfo
                    )
                }
                if !cellItems.isEmpty {
                    return [Section(title: "", cellItems: cellItems)]
                }
                return []
            }
            .do(
                onError: { err in
                    Detail.logger.error("multiRemoteIntegrationSearch failed. err: \(err)")
                }
            )
            .catchErrorJustReturn([])
            .take(1)
            .asSingle()
    }

}

// MARK: - TableView Item

extension AtPickerViewModel {

    func numberOfSections() -> Int {
        return sections.count
    }

    func titleForHeader(inSection section: Int) -> String? {
        guard section >= 0 && section < sections.count else {
            assertionFailure()
            return nil
        }
        return sections[section].title
    }

    func numberOfRows(inSection section: Int) -> Int {
        guard section >= 0 && section < sections.count else {
            assertionFailure()
            return 0
        }
        return sections[section].cellItems.count
    }

    func cellDataForRow(atIndexPath indexPath: IndexPath) -> AtPickerTableViewCellDataType? {
        guard indexPath.section >= 0 && indexPath.section < sections.count else {
            assertionFailure()
            return nil
        }
        guard indexPath.row >= 0 && indexPath.row < sections[indexPath.section].cellItems.count else {
            assertionFailure()
            return nil
        }
        return sections[indexPath.section].cellItems[indexPath.row]
    }

    func userForRow(atIndexPath indexPath: IndexPath) -> User? {
        return (cellDataForRow(atIndexPath: indexPath) as? CellItem)?.user
    }

    func updateUser(_ user: User, completion: ((_ user: User) -> Void)?) {
        fetchApi?.getUsers(byIds: [user.chatterId]).take(1).asSingle()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { users in
                    guard let todoUser = users.first else { return }
                    var newUser = user
                    newUser.name = todoUser.name
                    completion?(newUser)
                },
                onError: { err in
                    completion?(user)
                    Detail.logger.info("updateUser failed, \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func updateSections(_ sections: [Section]) -> [Section] {
        guard !sections.isEmpty else { return sections }
        return sections.map { section in
            var newSection = section
            newSection.cellItems = section.cellItems.map({ [weak self] cellData in
                guard let self = self else { return cellData }
                var newCellData = cellData
                if let otherName = cellData.user.otherName {
                    newCellData.name = otherName.displayNameForPick(self.formatRule)
                } else {
                    newCellData.name = cellData.user.name
                }
                return newCellData
            })
            return newSection
        }
    }

}

extension AtPickerViewModel {

    private struct Section {
        var title: String
        var cellItems: [CellItem]
    }

    private struct CellItem: AtPickerTableViewCellDataType {
        var user: User

        var avatarSeed: AvatarSeed { user.avatar }
        var name: String = ""
        var tagInfo: [TagDataItem] = []
        var desc: String?

        init(user: User, department: String?, tagInfo: [TagDataItem]) {
            self.user = user
            self.desc = department
            self.tagInfo = tagInfo
        }

        init(chatter: Basic_V1_Chatter, department: String?) {
            user = User(chatter: chatter)
            tagInfo = chatter.tagInfo.transform()
            desc = department
        }
    }

}

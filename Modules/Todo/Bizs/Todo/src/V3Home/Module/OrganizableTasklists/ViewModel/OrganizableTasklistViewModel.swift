//
//  OrganizableTasklistViewModel.swift
//  Todo
//
//  Created by wangwanxin on 2023/10/23.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import RustPB
import LKCommonsLogging
import UniverseDesignIcon
import LarkDocsIcon

final class OrganizableTasklistViewModel: UserResolverWrapper {

    let userResolver: LarkContainer.UserResolver
    let context: V3HomeModuleContext

    // collection 内容宽度
    var contentViewWidth: CGFloat = 0
    var cellDatas = [OrganizableTasklistItemData]()
    // 信号
    let rxLoadMoreState = BehaviorRelay<ListLoadMoreState>(value: .none)
    let rxViewState = BehaviorRelay<ListViewState>(value: .idle)
    let rxListUpdate = BehaviorRelay(value: void)
    let logger = Logger.log(OrganizableTasklistViewModel.self, category: "Todo.OrganizableTasklist")

    private var currentLoadMoreId: String?
    private(set) var currentRequest = OrganizableRequest()
    @ScopedInjectedLazy private var listApi: TaskListApi?

    private let disposeBag = DisposeBag()

    init(resolver: LarkContainer.UserResolver, context: V3HomeModuleContext) {
        self.userResolver = resolver
        self.context = context     
    }

    private func setState() {
        context.store.rxValue(forKeyPath: \.sideBarItem)
            .observeOn(MainScheduler.asyncInstance)
            .distinctUntilChanged { $0 == $1 }
            .subscribe(onNext: { [weak self] item in
                guard let self = self, let item = item,
                      case .custom(let category) = item,
                      case .taskLists(let tab, let isArchived) = category
                else { return }
                OrganizableTasklist.Track.clickTab(tab: tab, isArchived: isArchived)
                self.fetchData(by: tab, and: isArchived)
            })
            .disposed(by: disposeBag)
    }

    func setup() {
        // 首次需要读取Sidebar里面的数据，因为state通知在前，
        if case .custom(let category) = context.store.state.sideBarItem,
           case .taskLists(let tab, let isArchived) = category {
            fetchData(by: tab, and: isArchived)
        }
        setState()
    }

    func retryFetch() {
        // reset token
        currentRequest.token = ""
        loadData()
    }

    func loadData() {
        rxViewState.accept(.loading)
        fetchData { [weak self] res in
            self?.handleResult(res, isLoadMore: false)
        } onError: { [weak self] _ in
            self?.rxViewState.accept(.failed(.needsRetry))
        }
    }

    func loadMore(silent: Bool = false) {
        guard currentLoadMoreId == nil, !currentRequest.token.isEmpty else {
            logger.error("is loading more")
            return
        }
        currentLoadMoreId = UUID().uuidString
        if !silent {
            rxLoadMoreState.accept(.loading)
        }
        fetchData { [weak self] res in
            self?.currentLoadMoreId = nil
            self?.handleResult(res, isLoadMore: true)
        } onError: { [weak self] _ in
            self?.currentLoadMoreId = nil
            self?.rxLoadMoreState.accept(.hasMore)
        }
    }

    private func fetchData(by tab: Rust.TaskListTabFilter, and isArchived: Bool) {
        currentRequest.tab = tab
        currentRequest.status = isArchived ? .taskContainerArchived : .taskContainerUnarchived
        currentRequest.token = ""
        loadData()
    }

    private func fetchData(
        onSuccess: @escaping (Rust.PagingTaskListRelatedRes) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        var page = Rust.PageReq()
        page.pageCount = Int32(currentRequest.count)
        page.pageToken = currentRequest.token
        listApi?.getPagingTaskListRelated(tab: currentRequest.tab, status: currentRequest.status, page: page)
            .take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: onSuccess,
                onError: { [weak self] error in
                    self?.logger.error("fetch paging tasklist related error. \(error)")
                    onError(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func handleResult(_ res: Rust.PagingTaskListRelatedRes, isLoadMore: Bool) {
        currentRequest.token = res.pageResult.lastToken
        if !isLoadMore {
            cellDatas = makeCellDatas(from: res)
        } else {
            cellDatas.append(contentsOf: makeCellDatas(from: res))
        }
        rxLoadMoreState.accept(res.pageResult.hasMore_p ? .hasMore : .noMore)
        rxViewState.accept(cellDatas.isEmpty ? .empty : .data)
        rxListUpdate.accept(void)
    }

    private func makeCellDatas(from res: Rust.PagingTaskListRelatedRes) -> [OrganizableTasklistItemData] {
        guard !res.containers.isEmpty else { return [] }
        return res.containers.map { container in
            var item = OrganizableTasklistItemData()
            item.leadingIconBuilder = IconBuilder(
                bizIconType: .iconInfo(
                    iconType: Int(container.iconInfo.type),
                    iconKey: container.iconInfo.key,
                    textColor: nil
                ),
                iconExtend: .init(
                    shape: .SQUARE,
                    placeHolderImage: UDIcon.getIconByKey(.tasklistFilled, iconColor: UIColor.ud.colorfulIndigo)
                )
            )
            item.userResolver = userResolver
            item.title = container.name
            item.identifier = container.guid

            if container.isArchived {
                item.tailingIcon = UDIcon.getIconByKey(
                    .massageBoxOutOutlined,
                    iconColor: UIColor.ud.iconN3,
                    size: OrganizableTasklistItemData.Config.tailingIconSize
                )
            }
            item.userInfo = {
                let name = container.owner.name
                let width = CGFloat(ceil(name.size(withAttributes: [
                    .font: OrganizableTasklistItemData.Config.userFont
                ]).width))
                + OrganizableTasklistItemData.Config.userIconSize.width
                + OrganizableTasklistItemData.Config.userPadding * 2
                + OrganizableTasklistItemData.Config.userIconTextSpace
                var user = OrganizableTasklistUserData()
                user.avatar = User(pb: container.owner).avatar
                user.name = name
                if let userNames = item.sectionInfos?.names, userNames.isEmpty {
                    user.preferredMaxLayoutWidth = min(cellContentMaxWidth, width)
                } else {
                    user.preferredMaxLayoutWidth = min(cellContentMaxWidth / 2, width)
                }
                return user
            }()
            item.sectionInfos = {
                var info = OrganizableTasklistSectionData()
                info.preferredMaxLayoutWidth = cellContentMaxWidth
                - (item.userInfo?.preferredMaxLayoutWidth ?? 0)
                - OrganizableTasklistItemData.Config.dividingLineWidth
                - OrganizableTasklistItemData.Config.itemSpace * 2
                info.names = res.taskContainerSectionRefs[container.guid]?.taskContainerSectionRefs
                    .compactMap { ref in
                        guard !ref.isDeleted else { return nil }
                        guard let section = res.taskContainerSections[ref.sectionGuid] else {
                            return nil
                        }
                        guard !section.isDefault else { return nil }
                        return section.displayName
                    }
                return info
            }()
            return item
        }
    }

    private var cellContentMaxWidth: CGFloat {
        // content - icon - iconContentSpace - padding * 2
        return contentViewWidth
        - OrganizableTasklistItemData.Config.iconSize.width
        - OrganizableTasklistItemData.Config.iconContentSpace
        - OrganizableTasklistItemData.Config.padding * 2
    }

}

extension OrganizableTasklistViewModel {

    func numberOfItems() -> Int {
        return cellDatas.count
    }

    func itemData(at indexPath: IndexPath) -> OrganizableTasklistItemData? {
        guard let row = Utils.safeCheckRows(indexPath, from: cellDatas) else { return nil }
        return cellDatas[row]
    }

    func needPreload(at indexPath: IndexPath) -> Bool {
        guard currentLoadMoreId == nil else { return false }
        // 总数要大于30才能触发, 因为首评拉的30条数据
        guard rxLoadMoreState.value == .hasMore else { return false }
        let leftCount = cellDatas.count - indexPath.row
        let needFetch = leftCount <= Utils.List.fetchCount.loadMore
        guard needFetch else { return false }
        return true
    }

}

extension OrganizableTasklistViewModel {
    struct OrganizableRequest {
        var tab: Rust.TaskListTabFilter = .taskContainerAll
        var status: Rust.TaskListStatusFilter = .taskContainerUnarchived
        var count: Int = Utils.List.fetchCount.initial
        var token: String = ""

        var isArchived: Bool {
            if case .taskContainerArchived = status {
                return true
            }
            return false
        }

        var emptyText: String { tab.emptyText }
    }

}

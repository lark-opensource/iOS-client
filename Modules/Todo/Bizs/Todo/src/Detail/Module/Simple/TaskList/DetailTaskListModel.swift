//
//  DetailTaskListModel.swift
//  Todo
//
//  Created by wangwanxin on 2022/12/23.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer

final class DetailTaskListModel: UserResolverWrapper {
    let store: DetailModuleStore
    var userResolver: LarkContainer.UserResolver
    // 刷新
    enum UpdateType {
        case reload(isAddHidden: Bool)
        case failed
        case idle
        case hidden
    }

    var onUpdate: ((UpdateType) -> Void)?

    private let disposeBag = DisposeBag()
    private var cellDatas: [DetailTaskListContentData] = []

    @ScopedInjectedLazy var listApi: TaskListApi?
    @ScopedInjectedLazy private var operateApi: TodoOperateApi?

    init(resolver: UserResolver, store: DetailModuleStore) {
        self.userResolver = resolver
        self.store = store
    }

    func setup() {
        store.rxInitialized()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] _ in
                guard let self = self else { return }
                if self.store.state.scene.isForEditing {
                    self.getSectionRef()
                } else {
                    self.getContainerMetaData()
                }
            })
            .disposed(by: disposeBag)

        Observable.combineLatest(
            store.rxValue(forKeyPath: \.relatedTaskLists).distinctUntilChanged({ $0?.count == $0?.count }),
            store.rxValue(forKeyPath: \.sectionRefResult)
        )
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.makeCellData(self.store.state.relatedTaskLists, result: self.store.state.sectionRefResult)
        })
        .disposed(by: disposeBag)
    }

    private func getSectionRef() {
        guard store.state.scene.isForEditing, let taskGuid = store.state.todo?.guid else { return }
        listApi?.getSections(by: taskGuid)
            .take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] res in
                guard let self = self else { return }
                self.store.dispatch(.updateTaskList(self.store.state.relatedTaskLists, res.results))
            }, onError: { [weak self] err in
                Detail.logger.error("get section failed, err: \(err)")
                self?.onUpdate?(.failed)
            }).disposed(by: disposeBag)
    }

    private func getContainerMetaData() {
        if let relatedTaskList = store.state.relatedTaskLists {
            makeCellData(store.state.relatedTaskLists, result: store.state.sectionRefResult)
        } else {
            // 新建场景，而且不是expand展开
            guard let taskListGuid = store.state.scene.taskListGuid else { return }
            self.listApi?.getContainerMetaData(by: taskListGuid, needSection: true)
                .take(1).asSingle()
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onSuccess: { [weak self] metaData in
                    self?.handleMetaDataForCreate(metaData)
                })
                .disposed(by: self.disposeBag)
        }
    }

    private func handleMetaDataForCreate(_ metaData: Rust.ContainerMetaData) {
        let taskList = metaData.container
        let sectionRank = store.state.scene.sectionRankForCreate
        var sectionID = sectionRank?.sectionID ?? ""
        if sectionID.isEmpty {
            sectionID = metaData.sections.first(where: { $0.isDefault })?.guid ?? ""
        }

        var ref = Rust.ContainerTaskRef()
        ref.taskGuid = ""
        ref.sectionGuid = sectionID
        ref.containerGuid = taskList.guid
        ref.rank = sectionRank?.rank ?? ""

        var sectionRef = Rust.SectionRefResult()
        sectionRef.ref = ref
        sectionRef.sections = metaData.sections

        store.dispatch(.updateTaskList([taskList], [taskList.guid: sectionRef]))
    }

    private func makeCellData(_ realatedTaskLists: [Rust.TaskContainer]?, result: [String: Rust.SectionRefResult]?) {
        guard let relatedTaskLists = realatedTaskLists, let result = result else {
            onUpdate?(.idle)
            return
        }
        cellDatas = relatedTaskLists.compactMap { taskList -> DetailTaskListContentData? in
            guard let sectionRef = result[taskList.guid] else { return nil }
            let selectedRef = sectionRef.ref
            let section = sectionRef.sections.first(where: { $0.containerID == taskList.guid && $0.guid == selectedRef.sectionGuid })
            guard let section = section else { return nil }
            return DetailTaskListContentData(
                taskListGuid: taskList.guid,
                taskListText: taskList.name,
                sectionText: section.displayName,
                hideArrow: !taskList.canEdit
            )
        }
        onUpdate?(cellDatas.isEmpty ? .idle : .reload(isAddHidden: !isEditable))
    }
}

// MARK: - ViewAction

extension DetailTaskListModel {

    func sectionRef(by taskListGuid: String) -> Rust.SectionRefResult? {
        guard let sectionRef = store.state.sectionRefResult?[taskListGuid] else {
            return nil
        }
        return sectionRef
    }

    func taskList(by taskListGuid: String) -> Rust.TaskContainer? {
        return store.state.relatedTaskLists?.first(where: { $0.guid == taskListGuid })
    }

    func deleteTaskList(by indexPath: IndexPath) {
        guard let cellData = cellData(indexPath: indexPath) else { return }
        guard let sectionRef = sectionRef(by: cellData.taskListGuid) else { return }
        // 乐观更新
        let oldTaskLists = store.state.relatedTaskLists, oldRefResult = store.state.sectionRefResult
        let exitedTaskLists = oldTaskLists?.filter { $0.guid != cellData.taskListGuid }
        let exitedSectionRefResult = oldRefResult?.filter { $0.key != cellData.taskListGuid }
        store.dispatch(.updateTaskList(exitedTaskLists, exitedSectionRefResult))
        guard store.state.scene.isForEditing else {
            return
        }

        let old = sectionRef.ref
        var new = old
        new.deleteMilliTime = Int64(NSDate().timeIntervalSince1970 * 1_000)
        listApi?.updateTaskContainerRef(new: new, old: old).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    guard let self = self else { return }
                    Detail.Track.clickDeleteTaskList(with: self.store.state.todo?.guid)
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.store.dispatch(.updateTaskList(oldTaskLists, oldRefResult))
                    Detail.logger.error("delete task list faild. err: \(err)")
                })
            .disposed(by: disposeBag)
    }

    func handlePickerResult(_ res: DetailTaskListPicker) {
        switch res {
        case .taskList(let taskList, let dictionary):
            if store.state.scene.isForEditing {
                updateTaskListRef(taskList, dictionary)
            } else {
                optimisticUpdate(taskList: taskList, refResult: dictionary)
            }
        case .sectionRef(let taskList, let dictionary, let containerTaskRef):
            if store.state.scene.isForEditing {
                updateSectionRef(dictionary, containerTaskRef)
            } else {
                optimisticUpdate(taskList: taskList, refResult: dictionary)
            }
        case .ownedSection, .none: break
        }
    }

    /// 更新清单Ref
    func updateTaskListRef(_ selectedTaskList: Rust.TaskContainer?, _ sectionRefRes: [String: Rust.SectionRefResult]?) {
        guard let selectedTaskList = selectedTaskList,
              let sectionRefRes = sectionRefRes,
              var sectionRef = sectionRefRes[selectedTaskList.guid] else {
            return
        }
        // 乐观更新
        let (oldTaskLists, oldRefResult) = optimisticUpdate(taskList: selectedTaskList, refResult: sectionRefRes)

        var newRef = sectionRef.ref
        // 编辑情况需要补充taskGuid
        newRef.taskGuid = store.state.todo?.guid ?? ""
        // 添加新的清单到任务，所以old为nil
        listApi?.updateTaskContainerRef(new: newRef, old: nil).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] newRef in
                    guard let self = self else { return }
                    Detail.Track.clickAddTaskList(with: self.store.state.todo?.guid)
                    // 服务端会修正ref，所以这里接受新的ref
                    sectionRef.ref = newRef
                    let sectionRefRes = self.store.state.sectionRefResult?.merging([selectedTaskList.guid: sectionRef]) { $1 }
                    let taskLists = self.store.state.relatedTaskLists
                    self.store.dispatch(.updateTaskList(taskLists, sectionRefRes))
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.store.dispatch(.updateTaskList(oldTaskLists, oldRefResult))
                    Detail.logger.error("update task container faild. err: \(err)")
                })
            .disposed(by: disposeBag)
    }

    // 更新分组ref
    private func updateSectionRef(_ sectionRefRes: [String: Rust.SectionRefResult]?, _ oldRef: Rust.ContainerTaskRef?, isNewSection: Bool = false) {
        guard let sectionRefRes = sectionRefRes, let oldRef = oldRef else { return }
        guard let taskListGuid = sectionRefRes.keys.first,
              let sectionRef = sectionRefRes.values.first else {
            return
        }

        // 乐观更新
        let (oldTaskLists, oldRefResult) = optimisticUpdate(taskList: nil, refResult: sectionRefRes)

        var new = sectionRef.ref, old = oldRef
        listApi?.updateTaskContainerRef(new: new, old: old).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    guard let self = self else { return }
                    Detail.Track.clickEditSection(with: self.store.state.todo?.guid, isNew: isNewSection)
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.store.dispatch(.updateTaskList(oldTaskLists, oldRefResult))
                    Detail.logger.error("update section faild. err: \(err)")
                })
            .disposed(by: disposeBag)

    }

    func handleCreateRes(_ res: DetailTaskListCreate) {
        switch res {
        case .taskList(let name):
            createNewTaskList(by: name)
        case .sectionRef(let taskList, let name):
            createNewSection(taskList, name: name)
        default: break
        }
    }

    private func createNewTaskList(by name: String?) {
        guard let name = name else { return }
        var container = Rust.TaskContainer()
        container.guid = UUID().uuidString.lowercased()
        container.name = name
        container.category = .taskList

        listApi?.upsertContainer(new: container, old: nil)
            .take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] metaData in
                    guard let self = self else { return }
                    self.handleNewTaskList(metaData)
                    // track
                    Detail.Track.clickCreateTaskList(
                        with: self.store.state.todo?.guid ?? "",
                        metaData.container.guid,
                        self.store.state.scene.isForCreating
                    )
                }, onError: { err in
                    Detail.logger.error("create task list failed. \(err)")
                })
            .disposed(by: disposeBag)
    }

    private func handleNewTaskList(_ metaData: Rust.ContainerMetaData) {
        let taskList = metaData.container
        let defaultSectionID = metaData.sections.first(where: { $0.isDefault })?.guid ?? ""

        var ref = Rust.ContainerTaskRef()
        ref.taskGuid = ""
        ref.sectionGuid = defaultSectionID
        ref.containerGuid = taskList.guid
        ref.rank = Utils.Rank.defaultMinRank
        var sectionRef = Rust.SectionRefResult()
        sectionRef.ref = ref
        sectionRef.sections = metaData.sections
        let newSectionRefResult = [taskList.guid: sectionRef]

        if store.state.scene.isForEditing {
            updateTaskListRef(taskList, newSectionRefResult)
        } else {
            optimisticUpdate(taskList: taskList, refResult: newSectionRefResult)
        }
    }

    private func createNewSection(_ taskList: Rust.TaskContainer, name: String?) {
        guard let name = name, let sectionRef = sectionRef(by: taskList.guid) else { return }
        // 乐观更新
        let newSection = {
            var section = Rust.TaskSection()
            section.containerID = taskList.guid
            section.guid = UUID().uuidString.lowercased()
            section.name = name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if let first = sectionRef.sections.first {
                section.rank = Utils.Rank.pre(of: first.rank)
            } else {
                section.rank = Utils.Rank.defaultMinRank
            }
            return section
        }()

        operateApi?.upsertSection(old: nil, new: newSection).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] section in
                    guard let self = self else { return }
                    // 乐观更新
                    var newSectionRef = sectionRef
                    newSectionRef.sections.insert(section, at: 0)
                    newSectionRef.ref.sectionGuid = section.guid
                    if self.store.state.scene.isForEditing {
                        self.updateSectionRef([taskList.guid: newSectionRef], sectionRef.ref, isNewSection: true)
                    } else {
                        Detail.Track.clickCreateListSection(with: self.store.state.todo?.guid)
                        self.optimisticUpdate(taskList: taskList, refResult: [taskList.guid: newSectionRef])
                    }
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    Detail.logger.error("create task list section faild. err: \(err)")
                })
            .disposed(by: disposeBag)
    }

    // 乐观更新
    @discardableResult
    private func optimisticUpdate(taskList: Rust.TaskContainer?, refResult: [String: Rust.SectionRefResult]?) -> (oldTaskLists: [Rust.TaskContainer]?, oldRefResult: [String: Rust.SectionRefResult]?) {
        let oldTaskLists = store.state.relatedTaskLists, oldRefResult = store.state.sectionRefResult

        var exitedTaskLists = oldTaskLists ?? [Rust.TaskContainer]()
        var exitedSectionRefResult = oldRefResult ?? [String: Rust.SectionRefResult]()

        if let taskList = taskList {
            // 找到则替换，否则添加到最后
            if let index = exitedTaskLists.firstIndex(where: { $0.guid == taskList.guid }) {
                exitedTaskLists[index] = taskList
            } else {
                exitedTaskLists.append(taskList)
            }
        }

        if let refResult = refResult {
            exitedSectionRefResult = exitedSectionRefResult.merging(refResult) { $1 }
        }
        store.dispatch(.updateTaskList(exitedTaskLists, exitedSectionRefResult))
        return (oldTaskLists, oldRefResult)
    }
}

// MARK: - TableVeiw

extension DetailTaskListModel {

    func numberOfRows() -> Int { cellDatas.count }

    func cellData(indexPath: IndexPath) -> DetailTaskListContentData? {
        guard let (section, _) = safeCheckIndexPath(indexPath) else { return nil }
        return cellDatas[section]
    }

    func safeCheckIndexPath(_ indexPath: IndexPath) -> (section: Int, row: Int)? {
        let (section, row) = (indexPath.section, indexPath.row)
        guard section >= 0
                && (cellDatas.isEmpty ? section == 0 : section < cellDatas.count)
                && row >= 0
                && (cellDatas.isEmpty ? row == 0 : row < 1)
        else {
            return nil
        }
        return (section, row)
    }

    /// 获取左滑按钮描述
    func getSwipeAction(_ indexPath: IndexPath) -> [V3SwipeActionDescriptor]? {
        if store.state.scene.isForCreating {
            return [.delete]
        }
        guard isEditable else {
            // 没有权限
            return nil
        }
        // 有任务权限，但没有清单权限
        guard let cellData = cellData(indexPath: indexPath),
              let taskList = taskList(by: cellData.taskListGuid),
              taskList.canEdit else {
            return nil
        }
        return [.delete]
    }

    var isEditable: Bool {
        if store.state.scene.isForCreating {
            return true
        }
        guard let todo = store.state.todo else {
            // 没有权限
            return false
        }
        return todo.selfPermission.isEditable
    }

    func getContentHeight(by type: UpdateType) -> CGFloat {
        switch type {
        case .reload(let isAddHidden):
            let headerHeight = DetailTaskListView.headerHeight
            let footHeight = isAddHidden ? 0 : DetailTaskListView.footerHeight
            return CGFloat(cellDatas.count) * (DetailTaskListContentCell.cellHeight + DetailTaskListContentCell.sectionFooterHeight) + footHeight + headerHeight
        case .failed, .idle:
            return 48.0
        case .hidden:
            return .zero
        }
    }
}

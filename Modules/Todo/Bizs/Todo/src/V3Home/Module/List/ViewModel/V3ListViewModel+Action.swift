//
//  V3ListViewModel+Action.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/28.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - List Action

extension V3ListViewModel {
    /// swipe action
    func getSwipeDescriptor(at indexPath: IndexPath, with guid: String) -> [V3SwipeActionDescriptor]? {
        guard let cellData = cellData(at: indexPath, with: guid) else {
            V3Home.logger.info("can not find cell data, when swipe at \(indexPath) with \(guid)")
            return nil
        }
        guard !cellData.todo.guid.isEmpty else { return nil }
        let todo = cellData.todo
        var left = [V3SwipeActionDescriptor](), right = [V3SwipeActionDescriptor]()
        // 右侧action
        if todo.editable(for: .todoDeletedTime) {
            left.append(contentsOf: [.delete, .share])
        } else if !todo.isOutsider(curUserId) {
            left.append(contentsOf: [.quit, .share])
        } else {
            left.append(contentsOf: [.share])
        }
        if !left.isEmpty {
            V3Home.Track.clickSwipeItem(true)
        }

        // 左侧action
        if todo.editable(for: .todoCompletedTime) || isTaskEditableInContainer {
            if todo.isComleted(completeService) {
                right.append(.uncomplete)
            } else {
                right.append(.complete)
            }
        }
        if todo.editable(for: .todoDueTime) || isTaskEditableInContainer {
            right.append(.dueTime)
        }
        if !right.isEmpty {
            V3Home.Track.clickSwipeItem(false)
        }
        return left + right
    }

    /// 操作右侧按钮
    func doRightAction(at indexPath: IndexPath, with guid: String, action: V3SwipeActionDescriptor) -> Single<ListActionResult> {
        guard let cellData = cellData(at: indexPath, with: guid) else {
            return .just(.succeed(toast: nil))
        }
        removeItem(at: indexPath, with: guid, action: action)
        return operateTodo(cellData.todo, acion: action)
    }

    func doUpdateTime(at indexPath: IndexPath, with guid: String, and components: TimeComponents) {
        guard let cellData = cellData(at: indexPath, with: guid) else {
            return
        }
        var newTodo = cellData.todo
        components.appendSelf(to: &newTodo)
        doUpdateTodo(from: cellData.todo, to: newTodo)
    }

    // 调用update todo接口，不需要乐观更新，sdk已经有乐观更新了。失败情况也不需要处理
    private func doUpdateTodo(from oldTodo: Rust.Todo, to newTodo: Rust.Todo) {
        operateApi?.updateTodo(from: oldTodo, to: newTodo, with: curContainerID).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { _ in
                    V3Home.logger.error("doUpdate success")
                },
                onError: { err in
                    V3Home.logger.error("doUpdate failed. err: \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    /// 从本地移除
   private func removeItem(at indexPath: IndexPath, with guid: String, action: V3SwipeActionDescriptor) {
       guard !isTaskList || (isTaskList && action == .delete) else { return }
       guard let todo = self.cellData(at: indexPath, with: guid)?.todo else {
           V3Home.logger.info("remove item failed. cell data is nil")
           return
       }
       V3Home.logger.info("begin remove item. guid:\(todo.guid), from \(action)")
       // 乐观更新内存数据
       var deletedTodo = todo
       deletedTodo.deletedMilliTime = Int64(NSDate().timeIntervalSince1970 * 1_000)
       diffUpdate([deletedTodo])
    }

    private func operateTodo(_ todo: Rust.Todo, acion: V3SwipeActionDescriptor) -> Single<ListActionResult> {
        V3Home.logger.info("operate todo, guid: \(todo.guid), action: \(acion)")
        guard let operateApi = operateApi else { return .just(.failed(toast: nil)) }
        // 重置乐观更新
        var oldTodo = todo
        oldTodo.deletedMilliTime = 0
        let subject = PublishSubject<Void>()
        let op = acion == .delete ?
            operateApi.deleteTodo(forId: todo.guid, source: todo.source) :
            operateApi.quitTodo(forId: todo.guid, source: todo.source)
        op.take(1).asSingle()
            .subscribe(
                onSuccess: { _ in
                    subject.onCompleted()
                },
                onError: { [weak self] err in
                    subject.onError(err)
                    V3Home.logger.error("operate todo failed. reset by \(oldTodo.logInfo)")
                    self?.diffUpdate([oldTodo])
                }
            )
            .disposed(by: disposeBag)
        return .create { single -> Disposable in
            return subject.subscribe(
                onError: {
                    let toast = todo.source == .oapi ? acion.oapiFailureToast : Rust.displayMessage(from: $0)
                    single(.success(.failed(toast: toast)))
                },
                onCompleted: {
                    single(.success(.succeed(toast: acion.successToast)))
                }
            )
        }
    }
}

// MARK: - Section

extension V3ListViewModel {
    // 折叠分组
    func foldSection(section: Int, sectionId: String) {
        V3Home.logger.info("begin fold section \(sectionId)")
        let t = { [weak self] () -> V3ListViewData? in
            guard let self = self, self.isSectionValid(in: section, with: sectionId) else { return nil }
            var viewData = self.curViewData
            guard let header = viewData.data[section].header else {
                V3Home.assertionFailure("can not find header, when fold section")
                return viewData
            }
            self.tryCleanMarkedTodo(false)
            let newFoldState = !header.isFold
            self.updateFoldState(section: sectionId, isFold: newFoldState)
            viewData.data[section].header?.isFold = newFoldState
            viewData.data[section].footer.isFold = newFoldState
            return viewData
        }
        queue.addTask(t)
    }

    /// 点击更多标题
    func sectionMoreItems(section: Int, sectionId: String) -> ([(SectionMoreAction, String)], String?)? {
        guard isSectionValid(in: section, with: sectionId) else {
            V3Home.logger.info("did tap section more failed. sectionId: \(sectionId)")
            return nil
        }
        var items: [(SectionMoreAction, String)] = [
            (.rename, I18N.Todo_New_Section_RenameSection_Button),
            (.forwardCreate, I18N.Todo_New_Section_AddSectionAbove_Button),
            (.backwardCreate, I18N.Todo_New_Section_AddSectionBelow_Button)
        ]
        if FeatureGating(resolver: userResolver).boolValue(for: .reorderSection) {
            items.append((.reorder, I18N.Todo_ManageSectionSorting_Button))
        }
        var delete: String?
        let containerId = curContainerID
        let sections = curListMetaData?.sections.filter { $0.guid == sectionId && $0.containerID == containerId }
        if let sectionData = sections?.first, sectionData.isDefault {
            delete = nil
        } else {
            delete = I18N.Todo_New_Section_DeleteSection_Button
        }
        return (items, delete)
    }

    func dialogContent(in section: Int, with sectionId: String, action: V3ListViewModel.SectionMoreAction) -> (String, String?, String)? {
        guard isSectionValid(in: section, with: sectionId) else {
            V3Home.logger.info("did tap dialog failed. sectionId: \(sectionId)")
            return nil
        }
        let title = I18N.Todo_New_Section_NewSection_Button
        let placeholder = I18N.Todo_New_Section_EnterSectionName_Placeholder
        if action == .rename {
            let text = curViewData.data[section].header?.titleInfo?.text
            return (I18N.Todo_New_Section_RenameSection_Button, text ?? placeholder, placeholder)
        }
        return (title, nil, placeholder)
    }

    /// 删除分组
    func deleteSection(in section: Int, with sectionId: String) -> Single<ListActionResult> {
        guard isSectionValid(in: section, with: sectionId) else {
            V3Home.logger.info("delete section failed. sectionId: \(sectionId)")
            return .just(.succeed(toast: nil))
        }
        V3Home.Track.clickListEditSectionDelete(with: context.store.state.container)
        let containerId = curContainerID, curListMeta = curListMetaData
        let sections = curListMeta?.sections.filter { $0.guid == sectionId && $0.containerID == containerId }
        guard let sectionData = sections?.first else {
            return .just(.succeed(toast: nil))
        }
        let subject = PublishSubject<Void>()
        // 乐观更新
        var deletedSection = sectionData
        deletedSection.deleteMilliTime = Int64(NSDate().timeIntervalSince1970 * 1_000)
        // 更新newRefs
        let refs = curListMeta?.refs.filter { $0.containerGuid == deletedSection.containerID && $0.sectionGuid == deletedSection.guid }
        var newRefs = refs
        let defaultSection = curListMeta?.sections.first(where: { $0.isDefault })
        if let tmpRefs = newRefs, !tmpRefs.isEmpty, let tmpSection = defaultSection {
            newRefs = tmpRefs.map { ref in
                var new = ref
                new.sectionGuid = tmpSection.guid
                return new
            }
        }
        updateSections([deletedSection], with: newRefs)
        operateApi?.deleteSection(guid: sectionData.guid, containerID: sectionData.containerID).take(1).asSingle()
            .subscribe(
                onSuccess: { _ in
                    subject.onCompleted()
                },
                onError: { [weak self] err in
                    subject.onError(err)
                    V3Home.logger.error("delete section failed. reset data by \(sectionData.logInfo), refs: \(refs?.map(\.logInfo) ?? [])")
                    self?.updateSections([sectionData], with: refs)
                }
            )
            .disposed(by: disposeBag)
        return .create { single -> Disposable in
            return subject.subscribe(
                onError: {
                    let toast = Rust.displayMessage(from: $0)
                    single(.success(.failed(toast: toast)))
                },
                onCompleted: {
                    single(.success(.succeed(toast: I18N.Todo_CollabTask_Successful)))
                }
            )
        }
    }

    func upsertSection(in section: Int, with sectionId: String, action: SectionMoreAction, name: String?) -> Single<ListActionResult> {
        guard isSectionValid(in: section, with: sectionId) else {
            V3Home.logger.info("upsert section failed. sectionId: \(sectionId), action: \(action)")
            return .just(.succeed(toast: nil))
        }
        let containerId = curContainerID, curListMeta = curListMetaData
        let sections = curListMeta?.sections.filter { $0.guid == sectionId && $0.containerID == containerId }
        guard let baseSection = sections?.first else {
            V3Home.logger.info("base section can not found")
            return .just(.succeed(toast: nil))
        }
        let subject = PublishSubject<Void>()
        var newSection: Rust.TaskSection?, oldSection: Rust.TaskSection = baseSection

        switch action {
        case .rename:
            newSection = baseSection
            newSection?.name = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        case .forwardCreate, .backwardCreate:
            newSection = Rust.TaskSection()
            newSection?.containerID = baseSection.containerID
            newSection?.guid = UUID().uuidString.lowercased()
            newSection?.name = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            newSection?.rank = findNearestSectionRank(baseSection, by: action, in: curListMeta)
            // 接口失败的时候保证能reset回去
            oldSection = newSection ?? Rust.TaskSection()
            oldSection.deleteMilliTime = Int64(NSDate().timeIntervalSince1970 * 1_000)
        case .reorder: break
        }
        guard let newSection = newSection else { return .just(.succeed(toast: nil)) }
        // 乐观更新
        updateSections([newSection])
        operateApi?.upsertSection(old: action == .rename ? baseSection : nil, new: newSection).take(1).asSingle()
            .subscribe(
                onSuccess: { _ in
                    subject.onCompleted()
                },
                onError: { [weak self] err in
                    subject.onError(err)
                    V3Home.logger.error("upset failed. reset data by \(oldSection.logInfo)")
                    self?.updateSections([oldSection])
                }
            )
            .disposed(by: disposeBag)
        return .create { single -> Disposable in
            return subject.subscribe(
                onError: {
                    let toast = Rust.displayMessage(from: $0)
                    single(.success(.failed(toast: toast)))
                },
                onCompleted: {
                    single(.success(.succeed(toast: I18N.Todo_CollabTask_Successful)))
                }
            )
        }
    }

    /// 查找最近的section rank
    private func findNearestSectionRank(_ baseSection: Rust.TaskSection, by action: SectionMoreAction, in listMetaData: ListMetaData?) -> String {
        let defaultRank = Utils.Rank.next(of: baseSection.rank)
        guard let localSections = listMetaData?.sections else {
            return defaultRank
        }
        let sections = localSections
            .filter { $0.containerID == baseSection.containerID }
            .sorted(by: { $0.rank < $1.rank })
        guard let index = sections.firstIndex(where: { $0.guid == baseSection.guid }),
              [.forwardCreate, .backwardCreate].contains(action) else {
            return defaultRank
        }
        if action == .forwardCreate {
            if index == 0 {
                // 首位的时候直接算
                return Utils.Rank.pre(of: baseSection.rank)
            } else {
                return Utils.Rank.middle(of: baseSection.rank, and: sections[index - 1].rank)
            }
        } else {
            if index == sections.count - 1 {
                // 末尾的时候也是直接算
                return Utils.Rank.next(of: baseSection.rank)
            } else {
                return Utils.Rank.middle(of: baseSection.rank, and: sections[index + 1].rank)
            }
        }
    }

    func createTodo(in section: Int, with sectionId: String) {
        guard isSectionValid(in: section, with: sectionId) else {
            V3Home.logger.info("create todo failed, because secion invalid")
            return
        }
        let sectionData = curViewData.data[section], containerId = curContainerID
        guard sectionData.isCustom else {
            V3Home.logger.info("not support create todo is this section \(sectionId)")
            return
        }
        var param = Rust.ContainerSection()
        param.containerGuid = containerId
        param.sectionGuid = sectionData.isCustom ? sectionId : ""
        param.rank = findNearestTodoRank(containerId, sectionId, in: curListMetaData)
        var task = Rust.Todo().fixedForCreating()
        if isTaskList {
            guard let taskList = curTaskList else { return }
            task.relatedTaskListGuids = [taskList.guid]
            context.bus.post(.createTodo(param: .taskList(task, param)))
        } else {
            context.bus.post(.createTodo(param: .container(param, task)))
        }
    }

    private func findNearestTodoRank(_ containerId: String, _ sectionId: String, in listMetaData: ListMetaData?) -> String {
        let defaultRank = Utils.Rank.defaultRank
        guard let localSections = listMetaData?.sections else {
            return defaultRank
        }
        let sections = localSections
            .filter { $0.containerID == containerId }
            .sorted(by: { $0.rank < $1.rank })
        guard let index = sections.firstIndex(where: { $0.guid == sectionId }) else {
            return defaultRank
        }
        // 约定先往前找
        for i in (0...index).reversed() {
            let refs = listMetaData?.refs
                .filter { $0.containerGuid == containerId && $0.sectionGuid == sections[i].guid }
                .sorted(by: { $0.rank < $1.rank })
            if let last = refs?.last {
                return Utils.Rank.next(of: last.rank)
            }
        }

        // 在往后找
        for i in index..<sections.count {
            let refs = listMetaData?.refs
                .filter { $0.containerGuid == containerId && $0.sectionGuid == sections[i].guid }
                .sorted(by: { $0.rank < $1.rank })
            if let first = refs?.first {
                return Utils.Rank.pre(of: first.rank)
            }
        }
        return defaultRank
    }

    func reorderSections(_ new: [V3ListSectionData], _ old: [V3ListSectionData]) {
        V3Home.logger.info("start reorder sections")
        V3Home.Track.clickDragSection(with: context.store.state.container)
        guard new.count > 1, new.count == old.count, let curListMeta = curListMetaData else { return }
        // 当前留存的数据
        let action = { (data: V3ListSectionData) -> Rust.TaskSection? in
            return curListMeta.sections.first(where: { $0.guid == data.sectionId })
        }
        let curOldSections = old.compactMap(action), curNewSections = new.compactMap(action)
        guard curNewSections.count > 1, curNewSections.count == curOldSections.count else { return }
        // 计算rank
        var batchSection: [Rust.BatchSection] = [Rust.BatchSection]()
        for (index, value) in curNewSections.enumerated() {
            if let section = curOldSections.first(where: { $0.guid == value.guid }) {
                var newSection = section
                newSection.rank = curOldSections[index].rank
                var entity = Rust.BatchSection()
                entity.newSection = newSection
                entity.oldSection = section
                batchSection.append(entity)
            }
        }
        // 乐观更新
        updateSections(batchSection.map(\.newSection))
        operateApi?.batchUpsertSection(batchSection).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { _ in
                    V3Home.logger.info("batch upsert section success")
                },
                onError: { [weak self] err in
                    self?.updateSections(batchSection.map(\.oldSection))
                    V3Home.logger.error("batch upsert section failed. err: \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

}

// MARK: - Drag Drop Todo

extension V3ListViewModel {

    func checkCanDrag() -> (canDrag: Bool, toast: String?) {
        // 只有清单和我负责的支持拖拽
        guard isTaskList || isOwnedView else { return (false, nil) }
        // PRD: 优先级：先判断“暂无清单编辑权限”，再判断“由于设置了特定的排序规则，暂时无法拖拽任务。”，“当前分组设置不支持拖拽”
        if isTaskList, isTaskEditableInContainer == false {
            return (false, I18N.Todo_UnableCustomSortDueToPermissions_Toast)
        }
        if let sort = curView.sort, sort.field != .custom {
            return (false, I18N.Todo_UnableDragAndDropInThisSort_Toast)
        }
        if let group = curView.group, [.source, .creator, .startTime].contains(group) {
            return (false, I18N.Todo_UnableDragAndDropInThisSection_Toast)
        }
        return (true, nil)
    }

    func moveItem(from: String, to: String, preGuid: String?, todo: Rust.Todo, nextGuid: String?) {
        guard let ref = findRef(by: todo.guid, and: curContainerID, in: curListMetaData) else {
            V3Home.logger.error("can not move item cause ref is nil")
            return
        }
        V3Home.Track.clickDragTask(with: context.store.state.container)
        var oldTodo = todo, newTodo = oldTodo, changed = false, fromSection = from, toSection = to
        // 比如在无分组、截止时间、负责人、拖拽的时候，由于sectionid是本地的，需要替换回原来
        if UUID(uuidString: fromSection) == nil {
            fromSection = ref.sectionGuid
        }
        if UUID(uuidString: to) == nil {
            toSection = ref.sectionGuid
        }
        if from != to {
            // 不同分组内移动
            if let group = curView.group, case .dueTime = group {
                guard let header = curViewData.data.first(where: { $0.sectionId == to })?.header,
                      let type = header.dueTimeType else { return }
                newTodo.updateDueTime(to: type, offset: settingService?.defaultDueTimeDayOffset ?? 0, with: curTimeContext.timeZone)
                changed = true
            } else if let group = curView.group, case .startTime = group {
                guard let header = curViewData.data.first(where: { $0.sectionId == to })?.header,
                      let type = header.startTimeType else { return }
                newTodo.updateStartTime(to: type, offset: settingService?.defaultStartTimeDayOffset ?? 0, with: curTimeContext.timeZone)
                changed = true
            } else if let group = curView.group, case .owner = group {
                guard let header = curViewData.data.first(where: { $0.sectionId == to })?.header else { return }
                if let users = header.users {
                    // 负责人
                    newTodo.assignees = users.map { $0.asModel() }
                } else {
                    // 无负责任
                    newTodo.assignees = []
                }
                changed = true
            }
        }

        let newRef: Rust.ContainerTaskRef = {
            var new = ref
            new.sectionGuid = toSection
            new.rank = getRank(pre: preGuid, next: nextGuid, defaultRank: ref.rank)
            return new
        }()

        let oldRef: Rust.ContainerTaskRef = {
            var old = newRef
            old.sectionGuid = fromSection
            old.rank = ref.rank
            return old
        }()
        // 需要先乐观更新，然后在调用接口，不然会有跳动
        updateRefs([newRef])
        if changed {
            doUpdateTodo(from: oldTodo, to: newTodo)
        }
        listApi?.updateTaskContainerRef(new: newRef, old: oldRef).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { ref in
                    V3Home.logger.info("move item success, ref \(ref.logInfo)")
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    V3Home.logger.error("move item faild. err: \(err)")
                    self.updateRefs([oldRef])
                })
            .disposed(by: disposeBag)
    }

    private func findRef(by taskGuid: String, and containerID: String, in listMetaData: ListMetaData?) -> Rust.ContainerTaskRef? {
        guard let listMetaData = listMetaData else { return nil }
        let first = listMetaData.refs.first(where: { $0.containerGuid == containerID && $0.taskGuid == taskGuid })
        if let first = first, first.isValid {
            return first
        }
        return nil
    }

    private func getRank(pre: String?, next: String?, defaultRank: String) -> String {
        if pre == nil, let next = next, let ref = findRef(by: next, and: curContainerID, in: curListMetaData) {
            return Utils.Rank.pre(of: ref.rank)
        }
        if let pre = pre, next == nil, let ref = findRef(by: pre, and: curContainerID, in: curListMetaData) {
            return Utils.Rank.next(of: ref.rank)
        }
        if let pre = pre, let next = next, let preRef = findRef(by: pre, and: curContainerID, in: curListMetaData), let nextRef = findRef(by: next, and: curContainerID, in: curListMetaData) {
            return Utils.Rank.middle(of: preRef.rank, and: nextRef.rank)
        }
        return defaultRank
    }
}

// MARK: - Complete Todo

extension V3ListViewModel {

    func getCustomComplete(from todo: Rust.Todo) -> CustomComplete? {
        return completeService?.customComplete(from: todo)
    }

    func doubleCheckBeforeToggleCompleteState(from todo: Rust.Todo) -> CompleteDoubleCheckContext? {
        return completeService?.doubleCheckBeforeToggleState(
            with: .todo,
            todo: todo,
            hasContainerPermission: (isTaskEditableInContainer || todo.editable(for: .todoCompletedMilliTime))
        )
    }

    func toggleCompleteStatus(at indexPath: IndexPath, with guid: String, isFromSlide: Bool) -> Single<ListActionResult> {
        guard let cd = cellData(at: indexPath, with: guid), let completeService = completeService else {
            V3Home.logger.info("can not find cell data, when complete todo")
            return .just(.succeed(toast: nil))
        }
        let guid = cd.todo.guid, containerID = curContainerID
        var fromState = cd.completeState, toState = cd.completeState.toggled(by: .todo)
        if isTaskEditableInContainer || cd.todo.editable(for: .todoCompletedMilliTime) {
            fromState = completeService.mergeCompleteState(fromState, with: cd.todo.isTodoCompleted)
        }
        // log & track
        if isFromSlide {
            V3Home.Track.clickListSlideToComplete(with: context.store.state.container, guid: guid, isDone2Undone: fromState.isCompleted)
        } else {
            V3Home.Track.clickCheckBox(with: context.store.state.container, guid: guid, fromState: fromState)
        }
        V3Home.logger.info("list toggle complete, guid: \(guid), from:\(fromState), to:\(toState)")
        if !isAllCompleteStatus {
            // 如果不是全部仍然支持乐观更新，先删除数据
            removeItem(at: indexPath, with: guid, action: .complete)
        }
        let lastViewData = curViewData, subject = PublishSubject<Void>()
        let ctx = CompleteContext(fromState: fromState, role: .todo)
        completeService.toggleState(with: ctx, todoId: guid, todoSource: cd.todo.source, containerID: containerID)
            .subscribe(onSuccess: { res in
                subject.onCompleted()
                V3Home.logger.info("list toggle complete succeed. guid: \(guid), from:\(fromState), to:\(res.newState)")
            }, onError: { [weak self] err in
                V3Home.logger.info("list toggle complete failed. guid: \(guid), err: \(err)")
                subject.onError(err)
                self?.queue.addTask { return lastViewData }
            })
            .disposed(by: disposeBag)
        return .create { single -> Disposable in
            return subject.subscribe(
                onError: {
                    single(.success(.failed(toast: Rust.displayMessage(from: $0))))
                },
                onCompleted: {
                    let toast = cd.completeState.toggleSuccessToast(by: .todo)
                    single(.success(.succeed(toast: toast)))
                }
            )
        }
    }
}

// MARK: - Selcted Item

extension V3ListViewModel {
    // 记录选中的Id
    func updateSelected(_ selctedGuid: String?) {
        selectedGuid = selctedGuid
    }

    // 更新数据选中index path
    func updateSelctedIndexPath(_ viewData: V3ListViewData) -> V3ListViewData {
        guard let selected = selectedGuid, !selected.isEmpty else { return viewData }
        var data = viewData
        if let indexPath = indexPath(from: selected) {
            data.afterTransition = .selectItem(indexPath: indexPath)
        } else {
            data.afterTransition = .none
        }
        return data
    }
}

// MARK: New Todo

extension V3ListViewModel {
    // 取消高亮
    func tryCleanMarkedTodo(_ refreshNow: Bool = true) {
        guard !newCreatedGuid.isEmpty else { return }
        newCreatedGuid = nil
        if refreshNow {
            queue.addTask { [weak self] () -> V3ListViewData? in
                guard let self = self else { return nil }
                return self.makeListViewData(hasMore: self.hasMore)
            }
        }
    }

    /// 记录本地创建的Todo，用于标记高亮
    func didCreatedTodo(_ res: Rust.CreateTodoRes) {
        V3Home.logger.info("did created new todo. \(res.logInfo)")
        newCreatedGuid = res.todo.guid
        // 任务清单中创建
        if !res.taskListContainerRefs.isEmpty {
            if let ref = res.taskListContainerRefs.first(where: { $0.containerGuid == curContainerID && $0.taskGuid == res.todo.guid }) {
                var taskRef = Rust.TaskRefInfo()
                taskRef.task = res.todo
                taskRef.ref = ref
                updateTasks([taskRef])
            }
        }
        // 我负责的
        if res.taskContainerRef.isValid {
            diffUpdate([res.todo], with: [res.taskContainerRef])
        }
    }
}

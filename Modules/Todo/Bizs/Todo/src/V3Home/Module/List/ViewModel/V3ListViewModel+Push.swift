//
//  V3ListViewModel+Push.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/31.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - Data Push

extension V3ListViewModel {

    func listenUpdateNoti() {
        updateNoti?.rxFullUpdate
            .subscribe(onNext: { [weak self] _ in
                self?.fullUpdate()
            })
            .disposed(by: disposeBag)
        updateNoti?.rxDiffUpdate
            .subscribe(onNext: { [weak self] changeset in
                self?.diffUpdate(changeset.todos)
            })
            .disposed(by: disposeBag)
        updateNoti?.rxExtraUpdate
            .subscribe(onNext: { [weak self] infos in
                self?.updateExtra(infos)
            })
        .disposed(by: disposeBag)
        updateNoti?.rxSectionUpdate
            .subscribe(onNext: { [weak self] sections in
                self?.updateSections(sections)
            })
            .disposed(by: disposeBag)
        updateNoti?.rxRefsUpdate
            .subscribe(onNext: { [weak self] refs in
                self?.updateRefs(refs)
            })
            .disposed(by: disposeBag)
        listNoti?.rxTasksUpdate
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] taskRefs in
                self?.updateTasks(taskRefs)
            })
            .disposed(by: disposeBag)
    }

    private func fullUpdate() {
        if !curViewData.isEmpty {
            V3Home.logger.info("receive full upadate, but view data is not empty")
        }
        context.bus.post(.refetchAllTask)
    }

    /// Tasks
    func diffUpdate(_ todos: [Rust.Todo], with refs: [Rust.ContainerTaskRef]? = nil) {
        guard !todos.isEmpty else { return }
        let t = { [weak self] () -> V3ListViewData? in
            guard let self = self else { return nil }
            // log
            V3Home.logger.info("diff upadte \(todos.map(\.logInfo).joined(separator: ","))")
            // update refs
            var metaData = self.listScene.persist
            if let refs = refs {
                let tuple = self.updateRefData(refs, baseline: metaData?.refs ?? [])
                if tuple.changed {
                    metaData?.refs = tuple.refs
                }
            }
            // update all tasks
            let tuple = self.updateTaskData(todos, baseline: metaData?.tasks, curUserId: self.curUserId)
            if tuple.changed {
                metaData?.tasks = tuple.todos
                // 更新数据
                if let metaData = metaData {
                    self.listScene.persist = metaData
                }
            }

            // 任务清单存在需要更新任务清单
            var tasklistChanged = false
            if var taskListMetaData = self.listScene.temporary {
                if let refs = refs {
                    let tuple = self.updateRefData(refs, baseline: taskListMetaData.refs)
                    if tuple.changed {
                        tasklistChanged = true
                        taskListMetaData.refs = tuple.refs
                    }
                }
                let taskListTodos = todos.filter { $0.relatedTaskListGuids.contains(where: { $0 == self.curContainerID }) }
                let taskListTuple = self.updateTaskData(taskListTodos, baseline: taskListMetaData.tasks, curUserId: self.curUserId, ignoreRole: true)
                if taskListTuple.changed {
                    tasklistChanged = true
                    taskListMetaData.tasks = taskListTuple.todos
                    self.listScene.temporary = taskListMetaData
                }
            }

            if tuple.changed || tasklistChanged {
                let viewData = self.makeListViewData(hasMore: self.hasMore)
                V3Home.logger.info("after diff view data. \(viewData?.logInfo ?? "")")
                return viewData
            } else {
                V3Home.logger.info("diff update with old view data")
                return nil
            }
        }
        queue.addTask(t)
    }

    /// sections
    func updateSections(_ newSections: [Rust.TaskSection], with refs: [Rust.ContainerTaskRef]? = nil) {
        guard !newSections.isEmpty else { return }
        let t = { [weak self] () -> V3ListViewData? in
            guard let self = self else { return nil }
            V3Home.logger.info("before upadte section \(newSections.map(\.logInfo).joined(separator: ","))")
            var metaData = self.listScene.persist
            if let refs = refs {
                let tuple = self.updateRefData(refs, baseline: metaData?.refs ?? [])
                if tuple.changed {
                    metaData?.refs = tuple.refs
                }
            }

            // 更新我负责的：会有一些冗余数据，比如在清单下收到的push，也会被更新进去
            let tuple = self.updateSectionData(newSections, baseline: metaData?.sections ?? [])
            var tasklistChanged = false
            if var taskListMetaData = self.listScene.temporary {
                if let refs = refs {
                    let tuple = self.updateRefData(refs, baseline: taskListMetaData.refs)
                    if tuple.changed {
                        taskListMetaData.refs = tuple.refs
                    }
                }
                // 任务清单存在需要更新任务清单
                let taskListTuple = self.updateSectionData(newSections, baseline: taskListMetaData.sections)
                if taskListTuple.changed {
                    tasklistChanged = true
                    taskListMetaData.sections = taskListTuple.sections
                    self.listScene.temporary = taskListMetaData
                }
            }
            if tuple.changed || tasklistChanged {
                metaData?.sections = tuple.sections
                // 更新数据
                if let metaData = metaData {
                    self.listScene.persist = metaData
                }
                // 刷新UI
                let viewData = self.makeListViewData(hasMore: self.hasMore)
                V3Home.logger.info("after update section view data. \(viewData?.logInfo ?? "")")
                return viewData
            }
            return nil
        }
        queue.addTask(t)
    }

    func updateRefs(_ refs: [Rust.ContainerTaskRef]) {
        guard !refs.isEmpty else { return }
        let t = { [weak self] () -> V3ListViewData? in
            guard let self = self else { return nil }
            V3Home.logger.info("before upadte ref \(refs.map(\.logInfo).joined(separator: ","))")
            var metaData = self.listScene.persist
            let tuple = self.updateRefData(refs, baseline: metaData?.refs ?? [])
            if tuple.changed {
                metaData?.refs = tuple.refs
                if let metaData = metaData {
                    self.listScene.persist = metaData
                }
            }
            // 处理清单
            var tasklistChanged = false
            if var taskListMetaData = self.listScene.temporary {
                let tuple = self.updateRefData(refs, baseline: taskListMetaData.refs)
                if tuple.changed {
                    tasklistChanged = true
                    taskListMetaData.refs = tuple.refs
                    self.listScene.temporary = taskListMetaData
                }
            }

            if tuple.changed || tasklistChanged {
                let viewData = self.makeListViewData(hasMore: self.hasMore)
                V3Home.logger.info("after update ref view data. \(viewData?.logInfo ?? "")")
                return viewData
            } else {
                V3Home.logger.info("update ref with old view data")
                return nil
            }
        }
        queue.addTask(t)
    }

    /// Extra: commentCount, progress
    private func updateExtra(_ infos: [Rust.TodoExtraInfo]) {
        guard !infos.isEmpty else { return }
        let tuples = infos.map { info -> (Rust.TodoCommentCount?, Rust.TodoProgressChange?) in
            switch info.type {
            case .commentCount:
                return (info.commentCount, nil)
            case .progress:
                return (nil, info.progressChange)
            @unknown default: return (nil, nil)
            }
        }
        guard !tuples.isEmpty else { return }
        let t = { [weak self] () -> V3ListViewData? in
            guard let self = self else { return nil }
            var viewData = self.curViewData
            var updateTodos = [Rust.Todo]()
            tuples.forEach { (commentCount, progress) in
                if let cm = commentCount, let indexPath = self.indexPath(from: cm.guid) {
                    viewData.data[indexPath.section].items[indexPath.row].updateTodoExtra(commentCnt: cm.count)
                    updateTodos.append(viewData.data[indexPath.section].items[indexPath.row].todo)
                }
                if let pg = progress, let indexPath = self.indexPath(from: pg.guid) {
                    viewData.data[indexPath.section].items[indexPath.row].updateTodoExtra(progress: pg.progress)
                    updateTodos.append(viewData.data[indexPath.section].items[indexPath.row].todo)
                }
            }
            // 也要同时更新内存中的数据
            var metaData = self.listScene.persist
            let tuple = self.updateTaskData(updateTodos, baseline: metaData?.tasks, curUserId: self.curUserId)

            var tasklistChanged = false
            if var taskListMetaData = self.listScene.temporary {
                // 任务清单存在需要更新任务清单
                let taskListTuple = self.updateTaskData(updateTodos, baseline: taskListMetaData.tasks, curUserId: self.curUserId, ignoreRole: true)
                if taskListTuple.changed {
                    tasklistChanged = true
                    taskListMetaData.tasks = taskListTuple.todos
                    self.listScene.temporary = taskListMetaData
                }
            }

            if tuple.changed || tasklistChanged {
                metaData?.tasks = tuple.todos
                if let metaData = metaData {
                    self.listScene.persist = metaData
                }
            }
            return viewData
        }
        queue.addTask(t)
    }

    /// 接受push更新allTodos, changed
    /// 清单中可以不考虑角色
    private func updateTaskData(
        _ newTodos: [Rust.Todo],
        baseline todos: [Rust.Todo]?,
        curUserId: String,
        ignoreRole: Bool = false
    ) -> (todos: [Rust.Todo]?, changed: Bool) {
         guard let todos = todos else { return (nil, false) }
        guard !newTodos.isEmpty else { return (todos, false) }
        var all = todos, changed = false
        newTodos.forEach { todo in
            if let index = all.firstIndex(where: { $0.guid == todo.guid }) {
                if todo.isRemoved(curUserId, ignoreRole: ignoreRole) {
                    // 删除
                    changed = true
                    all.remove(at: index)
                } else {
                    // 修改
                    if todo.updateMilliTime >= all[index].updateMilliTime {
                        all[index] = todo
                        changed = true
                    }
                }
            } else {
                // 只有合法的数据才能被添加进来
                if !todo.isRemoved(curUserId, ignoreRole: ignoreRole) {
                    changed = true
                    all.append(todo)
                }
            }
        }
        V3Home.logger.info("current all todo count: \(all.count), changed: \(changed)")
        return (all, changed)
    }

    /// 更新section
    private func updateSectionData(_ newSections: [Rust.TaskSection], baseline sections: [Rust.TaskSection]) -> (sections: [Rust.TaskSection], changed: Bool) {
        guard !newSections.isEmpty else { return (sections, false) }
        var allSections = sections, changed = false
        newSections.forEach { newSection in
            if let index = allSections.firstIndex(where: { $0.guid == newSection.guid }) {
                if newSection.deleteMilliTime > 0 {
                    allSections.remove(at: index)
                    changed = true
                } else {
                    if newSection.version >= allSections[index].version {
                        allSections[index] = newSection
                        changed = true
                    }
                }
            } else {
                // 只有没有被删除的数据才能被添加进来
                if newSection.deleteMilliTime == 0 {
                    allSections.append(newSection)
                    changed = true
                }
            }
        }
        return (allSections, changed)
    }

    /// refs
    private func updateRefData(_ newRefs: [Rust.ContainerTaskRef], baseline refs: [Rust.ContainerTaskRef]) -> (refs: [Rust.ContainerTaskRef], changed: Bool) {
        guard !newRefs.isEmpty else { return (refs, false) }
        // 超过100的数据不打印
        if refs.count <= Utils.Logger.limmit {
            V3Home.logger.info("update ref data. newRefs: \(newRefs.map(\.logInfo)), baseline: \(refs.map(\.logInfo))")
        }
        var allRefs = refs, changed = false
        newRefs.forEach { ref in
            guard ref.isValid else { return }
            if let index = allRefs.firstIndex(where: { $0.containerGuid == ref.containerGuid && $0.taskGuid == ref.taskGuid }) {
                if ref.deleteMilliTime > 0 {
                    allRefs.remove(at: index)
                    changed = true
                } else {
                    if ref.version >= allRefs[index].version {
                        allRefs[index] = ref
                        changed = true
                    }
                }
            } else {
                // 只有没有被删除的数据才能被添加进来
                if ref.deleteMilliTime == 0 {
                    allRefs.append(ref)
                    changed = true
                }
            }
        }
        return (allRefs, changed)
    }

    // 任务清单 push
    func updateTasks(_ taskRefs: [Rust.TaskRefInfo]) {
        guard !taskRefs.isEmpty, var metaData = listScene.temporary else {
            V3Home.logger.error("list meta data is nil")
            return
        }
        let containerId = self.curContainerID
        // 属于当前清单的数据；不属于当前的清单的数据
        var includeCurTasks = [Rust.Todo](), excludedCurTasks = [Rust.Todo]()
        var includeCurRefs = [Rust.ContainerTaskRef](), excludedCurRefs = [Rust.ContainerTaskRef]()
        taskRefs.forEach { taskRef in
            if taskRef.task.relatedTaskListGuids.contains(where: { $0 == containerId }) {
                includeCurTasks.append(taskRef.task)
            } else {
                excludedCurTasks.append(taskRef.task)
            }
            if taskRef.ref.containerGuid == containerId {
                includeCurRefs.append(taskRef.ref)
            } else {
                excludedCurRefs.append(taskRef.ref)
            }
        }
        // swiftlint:disable line_length
        V3Home.logger.info("allTasks: \(metaData.tasks?.count ?? 0), allRefs: \(metaData.refs.count), includeCurTasks: \(includeCurTasks.count), excludedCurTasks: \(excludedCurTasks.count), includeCurRefs: \(includeCurRefs.count), excludedCurRefs: \(excludedCurRefs.count)")
        // swiftlint:enable line_length
        if !excludedCurTasks.isEmpty {
            metaData.tasks?.removeAll(where: { todo in
                return excludedCurTasks.contains(where: { $0.guid == todo.guid })
            })
        }
        if !excludedCurRefs.isEmpty {
            metaData.refs.removeAll(where: { ref in
                return excludedCurRefs.contains(where: { $0.containerGuid == ref.containerGuid && $0.taskGuid == ref.taskGuid })
            })
        }
        V3Home.logger.info("after remove allTasks: \(metaData.tasks?.count ?? 0), allRefs: \(metaData.refs.map(\.logInfo))")

        // update list meta data
        let taskTuple = updateTaskData(includeCurTasks, baseline: metaData.tasks, curUserId: curUserId, ignoreRole: true)
        let refTuple = updateRefData(includeCurRefs, baseline: metaData.refs)
        metaData.tasks = taskTuple.todos
        metaData.refs = refTuple.refs
        V3Home.logger.info("after update allTasks: \(metaData.tasks?.count ?? 0), allRefs: \(metaData.refs.map(\.logInfo))")
        listScene.temporary = metaData

        queue.addTask { [weak self] () -> V3ListViewData? in
            guard let self = self else { return nil }
            return self.makeListViewData(hasMore: self.hasMore)
        }
    }
}

// MARK: - Time Push

extension V3ListViewModel {
    /// 时间相关
    func listenTimeNoti() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self  else { return }
            self.stopDueTimeTimer()
            let timer = Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true) { [weak self] _ in
                V3Home.logger.info("timer handler invoked")
                self?.timeFomatChanged()
            }
            RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
            timer.fireDate = Date()
            self.dueTimetimer = timer
        }

        timeService?.rxTimeZone.distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                V3Home.logger.info("time zome changed")
                self?.timeFomatChanged()
            })
            .disposed(by: disposeBag)
        timeService?.rx12HourStyle.distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                V3Home.logger.info("time 12 hour style changed")
                self?.timeFomatChanged()
            })
            .disposed(by: disposeBag)
    }

    func stopDueTimeTimer() {
        dueTimetimer?.invalidate()
        dueTimetimer = nil
    }

    private func timeFomatChanged() {
        guard !curViewData.isEmpty else { return }
        let (new, last) = (curTimeContext, lastTimeContext)
        guard new.is12HourStyle != last.is12HourStyle ||
                new.timeZone.identifier != last.timeZone.identifier ||
                (new.currentTime / 60) != (last.currentTime / 60)
        else {
            return
        }
        lastTimeContext = new
        guard !queue.isBusy else {
            V3Home.logger.info("time changed but queue is busy")
            return
        }
        V3Home.logger.info("begin update list by current view data: \(curViewData.logInfo)")
        queue.addTask { [weak self] in self?.makeListViewData() }
    }
}

// MARK: - Setting Push

extension V3ListViewModel {
    /// 设置
    func listenSetting() {
        settingService?.observe(forKeyPath: \.listBadgeConfig)
            .distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                V3Home.logger.info("badge setting changed")
                self.badgeSettingChanged()
            })
            .disposed(by: disposeBag)
    }

    private func badgeSettingChanged() {
        guard !curViewData.isEmpty else { return }
        queue.addTask { [weak self] in self?.makeListViewData() }
    }
}

// MARK: - Heart Beat

extension V3ListViewModel {

    // 设置心跳：定时向 server 发送心跳，维系联系
    func trySetupHeartbeat() {
        // 销毁旧的
        stopHeartBeatTimer()
        // 只有清单才会用到
        guard isTaskList else { return }
        // 设置新的
        let doSend = { [weak self] in
            guard let self = self, let commentApi = self.commentApi else { return }
            commentApi.sendCommentHeartbeat(either: nil, or: self.curContainerID).subscribe().disposed(by: self.disposeBag)
        }
        doSend()
        let timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { _ in doSend() }
        RunLoop.main.add(timer, forMode: .common)
        heartbeatTimer = timer
    }

    func stopHeartBeatTimer() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
}

// MARK: - Bus

extension V3ListViewModel {

    func bindBusEvent() {
        context.bus.subscribe { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .setupPersistData(let meta):
                self.listScene.persist = meta
            case .containerUpdated(let toast):
                if let toast = toast {
                    self.onListUpdate?(.showToast(toast))
                }
            default: break
            }
        }.disposed(by: disposeBag)
    }
}

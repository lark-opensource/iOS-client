//
//  DetailGanttViewModel.swift
//  Todo
//
//  Created by wangwanxin on 2023/6/12.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa

final class DetailGanttViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    let rxViewData: BehaviorRelay<DetailGanttViewData?> = .init(value: nil)

    private let context: DetailModuleContext
    private let disposeBag = DisposeBag()

    init(resolver: UserResolver, context: DetailModuleContext) {
        self.userResolver = resolver
        self.context = context
        setup()
    }

    private func setup() {
        guard context.store.state.scene.isForEditing else { return }
        Observable.combineLatest(
            context.store.rxValue(forKeyPath: \.isMilestone),
            context.store.rxValue(forKeyPath: \.dependentsMap),
            context.store.rxValue(forKeyPath: \.dependents),
            context.store.rxValue(forKeyPath: \.completedState)
        )
        .observeOn(MainScheduler.instance)
        .map { [weak self] (isMilestone, dependentsMap, _, _) -> DetailGanttViewData? in
            self?.makeViewData(isMilestone: isMilestone, dependentsMap: dependentsMap)
        }
        .bind(to: rxViewData)
        .disposed(by: disposeBag)
    }

    private func makeViewData(isMilestone: Bool, dependentsMap: [String: Rust.Todo]?) -> DetailGanttViewData? {
        var viewData = DetailGanttViewData()
        viewData.isMilestone = isMilestone
        guard let dependentsMap = dependentsMap, let deps = context.store.state.dependents else {
            return viewData
        }
        let preDeps = deps.filter { ref in
            if ref.dependentType == .prev, ref.taskGuid == guid,
               dependentsMap[ref.dependentTaskGuid] != nil {
                return true
            }
            return false
        }
        let nextDeps = deps.filter { ref in
            if ref.dependentType == .next, ref.taskGuid == guid,
                dependentsMap[ref.dependentTaskGuid] != nil {
                return true
            }
            return false
        }
        viewData.preTaskCount = preDeps.count
        viewData.nextTaskCount = nextDeps.count
        if let todo = context.store.state.todo, todo.completedMilliTime > 0 {
            viewData.isCompleted = true
        } else {
            viewData.isCompleted = false
        }
        return viewData
    }
}

extension DetailGanttViewModel {

    var canEdit: Bool {
        return context.store.state.todo?.selfPermission.isEditable ?? false
    }

    var guid: String? {
        return context.store.state.todo?.guid
    }

    func dependentTodoList(_ type: Rust.TaskDependent.TypeEnum) -> [Rust.Todo]? {
        guard let dependentMap = context.store.state.dependentsMap,
              let dependents = context.store.state.dependents,
              !dependents.isEmpty else {
            return nil
        }
        let tasks = dependents.compactMap { dep in
            if let task = dependentMap[dep.dependentTaskGuid], dep.dependentType == type {
                return task
            } else {
                return nil
            }
        }
        return tasks
    }

    func allDependentGuids() -> [String]? {
        var guids: [String]?
        if let keys = context.store.state.dependentsMap?.keys {
            guids = Array(keys)
            if let guid = guid, !guid.isEmpty {
                guids?.append(guid)
            }
        }
        return guids
    }

    func handlePickerDependents(_ todos: [Rust.Todo], _ type: Rust.TaskDependent.TypeEnum) {
        var dependents = context.store.state.dependents ?? [Rust.TaskDepRef]()
        var dependentsMap = context.store.state.dependentsMap ?? [String: Rust.Todo]()
        let guid = context.store.state.todo?.guid ?? ""
        todos.forEach { todo in
            var dep = Rust.TaskDepRef()
            dep.taskGuid = guid
            dep.dependentTaskGuid = todo.guid
            dep.dependentType = type
            dependents.append(dep)
            dependentsMap[todo.guid] = todo
        }
        context.store.dispatch(.updateDependents(dependents, dependentsMap))
    }

    func removeDependents(_ guids: [String], _ type: Rust.TaskDependent.TypeEnum) {
        var dependents = context.store.state.dependents ?? [Rust.TaskDepRef]()
        var dependentsMap = context.store.state.dependentsMap ?? [String: Rust.Todo]()
        dependents.removeAll { dep in
            return guids.contains(where: { $0 == dep.dependentTaskGuid })
        }
        guids.forEach { guid in
            dependentsMap.removeValue(forKey:  guid)
        }
        context.store.dispatch(.updateDependents(dependents, dependentsMap))
    }
    

}

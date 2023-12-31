//
//  DetailDependentPickerViewModel.swift
//  Todo
//
//  Created by wangwanxin on 2023/7/19.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa

final class DetailDependentPickerViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    let filterTaskGuids: [String]?
    let type: Rust.TaskDependent.TypeEnum

    let rxViewState = BehaviorRelay<ListViewState>(value: .idle)
    var onUpdate: (() -> Void)?

    var title: String {
        if type == .prev {
            return I18N.Todo_GanttView_BlockedBy_MenuItem
        }
        return I18N.Todo_GanttView_Blocking_MenuItem
    }

    private let disposeBag = DisposeBag()
    private var lastSearchDisposable: Disposable?

    // 时间格式化上下文
    private var curTimeContext: TimeContext {
        return TimeContext(
            currentTime: Int64(Date().timeIntervalSince1970),
            timeZone: timeService?.rxTimeZone.value ?? .current,
            is12HourStyle: timeService?.rx12HourStyle.value ?? false
        )
    }

    @ScopedInjectedLazy var completeService: CompleteService?
    @ScopedInjectedLazy var timeService: TimeService?
    @ScopedInjectedLazy var richContentService: RichContentService?
    @ScopedInjectedLazy var fetchApi: TodoFetchApi?

    var cellDatas: [DetailDependentListCellData] = []
    var selectedTodos: [Rust.Todo] = []

    init(resolver: UserResolver, filterTaskGuids: [String]?, type: Rust.TaskDependent.TypeEnum) {
        self.userResolver = resolver
        self.filterTaskGuids = filterTaskGuids
        self.type = type
    }

    func queryTodo(by query: String) {
        lastSearchDisposable?.dispose()
        guard !query.isEmpty else {
            rxViewState.accept(.idle)
            cellDatas.removeAll()
            onUpdate?()
            return
        }
        lastSearchDisposable = queryTodoList(query).subscribe()
    }

    private func queryTodoList(_ query: String) -> Observable<Void> {
        rxViewState.accept(.loading)
        return fetchApi?.searchTasks(by: query)
            .observeOn(MainScheduler.asyncInstance)
            .do(
                onNext: { [weak self] (tasks) in
                    guard let self = self else { return }
                    self.makeCellData(tasks)
                    self.rxViewState.accept(self.cellDatas.isEmpty ? .empty : .data)
                    self.onUpdate?()
                },
                onError: { [weak self] _ in
                    guard let self = self else { return }
                    self.rxViewState.accept(.empty)
                }
            )
                .map { _ in void } ?? .just(void)
    }

    private func makeCellData(_ tasks: [Rust.Todo]) {
        let timeContext = curTimeContext, selected = filterTaskGuids
        cellDatas = tasks
            .compactMap { todo in
                guard let selected = selected,
                      !selected.contains(where: { $0 == todo.guid })
                else {
                    return nil
                }
                let completeState = completeService?.state(for: todo) ?? .outsider(isCompleted: false)
                var cellData = DetailDependentListCellData(with: todo, completeState: completeState)
                var contentData = V3ListContentData(
                    todo: todo,
                    isTaskEditableInContainer: false,
                    completeState: (completeState, true),
                    richContentService: richContentService,
                    timeContext: timeContext
                )
                // 这种场景不需要显示extensionInfo
                contentData.extensionInfo = nil
                cellData.showRemoveBtn = false
                cellData.contentType = .content(data: contentData)
                cellData.isSelected = selectedTodos.contains(where: { $0.guid == todo.guid })
                return cellData
            }
    }

    func safeCheckRows(_ indexPath: IndexPath) -> Int? {
        return V3ListSectionData.safeCheckRows(indexPath, from: cellDatas)
    }

    func didSelectItem(at indexPath: IndexPath) {
        guard let row = safeCheckRows(indexPath) else {
            return
        }
        let todo = cellDatas[row].todo
        // 没有权限不能点击
        guard todo.selfPermission.isEditable && !todo.isDeleted else {
            return
        }
        cellDatas[row].isSelected = !cellDatas[row].isSelected
        selectedTodos.removeAll(where: { $0.guid == todo.guid })
        if cellDatas[row].isSelected {
            selectedTodos.append(todo)
        }
        onUpdate?()
    }

}
